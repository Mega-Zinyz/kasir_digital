// Database Stress Test - kasir_digital
//
// Menguji performa database SQLite di bawah kondisi beban tinggi:
// - Bulk insert produk
// - Bulk insert transaksi
// - Query concurrent / bertubi-tubi
// - Pencarian (search) dengan dataset besar
// - Update & delete massal
//
// Jalankan: flutter test test/stress/database_stress_test.dart --timeout=120s
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// ── Config ──────────────────────────────────────────────────────────────────
// Ubah nilai di sini untuk menyesuaikan beban test

const kBulkInsertCounts     = [100, 500, 1000]; // Jumlah produk bulk insert (group 1)
const kQueryIterations      = 50;   // Berapa kali query semua produk (group 2)
const kSearchIterations     = 100;  // Berapa kali search LIKE (group 3)
const kUpdateCount          = 500;  // Produk yang diupdate stok (group 4)
const kTransactionCount     = 500;  // Transaksi yang diinsert (group 5)
const kDateRangeIterations  = 30;   // Berapa kali query date-range (group 6)
const kConcurrentParallel   = 20;   // Jumlah query paralel (group 7)
const kDeleteCount          = 500;  // Transaksi yang dihapus (group 8)
const kMixedLoadCount       = 200;  // Iterasi mixed CRUD (group 9)
// ── helpers ──────────────────────────────────────────────────────────────────

Database? _db;

