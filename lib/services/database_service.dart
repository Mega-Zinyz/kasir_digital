import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/index.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Menyimpan database di folder instalasi aplikasi
    final executablePath = Platform.resolvedExecutable;
    final appDir = Directory(executablePath).parent;
    final dataDir = Directory('${appDir.path}/data');

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final path = '${dataDir.path}/kasir_digital.db';

    // Check if database exists and needs migration
    // If old database exists, delete it to force recreation with new schema
    if (await File(path).exists()) {
      try {
        final db = await openDatabase(path);
        final currentVersion = await db.getVersion();
        await db.close();

        // If version is less than target, delete old database to force recreation
        if (currentVersion < 6) {
          await File(path).delete();
        }
      } catch (e) {
        // If database is corrupted, delete it
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create Products table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        barcode TEXT,
        costPrice REAL NOT NULL,
        profitMargin REAL NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        categories TEXT DEFAULT '',
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        expiryDate TEXT,
        unit TEXT DEFAULT 'pcs'
      )
    ''');

    // Create Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        transactionDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paymentAmount REAL NOT NULL,
        changeAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create Transaction Items table
    await db.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transactionId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0,
        profitMargin REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add barcode column to products table
      await db.execute('''
        ALTER TABLE products ADD COLUMN barcode TEXT
      ''');
    }
    if (oldVersion < 3) {
      // Add costPrice and profitMargin columns to products table
      // Set default values: use price as costPrice, and profitMargin as 0
      await db.execute('''
        ALTER TABLE products ADD COLUMN costPrice REAL NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE products ADD COLUMN profitMargin REAL NOT NULL DEFAULT 0
      ''');

      // Migrate existing price data to costPrice
      await db.execute('''
        UPDATE products SET costPrice = price WHERE costPrice = 0
      ''');
    }
    if (oldVersion < 4) {
      // Add costPrice and profitMargin columns to transaction_items table
      await db.execute('''
        ALTER TABLE transaction_items ADD COLUMN costPrice REAL NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE transaction_items ADD COLUMN profitMargin REAL NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 5) {
      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add categories column to products table (storing as pipe-separated string)
      await db.execute('''
        ALTER TABLE products ADD COLUMN categories TEXT DEFAULT ''
      ''');
    }
    if (oldVersion < 7) {
      // Add expiryDate column to products table
      await db.execute('''
        ALTER TABLE products ADD COLUMN expiryDate TEXT
      ''');
    }
    if (oldVersion < 8) {
      // Add unit column to products table
      await db.execute('''
        ALTER TABLE products ADD COLUMN unit TEXT DEFAULT 'pcs'
      ''');
    }
  }

  // ========== PRODUCT OPERATIONS ==========
  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toJson());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Product.fromJson(maps[i]));
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.copyWith(updatedAt: DateTime.now()).toJson(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getProductStock(String productId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (maps.isNotEmpty) {
      return maps.first['stock'] as int;
    }
    return 0;
  }

  Future<void> updateProductStock(String productId, int newStock) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock = ? WHERE id = ?',
      [newStock, productId],
    );
  }

  // ========== TRANSACTION OPERATIONS ==========
  Future<void> insertTransaction(SalesTransaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toJson());
  }

  Future<List<SalesTransaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'transactionDate DESC');
    
    // Load transaction items for each transaction
    List<SalesTransaction> transactions = [];
    for (var map in maps) {
      final transaction = SalesTransaction.fromJson(map);
      final items = await getTransactionItems(transaction.id);
      transactions.add(transaction.copyWith(items: items));
    }
    
    return transactions;
  }

  Future<SalesTransaction?> getTransactionById(String id) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SalesTransaction.fromJson(maps.first);
    }
    return null;
  }

  Future<List<SalesTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where:
          'transactionDate >= ? AND transactionDate <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'transactionDate DESC',
    );
    
    // Load transaction items for each transaction
    List<SalesTransaction> transactions = [];
    for (var map in maps) {
      final transaction = SalesTransaction.fromJson(map);
      final items = await getTransactionItems(transaction.id);
      transactions.add(transaction.copyWith(items: items));
    }
    
    return transactions;
  }

  Future<List<SalesTransaction>> getTransactionsByMonth(int month, int year) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    return getTransactionsByDateRange(startDate, endDate);
  }

  Future<void> updateTransaction(SalesTransaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    // Delete related items first
    await db.delete(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [id],
    );
    // Then delete transaction
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== TRANSACTION ITEM OPERATIONS ==========
  Future<void> insertTransactionItem(TransactionItem item) async {
    final db = await database;
    await db.insert('transaction_items', item.toJson());
  }

  Future<List<TransactionItem>> getTransactionItems(String transactionId) async {
    final db = await database;
    final maps = await db.query(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    return List.generate(maps.length, (i) => TransactionItem.fromJson(maps[i]));
  }

  Future<void> deleteTransactionItem(String itemId) async {
    final db = await database;
    await db.delete(
      'transaction_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ========== STATISTICS OPERATIONS ==========
  Future<double> getTotalSalesByMonth(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    double total = 0;
    for (var transaction in transactions) {
      if (transaction.status == 'completed') {
        total += transaction.totalAmount;
      }
    }
    return total;
  }

  Future<int> getTotalTransactionsByMonth(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    return transactions.where((t) => t.status == 'completed').length;
  }

  Future<Map<String, dynamic>> getDailySales(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final maps = await db.query(
      'transactions',
      where:
          'transactionDate >= ? AND transactionDate <= ? AND status = ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        'completed'
      ],
    );

    double totalSales = 0;
    int transactionCount = 0;

    for (var map in maps) {
      totalSales += (map['totalAmount'] as num).toDouble();
      transactionCount++;
    }

    return {
      'totalSales': totalSales,
      'transactionCount': transactionCount,
    };
  }

  // ========== CATEGORY OPERATIONS ==========
  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toJson());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromJson(maps.first);
    }
    return null;
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ========== BACKUP / RESTORE ==========
  /// Clear all user data (products, transactions, transaction_items, categories).
  /// Used by restore to replace existing data with backup data.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transaction_items');
      await txn.delete('transactions');
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  Future<List<TransactionItem>> getAllTransactionItems() async {
    final db = await database;
    final maps = await db.query('transaction_items');
    return List.generate(maps.length, (i) => TransactionItem.fromJson(maps[i]));
  }
}
