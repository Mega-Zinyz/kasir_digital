import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/index.dart';
import '../../utils/formatters.dart';
import '../../widgets/index.dart';
import '../../models/index.dart';
import '../../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week'; // week, month, year
  String _selectedView = 'current'; // current, alltime

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analitik & Statistik')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analytics Header
              _AnalyticsHeader(
                selectedView: _selectedView,
                selectedPeriod: _selectedPeriod,
                onViewChanged: (v) => setState(() => _selectedView = v),
                onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              ),
              const SizedBox(height: 24),
              if (_selectedView == 'current')
                _SummaryCardsSection(period: _selectedPeriod)
              else
                _AllTimeSummarySection(),
              const SizedBox(height: 32),
              if (_selectedView == 'current') ...[
                _SalesChartSection(period: _selectedPeriod),
                const SizedBox(height: 32),
                _ProductSalesChartSection(period: _selectedPeriod),
                const SizedBox(height: 32),
                _TopProductsListSection(period: _selectedPeriod),
              ] else ...[
                _AllTimeChartSection(),
                const SizedBox(height: 32),
                _AllTimeProductsListSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Analytics Header — unified view + period selector
class _AnalyticsHeader extends StatelessWidget {
  final String selectedView;
  final String selectedPeriod;
  final Function(String) onViewChanged;
  final Function(String) onPeriodChanged;

  const _AnalyticsHeader({
    required this.selectedView,
    required this.selectedPeriod,
    required this.onViewChanged,
    required this.onPeriodChanged,
  });

  String _dateRangeLabel() {
    final now = DateTime.now();
    if (selectedView == 'alltime') return 'Semua waktu';
    switch (selectedPeriod) {
      case 'week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('d MMM', 'id_ID').format(monday)} – ${DateFormat('d MMM yyyy', 'id_ID').format(sunday)}';
      case 'month':
        return DateFormat('MMMM yyyy', 'id_ID').format(now);
      case 'year':
        return '${now.year}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateRangeLabel();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? cs.surfaceContainerHighest : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View tabs
            Row(
              children: [
                _ViewTab(
                  label: 'Periode Aktual',
                  icon: Icons.date_range,
                  isSelected: selectedView == 'current',
                  onTap: () => onViewChanged('current'),
                ),
                const SizedBox(width: 8),
                _ViewTab(
                  label: 'Seumur Hidup',
                  icon: Icons.all_inclusive,
                  isSelected: selectedView == 'alltime',
                  onTap: () => onViewChanged('alltime'),
                ),
              ],
            ),
            if (selectedView == 'current') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _PeriodChip(
                    label: 'Minggu',
                    icon: Icons.view_week_outlined,
                    value: 'week',
                    selectedPeriod: selectedPeriod,
                    onTap: onPeriodChanged,
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Bulan',
                    icon: Icons.calendar_month_outlined,
                    value: 'month',
                    selectedPeriod: selectedPeriod,
                    onTap: onPeriodChanged,
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Tahun',
                    icon: Icons.calendar_today_outlined,
                    value: 'year',
                    selectedPeriod: selectedPeriod,
                    onTap: onPeriodChanged,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.primaryContainer
                          : cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: isDark ? cs.onPrimaryContainer : cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? cs.onPrimaryContainer : cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? cs.primary : cs.primary.withValues(alpha: 0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? cs.primary : cs.outline),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? cs.onPrimary : cs.primary)
                    : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? cs.onPrimary : cs.primary)
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selectedPeriod;
  final Function(String) onTap;

  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selectedPeriod,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedPeriod == value;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? cs.primary : cs.primary.withValues(alpha: 0.10))
              : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? cs.primary : cs.outline),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? (isDark ? cs.onPrimary : cs.primary)
                  : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? cs.onPrimary : cs.primary)
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Summary Cards Section
class _SummaryCardsSection extends StatelessWidget {
  final String period;

  const _SummaryCardsSection({required this.period});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final transactions = transactionProvider.allTransactions
            .where((t) => t.status == 'completed')
            .toList();

        double totalProfit = 0;
        double previousTotalProfit = 0;
        int totalTransactions = 0;

        final now = DateTime.now();
        late DateTime startDate;
        late DateTime endDate;
        late DateTime previousStartDate;
        late DateTime previousEndDate;

        if (period == 'week') {
          final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(
            mondayThisWeek.year,
            mondayThisWeek.month,
            mondayThisWeek.day,
          );
          endDate = startDate.add(const Duration(days: 7));
          previousStartDate = startDate.subtract(const Duration(days: 7));
          previousEndDate = startDate;
        } else if (period == 'month') {
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);

