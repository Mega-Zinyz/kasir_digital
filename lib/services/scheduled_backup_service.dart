import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../utils/app_constants.dart';

class ScheduledBackupService {
  late Timer? _backupTimer;
  final DatabaseService _dbService = DatabaseService();
  
  String? _backupDirectory;
  String? _frequency;
  DateTime? _lastBackupTime;
  
  Function(String)? onBackupComplete;
  Function(String)? onBackupError;

  ScheduledBackupService() {
    _backupTimer = null;
  }

  /// Initialize backup directory (near exe)
  void _initializeBackupDirectory() {
    try {
      final exePath = Platform.resolvedExecutable;
      final appDirectory = File(exePath).parent.path;
      final backupFolder = Directory('$appDirectory/Backup');
      
      // Create backup folder if it doesn't exist
      if (!backupFolder.existsSync()) {
        backupFolder.createSync(recursive: true);
        debugPrint('Created backup directory: ${backupFolder.path}');
      }
      
      _backupDirectory = backupFolder.path;
      debugPrint('Backup directory initialized: $_backupDirectory');
    } catch (e) {
      debugPrint('Error initializing backup directory: $e');
    }
  }

  /// Start scheduled backups
  void startScheduledBackups({
    required String frequency, // 'none', 'daily', 'weekly'
    DateTime? lastBackupTime,
    String? backupDirectory,
  }) {
    // Cancel any existing timer
    stopScheduledBackups();
    
    _frequency = frequency;
    _lastBackupTime = lastBackupTime;
    
    if (frequency == 'none') {
      return;
    }
    
    // Use provided path, or fall back to default near exe
    if (backupDirectory != null && backupDirectory.isNotEmpty) {
      _backupDirectory = backupDirectory;
    } else {
      _initializeBackupDirectory();
    }
    
    // Perform backup immediately if it's the first time or if enough time has passed
    _checkAndPerformBackup();
    
    // Set up periodic backup
    final duration = frequency == 'daily'
        ? const Duration(hours: 24)
        : const Duration(days: 7);
    
    _backupTimer = Timer.periodic(duration, (_) {
      _checkAndPerformBackup();
    });
  }

  /// Check if backup is needed and perform it
  Future<void> _checkAndPerformBackup() async {
    if (_frequency == 'none' || _backupDirectory == null) {
      return;
    }
    
    final now = DateTime.now();
    final shouldBackup = _lastBackupTime == null ||
        (_frequency == 'daily' &&
            _lastBackupTime!.isBefore(now.subtract(const Duration(hours: 24)))) ||
        (_frequency == 'weekly' &&
            _lastBackupTime!.isBefore(now.subtract(const Duration(days: 7))));
    
    if (shouldBackup) {
      await _performAutoBackup();
    }
  }

  /// Perform automatic backup
  Future<void> _performAutoBackup() async {
    try {
      final products = await _dbService.getAllProducts();
      final transactions = await _dbService.getAllTransactions();
      
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': AppConstants.appVersion,
        'products': products.map((p) => p.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };
      
      final jsonContent = _formatJson(backupData);
      final fileName = 'kasir_backup_$timestamp.json';
      final filePath = '$_backupDirectory/$fileName';
      
      await File(filePath).writeAsString(jsonContent);
      
      _lastBackupTime = DateTime.now();
      
      onBackupComplete?.call('Backup otomatis berhasil: $fileName');
    } catch (e) {
      onBackupError?.call('Gagal membuat backup otomatis: ${e.toString()}');
      debugPrint('Automatic backup error: $e');
    }
  }

  /// Format JSON with indentation
  String _formatJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// Stop scheduled backups
  void stopScheduledBackups() {
    _backupTimer?.cancel();
    _backupTimer = null;
  }

  /// Get backup directory
  String? getBackupDirectory() => _backupDirectory;

  /// Get list of backup files
  List<FileSystemEntity> getBackupFiles() {
    if (_backupDirectory == null) return [];
    
    try {
      final dir = Directory(_backupDirectory!);
      return dir
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    } catch (e) {
      debugPrint('Error reading backup files: $e');
      return [];
    }
  }

  /// Delete backup file
  Future<bool> deleteBackupFile(String filePath) async {
    try {
      await File(filePath).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }
}

class JsonEncoder {
  final String _indent;
  
  const JsonEncoder.withIndent(this._indent);
  
  String convert(dynamic data) {
    final buffer = StringBuffer();
    _writeValue(data, buffer, 0);
    return buffer.toString();
  }

  String _getIndent(int depth) {
    return _indent * depth;
  }
  
  void _writeValue(dynamic value, StringBuffer buffer, int depth) {
    if (value == null) {
      buffer.write('null');
    } else if (value is bool) {
      buffer.write(value);
    } else if (value is num) {
      buffer.write(value);
    } else if (value is String) {
      buffer.write('"');
      buffer.write(value.replaceAll('\\', '\\\\').replaceAll('"', '\\"'));
      buffer.write('"');
    } else if (value is List) {
      buffer.write('[\n');
      for (int i = 0; i < value.length; i++) {
        buffer.write(_getIndent(depth + 1));
        _writeValue(value[i], buffer, depth + 1);
        if (i < value.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write(_getIndent(depth));
      buffer.write(']');
    } else if (value is Map) {
      buffer.write('{\n');
      final entries = value.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        buffer.write(_getIndent(depth + 1));
        buffer.write('"${entries[i].key}": ');
        _writeValue(entries[i].value, buffer, depth + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write(_getIndent(depth));
      buffer.write('}');
    } else {
      buffer.write(value.toString());
    }
  }
}
