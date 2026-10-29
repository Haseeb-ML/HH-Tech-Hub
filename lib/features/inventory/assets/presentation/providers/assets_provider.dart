import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/assets_repository.dart';
import '../../data/repositories/assets_repository_impl.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../../../finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';


class AssetsState {
  final List<Asset> assets;
  final bool isLoading;
  final String searchQuery;
  final String typeFilter; // 'All', 'Hardware', 'Software', 'Other'
  final String statusFilter; // 'All', 'Available', 'Assigned', 'Under Maintenance', 'Retired'

  const AssetsState({
    required this.assets,
    required this.isLoading,
    required this.searchQuery,
    required this.typeFilter,
    required this.statusFilter,
  });

  AssetsState copyWith({
    List<Asset>? assets,
    bool? isLoading,
    String? searchQuery,
    String? typeFilter,
    String? statusFilter,
  }) {
    return AssetsState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<Asset> get filteredAssets {
    return assets.where((asset) {
      final matchesSearch = asset.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          asset.serialNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (asset.assignedToName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);

      final matchesType = typeFilter == 'All' || asset.type == typeFilter;
      final matchesStatus = statusFilter == 'All' || asset.status == statusFilter;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }
}

final assetsRepositoryProvider = Provider<AssetsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AssetsRepositoryImpl(dbService);
});

class AssetsNotifier extends Notifier<AssetsState> {
  AssetsRepository get _repository => ref.read(assetsRepositoryProvider);

  @override
  AssetsState build() {
    _loadAssets();
    return const AssetsState(
      assets: [],
      isLoading: true,
      searchQuery: '',
      typeFilter: 'All',
      statusFilter: 'All',
    );
  }

  Future<void> _loadAssets() async {
    try {
      final list = await _repository.getAssets();
      state = state.copyWith(assets: list, isLoading: false);
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

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> addAsset(Asset asset) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.assets, PermissionAction.create)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.addAsset(asset);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added asset: ${asset.name} (Type: ${asset.type}, Cost: ${asset.cost})',
      module: 'Inventory',
    );
    final updated = await _repository.getAssets();
    state = state.copyWith(assets: updated, isLoading: false);
  }

  Future<void> updateAsset(Asset asset) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.assets, PermissionAction.edit)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    await _repository.updateAsset(asset);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated asset: ${asset.name} (Type: ${asset.type}, Status: ${asset.status})',
      module: 'Inventory',
    );
    final updated = await _repository.getAssets();
    state = state.copyWith(assets: updated, isLoading: false);
  }

  Future<void> deleteAsset(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.assets, PermissionAction.delete)) {
      return;
    }
    final asset = state.assets.where((a) => a.id == id).firstOrNull;
    if (asset != null) {
      await ref.read(recoveryProvider.notifier).addDeletedItem(
        id: asset.id,
        itemType: 'Asset',
        title: asset.name,
        subtitle: '${asset.type} • Serial: ${asset.serialNumber}',
        jsonData: asset.toMap(),
        deletedBy: adminState.currentUser?.name ?? 'Admin',
      );
    }
    state = state.copyWith(isLoading: true);

    // 1. Clean up associated purchase expenses and ledger entries
    final possibleExpIds = ['AST-EXP-$id', 'AST-EXP-AST-$id', id];
    for (final expId in possibleExpIds) {
      try {
        await ref.read(expensesProvider.notifier).deleteExpense(expId);
      } catch (_) {}
      try {
        await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_$expId');
      } catch (_) {}
    }

    // 2. Delete asset record from database
    await _repository.deleteAsset(id);

    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted asset: $id',
      module: 'Inventory',
    );

    // 3. Reload assets
    final updated = await _repository.getAssets();
    state = state.copyWith(assets: updated, isLoading: false);
  }

  Future<void> deleteAllAssets() async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.assets, PermissionAction.delete)) {
      return;
    }
    state = state.copyWith(isLoading: true);
    final all = await _repository.getAssets();
    for (final asset in all) {
      final possibleExpIds = ['AST-EXP-${asset.id}', 'AST-EXP-AST-${asset.id}', asset.id];
      for (final expId in possibleExpIds) {
        try {
          await ref.read(expensesProvider.notifier).deleteExpense(expId);
        } catch (_) {}
        try {
          await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_exp_$expId');
        } catch (_) {}
      }
      await _repository.deleteAsset(asset.id);
    }
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted all assets (${all.length} assets)',
      module: 'Inventory',
    );
    final updated = await _repository.getAssets();
    state = state.copyWith(assets: updated, isLoading: false);
  }
}

final assetsProvider = NotifierProvider<AssetsNotifier, AssetsState>(() {
  return AssetsNotifier();
});