          final previousMonth = now.month == 1 ? 12 : now.month - 1;
          final previousYear = now.month == 1 ? now.year - 1 : now.year;
          previousStartDate = DateTime(previousYear, previousMonth, 1);
          previousEndDate = DateTime(previousYear, previousMonth + 1, 1);
        } else {
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year + 1, 1, 1);
          previousStartDate = DateTime(now.year - 1, 1, 1);
          previousEndDate = DateTime(now.year, 1, 1);
        }

        for (final transaction in transactions) {
          final txDate = _dateOnly(transaction.transactionDate);

          if ((txDate.isAtSameMomentAs(startDate) ||
                  txDate.isAfter(startDate)) &&
              txDate.isBefore(endDate)) {
            totalProfit += transaction.getTotalProfit();
            totalTransactions++;
          }

          if ((txDate.isAtSameMomentAs(previousStartDate) ||
                  txDate.isAfter(previousStartDate)) &&
              txDate.isBefore(previousEndDate)) {
            previousTotalProfit += transaction.getTotalProfit();
          }
        }

        final growth = previousTotalProfit == 0
            ? 0.0
            : ((totalProfit - previousTotalProfit) / previousTotalProfit) * 100;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Keuntungan',
                    value: CurrencyFormatter.format(totalProfit),
                    subtitle: growth >= 0
                        ? '+${growth.toStringAsFixed(1)}%'
                        : '${growth.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    iconColor: growth >= 0 ? cs.secondary : cs.error,
                  ),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Rata-rata',
                    value: totalTransactions > 0
                        ? CurrencyFormatter.format(
                            totalProfit / totalTransactions,
                          )
                        : 'Rp 0',
                    icon: Icons.equalizer,
                    iconColor: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Tertinggi',
                    value: transactions.isNotEmpty
                        ? CurrencyFormatter.format(
                            transactions
                                .where((t) {
                                  final txDate = _dateOnly(t.transactionDate);
                                  return (txDate.isAtSameMomentAs(startDate) ||
                                          txDate.isAfter(startDate)) &&
                                      txDate.isBefore(endDate);
                                })
                                .reduce(
                                  (a, b) =>
                                      a.getTotalProfit() > b.getTotalProfit()
                                      ? a
                                      : b,
                                )
                                .getTotalProfit(),
                          )
                        : 'Rp 0',
                    icon: Icons.trending_up,
                    iconColor: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// Sales Chart Section
class _SalesChartSection extends StatelessWidget {
  final String period;

