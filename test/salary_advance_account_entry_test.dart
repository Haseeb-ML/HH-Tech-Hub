import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';

void main() {
  group('Salary Advance Account & Ledger Integration Tests', () {
    const hassanPersonalAccount = BankAccount(
      id: 'acc_personal_hassan',
      name: 'Hassan Personal Account',
      type: 'Bank',
      bankName: 'Meezan Bank',
      accountNumber: 'PK-HASSAN-01',
      balance: 100000.0,
      openingBalance: 100000.0,
      accountScope: 'Personal',
      ownerName: 'Hassan',
      status: 'Active',
    );

    const companyBankAccount = BankAccount(
      id: 'acc_company_meezan',
      name: 'HH Tech Hub Main',
      type: 'Bank',
      bankName: 'Meezan Bank',
      accountNumber: 'PK-COMPANY-01',
      balance: 250000.0,
      openingBalance: 250000.0,
      accountScope: 'Company',
      status: 'Active',
    );

    test('calculateAuthoritativeAccountBalance deducts Salary Advance from Personal Account', () {
      final salaryAdvanceLedger = LedgerEntry(
        id: 'led_adv_12345',
        date: DateTime.now().toIso8601String(),
        accountId: hassanPersonalAccount.id,
        accountName: hassanPersonalAccount.name,
        type: 'Credit',
        category: 'Salary Advance',
        amount: 25000.0,
        reference: 'ADV-001',
        description: 'Salary Advance disbursed to Ali',
      );

      final balanceBefore = calculateAuthoritativeAccountBalance(
        account: hassanPersonalAccount,
        incomes: [],
        expenses: [],
        loans: [],
        ledgerEntries: [],
      );
      expect(balanceBefore, equals(100000.0));

      final balanceAfter = calculateAuthoritativeAccountBalance(
        account: hassanPersonalAccount,
        incomes: [],
        expenses: [],
        loans: [],
        ledgerEntries: [salaryAdvanceLedger],
      );
      expect(balanceAfter, equals(75000.0));
    });

    test('calculateAuthoritativeAccountBalance deducts Salary Advance from Company Account', () {
      final salaryAdvanceLedger = LedgerEntry(
        id: 'led_adv_67890',
        date: DateTime.now().toIso8601String(),
        accountId: companyBankAccount.id,
        accountName: companyBankAccount.name,
        type: 'Credit',
        category: 'Salary Advance',
        amount: 40000.0,
        reference: 'ADV-002',
        description: 'Salary Advance disbursed to Usman',
      );

      final balanceBefore = calculateAuthoritativeAccountBalance(
        account: companyBankAccount,
        incomes: [],
        expenses: [],
        loans: [],
        ledgerEntries: [],
      );
      expect(balanceBefore, equals(250000.0));

      final balanceAfter = calculateAuthoritativeAccountBalance(
        account: companyBankAccount,
        incomes: [],
        expenses: [],
        loans: [],
        ledgerEntries: [salaryAdvanceLedger],
      );
      expect(balanceAfter, equals(210000.0));
    });

    test('directAccountEntries filter correctly captures Salary Advance for Personal Account', () {
      final salaryAdvanceEntry = LedgerEntry(
        id: 'led_adv_hassan',
        date: '2026-09-17T12:00:00.000',
        accountId: 'acc_personal_hassan',
        accountName: 'Hassan Personal Account',
        type: 'Credit',
        category: 'Salary Advance',
        amount: 30000.0,
        reference: 'ADV-999',
        description: 'Salary Advance disbursed to Ahmed',
      );

      final transferEntry = LedgerEntry(
        id: 'led_tr_1',
        date: '2026-09-17T10:00:00.000',
        accountId: 'acc_personal_hassan',
        accountName: 'Hassan Personal Account',
        type: 'Debit',
        category: 'Personal Deposit',
        amount: 50000.0,
        reference: 'Cash',
        description: 'Cash deposit',
      );

      final otherAccountEntry = LedgerEntry(
        id: 'led_adv_other',
        date: '2026-09-17T11:00:00.000',
        accountId: 'acc_personal_huzaifa',
        accountName: 'Huzaifa Personal Account',
        type: 'Credit',
        category: 'Salary Advance',
        amount: 15000.0,
        reference: 'ADV-888',
        description: 'Salary Advance disbursed to Bilal',
      );

      final allEntries = [salaryAdvanceEntry, transferEntry, otherAccountEntry];

      final filtered = allEntries.where((entry) =>
          entry.accountId == 'acc_personal_hassan' &&
          (entry.category == 'Personal Deposit' ||
           entry.category == 'Company Deposit' ||
           entry.category == 'Account Transfer' ||
           entry.category == 'Salary Advance' ||
           entry.category == 'Other Expense')).toList();

      expect(filtered.length, equals(2));
      expect(filtered.any((e) => e.id == 'led_adv_hassan' && e.category == 'Salary Advance'), isTrue);

      final directOutflow = filtered
          .where((entry) => entry.type == 'Credit')
          .fold<double>(0.0, (sum, entry) => sum + entry.amount);
      expect(directOutflow, equals(30000.0));
    });

    test('directAccountEntries filter correctly captures Salary Advance for Company Account', () {
      final salaryAdvanceEntry = LedgerEntry(
        id: 'led_adv_comp',
        date: '2026-09-17T12:00:00.000',
        accountId: 'acc_company_meezan',
        accountName: 'HH Tech Hub Main',
        type: 'Credit',
        category: 'Salary Advance',
        amount: 18000.0,
        reference: 'ADV-555',
        description: 'Salary Advance disbursed to Hamza',
      );

      final allEntries = [salaryAdvanceEntry];

      final filtered = allEntries.where((entry) =>
          entry.accountId == 'acc_company_meezan' &&
          (entry.category == 'Account Transfer' ||
           entry.category == 'Personal Deposit' ||
           entry.category == 'Company Deposit' ||
           entry.category == 'Salary Advance' ||
           entry.category == 'Other Expense')).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.category, equals('Salary Advance'));
      expect(filtered.first.amount, equals(18000.0));
    });
  });
}
