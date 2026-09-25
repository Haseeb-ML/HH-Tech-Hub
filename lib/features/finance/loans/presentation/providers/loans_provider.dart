import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan_record.dart';
import '../../domain/repositories/loans_repository.dart';
import '../../data/repositories/loans_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';


class LoansState {
  final List<LoanRecord> loans;
  final bool isLoading;
  final String searchQuery;
  final String typeFilter; // 'All', 'Lent', 'Borrowed'

  const LoansState({
    required this.loans,
    required this.isLoading,
    required this.searchQuery,
    required this.typeFilter,
  });

  LoansState copyWith({
    List<LoanRecord>? loans,
    bool? isLoading,
    String? searchQuery,
    String? typeFilter,
  }) {
    return LoansState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  List<LoanRecord> get filteredLoans {
    final list = List<LoanRecord>.from(loans);
    list.sort((a, b) => b.startDate.compareTo(a.startDate));

    return list.where((l) {
      if (l.id.startsWith('loan_exp_') ||
          l.description.contains('[AutoExpense]') ||
          l.borrowerName == 'Owner (Drawings)' ||
          l.description.contains('Personal expense paid by Company Account') ||
          l.description.contains('Company expense paid by Personal Account')) {
        return false;
      }

      final matchesSearch = l.borrowerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          l.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesType = typeFilter == 'All' || l.type == typeFilter;

      return matchesSearch && matchesType;
    }).toList();
  }
}

final loansRepositoryProvider = Provider<LoansRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return LoansRepositoryImpl(dbService);
});

class LoansNotifier extends Notifier<LoansState> {
  LoansRepository get _repository => ref.read(loansRepositoryProvider);

  @override
  LoansState build() {
    loadLoans();
    return const LoansState(
      loans: [],
      isLoading: true,
      searchQuery: '',
      typeFilter: 'All',
    );
  }

  bool _isAutoExpenseLoan(LoanRecord l) {
    return l.id.startsWith('loan_exp_') ||
        l.description.contains('[AutoExpense]') ||
        l.borrowerName == 'Owner (Drawings)' ||
        l.description.contains('Personal expense paid by Company Account') ||
        l.description.contains('Company expense paid by Personal Account');
  }

