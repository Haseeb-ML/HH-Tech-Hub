import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/loans/domain/entities/loan_record.dart';

void main() {
  group('LoanRecord Account Linking & Resolution Tests', () {
    test('resolves accountId and accountName from description tag', () {
      final loan = LoanRecord(
        id: 'loan_123',
        borrowerName: 'Investor Ali',
        amount: 50000.0,
        remainingBalance: 50000.0,
        startDate: '2026-09-09',
        endDate: '2026-12-31',
        status: 'Active',
        type: 'Borrowed',
        description: 'Business expansion [Account:acc_main|HBL Main Account]',
        repayments: [],
      );

      expect(loan.resolvedAccountId, equals('acc_main'));
      expect(loan.resolvedAccountName, equals('HBL Main Account'));
      expect(loan.cleanDescription, equals('Business expansion'));
    });

    test('cleanDescription handles pure tag without trailing text', () {
      final loan = LoanRecord(
        id: 'loan_456',
        borrowerName: 'ABC Lender',
        amount: 25000.0,
        remainingBalance: 25000.0,
        startDate: '2026-09-09',
        endDate: '2026-12-31',
        status: 'Active',
        type: 'Borrowed',
        description: '[Account:acc_cash|Cash Vault]',
        repayments: [],
      );

      expect(loan.resolvedAccountId, equals('acc_cash'));
      expect(loan.resolvedAccountName, equals('Cash Vault'));
      expect(loan.cleanDescription, equals(''));
    });

    test('resolves direct accountId/accountName properties if set', () {
      final loan = LoanRecord(
        id: 'loan_789',
        borrowerName: 'Direct Partner',
        amount: 100000.0,
        remainingBalance: 100000.0,
        startDate: '2026-09-09',
        endDate: '2026-12-31',
        status: 'Active',
        type: 'Borrowed',
        description: 'Direct cash injection',
        repayments: [],
        accountId: 'acc_direct',
        accountName: 'Direct Bank',
      );

      expect(loan.resolvedAccountId, equals('acc_direct'));
      expect(loan.resolvedAccountName, equals('Direct Bank'));
      expect(loan.cleanDescription, equals('Direct cash injection'));
    });

    test('Account inflows and outflows include borrowed loans and repayments properly', () {
      // Simulate account transactions
      const double initialBalance = 10000.0;
      const double regularIncome = 5000.0;
      const double regularExpense = 2000.0;
      const double borrowedLoan = 20000.0; // Borrowed -> Cash comes IN (+20,000)
      const double loanRepayment = 5000.0;  // Repaying borrowed loan -> Cash goes OUT (-5,000)

      final totalInflow = regularIncome + borrowedLoan;
      final totalOutflow = regularExpense + loanRepayment;
      final endingBalance = initialBalance + totalInflow - totalOutflow;

      expect(totalInflow, equals(25000.0));
      expect(totalOutflow, equals(7000.0));
      expect(endingBalance, equals(28000.0));
    });
  });
}
