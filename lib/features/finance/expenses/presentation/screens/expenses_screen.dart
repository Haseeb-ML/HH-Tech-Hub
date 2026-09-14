import 'package:flutter/material.dart';
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

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  static const int _rowsPerPage = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final tr = ref.watch(translationProvider);
    final state = ref.watch(expensesProvider);
    final accountsState = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final filteredExpenses = state.filteredExpenses;
    final totalPages = (filteredExpenses.length / _rowsPerPage).ceil();
    final validPage = totalPages == 0
      ? 0
      : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
    final paginatedExpenses = filteredExpenses
      .skip(validPage * _rowsPerPage)
      .take(_rowsPerPage)
      .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expensesProvider.notifier).syncAssetsAndInventoryExpenses();
    });

    // Calculate metrics
    final companyExpenses = state.expenses.where((e) => !e.isPersonalExpense).toList();
    final totalExpenses = companyExpenses.length;
    final totalAmount = companyExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    // Category breakdown calculation
    final Map<String, double> categorySums = {};
    for (var exp in companyExpenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1000;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.expenses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const FinanceSubNav(activeRoute: '/finance/expenses'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
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
                            ),
                            Row(
                              children: [
                                ExportButton(
                                  title: 'Expense Tracker',
                                  fileName: 'expense_tracker_export',
                                  headers: ['Expense ID', tr('Date'), 'Amount', 'Account ID', tr('Category'), 'Vendor Name', tr('Description')],
                                  rows: state.filteredExpenses.map((e) => [
                                    e.id,
                                    e.date,
                                    'Rs. ${e.amount.toStringAsFixed(2)}',
                                    e.accountId,
                                    e.category,
                                    e.vendorName,
                                    e.description,
                                  ]).toList(),
                                ),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cards = [
                              SizedBox(
                                width: constraints.maxWidth >= 720 ? null : 240,
                                child: StatCard(
                                  title: tr('Total Expenses'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Total Expenses')}.",
                                  value: 'Rs. ${totalAmount.toStringAsFixed(0)}',
                                  icon: Icons.trending_down,
                                  iconColor: context.error,
                                  iconBgColor: context.errorLight,
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth >= 720 ? null : 240,
                                child: StatCard(
                                  title: 'Transaction Count',
                                  tooltipMessage: 'Detailed statistics and information regarding Transaction Count.',
                                  value: '$totalExpenses Logs',
                                  icon: Icons.receipt_long_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth >= 720 ? null : 240,
                                child: StatCard(
                                  title: tr('Top Category'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Top Category')}.",
                                  value: sortedCategories.isNotEmpty ? sortedCategories.first.key : 'None',
                                  icon: Icons.pie_chart_outline,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                              ),
                            ];

                            if (constraints.maxWidth >= 720) {
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
                                    cards[0],
                                    const SizedBox(width: 16),
                                    cards[1],
                                    const SizedBox(width: 16),
                                    cards[2],
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Main Content (List + Category Chart Sidebar)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Left: List of Expenses
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    // Search and filter row
                                    GlassCard(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
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
                                                  onChanged: (val) {
                                                    ref.read(expensesProvider.notifier).setSearchQuery(val);
                                                    setState(() => _currentPage = 0);
                                                  },
                                                  style: TextStyle(color: context.textPrimary),
                                                  decoration: InputDecoration(
                                                    hintText: tr('Search by vendor, category or description...'),
                                                    hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
                                                    prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                                    border: InputBorder.none,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
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
                                                    'Rent',
                                                    tr('Salaries'),
                                                    'Bills',
                                                    'Internet',
                                                    'Electricity',
                                                    'Supplies',
                                                    'Refreshments',
                                                    'Travel',
                                                    'Office Inventory',
                                                    'Assets Management',
                                                    'Other',
                                                  ].map((c) {
                                                    return DropdownMenuItem<String>(
                                                      value: c,
                                                      child: Text('${tr("Category")}: $c'),
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
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // ListView
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
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: paginatedExpenses.length,
                                                separatorBuilder: (context, index) => const Divider(height: 1),
                                                itemBuilder: (context, index) {
                                                  final exp = paginatedExpenses[index];
                                                  final account = accountsState.accounts.where((a) => a.id == exp.accountId).firstOrNull;
                                                  return _ExpenseListTile(
                                                    expense: exp,
                                                    accountName: account?.name ?? 'Unknown',
                                                    accountScope: account?.accountScope ?? 'Company',
                                                    ownerName: account?.ownerName ?? '',
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                    if (filteredExpenses.isNotEmpty && totalPages > 1)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Page ${validPage + 1} of $totalPages',
                                              style: TextStyle(color: context.textSecondary, fontSize: 12),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'Previous page',
                                              onPressed: validPage > 0
                                                  ? () => setState(() => _currentPage = validPage - 1)
                                                  : null,
                                              icon: const Icon(Icons.chevron_left),
                                            ),
                                            IconButton(
                                              tooltip: 'Next page',
                                              onPressed: validPage < totalPages - 1
                                                  ? () => setState(() => _currentPage = validPage + 1)
                                                  : null,
                                              icon: const Icon(Icons.chevron_right),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Right: Category breakdown sidebar (only on wider screens)
                              if (isWide) ...[
                                const SizedBox(width: 24),
                                Container(
                                  width: 320,
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
                                                        Text(
                                                          cat.key,
                                                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
                                ),
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

class _ExpenseListTile extends ConsumerWidget {
  final ExpenseRecord expense;
  final String accountName;
  final String accountScope;
  final String ownerName;

  const _ExpenseListTile({
    required this.expense,
    required this.accountName,
    required this.accountScope,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => _ExpenseDetailsDialog(
            expense: expense,
            accountName: accountName,
            accountScope: accountScope,
            ownerName: ownerName,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.errorLight,
            child: Icon(
              Icons.trending_down,
              size: 16,
              color: context.error,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      expense.category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    if (expense.isPersonalExpense) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.warningLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.warning.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Owner Drawings',
                          style: TextStyle(fontSize: 9, color: context.warning, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (expense.vendorName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expense.vendorName,
                          style: TextStyle(fontSize: 9, color: context.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  expense.description,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatExpenseDate(expense.date),
                      style: TextStyle(color: context.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: context.textMuted, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paid from: $accountName • $accountScope${accountScope == 'Personal' && ownerName.isNotEmpty ? ' ($ownerName)' : ''}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Amount & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '- Rs. ${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: context.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog<ExpenseRecord>(
                        context: context,
                        builder: (context) => _AddEditExpenseDialog(expense: expense),
                      );
                      if (result != null) {
                        ref.read(expensesProvider.notifier).updateExpense(expense, result);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Expense updated successfully.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.success,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Edit',
                      style: TextStyle(color: context.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Expense Log'),
                          content: Text('${tr("Are you sure you want to delete this expense record for")} "${expense.category}"? ${tr("This will rollback account balance and ledger entry.")}'),
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
                        ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Expense deleted and rolls rolled back.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.error,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: context.error, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _ExpenseDetailsDialog extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final accountLabel = accountScope == 'Personal' && ownerName.isNotEmpty
        ? '$accountName • Personal ($ownerName)'
        : '$accountName • $accountScope';

    return AlertDialog(
      title: const Text('Expense Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(context, 'Expense ID', expense.id),
            _detailRow(context, 'Category', expense.category),
            _detailRow(context, 'Amount', 'Rs. ${expense.amount.toStringAsFixed(2)}'),
            _detailRow(context, 'Vendor / Beneficiary', expense.vendorName.isEmpty ? 'Not provided' : expense.vendorName),
            _detailRow(context, 'Paid From Account', accountLabel),
            _detailRow(context, 'Date Paid', _formatExpenseDate(expense.date)),
            _detailRow(context, 'Description', expense.description.isEmpty ? 'Not provided' : expense.description),
            _detailRow(context, 'Expense Type', expense.isPersonalExpense ? 'Personal Expense' : 'Company Expense'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
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

  String _category = 'Rent';
  String? _selectedAccountId;
  DateTime _date = DateTime.now();
  bool _isPersonalExpense = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    _vendorController = TextEditingController(text: widget.expense?.vendorName ?? '');
    _descController = TextEditingController(text: widget.expense?.description ?? '');

    if (widget.expense != null) {
      _category = widget.expense!.category;
      _selectedAccountId = widget.expense!.accountId;
      _date = DateTime.tryParse(widget.expense!.date) ?? DateTime.now();
      _isPersonalExpense = widget.expense!.isPersonalExpense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, child) {
            final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();

            final accountExists = accounts.any((a) => a.id == _selectedAccountId);
            if (!accountExists && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }

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
                          widget.expense == null ? 'Record Payout / Expense' : 'Edit Expense Log',
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

                    // Category Select
                    _buildLabel('Expense Category'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _category,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Category'),
                      items: {
                        'Rent & Occupancy',
                        'Salaries & Payroll',
                        'Electricity & Utilities',
                        'Internet & Telecom',
                        'Transport & Logistics',
                        'Marketing & Advertising',
                        'Office & Admin Expenses',
                        'Repairs & Maintenance',
                        'Depreciation',
                        'Bank Charges & Fees',
                        'Rent',
                        'Salaries',
                        'Bills',
                        'Supplies',
                        'Refreshments',
                        'Travel',
                        'Other',
                        if (_category.isNotEmpty) _category,
                      }.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount & Vendor Name
                    Row(
                      children: [
                        Expanded(
                          child: Column(
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Vendor / Beneficiary'),
                              TextFormField(
                                controller: _vendorController,
                                style: TextStyle(color: context.textPrimary),
                                decoration: _buildInputDecoration('e.g. K-Electric / Landlord'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payout Account & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
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
                                  final scope = a.accountScope == 'Personal'
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('Date Paid')),
                              OutlinedButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _date = picked);
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
                                      _date.toIso8601String().substring(0, 10),
                                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    ),
                                    Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                              final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;
                              final expenseDate = (widget.expense != null && !isToday && widget.expense!.date.startsWith(_date.toIso8601String().substring(0, 10)))
                                  ? widget.expense!.date
                                  : (isToday ? now.toIso8601String() : DateTime(_date.year, _date.month, _date.day, 12, 0, 0).toIso8601String());

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

String _formatExpenseDate(String isoString) {
  try {
    final d = DateTime.parse(isoString);
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final hasExplicitTime = isoString.contains('T') || isoString.contains(' ');
    final isMidnight = d.hour == 0 && d.minute == 0 && d.second == 0;
    final isSyntheticNoon = d.hour == 12 && d.minute == 0 && isoString.endsWith('T12:00:00.000');

    if (!hasExplicitTime || isMidnight || isSyntheticNoon) {
      return date;
    }

    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$date • $hour:$minute $period';
  } catch (_) {
    return isoString.split('T').first;
  }
}
