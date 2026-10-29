import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';

import 'package:software_house_erp/core/utils/transaction_id_helper.dart';

import 'package:software_house_erp/core/services/cloud_sync_service.dart';

class ExpensesState {
  final List<ExpenseRecord> expenses;
  final bool isLoading;
  final String searchQuery;
  final String categoryFilter; // 'All' or specific category
  final String accountIdFilter; // 'All' or specific accountId
  final String? fromDateFilter; // 'YYYY-MM-DD' or null
  final String? toDateFilter; // 'YYYY-MM-DD' or null

  const ExpensesState({
    required this.expenses,
    required this.isLoading,
    required this.searchQuery,
    required this.categoryFilter,
    this.accountIdFilter = 'All',
    this.fromDateFilter,
    this.toDateFilter,
  });

  ExpensesState copyWith({
    List<ExpenseRecord>? expenses,
    bool? isLoading,
    String? searchQuery,
    String? categoryFilter,
    String? accountIdFilter,
    String? fromDateFilter,
    String? toDateFilter,
    bool clearDates = false,
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      accountIdFilter: accountIdFilter ?? this.accountIdFilter,
      fromDateFilter: clearDates ? null : (fromDateFilter ?? this.fromDateFilter),
      toDateFilter: clearDates ? null : (toDateFilter ?? this.toDateFilter),
    );
  }

  bool _isCategoryMatch(String recordCategory, String filterCategory) {
    if (filterCategory == 'All') return true;
    if (recordCategory == filterCategory) return true;

    final rLower = recordCategory.toLowerCase().trim();
    final fLower = filterCategory.toLowerCase().trim();

    // Electricity & Utilities matching
    if ((fLower.contains('electric') || fLower.contains('utilit')) &&
        (rLower.contains('electric') || rLower.contains('utilit'))) {
      return true;
    }

    // Salaries & Payroll matching
    if ((fLower.contains('salar') || fLower.contains('payroll')) &&
        (rLower.contains('salar') || rLower.contains('payroll'))) {
      return true;
    }

    // Rent & Occupancy matching
    if (fLower.contains('rent') && rLower.contains('rent')) {
      return true;
    }

    // Internet & Telecom matching
    if ((fLower.contains('internet') || fLower.contains('telecom')) &&
        (rLower.contains('internet') || rLower.contains('telecom'))) {
      return true;
    }

    return false;
  }

