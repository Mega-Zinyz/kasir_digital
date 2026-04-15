import 'package:flutter/material.dart';
import 'dart:io';
import '../models/store_profile.dart';

class SettingsProvider extends ChangeNotifier {
  int _lowStockThreshold = 5; // Default value
  String _exportPath = ''; // Default empty, will use file picker
  String _backupPath = ''; // Default empty, auto-created
  String _backupFrequency = 'none'; // none, daily, weekly
  DateTime? _lastBackupTime;
  bool _isFullscreen = true; // Fullscreen by default
  StoreProfile _storeProfile = StoreProfile(
    name: 'Toko Kasir Digital',
    phone: '08xxxxxxxxxx',
    address: 'Jl. Contoh No. 123',
  );

  int get lowStockThreshold => _lowStockThreshold;
  String get exportPath => _exportPath;
  String get backupPath => _backupPath;
  String get backupFrequency => _backupFrequency;
  DateTime? get lastBackupTime => _lastBackupTime;
  bool get isFullscreen => _isFullscreen;
  StoreProfile get storeProfile => _storeProfile;

  SettingsProvider() {
    _initializePaths();
  }

  // Initialize all default paths (export, backup) and create folders
  Future<void> _initializePaths() async {
    try {
      // Get the directory where the executable is located
      final exePath = Platform.resolvedExecutable;
      final appDirectory = File(exePath).parent.path;
      
      // Create "Laporan" folder for exports
      final reportFolder = Directory('$appDirectory/Laporan');
      if (!reportFolder.existsSync()) {
        reportFolder.createSync(recursive: true);
      }
      _exportPath = reportFolder.path;
      
      // Create "Backup" folder for auto-backups
      final backupFolder = Directory('$appDirectory/Backup');
      if (!backupFolder.existsSync()) {
        backupFolder.createSync(recursive: true);
      }
      _backupPath = backupFolder.path;
      
      notifyListeners();
      debugPrint('SettingsProvider: Initialized paths');
      debugPrint('  Export path: $_exportPath');
      debugPrint('  Backup path: $_backupPath');
    } catch (e) {
      debugPrint('Error initializing paths: $e');
      _exportPath = '';
      _backupPath = '';
    }
  }

  // Set low stock threshold
  void setLowStockThreshold(int threshold) {
    if (threshold > 0) {
      _lowStockThreshold = threshold;
      notifyListeners();
    }
  }

  // Get low stock threshold
  int getLowStockThreshold() => _lowStockThreshold;

  // Set export path
  void setExportPath(String path) {
    _exportPath = path;
    notifyListeners();
  }

  // Get export path
  String getExportPath() => _exportPath;

  // Set backup path
  void setBackupPath(String path) {
    _backupPath = path;
    notifyListeners();
  }

  // Get backup path
  String getBackupPath() => _backupPath;

  // Set backup frequency
  void setBackupFrequency(String frequency) {
    if (['none', 'daily', 'weekly'].contains(frequency)) {
      _backupFrequency = frequency;
      notifyListeners();
    }
  }

  // Set last backup time
  void setLastBackupTime(DateTime time) {
    _lastBackupTime = time;
    notifyListeners();
  }

  // Update store profile
  void updateStoreProfile({
    String? name,
    String? phone,
    String? address,
  }) {
    _storeProfile = _storeProfile.copyWith(
      name: name,
      phone: phone,
      address: address,
    );
    notifyListeners();
  }

  // Update store name
  void setStoreName(String name) {
    _storeProfile = _storeProfile.copyWith(name: name);
    notifyListeners();
  }

  // Update store phone
  void setStorePhone(String phone) {
    _storeProfile = _storeProfile.copyWith(phone: phone);
    notifyListeners();
  }

  // Update store address
  void setStoreAddress(String address) {
    _storeProfile = _storeProfile.copyWith(address: address);
    notifyListeners();
  }

  // Toggle fullscreen mode
  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  // Set fullscreen mode
  void setFullscreen(bool value) {
    _isFullscreen = value;
    notifyListeners();
  }
}
