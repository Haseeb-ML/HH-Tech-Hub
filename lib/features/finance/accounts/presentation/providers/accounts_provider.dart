import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../../data/repositories/accounts_repository_impl.dart';
import '../../../income/domain/entities/income_record.dart';
import '../../../expenses/domain/entities/expense_record.dart';
import '../../../loans/domain/entities/loan_record.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';



double calculateAuthoritativeAccountBalance({
  required BankAccount account,
  required List<IncomeRecord> incomes,
  required List<ExpenseRecord> expenses,
  required List<LoanRecord> loans,
  required List<LedgerEntry> ledgerEntries,
}) {
  // 1. Income Inflow
  final incomeInflow = incomes
      .where((inc) => inc.accountId == account.id)
      .fold<double>(0.0, (sum, inc) => sum + inc.amount);

  // 2. Loans
  final isPersonalAcc = account.accountScope == 'Personal';

  // Company loans for this account (ignore personal-external loans so they never affect company balance)
  final companyLoans = !isPersonalAcc
      ? loans.where((l) => (l.accountId == account.id || l.resolvedAccountId == account.id) && !l.isPersonalExternalLoan).toList()
      : <LoanRecord>[];

  // Internal loans linked to this personal account
  final internalLoans = isPersonalAcc
      ? loans.where((l) => l.personalAccountId == account.id && l.isInternalLoan).toList()
      : <LoanRecord>[];

  // Personal external loans taken or given by this personal account
  final personalExternalLoans = isPersonalAcc
      ? loans.where((l) => (l.personalAccountId == account.id || l.accountId == account.id) && l.isPersonalExternalLoan).toList()
      : <LoanRecord>[];

  // Loan Inflow Calculation
  // A) Company Account:
  final compBorrowedInflow = companyLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount);
  final compLentRepaymentsInflow = companyLoans
      .where((l) => l.type == 'Lent')
      .expand((l) => l.repayments)
      .where((r) => r.accountId == account.id)
      .fold<double>(0.0, (sum, r) => sum + r.amount);

  // B) Personal Account (Internal: Company lent to personal = personal cash inflow; Company borrowed repayments = personal cash inflow):
  final internalPersonalInflow = internalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount) +
      internalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

  // C) Personal Account (External: Owner borrowed from 3rd party = cash inflow; Owner lent repayments received = cash inflow):
  final personalExternalInflow = personalExternalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount) +
      personalExternalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

  final totalLoanInflow = compBorrowedInflow + compLentRepaymentsInflow + internalPersonalInflow + personalExternalInflow;

  // 3. Direct Ledger Inflow (Transfers in, Deposits)
  final directInflow = ledgerEntries
      .where((entry) =>
          entry.accountId == account.id &&
          (entry.category == 'Account Transfer' ||
              entry.category == 'Personal Deposit' ||
              entry.category == 'Company Deposit') &&
          entry.type == 'Debit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

  final totalInflow = incomeInflow + totalLoanInflow + directInflow;

  // 4. Expenses Outflow
  final expenseOutflow = expenses
      .where((exp) => exp.accountId == account.id)
      .fold<double>(0.0, (sum, exp) => sum + exp.amount);

  // 5. Loan Outflow Calculation
  // A) Company Account:
  final compLentOutflow = companyLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount);
  final compBorrowedRepaymentsOutflow = companyLoans
      .where((l) => l.type == 'Borrowed')
      .expand((l) => l.repayments)
      .where((r) => r.accountId == account.id)
      .fold<double>(0.0, (sum, r) => sum + r.amount);

  // B) Personal Account (Internal: Company borrowed from personal = personal cash outflow; Company lent repayments = personal repaid company):
  final internalPersonalOutflow = internalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount) +
      internalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

  // C) Personal Account (External: Owner lent to 3rd party = personal cash outflow; Owner borrowed repayments = personal repaid 3rd party):
  final personalExternalOutflow = personalExternalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount) +
      personalExternalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

  final totalLoanOutflow = compLentOutflow + compBorrowedRepaymentsOutflow + internalPersonalOutflow + personalExternalOutflow;

  // 6. Direct Ledger Outflow (Transfers out, Other Expense, Salary Advance)
  final directOutflow = ledgerEntries
      .where((entry) =>
          entry.accountId == account.id &&
          (entry.category == 'Account Transfer' ||
              entry.category == 'Other Expense' ||
              entry.category == 'Salary Advance') &&
          entry.type == 'Credit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

  final totalOutflow = expenseOutflow + totalLoanOutflow + directOutflow;

  final opening = account.openingBalance > 0
      ? account.openingBalance
      : (account.balance > 0 ? account.balance : 0.0);
  return opening + totalInflow - totalOutflow;
}

class AccountsState {
  final List<BankAccount> accounts;
  final bool isLoading;
  final String searchQuery;
  final String typeFilter; // 'All', 'Cash', 'Bank', 'Wallet'

