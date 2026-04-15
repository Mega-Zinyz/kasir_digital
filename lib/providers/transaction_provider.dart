import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<SalesTransaction> _transactions = [];
  List<SalesTransaction> _allTransactions = [];
  bool _isLoading = false;

  List<SalesTransaction> get transactions => _transactions;
  List<SalesTransaction> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;

  // Load all transactions (analytics only — unaffected by date filters)
  Future<void> loadAllTransactions() async {
    try {
      final data = await _dbService.getAllTransactions();
      _allTransactions = List<SalesTransaction>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all transactions: $e');
    }
  }

  // Load all transactions
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _dbService.getAllTransactions();
      _transactions = List<SalesTransaction>.from(data);
      _allTransactions = List<SalesTransaction>.from(data);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load transactions by date range
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _dbService.getTransactionsByDateRange(
        startDate,
        endDate,
      );
      _transactions = List<SalesTransaction>.from(data);
      // Keep allTransactions in sync with full unfiltered data
      final allData = await _dbService.getAllTransactions();
      _allTransactions = List<SalesTransaction>.from(allData);
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      _transactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load transactions by month
  Future<void> loadTransactionsByMonth(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _dbService.getTransactionsByMonth(month, year);
      _transactions = List<SalesTransaction>.from(data);
    } catch (e) {
      _transactions = [];
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new transaction
  Future<void> addTransaction({
    String? transactionId,
    required double totalAmount,
    required double paymentAmount,
    required String paymentMethod,
    List<TransactionItem>? items,
    String? notes,
  }) async {
    try {
      final txnId = transactionId ?? const Uuid().v4();
      final changeAmount = paymentAmount - totalAmount;

      final transaction = SalesTransaction(
        id: txnId,
        transactionDate: DateTime.now(),
        totalAmount: totalAmount,
        paymentAmount: paymentAmount,
        changeAmount: changeAmount,
        paymentMethod: paymentMethod,
        status: 'completed',
        notes: notes,
        createdAt: DateTime.now(),
        items: items ?? [], // Include items in the transaction
      );

      await _dbService.insertTransaction(transaction);

      // Insert transaction items
      if (items != null) {
        for (var item in items) {
          await _dbService.insertTransactionItem(item);
        }
      }

      _transactions.insert(0, transaction);
      _allTransactions.insert(0, transaction);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _dbService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _allTransactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Get transaction details with items
  Future<Map<String, dynamic>?> getTransactionDetails(String transactionId) async {
    try {
      final transaction = await _dbService.getTransactionById(transactionId);
      if (transaction == null) return null;

      final items = await _dbService.getTransactionItems(transactionId);

      return {
        'transaction': transaction,
        'items': items,
      };
    } catch (e) {
      debugPrint('Error getting transaction details: $e');
      return null;
    }
  }

  // Get total sales this month
  Future<double> getTotalSalesThisMonth() async {
    try {
      final now = DateTime.now();
      return await _dbService.getTotalSalesByMonth(now.month, now.year);
    } catch (e) {
      debugPrint('Error getting total sales: $e');
      return 0.0;
    }
  }

  // Get total transactions this month
  Future<int> getTotalTransactionsThisMonth() async {
    try {
      final now = DateTime.now();
      return await _dbService.getTotalTransactionsByMonth(now.month, now.year);
    } catch (e) {
      debugPrint('Error getting transaction count: $e');
      return 0;
    }
  }

  // Get daily sales
  Future<Map<String, dynamic>> getDailySales(DateTime date) async {
    try {
      return await _dbService.getDailySales(date);
    } catch (e) {
      debugPrint('Error getting daily sales: $e');
      return {'totalSales': 0.0, 'transactionCount': 0};
    }
  }
}
