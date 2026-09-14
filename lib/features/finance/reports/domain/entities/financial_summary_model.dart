import 'package:flutter/foundation.dart';

@immutable
class ExpenseCategorySummary {
  final String category;
  final double amount;
  final double percentage;

  const ExpenseCategorySummary({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

@immutable
class ProfitLossSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final List<ExpenseCategorySummary> expenseCategories;

  const ProfitLossSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.expenseCategories,
  });

  bool get isProfitable => netProfit >= 0;
}

@immutable
class CashFlowSummary {
  final double operatingInflow;
  final double operatingOutflow;
  final double operatingNet;

  final double financingInflow;
  final double financingOutflow;
  final double financingNet;

  final double netCashFlow;

  const CashFlowSummary({
    required this.operatingInflow,
    required this.operatingOutflow,
    required this.operatingNet,
    required this.financingInflow,
    required this.financingOutflow,
    required this.financingNet,
    required this.netCashFlow,
  });
}

@immutable
class AssetsLiabilitiesSummary {
  final double cashAndBankBalance;
  final double accountsReceivable;
  final double inventoryValue;
  final double totalCurrentAssets;

  final double accountsPayable;
  final double shortTermLoans;
  final double salariesPayable;
  final double totalCurrentLiabilities;

  final double workingCapital;

  const AssetsLiabilitiesSummary({
    required this.cashAndBankBalance,
    required this.accountsReceivable,
    required this.inventoryValue,
    required this.totalCurrentAssets,
    required this.accountsPayable,
    required this.shortTermLoans,
    required this.salariesPayable,
    required this.totalCurrentLiabilities,
    required this.workingCapital,
  });
}