  Future<void> loadLoans() async {
    try {
      final list = await _repository.getLoans();
      // Clean up legacy auto-created expense loans so they do not pollute Loans module
      final legacyAutoLoans = list.where(_isAutoExpenseLoan).toList();
      for (final l in legacyAutoLoans) {
        await _repository.deleteLoan(l.id);
      }
      final cleanList = list.where((l) => !_isAutoExpenseLoan(l)).toList();
      final enriched = _enrichLoansWithAccounts(cleanList);
      state = state.copyWith(loans: enriched, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<LoanRecord> _enrichLoansWithAccounts(List<LoanRecord> rawLoans) {
    final ledgerEntries = ref.read(ledgerProvider).entries;
    final accounts = ref.read(accountsProvider).accounts;

    return rawLoans.map((l) {
      String accId = l.resolvedAccountId;
      String accName = l.resolvedAccountName;

      if (accId.isEmpty) {
        final initLedger = ledgerEntries.where((e) => e.id == 'led_loan_init_${l.id}').firstOrNull;
        if (initLedger != null) {
          accId = initLedger.accountId;
          accName = initLedger.accountName;
        }
      }

      if (accName.isEmpty && accId.isNotEmpty) {
        final acc = accounts.where((a) => a.id == accId).firstOrNull;
        if (acc != null) accName = acc.name;
      }

      return l.copyWith(
        accountId: accId,
        accountName: accName,
      );
    }).toList();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(String filter) {
    state = state.copyWith(typeFilter: filter);
  }

  Future<void> addLoan(
    LoanRecord record,
    String accountId, {
    String? personalAccountId,
    String? loanScope,
  }) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.loans, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to create loans.');
    }

    state = state.copyWith(isLoading: true);

    // Resolve Account Name
    final accounts = await ref.read(accountsRepositoryProvider).getAccounts();
    final account = accounts.where((a) => a.id == accountId).firstOrNull;
    final accountName = account?.name ?? 'Bank/Cash Account';

    String personalAccountName = '';
    if (personalAccountId != null && personalAccountId.isNotEmpty) {
      final pAcc = accounts.where((a) => a.id == personalAccountId).firstOrNull;
      personalAccountName = pAcc != null
          ? (pAcc.ownerName.isNotEmpty ? pAcc.ownerName : pAcc.name)
          : 'Personal Account';
    }

    var desc = record.description.trim();
    final bool isPersonalExternal = loanScope == 'PersonalExternal' ||
        (personalAccountId != null && personalAccountId == accountId);
    final bool isInternal = loanScope == 'Internal' ||
        (!isPersonalExternal && personalAccountId != null && personalAccountId.isNotEmpty && personalAccountId != accountId);

    if (isPersonalExternal) {
      if (!desc.contains('[LoanScope:PersonalExternal]')) {
        desc = '$desc\n[LoanScope:PersonalExternal]';
      }
      if (!desc.contains('[PersonalAccount:')) {
        desc = '$desc\n[PersonalAccount:$personalAccountId|$personalAccountName]';
      }
      if (!desc.contains('[Account:')) {
        desc = '$desc\n[Account:$accountId|$accountName]';
      }
    } else if (isInternal) {
      if (!desc.contains('[LoanScope:Internal]')) {
        desc = '$desc\n[LoanScope:Internal]';
      }
      if (!desc.contains('[Account:')) {
        desc = '$desc\n[Account:$accountId|$accountName]';
      }
      if (!desc.contains('[PersonalAccount:')) {
        desc = '$desc\n[PersonalAccount:$personalAccountId|$personalAccountName]';
      }
    } else {
      if (!desc.contains('[Account:')) {
        desc = '$desc\n[Account:$accountId|$accountName]';
      }
    }

    final taggedRecord = record.copyWith(
      accountId: accountId,
      accountName: accountName,
      description: desc,
    );

    await _repository.addLoan(taggedRecord);

    // Resolve exact ISO date and time for ledger entry
    String ledgerDate = record.startDate;
    if (ledgerDate.length == 10) {
      try {
        final match = RegExp(r'loan_(\d{12,14})').firstMatch(record.id) ?? RegExp(r'\d{12,14}').firstMatch(record.id);
        if (match != null) {
          final ms = int.tryParse(match.group(1) ?? match.group(0)!);
          if (ms != null && ms > 0 && ms < 8640000000000000) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ms);
            final pDate = DateTime.tryParse(ledgerDate) ?? dt;
            ledgerDate = DateTime(pDate.year, pDate.month, pDate.day, dt.hour, dt.minute, dt.second, dt.millisecond).toIso8601String();
          }
        }
      } catch (_) {}
      if (ledgerDate.length == 10) {
        ledgerDate = '${record.startDate}T${DateTime.now().toIso8601String().substring(11)}';
      }
    }

    if (isPersonalExternal) {
      // 1. Personal Account Owner with External Third Party
      final pTargetId = personalAccountId ?? accountId;
      if (record.type == 'Lent') {
        // Owner lent cash from Personal Account to external party -> Personal Cash Outflow
        await ref.read(accountsProvider.notifier).adjustBalance(pTargetId, -record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: pTargetId,
          accountName: personalAccountName.isNotEmpty ? personalAccountName : accountName,
          type: 'Credit',
          category: 'Personal Loan Lent',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Personal funds lent to: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        // Owner borrowed cash from external party into Personal Account -> Personal Cash Inflow
        await ref.read(accountsProvider.notifier).adjustBalance(pTargetId, record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: pTargetId,
          accountName: personalAccountName.isNotEmpty ? personalAccountName : accountName,
          type: 'Debit',
          category: 'Personal Loan Borrowed',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Personal loan borrowed from: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    } else if (isInternal) {
      // 2. Internal Loan (Company <-> Personal Account)
      if (record.type == 'Lent') {
        // Deduct lent amount from company bank/cash account
        await ref.read(accountsProvider.notifier).adjustBalance(accountId, -record.amount);
        // Add amount into Personal Account
        await ref.read(accountsProvider.notifier).adjustBalance(personalAccountId!, record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: accountId,
          accountName: accountName,
          type: 'Credit',
          category: 'Personal Loan Lent',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Lent loan to Personal Account ($personalAccountName). ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        // Add borrowed amount to company bank/cash account
        await ref.read(accountsProvider.notifier).adjustBalance(accountId, record.amount);
        // Deduct amount from Personal Account
        await ref.read(accountsProvider.notifier).adjustBalance(personalAccountId!, -record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: accountId,
          accountName: accountName,
          type: 'Debit',
          category: 'Personal Loan Borrowed',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Borrowed loan from Personal Account ($personalAccountName). ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    } else {
      // 3. Company Loan with External Third Party
      if (record.type == 'Lent') {
        await ref.read(accountsProvider.notifier).adjustBalance(accountId, -record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: accountId,
          accountName: accountName,
          type: 'Credit',
          category: 'Loan Lent',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Lent loan to: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        await ref.read(accountsProvider.notifier).adjustBalance(accountId, record.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_init_${record.id}',
          date: ledgerDate,
          accountId: accountId,
          accountName: accountName,
          type: 'Debit',
          category: 'Loan Borrowed',
          amount: record.amount,
          reference: record.borrowerName,
          description: 'Borrowed loan from: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    }

    ref.read(adminProvider.notifier).logAction(
      action: 'Added loan: ${record.type} ${record.amount} (Borrower: ${record.borrowerName})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updated = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updated), isLoading: false);
  }

  Future<void> recordRepayment(String loanId, LoanRepayment repayment) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.loans, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to record repayments.');
    }

    final list = List<LoanRecord>.from(state.loans);
    final index = list.indexWhere((l) => l.id == loanId);
    if (index == -1) return;

    state = state.copyWith(isLoading: true);
    final loan = list[index];

    final updatedRepayments = List<LoanRepayment>.from(loan.repayments)..add(repayment);
    final double newRemaining = loan.remainingBalance - repayment.amount;
    final String newStatus = newRemaining <= 0 ? 'Repaid' : 'Active';

    final updatedLoan = loan.copyWith(
      repayments: updatedRepayments,
      remainingBalance: newRemaining < 0 ? 0.0 : newRemaining,
      status: newStatus,
    );

    await _repository.updateLoan(updatedLoan);

    if (loan.isPersonalExternalLoan) {
      // 1. Personal Account with External Third Party
      if (loan.type == 'Lent') {
        // Outside borrower repays Owner -> Personal Account gets Inflow / Debit
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, repayment.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Debit',
          category: 'Personal Loan Repayment Inflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Received installment repayment for personal loan ID: ${loan.id} from ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        // Owner repays outside lender -> Personal Account pays Outflow / Credit
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, -repayment.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Credit',
          category: 'Personal Loan Repayment Outflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Paid installment repayment for personal loan ID: ${loan.id} to ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    } else if (loan.isInternalLoan) {
      // 2. Internal Loan (Company <-> Personal Account)
      if (loan.type == 'Lent') {
        // Owner repays Company -> Company gets Inflow / Debit
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, repayment.amount);
        // Personal Account pays out this repayment
        if (loan.personalAccountId.isNotEmpty) {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -repayment.amount);
        }

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Debit',
          category: 'Personal Loan Repayment Inflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Received installment repayment for loan ID: ${loan.id} from ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        // Company repays Owner -> Company pays Outflow / Credit
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, -repayment.amount);
        // Personal Account receives this repayment back
        if (loan.personalAccountId.isNotEmpty) {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, repayment.amount);
        }

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Credit',
          category: 'Personal Loan Repayment Outflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Paid installment repayment for loan ID: ${loan.id} to ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    } else {
      // 3. Company Loan with External Third Party
      if (loan.type == 'Lent') {
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, repayment.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Debit',
          category: 'Loan Repayment Inflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Received installment repayment for loan ID: ${loan.id} from ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      } else {
        await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, -repayment.amount);

        final ledgerEntry = LedgerEntry(
          id: 'led_loan_rep_${repayment.id}',
          date: repayment.date,
          accountId: repayment.accountId,
          accountName: repayment.accountName,
          type: 'Credit',
          category: 'Loan Repayment Outflow',
          amount: repayment.amount,
          reference: loan.borrowerName,
          description: 'Paid installment repayment for loan ID: ${loan.id} to ${loan.borrowerName}',
        );
        await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
      }
    }

    ref.read(adminProvider.notifier).logAction(
      action: 'Recorded repayment of ${repayment.amount} for loan ${loan.borrowerName} (Remaining: ${newRemaining < 0 ? 0.0 : newRemaining})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updatedList = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updatedList), isLoading: false);
  }

  Future<void> deleteLoan(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.loans, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete loans.');
    }

    final list = List<LoanRecord>.from(state.loans);
    final index = list.indexWhere((l) => l.id == id);
    if (index == -1) return;

    state = state.copyWith(isLoading: true);
    final loan = list[index];

    final ledgerEntries = ref.read(ledgerProvider).entries;
    final initLedger = ledgerEntries.where((e) => e.id == 'led_loan_init_${loan.id}').firstOrNull;

    if (loan.isPersonalExternalLoan) {
      // 1. Personal Account with External Party rollback
      final targetAccId = loan.personalAccountId.isNotEmpty
          ? loan.personalAccountId
          : (loan.resolvedAccountId.isNotEmpty ? loan.resolvedAccountId : initLedger?.accountId);

      if (targetAccId != null && targetAccId.isNotEmpty) {
        if (loan.type == 'Lent') {
          // Lent was outflow, so rollback adds back
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccId, loan.amount);
        } else {
          // Borrowed was inflow, so rollback subtracts
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccId, -loan.amount);
        }
      }

      for (var rep in loan.repayments) {
        if (loan.type == 'Lent') {
          // Repayment was Debit (added), so rollback subtracts
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, -rep.amount);
        } else {
          // Repayment was Credit (subtracted), so rollback adds back
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, rep.amount);
        }
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_loan_rep_${rep.id}');
      }
    } else if (loan.isInternalLoan) {
      // 2. Internal Loan rollback
      final targetAccountId = loan.resolvedAccountId.isNotEmpty
          ? loan.resolvedAccountId
          : initLedger?.accountId;

      if (targetAccountId != null && targetAccountId.isNotEmpty) {
        if (loan.type == 'Lent') {
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, loan.amount);
        } else {
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, -loan.amount);
        }
      }

      if (loan.personalAccountId.isNotEmpty) {
        if (loan.type == 'Lent') {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -loan.amount);
        } else {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, loan.amount);
        }
      }

