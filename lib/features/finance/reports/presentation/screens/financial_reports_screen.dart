import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
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
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tab Specific Body Content
                  if (_selectedIndex == 0)
                    _buildFinanceSummaryView(context, pl, al)
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
  ) {
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
                trendText: 'Income vs last period',
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
                trendText: 'Costs vs last period',
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
                trendText: 'Outstanding bills & expenses',
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

        // Breakdown Card Table
        GlassCard(
          title: 'Financial Breakdown Summary',
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Classification')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Amount (Rs.)')),
                DataColumn(label: Text('Percentage / Status')),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('Revenue')),
                  const DataCell(Text('Client Invoices & Income')),
                  DataCell(Text('Rs. ${pl.totalRevenue.toStringAsFixed(2)}')),
                  const DataCell(Text('100.0%')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Expense')),
                  const DataCell(Text('Direct Expenses & Payroll')),
                  DataCell(Text('Rs. ${pl.totalExpenses.toStringAsFixed(2)}')),
                  DataCell(Text('${pl.totalRevenue > 0 ? ((pl.totalExpenses / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}%')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Net Margin')),
                  const DataCell(Text('Net Profit / Loss')),
                  DataCell(Text('Rs. ${pl.netProfit.toStringAsFixed(2)}')),
                  DataCell(Text('${pl.totalRevenue > 0 ? ((pl.netProfit / pl.totalRevenue) * 100).toStringAsFixed(1) : "0"}%')),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Working Capital')),
                  const DataCell(Text('Assets minus Liabilities')),
                  DataCell(Text('Rs. ${al.workingCapital.toStringAsFixed(2)}')),
                  DataCell(Text(al.workingCapital >= 0 ? 'Healthy' : 'Deficit')),
                ]),
              ],
            ),
          ),
        ),
      ],
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
