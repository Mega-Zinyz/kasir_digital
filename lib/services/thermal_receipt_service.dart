import 'dart:io';

import 'package:intl/intl.dart';

import '../models/store_profile.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../utils/formatters.dart';

class ThermalPrintResult {
  final bool success;
  final String message;

  const ThermalPrintResult({required this.success, required this.message});
}

class ThermalReceiptService {
  static const int _paperWidth = 32;

  String buildReceiptPreview({
    required StoreProfile storeProfile,
    required SalesTransaction transaction,
    required List<TransactionItem> items,
  }) {
    return _buildReceiptContent(
      storeProfile: storeProfile,
      transaction: transaction,
      items: items,
    );
  }

  Future<File> saveReceiptCopy({
    required StoreProfile storeProfile,
    required SalesTransaction transaction,
    required List<TransactionItem> items,
    String? outputDirectory,
  }) async {
    final baseDirectory = outputDirectory != null && outputDirectory.trim().isNotEmpty
        ? Directory(outputDirectory)
        : await Directory.systemTemp.createTemp('kasir_receipt_export_');

    if (!baseDirectory.existsSync()) {
      baseDirectory.createSync(recursive: true);
    }

    final receiptDirectory = Directory('${baseDirectory.path}/Struk');
    if (!receiptDirectory.existsSync()) {
      receiptDirectory.createSync(recursive: true);
    }

    final fileName =
        'receipt-${DateFormat('yyyyMMdd-HHmmss').format(transaction.transactionDate)}-${transaction.id.substring(0, 8)}.txt';
    final receiptFile = File('${receiptDirectory.path}/$fileName');
    await receiptFile.writeAsString(
      _buildReceiptContent(
        storeProfile: storeProfile,
        transaction: transaction,
        items: items,
      ),
    );

    return receiptFile;
  }

  Future<ThermalPrintResult> printPaymentReceipt({
    required StoreProfile storeProfile,
    required SalesTransaction transaction,
    required List<TransactionItem> items,
    String? printerName,
  }) async {
    if (!Platform.isWindows) {
      return const ThermalPrintResult(
        success: false,
        message: 'Cetak thermal saat ini hanya didukung di Windows.',
      );
    }

    final resolvedPrinter = await _resolvePrinterName(printerName);
    if (resolvedPrinter == null || resolvedPrinter.isEmpty) {
      return const ThermalPrintResult(
        success: false,
        message: 'Printer thermal tidak ditemukan.',
      );
    }

    final receiptFile = await _writeReceiptFile(
      storeProfile: storeProfile,
      transaction: transaction,
      items: items,
    );

    try {
      final printProcess = await Process.run('powershell', [
        '-Command',
        r'''$path = $args[0]; $printer = $args[1]; Get-Content -Path $path | Out-Printer -Name $printer''',
        receiptFile.path,
        resolvedPrinter,
      ]);

      if (printProcess.exitCode != 0) {
        return ThermalPrintResult(
          success: false,
          message: printProcess.stderr.toString().trim().isNotEmpty
              ? printProcess.stderr.toString().trim()
              : 'Gagal mencetak ke printer thermal.',
        );
      }

      return ThermalPrintResult(
        success: true,
        message: 'Struk berhasil dikirim ke $resolvedPrinter.',
      );
    } catch (e) {
      return ThermalPrintResult(
        success: false,
        message: 'Gagal mencetak struk: $e',
      );
    }
  }

  Future<String?> _resolvePrinterName(String? preferredPrinterName) async {
    if (preferredPrinterName != null &&
        preferredPrinterName.isNotEmpty &&
        preferredPrinterName != 'Thermal Printer') {
      return preferredPrinterName;
    }

    try {
      final printerProcess = await Process.run('powershell', [
        '-Command',
        r'''$printers = Get-WmiObject Win32_Printer | Where-Object {$_.Description -match 'thermal|receipt|pos' -or $_.Name -match 'thermal|receipt|pos'} | Select-Object Name, Default | ConvertTo-Json; Write-Output $printers''',
      ]);

      final rawOutput = printerProcess.stdout.toString().trim();
      if (rawOutput.isEmpty || rawOutput == '{}') {
        return null;
      }

      final normalized = rawOutput.startsWith('[') ? rawOutput : '[$rawOutput]';

      final tempFile = File('${Directory.systemTemp.path}/kasir_printers.json');
      await tempFile.writeAsString(normalized);
      final content = await tempFile.readAsString();
      final entries = _parsePrinterLines(content);
      if (entries.isEmpty) {
        return null;
      }

      final preferred = entries.where((entry) => entry['default'] == 'true');
      return (preferred.isNotEmpty ? preferred.first : entries.first)['name'];
    } catch (_) {
      return null;
    }
  }

