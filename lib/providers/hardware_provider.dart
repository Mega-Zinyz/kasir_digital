import 'package:flutter/material.dart';
import '../services/hardware_detection_service.dart';

class HardwareProvider extends ChangeNotifier {
  final HardwareDetectionService _detectionService = HardwareDetectionService();
  
  List<DeviceModel> _devices = [];
  bool _isScanning = false;

  List<DeviceModel> get devices => _devices;
  bool get isScanning => _isScanning;

  HardwareProvider() {
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    // Start hardware detection
    _detectionService.startDetection(interval: const Duration(seconds: 5));
    
    // Initial scan
    await refreshDevices();
  }

  /// Refresh device list
  Future<void> refreshDevices() async {
    _isScanning = true;
    notifyListeners();

    try {
      // Perform scan
      _devices = _detectionService.devices;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing devices: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Get device by type
  DeviceModel? getDevice(String type) {
    try {
      return _devices.firstWhere((d) => d.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get scanner status
  DeviceModel? get scanner => getDevice('scanner');

  /// Get printer status
  DeviceModel? get printer => getDevice('printer');

  /// Get cash drawer status
  DeviceModel? get cashDrawer => getDevice('cashdrawer');

  /// Check if all devices are connected
  bool get allDevicesConnected =>
      _devices.isNotEmpty && _devices.every((d) => d.connected);

  /// Get connected devices count
  int get connectedDevicesCount =>
      _devices.where((d) => d.connected).length;

  /// Get total devices count
  int get totalDevicesCount => _devices.length;

  /// Get connection status percentage
  int get connectionPercentage {
    if (_devices.isEmpty) return 0;
    return ((connectedDevicesCount / totalDevicesCount) * 100).toInt();
  }

  /// Test device connection
  Future<bool> testDeviceConnection(String deviceType) async {
    try {
      final device = getDevice(deviceType);
      if (device == null) return false;
      
      // Simulate test (in real implementation, would test actual connection)
      await Future.delayed(const Duration(milliseconds: 500));
      
      return device.connected;
    } catch (e) {
      debugPrint('Error testing device: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _detectionService.stopDetection();
    super.dispose();
  }
}