Future<Database> _openTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dir = Directory.systemTemp.createTempSync('kasir_stress_');
  final path = '${dir.path}/stress_test.db';

  return await databaseFactory.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
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
            expiryDate TEXT
          )
        ''');
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
      },
    ),
  );
}

Map<String, dynamic> _fakeProduct(int i) => {
      'id': 'prod-$i',
      'name': 'Produk Stres Test $i',
      'code': 'SKU-${i.toString().padLeft(6, '0')}',
      'barcode': '89${i.toString().padLeft(10, '0')}',
      'costPrice': 5000.0 + (i % 50) * 100,
      'profitMargin': 1000.0 + (i % 20) * 50,
      'price': 6000.0 + (i % 50) * 100 + (i % 20) * 50,
      'stock': 50 + (i % 200),
      'categories': 'cat-${i % 5}',
      'imagePath': null,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': null,
      'expiryDate': null,
    };

Map<String, dynamic> _fakeTransaction(int i, String productId, String productName, double price) => {
      'id': 'txn-$i',
      'transactionDate': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
      'totalAmount': price * (1 + i % 5),
      'paymentAmount': price * (1 + i % 5) + 1000,
      'changeAmount': 1000.0,
      'paymentMethod': i % 2 == 0 ? 'cash' : 'card',
      'status': 'completed',
      'notes': null,
      'createdAt': DateTime.now().toIso8601String(),
    };

Map<String, dynamic> _fakeTransactionItem(String txnId, String productId, String productName, double price, int qty) => {
      'id': '$txnId-item',
      'transactionId': txnId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': qty,
      'subtotal': price * qty,
      'costPrice': price * 0.7,
      'profitMargin': price * 0.3,
    };

// ── hasil bantu ───────────────────────────────────────────────────────────────

class _Result {
  final String name;
  final int count;
  final Duration elapsed;

  _Result(this.name, this.count, this.elapsed);

  double get opsPerSecond => count / elapsed.inMilliseconds * 1000;

  @override
  String toString() =>
      '[${name.padRight(40)}] '
      'count=${count.toString().padLeft(6)} | '
      'ms=${elapsed.inMilliseconds.toString().padLeft(7)} | '
      'ops/s=${opsPerSecond.toStringAsFixed(1).padLeft(10)}';
}

final _results = <_Result>[];

Future<_Result> _measure(String name, int count, Future<void> Function() fn) async {
  final sw = Stopwatch()..start();
  await fn();
  sw.stop();
  final r = _Result(name, count, sw.elapsed);
  _results.add(r);
  return r;
}

// ── setup / teardown ─────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    _db = await _openTestDatabase();
  });

  tearDownAll(() async {
    _printSummary();
    await _db?.close();
  });

  // ── 1. BULK INSERT PRODUK ─────────────────────────────────────────────────
  group('1. Bulk Insert Produk', () {
    const counts = kBulkInsertCounts;

    for (final n in counts) {
      test('Insert $n produk (batch)', () async {
        final db = _db!;
        // Hapus data lama untuk test berikutnya
        await db.delete('products', where: "id LIKE 'prod-$n%'");

        final r = await _measure('Bulk Insert $n produk', n, () async {
          final batch = db.batch();
          for (int i = 0; i < n; i++) {
            batch.insert(
              'products',
              _fakeProduct(i),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        });

        print(r);
        // Target: minimal 200 insert/detik untuk SQLite FFI
        expect(r.opsPerSecond, greaterThan(200),
            reason: 'Performa insert terlalu lambat: ${r.opsPerSecond.toStringAsFixed(1)} ops/s');
      });
    }
  });

  // ── 2. QUERY SEMUA PRODUK ─────────────────────────────────────────────────
  group('2. Query getAllProducts', () {
    test('Query semua produk berulang ${kQueryIterations}x', () async {
      final db = _db!;
      const iterations = kQueryIterations;

      final r = await _measure('Query getAllProducts x$iterations', iterations, () async {
        for (int i = 0; i < iterations; i++) {
          final _ = await db.query('products', orderBy: 'name ASC');
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(10),
          reason: 'Query terlalu lambat: ${r.opsPerSecond.toStringAsFixed(1)} ops/s');
    });
  });

  // ── 3. PENCARIAN PRODUK ───────────────────────────────────────────────────
  group('3. Pencarian Produk (LIKE)', () {
    test('Search ${kSearchIterations}x dengan keyword berbeda', () async {
      final db = _db!;
      const iterations = kSearchIterations;
      final keywords = ['Produk', 'SKU', 'Test', '001', '005', '009'];

      final r = await _measure('Search LIKE x$iterations', iterations, () async {
        for (int i = 0; i < iterations; i++) {
          final kw = keywords[i % keywords.length];
          await db.query(
            'products',
            where: 'name LIKE ? OR code LIKE ?',
            whereArgs: ['%$kw%', '%$kw%'],
            orderBy: 'name ASC',
          );
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(30),
          reason: 'Query LIKE terlalu lambat');
    });
  });

  // ── 4. UPDATE STOK MASSAL ─────────────────────────────────────────────────
  group('4. Update Stok Massal', () {
    test('Update stok $kUpdateCount produk satu per satu', () async {
      final db = _db!;
      const n = kUpdateCount;

      final r = await _measure('Update stok satu per satu x$n', n, () async {
        for (int i = 0; i < n; i++) {
          await db.rawUpdate(
            'UPDATE products SET stock = ? WHERE id = ?',
            [100 + i, 'prod-$i'],
          );
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(100),
          reason: 'Update stok terlalu lambat');
    });

    test('Update stok $kUpdateCount produk via batch', () async {
      final db = _db!;
      const n = kUpdateCount;

      final r = await _measure('Update stok batch x$n', n, () async {
        final batch = db.batch();
        for (int i = 0; i < n; i++) {
          batch.rawUpdate(
            'UPDATE products SET stock = ? WHERE id = ?',
            [200 + i, 'prod-$i'],
          );
        }
        await batch.commit(noResult: true);
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(500),
          reason: 'Batch update stok terlalu lambat');
    });
  });

  // ── 5. BULK INSERT TRANSAKSI ──────────────────────────────────────────────
  group('5. Bulk Insert Transaksi', () {
    const txnCount = kTransactionCount;

    test('Insert $txnCount transaksi + item (batch)', () async {
      final db = _db!;

      final r = await _measure('Bulk Insert $txnCount transaksi', txnCount, () async {
        final batch = db.batch();
        for (int i = 0; i < txnCount; i++) {
          final txn = _fakeTransaction(i, 'prod-${i % 100}', 'Produk Stres Test ${i % 100}', 6000 + (i % 50) * 100.0);
          batch.insert('transactions', txn, conflictAlgorithm: ConflictAlgorithm.replace);
          batch.insert(
            'transaction_items',
            _fakeTransactionItem('txn-$i', 'prod-${i % 100}', 'Produk Stres Test ${i % 100}', 6000 + (i % 50) * 100.0, 1 + i % 5),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(200),
          reason: 'Insert transaksi terlalu lambat');
    });
  });

  // ── 6. QUERY TRANSAKSI DENGAN DATE RANGE ─────────────────────────────────
  group('6. Query Transaksi (Date Range)', () {
    test('Query transaksi $kDateRangeIterations hari terakhir, ${kDateRangeIterations}x berulang', () async {
      final db = _db!;
      const iterations = kDateRangeIterations;
      final startDate = DateTime.now().subtract(const Duration(days: kDateRangeIterations));
      final endDate = DateTime.now();

      final r = await _measure('Query transaksi date-range x$iterations', iterations, () async {
        for (int i = 0; i < iterations; i++) {
          await db.query(
            'transactions',
            where: 'transactionDate >= ? AND transactionDate <= ?',
            whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
            orderBy: 'transactionDate DESC',
          );
        }
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(10),
          reason: 'Query date-range terlalu lambat');
    });
  });

  // ── 7. CONCURRENT READ SIMULATION ────────────────────────────────────────
  group('7. Concurrent Read Simulation', () {
    test('$kConcurrentParallel query paralel secara bersamaan', () async {
      final db = _db!;
      const parallelCount = kConcurrentParallel;

      final sw = Stopwatch()..start();
      await Future.wait(List.generate(parallelCount, (i) async {
        await db.query('products', orderBy: 'name ASC', limit: 100);
        await db.query('transactions', orderBy: 'transactionDate DESC', limit: 50);
      }));
      sw.stop();

      final r = _Result('Concurrent Read (${parallelCount}x parallel)', parallelCount * 2, sw.elapsed);
      _results.add(r);
      print(r);

      expect(sw.elapsed.inMilliseconds, lessThan(5000),
          reason: 'Concurrent read timeout (>5 detik): ${sw.elapsed.inMilliseconds}ms');
    });
  });

  // ── 8. DELETE MASSAL ──────────────────────────────────────────────────────
  group('8. Delete Massal', () {
    test('Delete $kDeleteCount transaksi dan items', () async {
      final db = _db!;
      const n = kDeleteCount;

      final r = await _measure('Delete $n transaksi + items (batch)', n, () async {
        final batch = db.batch();
        for (int i = 0; i < n; i++) {
          batch.delete('transaction_items', where: 'transactionId = ?', whereArgs: ['txn-$i']);
          batch.delete('transactions', where: 'id = ?', whereArgs: ['txn-$i']);
        }
        await batch.commit(noResult: true);
      });

      print(r);
      expect(r.opsPerSecond, greaterThan(100),
          reason: 'Delete terlalu lambat');
    });
  });

  // ── 9. STRESS GABUNGAN (Mixed Load) ──────────────────────────────────────
  group('9. Mixed Load (CRUD bersamaan)', () {
    test('Insert + Query + Update bergantian ${kMixedLoadCount}x', () async {
      final db = _db!;
      const n = kMixedLoadCount;

      final r = await _measure('Mixed Load x$n', n, () async {
        for (int i = 0; i < n; i++) {
          // Insert
          await db.insert(
            'products',
            _fakeProduct(2000 + i),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          // Query
          await db.query('products', where: 'id = ?', whereArgs: ['prod-${i % 100}']);
          // Update
          await db.rawUpdate('UPDATE products SET stock = ? WHERE id = ?', [i + 1, 'prod-${i % 100}']);
        }
      });

      print(r);
      // Mixed ops dihitung 3 operasi per iterasi
      final adjustedOps = (n * 3) / r.elapsed.inMilliseconds * 1000;
      print('  Mixed ops/s (3 ops/iter): ${adjustedOps.toStringAsFixed(1)}');
      expect(r.elapsed.inSeconds, lessThan(30),
          reason: 'Mixed load melebihi batas waktu 30 detik');
    });
  });
}

// ── Summary ───────────────────────────────────────────────────────────────────

void _printSummary() {
  final line = '-' * 80;
  print('\n$line');
  print('STRESS TEST SUMMARY - kasir_digital Database');
  print(line);
  for (final r in _results) {
    final status = r.opsPerSecond >= 100 ? '✓' : (r.opsPerSecond >= 30 ? '⚠' : '✗');
    print('$status $r');
  }
  print(line);
  print('Total tests: ${_results.length}');
  print(line);
}
