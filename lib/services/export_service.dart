import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../utils/formatters.dart';

class ExportService {
  /// Export transactions to PDF — same format as detail Excel (1 baris per transaksi)
  static Future<String?> exportToPDF(List<dynamic> transactions,
      DateTime startDate, DateTime endDate, {String? defaultPath}) async {
    // Hitung statistik
    double totalRevenue = 0, totalProfit = 0;
    int totalItemsCount = 0;
    for (var t in transactions) {
      if ((t.status ?? '') != 'completed') continue;
      totalRevenue += t.totalAmount ?? 0;
      if (t.items != null) {
        for (var item in t.items) {
          totalProfit += item.profitMargin * item.quantity;
          totalItemsCount += item.quantity as int;
        }
      }
    }
    final completedCount =
        transactions.where((t) => (t.status ?? '') == 'completed').length;

    // Build data rows — 1 transaksi 1 baris
    final completedTx =
        transactions.where((t) => (t.status ?? '') == 'completed').toList();
    final dataRows = completedTx.asMap().entries.map((entry) {
      final i = entry.key;
      final t = entry.value;
      final id =
          (t.id ?? '').length >= 8 ? t.id.substring(0, 8) : t.id ?? '';
      final tanggal =
          DateTimeFormatter.formatDate(t.transactionDate ?? DateTime.now());
      final jam = _formatTime(t.transactionDate ?? DateTime.now());
      String produkList = '-';
      int totalQty = 0;
      double profit = 0;
      if (t.items != null && t.items.isNotEmpty) {
        final parts = <String>[];
        for (var item in t.items) {
          parts.add('${item.productName} x${item.quantity}');
          totalQty += item.quantity as int;
          profit += item.profitMargin * item.quantity;
        }
        produkList = parts.join(', ');
      }
      return [
        (i + 1).toString(),
        id,
        tanggal,
        jam,
        produkList,
        totalQty.toString(),
        CurrencyFormatter.format(t.totalAmount ?? 0),
        CurrencyFormatter.format(profit),
        t.paymentMethod ?? '-',
        t.notes ?? '-',
      ];
    }).toList();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context ctx) => [
          pw.Text(
            'LAPORAN DETAIL PENJUALAN',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Periode: ${DateTimeFormatter.formatDate(startDate)} - ${DateTimeFormatter.formatDate(endDate)}',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            _pdfStatBox('Total Penjualan', CurrencyFormatter.format(totalRevenue)),
            pw.SizedBox(width: 8),
            _pdfStatBox('Total Keuntungan', CurrencyFormatter.format(totalProfit)),
            pw.SizedBox(width: 8),
            _pdfStatBox('Jumlah Transaksi', completedCount.toString()),
            pw.SizedBox(width: 8),
            _pdfStatBox('Total Item Terjual', totalItemsCount.toString()),
          ]),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: [
              'No', 'ID', 'Tanggal', 'Jam',
              'Produk (Nama x Qty)', 'Qty',
              'Total Penjualan', 'Keuntungan', 'Metode', 'Catatan',
            ],
            columnWidths: {
              0: pw.FixedColumnWidth(25),
              1: pw.FixedColumnWidth(55),
              2: pw.FixedColumnWidth(65),
              3: pw.FixedColumnWidth(32),
              4: pw.FlexColumnWidth(3),
              5: pw.FixedColumnWidth(28),
              6: pw.FixedColumnWidth(85),
              7: pw.FixedColumnWidth(80),
              8: pw.FixedColumnWidth(48),
              9: pw.FlexColumnWidth(1.5),
            },
            data: dataRows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: pw.TextStyle(fontSize: 7),
            cellHeight: 20,
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.3)),
            ),
          ),
        ],
      ),
    );

    String? savePath = defaultPath;
    if (savePath == null || savePath.isEmpty) {
      savePath = await FilePicker.getDirectoryPath();
    }

    if (savePath != null && savePath.isNotEmpty) {
      final fileName =
          'Laporan_Detail_Penjualan_${DateTime.now().toString().split(' ')[0]}.pdf';
      final filePath = '$savePath/$fileName';
      final fileBytes = await pdf.save();
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      return filePath;
    }
    return null;
  }

  /// Stat box untuk PDF
  static pw.Widget _pdfStatBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Export transactions to Excel file
  static Future<String?> exportToExcel(
      List<dynamic> transactions,
      DateTime startDate,
      DateTime endDate,
      {String? defaultPath}) async {
    // Create Excel file
    var excel = Excel.createExcel();
    final sheetObject = excel['Sheet1'];

    // Add header
    sheetObject.insertRowIterables(['LAPORAN RIWAYAT PENJUALAN'], 0);
    sheetObject.insertRowIterables(
        ['Periode: ${DateTimeFormatter.formatDate(startDate)} - ${DateTimeFormatter.formatDate(endDate)}'],
        1);

    // Add statistics
    double totalSales = 0;
    for (var transaction in transactions) {
      final status = transaction.status ?? '';
      if (status == 'completed') {
        totalSales += transaction.totalAmount ?? 0;
      }
    }
    int completedCount =
        transactions.where((t) => (t.status ?? '') == 'completed').length;

    sheetObject.insertRowIterables([''], 2);
    sheetObject.insertRowIterables(['Total Penjualan:', CurrencyFormatter.format(totalSales)], 3);
    sheetObject.insertRowIterables(['Jumlah Transaksi:', completedCount.toString()], 4);
    sheetObject.insertRowIterables([''], 5);

    // Add column headers
    sheetObject.insertRowIterables(
      ['No', 'ID Transaksi', 'Tanggal', 'Total', 'Metode Bayar', 'Status', 'Catatan'],
      6,
    );

    // Add data rows
    int rowIndex = 7;
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      final id = transaction.id?.substring(0, 8) ?? '';
      final totalAmount = transaction.totalAmount ?? 0;
      final status = transaction.status ?? '';
      final paymentMethod = transaction.paymentMethod ?? '-';
      final notes = transaction.notes ?? '-';
      
      sheetObject.insertRowIterables(
        [
          (i + 1).toString(),
          id,
          DateTimeFormatter.formatDate(transaction.transactionDate ?? DateTime.now()),
          totalAmount.toString(),
          paymentMethod,
          status,
          notes,
        ],
        rowIndex,
      );
      rowIndex++;
    }

    // Determine save location
    String? savePath = defaultPath;
    
    if (savePath == null || savePath.isEmpty) {
      savePath = await FilePicker.getDirectoryPath();
    }
    
    if (savePath != null && savePath.isNotEmpty) {
      final fileName =
          'Laporan_Penjualan_${DateTime.now().toString().split(' ')[0]}.xlsx';
      final filePath = '$savePath/$fileName';
      
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return filePath;
      }
    }
    return null;
  }

  /// Export transactions with detailed items to Excel file
  /// 1 transaksi = 1 baris, detail item digabung dalam kolom "Produk"
  static Future<String?> exportToExcelDetailed(
      List<dynamic> transactions,
      DateTime startDate,
      DateTime endDate,
      {String? defaultPath}) async {
    var excel = Excel.createExcel();
    final sheetObject = excel['Sheet1'];

    // Header title
    sheetObject.insertRowIterables(['LAPORAN DETAIL PENJUALAN'], 0);
    sheetObject.insertRowIterables(
        ['Periode: ${DateTimeFormatter.formatDate(startDate)} - ${DateTimeFormatter.formatDate(endDate)}'],
        1);

    // Hitung statistik
    double totalProfit = 0;
    double totalRevenue = 0;
    int totalItemsCount = 0;
    for (var transaction in transactions) {
      if ((transaction.status ?? '') != 'completed') continue;
      totalRevenue += transaction.totalAmount ?? 0;
      if (transaction.items != null) {
        for (var item in transaction.items) {
          totalProfit += (item.profitMargin * item.quantity);
          totalItemsCount += item.quantity as int;
        }
      }
    }
    final completedCount =
        transactions.where((t) => (t.status ?? '') == 'completed').length;

    sheetObject.insertRowIterables([''], 2);
    sheetObject.insertRowIterables(['Total Penjualan:', CurrencyFormatter.format(totalRevenue)], 3);
    sheetObject.insertRowIterables(['Total Keuntungan:', CurrencyFormatter.format(totalProfit)], 4);
    sheetObject.insertRowIterables(['Total Transaksi:', completedCount.toString()], 5);
    sheetObject.insertRowIterables(['Total Item Terjual:', totalItemsCount.toString()], 6);
    sheetObject.insertRowIterables([''], 7);

    // Kolom header
    sheetObject.insertRowIterables(
      [
        'No',
        'ID Transaksi',
        'Tanggal',
        'Jam',
        'Produk (Nama x Qty)',
        'Total Item',
        'Total Penjualan',
        'Total Keuntungan',
        'Metode Bayar',
        'Status',
        'Catatan',
      ],
      8,
    );

    // Baris data — 1 transaksi 1 baris
    int rowIndex = 9;
    int no = 1;

    for (var transaction in transactions) {
      if ((transaction.status ?? '') != 'completed') continue;

      final orderId = (transaction.id ?? '').length >= 8
          ? transaction.id.substring(0, 8)
          : transaction.id ?? '';
      final tanggal = DateTimeFormatter.formatDate(
          transaction.transactionDate ?? DateTime.now());
      final jam = _formatTime(transaction.transactionDate ?? DateTime.now());
      final metode = transaction.paymentMethod ?? '-';
      final catatan = transaction.notes ?? '-';

      // Gabungkan semua item menjadi satu string
      String produkList = '-';
      int totalQty = 0;
      double profit = 0;

      if (transaction.items != null && transaction.items.isNotEmpty) {
        final parts = <String>[];
        for (var item in transaction.items) {
          parts.add('${item.productName} x${item.quantity}');
          totalQty += item.quantity as int;
          profit += item.profitMargin * item.quantity;
        }
        produkList = parts.join(', ');
      }

      sheetObject.insertRowIterables(
        [
          no.toString(),
          orderId,
          tanggal,
          jam,
          produkList,
          totalQty.toString(),
          CurrencyFormatter.format(transaction.totalAmount ?? 0),
          CurrencyFormatter.format(profit),
          metode,
          transaction.status ?? '',
          catatan,
        ],
        rowIndex,
      );
      rowIndex++;
      no++;
    }

    // Simpan file
    String? savePath = defaultPath;
    if (savePath == null || savePath.isEmpty) {
      savePath = await FilePicker.getDirectoryPath();
    }

    if (savePath != null && savePath.isNotEmpty) {
      final fileName =
          'Laporan_Detail_Penjualan_${DateTime.now().toString().split(' ')[0]}.xlsx';
      final filePath = '$savePath/$fileName';
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        return filePath;
      }
    }
    return null;
  }

  /// Helper function to format time
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