  List<Map<String, String>> _parsePrinterLines(String rawJson) {
    final cleaned = rawJson.trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    final rows = <Map<String, String>>[];
    final nameRegex = RegExp(r'"Name"\s*:\s*"([^"]+)"');
    final defaultRegex = RegExp(r'"Default"\s*:\s*(true|false)');
    final objectRegex = RegExp(r'\{[^\}]+\}', multiLine: true);
    final matches = objectRegex.allMatches(cleaned);

    for (final match in matches) {
      final segment = match.group(0) ?? '';
      final nameMatch = nameRegex.firstMatch(segment);
      final defaultMatch = defaultRegex.firstMatch(segment);
      if (nameMatch != null) {
        rows.add({
          'name': nameMatch.group(1) ?? '',
          'default': defaultMatch?.group(1) ?? 'false',
        });
      }
    }

    if (rows.isEmpty) {
      final nameMatch = nameRegex.firstMatch(cleaned);
      final defaultMatch = defaultRegex.firstMatch(cleaned);
      if (nameMatch != null) {
        rows.add({
          'name': nameMatch.group(1) ?? '',
          'default': defaultMatch?.group(1) ?? 'false',
        });
      }
    }

    return rows.where((row) => (row['name'] ?? '').isNotEmpty).toList();
  }

  Future<File> _writeReceiptFile({
    required StoreProfile storeProfile,
    required SalesTransaction transaction,
    required List<TransactionItem> items,
  }) async {
    return saveReceiptCopy(
      storeProfile: storeProfile,
      transaction: transaction,
      items: items,
    );
  }

  String _buildReceiptContent({
    required StoreProfile storeProfile,
    required SalesTransaction transaction,
    required List<TransactionItem> items,
  }) {
    final lines = <String>[
      _center(storeProfile.name),
      if (storeProfile.address.trim().isNotEmpty)
        ..._wrapCentered(storeProfile.address.trim()),
      if (storeProfile.phone.trim().isNotEmpty)
        _center('Telp: ${storeProfile.phone.trim()}'),
      _divider(),
      'No  : ${transaction.id.substring(0, 8).toUpperCase()}',
      'Tgl : ${DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(transaction.transactionDate)}',
      'Byr : ${transaction.paymentMethod.toUpperCase()}',
      _divider(),
      ...items.expand(_buildItemLines),
      _divider(),
      _pair('TOTAL', CurrencyFormatter.format(transaction.totalAmount)),
      _pair('BAYAR', CurrencyFormatter.format(transaction.paymentAmount)),
      _pair('KEMBALI', CurrencyFormatter.format(transaction.changeAmount)),
      _divider(),
      _center('Terima kasih'),
      _center('Semoga belanja Anda menyenangkan'),
      '',
      '',
      '',
    ];

    return '${lines.join('\r\n')}\r\n';
  }

  List<String> _buildItemLines(TransactionItem item) {
    final lines = <String>[];
    lines.addAll(_wrapText(item.productName));
    lines.add(
      _pair(
        '${item.quantity} x ${CurrencyFormatter.format(item.price)}',
        CurrencyFormatter.format(item.subtotal),
      ),
    );
    return lines;
  }

  String _pair(String left, String right) {
    final maxLeft = _paperWidth - right.length - 1;
    final trimmedLeft = left.length > maxLeft
        ? '${left.substring(0, maxLeft - 1)}…'
        : left;
    final spaces = (_paperWidth - trimmedLeft.length - right.length).clamp(
      1,
      _paperWidth,
    );
    return '$trimmedLeft${' ' * spaces}$right';
  }

  String _center(String text) {
    final trimmed = text.length > _paperWidth
        ? text.substring(0, _paperWidth)
        : text;
    final leftPadding = ((_paperWidth - trimmed.length) / 2).floor().clamp(
      0,
      _paperWidth,
    );
    return '${' ' * leftPadding}$trimmed';
  }

  List<String> _wrapCentered(String text) =>
      _wrapText(text).map(_center).toList();

  List<String> _wrapText(String text) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      final candidate = current.isEmpty ? word : '$current $word';
      if (candidate.length <= _paperWidth) {
        current = candidate;
      } else {
        if (current.isNotEmpty) {
          lines.add(current);
        }
        current = word;
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }

    return lines.isEmpty ? [''] : lines;
  }

  String _divider() => '-' * _paperWidth;
}
