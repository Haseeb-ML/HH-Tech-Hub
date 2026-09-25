import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import '../providers/advances_provider.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../domain/entities/advance_record.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(advancesProvider);
    final theme = Theme.of(context);

    // Separate pending requests from approved/other list
    final pendingRequests = state.advances.where((adv) => adv.status == 'Pending').toList();
    final nonPendingRecords = state.filteredAdvances.where((adv) => adv.status != 'Pending').toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.advances.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const HrSubNav(activeRoute: '/hr/advances'),
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
                            'Salary Advances',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track employee advance requests, repayments, and automatic monthly payroll deductions.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );

                      final canCreate = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.create);
                      final actionBtn = canCreate
                          ? ElevatedButton.icon(
                              onPressed: () async {
                                final employees = ref.read(employeesProvider).employees;
                                if (employees.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Add employees in the Directory first before requesting advances.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.error,
                                    ),
                                  );
                                  return;
                                }

                                final result = await showDialog<AdvanceRecord>(
                                  context: context,
                                  builder: (context) => const _RequestAdvanceDialog(),
                                );
                                if (result != null) {
                                  ref.read(advancesProvider.notifier).addAdvance(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Salary advance requested for ${result.employeeName}.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Request Advance'),
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
                            if (actionBtn != null) ...[
                              const SizedBox(height: 14),
                              actionBtn,
                            ],
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: titleWidget),
                          if (actionBtn != null) ...[
                            const SizedBox(width: 16),
                            actionBtn,
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Stats row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      final cardWidgets = [
                        StatCard(
                          title: 'Approved Advances',
                          tooltipMessage: 'Detailed statistics and information regarding Approved Advances.',
                          value: 'Rs. ${state.totalApprovedAmount.toStringAsFixed(0)}',
                          icon: Icons.assignment_turned_in_outlined,
                          iconColor: context.success,
                          iconBgColor: context.successLight,
                          trendText: 'Lifetime approved',
                        ),
                        StatCard(
                          title: 'Remaining Balance',
                          tooltipMessage: 'Detailed statistics and information regarding Remaining Balance.',
                          value: 'Rs. ${state.remainingRepaymentAmount.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: context.primaryColor,
                          iconBgColor: context.infoLight,
                          trendText: 'Active outstanding',
                        ),
                        StatCard(
                          title: 'Pending Requests',
                          tooltipMessage: 'Detailed statistics and information regarding Pending Requests.',
                          value: state.pendingApprovalsCount.toString(),
                          icon: Icons.hourglass_empty,
                          iconColor: context.warning,
                          iconBgColor: context.warningLight,
                          trendText: 'Require decision',
                        ),
                      ];

                      if (isMobile) {
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                          physics: const NeverScrollableScrollPhysics(),
                          children: cardWidgets,
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Approved Advances',
                              tooltipMessage: 'Detailed statistics and information regarding Approved Advances.',
                              value: 'Rs. ${state.totalApprovedAmount.toStringAsFixed(0)}',
                              icon: Icons.assignment_turned_in_outlined,
                              iconColor: context.success,
                              iconBgColor: context.successLight,
                              trendText: 'Lifetime approved',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              title: 'Remaining Balance',
                              tooltipMessage: 'Detailed statistics and information regarding Remaining Balance.',
                              value: 'Rs. ${state.remainingRepaymentAmount.toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: context.primaryColor,
                              iconBgColor: context.infoLight,
                              trendText: 'Active outstanding',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatCard(
                              title: 'Pending Requests',
                              tooltipMessage: 'Detailed statistics and information regarding Pending Requests.',
                              value: state.pendingApprovalsCount.toString(),
                              icon: Icons.hourglass_empty,
                              iconColor: context.warning,
                              iconBgColor: context.warningLight,
                              trendText: 'Require decision',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Pending Requests Area (If any)
                  if (pendingRequests.isNotEmpty) ...[
                    Text(
                      'Pending Approval Requests',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 160,
                      ),
                      itemCount: pendingRequests.length,
                      itemBuilder: (context, index) {
                        final req = pendingRequests[index];
                        return _PendingRequestCard(request: req);
                      },
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Advances Log and Filters
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = constraints.maxWidth < 550;
                              final title = Text(
                                'Advances Log & Repayment Status',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              );

                              final filterDropdown = SizedBox(
                                width: isSmall ? double.infinity : 180,
                                child: DropdownButtonFormField<String>(
                                  value: state.statusFilter,
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
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All Records')),
                                    DropdownMenuItem(value: 'Approved', child: Text('Approved / Active')),
                                    DropdownMenuItem(value: 'Fully Paid', child: Text('Fully Paid')),
                                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(advancesProvider.notifier).setStatusFilter(val);
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
                          const Divider(),
                          const SizedBox(height: 8),

                          // Table of Repayments
                          nonPendingRecords.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'No salary advance records logged under this filter.',
                                      style: TextStyle(color: context.textSecondary),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: nonPendingRecords.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final record = nonPendingRecords[index];
                                    return _AdvanceRow(record: record);
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
}

class _PendingRequestCard extends ConsumerWidget {
  final AdvanceRecord request;

  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit);

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.warning, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: context.warning.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Rs. ${request.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.reason,
            style: TextStyle(color: context.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Requested: ${request.requestDate}',
            style: TextStyle(color: context.textMuted, fontSize: 10),
          ),
          if (canEdit) ...[
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _EditAdvanceDialog(record: request),
                    );
                  },
                  icon: Icon(Icons.edit_outlined, size: 16, color: context.primaryColor),
                  tooltip: 'Edit Request',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => ref.read(advancesProvider.notifier).rejectAdvance(request.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.errorLight,
                    foregroundColor: context.error,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _DisburseAdvanceDialog(request: request),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AdvanceRow extends ConsumerWidget {
  final AdvanceRecord record;

  const _AdvanceRow({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canEdit = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit);
    final canDelete = ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.delete);
    final progress = record.amountRepaid / record.amount;

    // Status colors
    Color statusColor = context.success;
    Color statusBg = context.successLight;
    if (record.status == 'Rejected') {
      statusColor = context.error;
      statusBg = context.errorLight;
    } else if (record.status == 'Pending') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          Widget buildMenu() {
            if (!canEdit && !canDelete) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
              color: context.cardBg,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) async {
                if (val == 'delete') {
                  if (!canDelete) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Advance Record'),
                      content: Text('Are you sure you want to delete this salary advance record for "${record.employeeName}"? This action cannot be undone.'),
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
                    ref.read(advancesProvider.notifier).deleteAdvance(record.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Salary advance record for "${record.employeeName}" deleted.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: context.error,
                      ),
                    );
                  }
                } else if (val == 'edit') {
                  if (!canEdit) return;
                  showDialog(
                    context: context,
                    builder: (context) => _EditAdvanceDialog(record: record),
                  );
                }
              },
              itemBuilder: (context) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Request', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Record', style: TextStyle(color: context.error, fontSize: 13)),
                  ),
              ],
            );
          }

          if (isNarrow) {
            return Column(
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
                            record.reason,
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    buildMenu(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repaid Rs. ${record.amountRepaid.toStringAsFixed(0)} / Rs. ${record.amount.toStringAsFixed(0)}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: context.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: context.scaffoldBg,
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining Balance: Rs. ${record.remainingAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: context.textMuted, fontSize: 10),
                ),
              ],
            );
          }

          return Row(
            children: [
              // Employee Name
              Expanded(
                flex: 2,
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.reason,
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Repayment progress
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Repaid Rs. ${record.amountRepaid.toStringAsFixed(0)} / Rs. ${record.amount.toStringAsFixed(0)}',
                            style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: context.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: context.scaffoldBg,
                          valueColor: AlwaysStoppedAnimation<Color>(context.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remaining Balance: Rs. ${record.remainingAmount.toStringAsFixed(0)}',
                        style: TextStyle(color: context.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Quick actions
              buildMenu(),
            ],
          );
        },
      ),
    );
  }
}

