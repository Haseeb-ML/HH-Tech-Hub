import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../../../finance/ledger/presentation/providers/ledger_provider.dart';


class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String searchQuery;
  final String categoryFilter; // 'All', 'Stationery', 'Pantry', 'Merchandise', 'Office Supplies'

  const InventoryState({
    required this.items,
    required this.isLoading,
    required this.searchQuery,
    required this.categoryFilter,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  List<InventoryItem> get filteredItems {
    return items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory = categoryFilter == 'All' || item.category == categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return InventoryRepositoryImpl(dbService);
});

class InventoryNotifier extends Notifier<InventoryState> {
  InventoryRepository get _repository => ref.read(inventoryRepositoryProvider);

  @override
  InventoryState build() {
    _loadItems();
    return const InventoryState(
      items: [],
      isLoading: true,
      searchQuery: '',
      categoryFilter: 'All',
    );
  }

  Future<void> _loadItems() async {
    try {
      final list = await _repository.getInventoryItems();
      state = state.copyWith(items: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String filter) {
    state = state.copyWith(categoryFilter: filter);
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    state = state.copyWith(isLoading: true);
    await _repository.addInventoryItem(item);
    final updated = await _repository.getInventoryItems();
    state = state.copyWith(items: updated, isLoading: false);
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateInventoryItem(item);
    final updated = await _repository.getInventoryItems();
    state = state.copyWith(items: updated, isLoading: false);
  }

  Future<void> deleteInventoryItem(String id) async {
    state = state.copyWith(isLoading: true);

    // 1. Clean up associated purchase expenses and ledger entries
    final possibleExpIds = ['INV-EXP-$id', 'INV-EXP-INV-$id', id];
    for (final expId in possibleExpIds) {
      try {
        await ref.read(expensesProvider.notifier).deleteExpense(expId);
      } catch (_) {}
      try {
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_$expId');
      } catch (_) {}
    }

    // 2. Delete inventory item from database
    await _repository.deleteInventoryItem(id);

    // 3. Reload inventory items
    final updated = await _repository.getInventoryItems();
    state = state.copyWith(items: updated, isLoading: false);
  }

  Future<void> deleteAllInventoryItems() async {
    state = state.copyWith(isLoading: true);
    final all = await _repository.getInventoryItems();
    for (final item in all) {
      final possibleExpIds = ['INV-EXP-${item.id}', 'INV-EXP-INV-${item.id}', item.id];
      for (final expId in possibleExpIds) {
        try {
          await ref.read(expensesProvider.notifier).deleteExpense(expId);
        } catch (_) {}
        try {
          await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_$expId');
        } catch (_) {}
      }
      await _repository.deleteInventoryItem(item.id);
    }
    final updated = await _repository.getInventoryItems();
    state = state.copyWith(items: updated, isLoading: false);
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(() {
  return InventoryNotifier();
});
