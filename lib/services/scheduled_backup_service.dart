import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'backup_service.dart';

class ScheduledBackupService {
  late Timer? _backupTimer;
  final BackupService _backupService = BackupService();
  
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
      final filePath = await _backupService.exportDatabase(
        defaultPath: _backupDirectory,
      );

      if (filePath == null || filePath.isEmpty) {
        throw Exception('Path backup otomatis tidak tersedia');
      }
      
      _lastBackupTime = DateTime.now();

      final fileName = filePath.split(Platform.pathSeparator).last;
      onBackupComplete?.call('Backup otomatis berhasil: $fileName');
    } catch (e) {
      onBackupError?.call('Gagal membuat backup otomatis: ${e.toString()}');
      debugPrint('Automatic backup error: $e');
    }
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
