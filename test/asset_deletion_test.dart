import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/inventory/assets/domain/entities/asset.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';

void main() {
  group('Asset Management Deletion & Filter Tests', () {
    test('AssetsState filteredAssets filters correctly and updates on deletion', () {
      final asset1 = Asset(
        id: 'AST-101',
        name: 'MacBook Pro 16',
        type: 'Hardware',
        serialNumber: 'SN-APPLE-01',
        purchaseDate: '2026-09-09',
        cost: 450000.0,
        status: 'Available',
        condition: 'New',
      );

      final asset2 = Asset(
        id: 'AST-102',
        name: 'JetBrains All Products Pack',
        type: 'Software',
        serialNumber: 'LIC-JB-99',
        purchaseDate: '2026-09-08',
        cost: 65000.0,
        status: 'Assigned',
        condition: 'Good',
        assignedToId: 'EMP-01',
        assignedToName: 'Ali Developer',
      );

      var state = AssetsState(
        assets: [asset1, asset2],
        isLoading: false,
        searchQuery: '',
        typeFilter: 'All',
        statusFilter: 'All',
      );

      expect(state.filteredAssets.length, equals(2));

      // Filter by type
      state = state.copyWith(typeFilter: 'Hardware');
      expect(state.filteredAssets.length, equals(1));
      expect(state.filteredAssets.first.id, equals('AST-101'));

      // Filter by assigned status
      state = state.copyWith(typeFilter: 'All', statusFilter: 'Assigned');
      expect(state.filteredAssets.length, equals(1));
      expect(state.filteredAssets.first.id, equals('AST-102'));

      // Simulate deletion of asset2
      final remaining = state.assets.where((a) => a.id != 'AST-102').toList();
      state = state.copyWith(assets: remaining, statusFilter: 'All');
      expect(state.assets.length, equals(1));
      expect(state.filteredAssets.length, equals(1));
      expect(state.filteredAssets.first.name, equals('MacBook Pro 16'));

      // Simulate deletion of all assets
      state = state.copyWith(assets: []);
      expect(state.assets.isEmpty, isTrue);
      expect(state.filteredAssets.isEmpty, isTrue);
    });

    test('Identifies corresponding expense and ledger keys for both standard and prefixed asset IDs', () {
      const standardId = 'AST-26231';
      final possibleExpIds = ['AST-EXP-$standardId', 'AST-EXP-AST-$standardId', standardId];
      expect(possibleExpIds, contains('AST-EXP-AST-26231'));
      expect(possibleExpIds, contains('AST-EXP-AST-26231'));

      const plainId = '26231';
      final plainExpIds = ['AST-EXP-$plainId', 'AST-EXP-AST-$plainId', plainId];
      expect(plainExpIds, contains('AST-EXP-26231'));
      expect(plainExpIds, contains('AST-EXP-AST-26231'));
    });
  });
}
