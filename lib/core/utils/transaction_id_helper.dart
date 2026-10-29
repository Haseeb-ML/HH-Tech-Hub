import '../../features/finance/expenses/domain/entities/expense_record.dart';
import '../../features/finance/income/domain/entities/income_record.dart';
import '../../features/finance/ledger/domain/entities/ledger_entry.dart';

class TransactionIdHelper {
  /// Generate a permanent, strictly unique Expense / Salary ID for an ExpenseRecord
  /// Derived deterministically from the record's permanent ID attributes so it NEVER shifts when records are deleted.
  static String getExpenseId(ExpenseRecord record, List<ExpenseRecord> allExpenses) {
    final isSalary = record.category.toLowerCase().contains('salary') ||
        record.category.toLowerCase().contains('payroll') ||
        record.id.toLowerCase().contains('sal_');

    final prefix = isSalary ? 'SAL_' : 'EXP_';
    final rawId = record.id.trim();

    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return '$prefix${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return '$prefix${seq.toString().padLeft(4, '0')}';
      }
    }

    return '${prefix}0001';
  }

  /// Generate a permanent, strictly unique Receipt ID (RCP_0001 format) for an IncomeRecord
  static String getReceiptId(IncomeRecord record, List<IncomeRecord> allIncomes) {
    final rawId = record.id.trim();
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return 'RCP_${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return 'RCP_${seq.toString().padLeft(4, '0')}';
      }
    }
    return 'RCP_0001';
  }

  /// Generate a permanent, strictly unique Invoice ID for an IncomeRecord
  static String getIncomeId(IncomeRecord record, List<IncomeRecord> allIncomes) {
    final inv = record.invoiceNumber.trim();
    if (inv.isNotEmpty) {
      final isLongEpoch = RegExp(r'\d{6,}').hasMatch(inv);
      final isRawAddonOrProj = inv.toLowerCase().contains('addon_') ||
          inv.toLowerCase().contains('proj_') ||
          inv.toLowerCase().contains('rec_');
      if (!isLongEpoch && !isRawAddonOrProj) {
        if (inv.toUpperCase().startsWith('INV')) {
          return inv.toUpperCase();
        }
        final digits = inv.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          final numVal = int.tryParse(digits) ?? 1;
          if (numVal <= 9999) {
            return 'INV_${numVal.toString().padLeft(4, '0')}';
          }
          final last4 = numVal % 10000;
          final seq = last4 == 0 ? 1 : last4;
          return 'INV_${seq.toString().padLeft(4, '0')}';
        }
      }
    }

    final rawId = record.id.trim();
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return 'INV_${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return 'INV_${seq.toString().padLeft(4, '0')}';
      }
    }
    return 'INV_0001';
  }

  /// Generate a permanent, strictly unique Loan ID (LOAN_0001 format) for a LoanRecord
  static String getLoanId(dynamic record, List<dynamic> allLoans) {
    if (record == null) return 'LOAN_0001';
    final rawId = (record.id ?? '').toString().trim();
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return 'LOAN_${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return 'LOAN_${seq.toString().padLeft(4, '0')}';
      }
    }
    return 'LOAN_0001';
  }

  /// Generate a permanent, strictly unique Repayment ID (REP_0001 format) for a LoanRepayment
  static String getRepaymentId(dynamic repayment, List<dynamic> allRepayments) {
    if (repayment == null) return 'REP_0001';
    final rawId = (repayment.id ?? '').toString().trim();
    final digits = rawId.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return 'REP_${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return 'REP_${seq.toString().padLeft(4, '0')}';
      }
    }
    return 'REP_0001';
  }

  /// Resolve permanent unique Invoice / Expense ID for a LedgerEntry
  static String getLedgerInvoiceId({
    required LedgerEntry entry,
    required List<IncomeRecord> incomes,
    required List<ExpenseRecord> expenses,
  }) {
    // 1. Check if linked to an Income record
    if (entry.id.startsWith('led_inc_')) {
      final realIncId = entry.id.replaceFirst('led_inc_', '');
      final matchedInc = incomes.where((i) => i.id == realIncId).firstOrNull;
      if (matchedInc != null) {
        return getIncomeId(matchedInc, incomes);
      }
    }

    // 2. Check if linked to an Expense record
    if (entry.id.startsWith('led_exp_')) {
      final realExpId = entry.id.replaceFirst('led_exp_', '');
      final matchedExp = expenses.where((e) => e.id == realExpId).firstOrNull;
      if (matchedExp != null) {
        return getExpenseId(matchedExp, expenses);
      }
    }

    // 3. Fallback based on reference or type
    if (entry.reference.isNotEmpty && entry.reference != '—') {
      if (entry.reference.toUpperCase().startsWith('INV') ||
          entry.reference.toUpperCase().startsWith('EXP') ||
          entry.reference.toUpperCase().startsWith('SAL') ||
          entry.reference.toUpperCase().startsWith('RCP')) {
        return entry.reference.toUpperCase();
      }
    }

    final prefix = entry.type == 'Credit' ? 'EXP_' : 'INV_';
    final digits = entry.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return '$prefix${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return '$prefix${seq.toString().padLeft(4, '0')}';
      }
    }
    return '${prefix}0001';
  }
}