class _DisburseAdvanceDialog extends ConsumerStatefulWidget {
  final AdvanceRecord request;

  const _DisburseAdvanceDialog({required this.request});

  @override
  ConsumerState<_DisburseAdvanceDialog> createState() => _DisburseAdvanceDialogState();
}

class _DisburseAdvanceDialogState extends ConsumerState<_DisburseAdvanceDialog> {
  String? _selectedAccountId;
  String? _selectedAccountName;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();

    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        'Disburse Salary Advance',
        style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disbursing advance payment of Rs. ${widget.request.amount.toStringAsFixed(0)} to employee "${widget.request.employeeName}".',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Payment Source Account *',
                style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'Choose payment account',
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} (${acc.type}) - Bal: Rs. ${acc.balance.toStringAsFixed(0)}'),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
        ),
        if (ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit))
          ElevatedButton(
            onPressed: _selectedAccountId == null
                ? null
                : () async {
                    await ref.read(advancesProvider.notifier).disburseAdvance(
                          record: widget.request,
                          accountId: _selectedAccountId!,
                          accountName: _selectedAccountName!,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Salary advance disbursed successfully from $_selectedAccountName.'),
                          backgroundColor: context.success,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Pay'),
          ),
      ],
    );
  }
}

class _RequestAdvanceDialog extends ConsumerStatefulWidget {
  const _RequestAdvanceDialog();

