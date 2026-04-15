import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../models/index.dart';
import '../utils/app_constants.dart';

class BackupService {
  final DatabaseService _dbService = DatabaseService();

  /// Export database to JSON backup file (includes transaction_items)
  Future<String?> exportDatabase({String? defaultPath}) async {
    try {
      final products = await _dbService.getAllProducts();
      final transactions = await _dbService.getAllTransactions();
      final transactionItems = await _dbService.getAllTransactionItems();

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
        'products': products.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'transaction_items': transactionItems.map((i) => i.toJson()).toList(),
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(backupData);

      String? savePath = defaultPath;
      if (savePath == null || savePath.isEmpty) {
        savePath = await FilePicker.getDirectoryPath();
      }

      if (savePath != null && savePath.isNotEmpty) {
        final fileName = 'kasir_backup_$timestamp.json';
        final filePath = '$savePath/$fileName';
        await File(filePath).writeAsString(jsonContent);
        return filePath;
      }

      return null;
    } catch (e) {
      throw Exception('Gagal membuat backup: ${e.toString()}');
    }
  }

  /// Validate backup file and return parsed data, or throw on error.
  Future<Map<String, dynamic>> validateBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('__cancelled__');
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      throw Exception('Tidak dapat membaca path file');
    }

    final jsonContent = await File(filePath).readAsString();

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('File bukan JSON yang valid');
    }

    if (!data.containsKey('products') || !data.containsKey('transactions')) {
      throw Exception('Format file backup tidak valid');
    }

    return data;
  }

  /// Restore database from parsed backup data (replaces all existing data).
  Future<void> restoreDatabase(Map<String, dynamic> data) async {
    await _dbService.clearAllData();

    // Restore categories
    final rawCategories = data['categories'] as List<dynamic>? ?? [];
    for (final raw in rawCategories) {
      await _dbService.insertCategory(
          Category.fromJson(raw as Map<String, dynamic>));
    }

    // Restore products
    final rawProducts = data['products'] as List<dynamic>;
    for (final raw in rawProducts) {
      await _dbService.insertProduct(
          Product.fromJson(raw as Map<String, dynamic>));
    }

    // Restore transactions
    final rawTransactions = data['transactions'] as List<dynamic>;
    for (final raw in rawTransactions) {
      await _dbService.insertTransaction(
          SalesTransaction.fromJson(raw as Map<String, dynamic>));
    }

    // Restore transaction items (new field — optional for old backups)
    final rawItems = data['transaction_items'] as List<dynamic>? ?? [];
    for (final raw in rawItems) {
      await _dbService.insertTransactionItem(
          TransactionItem.fromJson(raw as Map<String, dynamic>));
    }
  }
}

