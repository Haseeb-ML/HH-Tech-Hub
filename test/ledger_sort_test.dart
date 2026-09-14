import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';
import 'package:software_house_erp/features/finance/expenses/domain/entities/expense_record.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';

void main() {
  group('LedgerEntry sort order', () {
    test('puts newest transactions first even when dates include time', () {
      final entries = [
        const LedgerEntry(
          id: '1',
          date: '2026-09-01T09:00:00',
          accountId: 'a',
          accountName: 'Cash',
          type: 'Debit',
          category: 'Income',
          amount: 100,
          reference: 'ref1',
          description: 'old',
        ),
        const LedgerEntry(
          id: '2',
          date: '2026-09-08T17:30:00',
          accountId: 'a',
          accountName: 'Cash',
          type: 'Debit',
          category: 'Income',
          amount: 500,
          reference: 'ref2',
          description: 'newer',
        ),
      ];

      final sorted = LedgerEntry.sortEntriesNewestFirst(entries);

      expect(sorted.first.description, 'newer');
      expect(sorted.last.description, 'old');
    });

    test('sorts by date-only strings correctly', () {
      final entries = [
        const LedgerEntry(
          id: 'old',
          date: '2026-08-31',
          accountId: 'a',
          accountName: 'Cash',
          type: 'Credit',
          category: 'Expense',
          amount: 50,
          reference: 'r1',
          description: 'old',
        ),
        const LedgerEntry(
          id: 'new',
          date: '2026-09-01',
          accountId: 'a',
          accountName: 'Cash',
          type: 'Debit',
          category: 'Income',
          amount: 200,
          reference: 'r2',
          description: 'new',
        ),
      ];

      final sorted = LedgerEntry.sortEntriesNewestFirst(entries);

      expect(sorted.first.id, 'new');
      expect(sorted.last.id, 'old');
    });

    test('same-minute entries sort with newer created entry (higher ID timestamp) on top', () {
      // Advance payment created first at 10:40 with seconds
      const advance = LedgerEntry(
        id: 'led_inc_inc_1788932408083',
        date: '2026-09-09T10:40:08.083',
        accountId: 'acc1',
        accountName: 'Cash',
        type: 'Debit',
        category: 'Client Income',
        amount: 18000,
        reference: 'Advance Payment',
        description: 'Project Advance',
      );

      // Partial payment created 45s later at 10:40 (picker gave :00.000)
      const partial = LedgerEntry(
        id: 'led_inc_inc_1788932453912',
        date: '2026-09-09T10:40:00.000',
        accountId: 'acc1',
        accountName: 'Cash',
        type: 'Debit',
        category: 'Client Income',
        amount: 4000,
        reference: 'Partial Payment',
        description: 'Project Partial',
      );

      final sorted = LedgerEntry.sortEntriesNewestFirst([advance, partial]);

      // Newer created entry (Partial) should be on top!
      expect(sorted.first.id, 'led_inc_inc_1788932453912');
      expect(sorted.last.id, 'led_inc_inc_1788932408083');
    });

    test('orders user real-world scenario: loan (11:05 AM) > partial (10:40 AM) > advance (10:40 AM) > yesterday inventory', () {
      final loan = const LedgerEntry(
        id: 'led_loan_init_loan_1788934732543',
        date: '2026-09-09T11:05:00.000',
        accountId: 'acc1',
        accountName: 'Meezan Business Account',
        type: 'Debit',
        category: 'Loan Borrowed',
        amount: 10000,
        reference: 'Arfan Malik',
        description: 'Borrowed loan from: Arfan Malik',
      );

      final advance = const LedgerEntry(
        id: 'led_inc_inc_1788932408083',
        date: '2026-09-09T10:40:08.083',
        accountId: 'acc2',
        accountName: 'HBL Account',
        type: 'Debit',
        category: 'Bank',
        amount: 18000,
        reference: 'Advance Payment',
        description: 'Generate image to invoice - Faheem',
      );

      final partial = const LedgerEntry(
        id: 'led_inc_inc_1788932453912',
        date: '2026-09-09T10:40:00.000',
        accountId: 'acc1',
        accountName: 'Meezan Business Account',
        type: 'Debit',
        category: 'Cash',
        amount: 4000,
        reference: 'Partial Payment',
        description: 'Generate image to invoice - Faheem',
      );

      final inventoryYesterday = const LedgerEntry(
        id: 'led_exp_INV-EXP-INV-27171',
        date: '2026-09-08T18:58:47.222',
        accountId: 'acc1',
        accountName: 'Meezan Business Account',
        type: 'Credit',
        category: 'Office Inventory',
        amount: 9000,
        reference: 'Inventory Purchase',
        description: 'Inventory purchase - ooo',
      );

      // Input in mixed/shuffled order
      final entries = [advance, inventoryYesterday, partial, loan];
      final sorted = LedgerEntry.sortEntriesNewestFirst(entries);

      expect(sorted[0].id, loan.id, reason: 'Loan at 11:05 AM must be on top');
      expect(sorted[1].id, partial.id, reason: 'Partial payment made second at 10:40 AM must be 2nd');
      expect(sorted[2].id, advance.id, reason: 'Advance payment made first at 10:40 AM must be 3rd');
      expect(sorted[3].id, inventoryYesterday.id, reason: 'Yesterday inventory purchase must be last');
    });
  });

  group('Bank statement export sorting', () {
    test('bank export lists newest transaction first', () {
      final transactions = [
        {'id': 'old-1', 'sortKey': 'old-1', 'date': DateTime(2026, 9, 1, 9, 0), 'desc': 'old', 'inflow': 100.0, 'outflow': 0.0},
        {'id': 'new-2', 'sortKey': 'new-2', 'date': DateTime(2026, 9, 8, 17, 30), 'desc': 'new', 'inflow': 500.0, 'outflow': 0.0},
      ];

      final sorted = ExportHelper.sortTransactionsNewestFirst(transactions);

      expect(sorted.first['desc'], 'new');
      expect(sorted.last['desc'], 'old');
    });

    test('same-day transactions use id as final tiebreaker', () {
      final transactions = [
        {'id': 'record-1', 'sortKey': 'record-1', 'date': DateTime(2026, 9, 8), 'desc': 'older same day', 'inflow': 100.0, 'outflow': 0.0},
        {'id': 'record-2', 'sortKey': 'record-2', 'date': DateTime(2026, 9, 8), 'desc': 'newer same day', 'inflow': 200.0, 'outflow': 0.0},
      ];

      final sorted = ExportHelper.sortTransactionsNewestFirst(transactions);

      expect(sorted.first['desc'], 'newer same day');
      expect(sorted.last['desc'], 'older same day');
    });
  });

  group('Expense category mapping', () {
    test('normalizes misc and keeps inventory and asset categories distinct in any case', () {
      expect(ExpenseRecord.normalizeCategory('Misc'), 'Other');
      expect(ExpenseRecord.normalizeCategory('other'), 'Other');
      expect(ExpenseRecord.normalizeCategory('office inventory'), 'Office Inventory');
      expect(ExpenseRecord.normalizeCategory('ASSETS MANAGEMENT'), 'Assets Management');
      expect(ExpenseRecord.inventoryCategory(), 'Office Inventory');
      expect(ExpenseRecord.assetCategory(), 'Assets Management');
    });
  });
}