      for (var rep in loan.repayments) {
        if (loan.type == 'Lent') {
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, -rep.amount);
          if (loan.personalAccountId.isNotEmpty) {
            await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, rep.amount);
          }
        } else {
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, rep.amount);
          if (loan.personalAccountId.isNotEmpty) {
            await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -rep.amount);
          }
        }
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_loan_rep_${rep.id}');
      }
    } else {
      // 3. Company Loan with External Party rollback
      final targetAccountId = loan.resolvedAccountId.isNotEmpty
          ? loan.resolvedAccountId
          : initLedger?.accountId;

      if (targetAccountId != null && targetAccountId.isNotEmpty) {
        if (loan.type == 'Lent') {
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, loan.amount);
        } else {
          await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, -loan.amount);
        }
      }

      for (var rep in loan.repayments) {
        if (loan.type == 'Lent') {
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, -rep.amount);
        } else {
          await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, rep.amount);
        }
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_loan_rep_${rep.id}');
      }
    }

    if (initLedger != null) {
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry(initLedger.id);
    }

    await _repository.deleteLoan(id);

    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted loan: ${loan.type} ${loan.amount} (Borrower: ${loan.borrowerName})',
      module: 'Finance',
    );

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updatedList = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updatedList), isLoading: false);
  }
}

final loansProvider = NotifierProvider<LoansNotifier, LoansState>(() {
  return LoansNotifier();
});
