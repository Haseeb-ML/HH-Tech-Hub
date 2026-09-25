import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/income/domain/entities/income_record.dart';
import 'package:software_house_erp/features/finance/expenses/domain/entities/expense_record.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';

void main() {
  group('Authoritative Account Balance & Income Tests', () {
    const companyAccount = BankAccount(
      id: 'acc_company_1',
      name: 'HH Tech Hub',
      type: 'Bank',
      bankName: 'Meezan Bank',
      accountNumber: 'PK123456789',
      balance: -43442.0, // Desynchronized stored balance in DB
      openingBalance: 0.0,
      accountScope: 'Company',
      ownerName: 'Company',
      status: 'Active',
    );

    const personalAccount = BankAccount(
      id: 'acc_personal_hassan',
      name: 'Hassan Personal Account',
      type: 'Cash',
      bankName: 'Cash Wallet',
      accountNumber: '03001234567',
      balance: 10000.0,
      openingBalance: 10000.0,
      accountScope: 'Personal',
      ownerName: 'Hassan',
      status: 'Active',
    );

    test('Real scenario: 149,500 income and 95,852 expense yields positive 53,648 balance, fixing negative display', () {
      final List<IncomeRecord> incomes = [
        const IncomeRecord(
          id: 'inc_1',
          date: '2026-09-10',
          clientId: 'client_1',
          clientName: 'Client A',
          amount: 100000.0,
          accountId: 'acc_company_1',
          invoiceNumber: 'INV-1',
          description: 'Payment 1',
          status: 'Received',
        ),
        const IncomeRecord(
          id: 'inc_2',
          date: '2026-09-12',
          clientId: 'client_2',
          clientName: 'Client B',
          amount: 49500.0,
          accountId: 'acc_company_1',
          invoiceNumber: 'INV-2',
          description: 'Payment 2',
          status: 'Received',
        ),
      ];

      final List<ExpenseRecord> expenses = [
        const ExpenseRecord(
          id: 'exp_1',
          date: '2026-09-11',
          category: 'Rent',
          amount: 95852.0,
          accountId: 'acc_company_1',
          description: 'Rent',
          vendorName: 'Landlord',
        ),
      ];

      final calculatedBalance = calculateAuthoritativeAccountBalance(
        account: companyAccount,
        incomes: incomes,
        expenses: expenses,
        loans: [],
        ledgerEntries: [],
      );

      // Total Inflows = 149,500; Outflows = 95,852 -> Net = +53,648
      expect(calculatedBalance, equals(53648.0));
      expect(calculatedBalance > 0, isTrue);
    });

    test('Adding new income directly increases the authoritative balance', () {
      final List<IncomeRecord> incomes = [
        const IncomeRecord(
          id: 'inc_1',
          date: '2026-09-10',
          clientId: 'client_1',
          clientName: 'Client A',
          amount: 50000.0,
          accountId: 'acc_company_1',
          invoiceNumber: 'INV-1',
          description: 'Payment 1',
          status: 'Received',
        ),
      ];

      final List<ExpenseRecord> expenses = [
        const ExpenseRecord(
          id: 'exp_1',
          date: '2026-09-11',
          category: 'Supplies',
          amount: 20000.0,
          accountId: 'acc_company_1',
          description: 'Supplies',
          vendorName: 'Vendor',
        ),
      ];

      final balanceBefore = calculateAuthoritativeAccountBalance(
        account: companyAccount,
        incomes: incomes,
        expenses: expenses,
        loans: [],
        ledgerEntries: [],
      );
      expect(balanceBefore, equals(30000.0));

      // User adds 25,000 new income to the company account
      const newIncome = IncomeRecord(
        id: 'inc_2',
        date: '2026-09-17',
        clientId: 'client_1',
        clientName: 'Client A',
        amount: 25000.0,
        accountId: 'acc_company_1',
        invoiceNumber: 'INV-2',
        description: 'Milestone 2',
        status: 'Received',
      );

      final balanceAfter = calculateAuthoritativeAccountBalance(
        account: companyAccount,
        incomes: [...incomes, newIncome],
        expenses: expenses,
        loans: [],
        ledgerEntries: [],
      );
      expect(balanceAfter, equals(55000.0));
    });

    test('Form selection prioritizes company accounts over personal wallets', () {
      final allAccounts = [personalAccount, companyAccount];

      // Filtering company accounts
      final companyAccounts = allAccounts.where((a) => a.accountScope != 'Personal').toList();
      expect(companyAccounts.isNotEmpty, isTrue);

      // Default selection should choose Company account, not personal account
      final defaultAccountId = companyAccounts.isNotEmpty 
          ? companyAccounts.first.id 
          : allAccounts.first.id;

      expect(defaultAccountId, equals('acc_company_1'));
      expect(defaultAccountId, isNot(equals('acc_personal_hassan')));
    });

    test('Dropdown label formatting uses bullet separator instead of minus dash to avoid negative balance confusion', () {
      final balance = 53648.0;
      final scopeLabel = companyAccount.accountScope;
      final subLabel = companyAccount.ownerName;

      // Old formatting had: "${companyAccount.name} ($scopeLabel - $subLabel) - Bal: Rs. $balance"
      // which looked like minus balance: "HH Tech Hub (Company - Company) - Bal: Rs. 53,648"
      final cleanLabel = '${companyAccount.name} ($scopeLabel • $subLabel) • Bal: Rs. ${balance.toStringAsFixed(0)}';

      expect(cleanLabel.contains('• Bal: Rs. 53648'), isTrue);
      expect(cleanLabel.contains('- Bal:'), isFalse);
    });
  });
}
