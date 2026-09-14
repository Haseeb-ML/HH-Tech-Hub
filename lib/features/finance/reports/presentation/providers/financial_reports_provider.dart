import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/financial_summary_model.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/income/presentation/providers/income_provider.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/features/finance/loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/features/hr/salaries/presentation/providers/salaries_provider.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';
import 'package:software_house_erp/features/sales/sales/presentation/providers/sales_invoices_provider.dart';

enum ReportDateRange { today, thisMonth, thisYear, allTime, custom }

class FinancialReportFilter {
  final ReportDateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FinancialReportFilter({
    this.dateRange = ReportDateRange.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  FinancialReportFilter copyWith({
    ReportDateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return FinancialReportFilter(
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

class ReportFilterNotifier extends Notifier<FinancialReportFilter> {
  @override
  FinancialReportFilter build() {
    return const FinancialReportFilter(dateRange: ReportDateRange.thisMonth);
  }

  void setFilter(FinancialReportFilter filter) {
    state = filter;
  }

  void setDateRange(ReportDateRange range) {
    state = state.copyWith(dateRange: range);
  }
}

final reportFilterProvider =
    NotifierProvider<ReportFilterNotifier, FinancialReportFilter>(
  ReportFilterNotifier.new,
);

class FinancialReportState {
  final ProfitLossSummary profitLoss;
  final CashFlowSummary cashFlow;
  final AssetsLiabilitiesSummary assetsLiabilities;
  final DateTime startDate;
  final DateTime endDate;

  const FinancialReportState({
    required this.profitLoss,
    required this.cashFlow,
    required this.assetsLiabilities,
    required this.startDate,
    required this.endDate,
  });
}

final financialReportsProvider = Provider<FinancialReportState>((ref) {
  final filter = ref.watch(reportFilterProvider);
  final accountsState = ref.watch(accountsProvider);
  final expensesState = ref.watch(expensesProvider);
  final incomeState = ref.watch(incomeProvider);
  final ledgerState = ref.watch(ledgerProvider);
  final loansState = ref.watch(loansProvider);
  final salariesState = ref.watch(salariesProvider);
  final inventoryState = ref.watch(inventoryProvider);
  final salesInvoicesState = ref.watch(salesInvoicesProvider);

  final now = DateTime.now();
  DateTime startDate = DateTime(now.year, now.month, 1);
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filter.dateRange) {
    case ReportDateRange.today:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case ReportDateRange.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      break;
    case ReportDateRange.thisYear:
      startDate = DateTime(now.year, 1, 1);
      break;
    case ReportDateRange.allTime:
      startDate = DateTime(2020, 1, 1);
      break;
    case ReportDateRange.custom:
      startDate = filter.customStartDate ?? DateTime(now.year, now.month, 1);
      endDate = filter.customEndDate ?? endDate;
      break;
  }

  bool isWithinRange(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return false;
    return dt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
           dt.isBefore(endDate.add(const Duration(seconds: 1)));
  }

  // 1. REVENUE / INCOME CALCULATIONS
  final filteredIncomes = incomeState.incomes.where((i) => isWithinRange(i.date)).toList();
  final incomeTotal = filteredIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);

  final directDebitLedger = ledgerState.entries.where((e) =>
      isWithinRange(e.date) &&
      e.type == 'Debit' &&
      (e.category == 'Personal Deposit' || e.category == 'Company Deposit')).toList();
  final directDebitTotal = directDebitLedger.fold<double>(0.0, (sum, e) => sum + e.amount);

  final totalRevenue = incomeTotal + directDebitTotal;

  // 2. EXPENSE CALCULATIONS
  final filteredExpenses = expensesState.expenses.where((e) => isWithinRange(e.date)).toList();
  final expenseRecordsTotal = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

  final filteredSalaries = salariesState.salaries.where((s) => isWithinRange(s.paymentDate)).toList();
  final salaryPaidTotal = filteredSalaries
      .where((s) => s.status == 'Paid')
      .fold<double>(0.0, (sum, s) => sum + s.netPaid);

  final directCreditLedger = ledgerState.entries.where((e) =>
      isWithinRange(e.date) &&
      e.type == 'Credit' &&
      e.category == 'Other Expense').toList();
  final directCreditTotal = directCreditLedger.fold<double>(0.0, (sum, e) => sum + e.amount);

  final totalExpenses = expenseRecordsTotal + salaryPaidTotal + directCreditTotal;
  final netProfit = totalRevenue - totalExpenses;

  // Expense Categories Breakdown
  final Map<String, double> categoryMap = {};
  for (final e in filteredExpenses) {
    categoryMap[e.category] = (categoryMap[e.category] ?? 0.0) + e.amount;
  }
  if (salaryPaidTotal > 0) {
    categoryMap['Salaries & Payroll'] = (categoryMap['Salaries & Payroll'] ?? 0.0) + salaryPaidTotal;
  }
  if (directCreditTotal > 0) {
    categoryMap['Other Expenses'] = (categoryMap['Other Expenses'] ?? 0.0) + directCreditTotal;
  }

  final List<ExpenseCategorySummary> categorySummaries = categoryMap.entries.map((entry) {
    final pct = totalExpenses > 0 ? (entry.value / totalExpenses) * 100 : 0.0;
    return ExpenseCategorySummary(
      category: entry.key,
      amount: entry.value,
      percentage: pct,
    );
  }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

  final profitLossSummary = ProfitLossSummary(
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
    netProfit: netProfit,
    expenseCategories: categorySummaries,
  );

  // 3. CASH FLOW CALCULATIONS
  final operatingInflow = totalRevenue;
  final operatingOutflow = totalExpenses;
  final operatingNet = operatingInflow - operatingOutflow;

  final borrowedLoansInflow = loansState.loans
      .where((l) => l.type == 'Borrowed' && isWithinRange(l.startDate))
      .fold<double>(0.0, (sum, l) => sum + l.amount);
  final lentRepaidInflow = loansState.loans
      .where((l) => l.type == 'Lent')
      .expand((l) => l.repayments)
      .where((r) => isWithinRange(r.date))
      .fold<double>(0.0, (sum, r) => sum + r.amount);
  final financingInflow = borrowedLoansInflow + lentRepaidInflow;

  final lentLoansOutflow = loansState.loans
      .where((l) => l.type == 'Lent' && isWithinRange(l.startDate))
      .fold<double>(0.0, (sum, l) => sum + l.amount);
  final borrowedRepaidOutflow = loansState.loans
      .where((l) => l.type == 'Borrowed')
      .expand((l) => l.repayments)
      .where((r) => isWithinRange(r.date))
      .fold<double>(0.0, (sum, r) => sum + r.amount);
  final financingOutflow = lentLoansOutflow + borrowedRepaidOutflow;
  final financingNet = financingInflow - financingOutflow;

  final netCashFlow = operatingNet + financingNet;

  final cashFlowSummary = CashFlowSummary(
    operatingInflow: operatingInflow,
    operatingOutflow: operatingOutflow,
    operatingNet: operatingNet,
    financingInflow: financingInflow,
    financingOutflow: financingOutflow,
    financingNet: financingNet,
    netCashFlow: netCashFlow,
  );

  // 4. ASSETS & LIABILITIES (BALANCE SHEET PREVIEW)
  final companyAccounts = accountsState.accounts.where((a) => a.accountScope != 'Personal' && a.status == 'Active').toList();
  final cashAndBankBalance = companyAccounts.fold<double>(0.0, (sum, a) => sum + a.balance);

  // Accounts Receivable (Unpaid invoices + unpaid income records)
  final unpaidInvoicesAR = salesInvoicesState.invoices
      .where((inv) => inv.status.toLowerCase() != 'paid')
      .fold<double>(0.0, (sum, inv) => sum + inv.total);
  final unpaidIncomeAR = incomeState.incomes
      .where((inc) => inc.status.toLowerCase() == 'pending' || inc.status.toLowerCase() == 'unpaid')
      .fold<double>(0.0, (sum, inc) => sum + inc.amount);
  final accountsReceivable = unpaidInvoicesAR + unpaidIncomeAR;

  // Inventory Stock Value
  final inventoryValue = inventoryState.items.fold<double>(0.0, (sum, item) => sum + (item.pricePerUnit * item.quantity));

  final totalCurrentAssets = cashAndBankBalance + accountsReceivable + inventoryValue;

  // Accounts Payable & Short term liabilities
  final unpaidExpensesAP = expensesState.expenses
      .fold<double>(0.0, (sum, exp) => sum + exp.amount);
  final shortTermLoans = loansState.loans
      .where((l) => l.type == 'Borrowed' && l.status != 'Settled')
      .fold<double>(0.0, (sum, l) => sum + l.remainingBalance);
  final salariesPayable = salariesState.salaries
      .where((s) => s.status.toLowerCase() != 'paid')
      .fold<double>(0.0, (sum, s) => sum + s.netPaid);

  final totalCurrentLiabilities = unpaidExpensesAP + shortTermLoans + salariesPayable;
  final workingCapital = totalCurrentAssets - totalCurrentLiabilities;

  final assetsLiabilitiesSummary = AssetsLiabilitiesSummary(
    cashAndBankBalance: cashAndBankBalance,
    accountsReceivable: accountsReceivable,
    inventoryValue: inventoryValue,
    totalCurrentAssets: totalCurrentAssets,
    accountsPayable: unpaidExpensesAP,
    shortTermLoans: shortTermLoans,
    salariesPayable: salariesPayable,
    totalCurrentLiabilities: totalCurrentLiabilities,
    workingCapital: workingCapital,
  );

  return FinancialReportState(
    profitLoss: profitLossSummary,
    cashFlow: cashFlowSummary,
    assetsLiabilities: assetsLiabilitiesSummary,
    startDate: startDate,
    endDate: endDate,
  );
});
