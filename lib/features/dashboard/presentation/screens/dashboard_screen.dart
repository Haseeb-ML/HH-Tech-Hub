import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/responsive_builder.dart';

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

    // Responsive columns for stat cards
    int crossAxisCount;
    if (width >= 1400) {
      crossAxisCount = 6;
    } else if (width >= 900) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    // Dynamic Lists processing
    // 1. Transactions
    final allTransactions = [
      ...incomesState.incomes.map((inc) => _TransactionItem(
            inc.description.isNotEmpty ? inc.description : 'Income from ${inc.clientName}',
            'Revenue',
            inc.amount,
            inc.date,
            true,
          )),
      ...companyExpenses.map((exp) => _TransactionItem(
            exp.description.isNotEmpty ? exp.description : 'Expense to ${exp.vendorName}',
            exp.category,
            exp.amount,
            exp.date,
            false,
          )),
    ];
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    final recentTransactions = allTransactions.take(4).toList();

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
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
                        child: Image.asset(
                          'assets/logo.png',
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
                              tr('Welcome back, Admin'),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Here is a quick overview of Software House performance today.'),
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
                  onPressed: () {
                    // Triggers hot reload/refresh notification
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: context.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        content: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              tr('Dashboard statistics updated.'),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
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
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              children: [
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
              ],
            ),
            const SizedBox(height: 24),
  
            // Two-column layout
            ResponsiveBuilder(
              mobile: Column(
                children: [
                  _buildTransactions(context, recentTransactions, ref),
                  const SizedBox(height: 24),
                  _buildUpcomingTasks(context, displayTasks, ref),
                  const SizedBox(height: 24),
                  _buildRecentActivities(context, recentActivities),
                  const SizedBox(height: 24),
                  _buildLowStockAlerts(context, displayAlerts),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Transactions & Activities
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildTransactions(context, recentTransactions, ref),
                        const SizedBox(height: 24),
                        _buildRecentActivities(context, recentActivities),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Tasks & Alerts
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildUpcomingTasks(context, displayTasks, ref),
                        const SizedBox(height: 24),
                        _buildLowStockAlerts(context, displayAlerts),
                      ],
                    ),
                  ),
                ],
              ),
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
          : Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
              },
              children: [
                // Table Header
                TableRow(
                  decoration: BoxDecoration(
                    color: context.divider,
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
                      border: Border(bottom: BorderSide(color: context.divider)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          tx.details,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          tx.type,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          '${tx.isIncome ? '+' : ''}${_formatCurrency(tx.amount)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: tx.isIncome ? context.success : context.error,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Text(
                          _formatDate(tx.date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.textMuted,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildTableHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
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
                            Row(
                              children: [
                                Icon(Icons.calendar_month, size: 12, color: context.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: theme.textTheme.labelMedium?.copyWith(color: context.textSecondary),
                                ),
                                const SizedBox(width: 12),
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
