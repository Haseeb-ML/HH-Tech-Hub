import 'dart:math';
import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/app_logo.dart';

// Providers & Entities imports
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/clients/clients/presentation/providers/clients_provider.dart';
import 'package:software_house_erp/features/hr/employees/presentation/providers/employees_provider.dart';
import 'package:software_house_erp/features/projects/projects/presentation/providers/projects_provider.dart';
import 'package:software_house_erp/features/projects/tasks/presentation/providers/tasks_provider.dart';
import 'package:software_house_erp/features/projects/tasks/domain/entities/project_task.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    final len = integerPart.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }
    return '${isNegative ? '-' : ''}Rs. $buffer.$decimalPart';
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[parsed.month - 1]} ${parsed.day.toString().padLeft(2, '0')}, ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    // Watch states
    final incomesState = ref.watch(incomeProvider);
    final expensesState = ref.watch(expensesProvider);
    final clientsState = ref.watch(clientsProvider);
    final employeesState = ref.watch(employeesProvider);
    final projectsState = ref.watch(projectsProvider);
    final tasksState = ref.watch(tasksProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final assetsState = ref.watch(assetsProvider);
    final adminState = ref.watch(adminProvider);

    // Filter company expenses
    final companyExpenses = expensesState.expenses.where((e) => !e.isPersonalExpense).toList();

    // Calculate metrics
    final totalIncome = incomesState.incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final totalExpense = companyExpenses.fold<double>(0.0, (sum, i) => sum + i.amount);
    final netProfit = totalIncome - totalExpense;

    final activeClientsCount = clientsState.clients.where((c) => c.status == 'Active').length;
    final totalStaffCount = employeesState.employees.length;
    final activeStaffCount = employeesState.employees.where((e) => e.status == 'Active').length;
    final ongoingProjectsCount = projectsState.projects.where((p) => p.status == 'In Progress').length;

    // Check module view permissions
    final canViewFinance = adminState.hasPermission(AppModule.finance, PermissionAction.view);
    final canViewClients = adminState.hasPermission(AppModule.clients, PermissionAction.view);
    final canViewHR = adminState.hasPermission(AppModule.hr, PermissionAction.view);
    final canViewProjects = adminState.hasPermission(AppModule.projects, PermissionAction.view);
    final canViewInventory = adminState.hasPermission(AppModule.inventory, PermissionAction.view);
    final canViewAdministration = adminState.hasPermission(AppModule.administration, PermissionAction.view);

    final currentUser = adminState.currentUser;
    final userName = currentUser != null && currentUser.name.isNotEmpty
        ? currentUser.name
        : (currentUser?.username ?? 'Admin');

    // Dynamic Lists processing
    // 1. Transactions
    final allTransactions = [
      ...incomesState.incomes.map((inc) {
        String desc = inc.description.trim();
        if (desc.isEmpty || desc.toLowerCase() == 'no comment') {
          desc = inc.clientName.isNotEmpty ? 'Income from ${inc.clientName}' : 'General Income';
        }
        return _TransactionItem(
          desc,
          'Revenue',
          inc.amount,
          inc.date,
          true,
        );
      }),
      ...companyExpenses.map((exp) {
        String desc = exp.description.trim();
        if (desc.isEmpty || desc.toLowerCase() == 'no comment') {
          desc = exp.vendorName.isNotEmpty
              ? 'Expense to ${exp.vendorName}'
              : (exp.category.isNotEmpty ? exp.category : 'General Expense');
        }
        return _TransactionItem(
          desc,
          exp.category.isNotEmpty ? exp.category : 'Expense',
          exp.amount,
          exp.date,
          false,
        );
      }),
    ];
    allTransactions.sort((a, b) {
      final dtA = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = dtB.compareTo(dtA);
      if (cmp != 0) return cmp;
      return b.date.compareTo(a.date);
    });
    final recentTransactions = allTransactions.take(5).toList();

    // 2. Activities (Audit Logs)
    final recentActivities = adminState.logs.map((log) {
      IconData icon;
      Color color;
      switch (log.module) {
        case 'HR':
          icon = Icons.person_add_outlined;
          color = Colors.teal;
          break;
        case 'Finance':
          icon = Icons.account_balance_outlined;
          color = context.success;
          break;
        case 'Projects':
          icon = Icons.assignment_outlined;
          color = context.primaryColor;
          break;
        case 'Inventory':
          icon = Icons.shopping_cart_outlined;
          color = context.warning;
          break;
        default:
          icon = Icons.settings_outlined;
          color = Colors.purple;
      }
      return _ActivityItem(log.action, log.timestamp, icon, color);
    }).take(4).toList();

    // 3. Upcoming Tasks
    final upcomingTasks = tasksState.tasks
        .where((t) => t.status != 'Done')
        .map((t) => _TaskItem(
              t.title,
              t.dueDate,
              t.assigneeName,
              t.status == 'Done',
              t,
            ))
        .toList();
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final displayTasks = upcomingTasks.take(4).toList();

    // 4. Low Stock Alerts & Critical Assets
    final lowStockSupplies = inventoryState.items
        .where((item) => item.quantity <= item.minQuantity)
        .map((item) => _StockAlertItem(
              item.name,
              '${item.quantity} ${item.unit} left',
              'Minimum ${item.minQuantity} ${item.unit}',
              context.error,
              context.errorLight,
            ));

    final criticalAssets = assetsState.assets
        .where((a) => a.status == 'Under Maintenance' || a.condition == 'Damaged')
        .map((a) => _StockAlertItem(
              a.name,
              a.status,
              a.condition == 'Damaged' ? 'Damaged condition - Repair required' : 'Scheduled maintenance',
              context.warning,
              context.warningLight,
            ));

    final displayAlerts = [...lowStockSupplies, ...criticalAssets].take(4).toList();

    final isMobile = width < 768;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border, width: 1),
                        ),
                        child: const AppLogo(
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${tr('Welcome back')}, $userName',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('Here is a quick overview of Software House performance today.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ref.read(cloudSyncStateProvider.notifier).syncNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: context.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text(
                                      tr('Dashboard data synced and updated.'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: context.error,
                                content: Text(tr('Failed to sync data: $e')),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.cardBg,
                        foregroundColor: context.textPrimary,
                        elevation: 0,
                        side: BorderSide(color: context.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: const AppLogo(
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tr('Welcome back')}, $userName',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentUser != null && currentUser.role.isNotEmpty
                                    ? '${tr('Role')}: ${currentUser.role} • ${tr('Here is a quick overview of Software House performance today.')}'
                                    : tr('Here is a quick overview of Software House performance today.'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fresh refresh indicator
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(cloudSyncStateProvider.notifier).syncNow();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: context.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    tr('Dashboard data synced and updated.'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: context.error,
                              content: Text(tr('Failed to sync data: $e')),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.cardBg,
                      foregroundColor: context.textPrimary,
                      elevation: 0,
                      side: BorderSide(color: context.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
  
            // Overview Metrics Grid
            Builder(
              builder: (context) {
                final List<Widget> visibleStatCards = [];
                if (canViewFinance) {
                  visibleStatCards.addAll([
                    StatCard(
                      title: tr('Total Income'),
                      tooltipMessage: "Detailed statistics and information regarding ${tr('Total Income')}.",
                      value: _formatCurrency(totalIncome),
                      icon: Icons.trending_up,
                      iconColor: context.success,
                      iconBgColor: context.successLight,
                      trendText: tr('Live registry inflow'),
                      isPositiveTrend: true,
                    ),
                    StatCard(
                      title: tr('Total Expense'),
                      value: _formatCurrency(totalExpense),
                      icon: Icons.trending_down,
                      iconColor: context.error,
                      iconBgColor: context.errorLight,
                      trendText: tr('Live registry outflow'),
                      isPositiveTrend: false,
                    ),
                    StatCard(
                      title: 'Net Profit',
                      tooltipMessage: 'Detailed statistics and information regarding Net Profit.',
                      value: _formatCurrency(netProfit),
                      icon: Icons.account_balance,
                      iconColor: context.primaryColor,
                      iconBgColor: context.infoLight,
                      trendText: netProfit >= 0 ? 'Positive net margin' : 'Deficit margin',
                      isPositiveTrend: netProfit >= 0,
                    ),
                  ]);
                }
                if (canViewClients) {
                  visibleStatCards.add(
                    StatCard(
                      title: 'Total Clients',
                      tooltipMessage: 'Detailed statistics and information regarding Total Clients.',
                      value: '$activeClientsCount Active',
                      icon: Icons.business,
                      iconColor: Colors.purple,
                      iconBgColor: context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF),
                      trendText: '${clientsState.clients.length} registered total',
                      isPositiveTrend: true,
                    ),
                  );
                }
                if (canViewHR) {
                  visibleStatCards.add(
                    StatCard(
                      title: tr('Total Employees'),
                      tooltipMessage: "Detailed statistics and information regarding ${tr('Total Employees')}.",
                      value: '$totalStaffCount Staff',
                      icon: Icons.people,
                      iconColor: Colors.teal,
                      iconBgColor: context.isDarkMode ? Colors.teal.withValues(alpha: 0.2) : const Color(0xFFE6FFFA),
                      trendText: '$activeStaffCount active team members',
                      isPositiveTrend: true,
                    ),
                  );
                }
                if (canViewProjects) {
                  visibleStatCards.add(
                    StatCard(
                      title: tr('Active Projects'),
                      tooltipMessage: "Detailed statistics and information regarding ${tr('Active Projects')}.",
                      value: '$ongoingProjectsCount Ongoing',
                      icon: Icons.task_alt,
                      iconColor: context.warning,
                      iconBgColor: context.warningLight,
                      trendText: '${projectsState.projects.length} total projects',
                      isPositiveTrend: true,
                    ),
                  );
                }

                if (visibleStatCards.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        tr('No dashboard metrics available for your current role permissions.'),
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  );
                }

                final cardCount = visibleStatCards.length;
                int crossAxisCount;
                double childAspectRatio;
                if (width >= 1400) {
                  crossAxisCount = min(cardCount, 6);
                  childAspectRatio = 1.1;
                } else if (width >= 900) {
                  crossAxisCount = min(cardCount, 3);
                  childAspectRatio = 1.15;
                } else if (width >= 600) {
                  crossAxisCount = min(cardCount, 2);
                  childAspectRatio = 1.25;
                } else {
                  crossAxisCount = width < 360 ? 1 : min(cardCount, 2);
                  childAspectRatio = width < 360 ? 2.2 : 0.95;
                }
                if (crossAxisCount < 1) crossAxisCount = 1;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  children: visibleStatCards,
                );
              },
            ),
            const SizedBox(height: 24),

            // Two-column layout with permissions filtering
            Builder(
              builder: (context) {
                final List<Widget> mobileWidgets = [];
                if (canViewFinance) {
                  if (mobileWidgets.isNotEmpty) mobileWidgets.add(const SizedBox(height: 24));
                  mobileWidgets.add(_buildTransactions(context, recentTransactions, ref));
                }
                if (canViewProjects) {
                  if (mobileWidgets.isNotEmpty) mobileWidgets.add(const SizedBox(height: 24));
                  mobileWidgets.add(_buildUpcomingTasks(context, displayTasks, ref));
                }
                if (canViewAdministration) {
                  if (mobileWidgets.isNotEmpty) mobileWidgets.add(const SizedBox(height: 24));
                  mobileWidgets.add(_buildRecentActivities(context, recentActivities));
                }
                if (canViewInventory) {
                  if (mobileWidgets.isNotEmpty) mobileWidgets.add(const SizedBox(height: 24));
                  mobileWidgets.add(_buildLowStockAlerts(context, displayAlerts));
                }

                final List<Widget> leftColumnWidgets = [];
                if (canViewFinance) {
                  leftColumnWidgets.add(_buildTransactions(context, recentTransactions, ref));
                }
                if (canViewAdministration) {
                  if (leftColumnWidgets.isNotEmpty) leftColumnWidgets.add(const SizedBox(height: 24));
                  leftColumnWidgets.add(_buildRecentActivities(context, recentActivities));
                }

                final List<Widget> rightColumnWidgets = [];
                if (canViewProjects) {
                  rightColumnWidgets.add(_buildUpcomingTasks(context, displayTasks, ref));
                }
                if (canViewInventory) {
                  if (rightColumnWidgets.isNotEmpty) rightColumnWidgets.add(const SizedBox(height: 24));
                  rightColumnWidgets.add(_buildLowStockAlerts(context, displayAlerts));
                }

                if (mobileWidgets.isEmpty && leftColumnWidgets.isEmpty && rightColumnWidgets.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ResponsiveBuilder(
                  mobile: Column(children: mobileWidgets),
                  desktop: (leftColumnWidgets.isNotEmpty && rightColumnWidgets.isNotEmpty)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(children: leftColumnWidgets),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(children: rightColumnWidgets),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: leftColumnWidgets.isNotEmpty
                                    ? leftColumnWidgets
                                    : rightColumnWidgets,
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
    );
  }

  // Helper: Transactions Section
  Widget _buildTransactions(BuildContext context, List<_TransactionItem> transactions, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return GlassCard(
      title: 'Recent Transactions',
      padding: EdgeInsets.zero,
      child: transactions.isEmpty
          ? Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No recent transactions found.',
                style: TextStyle(color: context.textSecondary),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = max(constraints.maxWidth, 680.0);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FlexColumnWidth(3.0), // Details with icon & subtext
                        1: FlexColumnWidth(1.6), // Type / Category pill badge
                        2: FlexColumnWidth(1.8), // Amount formatted nicely
                        3: FixedColumnWidth(140), // Date (dedicated width)
                      },
                      children: [
                        // Table Header
                        TableRow(
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade50,
                            border: Border(bottom: BorderSide(color: context.divider)),
                          ),
                          children: [
                            _buildTableHeaderCell(context, 'Details'),
                            _buildTableHeaderCell(context, tr('Type')),
                            _buildTableHeaderCell(context, 'Amount'),
                            _buildTableHeaderCell(context, tr('Date')),
                          ],
                        ),
                        // Table Body
                        ...transactions.map((tx) {
                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: context.divider.withValues(alpha: 0.6))),
                            ),
                            children: [
                              // 0. Details with Inflow/Outflow Icon & Subtitle
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: tx.isIncome
                                            ? context.success.withValues(alpha: 0.12)
                                            : context.error.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        tx.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        size: 16,
                                        color: tx.isIncome ? context.success : context.error,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            tx.details,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tx.isIncome ? 'Inflow Receipt' : 'Outflow Expense',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 1. Type / Category Pill
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tx.isIncome
                                          ? context.success.withValues(alpha: 0.08)
                                          : context.primaryColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: tx.isIncome
                                            ? context.success.withValues(alpha: 0.25)
                                            : context.primaryColor.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tx.type,
                                      style: TextStyle(
                                        color: tx.isIncome ? context.success : context.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              // 2. Amount
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  _formatCurrency(tx.amount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: tx.isIncome ? context.success : context.error,
                                  ),
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // 3. Date
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 13, color: context.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(tx.date),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: context.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTableHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: context.textSecondary,
              letterSpacing: 0.3,
            ),
      ),
    );
  }

  // Helper: Activities Section
  Widget _buildRecentActivities(BuildContext context, List<_ActivityItem> activities) {
    final theme = Theme.of(context);

    return GlassCard(
      title: 'Recent Activities',
      child: activities.isEmpty
          ? Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'No recent activities recorded.',
                style: TextStyle(color: context.textSecondary),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final act = activities[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: act.color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(act.icon, size: 18, color: act.color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.content,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            act.timestamp,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // Helper: Upcoming Tasks Section
  Widget _buildUpcomingTasks(BuildContext context, List<_TaskItem> tasks, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return GlassCard(
      title: 'Upcoming Tasks',
      child: tasks.isEmpty
          ? Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text(
                'All tasks completed!',
                style: TextStyle(color: context.textSecondary),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(tasksProvider.notifier).updateTask(
                                  task.rawTask.copyWith(
                                    status: val ? 'Done' : 'In Progress',
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task "${task.name}" marked as ${val ? tr("completed") : tr("in progress")}.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        activeColor: context.primaryColor,
                        side: BorderSide(color: context.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? context.textMuted : context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_month, size: 12, color: context.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(task.dueDate),
                                      style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_outline, size: 12, color: context.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.assignee,
                                      style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Helper: Low Stock Alerts Section
  Widget _buildLowStockAlerts(BuildContext context, List<_StockAlertItem> alerts) {
    final theme = Theme.of(context);

    return GlassCard(
      title: 'Low Stock & Asset Alerts',
      child: Column(
        children: [
          alerts.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'No stock or asset alerts. All systems operational.',
                    style: TextStyle(color: context.textSecondary),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: alert.bgHex,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: alert.colorHex.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: alert.colorHex, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.assetName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      alert.currentStatus,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: alert.colorHex,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '•  ${alert.recommendation}',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: context.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// Data Classes
class _TransactionItem {
  final String details;
  final String type;
  final double amount;
  final String date;
  final bool isIncome;

  _TransactionItem(this.details, this.type, this.amount, this.date, this.isIncome);
}

class _ActivityItem {
  final String content;
  final String timestamp;
  final IconData icon;
  final Color color;

  _ActivityItem(this.content, this.timestamp, this.icon, this.color);
}

class _TaskItem {
  final String name;
  final String dueDate;
  final String assignee;
  final bool isCompleted;
  final ProjectTask rawTask;

  _TaskItem(this.name, this.dueDate, this.assignee, this.isCompleted, this.rawTask);
}

class _StockAlertItem {
  final String assetName;
  final String currentStatus;
  final String recommendation;
  final Color colorHex;
  final Color bgHex;

  _StockAlertItem(this.assetName, this.currentStatus, this.recommendation, this.colorHex, this.bgHex);
}
