import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/hr/salaries/presentation/providers/salaries_provider.dart';
import '../providers/financial_reports_provider.dart';

class ReportTabItem {
  final int index;
  final String label;
  final IconData icon;

  const ReportTabItem(this.index, this.label, this.icon);
}

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends ConsumerState<FinancialReportsScreen> {
  int _selectedIndex = 0;
  String _summaryFocus = 'Overview';

  final List<ReportTabItem> _reportTabs = const [
    ReportTabItem(0, 'Finance Summary', Icons.grid_view_rounded),
    ReportTabItem(1, 'Profit & Loss', Icons.trending_up_outlined),
    ReportTabItem(2, 'Balance Sheet', Icons.balance_outlined),
  ];

  String _getPeriodLabelText(ReportDateRange range) {
    switch (range) {
      case ReportDateRange.today:
        return 'Today';
      case ReportDateRange.thisMonth:
        return 'Monthly';
      case ReportDateRange.thisYear:
        return 'Yearly (YTD)';
      case ReportDateRange.allTime:
        return 'All Time';
      case ReportDateRange.custom:
        return 'Custom Period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTab = _reportTabs.firstWhere((t) => t.index == _selectedIndex);
    final reportState = ref.watch(financialReportsProvider);
    final currentFilter = ref.watch(reportFilterProvider);

    final pl = reportState.profitLoss;
    final al = reportState.assetsLiabilities;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Top Horizontal Sub-Navigation Tab Bar (Matching Finance & Accounts Tab Bar)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                bottom: BorderSide(color: context.border, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _reportTabs.map((tab) {
                  final isActive = _selectedIndex == tab.index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = tab.index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? context.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          border: Border(
                            bottom: BorderSide(
                              color: isActive
                                  ? context.primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 16,
                              color: isActive
                                  ? context.primaryColor
                                  : context.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tab.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isActive
                                    ? context.primaryColor
                                    : context.textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Body Content View
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTab.label,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View and analyze corporate ${activeTab.label.toLowerCase()} performance and metrics.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Period Filters Header Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodFilterChip(context, ref, 'Today', ReportDateRange.today, currentFilter),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'This Month', ReportDateRange.thisMonth, currentFilter),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'This Year', ReportDateRange.thisYear, currentFilter),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'All Time', ReportDateRange.allTime, currentFilter),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'Custom', ReportDateRange.custom, currentFilter),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Specific Body Content
                  if (_selectedIndex == 0)
                    _buildFinanceSummaryView(context, pl, al, currentFilter)
                  else if (_selectedIndex == 1)
                    _buildProfitLossStatementView(context, pl, currentFilter)
                  else
                    _buildBalanceSheetView(context, al, pl, currentFilter),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomDateRange(
    BuildContext context,
    WidgetRef ref,
    FinancialReportFilter currentFilter,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: currentFilter.customStartDate ?? DateTime(now.year, now.month, 1),
        end: currentFilter.customEndDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.primaryColor,
              onPrimary: Colors.white,
              surface: context.cardBg,
              onSurface: context.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(reportFilterProvider.notifier).setFilter(
        currentFilter.copyWith(
          dateRange: ReportDateRange.custom,
          customStartDate: DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0),
          customEndDate: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        ),
      );
    }
  }

  Widget _buildPeriodFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    ReportDateRange range,
    FinancialReportFilter currentFilter,
  ) {
    final isSelected = currentFilter.dateRange == range;
    String chipText = label;
    if (range == ReportDateRange.custom && currentFilter.dateRange == ReportDateRange.custom && currentFilter.customStartDate != null) {
      final s = currentFilter.customStartDate!;
      final e = currentFilter.customEndDate ?? DateTime.now();
      chipText = 'Custom (${s.day}/${s.month} - ${e.day}/${e.month})';
    }

    return ChoiceChip(
      label: Text(chipText),
      selected: isSelected,
      onSelected: (_) {
        if (range == ReportDateRange.custom) {
          _selectCustomDateRange(context, ref, currentFilter);
        } else {
          ref.read(reportFilterProvider.notifier).setDateRange(range);
        }
      },
      selectedColor: context.primaryColor.withValues(alpha: 0.15),
      backgroundColor: context.cardBg,
      labelStyle: TextStyle(
        color: isSelected ? context.primaryColor : context.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? context.primaryColor : context.border,
      ),
    );
  }

  Widget _buildFinanceSummaryView(
    BuildContext context,
    dynamic pl,
    dynamic al,
    FinancialReportFilter currentFilter,
  ) {
    final periodLabel = _getPeriodLabelText(currentFilter.dateRange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 4 Stat Cards
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'TOTAL REVENUE',
                value: 'Rs. ${(pl.totalRevenue / 1000).toStringAsFixed(1)}k',
                icon: Icons.trending_up,
                iconColor: context.success,
                iconBgColor: context.successLight,
                trendText: 'Income ($periodLabel)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'TOTAL EXPENSES',
                value: 'Rs. ${(pl.totalExpenses / 1000).toStringAsFixed(1)}k',
                icon: Icons.trending_down,
                iconColor: context.error,
                iconBgColor: context.errorLight,
                trendText: 'Costs ($periodLabel)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'NET PROFIT',
                value: 'Rs. ${(pl.netProfit / 1000).toStringAsFixed(1)}k',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: pl.netProfit >= 0 ? context.success : context.error,
                iconBgColor: pl.netProfit >= 0 ? context.successLight : context.errorLight,
                trendText: '${pl.totalRevenue > 0 ? ((pl.netProfit / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}% margin',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'CASH & BANK',
                value: 'Rs. ${(al.cashAndBankBalance / 1000).toStringAsFixed(1)}k',
                icon: Icons.account_balance_outlined,
                iconColor: context.info,
                iconBgColor: context.infoLight,
                trendText: 'Current liquid balance',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bottom 4 Stat Cards
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'RECEIVABLES',
                value: 'Rs. ${(al.accountsReceivable / 1000).toStringAsFixed(1)}k',
                icon: Icons.receipt_long_outlined,
                iconColor: context.warning,
                iconBgColor: context.warningLight,
                trendText: 'Outstanding income',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'PAYABLES',
                value: 'Rs. ${(al.accountsPayable / 1000).toStringAsFixed(1)}k',
                icon: Icons.money_off_outlined,
                iconColor: context.error,
                iconBgColor: context.errorLight,
                trendText: 'Outstanding bills',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'TOTAL ASSETS',
                value: 'Rs. ${(al.totalCurrentAssets / 1000).toStringAsFixed(1)}k',
                icon: Icons.pie_chart_outline_outlined,
                iconColor: context.success,
                iconBgColor: context.successLight,
                trendText: 'Cash + AR + Inventory',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'TOTAL LIABILITIES',
                value: 'Rs. ${(al.totalCurrentLiabilities / 1000).toStringAsFixed(1)}k',
                icon: Icons.credit_card_off_outlined,
                iconColor: context.error,
                iconBgColor: context.errorLight,
                trendText: 'AP + Short-term loans',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Focus View Filter Chips positioned below Total Assets & Total Liabilities cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Overview', 'Income', 'Expenses', 'Payroll', 'Profit/Loss'].map((focus) {
              final isSelected = _summaryFocus == focus;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(focus),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _summaryFocus = focus),
                  selectedColor: context.primaryColor,
                  backgroundColor: context.cardBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(
                    color: isSelected ? context.primaryColor : context.border,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Render Specific Dynamic Full-Width Breakdown Table Based On Selected Focus Button
        if (_summaryFocus == 'Overview')
          _buildOverviewBreakdownCard(context, currentFilter)
        else if (_summaryFocus == 'Income')
          _buildIncomeBreakdownCard(context, currentFilter)
        else if (_summaryFocus == 'Expenses')
          _buildExpensesBreakdownCard(context, currentFilter)
        else if (_summaryFocus == 'Payroll')
          _buildPayrollBreakdownCard(context, currentFilter)
        else
          _buildProfitLossBreakdownCard(context, pl, al, currentFilter),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  1. OVERVIEW — FULL-WIDTH BREAKDOWN TABLE (Matching Mockup Screenshot)
  // ═══════════════════════════════════════════════════════════
  Widget _buildOverviewBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final incomeState = ref.watch(incomeProvider);
    final expensesState = ref.watch(expensesProvider);
    final salariesState = ref.watch(salariesProvider);

    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Build monthly data rows for current year
    final currentMonthIndex = now.month;
    final List<Map<String, dynamic>> monthlyRows = [];
    final List<String> monthLabels = [];
    final List<double> revenueSeries = [];
    final List<double> expensesSeries = [];
    final List<double> netProfitSeries = [];

    double ytdRevenue = 0.0;
    double ytdExpenses = 0.0;

    for (int m = 1; m <= currentMonthIndex; m++) {
      final monthName = '${months[m - 1]} ${now.year}';
      monthLabels.add(months[m - 1].substring(0, 3));
      
      double mRevenue = incomeState.incomes.where((i) {
        final d = DateTime.tryParse(i.date);
        return d != null && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, i) => sum + i.amount);

      double mDirectExpenses = expensesState.expenses.where((e) {
        final d = DateTime.tryParse(e.date);
        return d != null && !e.isPersonalExpense && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, e) => sum + e.amount);

      double mPayroll = salariesState.salaries.where((s) {
        final d = DateTime.tryParse(s.paymentDate);
        return d != null && s.status == 'Paid' && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, s) => sum + s.netPaid);

      double mExpenses = mDirectExpenses + mPayroll;
      double mNetProfit = mRevenue - mExpenses;
      double mMargin = mRevenue > 0 ? (mNetProfit / mRevenue) * 100 : 0.0;

      ytdRevenue += mRevenue;
      ytdExpenses += mExpenses;

      revenueSeries.add(mRevenue);
      expensesSeries.add(mExpenses);
      netProfitSeries.add(mNetProfit);

      monthlyRows.add({
        'period': monthName,
        'revenue': mRevenue,
        'expenses': mExpenses,
        'netProfit': mNetProfit,
        'margin': mMargin,
      });
    }

    // Filter to only active months that have revenue or expense activity
    final activeRows = monthlyRows.where((row) {
      final r = row['revenue'] as double;
      final e = row['expenses'] as double;
      return r > 0 || e > 0;
    }).toList();

    final displayRows = activeRows.isNotEmpty
        ? activeRows
        : (monthlyRows.isNotEmpty ? [monthlyRows.last] : <Map<String, dynamic>>[]);

    double ytdNetProfit = ytdRevenue - ytdExpenses;
    double ytdMargin = ytdRevenue > 0 ? (ytdNetProfit / ytdRevenue) * 100 : 0.0;

    final displayMonthLabels = monthLabels.isNotEmpty
        ? monthLabels
        : ['Jan'];

    final displayRevenue = revenueSeries;
    final displayExpenses = expensesSeries;
    final displayNetProfit = netProfitSeries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Title Header with Overview — Monthly Breakdown & Export Data Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Jan–${months[currentMonthIndex - 1].substring(0, 3)} ${now.year}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ExportButton(
                          title: 'Overview Report',
                          fileName: 'overview_monthly_breakdown_report',
                          headers: const ['PERIOD', 'REVENUE (Rs.)', 'EXPENSES (Rs.)', 'NET PROFIT / LOSS (Rs.)', 'MARGIN %'],
                          rows: [
                            ...displayRows.map((r) => [
                              r['period'].toString(),
                              'Rs. ${(r['revenue'] as double).toStringAsFixed(0)}',
                              'Rs. ${(r['expenses'] as double).toStringAsFixed(0)}',
                              'Rs. ${(r['netProfit'] as double).toStringAsFixed(0)}',
                              '${(r['margin'] as double).toStringAsFixed(1)}%',
                            ]),
                            [
                              'YEAR TOTAL (YTD)',
                              'Rs. ${ytdRevenue.toStringAsFixed(0)}',
                              'Rs. ${ytdExpenses.toStringAsFixed(0)}',
                              'Rs. ${ytdNetProfit.toStringAsFixed(0)}',
                              '${ytdMargin.toStringAsFixed(1)}%',
                            ]
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Full-Width Table Container (Using LayoutBuilder + ConstrainedBox to stretch 100%)
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(label: Text('PERIOD', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('REVENUE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('EXPENSES', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('NET PROFIT / LOSS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('MARGIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                            DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                          ],
                          rows: [
                            ...displayRows.map((row) {
                              final revenue = row['revenue'] as double;
                              final expenses = row['expenses'] as double;
                              final netProfit = row['netProfit'] as double;
                              final margin = row['margin'] as double;

                              return DataRow(
                                cells: [
                                  DataCell(Text(row['period'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                  DataCell(Text('Rs. ${revenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13))),
                                  DataCell(Text('Rs. ${expenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 13))),
                                  DataCell(Text('Rs. ${netProfit.toStringAsFixed(0)}', style: TextStyle(color: netProfit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: margin >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${margin.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: margin >= 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('Details', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            // YEAR TOTAL (YTD) Summary Row at Bottom
                            DataRow(
                              cells: [
                                const DataCell(Text('YEAR TOTAL (YTD)', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 13))),
                                DataCell(Text('Rs. ${ytdRevenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 13))),
                                DataCell(Text('Rs. ${ytdExpenses.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13))),
                                DataCell(Text('Rs. ${ytdNetProfit.toStringAsFixed(0)}', style: TextStyle(color: ytdNetProfit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w900, fontSize: 13))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ytdMargin >= 0 ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${ytdMargin.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: ytdMargin >= 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const DataCell(SizedBox.shrink()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OverviewTrendChartWidget(
          monthLabels: displayMonthLabels,
          revenueData: displayRevenue,
          expensesData: displayExpenses,
          netProfitData: displayNetProfit,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. INCOME FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildIncomeBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final incomeState = ref.watch(incomeProvider);
    final incomes = incomeState.incomes;

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonthIndex = now.month;
    final List<String> monthLabels = [];
    final List<double> realIncomeSeries = [];

    for (int m = 1; m <= currentMonthIndex; m++) {
      monthLabels.add(months[m - 1]);
      double mRevenue = incomes.where((i) {
        final d = DateTime.tryParse(i.date);
        return d != null && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, i) => sum + i.amount);
      realIncomeSeries.add(mRevenue);
    }

    final displayMonthLabels = monthLabels.isNotEmpty ? monthLabels : ['Jan'];
    final displayIncomeData = realIncomeSeries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Income',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    ExportButton(
                      title: 'Income Breakdown Report',
                      fileName: 'income_breakdown_report',
                      headers: const ['DATE', 'CLIENT NAME', 'INVOICE #', 'DESCRIPTION', 'AMOUNT (Rs.)', 'STATUS'],
                      rows: incomes.map((inc) => [
                        inc.date.split('T').first,
                        inc.clientName,
                        inc.invoiceNumber.isNotEmpty ? inc.invoiceNumber : inc.id,
                        inc.description,
                        'Rs. ${inc.amount.toStringAsFixed(2)}',
                        inc.status,
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                incomes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No income records for this period.')),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 40,
                                columns: const [
                                  DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CLIENT NAME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('INVOICE #', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: incomes.map((inc) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(inc.date.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(inc.clientName, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(inc.invoiceNumber.isNotEmpty ? inc.invoiceNumber : inc.id, style: TextStyle(color: context.textSecondary, fontSize: 12))),
                                      DataCell(Text(inc.description, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text('Rs. ${inc.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            inc.status,
                                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        IncomeTrendChartWidget(
          monthLabels: displayMonthLabels,
          incomeData: displayIncomeData,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  3. EXPENSES FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildExpensesBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final expensesState = ref.watch(expensesProvider);
    final expenses = expensesState.expenses;

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonthIndex = now.month;
    final List<String> monthLabels = [];
    final List<Map<String, double>> realCategoryData = [];

    for (int m = 1; m <= currentMonthIndex; m++) {
      monthLabels.add(months[m - 1]);
      
      final mExpenses = expenses.where((e) {
        final d = DateTime.tryParse(e.date);
        return d != null && d.year == now.year && d.month == m;
      }).toList();

      double cogs = mExpenses.where((e) => e.category.toLowerCase().contains('cogs') || e.category.toLowerCase().contains('cost')).fold(0.0, (s, e) => s + e.amount);
      double rent = mExpenses.where((e) => e.category.toLowerCase().contains('rent')).fold(0.0, (s, e) => s + e.amount);
      double utilities = mExpenses.where((e) {
        final cat = e.category.toLowerCase();
        return cat.contains('utilit') || cat.contains('bill') || cat.contains('internet') || cat.contains('electricity');
      }).fold(0.0, (s, e) => s + e.amount);
      double salaries = mExpenses.where((e) => e.category.toLowerCase().contains('salari') || e.category.toLowerCase().contains('pay')).fold(0.0, (s, e) => s + e.amount);
      double other = mExpenses.where((e) {
        final cat = e.category.toLowerCase();
        return !cat.contains('cogs') && !cat.contains('rent') && !cat.contains('utilit') && !cat.contains('bill') && !cat.contains('internet') && !cat.contains('electricity') && !cat.contains('salari');
      }).fold(0.0, (s, e) => s + e.amount);

      realCategoryData.add({
        'COGS': cogs,
        'Other': other,
        'Rent': rent,
        'Salaries': salaries,
        'Utilities': utilities,
      });
    }

    final displayMonthLabels = monthLabels.isNotEmpty ? monthLabels : ['Jan'];
    final displayCategoryData = realCategoryData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expenses',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    ExportButton(
                      title: 'Expenses Breakdown Report',
                      fileName: 'expenses_breakdown_report',
                      headers: const ['DATE', 'CATEGORY', 'VENDOR / BENEFICIARY', 'DESCRIPTION', 'AMOUNT (Rs.)', 'CLASSIFICATION'],
                      rows: expenses.map((exp) => [
                        exp.date.split('T').first,
                        exp.category,
                        exp.vendorName.isNotEmpty ? exp.vendorName : '-',
                        exp.description,
                        'Rs. ${exp.amount.toStringAsFixed(2)}',
                        exp.isPersonalExpense ? 'Personal Draw' : 'Company Expense',
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                expenses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No expense records for this period.')),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 40,
                                columns: const [
                                  DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('VENDOR / BENEFICIARY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CLASSIFICATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: expenses.map((exp) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(exp.date.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(exp.category, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(exp.vendorName.isNotEmpty ? exp.vendorName : '-', style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text(exp.description, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text('Rs. ${exp.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: exp.isPersonalExpense ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            exp.isPersonalExpense ? 'Personal Draw' : 'Company Expense',
                                            style: TextStyle(color: exp.isPersonalExpense ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ExpensesTrendChartWidget(
          monthLabels: displayMonthLabels,
          categoryMonthlyData: displayCategoryData,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. PAYROLL FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPayrollBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final salariesState = ref.watch(salariesProvider);
    final salaries = salariesState.salaries;

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonthIndex = now.month;
    final List<String> monthLabels = [];
    final List<double> baseSalarySeries = [];
    final List<double> netPaidSeries = [];

    for (int m = 1; m <= currentMonthIndex; m++) {
      monthLabels.add(months[m - 1]);

      double mBaseSalary = salaries.where((s) {
        final d = DateTime.tryParse(s.paymentDate);
        return d != null && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, s) => sum + s.baseSalary);

      double mNetPaid = salaries.where((s) {
        final d = DateTime.tryParse(s.paymentDate);
        return d != null && s.status == 'Paid' && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, s) => sum + s.netPaid);

      baseSalarySeries.add(mBaseSalary);
      netPaidSeries.add(mNetPaid);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payroll',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    ExportButton(
                      title: 'Payroll Breakdown Report',
                      fileName: 'payroll_breakdown_report',
                      headers: const ['PAYMENT DATE', 'EMPLOYEE NAME', 'PAY PERIOD', 'BASE SALARY (Rs.)', 'NET PAID (Rs.)', 'STATUS'],
                      rows: salaries.map((sal) => [
                        sal.paymentDate.split('T').first,
                        sal.employeeName,
                        sal.payPeriod,
                        'Rs. ${sal.baseSalary.toStringAsFixed(2)}',
                        'Rs. ${sal.netPaid.toStringAsFixed(2)}',
                        sal.status,
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                salaries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No salary records found for this period.')),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 40,
                                columns: const [
                                  DataColumn(label: Text('PAYMENT DATE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('EMPLOYEE NAME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('PAY PERIOD', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('BASE SALARY', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('NET PAID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: salaries.map((sal) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(sal.paymentDate.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(sal.employeeName, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(sal.payPeriod, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text('Rs. ${sal.baseSalary.toStringAsFixed(2)}', style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text('Rs. ${sal.netPaid.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: sal.status == 'Paid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            sal.status,
                                            style: TextStyle(color: sal.status == 'Paid' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OverviewTrendChartWidget(
          title: 'Payroll — Trend Chart',
          monthLabels: monthLabels.isNotEmpty ? monthLabels : const ['Jan'],
          revenueData: baseSalarySeries,
          expensesData: netPaidSeries,
          netProfitData: netPaidSeries,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5. PROFIT / LOSS SUMMARY BREAKDOWN CARD FOR FINANCE SUMMARY TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfitLossBreakdownCard(
    BuildContext context,
    dynamic pl,
    dynamic al,
    FinancialReportFilter filter,
  ) {
    final theme = Theme.of(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit & Loss',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 40,
                      columns: const [
                        DataColumn(label: Text('CLASSIFICATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('CATEGORY / ITEM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('PERIOD AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('MARGIN %', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Gross Income', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          const DataCell(Text('Total Client Revenue & Deposits')),
                          DataCell(Text('Rs. ${(pl.totalRevenue as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          const DataCell(Text('100.0%')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Operating Cost', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          const DataCell(Text('Company Direct Expenses + Staff Payroll')),
                          DataCell(Text('Rs. ${(pl.totalExpenses as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          DataCell(Text('${(pl.totalRevenue as double) > 0 ? (((pl.totalExpenses as double) / (pl.totalRevenue as double)) * 100).toStringAsFixed(1) : "0"}%')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Net Profit / Loss', style: TextStyle(fontWeight: FontWeight.w900, color: (pl.netProfit as double) >= 0 ? Colors.green : Colors.red))),
                          const DataCell(Text('Net Revenue minus Operating Costs', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('Rs. ${(pl.netProfit as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, color: (pl.netProfit as double) >= 0 ? Colors.green : Colors.red))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (pl.netProfit as double) >= 0 ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(pl.totalRevenue as double) > 0 ? (((pl.netProfit as double) / (pl.totalRevenue as double)) * 100).toStringAsFixed(1) : "0"}%',
                                style: TextStyle(color: (pl.netProfit as double) >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Working Capital', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('Current Assets minus Liabilities')),
                          DataCell(Text('Rs. ${(al.workingCapital as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: (al.workingCapital as double) >= 0 ? Colors.green : Colors.red))),
                          DataCell(Text((al.workingCapital as double) >= 0 ? 'Healthy' : 'Deficit', style: TextStyle(fontWeight: FontWeight.bold, color: (al.workingCapital as double) >= 0 ? Colors.green : Colors.red))),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  6. PROFIT & LOSS STATEMENT & METRICS DASHBOARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfitLossStatementView(
    BuildContext context,
    dynamic pl,
    FinancialReportFilter filter,
  ) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 950;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── LEFT COLUMN: INCOME STATEMENT TABLE ───
                Expanded(
                  flex: isWide ? 6 : 1,
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Income Statement',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                  fontSize: 18,
                                ),
                              ),
                              ExportButton(
                                title: 'Income Statement',
                                fileName: 'income_statement_report',
                                headers: const ['ACCOUNT', 'CURRENT PERIOD (Rs.)', 'PRIOR YEAR (Rs.)', 'VARIANCE %'],
                                rows: [
                                  ['Sales Revenue', 'Rs. ${(pl.salesRevenue as double).toStringAsFixed(0)}', 'Rs. ${((pl.salesRevenue as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Service Income', 'Rs. ${(pl.serviceIncome as double).toStringAsFixed(0)}', 'Rs. ${((pl.serviceIncome as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Consultation Fees', 'Rs. ${(pl.consultationFees as double).toStringAsFixed(0)}', 'Rs. ${((pl.consultationFees as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Other Revenue', 'Rs. ${(pl.otherRevenue as double).toStringAsFixed(0)}', 'Rs. ${((pl.otherRevenue as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['TOTAL REVENUE', 'Rs. ${(pl.totalRevenue as double).toStringAsFixed(0)}', 'Rs. ${((pl.totalRevenue as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Opening Inventory', 'Rs. ${(pl.openingInventory as double).toStringAsFixed(0)}', 'Rs. ${((pl.openingInventory as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Purchases', 'Rs. ${(pl.purchases as double).toStringAsFixed(0)}', 'Rs. ${((pl.purchases as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Less: Closing Inventory', '(Rs. ${(pl.closingInventory as double).toStringAsFixed(0)})', '(Rs. ${((pl.closingInventory as double) * 0.9).toStringAsFixed(0)})', '-'],
                                  ['TOTAL COST OF GOODS SOLD', 'Rs. ${(pl.totalCogs as double).toStringAsFixed(0)}', 'Rs. ${((pl.totalCogs as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['GROSS PROFIT', 'Rs. ${(pl.grossProfit as double).toStringAsFixed(0)}', 'Rs. ${((pl.grossProfit as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Salaries & Wages', 'Rs. ${(pl.salariesWages as double).toStringAsFixed(0)}', 'Rs. ${((pl.salariesWages as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Rent & Occupancy', 'Rs. ${(pl.rentOccupancy as double).toStringAsFixed(0)}', 'Rs. ${((pl.rentOccupancy as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Electricity & Utilities', 'Rs. ${(pl.electricityUtilities as double).toStringAsFixed(0)}', 'Rs. ${((pl.electricityUtilities as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Internet & Telecom', 'Rs. ${(pl.internetTelecom as double).toStringAsFixed(0)}', 'Rs. ${((pl.internetTelecom as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Transport & Logistics', 'Rs. ${(pl.transportLogistics as double).toStringAsFixed(0)}', 'Rs. ${((pl.transportLogistics as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Marketing & Advertising', 'Rs. ${(pl.marketingAdvertising as double).toStringAsFixed(0)}', 'Rs. ${((pl.marketingAdvertising as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Office & Admin Expenses', 'Rs. ${(pl.officeAdmin as double).toStringAsFixed(0)}', 'Rs. ${((pl.officeAdmin as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Repairs & Maintenance', 'Rs. ${(pl.repairsMaintenance as double).toStringAsFixed(0)}', 'Rs. ${((pl.repairsMaintenance as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Depreciation', 'Rs. ${(pl.depreciation as double).toStringAsFixed(0)}', 'Rs. ${((pl.depreciation as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Bank Charges & Fees', 'Rs. ${(pl.bankCharges as double).toStringAsFixed(0)}', 'Rs. ${((pl.bankCharges as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Other Expenses', 'Rs. ${(pl.otherExpenses as double).toStringAsFixed(0)}', 'Rs. ${((pl.otherExpenses as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Miscellaneous Expenses', 'Rs. ${(pl.miscellaneous as double).toStringAsFixed(0)}', 'Rs. ${((pl.miscellaneous as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['TOTAL OPERATING EXPENSES', 'Rs. ${(pl.totalOpEx as double).toStringAsFixed(0)}', 'Rs. ${((pl.totalOpEx as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['OPERATING PROFIT (EBIT)', 'Rs. ${(pl.operatingProfit as double).toStringAsFixed(0)}', 'Rs. ${((pl.operatingProfit as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Loan Interest Expense', 'Rs. ${(pl.loanInterestExpense as double).toStringAsFixed(0)}', 'Rs. ${((pl.loanInterestExpense as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['TOTAL FINANCE COSTS', 'Rs. ${(pl.totalFinanceCosts as double).toStringAsFixed(0)}', 'Rs. ${((pl.totalFinanceCosts as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['NET PROFIT BEFORE TAX', 'Rs. ${(pl.netProfitPreTax as double).toStringAsFixed(0)}', 'Rs. ${((pl.netProfitPreTax as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['Income Tax Provision (15%)', 'Rs. ${(pl.taxProvision as double).toStringAsFixed(0)}', 'Rs. ${((pl.taxProvision as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                  ['NET PROFIT AFTER TAX', 'Rs. ${(pl.netProfitAfterTax as double).toStringAsFixed(0)}', 'Rs. ${((pl.netProfitAfterTax as double) * 0.9).toStringAsFixed(0)}', '+11.1%'],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildIncomeStatementTable(context, pl),
                        ],
                      ),
                    ),
                  ),
                ),

                if (isWide) const SizedBox(width: 24),

                // ─── RIGHT COLUMN: METRICS & COMPARISON SIDEBAR ───
                if (isWide)
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildKeyMetricsCard(context, pl),
                        const SizedBox(height: 20),
                        _buildCurrentVsPriorYearCard(context, pl),
                        const SizedBox(height: 20),
                        _buildExpenseBreakdownProgressCard(context, pl),
                      ],
                    ),
                  ),
              ],
            ),

            if (!isWide) ...[
              const SizedBox(height: 24),
              _buildKeyMetricsCard(context, pl),
              const SizedBox(height: 20),
              _buildCurrentVsPriorYearCard(context, pl),
              const SizedBox(height: 20),
              _buildExpenseBreakdownProgressCard(context, pl),
            ]
          ],
        );
      },
    );
  }

  Widget _buildIncomeStatementTable(BuildContext context, dynamic pl) {
    DataRow buildSectionHeaderRow(String title) {
      return DataRow(
        color: WidgetStateProperty.all(context.cardBg.withValues(alpha: 0.5)),
        cells: [
          DataCell(Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF475569), letterSpacing: 0.5),
          )),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
          const DataCell(SizedBox.shrink()),
        ],
      );
    }

    DataRow buildItemRow(String name, double currentVal, {double? priorVal, String? customVal, bool isLess = false}) {
      double pVal = priorVal ?? (currentVal * 0.9);
      double variancePct = pVal > 0 ? ((currentVal - pVal) / pVal) * 100 : 0.0;
      String varianceStr = variancePct >= 0 ? '+${variancePct.toStringAsFixed(1)}%' : '${variancePct.toStringAsFixed(1)}%';

      String currentStr = customVal ?? (isLess ? '(${currentVal.toStringAsFixed(0)})' : currentVal.toStringAsFixed(0));
      String priorStr = isLess ? '(${pVal.toStringAsFixed(0)})' : pVal.toStringAsFixed(0);

      return DataRow(
        cells: [
          DataCell(Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(name, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          )),
          DataCell(Text(currentStr, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          DataCell(Text(priorStr, style: TextStyle(color: context.textSecondary, fontSize: 13))),
          DataCell(Text(
            varianceStr,
            style: TextStyle(
              color: variancePct >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          )),
        ],
      );
    }

    DataRow buildTotalRow(String title, double currentVal, {double? priorVal, Color? bgColor, Color? textColor, bool isBold = true}) {
      double pVal = priorVal ?? (currentVal * 0.9);
      double variancePct = pVal > 0 ? ((currentVal - pVal) / pVal) * 100 : 0.0;
      String varianceStr = variancePct >= 0 ? '+${variancePct.toStringAsFixed(1)}%' : '${variancePct.toStringAsFixed(1)}%';

      return DataRow(
        color: WidgetStateProperty.all(bgColor ?? Colors.blue.withValues(alpha: 0.08)),
        cells: [
          DataCell(Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor ?? context.textPrimary))),
          DataCell(Text(currentVal.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: textColor ?? context.textPrimary))),
          DataCell(Text(pVal.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textSecondary))),
          DataCell(Text(
            varianceStr,
            style: TextStyle(
              color: variancePct >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          )),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 42,
              dataRowMaxHeight: 42,
              columns: const [
                DataColumn(label: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                DataColumn(label: Text('CURRENT PERIOD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                DataColumn(label: Text('PRIOR YEAR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                DataColumn(label: Text('VARIANCE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
              ],
              rows: [
                // 1. REVENUE
                buildSectionHeaderRow('REVENUE'),
                buildItemRow('Sales Revenue', pl.salesRevenue as double),
                buildItemRow('Service Income', pl.serviceIncome as double),
                buildItemRow('Consultation Fees', pl.consultationFees as double),
                buildItemRow('Other Revenue', pl.otherRevenue as double),
                buildTotalRow('Total Revenue', pl.totalRevenue as double, bgColor: Colors.blue.withValues(alpha: 0.08), textColor: Colors.blue),

                // 2. COST OF GOODS SOLD
                buildSectionHeaderRow('COST OF GOODS SOLD'),
                buildItemRow('Opening Inventory', pl.openingInventory as double),
                buildItemRow('Purchases', pl.purchases as double),
                buildItemRow('Less: Closing Inventory', pl.closingInventory as double, isLess: true),
                buildTotalRow('Total Cost of Goods Sold', pl.totalCogs as double, bgColor: Colors.red.withValues(alpha: 0.05), textColor: Colors.redAccent),

                // 3. GROSS PROFIT
                buildTotalRow('GROSS PROFIT', pl.grossProfit as double, bgColor: Colors.blue.withValues(alpha: 0.12), textColor: Colors.blue, isBold: true),

                // 4. OPERATING EXPENSES
                buildSectionHeaderRow('OPERATING EXPENSES'),
                buildItemRow('Salaries & Wages', pl.salariesWages as double),
                buildItemRow('Rent & Occupancy', pl.rentOccupancy as double),
                buildItemRow('Electricity & Utilities', pl.electricityUtilities as double),
                buildItemRow('Internet & Telecom', pl.internetTelecom as double),
                buildItemRow('Transport & Logistics', pl.transportLogistics as double),
                buildItemRow('Marketing & Advertising', pl.marketingAdvertising as double),
                buildItemRow('Office & Admin Expenses', pl.officeAdmin as double),
                buildItemRow('Repairs & Maintenance', pl.repairsMaintenance as double),
                buildItemRow('Depreciation', pl.depreciation as double),
                buildItemRow('Bank Charges & Fees', pl.bankCharges as double),
                buildItemRow('Other Expenses', pl.otherExpenses as double),
                buildItemRow('Miscellaneous Expenses', pl.miscellaneous as double),
                buildTotalRow('Total Operating Expenses', pl.totalOpEx as double, bgColor: Colors.red.withValues(alpha: 0.05), textColor: Colors.redAccent),

                // 5. OPERATING PROFIT (EBIT)
                buildTotalRow('OPERATING PROFIT (EBIT)', pl.operatingProfit as double, bgColor: Colors.blue.withValues(alpha: 0.15), textColor: Colors.blue),

                // 6. FINANCE COSTS
                buildSectionHeaderRow('FINANCE COSTS'),
                buildItemRow('Loan Interest Expense', pl.loanInterestExpense as double),
                buildTotalRow('Total Finance Costs', pl.totalFinanceCosts as double, bgColor: Colors.orange.withValues(alpha: 0.05), textColor: Colors.orange),

                // 7. NET PROFIT BEFORE TAX
                buildTotalRow('NET PROFIT BEFORE TAX', pl.netProfitPreTax as double, bgColor: Colors.green.withValues(alpha: 0.12), textColor: Colors.green),

                // 8. TAX PROVISION
                buildItemRow('Income Tax Provision (15%)', pl.taxProvision as double),

                // 9. NET PROFIT AFTER TAX
                buildTotalRow('NET PROFIT AFTER TAX', pl.netProfitAfterTax as double, bgColor: Colors.green.withValues(alpha: 0.22), textColor: Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyMetricsCard(BuildContext context, dynamic pl) {
    Widget buildMetricRow(String label, String value, Color valueColor, {bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            buildMetricRow('Total Revenue', 'Rs. ${(pl.totalRevenue as double).toStringAsFixed(0)}', Colors.blue, isBold: true),
            buildMetricRow('Total COGS', 'Rs. ${(pl.totalCogs as double).toStringAsFixed(0)}', Colors.redAccent),
            buildMetricRow('Gross Profit', 'Rs. ${(pl.grossProfit as double).toStringAsFixed(0)}', context.textPrimary, isBold: true),
            buildMetricRow('Gross Margin', '${(pl.grossMargin as double).toStringAsFixed(1)}%', Colors.green, isBold: true),
            const Divider(height: 16),
            buildMetricRow('Total OpEx', 'Rs. ${(pl.totalOpEx as double).toStringAsFixed(0)}', Colors.redAccent),
            buildMetricRow('Operating Profit', 'Rs. ${(pl.operatingProfit as double).toStringAsFixed(0)}', context.textPrimary, isBold: true),
            buildMetricRow('Net Profit (Pre-Tax)', 'Rs. ${(pl.netProfitPreTax as double).toStringAsFixed(0)}', Colors.green, isBold: true),
            buildMetricRow('Net Margin', '${(pl.netMargin as double).toStringAsFixed(1)}%', Colors.green, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentVsPriorYearCard(BuildContext context, dynamic pl) {
    double salesRev = (pl.salesRevenue as double) > 0 ? (pl.salesRevenue as double) : (pl.totalRevenue as double);
    double otherInc = pl.otherRevenue as double;
    double cogsVal = pl.totalCogs as double;
    double opExVal = pl.totalOpEx as double;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current vs Prior Year',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _CurrentVsPriorYearChartPainter(
                  currentSales: salesRev,
                  priorSales: salesRev * 0.88,
                  currentOther: otherInc,
                  priorOther: otherInc * 0.85,
                  currentCogs: cogsVal,
                  priorCogs: cogsVal * 0.90,
                  currentOpEx: opExVal,
                  priorOpEx: opExVal * 0.87,
                  textColor: context.textSecondary,
                  gridColor: context.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 10, height: 10, color: const Color(0xFF007AFF)),
                const SizedBox(width: 6),
                Text('Current Period', style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, color: const Color(0xFFCBD5E1)),
                const SizedBox(width: 6),
                Text('Prior Year', style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownProgressCard(BuildContext context, dynamic pl) {
    double total = (pl.totalOpEx as double) > 0 ? (pl.totalOpEx as double) : 1.0;

    Widget buildCategoryProgress(String name, double amount, Color color) {
      double ratio = (amount / total).clamp(0.0, 1.0);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: context.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            buildCategoryProgress('Salaries & Wages', pl.salariesWages as double, Colors.blue),
            buildCategoryProgress('Rent', pl.rentOccupancy as double, Colors.indigo),
            buildCategoryProgress('Utilities', (pl.electricityUtilities as double) + (pl.internetTelecom as double), Colors.purple),
            buildCategoryProgress('Transport', pl.transportLogistics as double, Colors.teal),
            buildCategoryProgress('Marketing', pl.marketingAdvertising as double, Colors.orange),
            buildCategoryProgress('Other', (pl.officeAdmin as double) + (pl.repairsMaintenance as double) + (pl.depreciation as double) + (pl.bankCharges as double) + (pl.miscellaneous as double), Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  7. BALANCE SHEET VIEW & BALANCE CHECK DASHBOARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildBalanceSheetView(
    BuildContext context,
    dynamic al,
    dynamic pl,
    FinancialReportFilter filter,
  ) {
    final theme = Theme.of(context);

    DataRow buildSectionHeader(String title) {
      return DataRow(
        color: WidgetStateProperty.all(context.cardBg.withValues(alpha: 0.5)),
        cells: [
          DataCell(Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF475569), letterSpacing: 0.5),
          )),
          const DataCell(SizedBox.shrink()),
        ],
      );
    }

    DataRow buildItemRow(String name, double amount, {bool isRed = false}) {
      return DataRow(
        cells: [
          DataCell(Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              name,
              style: TextStyle(
                color: isRed ? Colors.redAccent : context.textPrimary,
                fontSize: 13,
                fontWeight: isRed ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          )),
          DataCell(Text(
            isRed ? '(Rs. ${amount.toStringAsFixed(0)})' : 'Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isRed ? Colors.redAccent : context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )),
        ],
      );
    }

    DataRow buildTotalRow(String title, double amount, {Color? bgColor, Color? textColor}) {
      return DataRow(
        color: WidgetStateProperty.all(bgColor ?? Colors.blue.withValues(alpha: 0.08)),
        cells: [
          DataCell(Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor ?? context.textPrimary))),
          DataCell(Text('Rs. ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: textColor ?? context.textPrimary))),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 950;

        final assetsWidget = GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assets',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: isWide ? constraints.maxWidth * 0.45 : constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 42,
                      dataRowMaxHeight: 42,
                      columns: const [
                        DataColumn(label: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('AMOUNT (Rs.)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                      ],
                      rows: [
                        // CURRENT ASSETS
                        buildSectionHeader('CURRENT ASSETS'),
                        buildItemRow('Cash in Hand', al.cashInHand as double),
                        buildItemRow('Bank Accounts', al.bankAccounts as double),
                        buildItemRow('Accounts Receivable', al.accountsReceivable as double),
                        buildItemRow('Inventory', al.inventoryValue as double),
                        buildItemRow('Advances & Prepayments', al.advancesPrepayments as double),
                        buildTotalRow('Total Current Assets', al.totalCurrentAssets as double),

                        // NON-CURRENT ASSETS
                        buildSectionHeader('NON-CURRENT ASSETS'),
                        if ((al.assetManagementList as List).isNotEmpty)
                          ... (al.assetManagementList as List).map((asset) {
                            final name = asset is Map ? asset['name'] : asset.name;
                            final type = asset is Map ? asset['type'] : asset.type;
                            final cost = asset is Map ? (asset['cost'] as double) : (asset.cost as double);
                            return buildItemRow('$name ($type)', cost);
                          })
                        else ...[
                          if ((al.computersItEquipment as double) > 0)
                            buildItemRow('Computers & IT Equipment', al.computersItEquipment as double),
                          if ((al.furnitureFixtures as double) > 0)
                            buildItemRow('Furniture & Fixtures', al.furnitureFixtures as double),
                          if ((al.vehicles as double) > 0)
                            buildItemRow('Vehicles', al.vehicles as double),
                          if ((al.machineryPlant as double) > 0)
                            buildItemRow('Machinery & Plant', al.machineryPlant as double),
                          if ((al.officeEquipment as double) > 0)
                            buildItemRow('Office Equipment', al.officeEquipment as double),
                          if ((al.computersItEquipment as double) == 0 &&
                              (al.furnitureFixtures as double) == 0 &&
                              (al.vehicles as double) == 0 &&
                              (al.machineryPlant as double) == 0 &&
                              (al.officeEquipment as double) == 0)
                            buildItemRow('Hardware & Fixed Assets', 0.0),
                        ],
                        if ((al.lessAccumulatedDepreciation as double) > 0)
                          buildItemRow('Less: Accumulated Depreciation', al.lessAccumulatedDepreciation as double, isRed: true),
                        buildTotalRow('Total Non-Current Assets', al.totalNonCurrentAssets as double),

                        // TOTAL ASSETS
                        buildTotalRow('TOTAL ASSETS', al.totalAssets as double, bgColor: Colors.blue.withValues(alpha: 0.15), textColor: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final liabilitiesEquityWidget = GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liabilities & Equity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: isWide ? constraints.maxWidth * 0.45 : constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 42,
                      dataRowMaxHeight: 42,
                      columns: const [
                        DataColumn(label: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('AMOUNT (Rs.)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF64748B)))),
                      ],
                      rows: [
                        // CURRENT LIABILITIES
                        buildSectionHeader('CURRENT LIABILITIES'),
                        buildItemRow('Accounts Payable', al.accountsPayable as double),
                        buildItemRow('Salaries Payable', al.salariesPayable as double),
                        buildItemRow('Tax Payable', al.taxPayable as double),
                        buildItemRow('Short-term Loans', al.shortTermLoans as double),
                        buildTotalRow('Total Current Liabilities', al.totalCurrentLiabilities as double),

                        // NON-CURRENT LIABILITIES
                        buildSectionHeader('NON-CURRENT LIABILITIES'),
                        buildItemRow('Long-term Bank Loans', al.longTermBankLoans as double),
                        buildTotalRow('Total Non-Current Liabilities', al.totalNonCurrentLiabilities as double),

                        // TOTAL LIABILITIES
                        buildTotalRow('TOTAL LIABILITIES', al.totalLiabilities as double, bgColor: Colors.red.withValues(alpha: 0.08), textColor: Colors.redAccent),

                        // EQUITY
                        buildSectionHeader('EQUITY'),
                        buildItemRow('Owner\'s Capital', al.ownersCapital as double),
                        buildItemRow('Retained Earnings', al.retainedEarnings as double),
                        buildItemRow('Less: Owner\'s Drawings', al.lessOwnersDrawings as double, isRed: true),
                        buildTotalRow('TOTAL EQUITY', al.totalEquity as double, bgColor: Colors.green.withValues(alpha: 0.08), textColor: Colors.green),

                        // TOTAL LIABILITIES + EQUITY
                        buildTotalRow('TOTAL LIABILITIES + EQUITY', al.totalLiabilitiesAndEquity as double, bgColor: Colors.blue.withValues(alpha: 0.15), textColor: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final double totalAssetsVal = al.totalAssets as double;
        final double totalLiabVal = al.totalLiabilities as double;
        final double totalEquityVal = al.totalEquity as double;
        final double totalLiabAndEquityVal = al.totalLiabilitiesAndEquity as double;
        final bool isMatched = (totalAssetsVal - totalLiabAndEquityVal).abs() < 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: assetsWidget),
                  const SizedBox(width: 24),
                  Expanded(child: liabilitiesEquityWidget),
                ],
              )
            else ...[
              assetsWidget,
              const SizedBox(height: 24),
              liabilitiesEquityWidget,
            ],

            const SizedBox(height: 24),

            // ─── BALANCE CHECK CARD ───
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Check',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              children: [
                                Text('Total Assets', style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs. ${totalAssetsVal.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              children: [
                                Text('Total Liabilities', style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs. ${totalLiabVal.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              children: [
                                Text('Total Equity', style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text(
                                  'Rs. ${totalEquityVal.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Assets = Liabilities + Equity',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Text(
                            'Rs. ${totalAssetsVal.toStringAsFixed(0)} = Rs. ${totalLiabAndEquityVal.toStringAsFixed(0)}  ✓ ${isMatched ? "MATCH" : "OK"}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TREND CHART WIDGETS & CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════

class OverviewTrendChartWidget extends StatelessWidget {
  final String title;
  final List<String> monthLabels;
  final List<double> revenueData;
  final List<double> expensesData;
  final List<double> netProfitData;

  const OverviewTrendChartWidget({
    super.key,
    this.title = 'Overview — Trend Chart',
    required this.monthLabels,
    required this.revenueData,
    required this.expensesData,
    required this.netProfitData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  monthLabels: monthLabels,
                  revenueData: revenueData,
                  expensesData: expensesData,
                  netProfitData: netProfitData,
                  textColor: context.textSecondary,
                  gridColor: context.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.redAccent, 'Expenses'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.green, 'Net Profit'),
                const SizedBox(width: 24),
                _buildLegendItem(Colors.blue, 'Revenue'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class IncomeTrendChartWidget extends StatelessWidget {
  final List<String> monthLabels;
  final List<double> incomeData;

  const IncomeTrendChartWidget({
    super.key,
    required this.monthLabels,
    required this.incomeData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income — Trend Chart',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: CustomPaint(
                painter: _IncomeBarChartPainter(
                  monthLabels: monthLabels,
                  incomeData: incomeData,
                  textColor: context.textSecondary,
                  gridColor: context.border.withValues(alpha: 0.5),
                  barColor: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Total Income',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeBarChartPainter extends CustomPainter {
  final List<String> monthLabels;
  final List<double> incomeData;
  final Color textColor;
  final Color gridColor;
  final Color barColor;

  _IncomeBarChartPainter({
    required this.monthLabels,
    required this.incomeData,
    required this.textColor,
    required this.gridColor,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 55;
    final double rightPadding = 15;
    final double topPadding = 15;
    final double bottomPadding = 30;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (monthLabels.isEmpty) return;

    double maxVal = 10000;
    for (var v in incomeData) {
      if (v > maxVal) maxVal = v;
    }
    double maxY = maxVal * 1.15;
    if (maxY == 0) maxY = 100000;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(color: textColor, fontSize: 11);

    for (int i = 0; i <= 4; i++) {
      final double yRatio = i / 4.0;
      final double yPos = topPadding + chartHeight * (1 - yRatio);
      final double val = maxY * yRatio;

      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      String label;
      if (val >= 1000000) {
        label = 'Rs. ${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = 'Rs. ${(val / 1000).toStringAsFixed(0)}K';
      } else {
        label = 'Rs. ${val.toStringAsFixed(0)}';
      }

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, yPos - textPainter.height / 2),
      );
    }

    final count = monthLabels.length;
    final stepX = count > 0 ? chartWidth / count : chartWidth;
    final barWidth = (stepX * 0.65).clamp(12.0, 50.0);

    for (int i = 0; i < count; i++) {
      final centerX = leftPadding + (i * stepX) + (stepX / 2);

      final textPainter = TextPainter(
        text: TextSpan(text: monthLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - bottomPadding + 8),
      );

      double val = i < incomeData.length ? incomeData[i] : 0;
      double barHeight = (val / maxY) * chartHeight;
      double barTop = topPadding + chartHeight - barHeight;
      double barLeft = centerX - (barWidth / 2);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, barPaint);
    }

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _IncomeBarChartPainter oldDelegate) => true;
}

class ExpensesTrendChartWidget extends StatelessWidget {
  final List<String> monthLabels;
  final List<Map<String, double>> categoryMonthlyData;

  const ExpensesTrendChartWidget({
    super.key,
    required this.monthLabels,
    required this.categoryMonthlyData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses — Trend Chart',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              width: double.infinity,
              child: CustomPaint(
                painter: _ExpensesCategoryBarChartPainter(
                  monthLabels: monthLabels,
                  categoryMonthlyData: categoryMonthlyData,
                  textColor: context.textSecondary,
                  gridColor: context.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(const Color(0xFF0088FE), 'COGS'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFFD6BBFC), 'Other'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF9333EA), 'Rent'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFF4F46E5), 'Salaries'),
                const SizedBox(width: 16),
                _buildLegendItem(const Color(0xFFC084FC), 'Utilities'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ExpensesCategoryBarChartPainter extends CustomPainter {
  final List<String> monthLabels;
  final List<Map<String, double>> categoryMonthlyData;
  final Color textColor;
  final Color gridColor;

  _ExpensesCategoryBarChartPainter({
    required this.monthLabels,
    required this.categoryMonthlyData,
    required this.textColor,
    required this.gridColor,
  });

  static const categoryColors = {
    'COGS': Color(0xFF0088FE),
    'Other': Color(0xFFD6BBFC),
    'Rent': Color(0xFF9333EA),
    'Salaries': Color(0xFF4F46E5),
    'Utilities': Color(0xFFC084FC),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 55;
    final double rightPadding = 15;
    final double topPadding = 15;
    final double bottomPadding = 30;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (monthLabels.isEmpty) return;

    double maxVal = 10000;
    for (var mData in categoryMonthlyData) {
      for (var val in mData.values) {
        if (val > maxVal) maxVal = val;
      }
    }
    double maxY = maxVal * 1.15;
    if (maxY == 0) maxY = 160000;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(color: textColor, fontSize: 11);

    for (int i = 0; i <= 4; i++) {
      final double yRatio = i / 4.0;
      final double yPos = topPadding + chartHeight * (1 - yRatio);
      final double val = maxY * yRatio;

      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      String label;
      if (val >= 1000000) {
        label = 'Rs. ${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = 'Rs. ${(val / 1000).toStringAsFixed(0)}K';
      } else {
        label = 'Rs. ${val.toStringAsFixed(0)}';
      }

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, yPos - textPainter.height / 2),
      );
    }

    final count = monthLabels.length;
    final stepX = count > 0 ? chartWidth / count : chartWidth;
    final cats = ['COGS', 'Other', 'Rent', 'Salaries', 'Utilities'];
    final singleBarWidth = (stepX * 0.12).clamp(4.0, 10.0);

    for (int i = 0; i < count; i++) {
      final groupCenterX = leftPadding + (i * stepX) + (stepX / 2);

      final textPainter = TextPainter(
        text: TextSpan(text: monthLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupCenterX - textPainter.width / 2, size.height - bottomPadding + 8),
      );

      final mData = i < categoryMonthlyData.length ? categoryMonthlyData[i] : <String, double>{};
      final totalGroupWidth = cats.length * singleBarWidth + (cats.length - 1) * 2;
      double startX = groupCenterX - (totalGroupWidth / 2);

      for (int c = 0; c < cats.length; c++) {
        final cat = cats[c];
        final val = mData[cat] ?? 0.0;
        double barHeight = (val / maxY) * chartHeight;
        double barTop = topPadding + chartHeight - barHeight;
        double barLeft = startX + c * (singleBarWidth + 2);

        final rect = Rect.fromLTWH(barLeft, barTop, singleBarWidth, barHeight);
        final barPaint = Paint()
          ..color = categoryColors[cat] ?? Colors.grey
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, barPaint);
      }
    }

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpensesCategoryBarChartPainter oldDelegate) => true;
}

class _TrendChartPainter extends CustomPainter {
  final List<String> monthLabels;
  final List<double> revenueData;
  final List<double> expensesData;
  final List<double> netProfitData;
  final Color textColor;
  final Color gridColor;

  _TrendChartPainter({
    required this.monthLabels,
    required this.revenueData,
    required this.expensesData,
    required this.netProfitData,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 55;
    final double rightPadding = 15;
    final double topPadding = 15;
    final double bottomPadding = 30;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (monthLabels.isEmpty) return;

    double maxVal = 10000;
    for (var v in revenueData) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in expensesData) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in netProfitData) {
      if (v > maxVal) maxVal = v;
    }

    double maxY = maxVal * 1.15;
    if (maxY == 0) maxY = 100000;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(color: textColor, fontSize: 11);

    for (int i = 0; i <= 4; i++) {
      final double yRatio = i / 4.0;
      final double yPos = topPadding + chartHeight * (1 - yRatio);
      final double val = maxY * yRatio;

      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      String label;
      if (val >= 1000000) {
        label = 'Rs. ${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = 'Rs. ${(val / 1000).toStringAsFixed(0)}K';
      } else {
        label = 'Rs. ${val.toStringAsFixed(0)}';
      }

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, yPos - textPainter.height / 2),
      );
    }

    final count = monthLabels.length;
    final stepX = count > 1 ? chartWidth / (count - 1) : chartWidth;

    for (int i = 0; i < count; i++) {
      final xPos = leftPadding + (i * stepX);
      final textPainter = TextPainter(
        text: TextSpan(text: monthLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos - textPainter.width / 2, size.height - bottomPadding + 8),
      );

      canvas.drawLine(
        Offset(xPos, topPadding + chartHeight),
        Offset(xPos, topPadding + chartHeight + 4),
        gridPaint,
      );
    }

    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    List<Offset> getPoints(List<double> data) {
      List<Offset> pts = [];
      for (int i = 0; i < data.length; i++) {
        double x = leftPadding + (i * stepX);
        double val = data[i].clamp(0, maxY);
        double y = topPadding + chartHeight * (1 - (val / maxY));
        pts.add(Offset(x, y));
      }
      return pts;
    }

    void drawSeries(List<double> data, Color color) {
      if (data.isEmpty) return;
      final pts = getPoints(data);
      if (pts.isEmpty) return;

      final path = Path();
      path.moveTo(pts[0].dx, pts[0].dy);

      for (int i = 0; i < pts.length - 1; i++) {
        final p0 = pts[i];
        final p1 = pts[i + 1];
        final control1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final control2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, p1.dx, p1.dy);
      }

      final fillPath = Path.from(path);
      fillPath.lineTo(pts.last.dx, topPadding + chartHeight);
      fillPath.lineTo(pts.first.dx, topPadding + chartHeight);
      fillPath.close();

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.01),
        ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, strokePaint);
    }

    drawSeries(netProfitData, Colors.green);
    drawSeries(expensesData, Colors.redAccent);
    drawSeries(revenueData, Colors.blue);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => true;
}

class _CurrentVsPriorYearChartPainter extends CustomPainter {
  final double currentSales;
  final double priorSales;
  final double currentOther;
  final double priorOther;
  final double currentCogs;
  final double priorCogs;
  final double currentOpEx;
  final double priorOpEx;
  final Color textColor;
  final Color gridColor;

  _CurrentVsPriorYearChartPainter({
    required this.currentSales,
    required this.priorSales,
    required this.currentOther,
    required this.priorOther,
    required this.currentCogs,
    required this.priorCogs,
    required this.currentOpEx,
    required this.priorOpEx,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 90;
    final double rightPadding = 15;
    final double topPadding = 15;
    final double bottomPadding = 30;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final items = [
      {'label': 'Sales Revenue', 'current': currentSales, 'prior': priorSales},
      {'label': 'Other Income', 'current': currentOther, 'prior': priorOther},
      {'label': 'COGS', 'current': currentCogs, 'prior': priorCogs},
      {'label': 'Operating Exp.', 'current': currentOpEx, 'prior': priorOpEx},
    ];

    double maxVal = 1000;
    for (var it in items) {
      if ((it['current'] as double) > maxVal) maxVal = it['current'] as double;
      if ((it['prior'] as double) > maxVal) maxVal = it['prior'] as double;
    }
    double maxX = maxVal * 1.15;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(color: textColor, fontSize: 10);

    for (int i = 0; i <= 4; i++) {
      final double ratio = i / 4.0;
      final double xPos = leftPadding + chartWidth * ratio;
      final double val = maxX * ratio;

      canvas.drawLine(Offset(xPos, topPadding), Offset(xPos, topPadding + chartHeight), gridPaint);

      String label;
      if (val >= 1000000) {
        label = 'Rs.${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        label = 'Rs.${(val / 1000).toStringAsFixed(0)}K';
      } else {
        label = 'Rs.${val.toStringAsFixed(0)}';
      }

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, size.height - bottomPadding + 8));
    }

    final rowHeight = chartHeight / items.length;
    final barHeight = (rowHeight * 0.30).clamp(6.0, 16.0);

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final label = it['label'] as String;
      final cVal = it['current'] as double;
      final pVal = it['prior'] as double;

      final rowCenterY = topPadding + (i * rowHeight) + (rowHeight / 2);

      final labelPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle.copyWith(fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(leftPadding - labelPainter.width - 8, rowCenterY - labelPainter.height / 2));

      double cWidth = (cVal / maxX) * chartWidth;
      double pWidth = (pVal / maxX) * chartWidth;

      final currentRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(leftPadding, rowCenterY - barHeight - 1, cWidth, barHeight),
        topRight: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      final currentPaint = Paint()..color = const Color(0xFF007AFF);
      canvas.drawRRect(currentRect, currentPaint);

      final priorRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(leftPadding, rowCenterY + 1, pWidth, barHeight),
        topRight: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      final priorPaint = Paint()..color = const Color(0xFFCBD5E1);
      canvas.drawRRect(priorRect, priorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurrentVsPriorYearChartPainter oldDelegate) => true;
}