  const _SalesChartSection({required this.period});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grafik Keuntungan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          height: 480,
          padding: const EdgeInsets.only(
            top: 16,
            right: 16,
            bottom: 40,
            left: 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Consumer<TransactionProvider>(
            builder: (context, transactionProvider, _) {
              return _SalesChart(
                transactions: transactionProvider.allTransactions
                    .where((t) => t.status == 'completed')
                    .toList(),
                period: period,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          period == 'week'
              ? 'Garis menunjukkan total keuntungan setiap hari dalam minggu ini (Sen=Senin hingga Min=Minggu). Sumbu vertikal adalah total Rupiah keuntungan.'
              : period == 'month'
              ? 'Garis menunjukkan total keuntungan harian. Label menampilkan tanggal bulan saat ini. Sumbu vertikal adalah total Rupiah keuntungan.'
              : 'Garis menunjukkan total keuntungan setiap bulan dalam tahun ini. Sumbu vertikal adalah total Rupiah keuntungan.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// Product Sales Chart Section
class _ProductSalesChartSection extends StatelessWidget {
  final String period;
  static const int _maxChartProducts = 10;

  const _ProductSalesChartSection({required this.period});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penjualan Produk',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Menampilkan $_maxChartProducts produk teratas agar grafik tetap terbaca.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Container(
          height: 500,
          padding: const EdgeInsets.only(
            top: 16,
            right: 16,
            bottom: 40,
            left: 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHigh : cs.surface,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Consumer<TransactionProvider>(
            builder: (context, transactionProvider, _) {
              return _ProductSalesChart(
                transactions: transactionProvider.allTransactions
                    .where((t) => t.status == 'completed')
                    .toList(),
                period: period,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          period == 'week'
              ? 'Grafik menunjukkan perbandingan penjualan produk setiap hari dalam minggu ini. Warna berbeda mewakili produk berbeda.'
              : period == 'month'
              ? 'Grafik menunjukkan perbandingan penjualan produk setiap hari bulan ini. Warna berbeda mewakili produk berbeda.'
              : 'Grafik menunjukkan perbandingan penjualan produk setiap bulan tahun ini. Warna berbeda mewakili produk berbeda.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// Top Products List Section
class _TopProductsListSection extends StatefulWidget {
  final String period;

  const _TopProductsListSection({required this.period});

  @override
  State<_TopProductsListSection> createState() =>
      _TopProductsListSectionState();
}

class _TopProductsListSectionState extends State<_TopProductsListSection> {
  bool _showFullAmount = false;
  bool _reversed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Produk Terlaris',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            // Toggle nominal asli
            Tooltip(
              message: _showFullAmount
                  ? 'Tampilkan ringkasan'
                  : 'Tampilkan nominal asli',
              child: InkWell(
                onTap: () => setState(() => _showFullAmount = !_showFullAmount),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showFullAmount
                        ? (isDark
                              ? cs.secondaryContainer
                              : cs.secondary.withValues(alpha: 0.08))
                        : (isDark ? cs.surfaceContainerHighest : cs.surface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showFullAmount
                          ? cs.secondary.withValues(alpha: 0.5)
                          : cs.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFullAmount ? Icons.attach_money : Icons.money_off,
                        size: 14,
                        color: _showFullAmount
                            ? cs.secondary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showFullAmount ? 'Nominal Asli' : 'Ringkasan',
                        style: TextStyle(
                          fontSize: 12,
                          color: _showFullAmount
                              ? cs.secondary
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle urutan
            Tooltip(
              message: _reversed ? 'Tampilkan terlaris' : 'Tampilkan terendah',
              child: InkWell(
                onTap: () => setState(() => _reversed = !_reversed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _reversed
                        ? (isDark
                              ? cs.tertiaryContainer
                              : cs.tertiary.withValues(alpha: 0.08))
                        : (isDark ? cs.surfaceContainerHighest : cs.surface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _reversed
                          ? cs.tertiary.withValues(alpha: 0.5)
                          : cs.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _reversed ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: _reversed ? cs.tertiary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _reversed ? 'Terendah' : 'Terlaris',
                        style: TextStyle(
                          fontSize: 12,
                          color: _reversed ? cs.tertiary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TransactionProvider>(
          builder: (context, transactionProvider, _) {
            return _TopProductsList(
              transactions: transactionProvider.allTransactions
                  .where((t) => t.status == 'completed')
                  .toList(),
              period: widget.period,
              showFullAmount: _showFullAmount,
              reversed: _reversed,
            );
          },
        ),
      ],
    );
  }
}

// Helper function to normalize DateTime to date only (midnight)
DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

// Sales Chart Widget
class _SalesChart extends StatelessWidget {
  final List<SalesTransaction> transactions;
  final String period;

  const _SalesChart({required this.transactions, required this.period});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _dateOnly(now);

    if (period == 'week') {
      // Current week (Monday to Sunday)
      List<double> dailyProfit = [0, 0, 0, 0, 0, 0, 0];

      // Get Monday of current week
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      for (var t in transactions) {
        final transactionDate = _dateOnly(t.transactionDate);

        // Check if transaction is within current week
        if ((transactionDate.isAtSameMomentAs(weekStart) ||
                transactionDate.isAfter(weekStart)) &&
            transactionDate.isBefore(weekEnd)) {
          // Map weekday directly to array index (1=Monday→0, 7=Sunday→6)
          final index = transactionDate.weekday - 1;
          dailyProfit[index] += t.getTotalProfit();
        }
      }

      List<FlSpot> profitSpots = [];
      for (int i = 0; i < dailyProfit.length; i++) {
        profitSpots.add(FlSpot(i.toDouble(), dailyProfit[i]));
      }

      return _LineChart(
        salesSpots: profitSpots,
        profitSpots: profitSpots,
        labels: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
        period: 'week',
      );
    } else if (period == 'month') {
      // Current month days (comparing dates only, not times)
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      List<double> dailyProfit = List.filled(daysInMonth, 0.0);

      final monthStart = _dateOnly(DateTime(now.year, now.month, 1));
      final monthEnd = _dateOnly(DateTime(now.year, now.month + 1, 0));

      for (var t in transactions) {
        final transactionDate = _dateOnly(t.transactionDate);
        if ((transactionDate.isAtSameMomentAs(monthStart) ||
                transactionDate.isAfter(monthStart)) &&
            (transactionDate.isAtSameMomentAs(monthEnd) ||
                transactionDate.isBefore(monthEnd))) {
          final dayIndex = transactionDate.day - 1;
          if (dayIndex >= 0 && dayIndex < daysInMonth) {
            dailyProfit[dayIndex] += t.getTotalProfit();
          }
        }
      }

      List<FlSpot> profitSpots = [];
      for (int i = 0; i < dailyProfit.length; i++) {
        profitSpots.add(FlSpot(i.toDouble(), dailyProfit[i]));
      }

      // Generate simple numeric labels for dates only
      List<String> labels = [];
      for (int i = 0; i < daysInMonth; i++) {
        labels.add('${i + 1}');
      }

      return _LineChart(
        salesSpots: profitSpots,
        profitSpots: profitSpots,
        labels: labels,
        period: 'month',
      );
    } else {
      // Current year - by month
      List<double> monthlyProfit = List.filled(12, 0.0);

      final yearStart = _dateOnly(DateTime(now.year, 1, 1));
      final yearEnd = _dateOnly(DateTime(now.year + 1, 1, 1));

      for (var t in transactions) {
        final transactionDate = _dateOnly(t.transactionDate);
        if ((transactionDate.isAtSameMomentAs(yearStart) ||
                transactionDate.isAfter(yearStart)) &&
            (transactionDate.isAtSameMomentAs(yearEnd) ||
                transactionDate.isBefore(yearEnd))) {
          monthlyProfit[transactionDate.month - 1] += t.getTotalProfit();
        }
      }

      List<FlSpot> profitSpots = [];
      for (int i = 0; i < monthlyProfit.length; i++) {
        profitSpots.add(FlSpot(i.toDouble(), monthlyProfit[i]));
      }

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return _LineChart(
        salesSpots: profitSpots,
        profitSpots: profitSpots,
        labels: months,
        period: 'year',
      );
    }
  }
}

Color _shiftedChartColor(
  Color base, {
  double hueShift = 0,
  double saturationDelta = 0,
  double lightnessDelta = 0,
}) {
  final hsl = HSLColor.fromColor(base);
  final shiftedHue = (hsl.hue + hueShift) % 360;
  return hsl
      .withHue(shiftedHue < 0 ? shiftedHue + 360 : shiftedHue)
      .withSaturation((hsl.saturation + saturationDelta).clamp(0.35, 0.95))
      .withLightness((hsl.lightness + lightnessDelta).clamp(0.30, 0.72))
      .toColor();
}

// Helper function to get varied colors that still follow the active theme.
Color _getColorForIndex(BuildContext context, int index) {
  final cs = Theme.of(context).colorScheme;
  final colors = [
    cs.primary,
    cs.secondary,
    cs.tertiary,
    cs.error,
    _shiftedChartColor(cs.primary, hueShift: 28, lightnessDelta: 0.06),
    _shiftedChartColor(cs.secondary, hueShift: -24, saturationDelta: 0.08),
    _shiftedChartColor(cs.tertiary, hueShift: 36, lightnessDelta: -0.04),
    _shiftedChartColor(
      cs.primary,
      saturationDelta: -0.20,
      lightnessDelta: 0.10,
    ),
    _shiftedChartColor(cs.secondary, hueShift: 18, lightnessDelta: -0.06),
    _shiftedChartColor(
      cs.tertiary,
      saturationDelta: 0.10,
      lightnessDelta: 0.08,
    ),
  ];
  return colors[index % colors.length];
}

// Line Chart Widget
class _LineChart extends StatelessWidget {
  final List<FlSpot> salesSpots;
  final List<FlSpot> profitSpots;
  final List<String> labels;
  final String period;

  const _LineChart({
    required this.salesSpots,
    required this.profitSpots,
    required this.labels,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Calculate max value for appropriate formatting
    double maxSales = salesSpots.isEmpty
        ? 0
        : salesSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double maxProfit = profitSpots.isEmpty
        ? 0
        : profitSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double maxValue = maxSales > maxProfit ? maxSales : maxProfit;

    // Determine interval based on max value
    double interval = 1;
    if (maxValue > 0) {
      if (maxValue > 10000000) {
        interval = (maxValue / 5 / 1000000).ceilToDouble() * 1000000;
      } else if (maxValue > 1000000) {
        interval = (maxValue / 5 / 500000).ceilToDouble() * 500000;
      } else if (maxValue > 100000) {
        interval = (maxValue / 5 / 100000).ceilToDouble() * 100000;
      } else {
        interval = (maxValue / 5 / 10000).ceilToDouble() * 10000;
      }
    }
    final maxY = interval > 0
        ? ((maxValue / interval).ceil() + 1) * interval
        : (maxValue > 0 ? maxValue * 1.2 : 1.0);

    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: cs.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Keuntungan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: [
                // Profit Line (Green)
                LineChartBarData(
                  spots: profitSpots,
                  isCurved: true,
                  curveSmoothness: 0.15,
                  preventCurveOverShooting: true,
                  color: cs.secondary,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: cs.secondary,
                        strokeWidth: 1.5,
                        strokeColor: cs.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: cs.secondary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              minX: 0,
              maxX: profitSpots.isEmpty ? 0 : profitSpots.last.x,
              minY: 0,
              maxY: maxY,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      final hasLabel =
                          index >= 0 &&
                          index < labels.length &&
                          labels[index].isNotEmpty;

                      if (hasLabel && (value - index).abs() < 0.01) {
                        // Only show label at exact integer positions (no repetition)
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Transform.rotate(
                            angle: period == 'month'
                                ? 0
                                : 0, // 45 deg for month (-π/4)
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[index],
                                style: TextStyle(
                                  fontSize: period == 'month' ? 13 : 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: period == 'month' ? 80 : 40,
                    interval: period == 'week' ? 1.0 : null,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value < 0) return const SizedBox.shrink();

                      String label;
                      if (value >= 1000000) {
                        label = 'Rp ${(value / 1000000).toStringAsFixed(1)}M';
                      } else if (value >= 1000) {
                        label = 'Rp ${(value / 1000).toStringAsFixed(0)}K';
                      } else {
                        label = 'Rp ${value.toStringAsFixed(0)}';
                      }
                      return Text(label, style: const TextStyle(fontSize: 10));
                    },
                    reservedSize: 70,
                    interval: interval > 0 ? interval : 1,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: cs.outline, width: 1),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: interval > 0 ? interval : null,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: cs.outlineVariant,
                    strokeWidth: 0.8,
                    dashArray: [5, 5],
                  );
                },
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: cs.inverseSurface,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 16,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((touchedSpot) {
                      final barIndex = touchedSpot.barIndex;
                      final label = barIndex == 0 ? 'Penjualan' : 'Profit';
                      return LineTooltipItem(
                        '$label: ${CurrencyFormatter.formatCompact(touchedSpot.y)}',
                        TextStyle(
                          color: cs.onInverseSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Product Sales Chart Widget
class _ProductSalesChart extends StatefulWidget {
  final List<SalesTransaction> transactions;
  final String period;

  const _ProductSalesChart({required this.transactions, required this.period});

  @override
  State<_ProductSalesChart> createState() => _ProductSalesChartState();
}

class _ProductSalesChartState extends State<_ProductSalesChart> {
  static const int _maxChartProducts = 10;
  bool _loading = true;
  // Cached chart data
  List<MapEntry<String, Map<String, dynamic>>> _topProducts = [];
  List<MapEntry<String, Map<String, dynamic>>> _availableProducts = [];
  Map<String, List<FlSpot>> _productSpots = {};
  List<String> _xLabels = [];
  double _maxValue = 0;
  double? _interval;
  Set<String> _selectedProductIds = <String>{};
  String _rankingBasis = 'revenue';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(_ProductSalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.transactions.length != widget.transactions.length) {
      _fetchData();
    }
  }

  bool get _isUsingCustomSelection => _selectedProductIds.isNotEmpty;

  String get _rankingBasisLabel =>
      _rankingBasis == 'quantity' ? 'jumlah terjual' : 'omzet';

  Future<void> _showProductSelectionDialog() async {
    if (_availableProducts.isEmpty) {
      return;
    }

    final tempSelectedIds = Set<String>.from(_selectedProductIds);
    String searchQuery = '';
    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final filteredProducts = _availableProducts.where((product) {
              final productName = (product.value['productName'] as String)
                  .toLowerCase();
              return productName.contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Pilih Produk untuk Dibandingkan'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih hingga $_maxChartProducts produk. Jika tidak memilih apa pun, grafik akan kembali ke top $_maxChartProducts otomatis.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.primaryContainer
                            : cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${tempSelectedIds.length} / $_maxChartProducts produk dipilih',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? cs.onPrimaryContainer : cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama produk...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              tempSelectedIds
                                ..clear()
                                ..addAll(
                                  _availableProducts
                                      .take(_maxChartProducts)
                                      .map((product) => product.key),
                                );
                            });
                          },
                          icon: const Icon(Icons.auto_graph, size: 16),
                          label: const Text('Pilih Top 10 Saat Ini'),
                        ),
                        Text(
                          'Mengikuti ranking $_rankingBasisLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final productId = product.key;
                          final isSelected = tempSelectedIds.contains(
                            productId,
                          );
                          final disableUnchecked =
                              !isSelected &&
                              tempSelectedIds.length >= _maxChartProducts;

                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: disableUnchecked
                                ? null
                                : (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        tempSelectedIds.add(productId);
                                      } else {
                                        tempSelectedIds.remove(productId);
                                      }
                                    });
                                  },
                            title: Text(
                              product.value['productName'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Omzet ${CurrencyFormatter.formatCompact(product.value['total'] as double)} • ${product.value['quantity']} terjual',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    tempSelectedIds.clear();
                    setDialogState(() {});
                  },
                  child: const Text('Kosongkan Pilihan'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _selectedProductIds = tempSelectedIds;
      });
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final today = _dateOnly(now);
      List<SalesTransaction> filteredTransactions = [];

      if (widget.period == 'week') {
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        filteredTransactions = widget.transactions
            .where(
              (t) => _dateOnly(
                t.transactionDate,
              ).isAfter(weekStart.subtract(const Duration(days: 1))),
            )
            .toList();
      } else if (widget.period == 'month') {
        final monthStart = _dateOnly(DateTime(now.year, now.month, 1));
        final monthEnd = _dateOnly(DateTime(now.year, now.month + 1, 0));
        filteredTransactions = widget.transactions.where((t) {
          final tDate = _dateOnly(t.transactionDate);
          return (tDate.isAtSameMomentAs(monthStart) ||
                  tDate.isAfter(monthStart)) &&
              (tDate.isAtSameMomentAs(monthEnd) ||
                  tDate.isBefore(monthEnd.add(const Duration(days: 1))));
        }).toList();
      } else {
        final yearStart = _dateOnly(DateTime(now.year, 1, 1));
        final yearEnd = _dateOnly(DateTime(now.year + 1, 1, 1));
        filteredTransactions = widget.transactions.where((t) {
          final tDate = _dateOnly(t.transactionDate);
          return (tDate.isAtSameMomentAs(yearStart) ||
                  tDate.isAfter(yearStart)) &&
              (tDate.isAtSameMomentAs(yearEnd) || tDate.isBefore(yearEnd));
        }).toList();
      }

      Map<String, Map<String, dynamic>> productData = {};
      for (var transaction in filteredTransactions) {
        final items = await DatabaseService().getTransactionItems(
          transaction.id,
        );
        for (var item in items) {
          if (!productData.containsKey(item.productId)) {
            productData[item.productId] = {
              'productName': item.productName,
              'total': 0.0,
              'quantity': 0,
            };
          }
          productData[item.productId]!['total'] += item.subtotal;
          productData[item.productId]!['quantity'] += item.quantity;
        }
      }

      final sortedProducts = productData.entries.toList()
        ..sort(
          (a, b) => _rankingBasis == 'quantity'
              ? (b.value['quantity'] as int).compareTo(
                  a.value['quantity'] as int,
                )
              : (b.value['total'] as double).compareTo(
                  a.value['total'] as double,
                ),
        );

      final availableIds = sortedProducts.map((product) => product.key).toSet();
      final sanitizedSelection = _selectedProductIds
          .where(availableIds.contains)
          .toSet();
      final topProducts = sanitizedSelection.isEmpty
          ? sortedProducts.take(_maxChartProducts).toList()
          : sortedProducts
                .where((product) => sanitizedSelection.contains(product.key))
                .take(_maxChartProducts)
                .toList();

      Map<String, List<FlSpot>> productSpots = {};
      List<String> xLabels = [];
      double maxValue = 0;

      if (widget.period == 'week') {
        xLabels = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        for (var product in topProducts) {
          productSpots[product.key] = List.generate(
            7,
            (i) => FlSpot(i.toDouble(), 0),
          );
        }
        for (var transaction in filteredTransactions) {
          final items = await DatabaseService().getTransactionItems(
            transaction.id,
          );
          final txDate = _dateOnly(transaction.transactionDate);
          if ((txDate.isAtSameMomentAs(weekStart) ||
                  txDate.isAfter(weekStart)) &&
              txDate.isBefore(weekEnd)) {
            final dayIndex = txDate.weekday - 1;
            for (var item in items) {
              if (productSpots.containsKey(item.productId)) {
                final spots = productSpots[item.productId]!;
                spots[dayIndex] = FlSpot(
                  dayIndex.toDouble(),
                  spots[dayIndex].y + item.subtotal,
                );
                if (spots[dayIndex].y > maxValue) maxValue = spots[dayIndex].y;
              }
            }
          }
        }
      } else if (widget.period == 'month') {
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        xLabels = List.generate(daysInMonth, (i) => '${i + 1}');
        final monthStart = _dateOnly(DateTime(now.year, now.month, 1));
        final monthEnd = _dateOnly(DateTime(now.year, now.month + 1, 0));
        for (var product in topProducts) {
          productSpots[product.key] = List.generate(
            daysInMonth,
            (i) => FlSpot(i.toDouble(), 0),
          );
        }
        for (var transaction in filteredTransactions) {
          final items = await DatabaseService().getTransactionItems(
            transaction.id,
          );
          final txDate = _dateOnly(transaction.transactionDate);
          if ((txDate.isAtSameMomentAs(monthStart) ||
                  txDate.isAfter(monthStart)) &&
              (txDate.isAtSameMomentAs(monthEnd) ||
                  txDate.isBefore(monthEnd.add(const Duration(days: 1))))) {
            final dayIndex = txDate.day - 1;
            for (var item in items) {
              if (productSpots.containsKey(item.productId)) {
                final spots = productSpots[item.productId]!;
                spots[dayIndex] = FlSpot(
                  dayIndex.toDouble(),
                  spots[dayIndex].y + item.subtotal,
                );
                if (spots[dayIndex].y > maxValue) maxValue = spots[dayIndex].y;
              }
            }
          }
        }
      } else {
        xLabels = const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        final yearStart = _dateOnly(DateTime(now.year, 1, 1));
        final yearEnd = _dateOnly(DateTime(now.year + 1, 1, 1));
        for (var product in topProducts) {
          productSpots[product.key] = List.generate(
            12,
            (i) => FlSpot(i.toDouble(), 0),
          );
        }
        for (var transaction in filteredTransactions) {
          final items = await DatabaseService().getTransactionItems(
            transaction.id,
          );
          final txDate = _dateOnly(transaction.transactionDate);
          if ((txDate.isAtSameMomentAs(yearStart) ||
                  txDate.isAfter(yearStart)) &&
              txDate.isBefore(yearEnd)) {
            final monthIndex = txDate.month - 1;
            for (var item in items) {
              if (productSpots.containsKey(item.productId)) {
                final spots = productSpots[item.productId]!;
                spots[monthIndex] = FlSpot(
                  monthIndex.toDouble(),
                  spots[monthIndex].y + item.subtotal,
                );
                if (spots[monthIndex].y > maxValue) {
                  maxValue = spots[monthIndex].y;
                }
              }
            }
          }
        }
      }

      double? interval;
      if (maxValue > 0) {
        if (maxValue <= 1000000) {
          interval = 100000;
        } else if (maxValue <= 10000000) {
          interval = 1000000;
        } else {
          interval = 10000000;
        }
      }

      if (mounted) {
        setState(() {
          _availableProducts = sortedProducts;
          _selectedProductIds = sanitizedSelection;
          _topProducts = topProducts;
          _productSpots = productSpots;
          _xLabels = xLabels;
          _maxValue = maxValue;
          _interval = interval;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 440,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_topProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada penjualan periode ini',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<LineChartBarData> lineBars = [];
    for (int i = 0; i < _topProducts.length; i++) {
      final product = _topProducts[i];
      final spots = _productSpots[product.key] ?? [];
      final color = _getColorForIndex(context, i);
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.15,
          preventCurveOverShooting: true,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Theme.of(context).colorScheme.surface,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isUsingCustomSelection
                        ? 'Mode kustom: membandingkan ${_topProducts.length} produk pilihan'
                        : 'Mode otomatis: top $_maxChartProducts produk berdasarkan $_rankingBasisLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Berdasarkan Omzet'),
                      selected: _rankingBasis == 'revenue',
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() {
                          _rankingBasis = 'revenue';
                        });
                        _fetchData();
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Berdasarkan Qty'),
                      selected: _rankingBasis == 'quantity',
                      onSelected: (selected) {
                        if (!selected) return;
                        setState(() {
                          _rankingBasis = 'quantity';
                        });
                        _fetchData();
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _showProductSelectionDialog,
                  icon: const Icon(Icons.tune, size: 16),
                  label: Text(
                    _isUsingCustomSelection ? 'Ubah Produk' : 'Pilih Produk',
                  ),
                ),
              ],
            ),
          ),
          if (_isUsingCustomSelection)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedProductIds.clear();
                    });
                    _fetchData();
                  },
                  child: const Text('Kembali ke Top 10 Otomatis'),
                ),
              ),
            ),
          // Legend
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(_topProducts.length, (index) {
                final product = _topProducts[index];
                final color = _getColorForIndex(context, index);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        product.value['productName'] as String,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          SizedBox(
            height: 380,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < _xLabels.length &&
                            (value - index).abs() < 0.01) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _xLabels[index],
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value < 0) return const SizedBox.shrink();
                        return Text(
                          CurrencyFormatter.formatCompact(value),
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                      reservedSize: 72,
                      interval: _interval,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                lineBarsData: lineBars,
                minX: 0,
                maxX: _xLabels.isEmpty ? 0 : (_xLabels.length - 1).toDouble(),
                minY: 0,
                maxY: _maxValue > 0 ? _maxValue * 1.2 : 1.0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final product =
                            _topProducts.isNotEmpty &&
                                spot.barIndex < _topProducts.length
                            ? _topProducts[spot.barIndex].value['productName']
                                  as String
                            : '';
                        return LineTooltipItem(
                          '$product\n${CurrencyFormatter.formatCompact(spot.y)}',
                          TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Top Products List Widget
class _TopProductsList extends StatefulWidget {
  final List<SalesTransaction> transactions;
  final String period;
  final bool showFullAmount;
  final bool reversed;

  const _TopProductsList({
    required this.transactions,
    required this.period,
    this.showFullAmount = false,
    this.reversed = false,
  });

  @override
  State<_TopProductsList> createState() => _TopProductsListState();
}

class _TopProductsListState extends State<_TopProductsList> {
  List<MapEntry<String, Map<String, dynamic>>> _sortedProducts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(_TopProductsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch only if transactions or period changed, not showFullAmount/reversed
    if (oldWidget.period != widget.period ||
        oldWidget.transactions.length != widget.transactions.length) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      List<SalesTransaction> filtered;

      if (widget.period == 'week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filtered = widget.transactions
            .where((t) => t.transactionDate.isAfter(weekStart))
            .toList();
      } else if (widget.period == 'month') {
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        filtered = widget.transactions
            .where(
              (t) =>
                  t.transactionDate.isAfter(monthStart) &&
                  t.transactionDate.isBefore(
                    monthEnd.add(const Duration(days: 1)),
                  ),
            )
            .toList();
      } else {
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        filtered = widget.transactions
            .where(
              (t) =>
                  t.transactionDate.isAfter(yearStart) &&
                  t.transactionDate.isBefore(yearEnd),
            )
            .toList();
      }

      Map<String, Map<String, dynamic>> productSales = {};
      for (var transaction in filtered) {
        final items = await DatabaseService().getTransactionItems(
          transaction.id,
        );
        for (var item in items) {
          if (productSales.containsKey(item.productId)) {
            productSales[item.productId]!['quantity'] += item.quantity;
            productSales[item.productId]!['amount'] += item.subtotal;
          } else {
            productSales[item.productId] = {
              'productName': item.productName,
              'quantity': item.quantity,
              'amount': item.subtotal,
            };
          }
        }
      }

      final sorted = productSales.entries.toList()
        ..sort(
          (a, b) => (b.value['quantity'] as int).compareTo(
            a.value['quantity'] as int,
          ),
        );

      if (mounted) {
        setState(() {
          _sortedProducts = sorted.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('Error loading products')),
      );
    }

    var topProducts = List<MapEntry<String, Map<String, dynamic>>>.from(
      _sortedProducts,
    );
    if (widget.reversed) topProducts = topProducts.reversed.toList();

    if (topProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada produk terjual',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxQuantity = widget.reversed
        ? (_sortedProducts.first.value['quantity'] as int).toDouble()
        : (topProducts.first.value['quantity'] as int).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topProducts.length,
        itemBuilder: (context, index) {
          final product = topProducts[index];
          final quantity = product.value['quantity'] as int;
          final amount = product.value['amount'] as double;
          final percentage = (quantity / maxQuantity) * 100;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${product.value['productName']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$quantity terjual',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      widget.showFullAmount
                          ? CurrencyFormatter.format(amount)
                          : CurrencyFormatter.formatCompact(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (index < topProducts.length - 1)
                  const Divider(height: 16, thickness: 1),
              ],
            ),
          );
        },
      ),
    );
  }
}

// All Time Summary Section
class _AllTimeSummarySection extends StatelessWidget {
  const _AllTimeSummarySection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final transactions = transactionProvider.allTransactions
            .where((t) => t.status == 'completed')
            .toList();

        double totalProfit = 0;
        int totalTransactions = transactions.length;

        for (var t in transactions) {
          totalProfit += t.getTotalProfit();
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Keuntungan',
                    value: CurrencyFormatter.format(totalProfit),
                    icon: Icons.trending_up,
                    iconColor: cs.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Total Transaksi',
                    value: totalTransactions.toString(),
                    icon: Icons.receipt_long,
                    iconColor: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Rata-rata',
                    value: totalTransactions > 0
                        ? CurrencyFormatter.format(
                            totalProfit / totalTransactions,
                          )
                        : 'Rp 0',
                    icon: Icons.equalizer,
                    iconColor: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Tertinggi',
                    value: transactions.isNotEmpty
                        ? CurrencyFormatter.format(
                            transactions
                                .reduce(
                                  (a, b) =>
                                      a.getTotalProfit() > b.getTotalProfit()
                                      ? a
                                      : b,
                                )
                                .getTotalProfit(),
                          )
                        : 'Rp 0',
                    icon: Icons.trending_up,
                    iconColor: cs.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// All Time Chart Section
class _AllTimeChartSection extends StatefulWidget {
  const _AllTimeChartSection();

  @override
  State<_AllTimeChartSection> createState() => _AllTimeChartSectionState();
}

class _AllTimeChartSectionState extends State<_AllTimeChartSection> {
  List<FlSpot> _profitSpots = [];
  List<String> _labels = [];
  double _maxValue = 0;
  double _interval = 100000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      context.read<TransactionProvider>().addListener(_onProviderChanged);
    });
  }

  @override
  void dispose() {
    context.read<TransactionProvider>().removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) _fetchData();
  }

  void _fetchData() {
    final transactions = context
        .read<TransactionProvider>()
        .allTransactions
        .where((t) => t.status == 'completed')
        .toList();

    final Map<String, double> monthlyData = {};
    for (var t in transactions) {
      final key =
          '${t.transactionDate.year}-${t.transactionDate.month.toString().padLeft(2, '0')}';
      monthlyData[key] = (monthlyData[key] ?? 0) + t.getTotalProfit();
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[sortedKeys[i]]!));
    }

    double maxValue = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    double interval = 100000;
    if (maxValue > 0) {
      if (maxValue > 10000000) {
        interval = (maxValue / 5 / 1000000).ceilToDouble() * 1000000;
      } else if (maxValue > 1000000) {
        interval = (maxValue / 5 / 500000).ceilToDouble() * 500000;
      } else if (maxValue > 100000) {
        interval = (maxValue / 5 / 100000).ceilToDouble() * 100000;
      } else {
        interval = (maxValue / 5 / 10000).ceilToDouble() * 10000;
      }
    }

    if (mounted) {
      setState(() {
        _profitSpots = spots;
        _labels = sortedKeys;
        _maxValue = maxValue;
        _interval = interval > 0 ? interval : 100000;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline Keuntungan Per Bulan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_profitSpots.isEmpty)
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Belum ada data transaksi')),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (_labels.length * 100).toDouble().clamp(
                  MediaQuery.of(context).size.width - 32,
                  double.infinity,
                ),
                height: 280,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    right: 16,
                    bottom: 40,
                    left: 8,
                  ),
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _profitSpots,
                          isCurved: true,
                          curveSmoothness: 0.15,
                          preventCurveOverShooting: true,
                          color: Theme.of(context).colorScheme.secondary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  strokeWidth: 1.5,
                                  strokeColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      minX: 0,
                      maxX: _profitSpots.isEmpty ? 0 : _profitSpots.last.x,
                      minY: 0,
                      maxY: _maxValue > 0 ? _maxValue * 1.2 : 1.0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: _interval,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 &&
                                  index < _labels.length &&
                                  (value - index).abs() < 0.01) {
                                final parts = _labels[index].split('-');
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${parts[0]}-${parts[1]}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 72,
                            interval: _interval,
                            getTitlesWidget: (value, meta) {
                              if (value < 0) return const SizedBox.shrink();
                              return Text(
                                CurrencyFormatter.formatCompact(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              final label = index >= 0 && index < _labels.length
                                  ? _labels[index]
                                  : '';
                              return LineTooltipItem(
                                '$label\n${CurrencyFormatter.formatCompact(spot.y)}',
                                TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface,
                                  fontSize: 11,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Scroll ke kanan untuk melihat data bulan-bulan sebelumnya. Grafik menunjukkan total keuntungan setiap bulan sejak awal.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// All Time Products List Section
class _AllTimeProductsListSection extends StatefulWidget {
  const _AllTimeProductsListSection();

  @override
  State<_AllTimeProductsListSection> createState() =>
      _AllTimeProductsListSectionState();
}

class _AllTimeProductsListSectionState
    extends State<_AllTimeProductsListSection> {
  bool _showFullAmount = false;
  bool _reversed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Produk Terlaris (Seumur Hidup)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            // Toggle nominal asli
            Tooltip(
              message: _showFullAmount
                  ? 'Tampilkan ringkasan'
                  : 'Tampilkan nominal asli',
              child: InkWell(
                onTap: () => setState(() => _showFullAmount = !_showFullAmount),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showFullAmount
                        ? (isDark
                              ? cs.secondaryContainer
                              : cs.secondary.withValues(alpha: 0.08))
                        : (isDark ? cs.surfaceContainerHighest : cs.surface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showFullAmount
                          ? cs.secondary.withValues(alpha: 0.5)
                          : cs.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showFullAmount ? Icons.attach_money : Icons.money_off,
                        size: 14,
                        color: _showFullAmount
                            ? cs.secondary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showFullAmount ? 'Nominal Asli' : 'Ringkasan',
                        style: TextStyle(
                          fontSize: 12,
                          color: _showFullAmount
                              ? cs.secondary
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle urutan
            Tooltip(
              message: _reversed ? 'Tampilkan terlaris' : 'Tampilkan terendah',
              child: InkWell(
                onTap: () => setState(() => _reversed = !_reversed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _reversed
                        ? (isDark
                              ? cs.tertiaryContainer
                              : cs.tertiary.withValues(alpha: 0.08))
                        : (isDark ? cs.surfaceContainerHighest : cs.surface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _reversed
                          ? cs.tertiary.withValues(alpha: 0.5)
                          : cs.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _reversed ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: _reversed ? cs.tertiary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _reversed ? 'Terendah' : 'Terlaris',
                        style: TextStyle(
                          fontSize: 12,
                          color: _reversed ? cs.tertiary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TransactionProvider>(
          builder: (context, transactionProvider, _) {
            final transactions = transactionProvider.allTransactions
                .where((t) => t.status == 'completed')
                .toList();

            // Calculate product sales
            final Map<String, Map<String, dynamic>> productStats = {};
            for (var t in transactions) {
              for (var item in t.items) {
                if (!productStats.containsKey(item.productId)) {
                  productStats[item.productId] = {
                    'name': item.productName,
                    'profit': 0.0,
                    'quantity': 0,
                  };
                }
                productStats[item.productId]!['profit'] +=
                    item.profitMargin * item.quantity;
                productStats[item.productId]!['quantity'] += item.quantity;
              }
            }

            // Sort by quantity (terlaris)
            final sortedProducts = productStats.values.toList()
              ..sort(
                (a, b) =>
                    (b['quantity'] as int).compareTo(a['quantity'] as int),
              );

            if (sortedProducts.isEmpty) {
              return const Center(child: Text('Belum ada data penjualan'));
            }

            var topProducts = sortedProducts.take(10).toList();
            if (_reversed) topProducts = topProducts.reversed.toList();

            final maxQuantity =
                (sortedProducts.take(10).first['quantity'] as int).toDouble();

            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topProducts.length,
                itemBuilder: (context, index) {
                  final product = topProducts[index];
                  final profit = product['profit'] as double;
                  final quantity = product['quantity'] as int;
                  final percentage = maxQuantity > 0
                      ? (quantity / maxQuantity) * 100
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${product['name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$quantity terjual',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _showFullAmount
                                  ? CurrencyFormatter.format(profit)
                                  : CurrencyFormatter.formatCompact(profit),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: cs.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 6,
                            backgroundColor: cs.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
                            ),
                          ),
                        ),
                        if (index < topProducts.length - 1)
                          const Divider(height: 16, thickness: 1),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
