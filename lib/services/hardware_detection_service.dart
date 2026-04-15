import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DeviceModel {
  final String type; // 'scanner', 'printer', 'cashdrawer'
  final String name;
  final bool connected;
  final String? details;
  final DateTime lastChecked;

  DeviceModel({
    required this.type,
    required this.name,
    required this.connected,
    this.details,
    required this.lastChecked,
  });

  @override
  String toString() =>
      '$name ($type): ${connected ? "Connected" : "Disconnected"}';
}

class HardwareDetectionService {
  static final HardwareDetectionService _instance =
      HardwareDetectionService._internal();

  factory HardwareDetectionService() {
    return _instance;
  }

  HardwareDetectionService._internal();

  Timer? _scanTimer;
  List<DeviceModel> _devices = [];

  List<DeviceModel> get devices => _devices;

  /// Start continuous device detection
  void startDetection({Duration interval = const Duration(seconds: 5)}) {
    // Initial scan
    _scanDevices();

    // Periodic scan
    _scanTimer = Timer.periodic(interval, (_) {
      _scanDevices();
    });
  }

  /// Stop device detection
  void stopDetection() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  /// Scan all devices
  Future<void> _scanDevices() async {
    try {
      final devices = <DeviceModel>[];

      // Scan USB Devices (including scanner and cash drawer)
      devices.addAll(await _scanUSBDevices());

      // Scan Printers
      devices.addAll(await _scanPrinters());

      _devices = devices;
    } catch (e) {
      debugPrint('Error scanning devices: $e');
    }
  }

  /// Scan USB devices for scanner and cash drawer
  Future<List<DeviceModel>> _scanUSBDevices() async {
    final devices = <DeviceModel>[];

    // Hanya untuk Windows
    if (!Platform.isWindows) {
      return devices;
    }

    try {
      // Scan USB mass storage devices (scanner)
      final scannerProcess = await Process.run('powershell', [
        '-Command',
        r'''Get-WmiObject Win32_USBDevice | Where-Object {$_.Description -match 'scanner|barcode'} | Select-Object Description, PNPDeviceID | ConvertTo-Json''',
      ]);

      if (scannerProcess.stdout.toString().isNotEmpty &&
          scannerProcess.stdout.toString() != '{}') {
        devices.add(
          DeviceModel(
            type: 'scanner',
            name: 'Scanner Barcode',
            connected: true,
            details: 'USB Scanner Barcode Detected',
            lastChecked: DateTime.now(),
          ),
        );
      } else {
        devices.add(
          DeviceModel(
            type: 'scanner',
            name: 'Scanner Barcode',
            connected: false,
            details: 'Tidak terhubung',
            lastChecked: DateTime.now(),
          ),
        );
      }

      // Scan USB serial devices (cash drawer)
      final drawerProcess = await Process.run('powershell', [
        '-Command',
        r'''Get-WmiObject Win32_SerialPort | Select-Object Name, Description | ConvertTo-Json''',
      ]);

      if (drawerProcess.stdout.toString().isNotEmpty &&
          drawerProcess.stdout.toString() != '{}') {
        devices.add(
          DeviceModel(
            type: 'cashdrawer',
            name: 'Laci Kasi',
            connected: true,
            details: 'USB Cash Drawer Detected',
            lastChecked: DateTime.now(),
          ),
        );
      } else {
        devices.add(
          DeviceModel(
            type: 'cashdrawer',
            name: 'Laci Kasi',
            connected: false,
            details: 'Tidak terhubung',
            lastChecked: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error scanning USB devices: $e');
      // Add default disconnected devices if scan fails
      devices.addAll([
        DeviceModel(
          type: 'scanner',
          name: 'Scanner Barcode',
          connected: false,
          details: 'Tidak terhubung atau tidak terdeteksi',
          lastChecked: DateTime.now(),
        ),
        DeviceModel(
          type: 'cashdrawer',
          name: 'Laci Kasi',
          connected: false,
          details: 'Tidak terhubung atau tidak terdeteksi',
          lastChecked: DateTime.now(),
        ),
      ]);
    }

    return devices;
  }

  /// Scan printers
  Future<List<DeviceModel>> _scanPrinters() async {
    final devices = <DeviceModel>[];

    if (!Platform.isWindows) {
      return devices;
    }

    try {
      final printerProcess = await Process.run('powershell', [
        '-Command',
        r'''Get-WmiObject Win32_Printer | Where-Object {$_.Description -match 'thermal|receipt|pos' -or $_.Name -match 'thermal|receipt|pos'} | Select-Object Name, Default, DriverName, PortName | ConvertTo-Json''',
      ]);

      if (printerProcess.stdout.toString().isNotEmpty &&
          printerProcess.stdout.toString() != '{}') {
        final printers = _parsePrinterEntries(printerProcess.stdout.toString());

        if (printers.isNotEmpty) {
          final printer = printers.firstWhere(
            (entry) => entry['default'] == true,
            orElse: () => printers.first,
          );

          final printerName = (printer['name'] as String?)?.trim();
          final driverName = (printer['driverName'] as String?)?.trim();
          final portName = (printer['portName'] as String?)?.trim();

          devices.add(
            DeviceModel(
              type: 'printer',
              name: printerName?.isNotEmpty == true
                  ? printerName!
                  : 'Thermal Printer',
              connected: true,
              details: [driverName, portName]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' • ')
                  .ifEmpty('Thermal Printer Detected'),
              lastChecked: DateTime.now(),
            ),
          );
        } else {
          devices.add(
            DeviceModel(
              type: 'printer',
              name: 'Thermal Printer',
              connected: true,
              details: 'Thermal Printer Detected',
              lastChecked: DateTime.now(),
            ),
          );
        }
      } else {
        devices.add(
          DeviceModel(
            type: 'printer',
            name: 'Thermal Printer',
            connected: false,
            details: 'Tidak terhubung',
            lastChecked: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error scanning printers: $e');
      devices.add(
        DeviceModel(
          type: 'printer',
          name: 'Thermal Printer',
          connected: false,
          details: 'Tidak terhubung atau tidak terdeteksi',
          lastChecked: DateTime.now(),
        ),
      );
    }

    return devices;
  }

  List<Map<String, dynamic>> _parsePrinterEntries(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
      }

      if (decoded is Map) {
        return [decoded.map((key, value) => MapEntry(key.toString(), value))];
      }
    } catch (e) {
      debugPrint('Error parsing printer data: $e');
    }

    return const [];
  }

  /// Get device connection status summary
  Map<String, bool> getConnectionStatus() {
    final status = <String, bool>{};
    for (var device in _devices) {
      status[device.type] = device.connected;
    }
    return status;
  }

  /// Get specific device
  DeviceModel? getDevice(String type) {
    try {
      return _devices.firstWhere((d) => d.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Check if all devices are connected
  bool get allDevicesConnected =>
      _devices.isNotEmpty && _devices.every((d) => d.connected);

  /// Check if any device is connected
  bool get anyDeviceConnected =>
      _devices.isNotEmpty && _devices.any((d) => d.connected);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