  List<ExpenseRecord> get filteredExpenses {
    final sorted = ExpenseRecord.sortExpensesNewestFirst(expenses);

    return sorted.where((e) {
      final q = searchQuery.trim().toLowerCase();
      final cleanExp = TransactionIdHelper.getExpenseId(e, sorted);

      final matchesSearch = searchQuery.isEmpty ||
          e.description.toLowerCase().contains(q) ||
          e.vendorName.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.expenseId.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q) ||
          cleanExp.toLowerCase().contains(q);

      final matchesCategory = _isCategoryMatch(e.category, categoryFilter);

      final matchesAccount = accountIdFilter == 'All' || e.accountId == accountIdFilter;

      bool matchesDate = true;
      if (fromDateFilter != null && fromDateFilter!.isNotEmpty) {
        final eDate = DateTime.tryParse(e.date);
        final fDate = DateTime.tryParse(fromDateFilter!);
        if (eDate != null && fDate != null) {
          final startOfDay = DateTime(fDate.year, fDate.month, fDate.day);
          if (eDate.isBefore(startOfDay)) matchesDate = false;
        }
      }
      if (matchesDate && toDateFilter != null && toDateFilter!.isNotEmpty) {
        final eDate = DateTime.tryParse(e.date);
        final tDate = DateTime.tryParse(toDateFilter!);
        if (eDate != null && tDate != null) {
          final endOfDay = DateTime(tDate.year, tDate.month, tDate.day, 23, 59, 59);
          if (eDate.isAfter(endOfDay)) matchesDate = false;
        }
      }

      return matchesSearch && matchesCategory && matchesAccount && matchesDate;
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
    ref.listen<SyncState>(cloudSyncStateProvider, (previous, next) {
      if ((next.status == SyncStatus.success || next.status == SyncStatus.offline) &&
          previous?.status == SyncStatus.syncing) {
        _loadExpenses();
      }
    });
    return const ExpensesState(
      expenses: [],
      isLoading: true,
      searchQuery: '',
      categoryFilter: 'All',
      accountIdFilter: 'All',
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

      // 4. Sync Approved Salary Advances
      final advances = await dbService.db.getAll(dbService.db.advanceRecordsTable);
      for (final adv in advances) {
        if (adv.status == 'Approved' || adv.status == 'Fully Paid') {
          final expId = 'ADV-EXP-${adv.id}';
          if (!existingExpenseIds.contains(expId) && !existingExpenseIds.contains('exp_adv_${adv.id}') && adv.amount > 0) {
            final expRecord = ExpenseRecord(
              id: expId,
              date: adv.requestDate.length > 10 ? adv.requestDate : (adv.requestDate.isNotEmpty ? '${adv.requestDate}T00:00:00.000' : DateTime.now().toIso8601String()),
              amount: adv.amount,
              accountId: defaultAccountId,
              category: 'Salary Advances',
              vendorName: adv.employeeName,
              description: 'Salary Advance disbursed to ${adv.employeeName}',
            );
            await _repository.addExpense(expRecord);
            existingExpenseIds.add(expId);
          }
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

  void setAccountIdFilter(String accountId) {
    state = state.copyWith(accountIdFilter: accountId);
  }

  void setDateRange(String? fromDate, String? toDate) {
    state = state.copyWith(fromDateFilter: fromDate, toDateFilter: toDate);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      categoryFilter: 'All',
      accountIdFilter: 'All',
      clearDates: true,
    );
  }

  Future<void> addExpense(ExpenseRecord record) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.expenses, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to create expense records.');
    }

    state = state.copyWith(isLoading: true);

    String isoDate = record.date;
    try {
      final match = RegExp(r'\d{12,14}').firstMatch(record.id);
      if (match != null) {
        final ms = int.tryParse(match.group(0)!);
        if (ms != null && ms > 0 && ms < 8640000000000000) {
          final timePart = DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String().substring(10);
          if (isoDate.length == 10) isoDate += timePart;
        }
      }
    } catch (_) {}
    if (isoDate.length == 10) {
      isoDate += DateTime.now().toIso8601String().substring(10);
    }

    final recordToSave = record.date.length == 10 ? record.copyWith(date: isoDate) : record;
    await _repository.addExpense(recordToSave);

    // Resolve Account Name
    final isKhata = recordToSave.accountId == 'general_khata';
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == recordToSave.accountId).firstOrNull;
    final accountName = isKhata ? 'General Khata' : (account?.name ?? 'Unknown Account');
    final isCompanyAccount = isKhata ? true : (account?.isCompany ?? true);

    // 1. Adjust bank account balance (Deduct expense amount only if not General Khata)
    if (!isKhata) {
      await ref.read(accountsProvider.notifier).adjustBalance(recordToSave.accountId, -recordToSave.amount);
    }

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

    // 3. Ledger entry already recorded above.
    // Auto-loans are not created for regular expenses to keep Loans module clean.

    ref.read(adminProvider.notifier).logAction(
      action: 'Added expense: ${recordToSave.description} (Amount: ${recordToSave.amount}, Category: ${recordToSave.category})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }

  Future<void> updateExpense(ExpenseRecord oldRecord, ExpenseRecord newRecord) async {
    final adminState = ref.read(adminProvider);
    final isSuperAdmin = adminState.currentUser?.isSuperAdmin == true ||
        adminState.currentUser?.role.trim().toLowerCase() == 'super admin' ||
        adminState.currentUser == null;
    if (!isSuperAdmin &&
        !adminState.hasPermission(AppModule.expenses, PermissionAction.edit) &&
        !adminState.hasPermission(AppModule.expenses, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to edit expense records.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.updateExpense(newRecord);

    // Resolve Account Name
    final accounts = ref.read(accountsProvider).accounts;
    final isOldKhata = oldRecord.accountId == 'general_khata';
    final isNewKhata = newRecord.accountId == 'general_khata';
    final account = accounts.where((a) => a.id == newRecord.accountId).firstOrNull;
    final accountName = isNewKhata ? 'General Khata' : (account?.name ?? 'Unknown Account');
    final isCompanyAccount = isNewKhata ? true : (account?.isCompany ?? true);

    // Bank Account Balance adjustment
    if (!isOldKhata && !isNewKhata) {
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
    } else if (!isOldKhata && isNewKhata) {
      // Switched from Bank Account to General Khata: refund the old bank account
      await ref.read(accountsProvider.notifier).adjustBalance(oldRecord.accountId, oldRecord.amount);
    } else if (isOldKhata && !isNewKhata) {
      // Switched from General Khata to Bank Account: deduct from the new bank account
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

    // If a legacy auto-loan existed for this expense, remove it
    final loanId = 'loan_exp_${newRecord.id}';
    final loans = await ref.read(loansRepositoryProvider).getLoans();
    final existingLoan = loans.where((l) => l.id == loanId).firstOrNull;
    if (existingLoan != null) {
      await ref.read(loansRepositoryProvider).deleteLoan(loanId);
      await ref.read(loansProvider.notifier).loadLoans();
    }

    ref.read(adminProvider.notifier).logAction(
      action: 'Updated expense: ${newRecord.description} (Amount: ${oldRecord.amount} → ${newRecord.amount}, Category: ${newRecord.category})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }

  Future<void> deleteExpense(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.expenses, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete expense records.');
    }

    ExpenseRecord? record = state.expenses.where((e) => e.id == id).firstOrNull;
    if (record == null) {
      final all = await _repository.getExpenses();
      record = all.where((e) => e.id == id).firstOrNull;
    }

    state = state.copyWith(isLoading: true);

    if (record != null) {
      await ref.read(recoveryProvider.notifier).addDeletedItem(
        id: record.id,
        itemType: 'Expense',
        title: '${record.category} (Rs. ${record.amount.toStringAsFixed(0)})',
        subtitle: '${record.description} • Date: ${record.date}',
        jsonData: record.toMap(),
        deletedBy: adminState.currentUser?.name ?? 'Admin',
      );

      // 1. Rollback bank account balance (Add back expense amount if not General Khata)
      if (record.accountId != 'general_khata') {
        await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, record.amount);
      }

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

    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted expense: ${record?.description ?? id} (Amount: ${record?.amount ?? 'N/A'})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
    final updated = await _repository.getExpenses();
    state = state.copyWith(expenses: updated, isLoading: false);
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, ExpensesState>(() {
  return ExpensesNotifier();
});
