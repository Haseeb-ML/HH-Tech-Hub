import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../../data/repositories/accounts_repository_impl.dart';


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
        updated = true;
      }

      if (!hasHuzaifa) {
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
    state = state.copyWith(isLoading: true);
    await _repository.addAccount(account);
    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
  }

  Future<void> updateAccount(BankAccount account) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateAccount(account);
    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
  }

  Future<void> deleteAccount(String id) async {
    if (id == 'acc_personal_hassan' ||
      id == 'acc_personal_huzaifa') {
      // Permanent accounts cannot be deleted
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.deleteAccount(id);
    final updated = await _repository.getAccounts();
    state = state.copyWith(accounts: updated, isLoading: false);
  }

  Future<void> loadAccounts() async {
    await _loadAccounts();
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
