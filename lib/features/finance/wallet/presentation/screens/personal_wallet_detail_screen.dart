import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/features/finance/loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';
import 'package:software_house_erp/features/finance/shared/widgets/transaction_detail_dialog.dart';
import '../widgets/personal_account_transaction_dialog.dart';
import '../widgets/settle_balance_dialog.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/core/utils/app_date_formatter.dart';

class PersonalWalletDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  const PersonalWalletDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<PersonalWalletDetailScreen> createState() =>
      _PersonalWalletDetailScreenState();
}

class _PersonalWalletDetailScreenState
    extends ConsumerState<PersonalWalletDetailScreen> {
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _typeFilter = 'All';
  int _currentPage = 0;
  static const int _rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final accountsState = ref.watch(accountsProvider);
    final expensesState = ref.watch(expensesProvider);
    final incomesState = ref.watch(incomeProvider);
    final loansState = ref.watch(loansProvider);
    final ledgerState = ref.watch(ledgerProvider);

    // ── Find the account by ID ─────────────────────────────────────
    final personalAccounts = accountsState.accounts
        .where((a) => a.isPersonal)
        .toList();

    final accountList =
        personalAccounts.where((a) => a.id == widget.accountId).toList();
    if (accountList.isEmpty) {
      // Account not found — go back
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.cardBg,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Account Not Found',
              style: TextStyle(color: context.textPrimary)),
        ),
        body: Center(
          child: Text('This account no longer exists.',
              style: TextStyle(color: context.textSecondary)),
        ),
      );
    }
    final account = accountList.first;
    final accountOwnerLabel =
        account.ownerName.isNotEmpty ? account.ownerName : account.name;

    // ── Compute Transaction Data ───────────────────────────────────
    final personalExpenses =
        expensesState.expenses.where((e) => e.accountId == account.id).toList();
    final personalIncomes =
        incomesState.incomes.where((i) => i.accountId == account.id).toList();
    // AutoExpense loans represent the company liability already linked to the
    // expense row; showing them here again would duplicate the personal cash outflow.
    final personalLoans = loansState.loans
      .where((l) =>
        (l.personalAccountId == account.id || (l.isPersonalExternalLoan && l.accountId == account.id)) &&
        !l.description.contains('[AutoExpense]'))
      .toList();
    final directAccountEntries = ledgerState.entries.where((entry) =>
      entry.accountId == account.id &&
      (entry.category == 'Personal Deposit' ||
       entry.category == 'Account Transfer' ||
       entry.category == 'Other Expense' ||
       entry.category == 'Balance Settlement')).toList();

    final directInflow = directAccountEntries
      .where((entry) => entry.type == 'Debit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);
    final directOutflow = directAccountEntries
      .where((entry) => entry.type == 'Credit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

    final internalLoans = personalLoans.where((l) => l.isInternalLoan).toList();
    final externalLoans = personalLoans.where((l) => l.isPersonalExternalLoan).toList();

    // Loan Inflows to Personal Account:
    final loansReceivedInflow =
        internalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (s, l) => s + l.amount) +
        externalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (s, l) => s + l.amount);

    final repaymentsReceivedInflow =
        internalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (s, r) => s + r.amount) +
        externalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (s, r) => s + r.amount);

    // Loan Outflows from Personal Account:
    final loansGivenOutflow =
        internalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (s, l) => s + l.amount) +
        externalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (s, l) => s + l.amount);

    final repaymentsPaidOutflow =
        internalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (s, r) => s + r.amount) +
        externalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (s, r) => s + r.amount);

    final pureIncomeTotal =
        personalIncomes.fold<double>(0.0, (s, i) => s + i.amount) + directInflow;
    final loansInflowTotal = loansReceivedInflow + repaymentsReceivedInflow;
    final totalInflow = account.openingBalance + pureIncomeTotal + loansInflowTotal;

    final pureExpenseTotal =
        personalExpenses.fold<double>(0.0, (s, e) => s + e.amount) + directOutflow;
    final loansOutflowTotal = loansGivenOutflow + repaymentsPaidOutflow;
    final totalExpense = pureExpenseTotal + loansOutflowTotal;

    final availableBalance = calculateAuthoritativeAccountBalance(
      account: account,
      incomes: incomesState.incomes,
      expenses: expensesState.expenses,
      loans: loansState.loans,
      ledgerEntries: ledgerState.entries,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final todayInflow = personalIncomes
            .where((i) => i.date.startsWith(todayStr))
            .fold<double>(0.0, (s, i) => s + i.amount) +
      directAccountEntries
          .where((entry) => entry.type == 'Debit' && entry.date.startsWith(todayStr))
          .fold<double>(0.0, (s, entry) => s + entry.amount) +
        personalLoans
            .where((l) =>
                l.type == 'Lent' && l.startDate.startsWith(todayStr))
            .fold<double>(0.0, (s, l) => s + l.amount) +
        personalLoans
            .where((l) => l.type == 'Borrowed')
            .expand((l) => l.repayments)
            .where((r) => r.date.startsWith(todayStr))
            .fold<double>(0.0, (s, r) => s + r.amount);
    final todayExpense = personalExpenses
            .where((e) => e.date.startsWith(todayStr))
            .fold<double>(0.0, (s, e) => s + e.amount) +
      directAccountEntries
          .where((entry) => entry.type == 'Credit' && entry.date.startsWith(todayStr))
          .fold<double>(0.0, (s, entry) => s + entry.amount) +
        personalLoans
            .where((l) =>
                l.type == 'Borrowed' && l.startDate.startsWith(todayStr))
            .fold<double>(0.0, (s, l) => s + l.amount) +
        personalLoans
            .where((l) => l.type == 'Lent')
            .expand((l) => l.repayments)
            .where((r) => r.date.startsWith(todayStr))
            .fold<double>(0.0, (s, r) => s + r.amount);
    final todayNet = todayInflow - todayExpense;

    // ── Build All Transactions ────────────────────────────────────
    final allTransactions = <_WalletTx>[
      if (account.openingBalance > 0)
        _WalletTx(
          id: 'opening_${account.id}',
          date: _openingBalanceDate(account),
          amount: account.openingBalance,
          type: 'Income',
          category: 'Opening Balance',
          description: 'Opening balance deposited when account was created',
          reference: 'Opening Balance',
          isPersonalExpense: false,
        ),
      ...directAccountEntries.map((entry) => _WalletTx(
        id: entry.id,
        date: entry.date,
        amount: entry.amount,
        type: entry.type == 'Debit' ? 'Income' : 'Expense',
        category: entry.category,
        description: entry.description,
        reference: entry.reference,
        isPersonalExpense: false,
          )),
      ...personalIncomes.map((i) => _WalletTx(
            id: i.id,
            date: i.date,
            amount: i.amount,
            type: 'Income',
            category: 'Project Payment',
            description: i.description.isNotEmpty
                ? i.description
                : 'Payment from ${i.clientName}',
            reference: i.clientName,
            isPersonalExpense: false,
          )),
      ...personalExpenses.map((e) => _WalletTx(
            id: e.id,
            date: e.date,
            amount: e.amount,
            type: 'Expense',
            category: e.category,
            description: e.description.isNotEmpty
                ? e.description
                : 'Expense to ${e.vendorName}',
            reference: e.vendorName,
            isPersonalExpense: e.isPersonalExpense,
          )),
      ...internalLoans.where((l) => l.type == 'Borrowed').map((l) => _WalletTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Expense',
            category: 'Loan to Company',
            description:
                'Company borrowed loan from personal funds: ${l.cleanDescription}',
            isPersonalExpense: true,
          )),
      ...internalLoans
          .where((l) => l.type == 'Borrowed')
          .expand((l) => l.repayments)
          .map((r) => _WalletTx(
                id: r.id,
                date: r.date,
                amount: r.amount,
                type: 'Income',
                category: 'Company Repayment',
                description: 'Company repaid loan installment',
                isPersonalExpense: false,
              )),
      ...internalLoans.where((l) => l.type == 'Lent').map((l) => _WalletTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Income',
            category: 'Loan from Company',
            description:
                'Advance / Loan received from Company: ${l.cleanDescription}',
            isPersonalExpense: false,
          )),
      ...internalLoans
          .where((l) => l.type == 'Lent')
          .expand((l) => l.repayments)
          .map((r) => _WalletTx(
                id: r.id,
                date: r.date,
                amount: r.amount,
                type: 'Expense',
                category: 'Repayment to Company',
                description: 'Repayment installment sent to Company',
                isPersonalExpense: true,
              )),
      ...externalLoans.where((l) => l.type == 'Borrowed').map((l) => _WalletTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Income',
            category: 'Personal Loan Borrowed',
            description:
                'Borrowed personal loan from ${l.borrowerName}: ${l.cleanDescription}',
            isPersonalExpense: false,
          )),
      ...externalLoans
          .where((l) => l.type == 'Borrowed')
          .expand((l) => l.repayments.map((r) => _WalletTx(
                id: r.id,
                date: r.date,
                amount: r.amount,
                type: 'Expense',
                category: 'Personal Loan Repayment',
                description: 'Repaid loan installment to ${l.borrowerName}',
                isPersonalExpense: true,
              ))),
      ...externalLoans.where((l) => l.type == 'Lent').map((l) => _WalletTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Expense',
            category: 'Personal Loan Lent',
            description:
                'Lent personal funds to ${l.borrowerName}: ${l.cleanDescription}',
            isPersonalExpense: true,
          )),
      ...externalLoans
          .where((l) => l.type == 'Lent')
          .expand((l) => l.repayments.map((r) => _WalletTx(
                id: r.id,
                date: r.date,
                amount: r.amount,
                type: 'Income',
                category: 'Personal Loan Repayment Recv',
                description: 'Received loan installment from ${l.borrowerName}',
                isPersonalExpense: false,
              ))),
    ];

    allTransactions.sort(_compareTransactionsNewestFirst);

    // ── Apply Filters ─────────────────────────────────────────────
    final filtered = allTransactions.where((t) {
      if (_typeFilter != 'All' && t.type != _typeFilter) return false;
      if (_startDate != null) {
        final d = DateTime.tryParse(t.date);
        if (d != null && d.isBefore(_startDate!)) return false;
      }
      if (_endDate != null) {
        final d = DateTime.tryParse(t.date);
        if (d != null &&
            d.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!t.description.toLowerCase().contains(q) &&
            !t.category.toLowerCase().contains(q) &&
            !t.amount.toString().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final totalPages = (filtered.length / _rowsPerPage).ceil();
    final validPage = totalPages == 0
      ? 0
      : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
    final paginatedTransactions = filtered
      .skip(validPage * _rowsPerPage)
      .take(_rowsPerPage)
      .toList();

    final canCreateTransaction = ref.watch(adminProvider).hasPermission(AppModule.accounts, PermissionAction.create);

    // ─────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              accountOwnerLabel,
              style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              account.name,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (canCreateTransaction)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final transaction = await showPersonalAccountTransactionDialog(
                    context,
                    personalAccountId: account.id,
                  );
                  if (transaction == null || !context.mounted) return;
                  try {
                    await recordPersonalAccountTransaction(ref, transaction);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Personal account transaction saved successfully.')),
                    );
                  } on StateError catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.message), backgroundColor: context.error),
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Add Transaction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Settle & Zero Balance',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => showSettleAccountBalanceDialog(
              context,
              ref: ref,
              account: account,
              currentBalance: availableBalance,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ExportButton(
              title: '$accountOwnerLabel Account Statement',
              fileName:
                  '${accountOwnerLabel.toLowerCase().replaceAll(' ', '_')}_wallet_export',
              headers: const [
                '#',
                'Date',
                'Description',
                'Reference',
                'Inflow',
                'Outflow',
              ],
              rows: filtered.asMap().entries.map((item) {
                final t = item.value;
                final isInflow = t.type == 'Income';
                return [
                  (item.key + 1).toString(),
                  AppDateFormatter.formatString(t.date),
                  t.description,
                  t.reference,
                  isInflow ? t.amount.toStringAsFixed(2) : '-',
                  isInflow ? '-' : t.amount.toStringAsFixed(2),
                ];
              }).toList(),
              customPdfExport: () async {
                final transactions = filtered.map((t) {
                  final isInflow = t.type == 'Income';
                  return <String, dynamic>{
                    'id': t.id,
                    'sortKey': t.id,
                    'date': DateTime.tryParse(t.date) ?? DateTime.now(),
                    'desc': t.description,
                    'ref': t.reference,
                    'inflow': isInflow ? t.amount : 0.0,
                    'outflow': isInflow ? 0.0 : t.amount,
                  };
                }).toList();
                final totalInflow = transactions.fold<double>(
                  0.0,
                  (sum, t) => sum + (t['inflow'] as double),
                );
                final totalOutflow = transactions.fold<double>(
                  0.0,
                  (sum, t) => sum + (t['outflow'] as double),
                );
                return ExportHelper.exportBankStatementPdf(
                  account: account,
                  transactions: transactions,
                  openingBalance: account.openingBalance,
                  totalInflow: totalInflow,
                  totalOutflow: totalOutflow,
                  closingBalance: account.balance,
                  totalIncomeTx: transactions.where((t) => (t['inflow'] as double) > 0).length,
                  totalExpenseTx: transactions.where((t) => (t['outflow'] as double) > 0).length,
                  includeVerification: false,
                  isPersonalStatement: true,
                  statementStartDate: _startDate,
                  statementEndDate: _endDate,
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account Overview Card Section (Matching UI Card Image) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Current Available Balance Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFFDBEAFE),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Available Balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.isDarkMode
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.formatAccountingBalance(availableBalance),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: availableBalance < 0
                                    ? (context.isDarkMode
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFDC2626))
                                    : (context.isDarkMode
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF2563EB)),
                              ),
                            ),
                            if (account.openingBalance > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Includes Rs. ${account.openingBalance.toStringAsFixed(0)} opening balance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.isDarkMode
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (availableBalance.abs() >= 0.01)
                            ElevatedButton.icon(
                              onPressed: () => showSettleAccountBalanceDialog(
                                context,
                                ref: ref,
                                account: account,
                                currentBalance: availableBalance,
                              ),
                              icon: const Icon(Icons.restart_alt_rounded, size: 16),
                              label: const Text('Zero Balance'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: availableBalance > 0
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                                  : const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 28,
                              color: context.isDarkMode
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Middle Row: Inflow & Outflow Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;

                    Widget buildOverviewCard({
                      required IconData icon,
                      required String title,
                      required String value,
                      required String subtext,
                      required Color accentColor,
                    }) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 16, color: accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtext,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final inflowWidget = buildOverviewCard(
                      icon: Icons.arrow_downward,
                      title: 'Total Inflow (All Time)',
                      value: 'Rs. ${totalInflow.toStringAsFixed(0)}',
                      subtext:
                          '${account.openingBalance > 0 ? "Opening: Rs. ${account.openingBalance.toStringAsFixed(0)} • " : ""}Income: Rs. ${pureIncomeTotal.toStringAsFixed(0)} • Loans: Rs. ${loansInflowTotal.toStringAsFixed(0)}',
                      accentColor: context.isDarkMode
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A),
                    );

                    final outflowWidget = buildOverviewCard(
                      icon: Icons.arrow_upward,
                      title: 'Total Outflow (All Time)',
                      value: 'Rs. ${totalExpense.toStringAsFixed(0)}',
                      subtext:
                          'Expenses: Rs. ${pureExpenseTotal.toStringAsFixed(0)} • Loans: Rs. ${loansOutflowTotal.toStringAsFixed(0)}',
                      accentColor: context.isDarkMode
                          ? const Color(0xFFF87171)
                          : const Color(0xFFDC2626),
                    );

                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: inflowWidget),
                          const SizedBox(width: 16),
                          Expanded(child: outflowWidget),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: inflowWidget),
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: outflowWidget),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 3. Today's Activity Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Activity",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 600;

                          Widget buildItem({
                            required IconData icon,
                            required String label,
                            required String value,
                            required Color iconBg,
                            required Color iconColor,
                            required Color valueColor,
                          }) {
                            return Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, size: 18, color: iconColor),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: valueColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          final item1 = buildItem(
                            icon: Icons.arrow_downward,
                            label: "Today's Inflow",
                            value: 'Rs. ${todayInflow.toStringAsFixed(0)}',
                            iconBg: context.isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFDCFCE7),
                            iconColor: context.isDarkMode
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                            valueColor: context.isDarkMode
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                          );

                          final item2 = buildItem(
                            icon: Icons.arrow_upward,
                            label: "Today's Outflow",
                            value: 'Rs. ${todayExpense.toStringAsFixed(0)}',
                            iconBg: context.isDarkMode
                                ? const Color(0xFF7F1D1D)
                                : const Color(0xFFFEE2E2),
                            iconColor: context.isDarkMode
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                            valueColor: context.isDarkMode
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                          );

                          final item3 = buildItem(
                            icon: Icons.drag_handle,
                            label: "Today's Net",
                            value:
                                'Rs. ${todayNet.abs().toStringAsFixed(0)}',
                            iconBg: context.isDarkMode
                                ? const Color(0xFF78350F)
                                : const Color(0xFFFEF3C7),
                            iconColor: context.isDarkMode
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                            valueColor: context.isDarkMode
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                          );

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: item1),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: context.border,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: item2,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: context.border,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: item3,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                item1,
                                const SizedBox(height: 12),
                                item2,
                                const SizedBox(height: 12),
                                item3,
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Ledger Header ───────────────────────────────────────
            if (MediaQuery.of(context).size.width < 600)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$accountOwnerLabel\'s Activity Ledger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showing transactions for $accountOwnerLabel only',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$accountOwnerLabel\'s Activity Ledger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Showing transactions for $accountOwnerLabel only',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Filters Bar ────────────────────────────────────────
            // ── Filters Bar (Full Width) ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;

                      final searchInput = SizedBox(
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF111827)
                                : context.scaffoldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() {
                              _searchQuery = v;
                              _currentPage = 0;
                            }),
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: tr('Search transactions...'),
                              hintStyle: TextStyle(
                                  fontSize: 13, color: context.textMuted),
                              prefixIcon: Icon(Icons.search,
                                  size: 18, color: context.textMuted),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      );

                      final dateRangePicker = InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange: _startDate != null &&
                                    _endDate != null
                                ? DateTimeRange(
                                    start: _startDate!, end: _endDate!)
                                : null,
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                              _currentPage = 0;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF111827)
                                : context.scaffoldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: context.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${AppDateFormatter.format(_startDate)} – ${AppDateFormatter.format(_endDate)}'
                                    : tr('Date Range'),
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );

                      final typeFilterDropdown = Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF111827)
                              : context.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _typeFilter,
                            dropdownColor: context.cardBg,
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            items: [
                              DropdownMenuItem(
                                  value: 'All', child: Text(tr('All Types'))),
                              DropdownMenuItem(
                                  value: 'Income',
                                  child: Text(tr('Inflow (Debit)'))),
                              DropdownMenuItem(
                                  value: 'Expense',
                                  child: Text(tr('Outflow (Credit)'))),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _typeFilter = v;
                                  _currentPage = 0;
                                });
                              }
                            },
                          ),
                        ),
                      );

                      final clearButton = SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _startDate = null;
                            _endDate = null;
                            _typeFilter = 'All';
                            _currentPage = 0;
                          }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: BorderSide(color: context.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Clear',
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );

                      if (isWide) {
                        return Row(
                          children: [
                            Expanded(child: searchInput),
                            const SizedBox(width: 12),
                            dateRangePicker,
                            const SizedBox(width: 12),
                            typeFilterDropdown,
                            const SizedBox(width: 12),
                            clearButton,
                          ],
                        );
                      } else {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(width: double.infinity, child: searchInput),
                            dateRangePicker,
                            typeFilterDropdown,
                            clearButton,
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Ledger Table ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: max(850.0, tableConstraints.maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border:
                          Border(bottom: BorderSide(color: context.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Text('Type',
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 3,
                            child: Text('Description',
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Row(children: [
                              Text('Date',
                                  style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_downward,
                                  size: 14, color: context.textPrimary),
                            ])),
                          Expanded(
                            flex: 2,
                            child: Text('Account',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                        Expanded(
                            flex: 2,
                            child: Text('Category',
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                              Expanded(
                                flex: 2,
                                child: Text('Reference',
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Amount',
                                style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: context.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'No Transactions Logged',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Audit logs will appear here once cash movements are registered.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: paginatedTransactions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final tx = paginatedTransactions[index];
                        final isIncome = tx.type == 'Income';
                        final color =
                            isIncome ? context.success : context.error;
                        final bgColor = isIncome
                            ? context.successLight
                            : context.errorLight;

                        return InkWell(
                          onTap: () {
                            TransactionDetailDialog.show(
                              context,
                              id: tx.id,
                              title: tx.description,
                              category: tx.category,
                              description: tx.description,
                              amount: tx.amount,
                              date: tx.date,
                              type: tx.type,
                              accountName: account.name,
                              accountScope: 'Personal',
                              reference: tx.reference,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 14,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.description,
                                          style: TextStyle(
                                              color: context.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      if (!isIncome)
                                        Text(
                                            tx.isPersonalExpense
                                                ? 'Personal Expense'
                                                : 'Company Expense (Paid from Personal)',
                                            style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: _buildDateAndTimeCell(
                                      context, tx.date, tx.id),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    account.name,
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode
                                          ? const Color(0xFF1E293B)
                                          : Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      border:
                                          Border.all(color: context.border),
                                    ),
                                    child: Text(
                                      tx.category,
                                      style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    tx.reference,
                                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Rs. ${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: isIncome
                                              ? context.success
                                              : context.error,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ),
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
                      );
                    },
                  ),
                  if (filtered.isNotEmpty && totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MediaQuery.of(context).size.width < 600
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.end,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _openingBalanceDate(BankAccount account) {
    if (account.openingBalanceDate.isNotEmpty) {
      return account.openingBalanceDate;
    }
    final digits = account.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 13) {
      final timestamp = int.tryParse(digits.substring(digits.length - 13));
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
      }
    }
    return DateTime.now().toIso8601String();
  }

  Widget _buildDateAndTimeCell(BuildContext context, String rawDate, String txId) {
    final dt = _resolveTransactionDate(rawDate, txId);
    final dateStr = AppDateFormatter.formatString(rawDate);
    String timeStr = '12:00 PM';
    if (dt != null) {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      timeStr = '$hour:$min $period';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          dateStr,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          timeStr,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  int _compareTransactionsNewestFirst(_WalletTx a, _WalletTx b) {
    final isAOpening = a.id.startsWith('opening_') || a.category == 'Opening Balance';
    final isBOpening = b.id.startsWith('opening_') || b.category == 'Opening Balance';
    if (isAOpening && !isBOpening) return 1;
    if (!isAOpening && isBOpening) return -1;

    final dateA = _resolveTransactionDate(a.date, a.id) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = _resolveTransactionDate(b.date, b.id) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dateComparison = dateB.compareTo(dateA);
    if (dateComparison != 0) return dateComparison;

    final aDigits = a.id.replaceAll(RegExp(r'[^0-9]'), '');
    final bDigits = b.id.replaceAll(RegExp(r'[^0-9]'), '');
    final aNumber = BigInt.tryParse(aDigits) ?? BigInt.zero;
    final bNumber = BigInt.tryParse(bDigits) ?? BigInt.zero;
    final idComparison = bNumber.compareTo(aNumber);
    return idComparison != 0 ? idComparison : b.id.compareTo(a.id);
  }

  DateTime? _resolveTransactionDate(String value, String id) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    if (value.contains('T')) return parsed;

    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 13) {
      final timestamp = int.tryParse(digits.substring(digits.length - 13));
      final createdAt = timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (createdAt != null) {
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          createdAt.hour,
          createdAt.minute,
          createdAt.second,
          createdAt.millisecond,
        );
      }
    }
    return parsed;
  }
}

class _WalletTx {
  final String id;
  final String date;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String reference;
  final bool isPersonalExpense;

  _WalletTx({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    this.reference = '-',
    required this.isPersonalExpense,
  });
}