  const AccountsState({
    required this.accounts,
    required this.isLoading,
    required this.searchQuery,
    required this.typeFilter,
  });

  AccountsState copyWith({
    List<BankAccount>? accounts,
    bool? isLoading,
    String? searchQuery,
    String? typeFilter,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  List<BankAccount> get filteredAccounts {
    return accounts.where((acc) {
      final matchesSearch = acc.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          acc.bankName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          acc.accountNumber.contains(searchQuery);

      final matchesType = typeFilter == 'All' || acc.type == typeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AccountsRepositoryImpl(dbService);
});

class AccountsNotifier extends Notifier<AccountsState> {
  AccountsRepository get _repository => ref.read(accountsRepositoryProvider);

  @override
  AccountsState build() {
    _loadAccounts();
    return const AccountsState(
      accounts: [],
      isLoading: true,
      searchQuery: '',
      typeFilter: 'All',
    );
  }

  Future<void> _loadAccounts() async {
    try {
      var list = await _repository.getAccounts();

      final hasHassan = list.any((a) =>
          a.accountScope == 'Personal' &&
          (a.name.toLowerCase().contains('hassan') || a.ownerName.toLowerCase().contains('hassan')));

      final hasHuzaifa = list.any((a) =>
          a.accountScope == 'Personal' &&
          (a.name.toLowerCase().contains('huzaifa') || a.ownerName.toLowerCase().contains('huzaifa')));

      bool updated = false;

      if (!hasHassan) {
        final existing = list.where((a) => a.id == 'acc_personal_hassan').firstOrNull;
        if (existing != null) {
          await _repository.updateAccount(existing.copyWith(
            accountScope: 'Personal',
            ownerName: 'Hassan',
            openingBalance: existing.openingBalance > 0 ? existing.openingBalance : existing.balance,
          ));
        } else {
          const hassanAcc = BankAccount(
            id: 'acc_personal_hassan',
            name: 'Hassan Personal Account',
            type: 'Bank',
            bankName: 'Personal Bank',
            accountNumber: 'PK-HASSAN-01',
            balance: 0.0,
            openingBalance: 0.0,
            accountScope: 'Personal',
            ownerName: 'Hassan',
            status: 'Active',
          );
          await _repository.addAccount(hassanAcc);
        }
        updated = true;
      }

      if (!hasHuzaifa) {
        final existing = list.where((a) => a.id == 'acc_personal_huzaifa').firstOrNull;
        if (existing != null) {
          await _repository.updateAccount(existing.copyWith(
            accountScope: 'Personal',
            ownerName: 'Huzaifa',
            openingBalance: existing.openingBalance > 0 ? existing.openingBalance : existing.balance,
          ));
        } else {
          const huzaifaAcc = BankAccount(
            id: 'acc_personal_huzaifa',
            name: 'Huzaifa Personal Account',
            type: 'Bank',
            bankName: 'Personal Bank',
            accountNumber: 'PK-HUZAIFA-02',
            balance: 0.0,
            openingBalance: 0.0,
            accountScope: 'Personal',
            ownerName: 'Huzaifa',
            status: 'Active',
          );
          await _repository.addAccount(huzaifaAcc);
        }
        updated = true;
      }

      if (updated) {
        list = await _repository.getAccounts();
      }

      state = state.copyWith(accounts: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(String filter) {
    state = state.copyWith(typeFilter: filter);
  }

  Future<void> addAccount(BankAccount account) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.accounts, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to create accounts.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.addAccount(account);
    if (account.openingBalance > 0) {
      try {
        await ref.read(ledgerProvider.notifier).updateLedgerEntry(LedgerEntry(
          id: 'led_opening_${account.id}',
          date: account.ledgerOpeningDate,
          accountId: account.id,
          accountName: account.name,
          type: 'Debit',
          category: 'Opening Balance',
          amount: account.openingBalance,
          reference: 'Opening Balance',
          description: 'Opening balance deposited for ${account.name}',
        ));
      } catch (_) {}
    }
    ref.read(adminProvider.notifier).logAction(
      action: 'Added account: ${account.name} (Type: ${account.type}, Opening Balance: ${account.openingBalance})',
      module: 'Finance',
    );

    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
    try {
      await ref.read(cloudSyncServiceProvider).syncAll(forcePush: true);
    } catch (_) {}
  }

  Future<void> updateAccount(BankAccount account) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.accounts, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to edit accounts.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.updateAccount(account);
    if (account.openingBalance > 0) {
      try {
        await ref.read(ledgerProvider.notifier).updateLedgerEntry(LedgerEntry(
          id: 'led_opening_${account.id}',
          date: account.ledgerOpeningDate,
          accountId: account.id,
          accountName: account.name,
          type: 'Debit',
          category: 'Opening Balance',
          amount: account.openingBalance,
          reference: 'Opening Balance',
          description: 'Opening balance deposited for ${account.name}',
        ));
      } catch (_) {}
    } else {
      try {
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_opening_${account.id}');
      } catch (_) {}
    }
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated account: ${account.name} (Type: ${account.type}, Balance: ${account.balance})',
      module: 'Finance',
    );

    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
    try {
      await ref.read(cloudSyncServiceProvider).syncAll(forcePush: true);
    } catch (_) {}
  }

  Future<void> deleteAccount(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.accounts, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete accounts.');
    }

    if (id == 'acc_personal_hassan' ||
      id == 'acc_personal_huzaifa') {
      // Permanent accounts cannot be deleted
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.deleteAccount(id);

    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted account: $id',
      module: 'Finance',
    );

    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
  }

  Future<void> loadAccounts() async {
    await _loadAccounts();
  }


  Future<void> syncAccountBalances({
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
    required List<LoanRecord> loans,
    required List<LedgerEntry> ledgerEntries,
  }) async {
    final accounts = await _repository.getAccounts();
    bool anyUpdated = false;
    for (final acc in accounts) {
      final realBal = calculateAuthoritativeAccountBalance(
        account: acc,
        incomes: incomes,
        expenses: expenses,
        loans: loans,
        ledgerEntries: ledgerEntries,
      );
      if ((acc.balance - realBal).abs() > 0.001) {
        await _repository.updateAccount(acc.copyWith(balance: realBal));
        anyUpdated = true;
      }
    }
    if (anyUpdated) {
      final updatedList = await _repository.getAccounts();
      state = state.copyWith(accounts: updatedList, isLoading: false);
    }
  }

  Future<void> syncBalancesFromDb() async {
    try {
      final db = ref.read(databaseServiceProvider).db;
      final accounts = await _repository.getAccounts();
      if (accounts.isEmpty) return;

      final incomes = await db.getAll(db.incomeRecordsTable);
      final expenses = await db.getAll(db.expenseRecordsTable);
      final loans = await db.getAll(db.loanRecordsTable);
      final ledgers = await db.getAll(db.ledgerEntriesTable);

      final domainIncomes = incomes.map((i) => IncomeRecord(
        id: i.id,
        date: i.date,
        clientId: i.clientId,
        clientName: i.clientName,
        amount: i.amount,
        accountId: i.accountId,
        invoiceNumber: i.invoiceNumber,
        description: i.description,
        status: i.status,
        projectId: i.projectId,
        projectName: i.projectName,
        projectPaymentType: i.projectPaymentType,
      )).toList();

      final domainExpenses = expenses.map((e) => ExpenseRecord(
        id: e.id,
        date: e.date,
        amount: e.amount,
        accountId: e.accountId,
        category: e.category,
        vendorName: e.vendorName,
        description: e.description,
      )).toList();

      final domainLoans = loans.map((l) => LoanRecord(
        id: l.id,
        borrowerName: l.borrowerName,
        type: l.type,
        amount: l.amount,
        remainingBalance: l.remainingBalance,
        startDate: l.startDate,
        endDate: l.endDate,
        status: l.status,
        description: l.description,
        repayments: l.repayments.map((r) => LoanRepayment(
          id: r['id']?.toString() ?? '',
          date: r['date']?.toString() ?? '',
          amount: (r['amount'] as num?)?.toDouble() ?? 0.0,
          accountId: r['accountId']?.toString() ?? '',
          accountName: r['accountName']?.toString() ?? '',
        )).toList(),
      )).toList();

      final domainLedgers = ledgers.map((l) => LedgerEntry(
        id: l.id,
        date: l.date,
        accountId: l.accountId,
        accountName: l.accountName,
        type: l.type,
        category: l.category,
        amount: l.amount,
        reference: l.reference,
        description: l.description,
      )).toList();

      bool anyUpdated = false;
      for (final acc in accounts) {
        final realBal = calculateAuthoritativeAccountBalance(
          account: acc,
          incomes: domainIncomes,
          expenses: domainExpenses,
          loans: domainLoans,
          ledgerEntries: domainLedgers,
        );
        if ((acc.balance - realBal).abs() > 0.001) {
          await _repository.updateAccount(acc.copyWith(balance: realBal));
          anyUpdated = true;
        }
      }
      if (anyUpdated) {
        final updatedList = await _repository.getAccounts();
        state = state.copyWith(accounts: updatedList, isLoading: false);
      }
    } catch (_) {}
  }

  Future<void> adjustBalance(String id, double amountChange) async {
    // Read directly from repository to avoid race conditions when state.accounts is still loading
    final accounts = await _repository.getAccounts();
    final index = accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final updatedAccount = accounts[index].copyWith(
        balance: accounts[index].balance + amountChange,
      );
      await _repository.updateAccount(updatedAccount);
      final updatedList = await _repository.getAccounts();
      state = state.copyWith(accounts: updatedList, isLoading: false);
    }
  }
}

final accountsProvider = NotifierProvider<AccountsNotifier, AccountsState>(() {
  return AccountsNotifier();
});