  @override
  ConsumerState<_RequestAdvanceDialog> createState() => _RequestAdvanceDialogState();
}

class _RequestAdvanceDialogState extends ConsumerState<_RequestAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employees = ref.watch(employeesProvider).employees.where((e) => e.status == 'Active').toList();

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
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
                      'Request Salary Advance',
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

                // Employee Select
                _buildLabel('Select Employee'),
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Choose employee'),
                  validator: (val) => val == null ? 'Please select employee' : null,
                  items: employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp.id,
                      child: Text(emp.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final empName = employees.firstWhere((e) => e.id == val).name;
                      setState(() {
                        _selectedEmployeeId = val;
                        _selectedEmployeeName = empName;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Amount
                _buildLabel('Advance Amount (Rs.)'),
                TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('e.g. 10000'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(val) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Reason
                _buildLabel('Reason for Request'),
                TextFormField(
                  controller: _reasonController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('Describe reason...'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please specify reason' : null,
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
                    if (ref.watch(adminProvider).hasPermission(AppModule.payroll, PermissionAction.create)) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final request = AdvanceRecord(
                              id: "adv_${DateTime.now().millisecondsSinceEpoch}",
                              employeeId: _selectedEmployeeId!,
                              employeeName: _selectedEmployeeName!,
                              amount: double.parse(_amountController.text),
                              requestDate: DateTime.now().toIso8601String().substring(0, 10),
                              reason: _reasonController.text.trim(),
                              repaymentMonths: 1,
                              amountRepaid: 0.0,
                              status: 'Pending',
                            );
                            Navigator.of(context).pop(request);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Request'),
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

class _EditAdvanceDialog extends ConsumerStatefulWidget {
  final AdvanceRecord record;
  const _EditAdvanceDialog({required this.record});

  @override
  ConsumerState<_EditAdvanceDialog> createState() => _EditAdvanceDialogState();
}

class _EditAdvanceDialogState extends ConsumerState<_EditAdvanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _reasonController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.record.amount.toStringAsFixed(0));
    _reasonController = TextEditingController(text: widget.record.reason);
    _status = widget.record.status;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
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
                      'Edit Advance Request',
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

                // Amount
                _buildLabel('Advance Amount (Rs.)'),
                TextFormField(
                  controller: _amountController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('e.g. 10000'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(val) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                _buildLabel('Approval Status'),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending Approval')),
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                    DropdownMenuItem(value: 'Settled', child: Text('Fully Settled')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),

                // Reason
                _buildLabel('Reason for Request'),
                TextFormField(
                  controller: _reasonController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('Describe reason...'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please specify reason' : null,
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
                              amount: double.parse(_amountController.text),
                              reason: _reasonController.text.trim(),
                              status: _status,
                            );
                            ref.read(advancesProvider.notifier).updateAdvance(updated);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Advance request details updated.'),
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
