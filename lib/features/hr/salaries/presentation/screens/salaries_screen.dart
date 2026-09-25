import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import '../providers/salaries_provider.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../advances/presentation/providers/advances_provider.dart';
import '../../domain/entities/salary_record.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class SalariesScreen extends ConsumerWidget {
  const SalariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salariesProvider);
    final theme = Theme.of(context);

    final totalPaid = state.totalPayoutsThisMonth;
    final totalPayslips = state.filteredSalaries.length;

    final nowMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final payrollTitle = state.salaries.isNotEmpty
        ? '${state.salaries.first.payPeriod} Payroll'
        : '$nowMonth Payroll';

    // Dynamic Pay Period filter list based on actual salary records
    final List<String> availablePeriods = ['All'];
    for (final s in state.salaries) {
      if (!availablePeriods.contains(s.payPeriod)) {
        availablePeriods.add(s.payPeriod);
      }
    }
    if (!availablePeriods.contains(nowMonth)) {
      availablePeriods.add(nowMonth);
    }

    final selectedFilter = availablePeriods.contains(state.periodFilter)
        ? state.periodFilter
        : 'All';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.salaries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const HrSubNav(activeRoute: '/hr/salaries'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Title + Add Button Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      final titleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payroll & Salaries',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Process monthly payroll, track allowances, deductions, and print payslips.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );

                      final canCreate = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.create);
                      final actionButton = canCreate
                          ? ElevatedButton.icon(
                              onPressed: () async {
                                final employees = ref.read(employeesProvider).employees;
                                if (employees.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Add employees in the Directory first before processing payroll.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.error,
                                    ),
                                  );
                                  return;
                                }

                                final result = await showDialog<SalaryRecord>(
                                  context: context,
                                  builder: (context) => const _ProcessPayrollDialog(),
                                );
                                if (result != null) {
                                  ref.read(salariesProvider.notifier).addSalary(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Payroll processed for ${result.employeeName}.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Process Payroll'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            )
                          : null;

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            if (actionButton != null) ...[
                              const SizedBox(height: 14),
                              actionButton,
                            ],
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: titleWidget),
                          if (actionButton != null) ...[
                            const SizedBox(width: 16),
                            actionButton,
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Row(
                          children: [
                            Expanded(
                              child: ExplainTooltip(
                                message: 'Monthly Payroll: Total amount paid out to employees for the current payroll month.',
                                child: StatCard(
                                  title: payrollTitle,
                                  tooltipMessage: 'Detailed statistics and information regarding $payrollTitle.',
                                  value: 'Rs. ${totalPaid.toStringAsFixed(0)}',
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                  trendText: 'Paid this month',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ExplainTooltip(
                                message: 'Total Payslips: Total number of payslips generated and logged in the system.',
                                child: StatCard(
                                  title: 'Total Payslips',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Payslips.',
                                  value: totalPayslips.toString(),
                                  icon: Icons.receipt_long_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                  trendText: 'Issued logs',
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ExplainTooltip(
                              message: 'Monthly Payroll: Total amount paid out to employees for the current payroll month.',
                              child: StatCard(
                                title: payrollTitle,
                                tooltipMessage: 'Detailed statistics and information regarding $payrollTitle.',
                                value: 'Rs. ${totalPaid.toStringAsFixed(0)}',
                                icon: Icons.check_circle_outline,
                                iconColor: context.success,
                                iconBgColor: context.successLight,
                                trendText: 'Paid this month',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ExplainTooltip(
                              message: 'Total Payslips: Total number of payslips generated and logged in the system.',
                              child: StatCard(
                                title: 'Total Payslips',
                                tooltipMessage: 'Detailed statistics and information regarding Total Payslips.',
                                value: totalPayslips.toString(),
                                icon: Icons.receipt_long_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                                trendText: 'Issued logs',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Payroll History List
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = constraints.maxWidth < 500;
                              final title = Text(
                                'Issued Payslips Log',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              );

                              final filterDropdown = SizedBox(
                                width: isSmall ? double.infinity : 180,
                                child: DropdownButtonFormField<String>(
                                  value: selectedFilter,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    filled: true,
                                    fillColor: context.scaffoldBg,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: context.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: context.border),
                                    ),
                                  ),
                                  items: availablePeriods.map((period) {
                                    return DropdownMenuItem(
                                      value: period,
                                      child: Text(period == 'All' ? 'All Pay Periods' : period),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(salariesProvider.notifier).setPeriodFilter(val);
                                    }
                                  },
                                ),
                              );

                              if (isSmall) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    title,
                                    const SizedBox(height: 12),
                                    filterDropdown,
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  title,
                                  filterDropdown,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Table of payouts
                          state.filteredSalaries.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'No payslip records found.',
                                      style: TextStyle(color: context.textSecondary),
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isMobile = constraints.maxWidth < 680;
                                    if (isMobile) {
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: state.filteredSalaries.length,
                                        separatorBuilder: (context, index) => Divider(
                                          height: 1,
                                          color: context.border.withValues(alpha: 0.35),
                                        ),
                                        itemBuilder: (context, index) {
                                          final record = state.filteredSalaries[index];
                                          return _SalaryRow(record: record, isMobile: true);
                                        },
                                      );
                                    }

                                    final double tableWidth = constraints.maxWidth < 850 ? 850 : constraints.maxWidth;
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: tableWidth,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildTableHeader(context),
                                            const SizedBox(height: 6),
                                            ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: state.filteredSalaries.length,
                                              separatorBuilder: (context, index) => Divider(
                                                height: 1,
                                                color: context.border.withValues(alpha: 0.35),
                                              ),
                                              itemBuilder: (context, index) {
                                                final record = state.filteredSalaries[index];
                                                return _SalaryRow(record: record, isMobile: false);
                                              },
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: context.textSecondary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.scaffoldBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'EMPLOYEE / PERIOD',
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'BASE SALARY',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ALLOWANCE',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DEDUCTIONS',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'NET PAY',
              textAlign: TextAlign.right,
              style: headerStyle,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.center,
              style: headerStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryRow extends ConsumerWidget {
  final SalaryRecord record;
  final bool isMobile;

  const _SalaryRow({required this.record, this.isMobile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canEdit = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit);
    final canDelete = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.delete);

    Widget buildMenu() {
      if (!canEdit && !canDelete) return const SizedBox.shrink();
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
        color: context.cardBg,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onSelected: (val) async {
          if (val == 'print') {
            _showPayslipPreview(context, ref, record);
          } else if (val == 'delete') {
            if (!canDelete) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Payslip'),
                content: Text('Are you sure you want to delete payslip log for "${record.employeeName}"? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Delete', style: TextStyle(color: context.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(salariesProvider.notifier).deleteSalary(record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payslip for "${record.employeeName}" deleted.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: context.error,
                  ),
                );
              }
            }
          } else if (val == 'edit') {
            if (!canEdit) return;
            showDialog(
              context: context,
              builder: (context) => _EditPayrollDialog(record: record),
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'print',
            child: Row(
              children: [
                Icon(Icons.print_outlined, size: 16, color: context.primaryColor),
                const SizedBox(width: 8),
                Text('Print Payslip', style: TextStyle(color: context.textPrimary, fontSize: 13)),
              ],
            ),
          ),
          if (canEdit)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Text('Edit Payslip', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          if (canDelete)
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: context.error),
                  const SizedBox(width: 8),
                  Text('Delete Log', style: TextStyle(color: context.error, fontSize: 13)),
                ],
              ),
            ),
        ],
      );
    }

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Period: ${record.payPeriod} • ${record.paymentDate}',
                        style: TextStyle(color: context.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${NumberFormat('#,##0').format(record.netPaid)}',
                      style: TextStyle(
                        color: context.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildPaymentMethodBadge(record.paymentMethod, context),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.print_outlined, size: 19, color: context.primaryColor),
                  tooltip: 'Print Payslip',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showPayslipPreview(context, ref, record),
                ),
                const SizedBox(width: 2),
                buildMenu(),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.scaffoldBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Base: Rs. ${NumberFormat('#,##0').format(record.baseSalary)}',
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                  Text(
                    'Allowance: +Rs. ${NumberFormat('#,##0').format(record.allowances)}',
                    style: TextStyle(
                      color: record.allowances > 0 ? context.success : context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Deductions: -Rs. ${NumberFormat('#,##0').format(record.deductions)}',
                    style: TextStyle(
                      color: record.deductions > 0 ? context.error : context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _showPayslipPreview(context, ref, record),
        hoverColor: context.primaryColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Column 1: Employee Name & Period (flex: 3)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Period: ${record.payPeriod} | Paid on ${record.paymentDate}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Column 2: Base Salary (flex: 2, right-aligned)
              Expanded(
                flex: 2,
                child: Text(
                  'Rs. ${NumberFormat('#,##0').format(record.baseSalary)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              // Column 3: Allowances (flex: 2, right-aligned)
              Expanded(
                flex: 2,
                child: Text(
                  record.allowances > 0
                      ? '+Rs. ${NumberFormat('#,##0').format(record.allowances)}'
                      : 'Rs. 0',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: record.allowances > 0 ? context.success : context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              // Column 4: Deductions (flex: 2, right-aligned)
              Expanded(
                flex: 2,
                child: Text(
                  record.deductions > 0
                      ? '-Rs. ${NumberFormat('#,##0').format(record.deductions)}'
                      : 'Rs. 0',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: record.deductions > 0 ? context.error : context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),

              // Column 5: Net Pay & Payment Method (flex: 2, right-aligned)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rs. ${NumberFormat('#,##0').format(record.netPaid)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: context.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildPaymentMethodBadge(record.paymentMethod, context),
                  ],
                ),
              ),

              // Column 6: Actions (fixed 80, centered)
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.print_outlined, size: 19, color: context.primaryColor),
                      tooltip: 'Print Payslip',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => _showPayslipPreview(context, ref, record),
                    ),
                    const SizedBox(width: 4),
                    buildMenu(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildPaymentMethodBadge(String method, BuildContext context) {
  Color fgColor;
  Color bgColor;
  IconData icon;
  final m = method.toLowerCase();

  if (m.contains('cash')) {
    fgColor = Colors.green.shade700;
    bgColor = Colors.green.withValues(alpha: 0.12);
    icon = Icons.payments_outlined;
  } else if (m.contains('cheque') || m.contains('chick')) {
    fgColor = Colors.purple.shade700;
    bgColor = Colors.purple.withValues(alpha: 0.12);
    icon = Icons.receipt_long_outlined;
  } else {
    fgColor = Colors.blue.shade700;
    bgColor = Colors.blue.withValues(alpha: 0.12);
    icon = Icons.account_balance_outlined;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 0.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fgColor),
        const SizedBox(width: 4),
        Text(
          method,
          style: TextStyle(
            color: fgColor,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

void _showPayslipPreview(BuildContext context, WidgetRef ref, SalaryRecord record) {
  showDialog(
    context: context,
    builder: (context) => _PayslipPreviewDialog(record: record),
  );
}

class _PayslipPreviewDialog extends ConsumerStatefulWidget {
  final SalaryRecord record;
  const _PayslipPreviewDialog({required this.record});

  @override
  ConsumerState<_PayslipPreviewDialog> createState() => _PayslipPreviewDialogState();
}

class _PayslipPreviewDialogState extends ConsumerState<_PayslipPreviewDialog> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = widget.record;
    final employees = ref.watch(employeesProvider).employees;
    final emp = employees.where((e) => e.id == record.employeeId).firstOrNull;

    final grossEarnings = record.baseSalary + record.allowances;

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long_rounded, color: context.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Payslip',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'Pay Period: ${record.payPeriod}',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: context.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 12),

              // Employee Details & Payment Method Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.employeeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${emp?.designation ?? "Employee"} • ${emp?.department ?? "Operations"}',
                              style: TextStyle(fontSize: 11, color: context.textSecondary),
                            ),
                          ],
                        ),
                        _buildPaymentMethodBadge(record.paymentMethod, context),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('Disbursed Date', record.paymentDate, context),
                        _buildInfoColumn('Slip Ref', 'PAY-${record.id.replaceAll('sal_', '')}', context),
                        _buildInfoColumn('Account', record.accountName.isNotEmpty ? record.accountName : 'Company Account', context),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Earnings & Deductions Tables
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Earnings Column
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.add_circle_outline, size: 14, color: Colors.blue),
                              SizedBox(width: 6),
                              Text('EARNINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildAmountRow('Base Salary', record.baseSalary, context),
                          const SizedBox(height: 4),
                          _buildAmountRow('Allowances', record.allowances, context, isAdd: true),
                          const Divider(height: 12),
                          _buildAmountRow('Gross Earnings', grossEarnings, context, isBold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Deductions Column
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.remove_circle_outline, size: 14, color: context.error),
                              const SizedBox(width: 6),
                              Text('DEDUCTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.error)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildAmountRow('Deductions', record.deductions, context, isSub: true),
                          const Divider(height: 12),
                          _buildAmountRow('Total Deductions', record.deductions, context, isBold: true, isError: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Net Take-Home Pay Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NET TAKE-HOME PAY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.success,
                          ),
                        ),
                        Text(
                          'Status: ${record.status.toUpperCase()} • Paid via ${record.paymentMethod}',
                          style: TextStyle(fontSize: 10, color: context.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      'Rs. ${record.netPaid.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.success,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: context.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingPdf
                        ? null
                        : () async {
                            setState(() => _isGeneratingPdf = true);
                            try {
                              final filePath = await ExportHelper.generatePayslipPdf(
                                record: record,
                                employee: emp,
                              );
                              await ExportHelper.openFile(filePath);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Payslip for "${record.employeeName}" opened for printing.'),
                                    backgroundColor: context.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: context.error),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isGeneratingPdf = false);
                            }
                          },
                    icon: _isGeneratingPdf
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.print, size: 18),
                    label: Text(_isGeneratingPdf ? 'Generating...' : 'Print / Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.textPrimary)),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, BuildContext context, {bool isAdd = false, bool isSub = false, bool isBold = false, bool isError = false}) {
    String prefix = '';
    if (isAdd && amount > 0) prefix = '+';
    if (isSub && amount > 0) prefix = '-';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? context.textPrimary : context.textSecondary,
          ),
        ),
        Text(
          '$prefix Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isError
                ? context.error
                : (isAdd ? context.success : (isBold ? context.textPrimary : context.textPrimary)),
          ),
        ),
      ],
    );
  }
}

class _ProcessPayrollDialog extends ConsumerStatefulWidget {
  const _ProcessPayrollDialog();

  @override
  ConsumerState<_ProcessPayrollDialog> createState() => _ProcessPayrollDialogState();
}

class _ProcessPayrollDialogState extends ConsumerState<_ProcessPayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  String? _selectedAccountId;
  String? _selectedAccountName;
  late List<String> _payPeriodOptions;
  late String _payPeriod;
  double _baseSalary = 0.0;
  String _paymentMethod = 'Bank Transfer';

  final _allowancesController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  
  // Salary advance details
  double _advanceDeduction = 0.0;
  bool _hasActiveAdvance = false;

  // Attendance details for pay period
  bool _isLoadingAttendance = false;
  int _attPresent = 0;
  int _attAbsent = 0;
  int _attLeave = 0;
  int _attHalfDay = 0;
  int _attLate = 0;
  double _calculatedAbsentDeduction = 0.0;
  bool _appliedAbsentDeduction = false;

  Future<void> _fetchAttendanceForPeriod() async {
    if (_selectedEmployeeId == null) return;
    setState(() => _isLoadingAttendance = true);

    try {
      final parts = _payPeriod.split(' ');
      if (parts.length >= 2) {
        final monthName = parts[0];
        final year = parts[1];
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthIdx = monthNames.indexOf(monthName) + 1;
        if (monthIdx > 0) {
          final yearMonth = '$year-${monthIdx.toString().padLeft(2, '0')}';
          final repo = ref.read(attendanceRepositoryProvider);
          final logs = await repo.getAttendanceForMonth(yearMonth);
          final empLogs = logs.where((l) => l.employeeId == _selectedEmployeeId).toList();
          final settings = ref.read(attendanceSettingsProvider).value;
          final workStart = settings?.workStartMinutes ?? 540;
          final grace = settings?.graceMinutes ?? 15;

          final present = empLogs.where((l) => l.status == AttendanceStatus.present).length;
          final absent = empLogs.where((l) => l.status == AttendanceStatus.absent).length;
          final leave = empLogs.where((l) => l.status == AttendanceStatus.leave).length;
          final halfDay = empLogs.where((l) => l.status == AttendanceStatus.halfDay).length;
          final lateCount = empLogs.where((l) => l.status == AttendanceStatus.present && l.isLate(workStartMinutes: workStart, graceMinutes: grace)).length;

          final workingDays = empLogs.where((l) => l.status != AttendanceStatus.off && l.status != AttendanceStatus.holiday).length;
          final effectiveDays = workingDays > 0 ? workingDays : 26;
          final perDaySalary = _baseSalary / effectiveDays;
          final absentDeduction = (absent * perDaySalary) + (halfDay * 0.5 * perDaySalary);

          if (mounted) {
            setState(() {
              _attPresent = present;
              _attAbsent = absent;
              _attLeave = leave;
              _attHalfDay = halfDay;
              _attLate = lateCount;
              _calculatedAbsentDeduction = absentDeduction;
              _appliedAbsentDeduction = false;
              _isLoadingAttendance = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingAttendance = false);
    }
  }

  Widget _buildAttendancePill(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payPeriodOptions = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      final monthName = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1];
      return '$monthName ${d.year}';
    });
    _payPeriod = _payPeriodOptions.first;
  }

  @override
  void dispose() {
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  double get netSalary {
    final allowances = double.tryParse(_allowancesController.text) ?? 0.0;
    final otherDeductions = double.tryParse(_deductionsController.text) ?? 0.0;
    return _baseSalary + allowances - (otherDeductions + _advanceDeduction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canCreate = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.create);
    
    // Fetch active employees & accounts
    final employees = ref.watch(employeesProvider).employees.where((e) => e.status == 'Active').toList();
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Process Payroll Slip',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Pay Period
                _buildLabel('Pay Period'),
                DropdownButtonFormField<String>(
                  value: _payPeriod,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: _payPeriodOptions.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _payPeriod = val);
                      _fetchAttendanceForPeriod();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Employee Select
                _buildLabel('Select Employee'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedEmployeeId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Choose employee'),
                  validator: (val) => val == null ? 'Please select employee' : null,
                  items: employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp.id,
                      child: Text(emp.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final emp = employees.firstWhere((e) => e.id == val);
                      
                      // INTEGRATION: Check for active salary advances for this employee
                      final activeAdvances = ref.read(advancesProvider).advances
                          .where((adv) => adv.employeeId == val && adv.status == 'Approved')
                          .toList();
                      
                      double deductionVal = 0.0;
                      bool activeAdv = false;
                      if (activeAdvances.isNotEmpty) {
                        deductionVal = activeAdvances.first.monthlyDeduction;
                        activeAdv = true;
                      }

                      setState(() {
                        _selectedEmployeeId = val;
                        _selectedEmployeeName = emp.name;
                        _baseSalary = emp.baseSalary;
                        final validMethods = ['Bank Transfer', 'Cash', 'Cheque'];
                        _paymentMethod = validMethods.contains(emp.paymentMethod) ? emp.paymentMethod : 'Bank Transfer';
                        _advanceDeduction = deductionVal;
                        _hasActiveAdvance = activeAdv;
                      });
                      _fetchAttendanceForPeriod();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Payment Method (Required)
                _buildLabel('Payment Method', isRequired: true),
                DropdownButtonFormField<String>(
                  value: ['Bank Transfer', 'Cash', 'Cheque'].contains(_paymentMethod) ? _paymentMethod : 'Bank Transfer',
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Select Payment Method'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_outlined, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Bank Transfer'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Cash',
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Cash'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Cheque',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Cheque'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _paymentMethod = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Payment Account Select (Required)
                _buildLabel('Payment Account', isRequired: true),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedAccountId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Select Company/Personal Account'),
                  validator: (val) => val == null ? 'Please select payment account' : null,
                  items: accounts.map((acc) {
                    final scopeLabel = acc.accountScope.isNotEmpty ? ' (${acc.accountScope})' : '';
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text('${acc.name}$scopeLabel • Rs. ${acc.balance.toStringAsFixed(0)}', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final acc = accounts.firstWhere((a) => a.id == val);
                      setState(() {
                        _selectedAccountId = val;
                        _selectedAccountName = acc.name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                if (_hasActiveAdvance) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.warningLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: context.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active advance detected. Monthly installment of Rs. ${_advanceDeduction.toStringAsFixed(0)} will be auto-deducted.',
                            style: TextStyle(color: context.warning, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Base Salary Display
                _buildLabel('Base Salary (Rs. / month)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'Rs. ${_baseSalary.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Attendance Summary & Suggested Absent Deductions
                if (_selectedEmployeeId != null) ...[
                  _buildLabel('Attendance Record & Deductions ($_payPeriod)'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Monthly Attendance Overview',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                            if (_isLoadingAttendance)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildAttendancePill('Present: $_attPresent', context.success, context.successLight),
                            _buildAttendancePill('Half Day: $_attHalfDay', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                            _buildAttendancePill('Leave: $_attLeave', context.warning, context.warningLight),
                            _buildAttendancePill('Absent: $_attAbsent', context.error, context.errorLight),
                            if (_attLate > 0)
                              _buildAttendancePill('Late: $_attLate', Colors.deepOrange, Colors.deepOrange.withValues(alpha: 0.12)),
                          ],
                        ),
                        if (_calculatedAbsentDeduction > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Suggested Absent Deduction: Rs. ${_calculatedAbsentDeduction.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: context.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _appliedAbsentDeduction
                                    ? null
                                    : () {
                                        final curDeductions = double.tryParse(_deductionsController.text) ?? 0.0;
                                        setState(() {
                                          _appliedAbsentDeduction = true;
                                          _deductionsController.text = (curDeductions + _calculatedAbsentDeduction).toStringAsFixed(0);
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _appliedAbsentDeduction ? 'Applied' : 'Apply Deduction',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Allowances & Other Deductions Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Allowances (+)'),
                          TextFormField(
                            controller: _allowancesController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 100'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Other Deductions (-)'),
                          TextFormField(
                            controller: _deductionsController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 50'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Final Net Salary Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Calculated Pay:',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs. ${netSalary.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                      child: const Text('Cancel'),
                    ),
                    if (canCreate) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _selectedEmployeeId != null && _selectedAccountId != null) {
                            final slip = SalaryRecord(
                              id: 'sal_${DateTime.now().millisecondsSinceEpoch}',
                              employeeId: _selectedEmployeeId!,
                              employeeName: _selectedEmployeeName!,
                              payPeriod: _payPeriod,
                              baseSalary: _baseSalary,
                              allowances: double.tryParse(_allowancesController.text) ?? 0.0,
                              deductions: (double.tryParse(_deductionsController.text) ?? 0.0) + _advanceDeduction,
                              netPaid: netSalary,
                              paymentDate: DateTime.now().toIso8601String().substring(0, 10),
                              status: 'Paid',
                              paymentMethod: _paymentMethod,
                              accountId: _selectedAccountId!,
                              accountName: _selectedAccountName!,
                            );
                            Navigator.of(context).pop(slip);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Pay Out & Log'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: context.textSecondary,
              ),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}

class _EditPayrollDialog extends ConsumerStatefulWidget {
  final SalaryRecord record;
  const _EditPayrollDialog({required this.record});

  @override
  ConsumerState<_EditPayrollDialog> createState() => _EditPayrollDialogState();
}

class _EditPayrollDialogState extends ConsumerState<_EditPayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _payPeriod;
  late double _baseSalary;
  late String _paymentMethod;
  late final TextEditingController _allowancesController;
  late final TextEditingController _deductionsController;
  late final List<String> _payPeriodOptions;

  @override
  void initState() {
    super.initState();
    _payPeriod = widget.record.payPeriod;
    _baseSalary = widget.record.baseSalary;
    _paymentMethod = widget.record.paymentMethod;
    _allowancesController = TextEditingController(text: widget.record.allowances.toStringAsFixed(0));
    _deductionsController = TextEditingController(text: widget.record.deductions.toStringAsFixed(0));

    final now = DateTime.now();
    final dynamicPeriods = List.generate(24, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMMM yyyy').format(d);
    });
    if (!dynamicPeriods.contains(_payPeriod) && _payPeriod.isNotEmpty) {
      dynamicPeriods.insert(0, _payPeriod);
    }
    _payPeriodOptions = dynamicPeriods;
  }

  @override
  void dispose() {
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  double get netSalary {
    final allowances = double.tryParse(_allowancesController.text) ?? 0.0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0.0;
    return _baseSalary + allowances - deductions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Payroll Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'Employee: ${widget.record.employeeName}',
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Pay Period
                _buildLabel('Pay Period'),
                DropdownButtonFormField<String>(
                  value: _payPeriod,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: _payPeriodOptions.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _payPeriod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Base Salary Display
                _buildLabel('Base Salary (Rs. / month)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'Rs. ${_baseSalary.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Allowances & Other Deductions Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Allowances (+)'),
                          TextFormField(
                            controller: _allowancesController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 100'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Deductions (-)'),
                          TextFormField(
                            controller: _deductionsController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 50'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Method
                _buildLabel('Payment Method'),
                DropdownButtonFormField<String>(
                  value: ['Bank Transfer', 'Cash', 'Cheque'].contains(_paymentMethod) ? _paymentMethod : 'Bank Transfer',
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: const [
                    DropdownMenuItem(
                      value: 'Bank Transfer',
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_outlined, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Bank Transfer'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Cash',
                      child: Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Cash'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Cheque',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('Cheque'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 20),

                // Final Net Salary Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Calculated Pay:',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs. ${netSalary.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                      child: const Text('Cancel'),
                    ),
                    if (ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit)) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final updated = widget.record.copyWith(
                              payPeriod: _payPeriod,
                              allowances: double.tryParse(_allowancesController.text) ?? 0.0,
                              deductions: double.tryParse(_deductionsController.text) ?? 0.0,
                              netPaid: netSalary,
                              paymentMethod: _paymentMethod,
                            );
                            ref.read(salariesProvider.notifier).updateSalary(updated);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payroll details updated successfully.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}
