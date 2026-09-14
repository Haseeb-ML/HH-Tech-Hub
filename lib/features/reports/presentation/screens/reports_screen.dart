import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';

// Import providers
import 'package:software_house_erp/features/hr/employees/presentation/providers/employees_provider.dart';
import 'package:software_house_erp/features/projects/projects/presentation/providers/projects_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _activeTab = 0; // 0: Projects, 1: Resources

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    
    // Watch all data providers for real-time aggregation
    final projectsState = ref.watch(projectsProvider);
    final employeesState = ref.watch(employeesProvider);
    final assetsState = ref.watch(assetsProvider);
    final inventoryState = ref.watch(inventoryProvider);

    final isLoading = projectsState.isLoading ||
        employeesState.isLoading ||
        assetsState.isLoading ||
        inventoryState.isLoading;

    // Construct dynamic export data based on active tab
    String exportTitle;
    String exportFileName;
    List<String> exportHeaders;
    List<List<dynamic>> exportRows;

    if (_activeTab == 0) {
      exportTitle = 'Projects Portfolio Report';
      exportFileName = 'projects_portfolio_report';
      exportHeaders = ['Project ID', 'Project Name', 'Client Name', 'Budget', tr('Status'), 'Start Date', 'End Date'];
      exportRows = projectsState.projects.map((p) => [
        p.id,
        p.name,
        p.clientName,
        'Rs. ${p.budget.toStringAsFixed(0)}',
        p.status,
        p.startDate,
        p.endDate,
      ]).toList();
    } else {
      exportTitle = 'Resources & Staffing Report';
      exportFileName = 'resources_staffing_report';
      exportHeaders = ['Resource ID', tr('Type'), 'Name', 'Category / Dept', 'Details', 'Cost / Price'];
      exportRows = [
        ...employeesState.employees.map((e) => [e.id, 'Staff', e.name, e.department, e.designation, 'Rs. ${e.baseSalary.toStringAsFixed(0)}']),
        ...assetsState.assets.map((a) => [a.id, 'Hardware Asset', a.name, a.type, 'Condition: ${a.condition}', 'Rs. ${a.cost.toStringAsFixed(0)}']),
        ...inventoryState.items.map((i) => [i.id, tr('Office Inventory'), i.name, i.category, 'Qty: ${i.quantity} ${i.unit}', 'Rs. ${i.pricePerUnit.toStringAsFixed(0)}']),
      ];
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Top Navigation Tabs ───────────────────
                _buildSubNav(),

                // ── Main Content Area ─────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Header
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 12,
                              spacing: 16,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  tr('Business Reports & Analytics'),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('Real-time data aggregation and visual intelligence for HH Tech Operations.'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ExportButton(
                                title: exportTitle,
                                fileName: exportFileName,
                                headers: exportHeaders,
                                rows: exportRows,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Switch Tab Body
                        if (_activeTab == 0)
                          _buildProjectsTab(projectsState)
                        else
                          _buildResourcesTab(employeesState, assetsState, inventoryState),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── SUB NAV ──────────────────────────────────────────
  Widget _buildSubNav() {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final tabs = [
      {'label': tr('Projects & Operations'), 'icon': Icons.assignment_turned_in_outlined},
      {'label': tr('Resources & Staffing'), 'icon': Icons.badge_outlined},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final tab = tabs[idx];
          final isActive = _activeTab == idx;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = idx),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? context.primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? context.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 16,
                      color: isActive ? context.primaryColor : context.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab['label'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isActive ? context.primaryColor : context.textSecondary,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── PROJECTS & OPERATIONS TAB ─────────────────────────
  Widget _buildProjectsTab(ProjectsState projState) {
    final tr = ref.watch(translationProvider);
    final projects = projState.projects;

    // Status counts
    final totalProjects = projects.length;
    final inProgress = projects.where((p) => p.status == 'In Progress').length;
    final completed = projects.where((p) => p.status == 'Completed').length;
    final planning = projects.where((p) => p.status == 'Planning').length;
    final onHold = projects.where((p) => p.status == 'On Hold').length;

    // Total budget allocation
    final totalBudget = projects.fold<double>(0, (sum, p) => sum + p.budget);

    // Group budgets by status
    final statusBudgets = <String, double>{
      'In Progress': 0,
      'Completed': 0,
      'Planning': 0,
      'On Hold': 0,
    };
    for (var p in projects) {
      statusBudgets[p.status] = (statusBudgets[p.status] ?? 0.0) + p.budget;
    }

    final barChartData = statusBudgets.entries.map((entry) {
      return _BarData(
        label: entry.key,
        primaryValue: entry.value,
        secondaryValue: 0.0, // only single bar chart needed
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operations metrics
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: tr('Active Projects'),
                value: '$inProgress',
                icon: Icons.computer_outlined,
                iconColor: context.info,
                iconBgColor: context.infoLight,
                trendText: tr('Currently developing'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Completed',
                tooltipMessage: 'Detailed statistics and information regarding Completed.',
                value: '$completed',
                icon: Icons.check_circle_outline,
                iconColor: context.success,
                iconBgColor: context.successLight,
                trendText: tr('Finished deployments'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Total Portfolio Budget',
                tooltipMessage: 'Detailed statistics and information regarding Total Portfolio Budget.',
                value: 'Rs. ${(totalBudget / 1000).toStringAsFixed(0)}k',
                icon: Icons.monetization_on_outlined,
                iconColor: context.primaryColor,
                iconBgColor: context.infoLight,
                trendText: tr('Accumulated project budgets'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: tr('Queue / Planning'),
                tooltipMessage: "Detailed statistics and information regarding ${tr('Queue / Planning')}.",
                value: '${planning + onHold}',
                icon: Icons.hourglass_empty,
                iconColor: context.warning,
                iconBgColor: context.warningLight,
                trendText: tr('Planning or On Hold'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Budget Allocation by Status Chart
            Expanded(
              flex: 5,
              child: GlassCard(
                title: 'Budget Allocation by Project Status',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _CustomBarChart(
                    data: barChartData,
                    primaryColor: context.primaryColor,
                    secondaryColor: Colors.transparent,
                    primaryLegend: tr('Allocated Budget (Rs.)'),
                    secondaryLegend: '',
                    isSingleBar: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right: Project Completion Efficiency
            Expanded(
              flex: 3,
              child: GlassCard(
                title: 'Project Delivery Health',
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Circular percentage indicator
                      _buildCircularIndicator(
                        value: totalProjects > 0 ? completed / totalProjects : 0.0,
                        title: 'Success Rate',
                        subtitle: tr('Ratio of Completed projects'),
                        color: context.success,
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSummaryRow(tr('Total Projects'), '$totalProjects'),
                      const SizedBox(height: 8),
                      _buildSummaryRow('In Progress', '$inProgress', color: context.info),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Completed', '$completed', color: context.success),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── RESOURCES & HR TAB ────────────────────────────────
  Widget _buildResourcesTab(EmployeesState empState, AssetsState assetState, InventoryState invState) {
    final tr = ref.watch(translationProvider);
    // 1. Calculations
    final employees = empState.employees;
    final totalStaff = employees.length;
    
    // Department Headcounts
    final deptCount = <String, int>{
      'Mobile Apps': 0,
      'Design': 0,
      'Quality Assurance': 0,
      'Management': 0,
      'Web Development': 0,
    };
    for (var emp in employees) {
      if (emp.status == 'Active') {
        deptCount[emp.department] = (deptCount[emp.department] ?? 0) + 1;
      }
    }

    // Asset Valuation
    final totalAssetsValue = assetState.assets.fold<double>(0, (sum, a) => sum + a.cost);
    final assignedAssets = assetState.assets.where((a) => a.status == 'Assigned').length;

    // Inventory Health
    final lowStockItems = invState.items.where((i) => i.quantity <= i.minQuantity).length;

    final breakdownItems = deptCount.entries.map((entry) {
      final percentage = totalStaff > 0 ? (entry.value / totalStaff) * 100 : 0.0;
      return _BreakdownItem(
        name: entry.key,
        value: entry.value.toDouble(),
        percentage: percentage,
      );
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resource metrics
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: tr('Total Active Staff'),
                tooltipMessage: "Detailed statistics and information regarding ${tr('Total Active Staff')}.",
                value: '$totalStaff',
                icon: Icons.people_outline,
                iconColor: context.primaryColor,
                iconBgColor: context.infoLight,
                trendText: tr('Registered headcount'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: tr('Hardware & License Assets'),
                tooltipMessage: "Detailed statistics and information regarding ${tr('Hardware & License Assets')}.",
                value: 'Rs. ${(totalAssetsValue / 1000).toStringAsFixed(0)}k',
                icon: Icons.computer_outlined,
                iconColor: context.success,
                iconBgColor: context.successLight,
                trendText: tr('Equipment inventory cost'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: tr('Assets Deployed'),
                tooltipMessage: "Detailed statistics and information regarding ${tr('Assets Deployed')}.",
                value: '$assignedAssets / ${assetState.assets.length}',
                icon: Icons.assignment_ind_outlined,
                iconColor: context.info,
                iconBgColor: context.infoLight,
                trendText: tr('Active device allocations'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: tr('Low Stock Alert Items'),
                tooltipMessage: "Detailed statistics and information regarding ${tr('Low Stock Alert Items')}.",
                value: '$lowStockItems',
                icon: Icons.warning_amber_outlined,
                iconColor: context.warning,
                iconBgColor: context.warningLight,
                trendText: tr('Inventory restocking needed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Department Headcount Share Breakdown
            Expanded(
              flex: 4,
              child: GlassCard(
                title: tr('Active Employees by Department'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CustomBreakdownList(
                    items: breakdownItems,
                    isHeadcount: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right: Asset Condition & Stock Status Circular Indicator
            Expanded(
              flex: 4,
              child: GlassCard(
                title: tr('Office Resource Allocation Health'),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCircularIndicator(
                        value: assetState.assets.isNotEmpty
                            ? assetState.assets.where((a) => a.condition != 'Damaged' && a.condition != 'Fair').length / assetState.assets.length
                            : 0.0,
                        title: tr('Asset Quality'),
                        subtitle: tr('Ratio in Good/New condition'),
                        color: context.success,
                      ),
                      _buildCircularIndicator(
                        value: invState.items.isNotEmpty
                            ? (invState.items.length - lowStockItems) / invState.items.length
                            : 0.0,
                        title: tr('Stock Health'),
                        subtitle: tr('Ratio of healthy inventory lines'),
                        color: context.info,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper circular graph
  Widget _buildCircularIndicator({
    required double value,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                color: color,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: context.textMuted, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String val, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        Text(
          val,
          style: TextStyle(
            color: color ?? context.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM BAR CHART WIDGET ────────────────────────────
class _BarData {
  final String label;
  final double primaryValue;
  final double secondaryValue;

  _BarData({
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
  });
}

class _CustomBarChart extends ConsumerWidget {
  final List<_BarData> data;
  final Color primaryColor;
  final Color secondaryColor;
  final String primaryLegend;
  final String secondaryLegend;
  final bool isSingleBar;

  const _CustomBarChart({
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
    required this.primaryLegend,
    required this.secondaryLegend,
    this.isSingleBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    // Find max value in dataset to scale heights
    double maxValue = 1.0;
    for (var d in data) {
      if (d.primaryValue > maxValue) maxValue = d.primaryValue;
      if (d.secondaryValue > maxValue) maxValue = d.secondaryValue;
    }

    const double chartHeight = 150.0;

    return Column(
      children: [
        // Legend Row
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Text(primaryLegend, style: TextStyle(color: context.textSecondary, fontSize: 11)),
              ],
            ),
            if (!isSingleBar) ...[
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(secondaryLegend, style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Grid & Bars Stack
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = data.length * 82.0 > constraints.maxWidth
                ? data.length * 82.0
                : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Stack(
                  children: [
            // Grid background lines
            SizedBox(
              height: chartHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return Container(
                    height: 1,
                    color: context.border.withValues(alpha: 0.5),
                  );
                }),
              ),
            ),

            // The Bars
            Container(
              height: chartHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) {
                  final double primaryHeight = maxValue > 0 ? (d.primaryValue / maxValue) * (chartHeight - 40) : 0.0;
                  final double secondaryHeight = maxValue > 0 ? (d.secondaryValue / maxValue) * (chartHeight - 40) : 0.0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Primary Bar
                          Tooltip(
                            message: '${d.label}: Rs. ${(d.primaryValue).toStringAsFixed(0)}',
                            child: Container(
                              width: 14,
                              height: primaryHeight > 12 ? primaryHeight : (d.primaryValue > 0 ? 12.0 : 4.0),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                          if (!isSingleBar) ...[
                            const SizedBox(width: 4),
                            // Secondary Bar
                            Tooltip(
                              message: '${d.label}: Rs. ${(d.secondaryValue).toStringAsFixed(0)}',
                              child: Container(
                                width: 14,
                                height: secondaryHeight > 12 ? secondaryHeight : (d.secondaryValue > 0 ? 12.0 : 4.0),
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          tr(d.label),
                          style: TextStyle(color: context.textSecondary, fontSize: 9, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── BREAKDOWN PROGRESS LIST ───────────────────────────
class _BreakdownItem {
  final String name;
  final double value;
  final double percentage;

  _BreakdownItem({
    required this.name,
    required this.value,
    required this.percentage,
  });
}

class _CustomBreakdownList extends ConsumerWidget {
  final List<_BreakdownItem> items;
  final bool isHeadcount;

  const _CustomBreakdownList({
    required this.items,
    this.isHeadcount = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    if (items.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No records to display.',
            style: TextStyle(color: context.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: items.take(5).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(item.name),
                    style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isHeadcount
                        ? '${item.value.toInt()} Staff (${item.percentage.toStringAsFixed(0)}%)'
                        : 'Rs. ${(item.value / 1000).toStringAsFixed(0)}k (${item.percentage.toStringAsFixed(0)}%)',
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.percentage / 100,
                  backgroundColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                  color: context.primaryColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
