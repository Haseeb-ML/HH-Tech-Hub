import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/expenses_provider.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../domain/entities/expense_record.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/utils/transaction_id_helper.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  static const int _rowsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  String _formatExpenseDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      try {
        final parsed = DateFormat('dd-MM-yyyy').parse(isoDate);
        return DateFormat('dd-MM-yyyy').format(parsed);
      } catch (_) {
        return isoDate;
      }
    }
  }

  void _showExpenseFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(expensesProvider);
            final accountsState = ref.watch(accountsProvider);

            return Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Expenses',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      'Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.categoryFilter,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            'All',
                            'Salaries & Payroll',
                            'Salary Advances',
                            'Electricity & Utilities',
                            'Internet & Telecom',
                            'Rent & Occupancy',
                            'Bills',
                            'Supplies',
                            'Refreshments',
                            'Travel & Transport',
                            'Office Inventory',
                            'Assets Management',
                            'Marketing & Advertising',
                            'Office & Admin Expenses',
                            'Repairs & Maintenance',
                            'Depreciation',
                            'Bank Charges & Fees',
                            'Other',
                          ].map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c == 'All' ? 'All Categories' : c),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(expensesProvider.notifier).setCategoryFilter(val);
                              setState(() => _currentPage = 0);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Account',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.accountIdFilter,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Accounts')),
                            ...accountsState.accounts.map((acc) {
                              final scopeLabel = acc.accountScope.isNotEmpty ? ' (${acc.accountScope})' : '';
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text('${acc.name}$scopeLabel'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(expensesProvider.notifier).setAccountIdFilter(val);
                              setState(() => _currentPage = 0);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Date Range',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.fromDateFilter != null ? (DateTime.tryParse(state.fromDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                final dateStr = picked.toIso8601String().substring(0, 10);
                                ref.read(expensesProvider.notifier).setDateRange(dateStr, state.toDateFilter);
                                setState(() => _currentPage = 0);
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.fromDateFilter != null ? context.primaryColor : context.textMuted),
                            label: Text(
                              state.fromDateFilter != null ? 'From: ${state.fromDateFilter}' : 'From Date',
                              style: TextStyle(fontSize: 11.5, color: state.fromDateFilter != null ? context.primaryColor : context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.toDateFilter != null ? (DateTime.tryParse(state.toDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                final dateStr = picked.toIso8601String().substring(0, 10);
                                ref.read(expensesProvider.notifier).setDateRange(state.fromDateFilter, dateStr);
                                setState(() => _currentPage = 0);
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.toDateFilter != null ? context.primaryColor : context.textMuted),
                            label: Text(
                              state.toDateFilter != null ? 'To: ${state.toDateFilter}' : 'To Date',
                              style: TextStyle(fontSize: 11.5, color: state.toDateFilter != null ? context.primaryColor : context.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(expensesProvider.notifier).clearFilters();
                              setState(() => _currentPage = 0);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Reset Filters', style: TextStyle(color: context.error)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final tr = ref.watch(translationProvider);
    final state = ref.watch(expensesProvider);
    final accountsState = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canCreateExpense = adminState.hasPermission(AppModule.expenses, PermissionAction.create);
    final canExportExpense = adminState.hasPermission(AppModule.expenses, PermissionAction.export);
    final filteredExpenses = state.filteredExpenses;
    final totalPages = (filteredExpenses.length / _rowsPerPage).ceil();
    final validPage = totalPages == 0
      ? 0
      : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
    final paginatedExpenses = filteredExpenses
      .skip(validPage * _rowsPerPage)
      .take(_rowsPerPage)
      .toList();

    // Calculate metrics based on current filtered dataset
    final displayedExpenses = filteredExpenses;
    final totalExpensesCount = displayedExpenses.length;
    final totalAmount = displayedExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    // Category breakdown calculation
    final Map<String, double> categorySums = {};
    for (var exp in displayedExpenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1000;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/expenses'),
          Expanded(
            child: (state.isLoading && state.expenses.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: width < 600 ? 12 : 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMob = constraints.maxWidth < 600;
                            final titleCol = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expense Tracker',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Record corporate payouts, monthly bills, employee payroll, and miscellaneous outflows.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );
                            final actionsRow = SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (canExportExpense)
                                    ExportButton(
                                    title: 'Expense Tracker',
                                    fileName: 'expense_tracker_export',
                                    headers: ['Expense ID', 'Expense Type', 'Comment', 'Date & Time', 'Paid By', 'Account', 'Amount (PKR)'],
                                    rows: state.filteredExpenses.map((e) {
                                      final account = accountsState.accounts.where((a) => a.id == e.accountId).firstOrNull;
                                      final accountName = account != null ? '${account.name} (${account.accountScope})' : 'Unknown Account';
                                      final paidBy = e.vendorName.isNotEmpty ? e.vendorName : 'Company';
                                      return [
                                        TransactionIdHelper.getExpenseId(e, state.expenses),
                                        e.category,
                                        e.description,
                                        _formatExpenseDateTime(e.date),
                                        paidBy,
                                        accountName,
                                        'Rs. ${e.amount.toStringAsFixed(0)}',
                                      ];
                                    }).toList(),
                                  ),
                                  if (canCreateExpense) ...[
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<ExpenseRecord>(
                                          context: context,
                                          builder: (context) => const _AddEditExpenseDialog(),
                                        );
                                        if (result != null) {
                                          ref.read(expensesProvider.notifier).addExpense(result);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Expense recorded successfully'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: context.success,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Record Expense'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                            if (isMob) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleCol,
                                  const SizedBox(height: 16),
                                  actionsRow,
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: titleCol),
                                const SizedBox(width: 16),
                                actionsRow,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMob = constraints.maxWidth < 600;
                            final cards = [
                              StatCard(
                                title: tr('Total Expenses'),
                                tooltipMessage: "Detailed statistics and information regarding ${tr('Total Expenses')}.",
                                value: 'Rs. ${totalAmount.toStringAsFixed(0)}',
                                icon: Icons.trending_down,
                                iconColor: context.error,
                                iconBgColor: context.errorLight,
                              ),
                              StatCard(
                                title: 'Transaction Count',
                                tooltipMessage: 'Detailed statistics and information regarding Transaction Count.',
                                value: '$totalExpensesCount Logs',
                                icon: Icons.receipt_long_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                              ),
                              StatCard(
                                title: tr('Top Category'),
                                tooltipMessage: "Detailed statistics and information regarding ${tr('Top Category')}.",
                                value: sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None',
                                icon: Icons.pie_chart_outline,
                                iconColor: context.warning,
                                iconBgColor: context.warningLight,
                              ),
                            ];

                            if (isMob) {
                              return GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.85,
                                ),
                                children: cards,
                              );
                            } else if (constraints.maxWidth >= 720) {
                              return Row(
                                children: [
                                  Expanded(child: cards[0]),
                                  const SizedBox(width: 16),
                                  Expanded(child: cards[1]),
                                  const SizedBox(width: 16),
                                  Expanded(child: cards[2]),
                                ],
                              );
                            } else {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    SizedBox(width: 240, child: cards[0]),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 240, child: cards[1]),
                                    const SizedBox(width: 16),
                                    SizedBox(width: 240, child: cards[2]),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Main Content (List/Table + Category Chart Sidebar)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Left: List of Expenses
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    // Search and filter panel
                                    GlassCard(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: width < 600
                                            ? Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: context.border, width: 1),
                                                      ),
                                                      child: TextField(
                                                        controller: _searchController,
                                                        onChanged: (val) {
                                                          ref.read(expensesProvider.notifier).setSearchQuery(val);
                                                          setState(() => _currentPage = 0);
                                                        },
                                                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                                                        decoration: InputDecoration(
                                                          hintText: tr('Search vendor, category...'),
                                                          hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                                          prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                                          suffixIcon: state.searchQuery.isNotEmpty
                                                              ? IconButton(
                                                                  icon: const Icon(Icons.clear, size: 16),
                                                                  color: context.textMuted,
                                                                  onPressed: () {
                                                                    _searchController.clear();
                                                                    ref.read(expensesProvider.notifier).setSearchQuery('');
                                                                    setState(() => _currentPage = 0);
                                                                  },
                                                                )
                                                              : null,
                                                          border: InputBorder.none,
                                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Stack(
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _showExpenseFilterBottomSheet(context),
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Container(
                                                          height: 40,
                                                          width: 40,
                                                          decoration: BoxDecoration(
                                                            color: (state.categoryFilter != 'All' || state.accountIdFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                                ? context.primaryColor.withValues(alpha: 0.15)
                                                                : (context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: (state.categoryFilter != 'All' || state.accountIdFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                                  ? context.primaryColor
                                                                  : context.border,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Icon(
                                                            Icons.filter_list,
                                                            size: 20,
                                                            color: (state.categoryFilter != 'All' || state.accountIdFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                                ? context.primaryColor
                                                                : context.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      if (state.categoryFilter != 'All' || state.accountIdFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                        Positioned(
                                                          right: 6,
                                                          top: 6,
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
                                              )
                                            : Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  // Search Input
                                                  SizedBox(
                                                    width: 240,
                                                    child: Container(
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: context.border, width: 1),
                                                      ),
                                                      child: TextField(
                                                        controller: _searchController,
                                                        onChanged: (val) {
                                                          ref.read(expensesProvider.notifier).setSearchQuery(val);
                                                          setState(() => _currentPage = 0);
                                                        },
                                                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                                                        decoration: InputDecoration(
                                                          hintText: tr('Search vendor, category...'),
                                                          hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                                          prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                                          border: InputBorder.none,
                                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Category Filter Dropdown
                                                  Container(
                                                    height: 40,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: context.border, width: 1),
                                                    ),
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: state.categoryFilter,
                                                        dropdownColor: context.cardBg,
                                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                                        items: [
                                                          'All',
                                                          'Salaries & Payroll',
                                                          'Salary Advances',
                                                          'Electricity & Utilities',
                                                          'Internet & Telecom',
                                                          'Rent & Occupancy',
                                                          'Bills',
                                                          'Supplies',
                                                          'Refreshments',
                                                          'Travel & Transport',
                                                          'Office Inventory',
                                                          'Assets Management',
                                                          'Marketing & Advertising',
                                                          'Office & Admin Expenses',
                                                          'Repairs & Maintenance',
                                                          'Depreciation',
                                                          'Bank Charges & Fees',
                                                          'Other',
                                                        ].map((c) {
                                                          return DropdownMenuItem<String>(
                                                            value: c,
                                                            child: Text(c == 'All' ? 'Category: All' : c),
                                                          );
                                                        }).toList(),
                                                        onChanged: (val) {
                                                          if (val != null) {
                                                            ref.read(expensesProvider.notifier).setCategoryFilter(val);
                                                            setState(() => _currentPage = 0);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  // Account Filter Dropdown
                                                  Container(
                                                    height: 40,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: context.border, width: 1),
                                                    ),
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: state.accountIdFilter,
                                                        dropdownColor: context.cardBg,
                                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                                        items: [
                                                          const DropdownMenuItem<String>(
                                                            value: 'All',
                                                            child: Text('Account: All'),
                                                          ),
                                                          ...accountsState.accounts.map((acc) {
                                                            final scopeLabel = acc.accountScope.isNotEmpty ? ' (${acc.accountScope})' : '';
                                                            return DropdownMenuItem<String>(
                                                              value: acc.id,
                                                              child: Text('${acc.name}$scopeLabel'),
                                                            );
                                                          }),
                                                        ],
                                                        onChanged: (val) {
                                                          if (val != null) {
                                                            ref.read(expensesProvider.notifier).setAccountIdFilter(val);
                                                            setState(() => _currentPage = 0);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  // From Date Button
                                                  OutlinedButton.icon(
                                                    onPressed: () async {
                                                      final picked = await showDatePicker(
                                                        context: context,
                                                        initialDate: state.fromDateFilter != null ? (DateTime.tryParse(state.fromDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                                        firstDate: DateTime(2020),
                                                        lastDate: DateTime(2030),
                                                      );
                                                      if (picked != null) {
                                                        final dateStr = picked.toIso8601String().substring(0, 10);
                                                        ref.read(expensesProvider.notifier).setDateRange(dateStr, state.toDateFilter);
                                                        setState(() => _currentPage = 0);
                                                      }
                                                    },
                                                    icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.fromDateFilter != null ? context.primaryColor : context.textMuted),
                                                    label: Text(
                                                      state.fromDateFilter != null ? 'From: ${state.fromDateFilter}' : 'From Date',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: state.fromDateFilter != null ? context.primaryColor : context.textSecondary,
                                                        fontWeight: state.fromDateFilter != null ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      minimumSize: const Size(0, 40),
                                                      side: BorderSide(color: state.fromDateFilter != null ? context.primaryColor : context.border),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      backgroundColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                    ),
                                                  ),

                                                  // To Date Button
                                                  OutlinedButton.icon(
                                                    onPressed: () async {
                                                      final picked = await showDatePicker(
                                                        context: context,
                                                        initialDate: state.toDateFilter != null ? (DateTime.tryParse(state.toDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                                        firstDate: DateTime(2020),
                                                        lastDate: DateTime(2030),
                                                      );
                                                      if (picked != null) {
                                                        final dateStr = picked.toIso8601String().substring(0, 10);
                                                        ref.read(expensesProvider.notifier).setDateRange(state.fromDateFilter, dateStr);
                                                        setState(() => _currentPage = 0);
                                                      }
                                                    },
                                                    icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.toDateFilter != null ? context.primaryColor : context.textMuted),
                                                    label: Text(
                                                      state.toDateFilter != null ? 'To: ${state.toDateFilter}' : 'To Date',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: state.toDateFilter != null ? context.primaryColor : context.textSecondary,
                                                        fontWeight: state.toDateFilter != null ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      minimumSize: const Size(0, 40),
                                                      side: BorderSide(color: state.toDateFilter != null ? context.primaryColor : context.border),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      backgroundColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                                    ),
                                                  ),

                                                  // Clear Filters Button
                                                  if (state.categoryFilter != 'All' || state.accountIdFilter != 'All' || state.searchQuery.isNotEmpty || state.fromDateFilter != null || state.toDateFilter != null)
                                                    TextButton.icon(
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        ref.read(expensesProvider.notifier).clearFilters();
                                                        setState(() => _currentPage = 0);
                                                      },
                                                      icon: Icon(Icons.filter_alt_off_outlined, size: 16, color: context.error),
                                                      label: Text(
                                                        'Clear Filters',
                                                        style: TextStyle(color: context.error, fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Expense DataTable
                                    state.filteredExpenses.isEmpty
                                        ? _buildEmptyState(context)
                                        : Container(
                                            decoration: BoxDecoration(
                                              color: context.cardBg,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: context.border),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Column(
                                                children: [
                                                  Scrollbar(
                                                    controller: _horizontalScrollController,
                                                    child: SingleChildScrollView(
                                                      controller: _horizontalScrollController,
                                                      scrollDirection: Axis.horizontal,
                                                      child: ConstrainedBox(
                                                        constraints: const BoxConstraints(minWidth: 970),
                                                        child: DataTable(
                                                          showCheckboxColumn: false,
                                                          columnSpacing: 14,
                                                          headingRowHeight: 46,
                                                          dataRowMaxHeight: 56,
                                                          headingRowColor: WidgetStateProperty.all(
                                                            context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                                          ),
                                                          columns: const [
                                                            DataColumn(label: SizedBox(width: 100, child: Text('Expense ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                             DataColumn(label: SizedBox(width: 115, child: Text('Expense Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                            DataColumn(label: SizedBox(width: 125, child: Text('Comment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                            DataColumn(label: SizedBox(width: 110, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                            DataColumn(label: SizedBox(width: 90, child: Text('Paid By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                            DataColumn(label: SizedBox(width: 110, child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                            DataColumn(label: SizedBox(width: 80, child: Align(alignment: Alignment.centerRight, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))),
                                                          ],
                                                          rows: paginatedExpenses.map((exp) {
                                                            final account = accountsState.accounts.where((a) => a.id == exp.accountId).firstOrNull;
                                                            final accountName = account?.name ?? 'Bank/Cash Account';
                                                            final accountScope = account?.accountScope ?? 'Company';
                                                            final ownerName = account?.ownerName ?? '';
                                                            final paidBy = exp.vendorName.isNotEmpty ? exp.vendorName : 'Company';

                                                            return DataRow(
                                                              onSelectChanged: (_) async {
                                                                final action = await showDialog<String>(
                                                                  context: context,
                                                                  builder: (context) => _ExpenseDetailsDialog(
                                                                    expense: exp,
                                                                    accountName: accountName,
                                                                    accountScope: accountScope,
                                                                    ownerName: ownerName,
                                                                  ),
                                                                );
                                                                if (action == 'edit' && context.mounted) {
                                                                  final updated = await showDialog<ExpenseRecord>(
                                                                    context: context,
                                                                    builder: (context) => _AddEditExpenseDialog(expense: exp),
                                                                  );
                                                                  if (updated != null && context.mounted) {
                                                                    try {
                                                                      await ref.read(expensesProvider.notifier).updateExpense(exp, updated);
                                                                      if (context.mounted) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(
                                                                            content: const Text('Expense updated successfully'),
                                                                            behavior: SnackBarBehavior.floating,
                                                                            backgroundColor: context.success,
                                                                          ),
                                                                        );
                                                                      }
                                                                    } catch (e) {
                                                                      if (context.mounted) {
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text('Error updating expense: $e'),
                                                                            behavior: SnackBarBehavior.floating,
                                                                            backgroundColor: context.error,
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              cells: [
                                                                // Expense ID
                                                                 DataCell(
                                                                   SizedBox(
                                                                     width: 100,
                                                                     child: Align(
                                                                       alignment: Alignment.centerLeft,
                                                                       child: Container(
                                                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                         decoration: BoxDecoration(
                                                                           color: context.isDarkMode ? const Color(0xFF111827) : Colors.grey.shade100,
                                                                           borderRadius: BorderRadius.circular(6),
                                                                           border: Border.all(color: context.border),
                                                                         ),
                                                                         child: Text(
                                                                           TransactionIdHelper.getExpenseId(exp, state.expenses),
                                                                           style: TextStyle(
                                                                             color: context.textPrimary,
                                                                             fontSize: 11.5,
                                                                             fontWeight: FontWeight.bold,
                                                                           ),
                                                                         ),
                                                                       ),
                                                                     ),
                                                                   ),
                                                                 ),
                                                                 // Expense Type
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 115,
                                                                    child: Align(
                                                                      alignment: Alignment.centerLeft,
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                        decoration: BoxDecoration(
                                                                          color: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFEFF6FF),
                                                                          borderRadius: BorderRadius.circular(6),
                                                                          border: Border.all(color: context.primaryColor.withValues(alpha: 0.3)),
                                                                        ),
                                                                        child: Text(
                                                                          exp.category,
                                                                          style: TextStyle(
                                                                            fontSize: 11,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: context.primaryColor,
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Comment / Description (fixed width, single line with tooltip)
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 125,
                                                                    child: Tooltip(
                                                                      message: exp.description.isNotEmpty ? exp.description : 'No comment entered',
                                                                      waitDuration: const Duration(milliseconds: 250),
                                                                      child: Text(
                                                                        exp.description.isEmpty ? '—' : exp.description,
                                                                        style: TextStyle(fontSize: 12, color: context.textPrimary),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Date & Time
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 110,
                                                                    child: Text(
                                                                      _formatExpenseDateTime(exp.date),
                                                                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Paid By
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 90,
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Icon(Icons.person_outline, size: 14, color: context.textMuted),
                                                                        const SizedBox(width: 4),
                                                                        Expanded(
                                                                          child: Text(
                                                                            paidBy,
                                                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textPrimary),
                                                                            overflow: TextOverflow.ellipsis,
                                                                            maxLines: 1,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Account
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 110,
                                                                    child: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          accountName,
                                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                                                                          overflow: TextOverflow.ellipsis,
                                                                          maxLines: 1,
                                                                        ),
                                                                        Text(
                                                                          accountScope,
                                                                          style: TextStyle(fontSize: 10, color: context.textMuted),
                                                                          overflow: TextOverflow.ellipsis,
                                                                          maxLines: 1,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Amount
                                                                DataCell(
                                                                  SizedBox(
                                                                    width: 80,
                                                                    child: Align(
                                                                      alignment: Alignment.centerRight,
                                                                      child: Text(
                                                                        'Rs. ${exp.amount.toStringAsFixed(0)}',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: context.error,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                // Action
                                                  // Action
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Pagination Bar
                                                  if (filteredExpenses.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border(top: BorderSide(color: context.border)),
                                                      ),
                                                      child: MediaQuery.sizeOf(context).width < 600
                                                          ? Column(
                                                              children: [
                                                                Text(
                                                                  'Showing ${filteredExpenses.isEmpty ? 0 : validPage * _rowsPerPage + 1}–${(validPage * _rowsPerPage + paginatedExpenses.length).clamp(0, filteredExpenses.length)} of ${filteredExpenses.length} entries',
                                                                  style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                                const SizedBox(height: 8),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: [
                                                                    IconButton(
                                                                      icon: const Icon(Icons.chevron_left, size: 20),
                                                                      onPressed: validPage > 0
                                                                          ? () => setState(() => _currentPage = validPage - 1)
                                                                          : null,
                                                                    ),
                                                                    Text(
                                                                      '${validPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                                                                      style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                                                    ),
                                                                    IconButton(
                                                                      icon: const Icon(Icons.chevron_right, size: 20),
                                                                      onPressed: validPage < totalPages - 1
                                                                          ? () => setState(() => _currentPage = validPage + 1)
                                                                          : null,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          : Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    'Showing ${filteredExpenses.isEmpty ? 0 : validPage * _rowsPerPage + 1}–${(validPage * _rowsPerPage + paginatedExpenses.length).clamp(0, filteredExpenses.length)} of ${filteredExpenses.length} entries',
                                                                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 8),
                                                                Row(
                                                                  children: [
                                                                    ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                                                        foregroundColor: context.textPrimary,
                                                                        elevation: 0,
                                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                      ),
                                                                      onPressed: validPage > 0
                                                                          ? () => setState(() => _currentPage = validPage - 1)
                                                                          : null,
                                                                      child: const Text('Previous', style: TextStyle(fontSize: 12)),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    for (int i = 0; i < totalPages; i++) ...[
                                                                      if (totalPages <= 7 || i == 0 || i == totalPages - 1 || (i >= validPage - 1 && i <= validPage + 1))
                                                                        InkWell(
                                                                          onTap: () => setState(() => _currentPage = i),
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                                                            decoration: BoxDecoration(
                                                                              color: i == validPage ? context.primaryColor : Colors.transparent,
                                                                              borderRadius: BorderRadius.circular(6),
                                                                              border: i == validPage ? null : Border.all(color: context.border),
                                                                            ),
                                                                            child: Text(
                                                                              '${i + 1}',
                                                                              style: TextStyle(
                                                                                color: i == validPage ? Colors.white : context.textPrimary,
                                                                                fontSize: 12,
                                                                                fontWeight: i == validPage ? FontWeight.bold : FontWeight.normal,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      else if (i == 1 && validPage > 3 || i == totalPages - 2 && validPage < totalPages - 4)
                                                                        const Padding(
                                                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                                                          child: Text('...', style: TextStyle(color: Colors.grey)),
                                                                        ),
                                                                    ],
                                                                    const SizedBox(width: 8),
                                                                    ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                                                        foregroundColor: context.textPrimary,
                                                                        elevation: 0,
                                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                      ),
                                                                      onPressed: validPage < totalPages - 1
                                                                          ? () => setState(() => _currentPage = validPage + 1)
                                                                          : null,
                                                                      child: const Text('Next', style: TextStyle(fontSize: 12)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  if (!isWide) ...[
                                    const SizedBox(height: 24),
                                    _buildCategoryBreakdown(context, theme, sortedCategories, totalAmount, isMobile: true),
                                  ],
                                  ],
                                ),
                              ),

                              // Right: Category breakdown sidebar (only on wider screens)
                              if (isWide) ...[
                                const SizedBox(width: 24),
                                _buildCategoryBreakdown(context, theme, sortedCategories, totalAmount, isMobile: false),
                              ],
                            ],
                          ),
                        ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, ThemeData theme, List<MapEntry<String, double>> sortedCategories, double totalAmount, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedCategories.isEmpty)
            Text('No data available', style: TextStyle(color: context.textSecondary))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCategories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final cat = sortedCategories[index];
                final pct = totalAmount > 0 ? cat.value / totalAmount : 0.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cat.key,
                            style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Rs. ${cat.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(color: context.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(context.error),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.money_off_outlined, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              'No Expenses Found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Record a new company expense payout log to start tracking.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


class _ExpenseDetailsDialog extends ConsumerWidget {
  final ExpenseRecord expense;
  final String accountName;
  final String accountScope;
  final String ownerName;

  const _ExpenseDetailsDialog({
    required this.expense,
    required this.accountName,
    required this.accountScope,
    required this.ownerName,
  });

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      try {
        final parsed = DateFormat('dd-MM-yyyy').parse(iso);
        return DateFormat('dd-MM-yyyy').format(parsed);
      } catch (_) {
        return iso;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDeleteExpense = ref.watch(adminProvider).hasPermission(AppModule.expenses, PermissionAction.delete);
    final canEditExpense = ref.watch(adminProvider).hasPermission(AppModule.expenses, PermissionAction.edit);
    final allExpenses = ref.watch(expensesProvider).expenses;
    final uniqueExpenseId = TransactionIdHelper.getExpenseId(expense, allExpenses);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final accountLabel = accountScope == 'Personal' && ownerName.isNotEmpty
        ? '$accountName • Personal ($ownerName)'
        : '$accountName • $accountScope';

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: context.errorLight,
                        child: Icon(Icons.trending_down, size: 18, color: context.error),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense Log Details',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: $uniqueExpenseId',
                            style: TextStyle(color: context.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Amount',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.error),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${expense.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.error),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.isPersonalExpense ? 'PERSONAL' : 'COMPANY',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    _detailRow(context, isMobile, 'Expense ID', uniqueExpenseId, Icons.receipt_long_outlined),
                    const Divider(height: 1),
                    _detailRow(context, isMobile, 'Category', expense.category, Icons.category_outlined),
                    const Divider(height: 1),
                    _detailRow(context, isMobile, 'Vendor / Beneficiary', expense.vendorName.isEmpty ? 'Not provided' : expense.vendorName, Icons.person_outline),
                    const Divider(height: 1),
                    _detailRow(context, isMobile, 'Paid From Account', accountLabel, Icons.account_balance_outlined),
                    const Divider(height: 1),
                    _detailRow(context, isMobile, 'Date Paid', _formatDate(expense.date), Icons.calendar_today_outlined),
                    const Divider(height: 1),
                    _detailRow(context, isMobile, 'Description / Notes', expense.description.isEmpty ? 'Not provided' : expense.description, Icons.notes_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  if (canDeleteExpense) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: const Text('Expense record deleted.'), backgroundColor: context.success),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: context.error),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                        label: Text('Delete', style: TextStyle(color: context.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (canEditExpense) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, 'edit'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit / Update', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Close', style: TextStyle(color: context.textSecondary, fontWeight: FontWeight.bold)),
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

  Widget _detailRow(BuildContext context, bool isMobile, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      SelectableText(value, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: SelectableText(value, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Smooth backspacing: if user is deleting, allow it without forcing re-addition of dashes
    if (newValue.text.length < oldValue.text.length) {
      if (oldValue.text.endsWith('-') && newValue.text.length == oldValue.text.length - 1) {
        final text = newValue.text.substring(0, newValue.text.length - 1);
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
      return newValue;
    }

    // Keep only numbers
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Maximum 8 digits: dd (2) + mm (2) + yyyy (4)
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i == 1 || i == 3) && i != limited.length - 1) {
        buffer.write('-');
      }
    }

    // Automatically append '-' after 2 digits (day) or 4 digits (month)
    if (limited.length == 2 || limited.length == 4) {
      buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddEditExpenseDialog extends ConsumerStatefulWidget {
  final ExpenseRecord? expense;
  const _AddEditExpenseDialog({this.expense});

  @override
  ConsumerState<_AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends ConsumerState<_AddEditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _descController;
  late final TextEditingController _dateController;

  String _category = 'Electricity & Utilities';
  String? _selectedAccountId;
  DateTime _date = DateTime.now();
  bool _isPersonalExpense = false;

  String _formatDateForDisplay(DateTime dt) {
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  DateTime _parseInputDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return DateTime.now();

    final formats = [
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'dd.MM.yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-dd HH:mm',
      'yyyy-MM-ddTHH:mm:ss',
      'yyyy-MM-ddTHH:mm',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parseStrict(trimmed);
      } catch (_) {
        try {
          return DateFormat(fmt).parse(trimmed);
        } catch (_) {}
      }
    }

    try {
      return DateTime.parse(trimmed);
    } catch (_) {}

    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _vendorController = TextEditingController(text: widget.expense?.vendorName ?? '');
    _descController = TextEditingController(text: widget.expense?.description ?? '');

    if (widget.expense != null) {
      _category = widget.expense!.category;
      _selectedAccountId = widget.expense!.accountId;
      final parsed = DateTime.tryParse(widget.expense!.date) ?? _parseInputDate(widget.expense!.date);
      _date = parsed;
      _dateController = TextEditingController(text: _formatDateForDisplay(parsed));
      _isPersonalExpense = widget.expense!.isPersonalExpense;
    } else {
      _date = DateTime.now();
      _dateController = TextEditingController(text: _formatDateForDisplay(_date));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 550;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Consumer(
          builder: (context, ref, child) {
            final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();

            final accountExists = accounts.any((a) => a.id == _selectedAccountId);
            if (!accountExists && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }

            final amountField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Amount Paid (Rs.)'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('e.g. 15000'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
              ],
            );

            final vendorField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Vendor / Beneficiary'),
                TextFormField(
                  controller: _vendorController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('e.g. K-Electric / Landlord'),
                ),
              ],
            );

            final accountField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Paid From Account'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedAccountId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Select Account'),
                  items: accounts.map((a) {
                    final scope = a.isPersonal
                        ? 'Personal${a.ownerName.isNotEmpty ? ' • ${a.ownerName}' : ''}'
                        : 'Company';
                    return DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} • $scope', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedAccountId = val);
                  },
                ),
              ],
            );

            final dateField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Date Paid'),
                    InkWell(
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          _date = now;
                          _dateController.text = _formatDateForDisplay(now);
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.today_outlined, size: 12, color: context.primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              'Today',
                              style: TextStyle(color: context.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _dateController,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    _DateTextFormatter(),
                  ],
                  decoration: _buildInputDecoration('DD-MM-YYYY (e.g. 29-10-2026)').copyWith(
                    suffixIcon: IconButton(
                      tooltip: 'Pick Date from Calendar',
                      icon: Icon(Icons.calendar_month_outlined, size: 20, color: context.primaryColor),
                      onPressed: () async {
                        final current = _parseInputDate(_dateController.text);
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: current,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (pickedDate != null && context.mounted) {
                          setState(() {
                            _date = pickedDate;
                            _dateController.text = _formatDateForDisplay(pickedDate);
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (val) {
                    _date = _parseInputDate(val);
                  },
                ),
              ],
            );

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
                        Expanded(
                          child: Text(
                            widget.expense == null ? 'Record Payout / Expense' : 'Edit Expense Log',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
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

                    // Category Select
                    _buildLabel('Expense Category'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _category,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Category'),
                      items: {
                        'Salaries & Payroll',
                        'Salary Advances',
                        'Electricity & Utilities',
                        'Internet & Telecom',
                        'Rent & Occupancy',
                        'Bills',
                        'Supplies',
                        'Refreshments',
                        'Travel & Transport',
                        'Office Inventory',
                        'Assets Management',
                        'Marketing & Advertising',
                        'Office & Admin Expenses',
                        'Repairs & Maintenance',
                        'Depreciation',
                        'Bank Charges & Fees',
                        'Other',
                        if (_category.isNotEmpty) _category,
                      }.map((c) {
                        return DropdownMenuItem<String>(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount & Vendor Name
                    if (isMobile) ...[
                      amountField,
                      const SizedBox(height: 16),
                      vendorField,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: amountField),
                          const SizedBox(width: 16),
                          Expanded(child: vendorField),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Payout Account & Date
                    if (isMobile) ...[
                      accountField,
                      const SizedBox(height: 16),
                      dateField,
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: accountField),
                          const SizedBox(width: 16),
                          Expanded(child: dateField),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Expense Type
                    _buildLabel('Expense Type'),
                    DropdownButtonFormField<bool>(
                      isExpanded: true,
                      initialValue: _isPersonalExpense,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Expense Type'),
                      items: const [
                        DropdownMenuItem(
                          value: false,
                          child: Text('Company Expense'),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Text('Personal Expense'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _isPersonalExpense = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description / Expense Notes'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Enter detail notes about this expense payout...'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
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
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() == true) {
                                final double expAmount = double.tryParse(_amountController.text) ?? 0.0;
                                final selectedAccount = accounts.firstWhere((a) => a.id == _selectedAccountId);
                                
                                double availableBalance = selectedAccount.balance;
                                if (widget.expense != null && widget.expense!.accountId == selectedAccount.id) {
                                  availableBalance += widget.expense!.amount;
                                }

                                if (expAmount > availableBalance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Insufficient Funds in ${selectedAccount.name}. Available: Rs. ${availableBalance.toStringAsFixed(0)}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.error,
                                    ),
                                  );
                                  return;
                                }

                                final now = DateTime.now();
                                final rawInput = _dateController.text.trim();
                                final DateTime chosenDate = rawInput.isEmpty ? now : _parseInputDate(rawInput);
                                final expenseDate = DateTime(chosenDate.year, chosenDate.month, chosenDate.day).toIso8601String();

                                final expense = ExpenseRecord(
                                  id: widget.expense?.id ?? 'exp_${now.millisecondsSinceEpoch}',
                                  date: expenseDate,
                                  amount: expAmount,
                                  accountId: _selectedAccountId!,
                                  category: _category,
                                  vendorName: _vendorController.text.trim(),
                                  description: _descController.text.trim(),
                                  isPersonalExpense: _isPersonalExpense,
                                );
                                Navigator.of(context).pop(expense);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(widget.expense == null ? tr('Record Outflow') : tr('Save Changes')),
                          ),
                        ],
                      ),
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

