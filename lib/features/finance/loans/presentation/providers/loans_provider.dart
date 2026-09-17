import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/loan_record.dart';
import '../../domain/repositories/loans_repository.dart';
import '../../data/repositories/loans_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';


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

  Future<void> addLoan(LoanRecord record, String accountId, {String? personalAccountId}) async {
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
    if (!desc.contains('[Account:')) {
      desc = '$desc\n[Account:$accountId|$accountName]';
    }
    if (personalAccountId != null && personalAccountId.isNotEmpty && !desc.contains('[PersonalAccount:')) {
      desc = '$desc\n[PersonalAccount:$personalAccountId|$personalAccountName]';
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
      final match = RegExp(r'loan_(\d{10,})').firstMatch(record.id);
      if (match != null) {
        final ms = int.tryParse(match.group(1)!);
        if (ms != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ms);
          final pDate = DateTime.tryParse(ledgerDate) ?? dt;
          ledgerDate = DateTime(pDate.year, pDate.month, pDate.day, dt.hour, dt.minute, dt.second, dt.millisecond).toIso8601String();
        }
      }
      if (ledgerDate.length == 10) {
        ledgerDate = '${record.startDate}T${DateTime.now().toIso8601String().substring(11)}';
      }
    }

    // Adjust Account Balance & Ledger entry
    final isPersonal = personalAccountId != null && personalAccountId.isNotEmpty;

    if (record.type == 'Lent') {
      // Deduct lent amount from company bank/cash account
      await ref.read(accountsProvider.notifier).adjustBalance(accountId, -record.amount);

      // If lent to Personal Account, add amount into that Personal Account
      if (isPersonal) {
        await ref.read(accountsProvider.notifier).adjustBalance(personalAccountId, record.amount);
      }
      
      // Credit / Outflow ledger entry
      final ledgerEntry = LedgerEntry(
        id: 'led_loan_init_${record.id}',
        date: ledgerDate,
        accountId: accountId,
        accountName: accountName,
        type: 'Credit',
        category: isPersonal ? 'Personal Loan Lent' : 'Loan Lent',
        amount: record.amount,
        reference: record.borrowerName,
        description: isPersonal
            ? 'Lent loan to Personal Account ($personalAccountName). ${taggedRecord.cleanDescription}'
            : 'Lent loan to: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
      );
      await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
    } else {
      // Add borrowed amount to company bank/cash account
      await ref.read(accountsProvider.notifier).adjustBalance(accountId, record.amount);

      // If borrowed from Personal Account, deduct amount from that Personal Account
      if (isPersonal) {
        await ref.read(accountsProvider.notifier).adjustBalance(personalAccountId, -record.amount);
      }

      // Debit / Inflow ledger entry
      final ledgerEntry = LedgerEntry(
        id: 'led_loan_init_${record.id}',
        date: ledgerDate,
        accountId: accountId,
        accountName: accountName,
        type: 'Debit',
        category: isPersonal ? 'Personal Loan Borrowed' : 'Loan Borrowed',
        amount: record.amount,
        reference: record.borrowerName,
        description: isPersonal
            ? 'Borrowed loan from Personal Account ($personalAccountName). ${taggedRecord.cleanDescription}'
            : 'Borrowed loan from: ${record.borrowerName}. ${taggedRecord.cleanDescription}',
      );
      await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
    }

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updated = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updated), isLoading: false);
  }

  Future<void> recordRepayment(String loanId, LoanRepayment repayment) async {
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

    final isPersonal = loan.isPersonalLoan && loan.personalAccountId.isNotEmpty;

    // Adjust Account Balance & Ledger entry
    if (loan.type == 'Lent') {
      // We are receiving repayments for money we lent -> Company gets Inflow / Debit
      await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, repayment.amount);

      // If it's a personal loan, Personal Account pays out this repayment
      if (isPersonal) {
        await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -repayment.amount);
      }

      final ledgerEntry = LedgerEntry(
        id: 'led_loan_rep_${repayment.id}',
        date: repayment.date,
        accountId: repayment.accountId,
        accountName: repayment.accountName,
        type: 'Debit',
        category: isPersonal ? 'Personal Loan Repayment Inflow' : 'Loan Repayment Inflow',
        amount: repayment.amount,
        reference: loan.borrowerName,
        description: 'Received installment repayment for loan ID: ${loan.id} from ${loan.borrowerName}',
      );
      await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
    } else {
      // We are paying repayments for money we borrowed -> Company pays Outflow / Credit
      await ref.read(accountsProvider.notifier).adjustBalance(repayment.accountId, -repayment.amount);

      // If it's a personal loan, Personal Account receives this repayment back
      if (isPersonal) {
        await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, repayment.amount);
      }

      final ledgerEntry = LedgerEntry(
        id: 'led_loan_rep_${repayment.id}',
        date: repayment.date,
        accountId: repayment.accountId,
        accountName: repayment.accountName,
        type: 'Credit',
        category: isPersonal ? 'Personal Loan Repayment Outflow' : 'Loan Repayment Outflow',
        amount: repayment.amount,
        reference: loan.borrowerName,
        description: 'Paid installment repayment for loan ID: ${loan.id} to ${loan.borrowerName}',
      );
      await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);
    }

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updatedList = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updatedList), isLoading: false);
  }

  Future<void> deleteLoan(String id) async {
    final list = List<LoanRecord>.from(state.loans);
    final index = list.indexWhere((l) => l.id == id);
    if (index == -1) return;

    state = state.copyWith(isLoading: true);
    final loan = list[index];

    // Rollback principal transaction for Company Account
    final ledgerEntries = ref.read(ledgerProvider).entries;
    final initLedger = ledgerEntries.where((e) => e.id == 'led_loan_init_${loan.id}').firstOrNull;
    final targetAccountId = loan.resolvedAccountId.isNotEmpty
        ? loan.resolvedAccountId
        : initLedger?.accountId;

    if (targetAccountId != null && targetAccountId.isNotEmpty) {
      if (loan.type == 'Lent') {
        // Lent was outflow/Credit (subtracted balance), so rollback adds it back
        await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, loan.amount);
      } else {
        // Borrowed was inflow/Debit (added balance), so rollback subtracts it
        await ref.read(accountsProvider.notifier).adjustBalance(targetAccountId, -loan.amount);
      }
    }

    // Rollback principal transaction for Personal Account if applicable
    if (loan.isPersonalLoan && loan.personalAccountId.isNotEmpty) {
      if (loan.type == 'Lent') {
        // Lent was inflow to Personal Account, so rollback subtracts it
        await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -loan.amount);
      } else {
        // Borrowed was outflow from Personal Account, so rollback adds it back
        await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, loan.amount);
      }
    }

    if (initLedger != null) {
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry(initLedger.id);
    }

    // Rollback all repayments
    for (var rep in loan.repayments) {
      if (loan.type == 'Lent') {
        // Repayment received was Debit (added balance to company), so rollback subtracts it
        await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, -rep.amount);
        // Personal account had paid it (-), so rollback adds it back
        if (loan.isPersonalLoan && loan.personalAccountId.isNotEmpty) {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, rep.amount);
        }
      } else {
        // Repayment paid was Credit (subtracted balance from company), so rollback adds it back
        await ref.read(accountsProvider.notifier).adjustBalance(rep.accountId, rep.amount);
        // Personal account had received it (+), so rollback subtracts it
        if (loan.isPersonalLoan && loan.personalAccountId.isNotEmpty) {
          await ref.read(accountsProvider.notifier).adjustBalance(loan.personalAccountId, -rep.amount);
        }
      }
      await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_loan_rep_${rep.id}');
    }

    await _repository.deleteLoan(id);

    await ref.read(accountsProvider.notifier).loadAccounts();
    await ref.read(ledgerProvider.notifier).loadEntries();

    final updatedList = await _repository.getLoans();
    state = state.copyWith(loans: _enrichLoansWithAccounts(updatedList), isLoading: false);
  }
}

final loansProvider = NotifierProvider<LoansNotifier, LoansState>(() {
  return LoansNotifier();
});
