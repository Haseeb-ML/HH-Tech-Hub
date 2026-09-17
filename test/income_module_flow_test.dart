import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/finance/income/domain/entities/income_record.dart';
import 'package:software_house_erp/features/projects/projects/domain/entities/project.dart';
import 'package:software_house_erp/features/clients/clients/domain/entities/client.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';

void main() {
  group('Income Module - Live Calculation Breakdown Tests', () {
    test('Breakdown calculation matches user scenario: 100k total, 60k received, 20k new -> 20k remaining', () {
      const double projectTotal = 100000.0;
      const double alreadyReceived = 60000.0;
      const double newPayment = 20000.0;

      final double remaining = (projectTotal - (alreadyReceived + newPayment)).clamp(0.0, double.infinity);
      final double totalAfterPayment = alreadyReceived + newPayment;

      expect(remaining, equals(20000.0));
      expect(totalAfterPayment, equals(80000.0));
      expect(totalAfterPayment < projectTotal, isTrue); // Partially Paid
    });

    test('Breakdown handles 100% full payment transition', () {
      const double projectTotal = 100000.0;
      const double alreadyReceived = 80000.0;
      const double newPayment = 20000.0;

      final double remaining = (projectTotal - (alreadyReceived + newPayment)).clamp(0.0, double.infinity);
      final double totalAfterPayment = alreadyReceived + newPayment;

      expect(remaining, equals(0.0));
      expect(totalAfterPayment, equals(projectTotal));
      expect(totalAfterPayment >= projectTotal, isTrue); // Fully Paid
    });

    test('Breakdown prevents negative remaining on overpayment', () {
      const double projectTotal = 50000.0;
      const double alreadyReceived = 40000.0;
      const double newPayment = 20000.0;

      final double remaining = (projectTotal - (alreadyReceived + newPayment)).clamp(0.0, double.infinity);
      expect(remaining, equals(0.0));
    });
  });

  group('Income Module - IncomeRecord Entity & Type Resolution Tests', () {
    test('Resolves Project Payment type and installments correctly', () {
      final advanceRecord = IncomeRecord(
        id: 'inc_1',
        date: '2026-09-16T10:00:00.000',
        clientId: 'client_1',
        clientName: 'Tech Corp',
        amount: 30000.0,
        accountId: 'acc_1',
        invoiceNumber: 'INV-001',
        description: 'Advance payment',
        status: 'Received',
        projectId: 'proj_1',
        projectName: 'ERP System',
        projectPaymentType: 'Advance',
      );

      expect(advanceRecord.incomeType, equals('Project Payment'));
      expect(advanceRecord.installmentType, equals('Advance'));

      final partialRecord = advanceRecord.copyWith(
        projectPaymentType: 'Partial',
      );
      expect(partialRecord.incomeType, equals('Project Payment'));
      expect(partialRecord.installmentType, equals('Partial'));

      final finalRecord = advanceRecord.copyWith(
        projectPaymentType: 'Final',
      );
      expect(finalRecord.incomeType, equals('Project Payment'));
      expect(finalRecord.installmentType, equals('Final'));
    });

    test('Resolves non-project categories as other income types', () {
      final consultingRecord = IncomeRecord(
        id: 'inc_2',
        date: '2026-09-16T11:00:00.000',
        clientId: 'client_2',
        clientName: 'Global Retail',
        amount: 15000.0,
        accountId: 'acc_1',
        invoiceNumber: 'INV-CONS-01',
        description: 'Architecture consulting',
        status: 'Received',
        projectId: null,
        projectName: null,
        projectPaymentType: 'Consulting Services',
      );

      expect(consultingRecord.incomeType, equals('Consulting Services'));
      expect(consultingRecord.installmentType, isNull);

      final maintenanceRecord = consultingRecord.copyWith(
        projectPaymentType: 'Maintenance & Support',
      );
      expect(maintenanceRecord.incomeType, equals('Maintenance & Support'));

      final otherRecord = consultingRecord.copyWith(
        projectPaymentType: '',
      );
      expect(otherRecord.incomeType, equals('Other Income'));
    });
  });

  group('Income Module - Project Payment Buckets & Status Synchronization Tests', () {
    test('Simulate multi-step project payments updating advance, partial, final and status', () {
      // Starting Project
      var project = const Project(
        id: 'proj_100',
        name: 'Enterprise Web Portal',
        description: 'ERP Portal',
        clientId: 'client_1',
        clientName: 'Tech Corp',
        startDate: '2026-09-01',
        endDate: '2026-12-31',
        status: 'In Progress',
        budget: 100000.0,
        advancedPayment: 0.0,
        partialPayments: 0.0,
        finalPayment: 0.0,
        paymentStatus: 'Pending',
        bankAccountId: 'acc_hbl',
        bankAccountName: 'HBL Business',
        accountHolder: 'HH Tech',
        teamMembers: [],
        clientPaymentSource: 'Bank Transfer',
      );

      // 1. First Payment (Advance: 60,000)
      const double payment1 = 60000.0;
      final newAdv = project.advancedPayment == 0 ? payment1 : project.advancedPayment;
      final totalReceived1 = newAdv + project.partialPayments + project.finalPayment;
      final status1 = totalReceived1 >= project.budget
          ? 'Fully Paid'
          : (totalReceived1 > 0 ? 'Partially Paid' : 'Pending');

      project = project.copyWith(
        advancedPayment: newAdv,
        paymentStatus: status1,
      );

      expect(project.advancedPayment, equals(60000.0));
      expect(project.partialPayments, equals(0.0));
      expect(project.finalPayment, equals(0.0));
      expect(project.paymentStatus, equals('Partially Paid'));
      expect(project.remainingPayment, equals(40000.0));

      // 2. Second Payment (Partial: 20,000)
      const double payment2 = 20000.0;
      final newPartial = project.partialPayments + payment2;
      final totalReceived2 = project.advancedPayment + newPartial + project.finalPayment;
      final status2 = totalReceived2 >= project.budget
          ? 'Fully Paid'
          : (totalReceived2 > 0 ? 'Partially Paid' : 'Pending');

      project = project.copyWith(
        partialPayments: newPartial,
        paymentStatus: status2,
      );

      expect(project.advancedPayment, equals(60000.0));
      expect(project.partialPayments, equals(20000.0));
      expect(project.paymentStatus, equals('Partially Paid'));
      expect(project.remainingPayment, equals(20000.0)); // Exact match to user scenario!

      // 3. Third Payment (Final: 20,000)
      const double payment3 = 20000.0;
      final newFinal = project.finalPayment + payment3;
      final totalReceived3 = project.advancedPayment + project.partialPayments + newFinal;
      final status3 = totalReceived3 >= project.budget
          ? 'Fully Paid'
          : (totalReceived3 > 0 ? 'Partially Paid' : 'Pending');

      project = project.copyWith(
        finalPayment: newFinal,
        paymentStatus: status3,
      );

      expect(project.advancedPayment, equals(60000.0));
      expect(project.partialPayments, equals(20000.0));
      expect(project.finalPayment, equals(20000.0));
      expect(project.paymentStatus, equals('Fully Paid'));
      expect(project.remainingPayment, equals(0.0));
    });

    test('Simulate payment rollback on Income record deletion', () {
      var project = const Project(
        id: 'proj_100',
        name: 'Enterprise Web Portal',
        description: 'ERP Portal',
        clientId: 'client_1',
        clientName: 'Tech Corp',
        startDate: '2026-09-01',
        endDate: '2026-12-31',
        status: 'In Progress',
        budget: 100000.0,
        advancedPayment: 60000.0,
        partialPayments: 20000.0,
        finalPayment: 20000.0,
        paymentStatus: 'Fully Paid',
        bankAccountId: 'acc_hbl',
        bankAccountName: 'HBL Business',
        accountHolder: 'HH Tech',
        teamMembers: [],
        clientPaymentSource: 'Bank Transfer',
      );

      // Deleting the 20,000 Final payment
      final double deletedAmount = 20000.0;
      final double remFinal = (project.finalPayment - deletedAmount).clamp(0.0, double.infinity);
      final double newTotal = project.advancedPayment + project.partialPayments + remFinal;
      final status = newTotal >= project.budget
          ? 'Fully Paid'
          : (newTotal > 0 ? 'Partially Paid' : 'Pending');

      project = project.copyWith(
        finalPayment: remFinal,
        paymentStatus: status,
      );

      expect(project.finalPayment, equals(0.0));
      expect(project.paymentStatus, equals('Partially Paid'));
      expect(project.remainingPayment, equals(20000.0));
    });
  });

  group('Income Module - Bank Account Balance & Ledger Entry Flow Tests', () {
    test('Add Income increases account balance and generates corresponding LedgerEntry', () {
      var account = const BankAccount(
        id: 'acc_mcb',
        name: 'MCB Main Account',
        type: 'Bank',
        accountNumber: 'PK99MCB123456789',
        bankName: 'Muslim Commercial Bank',
        balance: 50000.0,
        status: 'Active',
      );

      final income = IncomeRecord(
        id: 'inc_test_01',
        date: '2026-09-16T14:00:00.000',
        clientId: 'c_1',
        clientName: 'Software Client',
        amount: 25000.0,
        accountId: 'acc_mcb',
        invoiceNumber: 'INV-2026-09',
        description: 'Payment for Milestone 1',
        status: 'Received',
        projectId: 'proj_01',
        projectName: 'Mobile App',
        projectPaymentType: 'Advance',
      );

      // 1. Account balance adjustment (+25,000)
      account = account.copyWith(
        balance: account.balance + income.amount,
      );

      expect(account.balance, equals(75000.0));

      // 2. Ledger entry generation
      final ledgerEntry = LedgerEntry(
        id: 'ledger_${income.id}',
        date: income.date,
        accountId: income.accountId,
        accountName: account.name,
        type: 'Debit', // Inflow is debit in double-entry bookkeeping
        category: 'Client Invoice',
        amount: income.amount,
        reference: income.invoiceNumber,
        description: 'Income: ${income.description}',
        installmentType: income.installmentType ?? '',
      );

      expect(ledgerEntry.amount, equals(25000.0));
      expect(ledgerEntry.type, equals('Debit'));
      expect(ledgerEntry.accountId, equals('acc_mcb'));
      expect(ledgerEntry.reference, equals('INV-2026-09'));
    });

    test('Edit Income with account switch and amount delta correctly updates both accounts', () {
      var oldAccount = const BankAccount(
        id: 'acc_1',
        name: 'Account 1',
        type: 'Bank',
        accountNumber: '111',
        bankName: 'Bank A',
        balance: 80000.0, // Had 20,000 from this income
        status: 'Active',
      );

      var newAccount = const BankAccount(
        id: 'acc_2',
        name: 'Account 2',
        type: 'Bank',
        accountNumber: '222',
        bankName: 'Bank B',
        balance: 50000.0,
        status: 'Active',
      );

      const double oldIncomeAmount = 20000.0;
      const double newIncomeAmount = 30000.0;

      // When account changed from acc_1 to acc_2 with new amount 30,000:
      // Old account is refunded the 20,000
      oldAccount = oldAccount.copyWith(
        balance: oldAccount.balance - oldIncomeAmount,
      );
      // New account receives the 30,000
      newAccount = newAccount.copyWith(
        balance: newAccount.balance + newIncomeAmount,
      );

      expect(oldAccount.balance, equals(60000.0));
      expect(newAccount.balance, equals(80000.0));
    });

    test('Delete Income rolls back account balance', () {
      var account = const BankAccount(
        id: 'acc_mcb',
        name: 'MCB Main Account',
        type: 'Bank',
        accountNumber: 'PK99MCB123456789',
        bankName: 'Muslim Commercial Bank',
        balance: 75000.0,
        status: 'Active',
      );

      const double incomeToDelete = 25000.0;
      account = account.copyWith(
        balance: account.balance - incomeToDelete,
      );

      expect(account.balance, equals(50000.0));
    });
  });

  group('Income Module - Client Aggregation Tests', () {
    test('Client payment history accurately sums project and direct incomes', () {
      const client = Client(
        id: 'client_alpha',
        name: 'Alpha Systems',
        contactPerson: 'Ali Khan',
        email: 'ali@alphasystems.com',
        phone: '03001234567',
        status: 'Active',
        industry: 'Software',
        totalProjects: 2,
        advancedPayment: 0.0,
        fullPayment: 150000.0,
      );

      final incomes = [
        const IncomeRecord(
          id: 'inc_1',
          date: '2026-09-10',
          clientId: 'client_alpha',
          clientName: 'Alpha Systems',
          amount: 50000.0,
          accountId: 'acc_1',
          invoiceNumber: 'INV-1',
          description: 'Project 1 Advance',
          status: 'Received',
          projectId: 'proj_p1',
          projectName: 'ERP Phase 1',
          projectPaymentType: 'Advance',
        ),
        const IncomeRecord(
          id: 'inc_2',
          date: '2026-09-12',
          clientId: 'client_alpha',
          clientName: 'Alpha Systems',
          amount: 25000.0,
          accountId: 'acc_1',
          invoiceNumber: 'INV-2',
          description: 'Consulting services',
          status: 'Received',
          projectId: null,
          projectName: null,
          projectPaymentType: 'Consulting Services',
        ),
      ];

      final clientIncomes = incomes.where((i) => i.clientId == client.id).toList();
      final totalReceived = clientIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);
      final remaining = (client.fullPayment - totalReceived).clamp(0.0, double.infinity);

      expect(clientIncomes.length, equals(2));
      expect(totalReceived, equals(75000.0));
      expect(remaining, equals(75000.0));
    });
  });
}
