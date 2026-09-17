import 'package:flutter/foundation.dart';

@immutable
class RevenueCategorySummary {
  final String category;
  final double amount;
  final double percentage;

  const RevenueCategorySummary({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

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
  final double salesRevenue;
  final double serviceIncome;
  final double consultationFees;
  final double otherRevenue;

  final double openingInventory;
  final double purchases;
  final double closingInventory;
  final double totalCogs;

  final double grossProfit;
  final double grossMargin;

  final double salariesWages;
  final double rentOccupancy;
  final double electricityUtilities;
  final double internetTelecom;
  final double transportLogistics;
  final double marketingAdvertising;
  final double officeAdmin;
  final double repairsMaintenance;
  final double depreciation;
  final double bankCharges;
  final double otherExpenses;
  final double miscellaneous;
  final double totalOpEx;

  final double operatingProfit;
  final double loanInterestExpense;
  final double totalFinanceCosts;
  final double netProfitPreTax;
  final double taxProvision;
  final bool hasTaxData;
  final double netProfitAfterTax;
  final double netMargin;

  final double totalExpenses;
  final double netProfit;
  final List<ExpenseCategorySummary> expenseCategories;
  final List<RevenueCategorySummary> revenueCategories;

  final bool hasPriorYearData;
  final Map<String, double> priorYearAmounts;

  const ProfitLossSummary({
    required this.totalRevenue,
    this.salesRevenue = 0.0,
    this.serviceIncome = 0.0,
    this.consultationFees = 0.0,
    this.otherRevenue = 0.0,
    this.openingInventory = 0.0,
    this.purchases = 0.0,
    this.closingInventory = 0.0,
    this.totalCogs = 0.0,
    this.grossProfit = 0.0,
    this.grossMargin = 0.0,
    this.salariesWages = 0.0,
    this.rentOccupancy = 0.0,
    this.electricityUtilities = 0.0,
    this.internetTelecom = 0.0,
    this.transportLogistics = 0.0,
    this.marketingAdvertising = 0.0,
    this.officeAdmin = 0.0,
    this.repairsMaintenance = 0.0,
    this.depreciation = 0.0,
    this.bankCharges = 0.0,
    this.otherExpenses = 0.0,
    this.miscellaneous = 0.0,
    this.totalOpEx = 0.0,
    this.operatingProfit = 0.0,
    this.loanInterestExpense = 0.0,
    this.totalFinanceCosts = 0.0,
    this.netProfitPreTax = 0.0,
    this.taxProvision = 0.0,
    this.hasTaxData = false,
    this.netProfitAfterTax = 0.0,
    this.netMargin = 0.0,
    required this.totalExpenses,
    required this.netProfit,
    required this.expenseCategories,
    this.revenueCategories = const [],
    this.hasPriorYearData = false,
    this.priorYearAmounts = const {},
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
  final double cashInHand;
  final double bankAccounts;
  final double cashAndBankBalance;
  final double accountsReceivable;
  final double inventoryValue;
  final double advancesPrepayments;
  final double totalCurrentAssets;

  final double computersItEquipment;
  final double furnitureFixtures;
  final double vehicles;
  final double machineryPlant;
  final double officeEquipment;
  final double lessAccumulatedDepreciation;
  final double totalNonCurrentAssets;
  final double totalAssets;

  final double accountsPayable;
  final double salariesPayable;
  final double taxPayable;
  final double shortTermLoans;

  final double bankLoanAmount;
  final double ownerLoanAmount;
  final double otherLoanAmount;

  final double totalCurrentLiabilities;

  final double longTermBankLoans;
  final double totalNonCurrentLiabilities;
  final double totalLiabilities;

  final double ownersCapital;
  final double retainedEarnings;
  final double lessOwnersDrawings;
  final double totalEquity;
  final double totalLiabilitiesAndEquity;

  final double workingCapital;
  final List<dynamic> assetManagementList;
  final DateTime? asOfDate;

  const AssetsLiabilitiesSummary({
    this.cashInHand = 0.0,
    this.bankAccounts = 0.0,
    required this.cashAndBankBalance,
    required this.accountsReceivable,
    required this.inventoryValue,
    this.advancesPrepayments = 0.0,
    required this.totalCurrentAssets,
    this.computersItEquipment = 0.0,
    this.furnitureFixtures = 0.0,
    this.vehicles = 0.0,
    this.machineryPlant = 0.0,
    this.officeEquipment = 0.0,
    this.lessAccumulatedDepreciation = 0.0,
    this.totalNonCurrentAssets = 0.0,
    this.totalAssets = 0.0,
    required this.accountsPayable,
    required this.salariesPayable,
    this.taxPayable = 0.0,
    required this.shortTermLoans,
    this.bankLoanAmount = 0.0,
    this.ownerLoanAmount = 0.0,
    this.otherLoanAmount = 0.0,
    required this.totalCurrentLiabilities,
    this.longTermBankLoans = 0.0,
    this.totalNonCurrentLiabilities = 0.0,
    this.totalLiabilities = 0.0,
    this.ownersCapital = 0.0,
    this.retainedEarnings = 0.0,
    this.lessOwnersDrawings = 0.0,
    this.totalEquity = 0.0,
    this.totalLiabilitiesAndEquity = 0.0,
    required this.workingCapital,
    this.assetManagementList = const [],
    this.asOfDate,
  });
}
