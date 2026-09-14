import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/expenses/domain/entities/expense_record.dart';

void main() {
  group('ExpenseRecord sort order', () {
    test('user scenario: newly entered travel fuel cost appears on top above older office inventory and assets management', () {
      // 1. Older Asset entry created earlier today
      final assetExpense = const ExpenseRecord(
        id: 'AST-EXP-AST-26231',
        date: '2026-09-09T12:00:00.000',
        amount: 25000,
        accountId: 'acc1',
        category: 'Assets Management',
        vendorName: 'Asset Purchase',
        description: 'Asset purchase - Dell Monitor',
      );

      // 2. Older Inventory entry from yesterday or earlier
      final inventoryExpense = const ExpenseRecord(
        id: 'INV-EXP-INV-27171',
        date: '2026-09-08T18:58:47.222',
        amount: 9000,
        accountId: 'acc1',
        category: 'Office Inventory',
        vendorName: 'Inventory Purchase',
        description: 'Inventory purchase - Paper reams',
      );

      // 3. New entry: Travel Fuel Cost entered today with standard timestamp
      final travelFuelExpense = const ExpenseRecord(
        id: 'exp_1788936031357',
        date: '2026-09-09T12:15:30.000',
        amount: 1500,
        accountId: 'acc1',
        category: 'Travel',
        vendorName: 'Shell Petrol Station',
        description: 'fuel cost travel',
      );

      // Test with list ordered in any arbitrary way (e.g. Asset first, Inventory second, Fuel last)
      final rawList = [assetExpense, inventoryExpense, travelFuelExpense];
      final sorted = ExpenseRecord.sortExpensesNewestFirst(rawList);

      expect(sorted[0].id, travelFuelExpense.id, reason: 'Travel Fuel Cost must be at the top');
      expect(sorted[0].description, 'fuel cost travel');
      expect(sorted[1].id, assetExpense.id, reason: 'Today asset expense should be second');
      expect(sorted[2].id, inventoryExpense.id, reason: 'Yesterday inventory expense should be last');
    });

    test('new entry with legacy date-only string still resolves epoch timestamp from ID and appears on top of older asset', () {
      final oldAsset = const ExpenseRecord(
        id: 'AST-EXP-AST-26231',
        date: '2026-09-09T12:00:00.000',
        amount: 30000,
        accountId: 'acc1',
        category: 'Assets Management',
        vendorName: 'Asset Purchase',
        description: 'Asset purchase - Office Desk',
      );

      // Suppose a newly created expense had only YYYY-MM-DD stored in date, but ID has epoch ms for today 12:20 PM
      // (1788937200000 ms = ~12:20 PM on 2026-09-09)
      final newTravelExpense = const ExpenseRecord(
        id: 'exp_1788937200000',
        date: '2026-09-09',
        amount: 2000,
        accountId: 'acc1',
        category: 'Travel',
        vendorName: 'PSO',
        description: 'fuel cost travel',
      );

      final sorted = ExpenseRecord.sortExpensesNewestFirst([oldAsset, newTravelExpense]);

      expect(sorted.first.id, newTravelExpense.id, reason: 'New Travel Fuel Cost must be on top even if date was date-only');
      expect(sorted.last.id, oldAsset.id);
    });

    test('newer calendar days always sort above older calendar days', () {
      final sep8 = const ExpenseRecord(
        id: 'exp_1',
        date: '2026-09-08T23:59:59.000',
        amount: 100,
        accountId: 'acc1',
        category: 'Bills',
        vendorName: 'Electric',
        description: 'Bills',
      );

      final sep9 = const ExpenseRecord(
        id: 'exp_2',
        date: '2026-09-09T08:00:00.000',
        amount: 200,
        accountId: 'acc1',
        category: 'Supplies',
        vendorName: 'Stationery',
        description: 'Notebooks',
      );

      final sorted = ExpenseRecord.sortExpensesNewestFirst([sep8, sep9]);
      expect(sorted.first.id, 'exp_2');
      expect(sorted.last.id, 'exp_1');
    });

    test('same-day multiple user entries sort in descending order of creation time', () {
      final lunch = const ExpenseRecord(
        id: 'exp_1788936000000',
        date: '2026-09-09T12:00:00.000',
        amount: 500,
        accountId: 'acc1',
        category: 'Refreshments',
        vendorName: 'Restaurant',
        description: 'Team lunch',
      );

      final fuel = const ExpenseRecord(
        id: 'exp_1788939600000',
        date: '2026-09-09T13:00:00.000',
        amount: 1200,
        accountId: 'acc1',
        category: 'Travel',
        vendorName: 'Fuel pump',
        description: 'fuel cost travel',
      );

      final tea = const ExpenseRecord(
        id: 'exp_1788943200000',
        date: '2026-09-09T14:00:00.000',
        amount: 300,
        accountId: 'acc1',
        category: 'Refreshments',
        vendorName: 'Tea Stall',
        description: 'Evening tea',
      );

      final sorted = ExpenseRecord.sortExpensesNewestFirst([lunch, tea, fuel]);

      expect(sorted[0].id, tea.id, reason: '2:00 PM tea must be first');
      expect(sorted[1].id, fuel.id, reason: '1:00 PM fuel must be second');
      expect(sorted[2].id, lunch.id, reason: '12:00 PM lunch must be third');
    });
  });
}
