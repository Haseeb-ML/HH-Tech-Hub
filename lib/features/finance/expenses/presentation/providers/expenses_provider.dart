import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../loans/domain/entities/loan_record.dart';
import '../../../loans/presentation/providers/loans_provider.dart';

class ExpensesState {
  final List<ExpenseRecord> expenses;
  final bool isLoading;
  final String searchQuery;
  final String categoryFilter; // 'All' or specific category

  const ExpensesState({
    required this.expenses,
    required this.isLoading,
    required this.searchQuery,
    required this.categoryFilter,
  });

  ExpensesState copyWith({
    List<ExpenseRecord>? expenses,
    bool? isLoading,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  List<ExpenseRecord> get filteredExpenses {
    final sorted = ExpenseRecord.sortExpensesNewestFirst(expenses);

    return sorted.where((e) {
      final matchesSearch = e.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.vendorName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = categoryFilter == 'All' || e.category == categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ExpenseRepositoryImpl(dbService);
});

class ExpensesNotifier extends Notifier<ExpensesState> {
  ExpenseRepository get _repository => ref.read(expenseRepositoryProvider);

  @override
  ExpensesState build() {
    _loadExpenses();
    return const ExpensesState(
      expenses: [],
      isLoading: true,
      searchQuery: '',
      categoryFilter: 'All',
    );
  }

  Future<void> _loadExpenses() async {
    try {
      final list = await _repository.getExpenses();
      state = state.copyWith(expenses: list, isLoading: false);
      await syncAssetsAndInventoryExpenses();
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> syncAssetsAndInventoryExpenses() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      final accounts = ref.read(accountsProvider).accounts;
      final defaultAccountId = accounts.isNotEmpty ? accounts.first.id : 'acc_default';

      // 1. Normalize categories in SQLite for any legacy records
      await dbService.db.customStatement("UPDATE expense_records_table SET category = 'Assets Management' WHERE id LIKE '%AST-%' AND category != 'Assets Management'");
      await dbService.db.customStatement("UPDATE expense_records_table SET category = 'Office Inventory' WHERE id LIKE '%INV-%' AND category != 'Office Inventory'");
      await dbService.db.customStatement("UPDATE ledger_entries_table SET category = 'Assets Management' WHERE id LIKE '%AST-%' AND category != 'Assets Management'");
      await dbService.db.customStatement("UPDATE ledger_entries_table SET category = 'Office Inventory' WHERE id LIKE '%INV-%' AND category != 'Office Inventory'");

      final existingExpenses = await _repository.getExpenses();
      final existingExpenseIds = {for (var e in existingExpenses) e.id};

      // 2. Sync Assets
      final assets = await dbService.db.getAll(dbService.db.assetsTable);
      for (final asset in assets) {
        final expId = 'AST-EXP-${asset.id}';
        if (!existingExpenseIds.contains(expId) && asset.cost > 0) {
          final expRecord = ExpenseRecord(
            id: expId,
            date: asset.purchaseDate.length > 10 ? asset.purchaseDate : (asset.purchaseDate.isNotEmpty ? '${asset.purchaseDate}T00:00:00.000' : DateTime.now().toIso8601String()),
            amount: asset.cost,
            accountId: defaultAccountId,
            category: ExpenseRecord.assetCategory(),
            vendorName: 'Asset Purchase',
            description: 'Asset purchase - ${asset.name}',
          );
          await _repository.addExpense(expRecord);
          existingExpenseIds.add(expId);

          // Add General Ledger entry (Credit / Outflow)
          final ledgerEntry = LedgerEntry(
            id: 'led_exp_$expId',
            date: expRecord.date,
            accountId: expRecord.accountId,
            accountName: accounts.where((a) => a.id == expRecord.accountId).firstOrNull?.name ?? 'Bank/Cash Account',
            type: 'Credit',
            category: expRecord.category,
            amount: expRecord.amount,
            reference: 'Asset Purchase',
            description: expRecord.description,
          );
          await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
          
          // Adjust bank account balance (Deduct asset cost)
          await ref.read(accountsProvider.notifier).adjustBalance(defaultAccountId, -asset.cost);
        }
      }

      // 3. Sync Inventory Items
      final inventoryItems = await dbService.db.getAll(dbService.db.inventoryItemsTable);
      for (final item in inventoryItems) {
        final expId = 'INV-EXP-${item.id}';
        final totalCost = item.quantity * item.pricePerUnit;
        if (!existingExpenseIds.contains(expId) && totalCost > 0) {
          final expRecord = ExpenseRecord(
            id: expId,
            date: item.lastRestockedDate.length > 10 ? item.lastRestockedDate : (item.lastRestockedDate.isNotEmpty ? '${item.lastRestockedDate}T00:00:00.000' : DateTime.now().toIso8601String()),
            amount: totalCost,
            accountId: defaultAccountId,
            category: ExpenseRecord.inventoryCategory(),
            vendorName: 'Inventory Purchase',
            description: 'Inventory purchase - ${item.name}',
          );
          await _repository.addExpense(expRecord);
          existingExpenseIds.add(expId);

          // Add General Ledger entry (Credit / Outflow)
          final ledgerEntry = LedgerEntry(
            id: 'led_exp_$expId',
            date: expRecord.date,
            accountId: expRecord.accountId,
            accountName: accounts.where((a) => a.id == expRecord.accountId).firstOrNull?.name ?? 'Bank/Cash Account',
            type: 'Credit',
            category: expRecord.category,
            amount: expRecord.amount,
            reference: 'Inventory Purchase',
            description: expRecord.description,
          );
          await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
          
          // Adjust bank account balance (Deduct inventory cost)
          await ref.read(accountsProvider.notifier).adjustBalance(defaultAccountId, -totalCost);
        }
      }

      final updated = await _repository.getExpenses();
      bool isDifferent = updated.length != state.expenses.length;
      if (!isDifferent) {
        for (int i = 0; i < updated.length; i++) {
          if (updated[i].id != state.expenses[i].id ||
              updated[i].category != state.expenses[i].category ||
              updated[i].amount != state.expenses[i].amount ||
              updated[i].date != state.expenses[i].date) {
            isDifferent = true;
            break;
          }
        }
      }

      if (isDifferent) {
        state = state.copyWith(expenses: updated);
        await ref.read(ledgerProvider.notifier).loadEntries();
      }
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String filter) {
    state = state.copyWith(categoryFilter: filter);
  }

  Future<void> addExpense(ExpenseRecord record) async {
    state = state.copyWith(isLoading: true);

    String isoDate = record.date;
    final idNumStr = record.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (idNumStr.length > 10) {
      final ms = int.tryParse(idNumStr);
      if (ms != null) {
        final timePart = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String().substring(10);
        if (isoDate.length == 10) isoDate += timePart;
      }
    }
    if (isoDate.length == 10) {
      isoDate += DateTime.now().toIso8601String().substring(10);
    }

    final recordToSave = record.date.length == 10 ? record.copyWith(date: isoDate) : record;
    await _repository.addExpense(recordToSave);

    // Resolve Account Name
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == recordToSave.accountId).firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';
    final isCompanyAccount = account?.accountScope != 'Personal';

    // 1. Adjust bank account balance (Deduct expense amount)
    await ref.read(accountsProvider.notifier).adjustBalance(recordToSave.accountId, -recordToSave.amount);

    // 2. Add General Ledger entry (Credit / Outflow)
    String ledgerCategory = recordToSave.category;
    if (recordToSave.isPersonalExpense && isCompanyAccount) {
      ledgerCategory = 'Owner Drawings';
    }

    final ledgerEntry = LedgerEntry(
      id: 'led_exp_${recordToSave.id}',
      date: isoDate,
      accountId: recordToSave.accountId,
      accountName: accountName,
      type: 'Credit',
      category: ledgerCategory,
      amount: recordToSave.amount,
      reference: recordToSave.vendorName.isNotEmpty ? recordToSave.vendorName : 'Expense Outflow',
      description: recordToSave.description,
    );
    await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);

    // 3. Handle Auto-Loans for Company/Personal cross-transactions
    if (!recordToSave.isPersonalExpense && !isCompanyAccount) {
      final loanId = 'loan_exp_${recordToSave.id}';
      final autoLoan = LoanRecord(
        id: loanId,
        borrowerName: 'Company',
        type: 'Borrowed',
        amount: recordToSave.amount,
        remainingBalance: recordToSave.amount,
        startDate: isoDate,
        endDate: '',
        status: 'Active',
        description: '[AutoExpense] Company expense paid by Personal Account. [PersonalAccount:${account!.id}|$accountName]',
        repayments: const [],
      );
      await ref.read(loansRepositoryProvider).addLoan(autoLoan);
      await ref.read(loansProvider.notifier).loadLoans();
    } else if (recordToSave.isPersonalExpense && isCompanyAccount) {
      final loanId = 'loan_exp_${recordToSave.id}';
      final autoLoan = LoanRecord(
        id: loanId,
        borrowerName: 'Owner (Drawings)',
        type: 'Lent',
        amount: recordToSave.amount,
        remainingBalance: recordToSave.amount,
        startDate: isoDate,
        endDate: '',
        status: 'Active',
        description: '[AutoExpense] Personal expense paid by Company Account.',
        accountId: recordToSave.accountId,
        accountName: accountName,
        repayments: const [],
      );
      await ref.read(loansRepositoryProvider).addLoan(autoLoan);
      await ref.read(loansProvider.notifier).loadLoans();
    }

    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }

  Future<void> updateExpense(ExpenseRecord oldRecord, ExpenseRecord newRecord) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateExpense(newRecord);

    // Resolve Account Name
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == newRecord.accountId).firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';
    final isCompanyAccount = account?.accountScope != 'Personal';

    // Bank Account Balance adjustment
    if (oldRecord.accountId == newRecord.accountId) {
      final diff = newRecord.amount - oldRecord.amount;
      if (diff != 0) {
        await ref.read(accountsProvider.notifier).adjustBalance(newRecord.accountId, -diff);
      }
    } else {
      // Revert old account deduction
      await ref.read(accountsProvider.notifier).adjustBalance(oldRecord.accountId, oldRecord.amount);
      // Apply new account deduction
      await ref.read(accountsProvider.notifier).adjustBalance(newRecord.accountId, -newRecord.amount);
    }

    // Update General Ledger entry
    String ledgerCategory = newRecord.category;
    if (newRecord.isPersonalExpense && isCompanyAccount) {
      ledgerCategory = 'Owner Drawings';
    }

    final ledgerEntry = LedgerEntry(
      id: 'led_exp_${newRecord.id}',
      date: newRecord.date,
      accountId: newRecord.accountId,
      accountName: accountName,
      type: 'Credit',
      category: ledgerCategory,
      amount: newRecord.amount,
      reference: newRecord.vendorName.isNotEmpty ? newRecord.vendorName : 'Expense Outflow',
      description: newRecord.description,
    );
    await ref.read(ledgerProvider.notifier).updateLedgerEntry(ledgerEntry);

    // Update Auto-Loan if it exists
    final loanId = 'loan_exp_${newRecord.id}';
    final loans = await ref.read(loansRepositoryProvider).getLoans();
    final existingLoan = loans.where((l) => l.id == loanId).firstOrNull;

    if (!newRecord.isPersonalExpense && !isCompanyAccount) {
      final autoLoan = LoanRecord(
        id: loanId,
        borrowerName: 'Company',
        type: 'Borrowed',
        amount: newRecord.amount,
        remainingBalance: newRecord.amount,
        startDate: newRecord.date,
        endDate: '',
        status: 'Active',
        description: '[AutoExpense] Company expense paid by Personal Account. [PersonalAccount:${account!.id}|$accountName]',
        repayments: existingLoan?.repayments ?? const [],
      );
      if (existingLoan != null) {
        await ref.read(loansRepositoryProvider).updateLoan(autoLoan);
      } else {
        await ref.read(loansRepositoryProvider).addLoan(autoLoan);
      }
      await ref.read(loansProvider.notifier).loadLoans();
    } else if (newRecord.isPersonalExpense && isCompanyAccount) {
      final autoLoan = LoanRecord(
        id: loanId,
        borrowerName: 'Owner (Drawings)',
        type: 'Lent',
        amount: newRecord.amount,
        remainingBalance: newRecord.amount,
        startDate: newRecord.date,
        endDate: '',
        status: 'Active',
        description: '[AutoExpense] Personal expense paid by Company Account.',
        accountId: newRecord.accountId,
        accountName: accountName,
        repayments: existingLoan?.repayments ?? const [],
      );
      if (existingLoan != null) {
        await ref.read(loansRepositoryProvider).updateLoan(autoLoan);
      } else {
        await ref.read(loansRepositoryProvider).addLoan(autoLoan);
      }
      await ref.read(loansProvider.notifier).loadLoans();
    } else {
      // If it changed to not need a loan, delete the auto-loan
      if (existingLoan != null) {
        await ref.read(loansRepositoryProvider).deleteLoan(loanId);
        await ref.read(loansProvider.notifier).loadLoans();
      }
    }

    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }

  Future<void> deleteExpense(String id) async {
    ExpenseRecord? record = state.expenses.where((e) => e.id == id).firstOrNull;
    if (record == null) {
      final all = await _repository.getExpenses();
      record = all.where((e) => e.id == id).firstOrNull;
    }

    state = state.copyWith(isLoading: true);

    if (record != null) {
      // 1. Rollback bank account balance (Add back expense amount)
      await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, record.amount);

      // 2. Remove General Ledger entry
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_${record.id}');
      
      // 3. Remove Auto-Loan if exists
      final loanId = 'loan_exp_${record.id}';
      final loans = await ref.read(loansRepositoryProvider).getLoans();
      if (loans.any((l) => l.id == loanId)) {
        await ref.read(loansRepositoryProvider).deleteLoan(loanId);
        await ref.read(loansProvider.notifier).loadLoans();
      }
    } else {
      // Fallback: attempt to delete matching ledger entry directly
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_$id');
    }

    // 4. Delete expense record from database
    await _repository.deleteExpense(id);

    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, ExpensesState>(() {
  return ExpensesNotifier();
});
