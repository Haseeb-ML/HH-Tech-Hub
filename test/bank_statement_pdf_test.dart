import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  group('Bank Statement Authentic PDF & Chronological Sorting Tests', () {
    test('sortTransactionsOldestFirst orders transactions chronologically from oldest to newest', () {
      final t1 = {
        'id': 't1',
        'sortKey': 't1',
        'date': DateTime(2025, 12, 3),
        'desc': 'Debit Card Fee',
        'ref': 'AC-PL52737',
        'inflow': 0.0,
        'outflow': 208.0,
      };

      final t2 = {
        'id': 't2',
        'sortKey': 't2',
        'date': DateTime(2025, 12, 10),
        'desc': 'Cash Deposit',
        'ref': '',
        'inflow': 30000.0,
        'outflow': 0.0,
      };

      final t3 = {
        'id': 't3',
        'sortKey': 't3',
        'date': DateTime(2026, 2, 26),
        'desc': 'ATM Cash Withdrawal',
        'ref': '958364',
        'inflow': 0.0,
        'outflow': 25000.0,
      };

      // Pass in shuffled order
      final sorted = ExportHelper.sortTransactionsOldestFirst([t3, t1, t2]);

      expect(sorted[0]['id'], 't1');
      expect(sorted[1]['id'], 't2');
      expect(sorted[2]['id'], 't3');
    });

    test('exportBankStatementPdf creates authentic bank statement PDF file', () async {
      const account = BankAccount(
        id: 'acc_allied_1',
        name: 'MUHAMMAD SHAKEEL',
        type: 'Bank',
        accountNumber: '0010129874530014',
        bankName: 'Allied Bank',
        balance: 1724533.75,
        status: 'Active',
      );

      final transactions = [
        {
          'id': 'tx_1',
          'sortKey': 'tx_1',
          'date': DateTime(2025, 12, 3),
          'desc': 'FED on Debit Card Fee',
          'ref': 'AC-PL52737',
          'inflow': 0.0,
          'outflow': 208.0,
        },
        {
          'id': 'tx_2',
          'sortKey': 'tx_2',
          'date': DateTime(2025, 12, 10),
          'desc': 'Cash Deposit',
          'ref': 'BR-RAWALPINDI',
          'inflow': 30000.0,
          'outflow': 0.0,
        },
        {
          'id': 'tx_3',
          'sortKey': 'tx_3',
          'date': DateTime(2026, 2, 26),
          'desc': 'ATM Cash Withdrawal',
          'ref': '958364',
          'inflow': 0.0,
          'outflow': 25000.0,
        },
      ];

      final filePath = await ExportHelper.exportBankStatementPdf(
        account: account,
        transactions: transactions,
        openingBalance: 59032.62,
        totalInflow: 30000.0,
        totalOutflow: 25208.0,
        closingBalance: 1724533.75,
        totalIncomeTx: 1,
        totalExpenseTx: 2,
      );

      expect(filePath.endsWith('.pdf'), isTrue);
      final file = File(filePath);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1000));
      
      // Clean up temporary test file
      try {
        file.deleteSync();
      } catch (_) {}
    });
  });
}
