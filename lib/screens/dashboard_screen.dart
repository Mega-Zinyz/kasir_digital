import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/index.dart';
import '../../utils/formatters.dart';
import '../../widgets/index.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    // Schedule loading after build completes
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final productProvider = context.read<ProductProvider>();
    await Future.wait([
      _loadForDate(_selectedDate),
      productProvider.loadProducts(),
    ]);
  }

  Future<void> _loadForDate(DateTime date) async {
    final transactionProvider = context.read<TransactionProvider>();
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    await transactionProvider.loadTransactionsByDateRange(start, end);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadForDate(date);
  }

  void _prevMonth() {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _calendarMonth = DateTime(
        _calendarMonth.year,
        _calendarMonth.month + 1,
        1,
      );
    });
  }

  Widget _buildMiniCalendar() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(
      _calendarMonth.year,
      _calendarMonth.month,
    );
    final startOffset = _calendarMonth.weekday - 1; // Mon=0
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_calendarMonth);
    const dayHeaders = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Build flat list of cells (empty + day cells)
    final List<Widget> cells = [
      for (int i = 0; i < startOffset; i++) const SizedBox.shrink(),
      for (int day = 1; day <= daysInMonth; day++) _buildDayCell(day, now),
    ];

    // Pad to full week
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    // Split into rows of 7
    final List<Widget> weekRows = [];
    for (int i = 0; i < cells.length; i += 7) {
      weekRows.add(
        Row(
          children: [
            for (int j = i; j < i + 7; j++)
              Expanded(child: AspectRatio(aspectRatio: 0.85, child: cells[j])),
          ],
        ),
      );
    }

    return Card(
      elevation: isDark ? 0 : 1,
      color: isDark ? cs.surfaceContainerHigh : cs.surface,
      shadowColor: isDark
          ? Colors.transparent
          : cs.shadow.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month navigation header
            Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Day-of-week headers
            Row(
              children: dayHeaders
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 2),
            // Week rows
            ...weekRows,
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(int day, DateTime now) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
    final isSelected =
        _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

    return GestureDetector(
      onTap: isFuture ? null : () => _onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : isToday
              ? (isDark
                    ? cs.primaryContainer
                    : cs.primary.withValues(alpha: 0.10))
              : null,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? cs.onPrimary
                  : isFuture
                  ? cs.onSurface.withValues(alpha: 0.3)
                  : cs.onSurface,
              fontWeight: isSelected || isToday
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kasir'),
        actions: [
          // Hardware Status Indicator
          Consumer<HardwareProvider>(
            builder: (context, hardwareProvider, _) {
              final cs = Theme.of(context).colorScheme;
              // Build device list for tooltip
              final deviceList = hardwareProvider.devices
                  .map(
                    (device) =>
                        '${device.connected ? '✓' : '✗'} ${device.name}',
                  )
                  .join('\n');

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Tooltip(
                    message: deviceList.isEmpty
                        ? 'Tidak ada perangkat terdeteksi'
                        : deviceList,
                    showDuration: const Duration(seconds: 5),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to settings
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(6); // Settings index
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hardwareProvider.allDevicesConnected
                                  ? cs.secondary
                                  : cs.tertiary,
                              boxShadow: [
                                BoxShadow(
                                  color: hardwareProvider.allDevicesConnected
                                      ? cs.secondary.withValues(alpha: 0.45)
                                      : cs.tertiary.withValues(alpha: 0.45),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${hardwareProvider.connectedDevicesCount}/${hardwareProvider.totalDevicesCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner peringatan jika backup otomatis tidak aktif
            Consumer<SettingsProvider>(
              builder: (ctx, settings, _) {
                if (settings.backupFrequency != 'none') {
                  return const SizedBox.shrink();
                }
                final cs = Theme.of(ctx).colorScheme;
                final isDark = Theme.of(ctx).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? cs.errorContainer : cs.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.backup_outlined, color: cs.error, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup Otomatis Tidak Aktif',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? cs.onErrorContainer
                                    : cs.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aktifkan backup otomatis di halaman Backup & Restore untuk melindungi data Anda.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? cs.onErrorContainer
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => widget.onNavigate?.call(5),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Aktifkan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Greeting
            Text(
              'Selamat datang!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Keuntungan harian: ${DateTimeFormatter.formatDate(_selectedDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Stats kiri + mini kalender kanan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Consumer<TransactionProvider>(
                    builder: (context, transactionProvider, _) {
                      final transactions = transactionProvider.transactions;
                      double totalProfit = 0;
                      int totalTransactions = 0;

                      for (var transaction in transactions) {
                        if (transaction.status == 'completed') {
                          totalProfit += transaction.getTotalProfit();
                          totalTransactions++;
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(
                            builder: (context) {
                              final cs = Theme.of(context).colorScheme;
                              return SizedBox(
                                height: 168,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: StatCard(
                                        title: 'Keuntungan Hari Ini',
                                        value: CurrencyFormatter.formatCompact(
                                          totalProfit,
                                        ),
                                        fullValue: CurrencyFormatter.format(
                                          totalProfit,
                                        ),
                                        icon: Icons.trending_up,
                                        iconColor: cs.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: StatCard(
                                        title: 'Transaksi',
                                        value: totalTransactions.toString(),
                                        icon: Icons.receipt_long,
                                        iconColor: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 168,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Consumer2<ProductProvider, SettingsProvider>(
                                    builder:
                                        (
                                          context,
                                          productProvider,
                                          settingsProvider,
                                          _,
                                        ) {
                                          final cs = Theme.of(
                                            context,
                                          ).colorScheme;
                                          final lowStockCount = productProvider
                                              .getLowStockProducts(
                                                settingsProvider
                                                    .lowStockThreshold,
                                              )
                                              .length;
                                          return Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              StatCard(
                                                title: 'Total Produk',
                                                value: productProvider
                                                    .products
                                                    .length
                                                    .toString(),
                                                icon: Icons.inventory_2,
                                                iconColor: cs.tertiary,
                                              ),
                                              if (lowStockCount > 0)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: cs.error,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '$lowStockCount ⚠️',
                                                      style: TextStyle(
                                                        color: cs.onError,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final cs = Theme.of(context).colorScheme;
                                      return StatCard(
                                        title: 'Rata-rata Keuntungan',
                                        value: totalTransactions > 0
                                            ? CurrencyFormatter.formatCompact(
                                                totalProfit / totalTransactions,
                                              )
                                            : 'Rp 0',
                                        fullValue: totalTransactions > 0
                                            ? CurrencyFormatter.format(
                                                totalProfit / totalTransactions,
                                              )
                                            : 'Rp 0',
                                        icon: Icons.calculate,
                                        iconColor: cs.primary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(width: 292, height: 346, child: _buildMiniCalendar()),
              ],
            ),

            const SizedBox(height: 28),

            // Low Stock Alert
            Consumer2<ProductProvider, SettingsProvider>(
              builder: (context, productProvider, settingsProvider, _) {
                final cs = Theme.of(context).colorScheme;
                final lowStockProducts = productProvider.getLowStockProducts(
                  settingsProvider.lowStockThreshold,
                );

                if (lowStockProducts.isNotEmpty) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peringatan Stok Minimal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cs.tertiary.withValues(alpha: 0.5),
                          ),
                          color: isDark ? cs.tertiaryContainer : cs.surface,
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: cs.tertiary,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${lowStockProducts.length} produk stok kurang dari ${settingsProvider.lowStockThreshold} unit',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? cs.onTertiaryContainer
                                          : cs.onSurface,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: lowStockProducts.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: cs.outlineVariant),
                              itemBuilder: (context, index) {
                                final product = lowStockProducts[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Stok: ${product.stock} unit',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.tertiary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Low Stock',
                                          style: TextStyle(
                                            color: cs.onTertiary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                }
                return SizedBox.shrink();
              },
            ),

            const SizedBox(height: 28),

            // Quick Actions
            Text(
              'Aksi Cepat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Buat Penjualan',
                    icon: Icons.add,
                    onPressed: () {
                      // Navigate to sales screen (index 1)
                      widget.onNavigate?.call(1);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Recent Transactions
            Text(
              'Transaksi Terbaru',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final recentTransactions = transactionProvider.transactions
                    .where((t) => t.status == 'completed')
                    .take(5)
                    .toList();

                if (recentTransactions.isEmpty) {
                  return Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceContainerHigh : cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? cs.surfaceContainerHigh : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: recentTransactions.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: cs.outlineVariant, height: 1),
                    itemBuilder: (context, index) {
                      final transaction = recentTransactions[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        title: Text(
                          'Transaksi #${transaction.id.substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          DateTimeFormatter.formatDateTime(
                            transaction.transactionDate,
                          ),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(transaction.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
