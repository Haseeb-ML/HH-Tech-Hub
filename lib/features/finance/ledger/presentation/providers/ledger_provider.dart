import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';


class LedgerState {
  final List<LedgerEntry> entries;
  final bool isLoading;
  final String searchQuery;
  final String accountFilter; // 'All' or accountId
  final String typeFilter; // 'All', 'Debit', 'Credit'
  final DateTime? startDate;
  final DateTime? endDate;
  final int currentPage;

  const LedgerState({
    required this.entries,
    required this.isLoading,
    required this.searchQuery,
    required this.accountFilter,
    required this.typeFilter,
    this.startDate,
    this.endDate,
    this.currentPage = 0,
  });

  LedgerState copyWith({
    List<LedgerEntry>? entries,
    bool? isLoading,
    String? searchQuery,
    String? accountFilter,
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? currentPage,
  }) {
    return LedgerState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      accountFilter: accountFilter ?? this.accountFilter,
      typeFilter: typeFilter ?? this.typeFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<LedgerEntry> get filteredEntries {
    final list = List<LedgerEntry>.from(entries);
    final filtered = list.where((e) {
      final matchesSearch = e.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.reference.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesAccount = accountFilter == 'All' || e.accountId == accountFilter;

      bool matchesType = true;
      if (typeFilter == 'Debit') {
        matchesType = e.type == 'Debit';
      } else if (typeFilter == 'Credit') {
        matchesType = e.type == 'Credit';
      } else if (typeFilter == 'Loans') {
        matchesType = e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan');
      } else if (typeFilter == 'Loans: Borrowed') {
        matchesType = (e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan')) && e.category.toLowerCase().contains('borrowed');
      } else if (typeFilter == 'Loans: Lent') {
        matchesType = (e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan')) && e.category.toLowerCase().contains('lent');
      }

      bool matchesDate = true;
      if (startDate != null && endDate != null) {
        try {
          final entryDate = DateTime.parse(e.date);
          final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
          final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
          matchesDate = entryDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        entryDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (_) {}
      }

      return matchesSearch && matchesAccount && matchesType && matchesDate;
    }).toList();

    return LedgerEntry.sortEntriesNewestFirst(filtered);
  }
}

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return LedgerRepositoryImpl(dbService);
});

class LedgerNotifier extends Notifier<LedgerState> {
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  LedgerState build() {
    loadEntries();
    ref.listen<SyncState>(cloudSyncStateProvider, (previous, next) {
      if ((next.status == SyncStatus.success || next.status == SyncStatus.offline) &&
          previous?.status == SyncStatus.syncing) {
        loadEntries();
      }
    });
    return const LedgerState(
      entries: [],
      isLoading: true,
      searchQuery: '',
      accountFilter: 'All',
      typeFilter: 'All',
      startDate: null,
      endDate: null,
    );
  }

  Future<void> loadEntries() async {
    try {
      final list = await _repository.getLedgerEntries();
      state = state.copyWith(entries: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 0);
  }

  void setAccountFilter(String filter) {
    state = state.copyWith(accountFilter: filter, currentPage: 0);
  }

  void setTypeFilter(String filter) {
    state = state.copyWith(typeFilter: filter, currentPage: 0);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end, currentPage: 0);
  }

  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      accountFilter: 'All',
      typeFilter: 'All',
      startDate: null,
      endDate: null,
      currentPage: 0,
    );
  }

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    state = state.copyWith(isLoading: true);
    await _repository.addLedgerEntry(entry);
    final updated = await _repository.getLedgerEntries();
    state = state.copyWith(entries: updated, isLoading: false, currentPage: 0);
  }

  Future<void> updateLedgerEntry(LedgerEntry entry) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateLedgerEntry(entry);
    final updated = await _repository.getLedgerEntries();
    state = state.copyWith(entries: updated, isLoading: false);
  }

  Future<void> deleteLedgerEntry(String id) async {
    final found = state.entries.where((e) => e.id == id).firstOrNull;
    if (found != null) {
      final adminState = ref.read(adminProvider);
      final currentUser = adminState.currentUser?.name ?? 'Admin';
      await ref.read(recoveryProvider.notifier).addDeletedItem(
        id: found.id,
        itemType: 'LedgerEntry',
        title: '${found.type}: ${found.category} (Rs. ${found.amount.toStringAsFixed(0)})',
        subtitle: '${found.description} • Account: ${found.accountName}',
        jsonData: found.toMap(),
        deletedBy: currentUser,
      );
    }

    state = state.copyWith(isLoading: true);
    await _repository.deleteLedgerEntry(id);
    final updated = await _repository.getLedgerEntries();
    state = state.copyWith(entries: updated, isLoading: false);
  }
}

final ledgerProvider = NotifierProvider<LedgerNotifier, LedgerState>(() {
  return LedgerNotifier();
});
