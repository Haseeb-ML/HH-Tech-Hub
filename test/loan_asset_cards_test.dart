import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/loans/domain/entities/loan_record.dart';
import 'package:software_house_erp/features/inventory/assets/domain/entities/asset.dart';

void main() {
  group('Loan and Asset Readable Cards & Optional End Date Tests', () {
    test('Loan with empty endDate is supported without error', () {
      final loan = LoanRecord(
        id: 'loan_opt_end',
        borrowerName: 'Haseeb Khan',
        amount: 50000.0,
        remainingBalance: 30000.0,
        startDate: '2026-09-09',
        endDate: '', // User chose optional end date
        status: 'Active',
        type: 'Lent',
        description: 'Short term loan [Account:acc_1|Meezan Bank]',
        repayments: [
          LoanRepayment(
            id: 'rep_1',
            date: '2026-09-10',
            amount: 20000.0,
            accountId: 'acc_1',
            accountName: 'Meezan Bank',
          ),
        ],
      );

      expect(loan.endDate, equals(''));
      expect(loan.repayments.length, equals(1));
      expect(loan.amount - loan.remainingBalance, equals(20000.0));
      expect(loan.resolvedAccountName, equals('Meezan Bank'));
      expect(loan.cleanDescription, equals('Short term loan'));
    });

    test('Asset card empty serial number safely displays placeholder', () {
      final asset = Asset(
        id: 'ast_laptop',
        name: 'MacBook Pro M2',
        type: 'Hardware',
        serialNumber: '',
        purchaseDate: '2026-05-15',
        cost: 350000.0,
        condition: 'Good',
        status: 'Available',
        assignedToId: null,
        assignedToName: null,
      );

      final displaySerial = asset.serialNumber.trim().isNotEmpty
          ? asset.serialNumber
          : 'No S/N';

      expect(displaySerial, equals('No S/N'));
      expect(asset.cost, equals(350000.0));
      expect(asset.assignedToId, isNull);
    });

    test('Asset card assigned employee reflects proper custody status', () {
      final asset = Asset(
        id: 'ast_monitor',
        name: 'Dell 27 4K Monitor',
        type: 'Hardware',
        serialNumber: 'DELL-987654',
        purchaseDate: '2026-02-10',
        cost: 85000.0,
        condition: 'Good',
        status: 'Assigned',
        assignedToId: 'emp_bilal',
        assignedToName: 'Bilal Ahmad',
      );

      expect(asset.serialNumber, equals('DELL-987654'));
      expect(asset.status, equals('Assigned'));
      expect(asset.assignedToId, equals('emp_bilal'));
      expect(asset.assignedToName, equals('Bilal Ahmad'));
    });
  });
}
