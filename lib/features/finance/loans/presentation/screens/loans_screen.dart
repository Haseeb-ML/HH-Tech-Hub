import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/loans_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../domain/entities/loan_record.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(loansProvider);
    final adminState = ref.watch(adminProvider);
    final canCreateLoan = adminState.hasPermission(AppModule.loans, PermissionAction.create);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalLent = state.loans
        .where((l) => l.type == 'Lent')
        .fold<double>(0.0, (sum, l) => sum + l.amount);
    
    final remainingLent = state.loans
        .where((l) => l.type == 'Lent')
        .fold<double>(0.0, (sum, l) => sum + l.remainingBalance);

    final totalBorrowed = state.loans
        .where((l) => l.type == 'Borrowed')
        .fold<double>(0.0, (sum, l) => sum + l.amount);

    final remainingBorrowed = state.loans
        .where((l) => l.type == 'Borrowed')
        .fold<double>(0.0, (sum, l) => sum + l.remainingBalance);

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width >= 1200 ? 3 : (width >= 800 ? 2 : 1);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/loans'),
          Expanded(
            child: (state.isLoading && state.loans.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(width < 600 ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 650;
                            final titleCol = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loans & Credits',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track operational credits, bank borrow lines, and employee advances/lent cash.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );

                            final addButton = ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => const _AddLoanDialog(),
                                );
                                if (result != null) {
                                  final loan = result['loan'] as LoanRecord;
                                  final accId = result['accountId'] as String;
                                  final personalAccId = result['personalAccountId'] as String?;
                                  final loanScope = result['loanScope'] as String?;
                                  ref.read(loansProvider.notifier).addLoan(loan, accId, personalAccountId: personalAccId, loanScope: loanScope);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Loan record created successfully.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(tr('Record Loan')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleCol,
                                  if (canCreateLoan) ...[
                                    const SizedBox(height: 14),
                                    addButton,
                                  ],
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: titleCol),
                                if (canCreateLoan) ...[
                                  const SizedBox(width: 16),
                                  addButton,
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final gridCrossCount = isMobile ? 2 : (constraints.maxWidth >= 1200 ? 4 : 2);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: isMobile ? 10 : 16,
                                mainAxisSpacing: isMobile ? 10 : 16,
                                childAspectRatio: isMobile ? 0.85 : (gridCrossCount == 4 ? 1.6 : 1.7),
                              ),
                              children: [
                                StatCard(
                                  title: 'Total Loans Lent',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Loans Lent.',
                                  value: 'Rs. ${(totalLent / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.upload_outlined,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                ),
                                StatCard(
                                  title: 'Remaining Lent Recv',
                                  tooltipMessage: 'Detailed statistics and information regarding Remaining Lent Recv.',
                                  value: 'Rs. ${(remainingLent / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.trending_up,
                                  iconColor: Colors.teal,
                                  iconBgColor: context.isDarkMode ? Colors.teal.withValues(alpha: 0.2) : const Color(0xFFE6F4EA),
                                ),
                                StatCard(
                                  title: 'Total Loans Borrowed',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Loans Borrowed.',
                                  value: 'Rs. ${(totalBorrowed / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.download_outlined,
                                  iconColor: context.error,
                                  iconBgColor: context.errorLight,
                                ),
                                StatCard(
                                  title: 'Remaining Borrowed Pay',
                                  tooltipMessage: 'Detailed statistics and information regarding Remaining Borrowed Pay.',
                                  value: 'Rs. ${(remainingBorrowed / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.trending_down,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 600;
                                final searchBox = Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: TextField(
                                    onChanged: (val) => ref.read(loansProvider.notifier).setSearchQuery(val),
                                    style: TextStyle(color: context.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: tr('Search loans by borrower/lender name or description...'),
                                      hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
                                      prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                );

                                final typeFilterBox = Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state.typeFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                      items: [
                                        DropdownMenuItem(value: 'All', child: Text(tr('Type: All'))),
                                        DropdownMenuItem(value: 'Lent', child: Text(tr('Type: Lent'))),
                                        DropdownMenuItem(value: 'Borrowed', child: Text(tr('Type: Borrowed'))),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(loansProvider.notifier).setTypeFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                );

                                if (isNarrow) {
                                  final hasActiveFilter = state.typeFilter != 'All';
                                  return Row(
                                    children: [
                                      Expanded(child: searchBox),
                                      const SizedBox(width: 8),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          InkWell(
                                            onTap: () => _showLoanFilterBottomSheet(context, ref),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              height: 40,
                                              width: 42,
                                              decoration: BoxDecoration(
                                                color: hasActiveFilter
                                                    ? context.primaryColor.withValues(alpha: 0.15)
                                                    : (context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: hasActiveFilter ? context.primaryColor : context.border,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.filter_list,
                                                size: 20,
                                                color: hasActiveFilter ? context.primaryColor : context.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (hasActiveFilter)
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: context.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(flex: 2, child: searchBox),
                                    const SizedBox(width: 12),
                                    typeFilterBox,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Loans Grid
                        state.filteredLoans.isEmpty
                            ? _buildEmptyState(context)
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: width < 600 ? 320 : 260,
                                ),
                                itemCount: state.filteredLoans.length,
                                itemBuilder: (context, index) {
                                  final loan = state.filteredLoans[index];
                                  return _LoanCard(loan: loan);
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Loan Records Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a new company credit or lent loan to start tracking balances.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLoanFilterBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentState = ref.watch(loansProvider);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_list, size: 20, color: context.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Loans',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      'Loan Type',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeFilterChip(
                          context: context,
                          label: 'All Types',
                          selected: currentState.typeFilter == 'All',
                          onTap: () {
                            ref.read(loansProvider.notifier).setTypeFilter('All');
                            setState(() {});
                          },
                        ),
                        _buildTypeFilterChip(
                          context: context,
                          label: 'Lent (Receivable)',
                          selected: currentState.typeFilter == 'Lent',
                          onTap: () {
                            ref.read(loansProvider.notifier).setTypeFilter('Lent');
                            setState(() {});
                          },
                        ),
                        _buildTypeFilterChip(
                          context: context,
                          label: 'Borrowed (Payable)',
                          selected: currentState.typeFilter == 'Borrowed',
                          onTap: () {
                            ref.read(loansProvider.notifier).setTypeFilter('Borrowed');
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(loansProvider.notifier).setTypeFilter('All');
                              Navigator.pop(sheetContext);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Reset Filter'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeFilterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? context.primaryColor.withValues(alpha: 0.15)
              : (context.isDarkMode ? const Color(0xFF1F2937) : context.scaffoldBg),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? context.primaryColor : context.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? context.primaryColor : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final LoanRecord loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final canDeleteLoan = adminState.hasPermission(AppModule.loans, PermissionAction.delete);
    final theme = Theme.of(context);
    final isLent = loan.type == 'Lent';
    final repaidAmount = loan.amount - loan.remainingBalance;
    final progress = loan.amount > 0 ? repaidAmount / loan.amount : 0.0;

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _LoanDetailsDialog(loan: loan),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.borrowerName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isLent ? 'Lent (Receivable)' : 'Borrowed (Payable)',
                              style: TextStyle(
                                color: isLent ? context.success : context.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (loan.isPersonalExternalLoan) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person, size: 10, color: Colors.purple),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Personal (Ext): ${loan.personalAccountName.isNotEmpty ? loan.personalAccountName : loan.resolvedAccountName}',
                                      style: const TextStyle(
                                        color: Colors.purple,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (loan.isInternalLoan) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.3), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_horiz, size: 10, color: Colors.indigo),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Internal: ${loan.personalAccountName} ⟷ ${loan.resolvedAccountName}',
                                      style: const TextStyle(
                                        color: Colors.indigo,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (loan.resolvedAccountName.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.2), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.account_balance, size: 10, color: context.primaryColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      loan.resolvedAccountName,
                                      style: TextStyle(
                                        color: context.primaryColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: loan.status == 'Repaid' ? context.successLight : context.warningLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan.status,
                      style: TextStyle(
                        color: loan.status == 'Repaid' ? context.success : context.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                    color: context.cardBg,
                    padding: EdgeInsets.zero,
                    onSelected: (val) async {
                      if (val == 'details') {
                        showDialog(
                          context: context,
                          builder: (context) => _LoanDetailsDialog(loan: loan),
                        );
                      } else if (val == 'delete' && canDeleteLoan) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Loan Record'),
                            content: Text('${tr("Are you sure you want to delete this loan for")} "${loan.borrowerName}"? ${tr("This will rollback bank account principal, repayments, and all matching ledger records.")}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(tr('Delete'), style: TextStyle(color: context.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(loansProvider.notifier).deleteLoan(loan.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Loan record deleted and balances rolled back.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: context.error,
                            ),
                          );
                        }
                      } else if (val == 'repayments') {
                        _showRepaymentsBottomSheet(context, ref, loan);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Text('View Details', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'repayments',
                        child: Text('Repayments Log', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      if (canDeleteLoan)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Loan', style: TextStyle(color: context.error, fontSize: 13)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Dates Row (Start Date & Due Date)
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 12, color: context.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Start: ${loan.startDate.split('T').first}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 3, height: 3, decoration: BoxDecoration(color: context.textMuted, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Icon(Icons.alarm_outlined, size: 12, color: loan.endDate.isNotEmpty ? context.primaryColor : context.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loan.endDate.isNotEmpty ? 'Due: ${loan.endDate}' : 'No Due Date',
                      style: TextStyle(
                        color: loan.endDate.isNotEmpty ? context.primaryColor : context.textMuted,
                        fontSize: 11,
                        fontWeight: loan.endDate.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Description preview
              Expanded(
                child: Text(
                  loan.cleanDescription.isNotEmpty ? loan.cleanDescription : 'No specific terms provided.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Repayment Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repayment Progress',
                        style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% Repaid',
                        style: TextStyle(color: context.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? context.success : context.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Principal & Remaining Balances Row + Tap Hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Principal',
                          style: TextStyle(color: context.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs. ${loan.amount.toStringAsFixed(0)}',
                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Repaid',
                          style: TextStyle(color: context.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs. ${repaidAmount.toStringAsFixed(0)}',
                          style: TextStyle(color: context.success, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining',
                          style: TextStyle(color: context.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs. ${loan.remainingBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: loan.remainingBalance > 0 ? context.warning : context.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Click to view details & history',
                    style: TextStyle(fontSize: 10, color: context.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 10, color: context.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showRepaymentsBottomSheet(BuildContext context, WidgetRef ref, LoanRecord loan) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.cardBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) {
        final tr = ref.watch(translationProvider);
        final canEditLoan = ref.watch(adminProvider).hasPermission(AppModule.loans, PermissionAction.edit);
        final allAccounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
        final accounts = loan.isPersonalExternalLoan
            ? allAccounts.where((a) => a.isPersonal).toList()
            : (allAccounts.where((a) => a.isCompany).toList().isNotEmpty
                ? allAccounts.where((a) => a.isCompany).toList()
                : allAccounts);
        final TextEditingController amountCtrl = TextEditingController();
        String? selectedAccId = accounts.where((a) => a.id == loan.resolvedAccountId || a.id == loan.personalAccountId).firstOrNull?.id ??
            (accounts.isNotEmpty ? accounts.first.id : null);
        DateTime repDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                padding: const EdgeInsets.all(24),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repayments Log - ${loan.borrowerName}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (loan.isPersonalExternalLoan) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loan.type == 'Borrowed'
                                  ? 'Installment repayment will be deducted from ${loan.personalAccountName.isNotEmpty ? loan.personalAccountName : loan.resolvedAccountName}\'s Personal Account and paid to ${loan.borrowerName}.'
                                  : 'Installment repayment will be received from ${loan.borrowerName} and deposited into ${loan.personalAccountName.isNotEmpty ? loan.personalAccountName : loan.resolvedAccountName}\'s Personal Account.',
                              style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (loan.isInternalLoan) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Colors.indigo, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loan.type == 'Borrowed'
                                  ? 'Company repayment will be deducted from selected Company Account and credited to ${loan.personalAccountName}\'s Personal Account.'
                                  : 'Repayment installment will be deducted from ${loan.personalAccountName}\'s Personal Account and deposited into the selected Company Account.',
                              style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Repayments List
                  Expanded(
                    child: loan.repayments.isEmpty
                        ? Center(
                            child: Text(
                              'No repayments recorded yet.',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            itemCount: loan.repayments.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final rep = loan.repayments[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle_outline, color: context.success),
                                title: Text('Installment Repayment', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                subtitle: Text('${rep.date} • Paid via: ${rep.accountName}', style: TextStyle(color: context.textSecondary)),
                                trailing: Text('Rs. ${rep.amount.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800)),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  if (canEditLoan && loan.remainingBalance > 0) ...[
                    // Add Repayment Form
                    Text('Record New Installment Repayment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final isMob = MediaQuery.of(context).size.width < 600;
                        final amountField = TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Installment Amount',
                            hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: context.scaffoldBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                          ),
                        );

                        final accountDropdown = DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedAccId,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: context.scaffoldBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
                          ),
                          items: accounts.map((a) {
                            return DropdownMenuItem(value: a.id, child: Text(a.name));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedAccId = val);
                          },
                        );

                        final recordButton = ElevatedButton(
                          onPressed: () {
                            final val = double.tryParse(amountCtrl.text);
                            if (val == null || val <= 0 || selectedAccId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('Please enter a valid amount')), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }
                            if (val > loan.remainingBalance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount exceeds remaining loan balance'), behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }

                            final acc = accounts.firstWhere((a) => a.id == selectedAccId);
                            final repayment = LoanRepayment(
                              id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
                              date: repDate.toIso8601String().substring(0, 10),
                              amount: val,
                              accountId: selectedAccId!,
                              accountName: acc.name,
                            );

                            ref.read(loansProvider.notifier).recordRepayment(loan.id, repayment);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Repayment logged successfully.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.success,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(tr('Record')),
                        );

                        if (isMob) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              amountField,
                              const SizedBox(height: 8),
                              accountDropdown,
                              const SizedBox(height: 10),
                              recordButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: amountField),
                            const SizedBox(width: 12),
                            Expanded(child: accountDropdown),
                            const SizedBox(width: 12),
                            recordButton,
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

class _AddLoanDialog extends ConsumerStatefulWidget {
  const _AddLoanDialog();

  @override
  ConsumerState<_AddLoanDialog> createState() => _AddLoanDialogState();
}

class _AddLoanDialogState extends ConsumerState<_AddLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descController;

  String _loanScope = 'CompanyExternal'; // 'CompanyExternal', 'PersonalExternal', 'Internal'
  String _type = 'Borrowed'; // Default: 'Borrowed' or 'Lent'
  String? _selectedCompanyAccountId;
  String? _selectedPersonalAccountId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 540,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Consumer(
          builder: (context, ref, child) {
            final allAccounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
            final companyAccounts = allAccounts.where((a) => a.isCompany).toList();
            final personalAccounts = allAccounts.where((a) => a.isPersonal).toList();

            // Fallback if no separate company accounts exist
            final availableCompanyAccounts = companyAccounts.isNotEmpty ? companyAccounts : allAccounts;

            if (_selectedCompanyAccountId == null && availableCompanyAccounts.isNotEmpty) {
              _selectedCompanyAccountId = availableCompanyAccounts.first.id;
            }
            if (_selectedPersonalAccountId == null && personalAccounts.isNotEmpty) {
              _selectedPersonalAccountId = personalAccounts.first.id;
              if (_loanScope == 'Internal') {
                final p = personalAccounts.first;
                _nameController.text = p.ownerName.isNotEmpty ? '${p.ownerName} (Personal)' : '${p.name} (Personal)';
              }
            }

            final selectedCompanyAccount = availableCompanyAccounts.where((a) => a.id == _selectedCompanyAccountId).firstOrNull;
            final selectedPersonalAccount = personalAccounts.where((a) => a.id == _selectedPersonalAccountId).firstOrNull;

            return Form(
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
                          'Record Loan / Debt Ledger',
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
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Counterparty Mode Selector: 3 Scopes
                    _buildLabel('Loan Category & Scope'),
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final isCompact = box.maxWidth < 460;
                          final scopes = [
                            (
                              'CompanyExternal',
                              'Company Loan',
                              '🏢 External',
                              Icons.business_outlined,
                              context.primaryColor,
                            ),
                            (
                              'PersonalExternal',
                              'Personal Loan',
                              '👤 External',
                              Icons.person_outline,
                              Colors.purple,
                            ),
                            (
                              'Internal',
                              'Internal Transfer',
                              '🔄 Comp ⟷ Pers',
                              Icons.swap_horiz,
                              Colors.indigo,
                            ),
                          ];

                          return Row(
                            children: scopes.map((item) {
                              final isSelected = _loanScope == item.$1;
                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _loanScope = item.$1;
                                      if (_loanScope == 'Internal') {
                                        if (selectedPersonalAccount != null) {
                                          _nameController.text = selectedPersonalAccount.ownerName.isNotEmpty
                                              ? '${selectedPersonalAccount.ownerName} (Personal)'
                                              : '${selectedPersonalAccount.name} (Personal)';
                                        }
                                      } else {
                                        _nameController.clear();
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? item.$5 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.$4,
                                                size: 13,
                                                color: isSelected ? Colors.white : context.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  item.$2,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : context.textSecondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isCompact ? 10 : 11,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!isCompact) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.$3,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white.withValues(alpha: 0.85) : context.textMuted,
                                                fontSize: 9.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loan Type
                    _buildLabel('Loan Type'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _type,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Type'),
                      items: [
                        DropdownMenuItem(
                          value: 'Borrowed',
                          child: Text(
                            _loanScope == 'PersonalExternal'
                                ? 'Borrowed (Personal Owner received loan from external party)'
                                : (_loanScope == 'Internal'
                                    ? 'Company Borrows from Personal Account (Company Liability)'
                                    : 'Borrowed (Company received credit/liability from third party)'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Lent',
                          child: Text(
                            _loanScope == 'PersonalExternal'
                                ? 'Lent (Personal Owner lent personal funds to external party)'
                                : (_loanScope == 'Internal'
                                    ? 'Company Lends to Personal Account (Owner Liability/Advance)'
                                    : 'Lent (Company gave cash advances to employee/third party)'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _type = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // If Personal External or Internal Loan: Show Personal Account Dropdown
                    if (_loanScope != 'CompanyExternal') ...[
                      if (personalAccounts.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.warningLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.warning),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: context.warning, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No Personal Accounts found. Please add a Personal Account in the "Personal Account" section first.',
                                  style: TextStyle(color: context.textPrimary, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        _buildLabel('Personal Account (Owner / Partner)'),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedPersonalAccountId,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Select Personal Account'),
                          items: personalAccounts.map((a) {
                            final label = a.ownerName.isNotEmpty ? '${a.ownerName} (${a.name})' : a.name;
                            return DropdownMenuItem(
                              value: a.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
                                  Text(
                                    'Bal: Rs. ${a.balance.toStringAsFixed(0)}',
                                    style: TextStyle(color: context.success, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPersonalAccountId = val;
                                if (_loanScope == 'Internal') {
                                  final p = personalAccounts.where((a) => a.id == val).firstOrNull;
                                  if (p != null) {
                                    _nameController.text = p.ownerName.isNotEmpty
                                        ? '${p.ownerName} (Personal)'
                                        : '${p.name} (Personal)';
                                  }
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // Name of Borrower / Lender (editable)
                    _buildLabel(_loanScope == 'Internal'
                        ? 'Internal Loan Record Title'
                        : (_loanScope == 'PersonalExternal'
                            ? (_type == 'Lent' ? 'External Borrower Name / Friend / 3rd Party' : 'External Lender Name / Bank / Friend')
                            : (_type == 'Lent' ? 'Borrower Name / Employee / 3rd Party' : 'Lender Name / Bank / Vendor'))),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration(
                        _loanScope == 'Internal'
                            ? 'e.g. Owner Advance or Working Capital'
                            : (_loanScope == 'PersonalExternal'
                                ? 'e.g. Ali Khan (Friend) or Meezan Personal Loan'
                                : 'e.g. Syed Bilal or HBL Bank'),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Amount & Company Account
                    Builder(
                      builder: (context) {
                        final amountCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Principal Amount (Rs.)'),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('e.g. 50000'),
                              onChanged: (_) => setState(() {}),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter amount';
                                final numVal = double.tryParse(val);
                                if (numVal == null || numVal <= 0) return 'Invalid amount';

                                if (_loanScope == 'PersonalExternal') {
                                  if (_type == 'Lent') {
                                    if (selectedPersonalAccount != null && numVal > selectedPersonalAccount.balance) {
                                      return 'Exceeds balance (Rs. ${selectedPersonalAccount.balance.toStringAsFixed(0)})';
                                    }
                                  }
                                } else if (_loanScope == 'Internal') {
                                  if (_type == 'Borrowed') {
                                    if (selectedPersonalAccount != null && numVal > selectedPersonalAccount.balance) {
                                      return 'Exceeds personal balance (Rs. ${selectedPersonalAccount.balance.toStringAsFixed(0)})';
                                    }
                                  } else {
                                    if (selectedCompanyAccount != null && numVal > selectedCompanyAccount.balance) {
                                      return 'Exceeds company balance (Rs. ${selectedCompanyAccount.balance.toStringAsFixed(0)})';
                                    }
                                  }
                                } else {
                                  if (_type == 'Lent') {
                                    if (selectedCompanyAccount != null && numVal > selectedCompanyAccount.balance) {
                                      return 'Exceeds balance (Rs. ${selectedCompanyAccount.balance.toStringAsFixed(0)})';
                                    }
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        );

                        // If Personal External: Company account is not involved
                        if (_loanScope == 'PersonalExternal') {
                          return amountCol;
                        }

                        final accountCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Company Bank/Cash Account'),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedCompanyAccountId,
                              dropdownColor: context.cardBg,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: _buildInputDecoration('Select Account'),
                              items: availableCompanyAccounts.map((a) {
                                return DropdownMenuItem(
                                  value: a.id,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                                      Text(
                                        'Rs. ${a.balance.toStringAsFixed(0)}',
                                        style: TextStyle(color: context.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedCompanyAccountId = val);
                              },
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              amountCol,
                              const SizedBox(height: 16),
                              accountCol,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: amountCol),
                            const SizedBox(width: 16),
                            Expanded(child: accountCol),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Visual Funds Transfer / Info Summary Card
                    if (_loanScope == 'PersonalExternal' && selectedPersonalAccount != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _type == 'Borrowed' ? Icons.south_west : Icons.north_east,
                                  size: 14,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _type == 'Borrowed'
                                      ? 'Fund Flow: External Third Party ──▶ Personal Account'
                                      : 'Fund Flow: Personal Account ──▶ External Third Party',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _type == 'Borrowed'
                                  ? 'Rs. ${_amountController.text.isEmpty ? "0" : _amountController.text} personal loan will be credited directly into ${selectedPersonalAccount.ownerName.isNotEmpty ? selectedPersonalAccount.ownerName : selectedPersonalAccount.name}\'s personal account. Company accounts will NOT be affected.'
                                  : 'Rs. ${_amountController.text.isEmpty ? "0" : _amountController.text} will be disbursed directly from ${selectedPersonalAccount.ownerName.isNotEmpty ? selectedPersonalAccount.ownerName : selectedPersonalAccount.name}\'s personal account to external borrower. Company accounts will NOT be affected.',
                              style: TextStyle(color: context.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (_loanScope == 'Internal' && selectedPersonalAccount != null && selectedCompanyAccount != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _type == 'Borrowed' ? Icons.south_west : Icons.north_east,
                                  size: 14,
                                  color: _type == 'Borrowed' ? context.success : context.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _type == 'Borrowed'
                                      ? 'Fund Flow: Personal Account ──▶ Company Account'
                                      : 'Fund Flow: Company Account ──▶ Personal Account',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _type == 'Borrowed'
                                  ? 'Rs. ${_amountController.text.isEmpty ? "0" : _amountController.text} will be transferred from ${selectedPersonalAccount.ownerName.isNotEmpty ? selectedPersonalAccount.ownerName : selectedPersonalAccount.name}\'s personal account into Company ${selectedCompanyAccount.name}. Company owes this liability to Owner.'
                                  : 'Rs. ${_amountController.text.isEmpty ? "0" : _amountController.text} will be disbursed from Company ${selectedCompanyAccount.name} into ${selectedPersonalAccount.ownerName.isNotEmpty ? selectedPersonalAccount.ownerName : selectedPersonalAccount.name}\'s personal account. Owner owes this debt/advance back to Company.',
                              style: TextStyle(color: context.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Start Date & End Date
                    Builder(
                      builder: (context) {
                        final startDateCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Start Date'),
                            OutlinedButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _startDate.toIso8601String().substring(0, 10),
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  ),
                                  Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                                ],
                              ),
                            ),
                          ],
                        );

                        final endDateCol = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('End Date (Due) - Optional'),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? _startDate.add(const Duration(days: 180)),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setState(() => _endDate = picked);
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: context.border),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : 'No Due Date (Optional)',
                                          style: TextStyle(
                                            color: _endDate != null ? context.textPrimary : context.textMuted,
                                            fontSize: 13,
                                            fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_endDate != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'Clear due date',
                                    icon: const Icon(Icons.clear, size: 18),
                                    color: context.error,
                                    onPressed: () {
                                      setState(() => _endDate = null);
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );

                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              startDateCol,
                              const SizedBox(height: 16),
                              endDateCol,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: startDateCol),
                            const SizedBox(width: 16),
                            Expanded(child: endDateCol),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description / Terms'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Enter detail loan agreements or terms...'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter terms' : null,
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_loanScope != 'CompanyExternal' && personalAccounts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please add a personal account first.')),
                              );
                              return;
                            }
                            if (_formKey.currentState?.validate() == true) {
                              final amt = double.parse(_amountController.text);
                              final now = DateTime.now();
                              final startDateTime = DateTime(
                                _startDate.year,
                                _startDate.month,
                                _startDate.day,
                                now.hour,
                                now.minute,
                                now.second,
                                now.millisecond,
                              );

                              final isPersonalExt = _loanScope == 'PersonalExternal';
                              final isInternal = _loanScope == 'Internal';

                              final accId = isPersonalExt ? _selectedPersonalAccountId! : _selectedCompanyAccountId!;
                              final accName = isPersonalExt
                                  ? (selectedPersonalAccount != null
                                      ? (selectedPersonalAccount.ownerName.isNotEmpty ? selectedPersonalAccount.ownerName : selectedPersonalAccount.name)
                                      : 'Personal Account')
                                  : (selectedCompanyAccount?.name ?? '');

                              final loan = LoanRecord(
                                id: 'loan_${now.millisecondsSinceEpoch}',
                                borrowerName: _nameController.text.trim(),
                                type: _type,
                                amount: amt,
                                remainingBalance: amt,
                                startDate: startDateTime.toIso8601String(),
                                endDate: _endDate != null ? _endDate!.toIso8601String().substring(0, 10) : '',
                                status: 'Active',
                                description: _descController.text.trim(),
                                accountId: accId,
                                accountName: accName,
                                repayments: [],
                              );
                              Navigator.of(context).pop({
                                'loan': loan,
                                'accountId': accId,
                                'personalAccountId': isPersonalExt ? _selectedPersonalAccountId : (isInternal ? _selectedPersonalAccountId : null),
                                'loanScope': _loanScope,
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _loanScope == 'PersonalExternal'
                                ? Colors.purple
                                : (_loanScope == 'Internal' ? Colors.indigo : context.primaryColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            _loanScope == 'PersonalExternal'
                                ? 'Register Personal Loan'
                                : (_loanScope == 'Internal' ? 'Register Internal Loan' : 'Register Company Loan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}

class _LoanDetailsDialog extends ConsumerWidget {
  final LoanRecord loan;

  const _LoanDetailsDialog({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveLoan = ref.watch(loansProvider).loans.where((l) => l.id == loan.id).firstOrNull ?? loan;
    final adminState = ref.watch(adminProvider);
    final canEditLoan = adminState.hasPermission(AppModule.loans, PermissionAction.edit);
    final canDeleteLoan = adminState.hasPermission(AppModule.loans, PermissionAction.delete);
    final theme = Theme.of(context);
    final isLent = liveLoan.type == 'Lent';
    final repaidAmount = liveLoan.amount - liveLoan.remainingBalance;
    final progress = liveLoan.amount > 0 ? repaidAmount / liveLoan.amount : 0.0;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 580,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isLent ? context.success : context.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isLent ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                    color: isLent ? context.success : context.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveLoan.borrowerName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLent ? context.successLight : context.errorLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isLent ? 'Lent (Receivable)' : 'Borrowed (Payable)',
                              style: TextStyle(
                                color: isLent ? context.success : context.error,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: liveLoan.status == 'Repaid' ? context.successLight : context.warningLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              liveLoan.status,
                              style: TextStyle(
                                color: liveLoan.status == 'Repaid' ? context.success : context.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Breakdown Cards
                    if (isMobile) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              title: 'Principal',
                              value: 'Rs. ${liveLoan.amount.toStringAsFixed(0)}',
                              color: context.primaryColor,
                              bgColor: context.primaryColor.withValues(alpha: 0.08),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              title: 'Total Repaid',
                              value: 'Rs. ${repaidAmount.toStringAsFixed(0)}',
                              color: context.success,
                              bgColor: context.successLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildMetricTile(
                        context,
                        title: 'Remaining Balance',
                        value: 'Rs. ${liveLoan.remainingBalance.toStringAsFixed(0)}',
                        color: liveLoan.remainingBalance > 0 ? context.warning : context.success,
                        bgColor: liveLoan.remainingBalance > 0 ? context.warningLight : context.successLight,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              title: 'Principal',
                              value: 'Rs. ${liveLoan.amount.toStringAsFixed(0)}',
                              color: context.primaryColor,
                              bgColor: context.primaryColor.withValues(alpha: 0.08),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              title: 'Total Repaid',
                              value: 'Rs. ${repaidAmount.toStringAsFixed(0)}',
                              color: context.success,
                              bgColor: context.successLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              title: 'Remaining',
                              value: 'Rs. ${liveLoan.remainingBalance.toStringAsFixed(0)}',
                              color: liveLoan.remainingBalance > 0 ? context.warning : context.success,
                              bgColor: liveLoan.remainingBalance > 0 ? context.warningLight : context.successLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Repayment Progress Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Repayment Progress',
                                style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}% Completed',
                                style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? context.success : context.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metadata Details Grid
                    Text(
                      'Loan Details & Agreements',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        children: [
                          if (liveLoan.isPersonalExternalLoan) ...[
                            _buildDetailRow(context, icon: Icons.person_outline, label: 'Personal Account', value: '${liveLoan.personalAccountName.isNotEmpty ? liveLoan.personalAccountName : liveLoan.resolvedAccountName} (Personal Wallet)', isMobile: isMobile),
                          ] else if (liveLoan.isInternalLoan) ...[
                            _buildDetailRow(context, icon: Icons.account_balance_outlined, label: 'Company Account', value: liveLoan.resolvedAccountName.isNotEmpty ? liveLoan.resolvedAccountName : 'Company Account', isMobile: isMobile),
                            const Divider(height: 16),
                            _buildDetailRow(context, icon: Icons.person_outline, label: 'Personal Account', value: '${liveLoan.personalAccountName} (Personal)', isMobile: isMobile),
                          ] else ...[
                            _buildDetailRow(context, icon: Icons.account_balance_outlined, label: 'Company Account', value: liveLoan.resolvedAccountName.isNotEmpty ? liveLoan.resolvedAccountName : 'Not Specified', isMobile: isMobile),
                          ],
                          const Divider(height: 16),
                          _buildDetailRow(context, icon: Icons.calendar_today_outlined, label: 'Start Date', value: liveLoan.startDate.split('T').first, isMobile: isMobile),
                          const Divider(height: 16),
                          _buildDetailRow(context, icon: Icons.alarm_outlined, label: 'Due Date', value: liveLoan.endDate.isNotEmpty ? liveLoan.endDate : 'No Due Date (Open-ended)', isMobile: isMobile),
                          const Divider(height: 16),
                          _buildDetailRow(context, icon: Icons.notes_outlined, label: 'Terms / Notes', value: liveLoan.cleanDescription.isNotEmpty ? liveLoan.cleanDescription : 'No additional terms entered.', isMobile: isMobile),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Repayments Log Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Repayment Installments (${liveLoan.repayments.length})',
                            style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canEditLoan && liveLoan.remainingBalance > 0)
                          TextButton.icon(
                            onPressed: () {
                              _showRepaymentsBottomSheet(context, ref, liveLoan);
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Add Repayment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    liveLoan.repayments.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.history_toggle_off, size: 28, color: context.textMuted),
                                const SizedBox(height: 6),
                                Text(
                                  'No installment repayments recorded yet.',
                                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.border),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: liveLoan.repayments.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final rep = liveLoan.repayments[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: context.successLight,
                                    child: Icon(Icons.check, size: 14, color: context.success),
                                  ),
                                  title: Text('Installment #${index + 1}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('${rep.date} • Paid via: ${rep.accountName}', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                                  trailing: Text('Rs. ${rep.amount.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Footer Actions
            if (isMobile) ...[
              Column(
                children: [
                  if (canEditLoan && liveLoan.remainingBalance > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showRepaymentsBottomSheet(context, ref, liveLoan);
                        },
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Record Repayment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (canDeleteLoan)
                        OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Loan Record'),
                              content: Text('Are you sure you want to delete loan for "${liveLoan.borrowerName}"? This will rollback balances and ledger records.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: context.error))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(loansProvider.notifier).deleteLoan(liveLoan.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Loan record deleted and balances rolled back.'), backgroundColor: context.error),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete Loan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.error,
                          side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                        ),
                      )
                      else
                        const SizedBox.shrink(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close', style: TextStyle(color: context.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canDeleteLoan)
                    OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Loan Record'),
                          content: Text('Are you sure you want to delete loan for "${liveLoan.borrowerName}"? This will rollback balances and ledger records.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: context.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(loansProvider.notifier).deleteLoan(liveLoan.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Loan record deleted and balances rolled back.'), backgroundColor: context.error),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete Loan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.error,
                      side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                    ),
                  )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close', style: TextStyle(color: context.textSecondary)),
                      ),
                      if (canEditLoan && liveLoan.remainingBalance > 0) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showRepaymentsBottomSheet(context, ref, liveLoan);
                          },
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Record Repayment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, {required String title, required String value, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value, bool isMobile = false}) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: context.primaryColor),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SelectableText(
                value,
                style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.primaryColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
