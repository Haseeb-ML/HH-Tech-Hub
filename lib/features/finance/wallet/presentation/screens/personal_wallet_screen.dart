import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/screens/accounts_screen.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import 'package:software_house_erp/features/finance/loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class PersonalWalletScreen extends ConsumerStatefulWidget {
  const PersonalWalletScreen({super.key});

  @override
  ConsumerState<PersonalWalletScreen> createState() => _PersonalWalletScreenState();
}

class _PersonalWalletScreenState extends ConsumerState<PersonalWalletScreen> {
  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final canCreateAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.create);
    final canEditAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.edit);
    final canDeleteAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.delete);
    final theme = Theme.of(context);
    final accountsState = ref.watch(accountsProvider);
    final expensesState = ref.watch(expensesProvider);
    final incomesState = ref.watch(incomeProvider);
    final loansState = ref.watch(loansProvider);
    final ledgerState = ref.watch(ledgerProvider);

    final personalAccounts = accountsState.accounts
        .where((a) => a.isPersonal)
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/wallet'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title Row with Action Buttons ──────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final titleCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Account',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Individual cash flow and independent account balances for each person.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );
                      final addBtn = ElevatedButton.icon(
                        onPressed: () async {
                          final result = await showDialog<BankAccount>(
                            context: context,
                            builder: (context) => const AddEditAccountDialog(
                              defaultScope: 'Personal',
                              isScopeFixed: true,
                            ),
                          );
                          if (result != null) {
                            await ref.read(accountsProvider.notifier).addAccount(result);
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(tr('Add Account')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleCol,
                            if (canCreateAccount) ...[
                              const SizedBox(height: 12),
                              addBtn,
                            ],
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleCol),
                          if (canCreateAccount) ...[
                            const SizedBox(width: 16),
                            addBtn,
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Section Title ──────────────────────────────────────
                  Text(
                    'Your Personal Accounts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap a card to view detailed balance, transactions, and ledger.',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // ── Empty State ────────────────────────────────────────
                  if (personalAccounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin_outlined,
                                size: 52, color: context.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No personal accounts added yet.',
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add individual personal accounts for each person here.',
                              style:
                                  TextStyle(color: context.textMuted, fontSize: 12),
                            ),
                            if (canCreateAccount) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await showDialog<BankAccount>(
                                    context: context,
                                    builder: (context) => const AddEditAccountDialog(
                                      defaultScope: 'Personal',
                                      isScopeFixed: true,
                                    ),
                                  );
                                  if (result != null) {
                                    await ref.read(accountsProvider.notifier).addAccount(result);
                                  }
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Personal Account'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    // ── Account Cards Grid ───────────────────────────────
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth >= 1200
                            ? 4
                            : (constraints.maxWidth >= 800
                                ? 3
                                : (constraints.maxWidth >= 500 ? 2 : 1));
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: personalAccounts.length,
                          itemBuilder: (context, index) {
                            final acc = personalAccounts[index];

                            final accLoans = loansState.loans
                              .where((l) =>
                                l.personalAccountId == acc.id &&
                                !l.description.contains('[AutoExpense]'))
                              .toList();
                            double accLoanIn = 0.0;
                            double accLoanOut = 0.0;
                            for (final l in accLoans) {
                              if (l.isPersonalExternalLoan) {
                                if (l.type == 'Borrowed') {
                                  accLoanIn += l.amount;
                                  accLoanOut += l.repayments.fold<double>(0.0, (s, r) => s + r.amount);
                                } else {
                                  accLoanOut += l.amount;
                                  accLoanIn += l.repayments.fold<double>(0.0, (s, r) => s + r.amount);
                                }
                              } else {
                                if (l.type == 'Lent') {
                                  accLoanIn += l.amount;
                                  accLoanOut += l.repayments.fold<double>(0.0, (s, r) => s + r.amount);
                                } else {
                                  accLoanOut += l.amount;
                                  accLoanIn += l.repayments.fold<double>(0.0, (s, r) => s + r.amount);
                                }
                              }
                            }
                             final directAccountEntries = ledgerState.entries.where((entry) =>
                                 entry.accountId == acc.id &&
                                 (entry.category == 'Personal Deposit' ||
                                  entry.category == 'Company Deposit' ||
                                  entry.category == 'Account Transfer' ||
                                  entry.category == 'Salary Advance' ||
                                  entry.category == 'Other Expense')).toList();

                             final directInflow = directAccountEntries
                                 .where((entry) => entry.type == 'Debit')
                                 .fold<double>(0.0, (sum, entry) => sum + entry.amount);

                             final directOutflow = directAccountEntries
                                 .where((entry) => entry.type == 'Credit')
                                 .fold<double>(0.0, (sum, entry) => sum + entry.amount);

                             final accIncomes = incomesState.incomes
                                     .where((i) => i.accountId == acc.id)
                                     .fold<double>(0.0, (s, i) => s + i.amount) +
                               accLoanIn + directInflow;
                             final accExpenses = expensesState.expenses
                                     .where((e) => e.accountId == acc.id)
                                     .fold<double>(0.0, (s, e) => s + e.amount) +
                               accLoanOut + directOutflow;

                             final currentCardBalance = calculateAuthoritativeAccountBalance(
                               account: acc,
                               incomes: incomesState.incomes,
                               expenses: expensesState.expenses,
                               loans: loansState.loans,
                               ledgerEntries: ledgerState.entries,
                             );

                            final isPermanent = acc.id == 'acc_personal_hassan' ||
                                acc.id == 'acc_personal_huzaifa' ||
                                (acc.accountScope == 'Personal' &&
                                    (acc.name.toLowerCase().contains('hassan') ||
                                        acc.name
                                            .toLowerCase()
                                            .contains('huzaifa')));

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    context.push('/finance/wallet/details/${acc.id}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: context.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              acc.type == 'Bank'
                                                  ? Icons.account_balance
                                                  : (acc.type == 'Wallet'
                                                      ? Icons.phone_android
                                                      : Icons.wallet),
                                              color: context.primaryColor,
                                              size: 18,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (isPermanent)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                        color: Colors.blue
                                                            .withValues(
                                                                alpha: 0.3)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.verified,
                                                          size: 10,
                                                          color: Colors.blue),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Permanent',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              const SizedBox(width: 4),
                                              PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert,
                                                    size: 18,
                                                    color: context.textSecondary),
                                                padding: EdgeInsets.zero,
                                                onSelected: (val) async {
                                                   if (val == 'details') {
                                                     context.push('/finance/wallet/details/${acc.id}');
                                                   } else if (val == 'edit' && canEditAccount) {
                                                    final result = await showDialog<BankAccount>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AddEditAccountDialog(
                                                        account: acc,
                                                        defaultScope: 'Personal',
                                                        isScopeFixed: true,
                                                      ),
                                                    );
                                                    if (result != null) {
                                                      await ref.read(accountsProvider.notifier).updateAccount(result);
                                                    }
                                                  } else if (val == 'delete' && canDeleteAccount) {
                                                    if (isPermanent) return;
                                                    final confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Delete Personal Account'),
                                                        content: Text(
                                                            'Are you sure you want to delete "${acc.name}"?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                                    backgroundColor:
                                                                        context
                                                                            .error),
                                                            child: const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      ref
                                                          .read(accountsProvider
                                                              .notifier)
                                                          .deleteAccount(acc.id);
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'details',
                                                    child: Text('View Details',
                                                        style: TextStyle(
                                                            color: context
                                                                .textPrimary,
                                                            fontSize: 13)),
                                                  ),
                                                  if (canEditAccount)
                                                    PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text(
                                                          tr('Edit Details'),
                                                          style: TextStyle(
                                                              color: context
                                                                  .textPrimary,
                                                              fontSize: 13)),
                                                    ),
                                                  if (!isPermanent && canDeleteAccount)
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                          'Delete Account',
                                                          style: TextStyle(
                                                              color:
                                                                  context.error,
                                                              fontSize: 13)),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        acc.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: context.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        acc.ownerName.isNotEmpty
                                            ? 'Owner: ${acc.ownerName}'
                                            : (acc.bankName.isNotEmpty
                                                ? acc.bankName
                                                : 'Personal Cash'),
                                        style: TextStyle(
                                            color: context.textSecondary,
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'In: Rs. ${accIncomes.toStringAsFixed(0)} • Out: Rs. ${accExpenses.toStringAsFixed(0)}',
                                                  style: TextStyle(color: context.textMuted, fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Rs. ${currentCardBalance.toStringAsFixed(0)}',
                                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: context.success),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: context.textMuted,
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
