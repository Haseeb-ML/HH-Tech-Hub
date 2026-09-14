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
import 'package:software_house_erp/features/sales/purchases/presentation/providers/purchase_orders_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';

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
  final purchaseOrdersState = ref.watch(purchaseOrdersProvider);
  final assetsState = ref.watch(assetsProvider);

  final now = DateTime.now();
  DateTime startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
  DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  switch (filter.dateRange) {
    case ReportDateRange.today:
      startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
    case ReportDateRange.thisMonth:
      startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      endDate = DateTime(now.year, now.month, lastDay, 23, 59, 59);
      break;
    case ReportDateRange.thisYear:
      startDate = DateTime(now.year, 1, 1, 0, 0, 0);
      endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    case ReportDateRange.allTime:
      startDate = DateTime(2020, 1, 1, 0, 0, 0);
      endDate = DateTime(2035, 12, 31, 23, 59, 59);
      break;
    case ReportDateRange.custom:
      startDate = filter.customStartDate != null
          ? DateTime(filter.customStartDate!.year, filter.customStartDate!.month, filter.customStartDate!.day, 0, 0, 0)
          : DateTime(now.year, now.month, 1, 0, 0, 0);
      endDate = filter.customEndDate != null
          ? DateTime(filter.customEndDate!.year, filter.customEndDate!.month, filter.customEndDate!.day, 23, 59, 59)
          : DateTime(now.year, now.month, now.day, 23, 59, 59);
      break;
  }

  DateTime? parseDate(String rawDate) {
    if (rawDate.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(rawDate.trim());
    if (parsed != null) {
      final local = parsed.toLocal();
      return DateTime(local.year, local.month, local.day, local.hour, local.minute, local.second);
    }

    try {
      final parts = rawDate.trim().split(RegExp(r'[/.\-\s]'));
      if (parts.length >= 3) {
        if (parts[0].length == 4) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2].substring(0, 2));
          return DateTime(y, m, d);
        } else if (parts[2].length >= 4) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2].substring(0, 4));
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}
    return null;
  }

  bool isWithinRange(String dateStr) {
    final dt = parseDate(dateStr);
    if (dt == null) return true;
    return (dt.isAfter(startDate) || dt.isAtSameMomentAs(startDate)) &&
           (dt.isBefore(endDate) || dt.isAtSameMomentAs(endDate));
  }

  // 1. REVENUE / INCOME CALCULATIONS
  final filteredIncomes = incomeState.incomes.where((i) => isWithinRange(i.date)).toList();
  final filteredSalesInvoices = salesInvoicesState.invoices.where((inv) => isWithinRange(inv.date)).toList();

  double salesRevenue = filteredSalesInvoices
      .where((inv) => inv.status.toLowerCase() == 'paid')
      .fold<double>(0.0, (sum, inv) => sum + inv.total);
  if (salesRevenue == 0) {
    salesRevenue = filteredIncomes
        .where((i) => i.description.toLowerCase().contains('sale') || i.description.toLowerCase().contains('product') || i.invoiceNumber.isNotEmpty)
        .fold<double>(0.0, (sum, i) => sum + i.amount);
  }

  double serviceIncome = filteredIncomes
      .where((i) => i.description.toLowerCase().contains('service') || i.description.toLowerCase().contains('project') || i.description.toLowerCase().contains('dev'))
      .fold<double>(0.0, (sum, i) => sum + i.amount);

  double consultationFees = filteredIncomes
      .where((i) => i.description.toLowerCase().contains('consult') || i.description.toLowerCase().contains('advis'))
      .fold<double>(0.0, (sum, i) => sum + i.amount);

  double directDebitTotal = ledgerState.entries.where((e) =>
      isWithinRange(e.date) &&
      e.type == 'Debit' &&
      (e.category == 'Personal Deposit' || e.category == 'Company Deposit')).fold<double>(0.0, (sum, e) => sum + e.amount);

  double incomeTotal = filteredIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);
  double totalRevenue = incomeTotal + directDebitTotal;

  double otherRevenue = totalRevenue - (salesRevenue + serviceIncome + consultationFees);
  if (otherRevenue < 0) {
    otherRevenue = 0.0;
  }

  // 2. COST OF GOODS SOLD (COGS)
  double closingInventory = inventoryState.items.fold<double>(0.0, (sum, item) => sum + (item.pricePerUnit * item.quantity));
  double purchases = purchaseOrdersState.orders
      .where((po) => isWithinRange(po.date) && po.status.toLowerCase() != 'cancelled')
      .fold<double>(0.0, (sum, po) => sum + po.total);
  double openingInventory = closingInventory > 0 ? closingInventory * 0.85 : 0.0;
  double totalCogs = (openingInventory + purchases > closingInventory) ? (openingInventory + purchases - closingInventory) : purchases;

  final filteredExpenses = expensesState.expenses.where((e) => isWithinRange(e.date)).toList();
  if (totalCogs == 0) {
    totalCogs = filteredExpenses
        .where((e) => e.category.toLowerCase().contains('cogs') || e.category.toLowerCase().contains('cost') || e.category.toLowerCase().contains('purchase'))
        .fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  double grossProfit = totalRevenue - totalCogs;
  double grossMargin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

  // 3. OPERATING EXPENSES (OpEx)
  final filteredSalaries = salariesState.salaries.where((s) => isWithinRange(s.paymentDate)).toList();
  double salaryPaidTotal = filteredSalaries
      .where((s) => s.status == 'Paid')
      .fold<double>(0.0, (sum, s) => sum + s.netPaid);

  double salariesWages = salaryPaidTotal + filteredExpenses
      .where((e) => e.category.toLowerCase().contains('salari') || e.category.toLowerCase().contains('pay'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double rentOccupancy = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('rent'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double electricityUtilities = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('electric') || e.category.toLowerCase().contains('power') || e.category.toLowerCase().contains('utility') || e.category.toLowerCase().contains('bill'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double internetTelecom = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('internet') || e.category.toLowerCase().contains('wifi') || e.category.toLowerCase().contains('telecom'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double transportLogistics = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('travel') || e.category.toLowerCase().contains('transport') || e.category.toLowerCase().contains('logistics'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double marketingAdvertising = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('market') || e.category.toLowerCase().contains('advert'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double officeAdmin = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('suppl') || e.category.toLowerCase().contains('office') || e.category.toLowerCase().contains('admin'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double repairsMaintenance = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('repair') || e.category.toLowerCase().contains('maint'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double depreciation = filteredExpenses
      .where((e) => e.category.toLowerCase() == 'depreciation' || e.description.toLowerCase().contains('depreciation'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double bankCharges = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('bank') || e.category.toLowerCase().contains('fee'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double directCreditTotal = ledgerState.entries
      .where((e) => isWithinRange(e.date) && e.type == 'Credit' && e.category == 'Other Expense')
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  double otherExpenses = filteredExpenses
      .where((e) {
        final cat = e.category.toLowerCase();
        final isSal = cat.contains('salari') || cat.contains('pay');
        final isRent = cat.contains('rent');
        final isUtil = cat.contains('electric') || cat.contains('power') || cat.contains('utility') || cat.contains('bill');
        final isNet = cat.contains('internet') || cat.contains('wifi') || cat.contains('telecom');
        final isTrans = cat.contains('travel') || cat.contains('transport') || cat.contains('logistics');
        final isMkt = cat.contains('market') || cat.contains('advert');
        final isAdmin = cat.contains('suppl') || cat.contains('office') || cat.contains('admin');
        final isRep = cat.contains('repair') || cat.contains('maint');
        final isDep = cat == 'depreciation' || e.description.toLowerCase().contains('depreciation');
        final isBank = cat.contains('bank') || cat.contains('fee');
        final isCogs = cat.contains('cogs') || cat.contains('cost') || cat.contains('purchase');
        final isInt = cat.contains('interest') || cat.contains('loan');
        return !isSal && !isRent && !isUtil && !isNet && !isTrans && !isMkt && !isAdmin && !isRep && !isDep && !isBank && !isCogs && !isInt;
      })
      .fold<double>(0.0, (sum, e) => sum + e.amount) + directCreditTotal;

  double expenseRecordsTotal = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  double totalExpenses = expenseRecordsTotal + salaryPaidTotal + directCreditTotal;

  double accountedOpEx = salariesWages + rentOccupancy + electricityUtilities + internetTelecom + transportLogistics + marketingAdvertising + officeAdmin + repairsMaintenance + depreciation + bankCharges + otherExpenses;
  double miscellaneous = totalExpenses > (accountedOpEx + totalCogs) ? (totalExpenses - accountedOpEx - totalCogs) : 0.0;
  double totalOpEx = accountedOpEx + miscellaneous;

  // 4. OPERATING PROFIT (EBIT)
  double operatingProfit = grossProfit - totalOpEx;

  // 5. FINANCE COSTS
  double loanInterestExpense = filteredExpenses
      .where((e) => e.category.toLowerCase().contains('interest') || e.category.toLowerCase().contains('loan'))
      .fold<double>(0.0, (sum, e) => sum + e.amount);
  double totalFinanceCosts = loanInterestExpense;

  // 6. NET PROFIT & TAX
  double netProfitPreTax = operatingProfit - totalFinanceCosts;
  double taxProvision = netProfitPreTax > 0 ? (netProfitPreTax * 0.15) : 0.0;
  double netProfitAfterTax = netProfitPreTax - taxProvision;
  double netMargin = totalRevenue > 0 ? (netProfitAfterTax / totalRevenue) * 100 : 0.0;
  double netProfit = netProfitAfterTax;

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
    salesRevenue: salesRevenue,
    serviceIncome: serviceIncome,
    consultationFees: consultationFees,
    otherRevenue: otherRevenue,
    openingInventory: openingInventory,
    purchases: purchases,
    closingInventory: closingInventory,
    totalCogs: totalCogs,
    grossProfit: grossProfit,
    grossMargin: grossMargin,
    salariesWages: salariesWages,
    rentOccupancy: rentOccupancy,
    electricityUtilities: electricityUtilities,
    internetTelecom: internetTelecom,
    transportLogistics: transportLogistics,
    marketingAdvertising: marketingAdvertising,
    officeAdmin: officeAdmin,
    repairsMaintenance: repairsMaintenance,
    depreciation: depreciation,
    bankCharges: bankCharges,
    otherExpenses: otherExpenses,
    miscellaneous: miscellaneous,
    totalOpEx: totalOpEx,
    operatingProfit: operatingProfit,
    loanInterestExpense: loanInterestExpense,
    totalFinanceCosts: totalFinanceCosts,
    netProfitPreTax: netProfitPreTax,
    taxProvision: taxProvision,
    netProfitAfterTax: netProfitAfterTax,
    netMargin: netMargin,
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

  // 4. ASSETS & LIABILITIES (PURE REAL SYSTEM DATA - NO DUMMY FALLBACKS)
  final companyAccounts = accountsState.accounts.where((a) => a.accountScope != 'Personal' && a.status == 'Active').toList();
  final cashInHand = companyAccounts
      .where((a) => a.type.toLowerCase().contains('cash'))
      .fold<double>(0.0, (sum, a) => sum + a.balance);
  final bankAccounts = companyAccounts
      .where((a) => !a.type.toLowerCase().contains('cash'))
      .fold<double>(0.0, (sum, a) => sum + a.balance);
  final cashAndBankBalance = cashInHand + bankAccounts;

  // Accounts Receivable (Unpaid invoices + pending income records)
  final unpaidInvoicesAR = salesInvoicesState.invoices
      .where((inv) => inv.status.toLowerCase() != 'paid')
      .fold<double>(0.0, (sum, inv) => sum + inv.total);
  final unpaidIncomeAR = incomeState.incomes
      .where((inc) => inc.status.toLowerCase() == 'pending' || inc.status.toLowerCase() == 'unpaid')
      .fold<double>(0.0, (sum, inc) => sum + inc.amount);
  final accountsReceivable = unpaidInvoicesAR + unpaidIncomeAR;

  // Inventory Stock Value
  final inventoryValue = inventoryState.items.fold<double>(0.0, (sum, item) => sum + (item.pricePerUnit * item.quantity));
  final advancesPrepayments = 0.0;

  final totalCurrentAssets = cashAndBankBalance + accountsReceivable + inventoryValue + advancesPrepayments;

  // Non-Current Assets (Real data directly from Asset Management & Office Inventory modules)
  final List<dynamic> nonCurrentAssetItems = [];

  double computersItEquipment = 0.0;
  double furnitureFixtures = 0.0;
  double vehicles = 0.0;
  double machineryPlant = 0.0;
  double officeEquipment = 0.0;

  for (final asset in assetsState.assets) {
    if (asset.status == 'Retired') continue;
    nonCurrentAssetItems.add(asset);

    final nameLower = asset.name.toLowerCase();
    final typeLower = asset.type.toLowerCase();

    if (nameLower.contains('furniture') || typeLower.contains('furniture') || nameLower.contains('chair') || nameLower.contains('table') || nameLower.contains('desk')) {
      furnitureFixtures += asset.cost;
    } else if (nameLower.contains('vehicle') || typeLower.contains('vehicle') || nameLower.contains('car') || nameLower.contains('bike') || nameLower.contains('van')) {
      vehicles += asset.cost;
    } else if (nameLower.contains('machinery') || typeLower.contains('machinery') || nameLower.contains('plant') || nameLower.contains('generator')) {
      machineryPlant += asset.cost;
    } else if (nameLower.contains('office') || typeLower.contains('printer') || nameLower.contains('scanner') || nameLower.contains('projector')) {
      officeEquipment += asset.cost;
    } else {
      computersItEquipment += asset.cost;
    }
  }

  for (final item in inventoryState.items) {
    final itemVal = item.pricePerUnit * item.quantity;
    if (itemVal <= 0) continue;
    nonCurrentAssetItems.add({
      'name': item.name,
      'type': '${item.category} Inventory',
      'cost': itemVal,
    });
    officeEquipment += itemVal;
  }

  final grossNonCurrentAssets = computersItEquipment + furnitureFixtures + vehicles + machineryPlant + officeEquipment;
  final lessAccumulatedDepreciation = profitLossSummary.depreciation;
  final totalNonCurrentAssets = grossNonCurrentAssets > lessAccumulatedDepreciation
      ? (grossNonCurrentAssets - lessAccumulatedDepreciation)
      : grossNonCurrentAssets;
  final totalAssets = totalCurrentAssets + totalNonCurrentAssets;

  // Current Liabilities (Real system data)
  final accountsPayable = purchaseOrdersState.orders
      .where((po) => po.status.toLowerCase() == 'pending' || po.status.toLowerCase() == 'ordered')
      .fold<double>(0.0, (sum, po) => sum + po.total);
  final shortTermLoans = loansState.loans
      .where((l) => l.type == 'Borrowed' && l.status != 'Settled')
      .fold<double>(0.0, (sum, l) => sum + l.remainingBalance);
  final salariesPayable = salariesState.salaries
      .where((s) => s.status.toLowerCase() != 'paid')
      .fold<double>(0.0, (sum, s) => sum + s.netPaid);
  final taxPayable = profitLossSummary.taxProvision;

  final totalCurrentLiabilities = accountsPayable + salariesPayable + taxPayable + shortTermLoans;

  // Non-Current Liabilities (Real data)
  final longTermBankLoans = 0.0;
  final totalNonCurrentLiabilities = longTermBankLoans;
  final totalLiabilities = totalCurrentLiabilities + totalNonCurrentLiabilities;

  // Equity (Real System Data)
  final retainedEarnings = profitLossSummary.netProfit;
  final lessOwnersDrawings = expensesState.expenses
      .where((e) => e.isPersonalExpense && isWithinRange(e.date))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  final totalEquity = totalAssets - totalLiabilities;
  final ownersCapital = (totalEquity - retainedEarnings + lessOwnersDrawings).clamp(0.0, double.infinity);
  final totalLiabilitiesAndEquity = totalLiabilities + totalEquity;

  final workingCapital = totalCurrentAssets - totalCurrentLiabilities;

  final assetsLiabilitiesSummary = AssetsLiabilitiesSummary(
    cashInHand: cashInHand,
    bankAccounts: bankAccounts,
    cashAndBankBalance: cashAndBankBalance,
    accountsReceivable: accountsReceivable,
    inventoryValue: inventoryValue,
    advancesPrepayments: advancesPrepayments,
    totalCurrentAssets: totalCurrentAssets,
    computersItEquipment: computersItEquipment,
    furnitureFixtures: furnitureFixtures,
    vehicles: vehicles,
    machineryPlant: machineryPlant,
    officeEquipment: officeEquipment,
    lessAccumulatedDepreciation: lessAccumulatedDepreciation,
    totalNonCurrentAssets: totalNonCurrentAssets > 0 ? totalNonCurrentAssets : 0.0,
    totalAssets: totalAssets,
    accountsPayable: accountsPayable,
    salariesPayable: salariesPayable,
    taxPayable: taxPayable,
    shortTermLoans: shortTermLoans,
    totalCurrentLiabilities: totalCurrentLiabilities,
    longTermBankLoans: longTermBankLoans,
    totalNonCurrentLiabilities: totalNonCurrentLiabilities,
    totalLiabilities: totalLiabilities,
    ownersCapital: ownersCapital,
    retainedEarnings: retainedEarnings,
    lessOwnersDrawings: lessOwnersDrawings,
    totalEquity: totalEquity,
    totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
    workingCapital: workingCapital,
    assetManagementList: nonCurrentAssetItems,
  );

  return FinancialReportState(
    profitLoss: profitLossSummary,
    cashFlow: cashFlowSummary,
    assetsLiabilities: assetsLiabilitiesSummary,
    startDate: startDate,
    endDate: endDate,
  );
});
