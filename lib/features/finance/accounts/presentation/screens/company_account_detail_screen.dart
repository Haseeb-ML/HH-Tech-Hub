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
import '../widgets/company_account_transaction_dialog.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/core/utils/app_date_formatter.dart';

class CompanyAccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;
  const CompanyAccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<CompanyAccountDetailScreen> createState() =>
      _CompanyAccountDetailScreenState();
}

class _CompanyAccountDetailScreenState
    extends ConsumerState<CompanyAccountDetailScreen> {
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

    final companyAccounts = accountsState.accounts
        .where((a) => a.isCompany)
        .toList();

    final accountList =
        companyAccounts.where((a) => a.id == widget.accountId).toList();
    if (accountList.isEmpty) {
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

    // ── Compute Calculations ───────────────────────────────────────
    final companyExpenses =
        expensesState.expenses.where((e) => e.accountId == account.id).toList();
    final companyIncomes =
        incomesState.incomes.where((i) => i.accountId == account.id).toList();
    final companyLoans = loansState.loans
        .where((l) => l.accountId == account.id || l.resolvedAccountId == account.id)
        .toList();
    final directAccountEntries = ledgerState.entries.where((entry) =>
        entry.accountId == account.id &&
        (entry.category == 'Account Transfer' ||
         entry.category == 'Personal Deposit' ||
         entry.category == 'Company Deposit' ||
         entry.category == 'Salary Advance' ||
         entry.category == 'Other Expense' ||
         entry.category == 'Balance Settlement')).toList();

    final directInflow = directAccountEntries
        .where((entry) => entry.type == 'Debit')
        .fold<double>(0.0, (sum, entry) => sum + entry.amount);
    final directOutflow = directAccountEntries
        .where((entry) => entry.type == 'Credit')
        .fold<double>(0.0, (sum, entry) => sum + entry.amount);

    final loansReceivedInflow = companyLoans
        .where((l) => l.type == 'Borrowed')
        .fold<double>(0.0, (s, l) => s + l.amount);
    final repaymentsReceivedInflow = loansState.loans
        .where((l) => l.type == 'Lent')
        .expand((l) => l.repayments)
        .where((r) => r.accountId == account.id)
        .fold<double>(0.0, (s, r) => s + r.amount);

    final loansGivenOutflow = companyLoans
        .where((l) => l.type == 'Lent')
        .fold<double>(0.0, (s, l) => s + l.amount);
    final repaymentsPaidOutflow = loansState.loans
        .where((l) => l.type == 'Borrowed')
        .expand((l) => l.repayments)
        .where((r) => r.accountId == account.id)
        .fold<double>(0.0, (s, r) => s + r.amount);

    final pureIncomeTotal =
        companyIncomes.fold<double>(0.0, (s, i) => s + i.amount) + directInflow;
    final loansInflowTotal = loansReceivedInflow + repaymentsReceivedInflow;

    final pureExpenseTotal =
        companyExpenses.fold<double>(0.0, (s, e) => s + e.amount) + directOutflow;
    final loansOutflowTotal = loansGivenOutflow + repaymentsPaidOutflow;
    final totalExpense = pureExpenseTotal + loansOutflowTotal;

    final initialBal = account.openingBalance > 0
        ? account.openingBalance
        : ((pureIncomeTotal == 0 && pureExpenseTotal == 0 && loansInflowTotal == 0 && loansOutflowTotal == 0)
            ? account.balance
            : 0.0);
    final totalInflow = initialBal + pureIncomeTotal + loansInflowTotal;

    final availableBalance = totalInflow - totalExpense;

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final todayInflow = companyIncomes
            .where((i) => i.date.startsWith(todayStr))
            .fold<double>(0.0, (s, i) => s + i.amount) +
        directAccountEntries
            .where((entry) => entry.type == 'Debit' && entry.date.startsWith(todayStr))
            .fold<double>(0.0, (s, entry) => s + entry.amount) +
        companyLoans
            .where((l) => l.type == 'Borrowed' && l.startDate.startsWith(todayStr))
            .fold<double>(0.0, (s, l) => s + l.amount) +
        loansState.loans
            .where((l) => l.type == 'Lent')
            .expand((l) => l.repayments)
            .where((r) => r.accountId == account.id && r.date.startsWith(todayStr))
            .fold<double>(0.0, (s, r) => s + r.amount);

    final todayExpense = companyExpenses
            .where((e) => e.date.startsWith(todayStr))
            .fold<double>(0.0, (s, e) => s + e.amount) +
        directAccountEntries
            .where((entry) => entry.type == 'Credit' && entry.date.startsWith(todayStr))
            .fold<double>(0.0, (s, entry) => s + entry.amount) +
        companyLoans
            .where((l) => l.type == 'Lent' && l.startDate.startsWith(todayStr))
            .fold<double>(0.0, (s, l) => s + l.amount) +
        loansState.loans
            .where((l) => l.type == 'Borrowed')
            .expand((l) => l.repayments)
            .where((r) => r.accountId == account.id && r.date.startsWith(todayStr))
            .fold<double>(0.0, (s, r) => s + r.amount);

    final todayNet = todayInflow - todayExpense;

    // ── Build All Transactions ────────────────────────────────────
    final allTransactions = <_CompanyTx>[
      if (account.openingBalance > 0)
        _CompanyTx(
          id: 'opening_${account.id}',
          date: _openingBalanceDate(account),
          amount: account.openingBalance,
          type: 'Income',
          category: 'Opening Balance',
          description: 'Opening balance deposited when account was created',
          reference: 'Opening Balance',
          canManageInAccount: true,
        ),
      ...directAccountEntries.map((entry) => _CompanyTx(
            id: entry.id,
            date: entry.date,
            amount: entry.amount,
            type: entry.type == 'Debit' ? 'Income' : 'Expense',
            category: entry.category,
            description: entry.description,
            reference: entry.reference,
            canManageInAccount: true,
          )),
      ...companyIncomes.map((i) => _CompanyTx(
            id: i.id,
            date: i.date,
            amount: i.amount,
            type: 'Income',
            category: 'Client Revenue',
            description: i.description.isNotEmpty
                ? i.description
                : 'Payment from ${i.clientName}',
            reference: i.clientName,
          )),
      ...companyExpenses.map((e) => _CompanyTx(
            id: e.id,
            date: e.date,
            amount: e.amount,
            type: 'Expense',
            category: e.category,
            description: e.description.isNotEmpty
                ? e.description
                : 'Expense to ${e.vendorName}',
            reference: e.vendorName,
          )),
      ...companyLoans.where((l) => l.type == 'Borrowed').map((l) => _CompanyTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Income',
            category: 'Borrowed Credit',
            description: 'Loan / Credit line borrowed into account: ${l.cleanDescription}',
            reference: 'Loan #${l.id.length > 4 ? l.id.substring(l.id.length - 4) : l.id}',
          )),
      ...companyLoans.where((l) => l.type == 'Lent').map((l) => _CompanyTx(
            id: l.id,
            date: l.startDate,
            amount: l.amount,
            type: 'Expense',
            category: 'Advance Outflow',
            description: 'Advance / Loan lent out from account: ${l.cleanDescription}',
            reference: 'Loan #${l.id.length > 4 ? l.id.substring(l.id.length - 4) : l.id}',
          )),
      ...loansState.loans
          .where((l) => l.type == 'Lent')
          .expand((l) => l.repayments.map((r) => MapEntry(l, r)))
          .where((e) => e.value.accountId == account.id)
          .map((e) => _CompanyTx(
                id: e.value.id,
                date: e.value.date,
                amount: e.value.amount,
                type: 'Income',
                category: 'Loan Repayment Inflow',
                description: 'Received loan repayment / return from ${e.key.borrowerName}',
                reference: e.key.borrowerName,
              )),
      ...loansState.loans
          .where((l) => l.type == 'Borrowed')
          .expand((l) => l.repayments.map((r) => MapEntry(l, r)))
          .where((e) => e.value.accountId == account.id)
          .map((e) => _CompanyTx(
                id: e.value.id,
                date: e.value.date,
                amount: e.value.amount,
                type: 'Expense',
                category: 'Loan Repayment Outflow',
                description: 'Paid loan repayment to ${e.key.borrowerName}',
                reference: e.key.borrowerName,
              )),
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
        if (d != null && d.isAfter(_endDate!.add(const Duration(days: 1)))) {
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
              account.name,
              style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              account.type == 'Cash'
                  ? 'Company Cash Vault'
                  : '${account.bankName} • ${account.accountNumber}',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (canCreateTransaction)
            IconButton(
              tooltip: 'Add Transaction',
              icon: const Icon(Icons.add_card_outlined),
            onPressed: () async {
              final transaction = await showCompanyAccountTransactionDialog(
                context,
                companyAccountId: account.id,
              );
              if (transaction == null || !context.mounted) return;
              try {
                await recordCompanyAccountTransaction(ref, transaction);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction saved successfully.')),
                );
              } on StateError catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.message), backgroundColor: context.error),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ExportButton(
              title: '${account.name} Statement',
              fileName: '${account.name.toLowerCase().replaceAll(' ', '_')}_statement',
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
                return ExportHelper.exportBankStatementPdf(
                  account: account,
                  transactions: transactions,
                  openingBalance: account.openingBalance,
                  totalInflow: totalInflow,
                  totalOutflow: totalExpense,
                  closingBalance: availableBalance,
                  totalIncomeTx: transactions.where((t) => (t['inflow'] as double) > 0).length,
                  totalExpenseTx: transactions.where((t) => (t['outflow'] as double) > 0).length,
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
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary Cards (Pixel Match to Card Image) ────────────
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
                            const SizedBox(height: 6),
                            Text(
                              account.openingBalance > 0
                                  ? 'Includes Rs. ${account.openingBalance.toStringAsFixed(0)} opening balance'
                                  : 'Official reconciled company balance for this account',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.isDarkMode
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
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
                ),
                const SizedBox(height: 16),

                // 2. Middle Row: Total Inflow & Total Outflow
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
                          '${account.openingBalance > 0 ? "Opening: Rs. ${account.openingBalance.toStringAsFixed(0)} • " : ""}Income: Rs. ${(pureIncomeTotal - directInflow).toStringAsFixed(0)} • Transfers: Rs. ${directInflow.toStringAsFixed(0)} • Loans: Rs. ${loansInflowTotal.toStringAsFixed(0)}',
                      accentColor: context.isDarkMode
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A),
                    );

                    final outflowWidget = buildOverviewCard(
                      icon: Icons.arrow_upward,
                      title: 'Total Outflow (All Time)',
                      value: 'Rs. ${totalExpense.toStringAsFixed(0)}',
                      subtext:
                          'Expenses: Rs. ${(pureExpenseTotal - directOutflow).toStringAsFixed(0)} • Transfers: Rs. ${directOutflow.toStringAsFixed(0)} • Loans: Rs. ${loansOutflowTotal.toStringAsFixed(0)}',
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
                    '${account.name}\'s Activity Ledger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showing transactions for ${account.name} only',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${account.name}\'s Activity Ledger',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    'Showing transactions for ${account.name} only',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
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
                          width: max(960.0, tableConstraints.maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header
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
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Center(
                                        child: Text('Actions',
                                            style: TextStyle(
                                                color: context.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Table Body
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
                                  separatorBuilder: (_, index) => const Divider(height: 1),
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
                                          accountScope: 'Company',
                                          reference: tx.reference,
                                          onDelete: tx.canManageInAccount ? () => _handleDeleteTransaction(tx, account) : null,
                                          onEdit: tx.canManageInAccount ? () => _handleEditTransaction(tx, account) : null,
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
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    tx.description,
                                                    style: TextStyle(
                                                      color: context.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    tx.reference.isNotEmpty &&
                                                            tx.reference != '-' &&
                                                            tx.reference != tx.description
                                                        ? '${tx.category} • ${tx.reference}'
                                                        : tx.category,
                                                    style: TextStyle(
                                                      color: context.textMuted,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
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
                                                style: TextStyle(
                                                    color: context.textSecondary,
                                                    fontSize: 12),
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
                                                  borderRadius: BorderRadius.circular(4),
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
                                                style: TextStyle(
                                                    color: context.textSecondary,
                                                    fontSize: 11),
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
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 80,
                                              child: tx.canManageInAccount
                                                  ? Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                                          color: context.primaryColor,
                                                          tooltip: 'Edit / Update',
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                          onPressed: () => _handleEditTransaction(tx, account),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete_outline, size: 16),
                                                          color: context.error,
                                                          tooltip: 'Delete',
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                          onPressed: () => _handleDeleteTransaction(tx, account),
                                                        ),
                                                      ],
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        '—',
                                                        style: TextStyle(
                                                          color: context.textMuted,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
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

                  // Pagination Controls
                  if (filtered.isNotEmpty && totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MediaQuery.of(context).size.width < 600
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.end,
                        children: [
                          Text(
                            'Page ${validPage + 1} of $totalPages',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12),
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
    try {
      final match = RegExp(r'\d{12,14}').firstMatch(account.id);
      if (match != null) {
        final timestamp = int.tryParse(match.group(0)!);
        if (timestamp != null && timestamp > 0 && timestamp < 8640000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
        }
      }
    } catch (_) {}
    return DateTime.now().toIso8601String();
  }

  int _compareTransactionsNewestFirst(_CompanyTx a, _CompanyTx b) {
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
    if (value.contains('T') && (parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0)) {
      return parsed;
    }

    try {
      final match = RegExp(r'\d{12,14}').firstMatch(id);
      if (match != null) {
        final timestamp = int.tryParse(match.group(0)!);
        if (timestamp != null && timestamp > 0 && timestamp < 8640000000000000) {
          final createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
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
    } catch (_) {}

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

  Widget _buildDateAndTimeCell(BuildContext context, String rawDate, String txId) {
    final dateStr = AppDateFormatter.formatString(rawDate);
    return Text(
      dateStr,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _handleDeleteTransaction(
    _CompanyTx tx,
    BankAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete this transaction?\n\n'
          '• Category: ${tx.category}\n'
          '• Description: ${tx.description}\n'
          '• Amount: Rs. ${tx.amount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // 1. Opening Balance
      if (tx.id.startsWith('opening_') || tx.category == 'Opening Balance') {
        final oldOpening = account.openingBalance;
        final updatedAccount = account.copyWith(
          openingBalance: 0.0,
          balance: account.balance - oldOpening,
        );
        await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening balance removed successfully')),
        );
        return;
      }

      // 2. Expense Record
      final expensesState = ref.read(expensesProvider);
      final isExp = tx.id.startsWith('exp_') || expensesState.expenses.any((e) => e.id == tx.id);
      if (isExp) {
        await ref.read(expensesProvider.notifier).deleteExpense(tx.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
        return;
      }

      // 3. Income Record
      final incomeState = ref.read(incomeProvider);
      final isInc = tx.id.startsWith('inv_') || tx.id.startsWith('rec_') || incomeState.incomes.any((i) => i.id == tx.id);
      if (isInc) {
        await ref.read(incomeProvider.notifier).deleteIncome(tx.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income transaction deleted successfully')),
        );
        return;
      }

      // 4. General Ledger Entry (Deposits, Transfers, Settlements)
      final ledgerState = ref.read(ledgerProvider);
      final entry = ledgerState.entries.where((e) => e.id == tx.id).firstOrNull;
      if (entry != null) {
        if (entry.category == 'Account Transfer' && entry.reference.isNotEmpty) {
          final paired = ledgerState.entries
              .where((e) => e.reference == entry.reference && e.id != entry.id)
              .firstOrNull;
          if (paired != null) {
            final pairedAdjust = paired.type == 'Debit' ? -paired.amount : paired.amount;
            await ref.read(accountsProvider.notifier).adjustBalance(paired.accountId, pairedAdjust);
            await ref.read(ledgerProvider.notifier).deleteLedgerEntry(paired.id);
          }
        }
        final balanceAdjust = entry.type == 'Debit' ? -entry.amount : entry.amount;
        await ref.read(accountsProvider.notifier).adjustBalance(account.id, balanceAdjust);
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry(tx.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        return;
      }

      // 5. Fallback delete
      final balanceAdjust = tx.type == 'Income' ? -tx.amount : tx.amount;
      await ref.read(accountsProvider.notifier).adjustBalance(account.id, balanceAdjust);
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry(tx.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleEditTransaction(
    _CompanyTx tx,
    BankAccount account,
  ) async {
    // 1. Opening Balance
    if (tx.id.startsWith('opening_') || tx.category == 'Opening Balance') {
      final amountController = TextEditingController(text: account.openingBalance.toStringAsFixed(0));
      final formKey = GlobalKey<FormState>();
      final updated = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update Opening Balance'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account: ${account.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance (Rs.)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter opening balance';
                    if (double.tryParse(v) == null || double.parse(v) < 0) return 'Enter a valid positive number';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, double.parse(amountController.text.trim()));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (updated != null && mounted) {
        final diff = updated - account.openingBalance;
        final updatedAccount = account.copyWith(
          openingBalance: updated,
          balance: account.balance + diff,
        );
        await ref.read(accountsProvider.notifier).updateAccount(updatedAccount);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening balance updated successfully')),
        );
      }
      return;
    }

    // 2. Expense Record
    final expensesState = ref.read(expensesProvider);
    final expense = expensesState.expenses.where((e) => e.id == tx.id).firstOrNull;
    if (expense != null) {
      final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
      final descController = TextEditingController(text: expense.description);
      final vendorController = TextEditingController(text: expense.vendorName);
      String category = expense.category;
      final formKey = GlobalKey<FormState>();

      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Update Expense'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
                      validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0
                          ? 'Enter valid amount'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
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
                        category,
                      }.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: vendorController,
                      decoration: const InputDecoration(labelText: 'Vendor / Beneficiary', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      );

      if (saved == true && mounted) {
        final newAmount = double.parse(amountController.text.trim());
        final updatedExpense = expense.copyWith(
          amount: newAmount,
          category: category,
          description: descController.text.trim(),
          vendorName: vendorController.text.trim(),
        );
        await ref.read(expensesProvider.notifier).updateExpense(expense, updatedExpense);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated successfully')),
        );
      }
      return;
    }

    // 3. Income Record
    final incomeState = ref.read(incomeProvider);
    final income = incomeState.incomes.where((i) => i.id == tx.id).firstOrNull;
    if (income != null) {
      final amountController = TextEditingController(text: income.amount.toStringAsFixed(0));
      final descController = TextEditingController(text: income.description);
      final formKey = GlobalKey<FormState>();

      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update Income Transaction'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
                  validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0
                      ? 'Enter valid amount'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      );

      if (saved == true && mounted) {
        final newAmount = double.parse(amountController.text.trim());
        final updatedIncome = income.copyWith(
          amount: newAmount,
          description: descController.text.trim(),
        );
        await ref.read(incomeProvider.notifier).updateIncome(income, updatedIncome);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income updated successfully')),
        );
      }
      return;
    }

    // 4. Ledger Entry (Deposits, Transfers, Settlements)
    final ledgerState = ref.read(ledgerProvider);
    final entry = ledgerState.entries.where((e) => e.id == tx.id).firstOrNull;
    if (entry != null) {
      final amountController = TextEditingController(text: entry.amount.toStringAsFixed(0));
      final descController = TextEditingController(text: entry.description);
      final formKey = GlobalKey<FormState>();

      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Update ${entry.category}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
                  validator: (v) => v == null || double.tryParse(v) == null || double.parse(v) <= 0
                      ? 'Enter valid amount'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      );

      if (saved == true && mounted) {
        final newAmount = double.parse(amountController.text.trim());
        final diff = newAmount - entry.amount;
        final balanceAdjust = entry.type == 'Debit' ? diff : -diff;
        if (balanceAdjust != 0) {
          await ref.read(accountsProvider.notifier).adjustBalance(account.id, balanceAdjust);
        }
        if (entry.category == 'Account Transfer' && entry.reference.isNotEmpty) {
          final paired = ledgerState.entries
              .where((e) => e.reference == entry.reference && e.id != entry.id)
              .firstOrNull;
          if (paired != null) {
            final pairedAdjust = paired.type == 'Debit' ? diff : -diff;
            if (pairedAdjust != 0) {
              await ref.read(accountsProvider.notifier).adjustBalance(paired.accountId, pairedAdjust);
            }
            await ref.read(ledgerProvider.notifier).updateLedgerEntry(paired.copyWith(amount: newAmount));
          }
        }

        final updatedEntry = entry.copyWith(
          amount: newAmount,
          description: descController.text.trim(),
        );
        await ref.read(ledgerProvider.notifier).updateLedgerEntry(updatedEntry);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
      }
      return;
    }
  }
}

class _CompanyTx {
  final String id;
  final String date;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String reference;
  final bool canManageInAccount;

  _CompanyTx({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    this.reference = '-',
    this.canManageInAccount = false,
  });
}
