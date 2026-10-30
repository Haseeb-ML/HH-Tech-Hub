import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/features/finance/expenses/domain/entities/expense_record.dart';
import 'package:software_house_erp/features/finance/income/domain/entities/income_record.dart';
import 'package:software_house_erp/features/hr/salaries/domain/entities/salary_record.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/features/finance/loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/features/hr/salaries/presentation/providers/salaries_provider.dart';
import 'package:software_house_erp/features/hr/advances/domain/entities/advance_record.dart';
import 'package:software_house_erp/features/hr/advances/presentation/providers/advances_provider.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';
import 'package:software_house_erp/features/sales/sales/presentation/providers/sales_invoices_provider.dart';
import 'package:software_house_erp/features/sales/purchases/presentation/providers/purchase_orders_provider.dart';
import 'package:software_house_erp/features/finance/shared/widgets/transaction_detail_dialog.dart';
import 'package:software_house_erp/features/projects/projects/presentation/providers/projects_provider.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import '../providers/financial_reports_provider.dart';
import '../../domain/entities/financial_summary_model.dart';

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

  DateTimeRange? _incomeDateRange;
  String _incomeCategoryFilter = 'All';
  String _incomeClientFilter = 'All';
  String _incomeAccountFilter = 'All';
  int _incomeCurrentPage = 0;
  static const int _incomeRowsPerPage = 10;

  String _expensesPeriodFilter = 'This Month';
  DateTimeRange? _expensesCustomDateRange;

  String _payrollPeriodFilter = 'This Month';
  DateTimeRange? _payrollCustomDateRange;

  String _advancesPeriodFilter = 'This Month';
  DateTimeRange? _advancesCustomDateRange;

  String _profitLossPeriodFilter = 'This Month';
  DateTimeRange? _profitLossCustomDateRange;

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
    ref.listen<SyncState>(cloudSyncStateProvider, (previous, next) {
        if ((next.status == SyncStatus.success || next.status == SyncStatus.offline) &&
          previous?.status == SyncStatus.syncing) {
        ref.invalidate(financialReportsProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(incomeProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(salariesProvider);
        ref.invalidate(advancesProvider);
        ref.invalidate(ledgerProvider);
        ref.invalidate(loansProvider);
        ref.invalidate(inventoryProvider);
        ref.invalidate(salesInvoicesProvider);
        ref.invalidate(purchaseOrdersProvider);
        ref.invalidate(assetsProvider);
        ref.invalidate(projectsProvider);
      }
    });

    final theme = Theme.of(context);
    final activeTab = _reportTabs.firstWhere((t) => t.index == _selectedIndex);
    final reportState = ref.watch(financialReportsProvider);
    final currentFilter = ref.watch(reportFilterProvider);

    final pl = reportState.profitLoss;
    final al = reportState.assetsLiabilities;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Finance Reports module navigation
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 12, isMobile ? 12 : 24, 0),
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
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activeTab.label,
                        style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.displaySmall)?.copyWith(
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
        // 8 Responsive Stat Cards
        LayoutBuilder(
          builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 600;
              final crossAxisCount = isMobile ? 1 : (width >= 1050 ? 4 : 2);
              final childAspectRatio = isMobile ? 2.2 : (width >= 1100 ? 1.6 : 1.4);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspectRatio,
              children: [
                StatCard(
                  title: 'TOTAL REVENUE',
                  value: CurrencyFormatter.formatCurrency(pl.totalRevenue),
                  icon: Icons.trending_up,
                  iconColor: context.success,
                  iconBgColor: context.successLight,
                  trendText: 'Income ($periodLabel)',
                ),
                StatCard(
                  title: 'TOTAL EXPENSES',
                  value: CurrencyFormatter.formatCurrency(pl.totalExpenses),
                  icon: Icons.trending_down,
                  iconColor: context.error,
                  iconBgColor: context.errorLight,
                  trendText: 'Costs ($periodLabel)',
                ),
                StatCard(
                  title: 'NET PROFIT',
                  value: CurrencyFormatter.formatAccountingBalance((pl.netProfit as num).toDouble(), showDr: false),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: pl.netProfit >= 0 ? context.success : context.error,
                  iconBgColor: pl.netProfit >= 0 ? context.successLight : context.errorLight,
                  trendText: '${pl.totalRevenue > 0 ? ((pl.netProfit / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}% margin',
                ),
                StatCard(
                  title: 'CASH & BANK',
                  value: CurrencyFormatter.formatAccountingBalance((al.cashAndBankBalance as num).toDouble(), showDr: false),
                  icon: Icons.account_balance_outlined,
                  iconColor: context.info,
                  iconBgColor: context.infoLight,
                  trendText: 'Current liquid balance',
                ),
                StatCard(
                  title: 'RECEIVABLES',
                  value: CurrencyFormatter.formatCurrency(al.accountsReceivable),
                  icon: Icons.receipt_long_outlined,
                  iconColor: context.warning,
                  iconBgColor: context.warningLight,
                  trendText: 'Outstanding income',
                ),
                StatCard(
                  title: 'PAYABLES',
                  value: CurrencyFormatter.formatCurrency(al.accountsPayable + al.shortTermLoans),
                  icon: Icons.money_off_outlined,
                  iconColor: context.error,
                  iconBgColor: context.errorLight,
                  trendText: al.shortTermLoans > 0
                      ? (al.accountsPayable > 0 ? 'Bills & Borrowed Loans' : 'Borrowed loans to pay')
                      : 'Outstanding bills',
                ),
                StatCard(
                  title: 'TOTAL ASSETS',
                  value: CurrencyFormatter.formatCurrency(al.totalCurrentAssets),
                  icon: Icons.pie_chart_outline_outlined,
                  iconColor: context.success,
                  iconBgColor: context.successLight,
                  trendText: 'Cash + AR + Inventory',
                ),
                StatCard(
                  title: 'TOTAL LIABILITIES',
                  value: CurrencyFormatter.formatCurrency(al.totalCurrentLiabilities),
                  icon: Icons.credit_card_off_outlined,
                  iconColor: context.error,
                  iconBgColor: context.errorLight,
                  trendText: 'AP + Short-term loans',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Focus View Filter Chips positioned below Total Assets & Total Liabilities cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Overview', 'Income', 'Expenses', 'Payroll', 'Advances', 'Profit/Loss'].map((focus) {
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
        else if (_summaryFocus == 'Advances')
          _buildAdvancesBreakdownCard(context, currentFilter)
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
        'month': m,
        'year': now.year,
      });
    }

    // Filter to only active months that have revenue or expense activity
    final activeRows = monthlyRows.where((row) {
      final r = row['revenue'] as double;
      final e = row['expenses'] as double;
      return r > 0 || e > 0;
    }).toList();

    // Show latest months on top (descending order)
    final displayRows = (activeRows.isNotEmpty
        ? activeRows
        : (monthlyRows.isNotEmpty ? [monthlyRows.last] : <Map<String, dynamic>>[])).reversed.toList();

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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Jan–${months[currentMonthIndex - 1].substring(0, 3)} ${now.year}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['This Month', 'This Year', 'All Time', 'Custom Date'].map((period) {
                            final isSelected = _profitLossPeriodFilter == period;
                            String chipLabel = period;
                            if (period == 'Custom Date' && _profitLossCustomDateRange != null) {
                              final startStr = DateFormat('dd MMM yyyy').format(_profitLossCustomDateRange!.start);
                              final endStr = DateFormat('dd MMM yyyy').format(_profitLossCustomDateRange!.end);
                              chipLabel = 'Custom ($startStr - $endStr)';
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(chipLabel),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (period == 'Custom Date') {
                                    _selectProfitLossCustomDateRange(context);
                                  } else {
                                    setState(() {
                                      _profitLossPeriodFilter = period;
                                    });
                                  }
                                },
                                selectedColor: context.primaryColor.withValues(alpha: 0.15),
                                backgroundColor: context.scaffoldBg,
                                labelStyle: TextStyle(
                                  color: isSelected ? context.primaryColor : context.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSelected ? context.primaryColor : context.border,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
                      child: SizedBox(
                        width: max(900.0, constraints.maxWidth),
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
                                      onPressed: () {
                                        _showPeriodDetailsModal(
                                          context,
                                          row['period'] as String,
                                          row['month'] as int,
                                          row['year'] as int,
                                        );
                                      },
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
  //  PERIOD DETAILS MODAL (REQ 7)
  // ═══════════════════════════════════════════════════════════
  void _showPeriodDetailsModal(BuildContext context, String periodLabel, int month, int year) {
    final incomeState = ref.read(incomeProvider);
    final expensesState = ref.read(expensesProvider);
    final salariesState = ref.read(salariesProvider);
    final accountsState = ref.read(accountsProvider);
    final projectsState = ref.read(projectsProvider);
    final reportState = ref.read(financialReportsProvider);
    final al = reportState.assetsLiabilities;

    final periodIncomes = incomeState.incomes.where((i) {
      final d = DateTime.tryParse(i.date);
      return d != null && d.year == year && d.month == month;
    }).toList();

    final periodExpenses = expensesState.expenses.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && !e.isPersonalExpense && d.year == year && d.month == month;
    }).toList();

    final periodSalaries = salariesState.salaries.where((s) {
      final d = DateTime.tryParse(s.paymentDate);
      return d != null && s.status == 'Paid' && d.year == year && d.month == month;
    }).toList();

    final double revenue = periodIncomes.fold(0.0, (sum, i) => sum + i.amount);
    final double directExpenses = periodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final double payrollExpenses = periodSalaries.fold(0.0, (sum, s) => sum + s.netPaid);
    final double totalExpense = directExpenses + payrollExpenses;
    final double netProfit = revenue - totalExpense;
    final double profitMargin = revenue > 0 ? (netProfit / revenue) * 100 : 0.0;

    final double cashAndBank = accountsState.accounts
        .where((a) => a.isCompany && a.status == 'Active')
        .fold(0.0, (sum, a) => sum + a.balance);

    double projectReceivables = 0.0;
    for (final project in projectsState.projects) {
      if (project.status != 'Completed' && project.status != 'Cancelled') {
        final received = incomeState.incomes
            .where((i) => i.projectId == project.id)
            .fold(0.0, (sum, i) => sum + i.amount);
        final remaining = (project.budget - received);
        if (remaining > 0) projectReceivables += remaining;
      }
    }

    final double payables = al.accountsPayable + al.shortTermLoans;
    final double inventoryVal = al.inventoryValue;
    final double totalAssets = cashAndBank + projectReceivables + inventoryVal;
    final double totalLiabilities = al.totalCurrentLiabilities;

    final int incomeCount = periodIncomes.length;
    final int expenseCount = periodExpenses.length;
    final int payrollCount = periodSalaries.length;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.assessment_outlined, color: context.primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Financial Summary — $periodLabel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Key financial indicators and performance breakdown for $periodLabel.',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildMetricDetailRow(context, 'Revenue', 'Rs. ${revenue.toStringAsFixed(2)}', Colors.blue, Icons.trending_up),
                        _buildMetricDetailRow(context, 'Expense', 'Rs. ${totalExpense.toStringAsFixed(2)}', Colors.redAccent, Icons.trending_down),
                        _buildMetricDetailRow(context, 'Net Profit / Loss', 'Rs. ${netProfit.toStringAsFixed(2)}', netProfit >= 0 ? Colors.green : Colors.red, Icons.account_balance_wallet),
                        _buildMetricDetailRow(context, 'Profit Margin', '${profitMargin.toStringAsFixed(1)}%', profitMargin >= 0 ? Colors.green : Colors.red, Icons.pie_chart),
                        const Divider(height: 20),
                        _buildMetricDetailRow(context, 'Cash & Bank (Company)', 'Rs. ${cashAndBank.toStringAsFixed(2)}', Colors.teal, Icons.account_balance),
                        _buildMetricDetailRow(context, 'Receivables', 'Rs. ${projectReceivables.toStringAsFixed(2)}', Colors.orange, Icons.receipt_long),
                        _buildMetricDetailRow(context, 'Payables', 'Rs. ${payables.toStringAsFixed(2)}', Colors.deepOrange, Icons.money_off),
                        _buildMetricDetailRow(context, 'Total Assets', 'Rs. ${totalAssets.toStringAsFixed(2)}', Colors.indigo, Icons.account_balance_wallet_outlined),
                        _buildMetricDetailRow(context, 'Total Liabilities', 'Rs. ${totalLiabilities.toStringAsFixed(2)}', Colors.pink, Icons.credit_card_off),
                        const Divider(height: 20),
                        _buildMetricDetailRow(context, 'Income Transactions Count', '$incomeCount', context.textPrimary, Icons.receipt),
                        _buildMetricDetailRow(context, 'Expense Transactions Count', '$expenseCount', context.textPrimary, Icons.shopping_bag),
                        _buildMetricDetailRow(context, 'Payroll Transactions Count', '$payrollCount', context.textPrimary, Icons.people),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricDetailRow(BuildContext context, String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  INCOME FILTER DIALOG (REQ 6)
  // ═══════════════════════════════════════════════════════════
  void _showIncomeFilterDialog(BuildContext context) {
    final incomeState = ref.read(incomeProvider);
    final accountsState = ref.read(accountsProvider);

    final categories = {'All', ...incomeState.incomes.map((i) => i.projectName?.isNotEmpty == true ? 'Project: ${i.projectName}' : (i.projectPaymentType ?? 'Client Payment'))}.toList();
    final clients = {'All', ...incomeState.incomes.map((i) => i.clientName).where((c) => c.isNotEmpty)}.toList();
    final accounts = {'All', ...accountsState.accounts.map((a) => a.name)}.toList();

    String tempCategory = _incomeCategoryFilter;
    String tempClient = _incomeClientFilter;
    String tempAccount = _incomeAccountFilter;
    DateTimeRange? tempDateRange = _incomeDateRange;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.filter_list_rounded, color: context.primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Filter Income Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 24),

                    Text('Date / Date Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: tempDateRange,
                        );
                        if (picked != null) {
                          setModalState(() => tempDateRange = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tempDateRange == null
                                  ? 'Select Date Range'
                                  : '${tempDateRange!.start.day}/${tempDateRange!.start.month}/${tempDateRange!.start.year} - ${tempDateRange!.end.day}/${tempDateRange!.end.month}/${tempDateRange!.end.year}',
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                            ),
                            Icon(Icons.calendar_today_outlined, size: 16, color: context.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Income Category / Source', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: categories.contains(tempCategory) ? tempCategory : 'All',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => tempCategory = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Client', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: clients.contains(tempClient) ? tempClient : 'All',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => tempClient = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: accounts.contains(tempAccount) ? tempAccount : 'All',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => tempAccount = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = 'All';
                              tempClient = 'All';
                              tempAccount = 'All';
                              tempDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.redAccent),
                          label: const Text('Clear Filters', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _incomeCategoryFilter = tempCategory;
                                  _incomeClientFilter = tempClient;
                                  _incomeAccountFilter = tempAccount;
                                  _incomeDateRange = tempDateRange;
                                  _incomeCurrentPage = 0;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  2. INCOME FULL-WIDTH BREAKDOWN TABLE (REQ 5 & REQ 6)
  // ═══════════════════════════════════════════════════════════
  Widget _buildIncomeBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final allIncomes = ref.watch(incomeProvider).incomes;
    final accountsState = ref.watch(accountsProvider);

    // Apply active multi-field filters
    final filteredIncomes = allIncomes.where((inc) {
      if (_incomeDateRange != null) {
        final d = DateTime.tryParse(inc.date);
        if (d == null || d.isBefore(_incomeDateRange!.start) || d.isAfter(_incomeDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      final source = inc.projectName?.isNotEmpty == true ? 'Project: ${inc.projectName}' : (inc.projectPaymentType ?? 'Client Payment');
      if (_incomeCategoryFilter != 'All' && source != _incomeCategoryFilter) {
        return false;
      }

      if (_incomeClientFilter != 'All' && inc.clientName != _incomeClientFilter) {
        return false;
      }

      final matches = accountsState.accounts.where((a) => a.id == inc.accountId);
      final acc = matches.isNotEmpty ? matches.first : null;
      final accountName = acc != null ? acc.name : (inc.accountId.isNotEmpty ? inc.accountId : 'Main Bank Account');
      if (_incomeAccountFilter != 'All' && accountName != _incomeAccountFilter) {
        return false;
      }

      return true;
    }).toList();

    // Sort in descending order (newest date / entry on top)
    filteredIncomes.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;
      final aStr = a.id.replaceAll(RegExp(r'[^0-9]'), '');
      final bStr = b.id.replaceAll(RegExp(r'[^0-9]'), '');
      final aNum = BigInt.tryParse(aStr) ?? BigInt.zero;
      final bNum = BigInt.tryParse(bStr) ?? BigInt.zero;
      return bNum.compareTo(aNum);
    });

    // Calculate pagination stats
    final totalEntries = filteredIncomes.length;
    final totalPages = (totalEntries / _incomeRowsPerPage).ceil() == 0 ? 1 : (totalEntries / _incomeRowsPerPage).ceil();

    if (_incomeCurrentPage >= totalPages) {
      _incomeCurrentPage = totalPages - 1;
    }
    if (_incomeCurrentPage < 0) {
      _incomeCurrentPage = 0;
    }

    final startIndex = _incomeCurrentPage * _incomeRowsPerPage;
    final endIndex = min(startIndex + _incomeRowsPerPage, totalEntries);
    final pagedIncomes = totalEntries > 0 ? filteredIncomes.sublist(startIndex, endIndex) : <IncomeRecord>[];

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final currentMonthIndex = now.month;
    final List<String> monthLabels = [];
    final List<double> realIncomeSeries = [];

    for (int m = 1; m <= currentMonthIndex; m++) {
      monthLabels.add(months[m - 1]);
      double mRevenue = allIncomes.where((i) {
        final d = DateTime.tryParse(i.date);
        return d != null && d.year == now.year && d.month == m;
      }).fold(0.0, (sum, i) => sum + i.amount);
      realIncomeSeries.add(mRevenue);
    }

    final displayMonthLabels = monthLabels.isNotEmpty ? monthLabels : ['Jan'];
    final displayIncomeData = realIncomeSeries;

    final isFiltered = _incomeCategoryFilter != 'All' ||
        _incomeClientFilter != 'All' ||
        _incomeAccountFilter != 'All' ||
        _incomeDateRange != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: LEFT: Income, RIGHT: [ Filters ] [ Export Data ]
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Income',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showIncomeFilterDialog(context),
                          icon: Icon(
                            Icons.filter_list,
                            size: 16,
                            color: isFiltered ? Colors.white : context.primaryColor,
                          ),
                          label: Text(
                            isFiltered ? 'Filtered' : 'Filters',
                            style: TextStyle(
                              color: isFiltered ? Colors.white : context.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isFiltered ? context.primaryColor : Colors.transparent,
                            side: BorderSide(color: context.primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                        ExportButton(
                          title: 'Income Report',
                          fileName: 'income_report',
                          headers: const ['DATE', 'SOURCE', 'CLIENT', 'ACCOUNT', 'AMOUNT (Rs.)', 'STATUS'],
                          rows: filteredIncomes.map((inc) {
                            final matches = accountsState.accounts.where((a) => a.id == inc.accountId);
                            final acc = matches.isNotEmpty ? matches.first : null;
                            final accountName = acc != null ? acc.name : (inc.accountId.isNotEmpty ? inc.accountId : 'Main Bank Account');
                            final source = inc.projectName?.isNotEmpty == true ? 'Project: ${inc.projectName}' : (inc.projectPaymentType ?? 'Client Payment');
                            return [
                              inc.date.split('T').first,
                              source,
                              inc.clientName,
                              accountName,
                              'Rs. ${inc.amount.toStringAsFixed(2)}',
                              inc.status,
                            ];
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                filteredIncomes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No matching income records found.')),
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
                                  DataColumn(label: Text('SOURCE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CLIENT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: pagedIncomes.map((inc) {
                                  final matches = accountsState.accounts.where((a) => a.id == inc.accountId);
                                  final acc = matches.isNotEmpty ? matches.first : null;
                                  final accountName = acc != null ? acc.name : (inc.accountId.isNotEmpty ? inc.accountId : 'Main Bank Account');
                                  final accountType = acc != null ? acc.type : 'Bank Account';
                                  final source = inc.projectName?.isNotEmpty == true ? 'Project: ${inc.projectName}' : (inc.projectPaymentType ?? 'Client Payment');

                                  final txData = {
                                    'id': inc.id,
                                    'date': inc.date,
                                    'type': 'Income',
                                    'category': source,
                                    'accountName': accountName,
                                    'accountType': accountType,
                                    'amount': inc.amount,
                                    'clientName': inc.clientName,
                                    'projectName': inc.projectName,
                                    'invoiceNumber': inc.invoiceNumber,
                                    'description': inc.description,
                                    'status': inc.status,
                                    'paymentType': inc.projectPaymentType,
                                  };

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(inc.date.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13)),
                                        onTap: () => TransactionDetailDialog.show(context, data: txData),
                                      ),
                                      DataCell(
                                        Text(source, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13)),
                                        onTap: () => TransactionDetailDialog.show(context, data: txData),
                                      ),
                                      DataCell(
                                        Text(inc.clientName, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                                        onTap: () => TransactionDetailDialog.show(context, data: txData),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: context.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            accountName,
                                            style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                                          ),
                                        ),
                                        onTap: () => TransactionDetailDialog.show(context, data: txData),
                                      ),
                                      DataCell(
                                        Text('Rs. ${inc.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                        onTap: () => TransactionDetailDialog.show(context, data: txData),
                                      ),
                                      DataCell(
                                        TextButton.icon(
                                          onPressed: () => TransactionDetailDialog.show(context, data: txData),
                                          icon: const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                                          label: const Text('Details', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Bottom Pagination: [Previous] [1] [2] [3] [Next] + Showing X–Y of Z entries
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Text(
                      totalEntries == 0
                          ? 'Showing 0 entries'
                          : 'Showing ${startIndex + 1}–$endIndex of $totalEntries entries',
                      style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: _incomeCurrentPage > 0
                                ? () => setState(() => _incomeCurrentPage--)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Previous', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          for (int p = 0; p < totalPages; p++) ...[
                            InkWell(
                              onTap: () => setState(() => _incomeCurrentPage = p),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _incomeCurrentPage == p ? context.primaryColor : context.cardBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _incomeCurrentPage == p ? context.primaryColor : context.border,
                                  ),
                                ),
                                child: Text(
                                  '${p + 1}',
                                  style: TextStyle(
                                    color: _incomeCurrentPage == p ? Colors.white : context.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _incomeCurrentPage < totalPages - 1
                                ? () => setState(() => _incomeCurrentPage++)
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: const Text('Next', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
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

  Future<void> _selectExpensesCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _expensesCustomDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
    );
    if (picked != null) {
      setState(() {
        _expensesCustomDateRange = picked;
        _expensesPeriodFilter = 'Custom Date';
      });
    }
  }

  List<ExpenseRecord> _getFilteredExpensesForReport(List<ExpenseRecord> allExpenses) {
    final now = DateTime.now();
    final list = allExpenses.where((exp) {
      final d = DateTime.tryParse(exp.date);
      if (d == null) return false;

      if (_expensesPeriodFilter == 'Today') {
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } else if (_expensesPeriodFilter == 'This Month') {
        return d.year == now.year && d.month == now.month;
      } else if (_expensesPeriodFilter == 'This Year') {
        return d.year == now.year;
      } else if (_expensesPeriodFilter == 'Custom Date') {
        if (_expensesCustomDateRange == null) return true;
        final start = DateTime(_expensesCustomDateRange!.start.year, _expensesCustomDateRange!.start.month, _expensesCustomDateRange!.start.day, 0, 0, 0);
        final end = DateTime(_expensesCustomDateRange!.end.year, _expensesCustomDateRange!.end.month, _expensesCustomDateRange!.end.day, 23, 59, 59);
        return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();

    // Sort in descending order (newest date / entry on top)
    return ExpenseRecord.sortExpensesNewestFirst(list);
  }

  // ═══════════════════════════════════════════════════════════
  //  3. EXPENSES FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildExpensesBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final expensesState = ref.watch(expensesProvider);
    final allExpenses = expensesState.expenses;
    final filteredExpenses = _getFilteredExpensesForReport(allExpenses);

    final totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final companyExpenses = filteredExpenses.where((e) => !e.isPersonalExpense).fold(0.0, (sum, e) => sum + e.amount);
    final personalExpenses = filteredExpenses.where((e) => e.isPersonalExpense).fold(0.0, (sum, e) => sum + e.amount);

    final Map<String, double> categoryTotals = {};
    for (var exp in filteredExpenses) {
      final cat = exp.category.trim().isEmpty ? 'Uncategorized' : exp.category.trim();
      categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final currencyFormat = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter & Export Action Bar Card
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Expenses Report',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    ExportButton(
                      title: 'Expenses Report',
                      fileName: 'expenses_report',
                      headers: const ['DATE', 'CATEGORY', 'DESCRIPTION', 'AMOUNT (Rs.)', 'CLASSIFICATION'],
                      rows: filteredExpenses.map((exp) => [
                        exp.date.split('T').first,
                        exp.category,
                        exp.description.isNotEmpty ? exp.description : '-',
                        'Rs. ${currencyFormat.format(exp.amount)}',
                        exp.isPersonalExpense ? 'Personal Draw' : 'Company Expense',
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Today', 'This Month', 'This Year', 'Custom Date'].map((period) {
                            final isSelected = _expensesPeriodFilter == period;
                            String chipLabel = period;
                            if (period == 'Custom Date' && _expensesCustomDateRange != null) {
                              final startStr = DateFormat('dd MMM yyyy').format(_expensesCustomDateRange!.start);
                              final endStr = DateFormat('dd MMM yyyy').format(_expensesCustomDateRange!.end);
                              chipLabel = 'Custom ($startStr - $endStr)';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(chipLabel),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (period == 'Custom Date') {
                                    _selectExpensesCustomDateRange(context);
                                  } else {
                                    setState(() {
                                      _expensesPeriodFilter = period;
                                    });
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Summary Cards Section: Total Expenses & Category Breakdown
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;

            final totalExpensesCard = GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.redAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL EXPENSES',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: context.textSecondary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${currencyFormat.format(totalExpenses)}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildExpenseSubDetail(context, 'Company Expense', 'Rs. ${currencyFormat.format(companyExpenses)}', Colors.blue),
                        _buildExpenseSubDetail(context, 'Personal Draw', 'Rs. ${currencyFormat.format(personalExpenses)}', Colors.orange),
                        _buildExpenseSubDetail(context, 'Records', '${filteredExpenses.length} Total', context.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            );

            final categoryBreakdownCard = GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category-wise Expense Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sortedCategories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No category breakdown available.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: sortedCategories.map((entry) {
                          final catName = entry.key;
                          final catAmount = entry.value;
                          final percent = totalExpenses > 0 ? (catAmount / totalExpenses) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        catName,
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rs. ${currencyFormat.format(catAmount)} (${(percent * 100).toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent.clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: context.border.withValues(alpha: 0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: totalExpensesCard),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: categoryBreakdownCard),
                ],
              );
            } else {
              return Column(
                children: [
                  totalExpensesCard,
                  const SizedBox(height: 16),
                  categoryBreakdownCard,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),

        // Expense Table Section
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expense Records',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                filteredExpenses.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No expense records found for the selected period.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                        ),
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
                                  DataColumn(label: Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('CLASSIFICATION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: filteredExpenses.map((exp) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(exp.date.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(exp.category, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(exp.description.isNotEmpty ? exp.description : '-', style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text('Rs. ${currencyFormat.format(exp.amount)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: exp.isPersonalExpense ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            exp.isPersonalExpense ? 'Personal Draw' : 'Company Expense',
                                            style: TextStyle(
                                              color: exp.isPersonalExpense ? Colors.orange : Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
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
      ],
    );
  }

  Widget _buildExpenseSubDetail(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _selectPayrollCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _payrollCustomDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
    );
    if (picked != null) {
      setState(() {
        _payrollCustomDateRange = picked;
        _payrollPeriodFilter = 'Custom Date';
      });
    }
  }

  Future<void> _selectProfitLossCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _profitLossCustomDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
    );
    if (picked != null) {
      setState(() {
        _profitLossCustomDateRange = picked;
        _profitLossPeriodFilter = 'Custom Date';
      });
    }
  }

  List<SalaryRecord> _getFilteredSalariesForReport(List<SalaryRecord> allSalaries) {
    final now = DateTime.now();
    final list = allSalaries.where((sal) {
      final d = DateTime.tryParse(sal.paymentDate);
      if (d == null) return false;

      if (_payrollPeriodFilter == 'This Month') {
        return d.year == now.year && d.month == now.month;
      } else if (_payrollPeriodFilter == 'This Year') {
        return d.year == now.year;
      } else if (_payrollPeriodFilter == 'Custom Date') {
        if (_payrollCustomDateRange == null) return true;
        final start = DateTime(_payrollCustomDateRange!.start.year, _payrollCustomDateRange!.start.month, _payrollCustomDateRange!.start.day, 0, 0, 0);
        final end = DateTime(_payrollCustomDateRange!.end.year, _payrollCustomDateRange!.end.month, _payrollCustomDateRange!.end.day, 23, 59, 59);
        return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();

    // Sort in descending order (newest date / entry on top)
    list.sort((a, b) {
      final dateA = DateTime.tryParse(a.paymentDate) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.paymentDate) ?? DateTime(1970);
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;
      final aStr = a.id.replaceAll(RegExp(r'[^0-9]'), '');
      final bStr = b.id.replaceAll(RegExp(r'[^0-9]'), '');
      final aNum = BigInt.tryParse(aStr) ?? BigInt.zero;
      final bNum = BigInt.tryParse(bStr) ?? BigInt.zero;
      return bNum.compareTo(aNum);
    });

    return list;
  }

  // ═══════════════════════════════════════════════════════════
  
  Future<void> _selectAdvancesCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _advancesCustomDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day),
      ),
    );
    if (picked != null) {
      setState(() {
        _advancesCustomDateRange = picked;
        _advancesPeriodFilter = 'Custom Date';
      });
    }
  }

  List<AdvanceRecord> _getFilteredAdvancesForReport(List<AdvanceRecord> allAdvances) {
    final now = DateTime.now();
    final list = allAdvances.where((adv) {
      final d = DateTime.tryParse(adv.requestDate);
      if (d == null) return false;

      if (_advancesPeriodFilter == 'This Month') {
        return d.year == now.year && d.month == now.month;
      } else if (_advancesPeriodFilter == 'This Year') {
        return d.year == now.year;
      } else if (_advancesPeriodFilter == 'Custom Date') {
        if (_advancesCustomDateRange == null) return true;
        final start = DateTime(_advancesCustomDateRange!.start.year, _advancesCustomDateRange!.start.month, _advancesCustomDateRange!.start.day, 0, 0, 0);
        final end = DateTime(_advancesCustomDateRange!.end.year, _advancesCustomDateRange!.end.month, _advancesCustomDateRange!.end.day, 23, 59, 59);
        return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)));
      }
      return true;
    }).toList();

    list.sort((a, b) {
      final dateA = DateTime.tryParse(a.requestDate) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.requestDate) ?? DateTime(1970);
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;
      final aStr = a.id.replaceAll(RegExp(r'[^0-9]'), '');
      final bStr = b.id.replaceAll(RegExp(r'[^0-9]'), '');
      final aNum = BigInt.tryParse(aStr) ?? BigInt.zero;
      final bNum = BigInt.tryParse(bStr) ?? BigInt.zero;
      return bNum.compareTo(aNum);
    });

    return list;
  }

  Widget _buildAdvancesBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final advancesState = ref.watch(advancesProvider);
    final allAdvances = advancesState.advances;
    final filteredAdvances = _getFilteredAdvancesForReport(allAdvances);

    final currencyFormat = NumberFormat('#,##0.00');

    final totalAmount = filteredAdvances.fold(0.0, (sum, a) => sum + a.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Salary Advances Report',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    ExportButton(
                      title: 'Salary Advances Report',
                      fileName: 'salary_advances_report',
                      headers: const ['REQUEST DATE', 'EMPLOYEE NAME', 'TOTAL AMOUNT (Rs.)', 'MONTHLY DEDUCTION (Rs.)', 'STATUS'],
                      rows: filteredAdvances.map((adv) => [
                        adv.requestDate,
                        adv.employeeName,
                        'Rs. ${currencyFormat.format(adv.amount)}',
                        'Rs. ${currencyFormat.format(adv.monthlyDeduction)}/mo',
                        adv.status,
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['This Month', 'This Year', 'All Time', 'Custom Date'].map((period) {
                            final isSelected = _advancesPeriodFilter == period;
                            String chipLabel = period;
                            if (period == 'Custom Date' && _advancesCustomDateRange != null) {
                              final startStr = DateFormat('dd MMM yyyy').format(_advancesCustomDateRange!.start);
                              final endStr = DateFormat('dd MMM yyyy').format(_advancesCustomDateRange!.end);
                              chipLabel = 'Custom ($startStr - $endStr)';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(chipLabel),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (period == 'Custom Date') {
                                    _selectAdvancesCustomDateRange(context);
                                  } else {
                                    setState(() {
                                      _advancesPeriodFilter = period;
                                    });
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handshake_outlined, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ADVANCES ISSUED',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${currencyFormat.format(totalAmount)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salary Advances Logs (${filteredAdvances.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredAdvances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'No salary advance records found for this period.',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: max(750.0, constraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 44,
                            dataRowMaxHeight: 52,
                            horizontalMargin: 12,
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('EMPLOYEE NAME')),
                              DataColumn(label: Text('AMOUNT (Rs.)')),
                              DataColumn(label: Text('DEDUCTION/MO')),
                              DataColumn(label: Text('STATUS')),
                            ],
                            rows: filteredAdvances.map((adv) {
                              Color statusColor;
                              switch (adv.status) {
                                case 'Approved':
                                  statusColor = context.success;
                                  break;
                                case 'Fully Paid':
                                  statusColor = context.info;
                                  break;
                                case 'Rejected':
                                  statusColor = context.error;
                                  break;
                                default:
                                  statusColor = context.warning;
                              }

                              return DataRow(
                                cells: [
                                  DataCell(Text(adv.requestDate, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                  DataCell(Text(adv.employeeName, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                                  DataCell(Text('Rs. ${currencyFormat.format(adv.amount)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                                  DataCell(Text('Rs. ${currencyFormat.format(adv.monthlyDeduction)}/mo', style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        adv.status,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
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
      ],
    );
  }

  //  4. PAYROLL FULL-WIDTH BREAKDOWN TABLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildPayrollBreakdownCard(BuildContext context, FinancialReportFilter filter) {
    final theme = Theme.of(context);
    final salariesState = ref.watch(salariesProvider);
    final accountsState = ref.watch(accountsProvider);
    final allSalaries = salariesState.salaries;
    final filteredSalaries = _getFilteredSalariesForReport(allSalaries);

    final currencyFormat = NumberFormat('#,##0.00');

    String getAccountName(SalaryRecord sal) {
      if (sal.accountName.isNotEmpty) return sal.accountName;
      if (sal.accountId.isNotEmpty) {
        final acc = accountsState.accounts.where((a) => a.id == sal.accountId).firstOrNull;
        if (acc != null) return acc.name;
      }
      return sal.paymentMethod.isNotEmpty ? sal.paymentMethod : 'Company Account';
    }

    final totalNetPaid = filteredSalaries.where((s) => s.status == 'Paid').fold(0.0, (sum, s) => sum + s.netPaid);
    final totalBaseSalary = filteredSalaries.fold(0.0, (sum, s) => sum + s.baseSalary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter & Export Action Bar Card
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Payroll Report',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 18,
                      ),
                    ),
                    ExportButton(
                      title: 'Payroll Report',
                      fileName: 'payroll_report',
                      headers: const ['PAYMENT DATE', 'EMPLOYEE NAME', 'PAY PERIOD', 'BASE SALARY (Rs.)', 'NET PAID (Rs.)', 'PAYMENT ACCOUNT', 'STATUS'],
                      rows: filteredSalaries.map((sal) => [
                        sal.paymentDate.split('T').first,
                        sal.employeeName,
                        sal.payPeriod,
                        'Rs. ${currencyFormat.format(sal.baseSalary)}',
                        'Rs. ${currencyFormat.format(sal.netPaid)}',
                        getAccountName(sal),
                        sal.status,
                      ]).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Period:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['This Month', 'This Year', 'Custom Date'].map((period) {
                            final isSelected = _payrollPeriodFilter == period;
                            String chipLabel = period;
                            if (period == 'Custom Date' && _payrollCustomDateRange != null) {
                              final startStr = DateFormat('dd MMM yyyy').format(_payrollCustomDateRange!.start);
                              final endStr = DateFormat('dd MMM yyyy').format(_payrollCustomDateRange!.end);
                              chipLabel = 'Custom ($startStr - $endStr)';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(chipLabel),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (period == 'Custom Date') {
                                    _selectPayrollCustomDateRange(context);
                                  } else {
                                    setState(() {
                                      _payrollPeriodFilter = period;
                                    });
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Summary Stat Card
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobileCard = constraints.maxWidth < 650;
                if (isMobileCard) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL NET PAID',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: context.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${currencyFormat.format(totalNetPaid)}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: context.border, height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Base Salary', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('Rs. ${currencyFormat.format(totalBaseSalary)}', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Container(height: 30, width: 1, color: context.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Records', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('${filteredSalaries.length} Records', style: TextStyle(color: context.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Colors.green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL NET PAID',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${currencyFormat.format(totalNetPaid)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: context.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Base Salary', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('Rs. ${currencyFormat.format(totalBaseSalary)}', style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 40, width: 1, color: context.border),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Records', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('${filteredSalaries.length} Records', style: TextStyle(color: context.primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Payroll Table Section
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payroll Records',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                filteredSalaries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No payroll records found for the selected period.',
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                        ),
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
                                  DataColumn(label: Text('PAYMENT ACCOUNT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: filteredSalaries.map((sal) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(sal.paymentDate.split('T').first, style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(sal.employeeName, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text(sal.payPeriod, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                      DataCell(Text('Rs. ${currencyFormat.format(sal.baseSalary)}', style: TextStyle(color: context.textPrimary, fontSize: 13))),
                                      DataCell(Text('Rs. ${currencyFormat.format(sal.netPaid)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(Text(getAccountName(sal), style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: sal.status == 'Paid' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            sal.status,
                                            style: TextStyle(
                                              color: sal.status == 'Paid' ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
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
    final reportsState = ref.watch(financialReportsProvider);
    final incomeState = ref.watch(incomeProvider);
    final expensesState = ref.watch(expensesProvider);
    final salariesState = ref.watch(salariesProvider);

    final currencyFormat = NumberFormat('#,##0.00');

    final localNow = DateTime.now();
    DateTime startDate = reportsState.startDate;
    DateTime endDate = reportsState.endDate;

    if (_profitLossPeriodFilter == 'This Month') {
      startDate = DateTime(localNow.year, localNow.month, 1);
      endDate = DateTime(localNow.year, localNow.month + 1, 0, 23, 59, 59);
    } else if (_profitLossPeriodFilter == 'This Year') {
      startDate = DateTime(localNow.year, 1, 1);
      endDate = DateTime(localNow.year, 12, 31, 23, 59, 59);
    } else if (_profitLossPeriodFilter == 'Custom Date' && _profitLossCustomDateRange != null) {
      startDate = DateTime(_profitLossCustomDateRange!.start.year, _profitLossCustomDateRange!.start.month, _profitLossCustomDateRange!.start.day, 0, 0, 0);
      endDate = DateTime(_profitLossCustomDateRange!.end.year, _profitLossCustomDateRange!.end.month, _profitLossCustomDateRange!.end.day, 23, 59, 59);
    } else if (_profitLossPeriodFilter == 'All Time') {
       startDate = DateTime(2020);
       endDate = localNow;
    }
    final daysDiff = endDate.difference(startDate).inDays;

    final List<String> monthLabels = [];
    final List<double> revenueSeries = [];
    final List<double> expensesSeries = [];
    final List<double> netProfitSeries = [];

    final monthsAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    if (daysDiff <= 31) {
      final step = daysDiff <= 7 ? 1 : (daysDiff <= 14 ? 2 : 5);
      for (int day = 0; day <= daysDiff; day += step) {
        final curStart = startDate.add(Duration(days: day));
        final curEnd = curStart.add(Duration(days: step - 1, hours: 23, minutes: 59, seconds: 59));
        final label = '${curStart.day} ${monthsAbbr[curStart.month - 1]}';
        monthLabels.add(label);

        double rev = incomeState.incomes.where((i) {
          final d = DateTime.tryParse(i.date);
          return d != null && !d.isBefore(curStart) && !d.isAfter(curEnd);
        }).fold(0.0, (s, i) => s + i.amount);

        double exp = expensesState.expenses.where((e) {
          final d = DateTime.tryParse(e.date);
          return d != null && !d.isBefore(curStart) && !d.isAfter(curEnd);
        }).fold(0.0, (s, e) => s + e.amount);

        double pay = salariesState.salaries.where((sal) {
          final d = DateTime.tryParse(sal.paymentDate);
          return d != null && sal.status == 'Paid' && !d.isBefore(curStart) && !d.isAfter(curEnd);
        }).fold(0.0, (s, sal) => s + sal.netPaid);

        double totExp = exp + pay;
        revenueSeries.add(rev);
        expensesSeries.add(totExp);
        netProfitSeries.add(rev - totExp);
      }
    } else {
      int startM = startDate.month;
      int endM = endDate.month;
      int startY = startDate.year;
      int endY = endDate.year;

      for (int y = startY; y <= endY; y++) {
        int mFirst = (y == startY) ? startM : 1;
        int mLast = (y == endY) ? endM : 12;
        for (int m = mFirst; m <= mLast; m++) {
          monthLabels.add(monthsAbbr[m - 1]);
          double rev = incomeState.incomes.where((i) {
            final d = DateTime.tryParse(i.date);
            return d != null && d.year == y && d.month == m;
          }).fold(0.0, (s, i) => s + i.amount);

          double exp = expensesState.expenses.where((e) {
            final d = DateTime.tryParse(e.date);
            return d != null && d.year == y && d.month == m;
          }).fold(0.0, (s, e) => s + e.amount);

          double pay = salariesState.salaries.where((sal) {
            final d = DateTime.tryParse(sal.paymentDate);
            return d != null && sal.status == 'Paid' && d.year == y && d.month == m;
          }).fold(0.0, (s, sal) => s + sal.netPaid);

          double totExp = exp + pay;
          revenueSeries.add(rev);
          expensesSeries.add(totExp);
          netProfitSeries.add(rev - totExp);
        }
      }
    }

    final double totalRevenueVal = incomeState.incomes.where((i) {
      final d = DateTime.tryParse(i.date);
      return d != null && !d.isBefore(startDate) && !d.isAfter(endDate);
    }).fold(0.0, (s, i) => s + i.amount);

    final double expensesRaw = expensesState.expenses.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && !d.isBefore(startDate) && !d.isAfter(endDate);
    }).fold(0.0, (s, e) => s + e.amount);

    final double payrollRaw = salariesState.salaries.where((sal) {
      final d = DateTime.tryParse(sal.paymentDate);
      return d != null && sal.status == 'Paid' && !d.isBefore(startDate) && !d.isAfter(endDate);
    }).fold(0.0, (s, sal) => s + sal.netPaid);

    final double totalExpensesVal = expensesRaw + payrollRaw;
    final double netProfitVal = totalRevenueVal - totalExpensesVal;

    final double expMargin = totalRevenueVal > 0 ? ((totalExpensesVal / totalRevenueVal) * 100) : 0.0;
    final double netMargin = totalRevenueVal > 0 ? ((netProfitVal / totalRevenueVal) * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Profit & Loss Statement',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    ExportButton(
                      title: 'Profit & Loss Statement',
                      fileName: 'profit_and_loss_statement',
                      headers: const ['CLASSIFICATION', 'CATEGORY / ITEM', 'PERIOD AMOUNT (Rs.)', 'MARGIN %'],
                      rows: [
                        ['Gross Income', 'Total Client Revenue & Deposits', 'Rs. ${currencyFormat.format(totalRevenueVal)}', '100.0%'],
                        ['Operating Cost', 'Company Direct Expenses + Staff Payroll', 'Rs. ${currencyFormat.format(totalExpensesVal)}', '${expMargin.toStringAsFixed(1)}%'],
                        ['Net Profit / Loss', 'Net Revenue minus Operating Costs', 'Rs. ${currencyFormat.format(netProfitVal)}', '${netMargin.toStringAsFixed(1)}%'],
                      ],
                    ),
                  ],
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
                              DataCell(Text('Rs. ${currencyFormat.format(totalRevenueVal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                              const DataCell(Text('100.0%')),
                            ]),
                            DataRow(cells: [
                              const DataCell(Text('Operating Cost', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              const DataCell(Text('Company Direct Expenses + Staff Payroll')),
                              DataCell(Text('Rs. ${currencyFormat.format(totalExpensesVal)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              DataCell(Text('${expMargin.toStringAsFixed(1)}%')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('Net Profit / Loss', style: TextStyle(fontWeight: FontWeight.w900, color: netProfitVal >= 0 ? Colors.green : Colors.red))),
                              const DataCell(Text('Net Revenue minus Operating Costs', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text('Rs. ${currencyFormat.format(netProfitVal)}', style: TextStyle(fontWeight: FontWeight.w900, color: netProfitVal >= 0 ? Colors.green : Colors.red))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: netProfitVal >= 0 ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${netMargin.toStringAsFixed(1)}%',
                                    style: TextStyle(color: netProfitVal >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ),
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
        ),
        const SizedBox(height: 24),
        OverviewTrendChartWidget(
          title: 'Profit & Loss — Revenue vs Expenses vs Net Profit Trend',
          monthLabels: monthLabels.isNotEmpty ? monthLabels : const ['Jan'],
          revenueData: revenueSeries,
          expensesData: expensesSeries,
          netProfitData: netProfitSeries,
        ),
      ],
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
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
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
                                  ...((pl.revenueCategories as List<RevenueCategorySummary>? ?? []).map((rc) {
                                    bool hasPrior = pl.hasPriorYearData == true && (pl.priorYearAmounts as Map<String, double>)[rc.category] != null;
                                    double pVal = (pl.priorYearAmounts as Map<String, double>)[rc.category] ?? 0.0;
                                    double vPct = (hasPrior && pVal > 0) ? ((rc.amount - pVal) / pVal) * 100 : 0.0;
                                    return [
                                      rc.category,
                                      'Rs. ${rc.amount.toStringAsFixed(0)}',
                                      hasPrior ? 'Rs. ${pVal.toStringAsFixed(0)}' : '—',
                                      hasPrior && pVal > 0 ? '${vPct >= 0 ? "+" : ""}${vPct.toStringAsFixed(1)}%' : '—',
                                    ];
                                  })),
                                  ['TOTAL REVENUE', 'Rs. ${(pl.totalRevenue as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["totalRevenue"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['TOTAL COST OF GOODS SOLD', 'Rs. ${(pl.totalCogs as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["totalCogs"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['GROSS PROFIT', 'Rs. ${(pl.grossProfit as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["grossProfit"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ...((pl.expenseCategories as List<ExpenseCategorySummary>? ?? []).map((ec) {
                                    bool hasPrior = pl.hasPriorYearData == true && (pl.priorYearAmounts as Map<String, double>)[ec.category] != null;
                                    double pVal = (pl.priorYearAmounts as Map<String, double>)[ec.category] ?? 0.0;
                                    double vPct = (hasPrior && pVal > 0) ? ((ec.amount - pVal) / pVal) * 100 : 0.0;
                                    return [
                                      ec.category,
                                      'Rs. ${ec.amount.toStringAsFixed(0)}',
                                      hasPrior ? 'Rs. ${pVal.toStringAsFixed(0)}' : '—',
                                      hasPrior && pVal > 0 ? '${vPct >= 0 ? "+" : ""}${vPct.toStringAsFixed(1)}%' : '—',
                                    ];
                                  })),
                                  ['TOTAL OPERATING EXPENSES', 'Rs. ${(pl.totalOpEx as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["totalOpEx"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['OPERATING PROFIT (EBIT)', 'Rs. ${(pl.operatingProfit as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["operatingProfit"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['TOTAL FINANCE COSTS', 'Rs. ${(pl.totalFinanceCosts as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["totalFinanceCosts"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['NET PROFIT BEFORE TAX', 'Rs. ${(pl.netProfitPreTax as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["netProfitPreTax"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['INCOME TAX PROVISION', pl.hasTaxData == true ? 'Rs. ${(pl.taxProvision as double).toStringAsFixed(0)}' : '—', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["taxProvision"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
                                  ['NET PROFIT AFTER TAX', 'Rs. ${(pl.netProfitAfterTax as double).toStringAsFixed(0)}', pl.hasPriorYearData == true ? 'Rs. ${((pl.priorYearAmounts as Map<String, double>)["netProfitAfterTax"] ?? 0.0).toStringAsFixed(0)}' : '—', '—'],
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
    bool hasPrior = pl.hasPriorYearData == true;
    Map<String, double> pMap = pl.priorYearAmounts as Map<String, double>? ?? {};

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
      bool itemHasPrior = hasPrior && priorVal != null;
      double pVal = priorVal ?? 0.0;

      String priorStr = itemHasPrior
          ? (isLess ? '(${pVal.toStringAsFixed(0)})' : 'Rs. ${pVal.toStringAsFixed(0)}')
          : '—';

      String varianceStr = '—';
      if (itemHasPrior && pVal > 0) {
        double variancePct = ((currentVal - pVal) / pVal) * 100;
        varianceStr = variancePct >= 0 ? '+${variancePct.toStringAsFixed(1)}%' : '${variancePct.toStringAsFixed(1)}%';
      }

      String currentStr = customVal ?? (isLess ? '(${currentVal.toStringAsFixed(0)})' : 'Rs. ${currentVal.toStringAsFixed(0)}');

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
              color: varianceStr.startsWith('+') ? Colors.green : (varianceStr.startsWith('-') ? Colors.red : context.textSecondary),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          )),
        ],
      );
    }

    DataRow buildTotalRow(String title, double currentVal, {double? priorVal, Color? bgColor, Color? textColor, bool isBold = true}) {
      bool totalHasPrior = hasPrior && priorVal != null;
      double pVal = priorVal ?? 0.0;

      String priorStr = totalHasPrior ? 'Rs. ${pVal.toStringAsFixed(0)}' : '—';
      String varianceStr = '—';
      if (totalHasPrior && pVal > 0) {
        double variancePct = ((currentVal - pVal) / pVal) * 100;
        varianceStr = variancePct >= 0 ? '+${variancePct.toStringAsFixed(1)}%' : '${variancePct.toStringAsFixed(1)}%';
      }

      return DataRow(
        color: WidgetStateProperty.all(bgColor ?? Colors.blue.withValues(alpha: 0.08)),
        cells: [
          DataCell(Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textColor ?? context.textPrimary))),
          DataCell(Text('Rs. ${currentVal.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: textColor ?? context.textPrimary))),
          DataCell(Text(priorStr, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textSecondary))),
          DataCell(Text(
            varianceStr,
            style: TextStyle(
              color: varianceStr.startsWith('+') ? Colors.green : (varianceStr.startsWith('-') ? Colors.red : context.textSecondary),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          )),
        ],
      );
    }

    final List<RevenueCategorySummary> revCategories = pl.revenueCategories as List<RevenueCategorySummary>? ?? [];
    final List<ExpenseCategorySummary> expCategories = pl.expenseCategories as List<ExpenseCategorySummary>? ?? [];

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
                if (revCategories.isNotEmpty)
                  ...revCategories.map((rc) => buildItemRow(rc.category, rc.amount, priorVal: pMap[rc.category]))
                else
                  buildItemRow('Revenue / Income', pl.totalRevenue as double, priorVal: pMap['totalRevenue']),
                buildTotalRow('Total Revenue', pl.totalRevenue as double, priorVal: pMap['totalRevenue'], bgColor: Colors.blue.withValues(alpha: 0.08), textColor: Colors.blue),

                // 2. COST OF GOODS SOLD
                buildSectionHeaderRow('COST OF GOODS SOLD'),
                buildItemRow('Purchases & Direct Materials', pl.purchases as double, priorVal: pMap['purchases']),
                if ((pl.closingInventory as double) > 0)
                  buildItemRow('Closing Inventory Value', pl.closingInventory as double, priorVal: pMap['closingInventory']),
                buildTotalRow('Total Cost of Goods Sold', pl.totalCogs as double, priorVal: pMap['totalCogs'], bgColor: Colors.red.withValues(alpha: 0.05), textColor: Colors.redAccent),

                // 3. GROSS PROFIT
                buildTotalRow('GROSS PROFIT', pl.grossProfit as double, priorVal: pMap['grossProfit'], bgColor: Colors.blue.withValues(alpha: 0.12), textColor: Colors.blue, isBold: true),

                // 4. OPERATING EXPENSES
                buildSectionHeaderRow('OPERATING EXPENSES'),
                if (expCategories.isNotEmpty)
                  ...expCategories.map((ec) => buildItemRow(ec.category, ec.amount, priorVal: pMap[ec.category]))
                else
                  buildItemRow('Operating Expenses', pl.totalOpEx as double, priorVal: pMap['totalOpEx']),
                buildTotalRow('Total Operating Expenses', pl.totalOpEx as double, priorVal: pMap['totalOpEx'], bgColor: Colors.red.withValues(alpha: 0.05), textColor: Colors.redAccent),

                // 5. OPERATING PROFIT (EBIT)
                buildTotalRow('OPERATING PROFIT (EBIT)', pl.operatingProfit as double, priorVal: pMap['operatingProfit'], bgColor: Colors.blue.withValues(alpha: 0.15), textColor: Colors.blue),

                // 6. FINANCE COSTS
                buildSectionHeaderRow('FINANCE COSTS'),
                buildItemRow('Loan Interest Expense', pl.loanInterestExpense as double, priorVal: pMap['totalFinanceCosts']),
                buildTotalRow('Total Finance Costs', pl.totalFinanceCosts as double, priorVal: pMap['totalFinanceCosts'], bgColor: Colors.orange.withValues(alpha: 0.05), textColor: Colors.orange),

                // 7. NET PROFIT BEFORE TAX
                buildTotalRow('NET PROFIT BEFORE TAX', pl.netProfitPreTax as double, priorVal: pMap['netProfitPreTax'], bgColor: Colors.green.withValues(alpha: 0.12), textColor: Colors.green),

                // 8. TAX PROVISION
                buildItemRow(
                  'Income Tax Provision',
                  pl.taxProvision as double,
                  customVal: pl.hasTaxData == true ? null : '— (No Tax Data)',
                  priorVal: pMap['taxProvision'],
                ),

                // 9. NET PROFIT AFTER TAX
                buildTotalRow('NET PROFIT AFTER TAX', pl.netProfitAfterTax as double, priorVal: pMap['netProfitAfterTax'], bgColor: Colors.green.withValues(alpha: 0.22), textColor: Colors.green),
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
    bool hasPrior = pl.hasPriorYearData == true;
    double salesRev = (pl.salesRevenue as double) > 0 ? (pl.salesRevenue as double) : (pl.totalRevenue as double);
    double otherInc = pl.otherRevenue as double;
    double cogsVal = pl.totalCogs as double;
    double opExVal = pl.totalOpEx as double;

    Map<String, double> pMap = pl.priorYearAmounts as Map<String, double>? ?? {};
    double priorSales = hasPrior ? (pMap['salesRevenue'] ?? 0.0) : 0.0;
    double priorOther = hasPrior ? (pMap['otherRevenue'] ?? 0.0) : 0.0;
    double priorCogs = hasPrior ? (pMap['totalCogs'] ?? 0.0) : 0.0;
    double priorOpEx = hasPrior ? (pMap['totalOpEx'] ?? 0.0) : 0.0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current vs Prior Year',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimary,
                  ),
                ),
                if (!hasPrior)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'No Prior Data',
                      style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _CurrentVsPriorYearChartPainter(
                  currentSales: salesRev,
                  priorSales: priorSales,
                  currentOther: otherInc,
                  priorOther: priorOther,
                  currentCogs: cogsVal,
                  priorCogs: priorCogs,
                  currentOpEx: opExVal,
                  priorOpEx: priorOpEx,
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
                Text(hasPrior ? 'Prior Year' : 'Prior Year (No Data)', style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownProgressCard(BuildContext context, dynamic pl) {
    final List<ExpenseCategorySummary> categories = pl.expenseCategories as List<ExpenseCategorySummary>? ?? [];
    final double totalOpEx = (pl.totalOpEx as double) > 0 ? (pl.totalOpEx as double) : 1.0;

    final List<Color> cardColors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.blueGrey,
      Colors.deepOrange,
      Colors.pink,
    ];

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
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No expenses recorded for this period',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              ...categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final color = cardColors[idx % cardColors.length];
                final ratio = (cat.amount / totalOpEx).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.category, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Rs. ${cat.amount.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
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
              }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  7. BALANCE SHEET VIEW & BALANCE CHECK DASHBOARD
  // ═══════════════════════════════════════════════════════════
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
    final reportsState = ref.watch(financialReportsProvider);
    final DateTime asOfDate = reportsState.endDate;
    final DateFormat df = DateFormat('dd MMMM yyyy');
    final String asOfFormatted = df.format(asOfDate);

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

    final headerCard = GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: asOfDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  ref.read(reportFilterProvider.notifier).setFilter(
                    filter.copyWith(
                      dateRange: ReportDateRange.custom,
                      customStartDate: DateTime(2020, 1, 1),
                      customEndDate: DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.calendar_today_outlined, color: context.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('As of Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary)),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 12, color: context.textSecondary.withValues(alpha: 0.7)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          asOfFormatted,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ExportButton(
              title: 'Balance Sheet (As of $asOfFormatted)',
              fileName: 'balance_sheet_report_${asOfDate.year}_${asOfDate.month}_${asOfDate.day}',
              headers: const ['SECTION / ACCOUNT', 'AMOUNT (Rs.)'],
              rows: [
                ['--- CURRENT ASSETS ---', ''],
                ['Cash in Hand', 'Rs. ${(al.cashInHand as double).toStringAsFixed(0)}'],
                ['Bank Accounts', 'Rs. ${(al.bankAccounts as double).toStringAsFixed(0)}'],
                ['Accounts Receivable', 'Rs. ${(al.accountsReceivable as double).toStringAsFixed(0)}'],
                ['Inventory', 'Rs. ${(al.inventoryValue as double).toStringAsFixed(0)}'],
                ['Advances & Prepayments', 'Rs. ${(al.advancesPrepayments as double).toStringAsFixed(0)}'],
                ['Total Current Assets', 'Rs. ${(al.totalCurrentAssets as double).toStringAsFixed(0)}'],
                ['--- NON-CURRENT ASSETS ---', ''],
                if ((al.assetManagementList as List).isNotEmpty)
                  ... (al.assetManagementList as List).map((asset) {
                    final name = asset is Map ? asset['name'] : asset.name;
                    final type = asset is Map ? asset['type'] : asset.type;
                    final cost = asset is Map ? (asset['cost'] as double) : (asset.cost as double);
                    return ['$name ($type)', 'Rs. ${cost.toStringAsFixed(0)}'];
                  })
                else ...[
                  if ((al.computersItEquipment as double) > 0)
                    ['Computers & IT Equipment', 'Rs. ${(al.computersItEquipment as double).toStringAsFixed(0)}'],
                  if ((al.furnitureFixtures as double) > 0)
                    ['Furniture & Fixtures', 'Rs. ${(al.furnitureFixtures as double).toStringAsFixed(0)}'],
                  if ((al.vehicles as double) > 0)
                    ['Vehicles', 'Rs. ${(al.vehicles as double).toStringAsFixed(0)}'],
                  if ((al.machineryPlant as double) > 0)
                    ['Machinery & Plant', 'Rs. ${(al.machineryPlant as double).toStringAsFixed(0)}'],
                  if ((al.officeEquipment as double) > 0)
                    ['Office Equipment', 'Rs. ${(al.officeEquipment as double).toStringAsFixed(0)}'],
                  if ((al.computersItEquipment as double) == 0 &&
                      (al.furnitureFixtures as double) == 0 &&
                      (al.vehicles as double) == 0 &&
                      (al.machineryPlant as double) == 0 &&
                      (al.officeEquipment as double) == 0)
                    ['Hardware & Fixed Assets', 'Rs. 0'],
                ],
                if ((al.lessAccumulatedDepreciation as double) > 0)
                  ['Less: Accumulated Depreciation', '(Rs. ${(al.lessAccumulatedDepreciation as double).toStringAsFixed(0)})'],
                ['Total Non-Current Assets', 'Rs. ${(al.totalNonCurrentAssets as double).toStringAsFixed(0)}'],
                ['TOTAL ASSETS', 'Rs. ${(al.totalAssets as double).toStringAsFixed(0)}'],
                ['--- CURRENT LIABILITIES ---', ''],
                ['Accounts Payable', 'Rs. ${(al.accountsPayable as double).toStringAsFixed(0)}'],
                ['Salaries Payable', 'Rs. ${(al.salariesPayable as double).toStringAsFixed(0)}'],
                if ((al.taxPayable as double) > 0)
                  ['Tax Payable', 'Rs. ${(al.taxPayable as double).toStringAsFixed(0)}'],
                if ((al.bankLoanAmount as double) > 0)
                  ['Bank / Financial Loan', 'Rs. ${(al.bankLoanAmount as double).toStringAsFixed(0)}'],
                if ((al.ownerLoanAmount as double) > 0)
                  ['Owner Loan / Due to Owner', 'Rs. ${(al.ownerLoanAmount as double).toStringAsFixed(0)}'],
                if ((al.otherLoanAmount as double) > 0)
                  ['Other Short-term Loan', 'Rs. ${(al.otherLoanAmount as double).toStringAsFixed(0)}'],
                if ((al.bankLoanAmount as double) == 0 && (al.ownerLoanAmount as double) == 0 && (al.otherLoanAmount as double) == 0 && (al.shortTermLoans as double) > 0)
                  ['Short-term Loans', 'Rs. ${(al.shortTermLoans as double).toStringAsFixed(0)}'],
                if ((al.shortTermLoans as double) == 0)
                  ['Short-term Loans', 'Rs. 0'],
                ['Total Current Liabilities', 'Rs. ${(al.totalCurrentLiabilities as double).toStringAsFixed(0)}'],
                ['--- NON-CURRENT LIABILITIES ---', ''],
                ['Long-term Bank Loans', 'Rs. ${(al.longTermBankLoans as double).toStringAsFixed(0)}'],
                ['Total Non-Current Liabilities', 'Rs. ${(al.totalNonCurrentLiabilities as double).toStringAsFixed(0)}'],
                ['TOTAL LIABILITIES', 'Rs. ${(al.totalLiabilities as double).toStringAsFixed(0)}'],
                ['--- EQUITY ---', ''],
                ['Owner\'s Capital', 'Rs. ${(al.ownersCapital as double).toStringAsFixed(0)}'],
                ['Retained Earnings', 'Rs. ${(al.retainedEarnings as double).toStringAsFixed(0)}'],
                if ((al.lessOwnersDrawings as double) > 0)
                  ['Less: Owner\'s Drawings', '(Rs. ${(al.lessOwnersDrawings as double).toStringAsFixed(0)})'],
                ['TOTAL EQUITY', 'Rs. ${(al.totalEquity as double).toStringAsFixed(0)}'],
                ['TOTAL LIABILITIES + EQUITY', 'Rs. ${(al.totalLiabilitiesAndEquity as double).toStringAsFixed(0)}'],
              ],
            ),
          ],
        ),
      ),
    );

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
                        if ((al.taxPayable as double) > 0)
                          buildItemRow('Tax Payable', al.taxPayable as double),

                        // Short-term Loans Breakdown
                        if ((al.bankLoanAmount as double) > 0)
                          buildItemRow('Bank / Financial Loan', al.bankLoanAmount as double),
                        if ((al.ownerLoanAmount as double) > 0)
                          buildItemRow('Owner Loan / Due to Owner', al.ownerLoanAmount as double),
                        if ((al.otherLoanAmount as double) > 0)
                          buildItemRow('Other Short-term Loan', al.otherLoanAmount as double),
                        if ((al.bankLoanAmount as double) == 0 && (al.ownerLoanAmount as double) == 0 && (al.otherLoanAmount as double) == 0 && (al.shortTermLoans as double) > 0)
                          buildItemRow('Short-term Loans', al.shortTermLoans as double),
                        if ((al.shortTermLoans as double) == 0)
                          buildItemRow('Short-term Loans', 0.0),

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
        final double diff = (totalAssetsVal - totalLiabAndEquityVal).abs();
        final bool isMatched = diff < 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerCard,
            const SizedBox(height: 20),

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
                    LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final isNarrow = boxConstraints.maxWidth < 600;
                        final card1 = Container(
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
                        );
                        final card2 = Container(
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
                        );
                        final card3 = Container(
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
                        );

                        if (isNarrow) {
                          return Column(
                            children: [
                              card1,
                              const SizedBox(height: 10),
                              card2,
                              const SizedBox(height: 10),
                              card3,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: card1),
                            const SizedBox(width: 16),
                            Expanded(child: card2),
                            const SizedBox(width: 16),
                            Expanded(child: card3),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isMatched ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isMatched ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isMatched ? Icons.check_circle_outline : Icons.error_outline,
                                color: isMatched ? Colors.green : Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Assets = Liabilities + Equity',
                                  style: TextStyle(
                                    color: isMatched ? Colors.green : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMatched
                                ? 'Rs. ${totalAssetsVal.toStringAsFixed(0)} = Rs. ${totalLiabAndEquityVal.toStringAsFixed(0)}  ✓ MATCH'
                                : 'Rs. ${totalAssetsVal.toStringAsFixed(0)} ≠ Rs. ${totalLiabAndEquityVal.toStringAsFixed(0)}  ✗ NOT BALANCED (Diff: Rs. ${diff.toStringAsFixed(0)})',
                            style: TextStyle(
                              color: isMatched ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = max(constraints.maxWidth, monthLabels.length * (constraints.maxWidth < 600 ? 40.0 : 52.0));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 260,
                    width: minWidth,
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
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.redAccent, 'Expenses'),
                _buildLegendItem(Colors.green, 'Net Profit'),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = max(constraints.maxWidth, monthLabels.length * (constraints.maxWidth < 600 ? 40.0 : 52.0));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 260,
                    width: minWidth,
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
                );
              },
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

    double maxVal = 0;
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

      final label = CurrencyFormatter.formatCurrency(val);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
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
        textDirection: ui.TextDirection.ltr,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = max(constraints.maxWidth, monthLabels.length * (constraints.maxWidth < 600 ? 40.0 : 52.0));
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 260,
                    width: minWidth,
                    child: CustomPaint(
                      painter: _ExpensesCategoryBarChartPainter(
                        monthLabels: monthLabels,
                        categoryMonthlyData: categoryMonthlyData,
                        textColor: context.textSecondary,
                        gridColor: context.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(const Color(0xFF0088FE), 'COGS'),
                _buildLegendItem(const Color(0xFFD6BBFC), 'Other'),
                _buildLegendItem(const Color(0xFF9333EA), 'Rent'),
                _buildLegendItem(const Color(0xFF4F46E5), 'Salaries'),
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

    double maxVal = 0;
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

      final label = CurrencyFormatter.formatCurrency(val);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
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
        textDirection: ui.TextDirection.ltr,
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

    double maxVal = 0;
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

      final label = CurrencyFormatter.formatCurrency(val);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
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
        textDirection: ui.TextDirection.ltr,
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

    double maxVal = 0;
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

      final label = CurrencyFormatter.formatCurrency(val);

      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: ui.TextDirection.ltr,
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
        textDirection: ui.TextDirection.ltr,
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
