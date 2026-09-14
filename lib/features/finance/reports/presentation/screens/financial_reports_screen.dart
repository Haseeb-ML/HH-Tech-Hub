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
    ReportTabItem(3, 'Cash Flow', Icons.swap_horiz_outlined),
    ReportTabItem(4, 'Receivables & Payables', Icons.receipt_long_outlined),
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
                  // Page Title Header + Integrated Export Data Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      // Standard Export Data Button (with PDF & Excel options inside dropdown)
                      ExportButton(
                        title: '${activeTab.label} Report',
                        fileName: '${activeTab.label.toLowerCase().replaceAll(' ', '_')}_report',
                        headers: const ['Metric / Item', 'Value / Amount (Rs.)', 'Notes'],
                        rows: [
                          ['Total Revenue', 'Rs. ${pl.totalRevenue.toStringAsFixed(2)}', 'Operational income'],
                          ['Total Expenses', 'Rs. ${pl.totalExpenses.toStringAsFixed(2)}', 'Direct expenses + Salaries'],
                          ['Net Profit', 'Rs. ${pl.netProfit.toStringAsFixed(2)}', 'Bottom line'],
                          ['Cash & Bank Balance', 'Rs. ${al.cashAndBankBalance.toStringAsFixed(2)}', 'Liquid funds'],
                          ['Accounts Receivable', 'Rs. ${al.accountsReceivable.toStringAsFixed(2)}', 'Outstanding income'],
                          ['Accounts Payable', 'Rs. ${al.accountsPayable.toStringAsFixed(2)}', 'Outstanding bills'],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Period & View Focus Filters Header Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodFilterChip(context, ref, 'Today', ReportDateRange.today, currentFilter.dateRange),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'This Month', ReportDateRange.thisMonth, currentFilter.dateRange),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'This Year', ReportDateRange.thisYear, currentFilter.dateRange),
                        const SizedBox(width: 8),
                        _buildPeriodFilterChip(context, ref, 'All Time', ReportDateRange.allTime, currentFilter.dateRange),

                        const SizedBox(width: 16),
                        Container(width: 1, height: 24, color: context.border),
                        const SizedBox(width: 16),

                        ...['Overview', 'Income', 'Expenses', 'Payroll', 'Profit/Loss'].map((focus) {
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
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Specific Body Content
                  if (_selectedIndex == 0)
                    _buildFinanceSummaryView(context, pl, al, currentFilter)
                  else
                    _buildTabPlaceholderView(context, activeTab),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    ReportDateRange range,
    ReportDateRange currentRange,
  ) {
    final isSelected = currentRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(reportFilterProvider.notifier).setDateRange(range);
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
        const SizedBox(height: 24),

        // ── Render Specific Dynamic Full-Width Breakdown Table Based On Selected Focus Button ──
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
    final periodLabel = _getPeriodLabelText(filter.dateRange);
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

    double ytdRevenue = 0.0;
    double ytdExpenses = 0.0;

    for (int m = 1; m <= currentMonthIndex; m++) {
      final monthName = '${months[m - 1]} ${now.year}';
      
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

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header matching Screenshot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overview — $periodLabel Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Jan–${months[currentMonthIndex - 1].substring(0, 3)} ${now.year}',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. INCOME FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildIncomeBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final periodLabel = _getPeriodLabelText(filter.dateRange);
    final theme = Theme.of(context);
    final incomeState = ref.watch(incomeProvider);
    final incomes = incomeState.incomes;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income — $periodLabel Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  3. EXPENSES FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildExpensesBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final periodLabel = _getPeriodLabelText(filter.dateRange);
    final theme = Theme.of(context);
    final expensesState = ref.watch(expensesProvider);
    final expenses = expensesState.expenses;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses — $periodLabel Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  4. PAYROLL FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPayrollBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final periodLabel = _getPeriodLabelText(filter.dateRange);
    final theme = Theme.of(context);
    final salariesState = ref.watch(salariesProvider);
    final salaries = salariesState.salaries;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payroll — $periodLabel Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                fontSize: 16,
              ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  5. PROFIT / LOSS FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildProfitLossBreakdownCard(
    BuildContext context,
    dynamic pl,
    dynamic al,
    FinancialReportFilter filter,
  ) {
    final periodLabel = _getPeriodLabelText(filter.dateRange);
    final theme = Theme.of(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit & Loss — $periodLabel Breakdown',
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
                          DataCell(Text('Rs. ${pl.totalRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          const DataCell(Text('100.0%')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Operating Cost', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          const DataCell(Text('Company Direct Expenses + Staff Payroll')),
                          DataCell(Text('Rs. ${pl.totalExpenses.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                          DataCell(Text('${pl.totalRevenue > 0 ? ((pl.totalExpenses / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}%')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Net Profit / Loss', style: TextStyle(fontWeight: FontWeight.w900, color: pl.netProfit >= 0 ? Colors.green : Colors.red))),
                          const DataCell(Text('Net Revenue minus Operating Costs', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text('Rs. ${pl.netProfit.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, color: pl.netProfit >= 0 ? Colors.green : Colors.red))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: pl.netProfit >= 0 ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pl.totalRevenue > 0 ? ((pl.netProfit / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}%',
                                style: TextStyle(color: pl.netProfit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Working Capital', style: TextStyle(fontWeight: FontWeight.bold))),
                          const DataCell(Text('Current Assets minus Liabilities')),
                          DataCell(Text('Rs. ${al.workingCapital.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: al.workingCapital >= 0 ? Colors.green : Colors.red))),
                          DataCell(Text(al.workingCapital >= 0 ? 'Healthy' : 'Deficit', style: TextStyle(fontWeight: FontWeight.bold, color: al.workingCapital >= 0 ? Colors.green : Colors.red))),
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

  Widget _buildTabPlaceholderView(BuildContext context, ReportTabItem activeTab) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activeTab.icon,
                  size: 36,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${activeTab.label} View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yahan ${activeTab.label} ka custom breakdown aur detailed components visual report me hain.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
