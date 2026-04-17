import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../utils/formatters.dart';
import '../../widgets/index.dart';
import '../../models/index.dart';
import '../../services/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int _currentPage = 0;
  static const int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, now.month, 1);
    // Set end date ke end of day (23:59:59) agar include semua transaksi hari ini
    _selectedEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    Future.microtask(() {
      if (mounted) {
        // Load all transactions by default
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Penjualan')),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHighest : cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Tanggal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _selectedStartDate != null
                                    ? DateTimeFormatter.formatDate(
                                        _selectedStartDate!,
                                      )
                                    : 'Mulai',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('-'),
                    SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _selectedEndDate != null
                                    ? DateTimeFormatter.formatDate(
                                        _selectedEndDate!,
                                      )
                                    : 'Akhir',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                PrimaryButton(
                  label: 'Tampilkan',
                  onPressed: () {
                    if (_selectedStartDate != null &&
                        _selectedEndDate != null) {
                      setState(() {
                        _currentPage = 0;
                      });
                      // Normalize dates untuk query
                      final startDate = DateTime(
                        _selectedStartDate!.year,
                        _selectedStartDate!.month,
                        _selectedStartDate!.day,
                        0,
                        0,
                        0, // 00:00:00
                      );
                      final endDate = DateTime(
                        _selectedEndDate!.year,
                        _selectedEndDate!.month,
                        _selectedEndDate!.day,
                        23,
                        59,
                        59, // 23:59:59
                      );
                      context
                          .read<TransactionProvider>()
                          .loadTransactionsByDateRange(startDate, endDate);
                    }
                  },
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportToPDF(context),
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Consumer<SettingsProvider>(
                      builder: (ctx, settings, _) {
                        final exportPath = settings.getExportPath();
                        return Tooltip(
                          message: exportPath.isEmpty
                              ? 'Atur lokasi laporan di Settings terlebih dahulu'
                              : 'Buka Folder Laporan',
                          child: ElevatedButton(
                            onPressed: exportPath.isNotEmpty
                                ? () => _openFolder(exportPath)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? cs.primaryContainer
                                  : cs.primary.withValues(alpha: 0.08),
                              foregroundColor: isDark
                                  ? cs.onPrimaryContainer
                                  : cs.primary,
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size(0, 36),
                            ),
                            child: Icon(Icons.folder_open, size: 20),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showExportDialog(context),
                        icon: Icon(Icons.table_chart),
                        label: Text('Export Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.secondary,
                          foregroundColor: cs.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics
          Padding(
            padding: EdgeInsets.all(16),
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                double totalProfit = 0;
                int totalTransactions = 0;

                // Hitung total profit dari semua items di semua transaksi
                for (var transaction in transactionProvider.transactions) {
                  if (transaction.status == 'completed') {
                    totalTransactions++;
                    // Hitung profit dari setiap item dalam transaksi
                    for (var item in transaction.items) {
                      totalProfit += (item.profitMargin * item.quantity);
                    }
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Profit',
                        value: CurrencyFormatter.format(totalProfit),
                        icon: Icons.trending_up,
                        iconColor: cs.secondary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        title: 'Transaksi',
                        value: totalTransactions.toString(),
                        icon: Icons.receipt_long,
                        iconColor: cs.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Transactions table/list - Responsive
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                if (transactionProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final transactions = transactionProvider.transactions
                    .where((t) => t.status == 'completed')
                    .toList();

                final totalPages = transactions.isEmpty
                    ? 1
                    : (transactions.length / _itemsPerPage).ceil();
                final safePage = _currentPage.clamp(0, totalPages - 1);
                final pageTransactions = transactions
                    .skip(safePage * _itemsPerPage)
                    .take(_itemsPerPage)
                    .toList();

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada data transaksi',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final isMobile = MediaQuery.of(context).size.width < 800;

                if (isMobile) {
                  // Mobile view: Card list
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(12),
                          itemCount: pageTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = pageTransactions[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _showTransactionDetails(
                                  context,
                                  transaction,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'No: ${transaction.id.substring(0, 8)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  DateTimeFormatter.formatDateTime(
                                                    transaction.transactionDate,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(
                                              transaction.totalAmount,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: cs.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Divider(),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total: ${CurrencyFormatter.format(transaction.totalAmount)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () =>
                                                    _showTransactionDetails(
                                                      context,
                                                      transaction,
                                                    ),
                                                icon: Icon(Icons.visibility),
                                                iconSize: 22,
                                                tooltip: 'Lihat Detail',
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    _showDeleteConfirmation(
                                                      context,
                                                      transaction,
                                                    ),
                                                icon: Icon(Icons.delete),
                                                iconSize: 22,
                                                color: Colors.red,
                                                tooltip: 'Hapus',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _buildPaginationBar(
                        safePage,
                        totalPages,
                        transactions.length,
                      ),
                    ],
                  );
                } else {
                  // Desktop view: Responsive table
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? cs.primaryContainer
                                : cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: cs.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Detail',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? cs.onPrimaryContainer
                                        : cs.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'No Transaksi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? cs.onPrimaryContainer
                                        : cs.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? cs.onPrimaryContainer
                                        : cs.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Jumlah',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? cs.onPrimaryContainer
                                        : cs.primary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? cs.onPrimaryContainer
                                        : cs.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table Body
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: pageTransactions.asMap().entries.map((
                                entry,
                              ) {
                                int index = entry.key;
                                final transaction = entry.value;
                                final isOddRow = index.isOdd;

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOddRow
                                        ? (isDark
                                              ? cs.surfaceContainerLow
                                              : cs.primary.withValues(
                                                  alpha: 0.025,
                                                ))
                                        : cs.surface,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: cs.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Tooltip(
                                            message: 'Lihat Detail',
                                            child: IconButton(
                                              onPressed: () =>
                                                  _showTransactionDetails(
                                                    context,
                                                    transaction,
                                                  ),
                                              icon: Icon(Icons.visibility),
                                              iconSize: 18,
                                              constraints: BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          transaction.id.substring(0, 8),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          DateTimeFormatter.formatDateTime(
                                            transaction.transactionDate,
                                          ),
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          CurrencyFormatter.format(
                                            transaction.totalAmount,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: cs.secondary,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Tooltip(
                                            message: 'Hapus',
                                            child: IconButton(
                                              onPressed: () =>
                                                  _showDeleteConfirmation(
                                                    context,
                                                    transaction,
                                                  ),
                                              icon: Icon(Icons.delete),
                                              iconSize: 18,
                                              color: Colors.red,
                                              constraints: BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        _buildPaginationBar(
                          safePage,
                          totalPages,
                          transactions.length,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _selectedStartDate ?? DateTime.now()
          : _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          // Set ke awal hari (00:00:00)
          _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
          // Validasi: jika start date > end date, update end date
          if (_selectedEndDate != null &&
              _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedEndDate = DateTime(
              _selectedStartDate!.year,
              _selectedStartDate!.month,
              _selectedStartDate!.day,
              23,
              59,
              59,
            );
          }
        } else {
          // Set ke akhir hari (23:59:59)
          _selectedEndDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
          // Validasi: jika end date < start date, update start date
          if (_selectedStartDate != null &&
              _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedStartDate = DateTime(
              _selectedEndDate!.year,
              _selectedEndDate!.month,
              _selectedEndDate!.day,
            );
          }
        }
      });
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    SalesTransaction transaction,
  ) {
    final dbService = context.read<TransactionProvider>();
    final buildContext = context;
    dbService.getTransactionDetails(transaction.id).then((details) {
      if (details != null && buildContext.mounted) {
        showDialog(
          context: buildContext,
          builder: (context) => Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Transaksi',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    _DetailRow('No Transaksi', transaction.id.substring(0, 12)),
                    _DetailRow(
                      'Tanggal',
                      DateTimeFormatter.formatDateTime(
                        transaction.transactionDate,
                      ),
                    ),
                    Divider(),
                    Text(
                      'Item Penjualan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final items =
                            details['items'] as List<TransactionItem>?;
                        final productProvider = context.read<ProductProvider>();
                        final expiryDateMap = {
                          for (final p in productProvider.products)
                            p.id: p.expiryDate,
                        };

                        if (items == null || items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'Tidak ada item dalam transaksi ini',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: items.map((item) {
                            final expiryDate = expiryDateMap[item.productId];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product name
                                    Text(
                                      item.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    // Quantity and price
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.quantity}x',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Harga: ${CurrencyFormatter.format(item.price)}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(
                                            item.subtotal,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Modal/unit: ${CurrencyFormatter.format(item.costPrice)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Modal total: ${CurrencyFormatter.format(item.costPrice * item.quantity)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (expiryDate != null) ...[
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Exp: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.tertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: 8),
                                    Divider(height: 1),
                                    SizedBox(height: 8),
                                    // Total profit for this item
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Profit: ${CurrencyFormatter.format(item.profitMargin * item.quantity)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    Divider(),
                    _DetailRow(
                      'Total',
                      CurrencyFormatter.format(transaction.totalAmount),
                      isBold: true,
                    ),
                    _DetailRow(
                      'Pembayaran',
                      CurrencyFormatter.format(transaction.paymentAmount),
                      isBold: true,
                    ),
                    _DetailRow(
                      'Kembalian',
                      CurrencyFormatter.format(transaction.changeAmount),
                      isBold: true,
                    ),
                    SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Tutup',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  void _showDeleteConfirmation(
    BuildContext context,
    SalesTransaction transaction,
  ) {
    final settingsProvider = context.read<SettingsProvider>();

    if (!settingsProvider.hasHistoryDeletePin) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PIN Admin Belum Diatur'),
          content: const Text(
            'Atur PIN hapus history di menu Pengaturan sebelum menghapus transaksi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    final pinController = TextEditingController();
    String? pinError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan PIN admin untuk menghapus transaksi ${transaction.id.substring(0, 8)}.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN Admin',
                  border: const OutlineInputBorder(),
                  errorText: pinError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (!settingsProvider.verifyHistoryDeletePin(pinController.text)) {
                  setDialogState(() {
                    pinError = 'PIN admin tidak valid';
                  });
                  return;
                }

                final buildContext = context;
                Navigator.pop(context);
                if (!buildContext.mounted) return;
                try {
                  await buildContext
                      .read<TransactionProvider>()
                      .deleteTransaction(transaction.id);
                  if (buildContext.mounted) {
                    ScaffoldMessenger.of(buildContext).showSnackBar(
                      const SnackBar(content: Text('Transaksi berhasil dihapus')),
                    );
                  }
                } catch (e) {
                  if (buildContext.mounted) {
                    ScaffoldMessenger.of(buildContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Theme.of(buildContext).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Hapus',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      final transactions = context
          .read<TransactionProvider>()
          .transactions
          .where((t) => t.status == 'completed')
          .toList();

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data untuk diexport')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Membuat PDF...')));

      final filePath = await ExportService.exportToPDF(
        transactions,
        _selectedStartDate ?? DateTime.now(),
        _selectedEndDate ?? DateTime.now(),
        defaultPath: context.read<SettingsProvider>().getExportPath(),
      );

      if (context.mounted) {
        _showFileOpenSnackBar(context, filePath, 'PDF');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Format Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Export Basic'),
                subtitle: Text(
                  'Format sederhana (ID Transaksi, Tanggal, Total)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel(context);
                },
              ),
              Divider(),
              ListTile(
                title: Text('Export Detail'),
                subtitle: Text(
                  'Format detail per item (dengan Profit, Harga Beli, dll)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcelDetailed(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToExcelDetailed(BuildContext context) async {
    try {
      final transactions = context
          .read<TransactionProvider>()
          .transactions
          .where((t) => t.status == 'completed')
          .toList();

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data untuk diexport')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Membuat Excel Detail...')));

      final filePath = await ExportService.exportToExcelDetailed(
        transactions,
        _selectedStartDate ?? DateTime.now(),
        _selectedEndDate ?? DateTime.now(),
        defaultPath: context.read<SettingsProvider>().getExportPath(),
      );

      if (context.mounted) {
        _showFileOpenSnackBar(context, filePath, 'Excel Detail');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      final transactions = context
          .read<TransactionProvider>()
          .transactions
          .where((t) => t.status == 'completed')
          .toList();

      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data untuk diexport')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Membuat Excel...')));

      final filePath = await ExportService.exportToExcel(
        transactions,
        _selectedStartDate ?? DateTime.now(),
        _selectedEndDate ?? DateTime.now(),
        defaultPath: context.read<SettingsProvider>().getExportPath(),
      );

      if (context.mounted) {
        _showFileOpenSnackBar(context, filePath, 'Excel');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFileOpenSnackBar(
    BuildContext context,
    String? filePath,
    String typeName,
  ) {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export $typeName dibatalkan'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File $typeName berhasil disimpan'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Buka File',
          textColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () => _openFile(filePath),
        ),
      ),
    );
  }

  void _openFile(String filePath) {
    final winPath = filePath.replaceAll('/', '\\');
    Process.run('explorer.exe', ['/select,$winPath']);
  }

  void _openFolder(String folderPath) {
    final winPath = folderPath.replaceAll('/', '\\');
    Process.run('explorer.exe', [winPath]);
  }

  Widget _buildPaginationBar(int currentPage, int totalPages, int totalItems) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final start = currentPage * _itemsPerPage + 1;
    final end = ((currentPage + 1) * _itemsPerPage).clamp(0, totalItems);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$start–$end dari $totalItems',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 0
                ? () => setState(() => _currentPage = currentPage - 1)
                : null,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          ...List.generate(
            totalPages,
            (i) => _buildPageButton(i, currentPage, totalPages),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages - 1
                ? () => setState(() => _currentPage = currentPage + 1)
                : null,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int page, int currentPage, int totalPages) {
    final cs = Theme.of(context).colorScheme;
    final isFirst = page == 0;
    final isLast = page == totalPages - 1;
    final nearCurrent = (page - currentPage).abs() <= 2;

    if (!isFirst && !isLast && !nearCurrent) {
      if (page == 1 || page == totalPages - 2) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('…', style: TextStyle(color: cs.onSurfaceVariant)),
        );
      }
      return const SizedBox.shrink();
    }

    final isActive = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => setState(() => _currentPage = page),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
