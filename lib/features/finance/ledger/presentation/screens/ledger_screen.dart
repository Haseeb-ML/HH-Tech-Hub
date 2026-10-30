import 'dart:math';
import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/ledger_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../accounts/domain/entities/bank_account.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/projects/presentation/screens/projects_screen.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/shared/widgets/transaction_detail_dialog.dart';
import '../../../../../core/services/cloud_sync_service.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/utils/transaction_id_helper.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';

DateTime? _extractTimestampFromId(String id) {
  try {
    final match = RegExp(r'\d{12,14}').firstMatch(id);
    if (match != null) {
      final ms = int.tryParse(match.group(0)!);
      if (ms != null && ms > 0 && ms < 8640000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
  } catch (_) {}
  return null;
}

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  String _formatAccountFilterLabel(BankAccount a) {
    if (a.isPersonal) {
      return a.name.toLowerCase().contains('personal') ? a.name : '${a.name} (Personal)';
    } else {
      return a.name.toLowerCase().contains('company') ? a.name : '${a.name} (Company)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SyncState>(cloudSyncStateProvider, (previous, next) {
        if ((next.status == SyncStatus.success || next.status == SyncStatus.offline) &&
          previous?.status == SyncStatus.syncing) {
        ref.invalidate(ledgerProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(incomeProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(projectsProvider);
      }
    });

    final tr = ref.watch(translationProvider);
    final state = ref.watch(ledgerProvider);
    final accountsState = ref.watch(accountsProvider);
    final clientAccounts = ref.watch(clientAccountsProvider);
    final incomes = ref.watch(incomeProvider).incomes;
    final expenses = ref.watch(expensesProvider).expenses;
    final loans = ref.watch(loansProvider).loans;
    final theme = Theme.of(context);

    // Build account lookup map (Company & Personal accounts only - client accounts excluded)
    final accountMap = {
      for (var a in accountsState.accounts) a.id: a.name,
    };

    final companyAccounts = accountsState.accounts.where((a) => a.isCompany).toList();
    final personalAccounts = accountsState.accounts.where((a) => a.isPersonal).toList();
    final isAccountFilterValid = state.accountFilter == 'All' || accountsState.accounts.any((a) => a.id == state.accountFilter);
    final activeAccountFilter = isAccountFilterValid ? state.accountFilter : 'All';

    // Compile real entries from IncomeRecords
    final allProjectsList = ref.watch(projectsProvider).projects;

    final realIncomeEntries = incomes.map((inc) {
      // Installment Type text for Subtext under Description
      String installmentText = 'Payment Received';
      if (inc.projectPaymentType == 'Advance') {
        installmentText = 'Advance Payment';
      } else if (inc.projectPaymentType == 'Partial') {
        installmentText = 'Partial Payment';
      } else if (inc.projectPaymentType == 'Final' || inc.projectPaymentType == 'Full') {
        installmentText = 'Full Payment';
      } else if (inc.projectId != null && inc.projectId!.isNotEmpty) {
        installmentText = 'Project Payment';
      } else if (inc.invoiceNumber.isNotEmpty) {
        installmentText = 'Invoice #${inc.invoiceNumber}';
      }

      // Clean Description: ONLY "Project Name - Client Name"
      String desc = inc.clientName;
      if (inc.projectName != null && inc.projectName!.isNotEmpty) {
        desc = '${inc.projectName!} - ${inc.clientName}';
      } else if (inc.projectId != null && inc.projectId!.isNotEmpty) {
        // Fallback: lookup project name from projects list for old records
        final proj = allProjectsList.where((p) => p.id == inc.projectId).firstOrNull;
        if (proj != null) {
          desc = '${proj.name} - ${inc.clientName}';
        }
      }
      // Never show raw description like "Partial Payment for Project..." or "Type Payment - ProjectName"
      if (desc.contains('Partial Payment for') || desc.contains('Payment for Project') || desc.contains('Payment -')) {
        final proj = allProjectsList.where((p) => p.id == inc.projectId).firstOrNull;
        if (proj != null) {
          desc = '${proj.name} - ${proj.clientName}';
        }
      }

      final matchedProj = allProjectsList.where((p) => p.id == inc.projectId).firstOrNull;

      // Match Client Account from clientAccountsProvider
      ClientAccount? matchedClientAccount;
      if (matchedProj != null) {
        matchedClientAccount = clientAccounts.where((ca) =>
            ca.id == matchedProj.clientPaymentSource ||
            ca.name == matchedProj.clientPaymentSource ||
            (matchedProj.clientPaymentSource.contains(ca.name)) ||
            (matchedProj.clientId.isNotEmpty && ca.clientId == matchedProj.clientId)
        ).firstOrNull;
      }
      if (matchedClientAccount == null && inc.clientId.isNotEmpty) {
        matchedClientAccount = clientAccounts.where((ca) => ca.clientId == inc.clientId).firstOrNull;
      }

      // Determine accurate Payment Method (Bank / Cash / Online)
      String pMethod = 'Bank';
      if (matchedClientAccount != null) {
        if (matchedClientAccount.paymentMethod == 'Bank') {
          pMethod = 'Bank';
        } else if (matchedClientAccount.paymentMethod == 'Wallet' || matchedClientAccount.paymentMethod == 'Online') {
          pMethod = 'Online';
        } else if (matchedClientAccount.paymentMethod == 'Cash') {
          pMethod = 'Cash';
        }
      } else {
        final paymentSource = (matchedProj?.clientPaymentSource ?? '').toLowerCase();
        final accName = (accountMap[inc.accountId] ?? '').toLowerCase();

        if (paymentSource.contains('easypaisa') || paymentSource.contains('jazzcash') || paymentSource.contains('wallet') || paymentSource.contains('online') || accName.contains('wallet') || accName.contains('easypaisa')) {
          pMethod = 'Online';
        } else if (paymentSource.contains('cash') || (accName.contains('cash') && !paymentSource.contains('bank'))) {
          pMethod = 'Cash';
        } else {
          // Default to Bank for project and client payments
          pMethod = 'Bank';
        }
      }

      // Determine accurate Received Account Name & Account ID (the account where payment was received)
      final receivedAcc = accountsState.accounts.where((a) => a.id == inc.accountId).firstOrNull;
      String actualAccountId = inc.accountId;
      String actualAccountName = receivedAcc?.name ?? accountMap[inc.accountId] ?? '';

      if (receivedAcc != null) {
        if (receivedAcc.type == 'Cash') {
          pMethod = 'Cash';
        } else if (receivedAcc.type == 'Wallet') {
          pMethod = 'Online';
        } else if (receivedAcc.type == 'Bank') {
          pMethod = 'Bank';
        }
      }

      if (actualAccountName.isEmpty) {
        if (matchedProj != null && matchedProj.bankAccountName.isNotEmpty) {
          actualAccountName = matchedProj.bankAccountName;
        } else {
          actualAccountName = pMethod == 'Bank' ? 'Bank Account' : (pMethod == 'Cash' ? 'Cash Account' : 'Online Wallet');
        }
      }

      // Determine clean, meaningful Reference
      String actualRef = '';
      final isAddon = inc.incomeType.toLowerCase().contains('addon') ||
          inc.description.toLowerCase().contains('addon') ||
          (inc.projectPaymentType != null && inc.projectPaymentType!.toLowerCase().contains('addon'));

      if (isAddon) {
        actualRef = 'ADDON';
      } else if (matchedProj != null && matchedProj.name.isNotEmpty) {
        actualRef = matchedProj.name;
      } else if (inc.invoiceNumber.isNotEmpty && !inc.invoiceNumber.contains('_') && !RegExp(r'\d{6,}').hasMatch(inc.invoiceNumber)) {
        actualRef = inc.invoiceNumber;
      } else {
        actualRef = '—';
      }

      String isoDate = inc.date.isNotEmpty ? inc.date : DateTime.now().toIso8601String();
      final dt = _extractTimestampFromId(inc.id);
      if (dt != null) {
        if (isoDate.length == 10) {
          isoDate += dt.toIso8601String().substring(10);
        } else if (isoDate.endsWith('T00:00:00.000') || isoDate.endsWith('T00:00:00') || isoDate.endsWith(':00.000')) {
          final p = DateTime.tryParse(isoDate);
          if (p != null && p.second == 0 && p.millisecond == 0) {
            isoDate = DateTime(p.year, p.month, p.day, p.hour, p.minute, dt.second, dt.millisecond).toIso8601String();
          }
        }
      }

      return LedgerEntry(
        id: 'led_inc_${inc.id}',
        date: isoDate,
        accountId: actualAccountId,
        accountName: actualAccountName,
        type: 'Debit',
        category: pMethod, // Payment Method (Bank / Cash / Online)
        amount: inc.amount,
        reference: actualRef, // Clean linked reference (no random fake strings)
        installmentType: installmentText,
        description: desc,
      );
    });

    // Compile real entries from ExpenseRecords
    final realExpenseEntries = expenses.map((exp) {
      String isoDate = exp.date.isNotEmpty ? exp.date : DateTime.now().toIso8601String();
      if (isoDate.length == 10) {
        final dt = _extractTimestampFromId(exp.id);
        if (dt != null) {
          isoDate += dt.toIso8601String().substring(10);
        }
        if (isoDate.length == 10) {
          isoDate += 'T12:00:00.000';
        }
      }

      return LedgerEntry(
        id: 'led_exp_${exp.id}',
        date: isoDate,
        accountId: exp.accountId,
        accountName: accountMap[exp.accountId] ?? 'Bank/Cash Account',
        type: 'Credit',
        category: exp.category,
        amount: exp.amount,
        reference: exp.vendorName.isNotEmpty ? exp.vendorName : 'Expense Outflow',
        description: exp.description,
      );
    });

    // Only use real income/expense records (no duplicate legacy entries)
    // Filter out any state.entries that overlap with income/expense IDs
    final incExpIds = <String>{};
    for (final inc in incomes) {
      incExpIds.add('led_inc_${inc.id}');
    }
    for (final exp in expenses) {
      incExpIds.add('led_exp_${exp.id}');
    }
    final uniqueStaticEntries = state.entries.where((e) => !incExpIds.contains(e.id)).map((e) {
      if (e.date.length == 10) {
        final dt = _extractTimestampFromId(e.id);
        if (dt != null) {
          final pDate = DateTime.tryParse(e.date) ?? dt;
          return e.copyWith(
            date: DateTime(pDate.year, pDate.month, pDate.day, dt.hour, dt.minute, dt.second, dt.millisecond).toIso8601String(),
          );
        }
        return e.copyWith(date: '${e.date}T12:00:00.000');
      }
      return e;
    }).toList();

    // Include Opening Balance entries for all accounts (Company & Personal) if not already present
    final existingIds = <String>{
      ...incExpIds,
      ...uniqueStaticEntries.map((e) => e.id),
    };
    final openingBalanceEntries = accountsState.accounts
        .where((a) => a.openingBalance > 0 && !existingIds.contains('led_opening_${a.id}'))
        .map((a) => LedgerEntry(
              id: 'led_opening_${a.id}',
              date: a.ledgerOpeningDate,
              accountId: a.id,
              accountName: a.name,
              type: 'Debit',
              category: 'Opening Balance',
              amount: a.openingBalance,
              reference: 'Opening Balance',
              description: 'Opening balance deposited for ${a.name}',
            ));

    final allEntries = [
      ...uniqueStaticEntries,
      ...realIncomeEntries,
      ...realExpenseEntries,
      ...openingBalanceEntries,
    ];

    // Filter entries
    final filteredEntries = allEntries.where((e) {
      final cleanTxId = TransactionIdHelper.getLedgerInvoiceId(entry: e, incomes: incomes, expenses: expenses);
      final matchesSearch = state.searchQuery.isEmpty ||
          e.description.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          e.reference.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          e.id.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          cleanTxId.toLowerCase().contains(state.searchQuery.toLowerCase());

      final matchesAccount = activeAccountFilter == 'All' || e.accountId == activeAccountFilter;

      bool matchesType = true;
      if (state.typeFilter == 'Debit') {
        matchesType = e.type == 'Debit';
      } else if (state.typeFilter == 'Credit') {
        matchesType = e.type == 'Credit';
      } else if (state.typeFilter == 'Loans') {
        matchesType = e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan');
      } else if (state.typeFilter == 'Loans: Borrowed') {
        matchesType = (e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan')) && e.category.toLowerCase().contains('borrowed');
      } else if (state.typeFilter == 'Loans: Lent') {
        matchesType = (e.id.startsWith('led_loan_') || e.category.toLowerCase().contains('loan')) && e.category.toLowerCase().contains('lent');
      }

      bool matchesDate = true;
      if (state.startDate != null && state.endDate != null) {
        try {
          final entryDate = DateTime.parse(e.date);
          final start = DateTime(state.startDate!.year, state.startDate!.month, state.startDate!.day);
          final end = DateTime(state.endDate!.year, state.endDate!.month, state.endDate!.day, 23, 59, 59);
          matchesDate = entryDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
                        entryDate.isBefore(end.add(const Duration(seconds: 1)));
        } catch (_) {}
      }

      return matchesSearch && matchesAccount && matchesType && matchesDate;
    }).toList();

    final sortedFilteredEntries = LedgerEntry.sortEntriesNewestFirst(filteredEntries);

    // Pagination Logic
    final currentPage = state.currentPage;
    final rowsPerPage = 10;
    final int totalRecords = sortedFilteredEntries.length;
    final int totalPages = (totalRecords / rowsPerPage).ceil();
    final validPage = currentPage >= totalPages ? (totalPages - 1).clamp(0, totalPages) : currentPage;
    final paginatedEntries = sortedFilteredEntries.skip(validPage * rowsPerPage).take(rowsPerPage).toList();

    // Calculate metrics
    final totalBalance = accountsState.accounts
        .where((a) => a.isCompany)
        .fold<double>(
          0.0,
          (sum, acc) => sum + calculateAuthoritativeAccountBalance(
            account: acc,
            incomes: incomes,
            expenses: expenses,
            loans: loans,
            ledgerEntries: allEntries,
          ),
        );
    
    final todayDateString = DateTime.now().toIso8601String().substring(0, 10);

    final incomeEntries = filteredEntries
      .where((e) => e.id.startsWith('led_inc_'))
      .toList();
    final expenseEntries = filteredEntries
      .where((e) => e.id.startsWith('led_exp_'))
      .toList();

    final double todayInflow = incomeEntries
      .where((e) => e.date.startsWith(todayDateString.substring(0,10)))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final double todayOutflow = expenseEntries
      .where((e) => e.date.startsWith(todayDateString.substring(0,10)))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final double totalInflow = incomeEntries
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/ledger'),
          Expanded(
            child: (state.isLoading && allEntries.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        if (isMobile) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'General Ledger',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Audit double-entry debit/credit ledger records and cash flow transactions.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ExportButton(
                                title: 'General Ledger Report',
                                fileName: 'general_ledger_report',
                                headers: const ['Transaction ID', 'Date & Time', 'Type', 'Account', 'Reference', 'Debit (PKR)', 'Credit (PKR)'],
                                rows: sortedFilteredEntries.map((e) {
                                  final isDebit = e.type.toLowerCase() == 'debit' || e.type.toLowerCase() == 'expense';
                                  final cleanTxId = TransactionIdHelper.getLedgerInvoiceId(entry: e, incomes: incomes, expenses: expenses);
                                  return [
                                    cleanTxId,
                                    e.date,
                                    isDebit ? 'Debit / Expense' : 'Credit / Income',
                                    e.accountId.isNotEmpty ? e.accountId : 'Cash/Bank',
                                    e.description.isNotEmpty ? e.description : '-',
                                    isDebit ? 'Rs. ${e.amount.toStringAsFixed(0)}' : '-',
                                    !isDebit ? 'Rs. ${e.amount.toStringAsFixed(0)}' : '-',
                                  ];
                                }).toList(),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'General Ledger',
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Audit double-entry debit/credit ledger records and cash flow transactions.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ExportButton(
                                title: 'General Ledger Report',
                                fileName: 'general_ledger_report',
                                headers: const ['Transaction ID', 'Date & Time', 'Type', 'Account', 'Reference', 'Debit (PKR)', 'Credit (PKR)'],
                                rows: sortedFilteredEntries.map((e) {
                                  final isDebit = e.type.toLowerCase() == 'debit' || e.type.toLowerCase() == 'expense';
                                  final cleanTxId = TransactionIdHelper.getLedgerInvoiceId(entry: e, incomes: incomes, expenses: expenses);
                                  return [
                                    cleanTxId,
                                    e.date,
                                    isDebit ? 'Debit / Expense' : 'Credit / Income',
                                    e.accountId.isNotEmpty ? e.accountId : 'Cash/Bank',
                                    e.description.isNotEmpty ? e.description : '-',
                                    isDebit ? 'Rs. ${e.amount.toStringAsFixed(0)}' : '-',
                                    !isDebit ? 'Rs. ${e.amount.toStringAsFixed(0)}' : '-',
                                  ];
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 5 : (constraints.maxWidth >= 800 ? 3 : 2);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: gridCrossCount >= 4
                                    ? 1.85
                                    : (gridCrossCount >= 3 ? 1.4 : (constraints.maxWidth < 400 ? 1.25 : 1.35)),
                              ),
                              children: [
                                StatCard(
                                  title: 'Current Balance',
                                  tooltipMessage: 'Detailed statistics and information regarding Current Balance.',
                                  value: CurrencyFormatter.formatAccountingBalance(totalBalance),
                                  trendText: 'Available',
                                ),
                                StatCard(
                                  title: "Today's Income",
                                  tooltipMessage: "Detailed statistics and information regarding Today's Income.",
                                  value: 'Rs. ${todayInflow.toStringAsFixed(0)}',
                                  trendText: 'Received today',
                                ),
                                StatCard(
                                  title: "Today's Expenses",
                                  tooltipMessage: "Detailed statistics and information regarding Today's Expenses.",
                                  value: 'Rs. ${todayOutflow.toStringAsFixed(0)}',
                                  trendText: 'Spent today',
                                ),
                                StatCard(
                                  title: "Today's Net",
                                  tooltipMessage: "Detailed statistics and information regarding Today's Net.",
                                  value: 'Rs. ${(todayInflow - todayOutflow).toStringAsFixed(0)}',
                                  trendText: 'Income - Expenses',
                                ),
                                StatCard(
                                  title: 'Total Income',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Income.',
                                  value: 'Rs. ${totalInflow.toStringAsFixed(0)}',
                                  trendText: 'All-time income',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar
                        if (isMobile)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: TextField(
                                    onChanged: (val) => ref.read(ledgerProvider.notifier).setSearchQuery(val),
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: tr('Search transactions...'),
                                      hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                      prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (btnCtx) {
                                  final activeCount = (state.startDate != null ? 1 : 0) +
                                      (activeAccountFilter != 'All' ? 1 : 0) +
                                      (state.typeFilter != 'All' ? 1 : 0);
                                  return InkWell(
                                    onTap: () {
                                      _showLedgerFilterBottomSheet(context, ref, state, accountMap, tr);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: activeCount > 0
                                            ? context.primaryColor.withValues(alpha: 0.12)
                                            : (context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: activeCount > 0 ? context.primaryColor : context.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.filter_list_rounded,
                                            size: 20,
                                            color: activeCount > 0 ? context.primaryColor : context.textSecondary,
                                          ),
                                          if (activeCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: context.primaryColor,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$activeCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: max(800.0, MediaQuery.of(context).size.width - 48),
                              child: GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Search
                                      SizedBox(
                                        width: 180,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: TextField(
                                            onChanged: (val) => ref.read(ledgerProvider.notifier).setSearchQuery(val),
                                            style: TextStyle(color: context.textPrimary),
                                            decoration: InputDecoration(
                                              hintText: tr('Search transactions...'),
                                              hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
                                              prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Date Range Filter
                                      SizedBox(
                                        width: 180,
                                        height: 40,
                                        child: InkWell(
                                          onTap: () async {
                                            final picked = await showDateRangePicker(
                                              context: context,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                              initialDateRange: state.startDate != null && state.endDate != null
                                                  ? DateTimeRange(start: state.startDate!, end: state.endDate!)
                                                  : null,
                                            );
                                            if (picked != null) {
                                              ref.read(ledgerProvider.notifier).setDateRange(picked.start, picked.end);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: context.border, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today_outlined, size: 16, color: context.textSecondary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    state.startDate != null && state.endDate != null
                                                        ? '${state.startDate!.toIso8601String().substring(0,10)} - ${state.endDate!.toIso8601String().substring(0,10)}'
                                                        : tr('Date Range'),
                                                    style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Account Filter
                                      SizedBox(
                                        width: 170,
                                        height: 40,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: activeAccountFilter,
                                              dropdownColor: context.cardBg,
                                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                              items: [
                                                DropdownMenuItem(value: 'All', child: Text(tr('All Accounts'))),
                                                ...companyAccounts.map((a) => DropdownMenuItem(
                                                  value: a.id,
                                                  child: Text(_formatAccountFilterLabel(a), overflow: TextOverflow.ellipsis),
                                                )),
                                                ...personalAccounts.map((a) => DropdownMenuItem(
                                                  value: a.id,
                                                  child: Text(_formatAccountFilterLabel(a), overflow: TextOverflow.ellipsis),
                                                )),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref.read(ledgerProvider.notifier).setAccountFilter(val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Type Filter (Debit/Credit/Loans)
                                      SizedBox(
                                        width: 185,
                                        height: 40,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: state.typeFilter,
                                              dropdownColor: context.cardBg,
                                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                              items: [
                                                DropdownMenuItem(value: 'All', child: Text(tr('All Types'))),
                                                DropdownMenuItem(value: 'Debit', child: Text(tr('Inflow (Debit)'))),
                                                DropdownMenuItem(value: 'Credit', child: Text(tr('Outflow (Credit)'))),
                                                DropdownMenuItem(value: 'Loans', child: Text(tr('Loans (All Records)'))),
                                                DropdownMenuItem(value: 'Loans: Borrowed', child: Text(tr('Loans: Borrowed'))),
                                                DropdownMenuItem(value: 'Loans: Lent', child: Text(tr('Loans: Lent'))),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref.read(ledgerProvider.notifier).setTypeFilter(val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Clear Filter
                                      OutlinedButton(
                                        onPressed: () {
                                          ref.read(ledgerProvider.notifier).clearFilters();
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          side: BorderSide(color: context.border),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Clear', style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Ledger Table/List
                        LayoutBuilder(
                          builder: (context, tableConstraints) {
                            return Container(
                              decoration: BoxDecoration(
                                color: context.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: max(980.0, tableConstraints.maxWidth),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Table Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            decoration: BoxDecoration(
                                              color: context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                              border: Border(bottom: BorderSide(color: context.border)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 1, child: Text('Type', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Text('Invoice / ID', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 3, child: Text('Description', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Row(children: [Text('Date & Time', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.arrow_downward, size: 14, color: context.textPrimary)])),
                                                Expanded(flex: 2, child: Text('Account', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Text('Category', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Text('Reference', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Amount', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)))),
                                              ],
                                            ),
                                          ),
                                          // Table Body
                                          paginatedEntries.isEmpty
                                              ? _buildEmptyState(context)
                                              : ListView.separated(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  padding: EdgeInsets.zero,
                                                  itemCount: paginatedEntries.length,
                                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                                  itemBuilder: (context, index) {
                                                    return _LedgerListTile(entry: paginatedEntries[index]);
                                                  },
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Pagination Controls
                                  if (totalPages > 1)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                        border: Border(top: BorderSide(color: context.border)),
                                      ),
                                      child: isMobile
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Showing ${(validPage * rowsPerPage) + 1} to ${(validPage * rowsPerPage) + paginatedEntries.length} of $totalRecords entries',
                                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        OutlinedButton(
                                                          onPressed: validPage > 0 ? () => ref.read(ledgerProvider.notifier).setCurrentPage(validPage - 1) : null,
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            side: BorderSide(color: validPage > 0 ? context.border : context.border.withValues(alpha: 0.5)),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          child: Text('Previous', style: TextStyle(color: validPage > 0 ? context.textPrimary : context.textMuted, fontSize: 12)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: List.generate(totalPages, (index) {
                                                            final isCurrent = index == validPage;
                                                            if (totalPages > 5) {
                                                              if (index != 0 && index != totalPages - 1 && (index < validPage - 1 || index > validPage + 1)) {
                                                                if (index == 1 && validPage > 2) return const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('...'));
                                                                if (index == totalPages - 2 && validPage < totalPages - 3) return const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('...'));
                                                                return const SizedBox.shrink();
                                                              }
                                                            }
                                                            return InkWell(
                                                              onTap: () => ref.read(ledgerProvider.notifier).setCurrentPage(index),
                                                              child: Container(
                                                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                                                width: 30,
                                                                height: 30,
                                                                alignment: Alignment.center,
                                                                decoration: BoxDecoration(
                                                                  color: isCurrent ? context.primaryColor : Colors.transparent,
                                                                  borderRadius: BorderRadius.circular(6),
                                                                ),
                                                                child: Text(
                                                                  '${index + 1}',
                                                                  style: TextStyle(
                                                                    color: isCurrent ? Colors.white : context.textPrimary,
                                                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                                    fontSize: 12,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        OutlinedButton(
                                                          onPressed: validPage < totalPages - 1 ? () => ref.read(ledgerProvider.notifier).setCurrentPage(validPage + 1) : null,
                                                          style: OutlinedButton.styleFrom(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                            side: BorderSide(color: validPage < totalPages - 1 ? context.border : context.border.withValues(alpha: 0.5)),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          child: Text('Next', style: TextStyle(color: validPage < totalPages - 1 ? context.textPrimary : context.textMuted, fontSize: 12)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Showing ${(validPage * rowsPerPage) + 1} to ${(validPage * rowsPerPage) + paginatedEntries.length} of $totalRecords entries',
                                                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                                                  ),
                                                  Row(
                                                    children: [
                                                      OutlinedButton(
                                                        onPressed: validPage > 0 ? () => ref.read(ledgerProvider.notifier).setCurrentPage(validPage - 1) : null,
                                                        style: OutlinedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                                          side: BorderSide(color: validPage > 0 ? context.border : context.border.withValues(alpha: 0.5)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        child: Text('Previous', style: TextStyle(color: validPage > 0 ? context.textPrimary : context.textMuted)),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Page Numbers
                                                      Row(
                                                        children: List.generate(totalPages, (index) {
                                                          final isCurrent = index == validPage;
                                                          // Show first, last, current and +/- 1
                                                          if (totalPages > 5) {
                                                            if (index != 0 && index != totalPages - 1 && (index < validPage - 1 || index > validPage + 1)) {
                                                              if (index == 1 && validPage > 2) return const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...'));
                                                              if (index == totalPages - 2 && validPage < totalPages - 3) return const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...'));
                                                              return const SizedBox.shrink();
                                                            }
                                                          }
                                                          return InkWell(
                                                            onTap: () => ref.read(ledgerProvider.notifier).setCurrentPage(index),
                                                            child: Container(
                                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                                              width: 32,
                                                              height: 32,
                                                              alignment: Alignment.center,
                                                              decoration: BoxDecoration(
                                                                color: isCurrent ? context.primaryColor : Colors.transparent,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                '${index + 1}',
                                                                style: TextStyle(
                                                                  color: isCurrent ? Colors.white : context.textPrimary,
                                                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      OutlinedButton(
                                                        onPressed: validPage < totalPages - 1 ? () => ref.read(ledgerProvider.notifier).setCurrentPage(validPage + 1) : null,
                                                        style: OutlinedButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                                          side: BorderSide(color: validPage < totalPages - 1 ? context.border : context.border.withValues(alpha: 0.5)),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        child: Text('Next', style: TextStyle(color: validPage < totalPages - 1 ? context.textPrimary : context.textMuted)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                       ],
                     ),
                   ),
                 ),
               ],
             ),
    );
  }

  void _showLedgerFilterBottomSheet(
    BuildContext context,
    WidgetRef ref,
    LedgerState state,
    Map<String, String> accountMap,
    dynamic tr,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentState = ref.watch(ledgerProvider);
            final accountsState = ref.watch(accountsProvider);
            final bottomSheetCompanyAccounts = accountsState.accounts.where((a) => a.isCompany).toList();
            final bottomSheetPersonalAccounts = accountsState.accounts.where((a) => a.isPersonal).toList();
            final isModalAccountValid = currentState.accountFilter == 'All' || accountsState.accounts.any((a) => a.id == currentState.accountFilter);
            final activeAccount = isModalAccountValid ? currentState.accountFilter : 'All';
            final activeType = currentState.typeFilter;
            final startDate = currentState.startDate;
            final endDate = currentState.endDate;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('Filter Transactions'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Date Range
                    Text(
                      tr('Date Range'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: startDate != null && endDate != null
                              ? DateTimeRange(start: startDate, end: endDate)
                              : null,
                        );
                        if (picked != null) {
                          ref.read(ledgerProvider.notifier).setDateRange(picked.start, picked.end);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: context.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                startDate != null && endDate != null
                                    ? '${startDate.toIso8601String().substring(0, 10)} - ${endDate.toIso8601String().substring(0, 10)}'
                                    : tr('All Dates'),
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (startDate != null)
                              InkWell(
                                onTap: () {
                                  ref.read(ledgerProvider.notifier).setDateRange(null, null);
                                },
                                child: Icon(Icons.clear, size: 16, color: context.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account Filter
                    Text(
                      tr('Account'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: activeAccount,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            DropdownMenuItem(value: 'All', child: Text(tr('All Accounts'))),
                            ...bottomSheetCompanyAccounts.map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(_formatAccountFilterLabel(a), overflow: TextOverflow.ellipsis),
                            )),
                            ...bottomSheetPersonalAccounts.map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(_formatAccountFilterLabel(a), overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(ledgerProvider.notifier).setAccountFilter(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type Filter (Debit/Credit)
                    Text(
                      tr('Transaction Type'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: activeType,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            DropdownMenuItem(value: 'All', child: Text(tr('All Types'))),
                            DropdownMenuItem(value: 'Debit', child: Text(tr('Inflow (Debit)'))),
                            DropdownMenuItem(value: 'Credit', child: Text(tr('Outflow (Credit)'))),
                            DropdownMenuItem(value: 'Loans', child: Text(tr('Loans (All Records)'))),
                            DropdownMenuItem(value: 'Loans: Borrowed', child: Text(tr('Loans: Borrowed'))),
                            DropdownMenuItem(value: 'Loans: Lent', child: Text(tr('Loans: Lent'))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(ledgerProvider.notifier).setTypeFilter(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref.read(ledgerProvider.notifier).clearFilters();
                              Navigator.pop(modalCtx);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(tr('Reset'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(tr('Apply'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Transactions Logged',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Audit logs will appear here once cash movements are registered.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerListTile extends ConsumerWidget {
  final LedgerEntry entry;

  const _LedgerListTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final incomes = ref.watch(incomeProvider).incomes;
    final expenses = ref.watch(expensesProvider).expenses;
    final projects = ref.watch(projectsProvider).projects;
    final displayInvoiceId = TransactionIdHelper.getLedgerInvoiceId(
      entry: entry,
      incomes: incomes,
      expenses: expenses,
    );
    final adminState = ref.watch(adminProvider);
    bool canDelete = false;
    if (entry.id.startsWith('led_inc_')) {
      canDelete = adminState.hasPermission(AppModule.income, PermissionAction.delete);
    } else if (entry.id.startsWith('led_exp_')) {
      canDelete = adminState.hasPermission(AppModule.expenses, PermissionAction.delete);
    } else {
      canDelete = adminState.hasPermission(AppModule.finance, PermissionAction.delete);
    }
    final isDebit = entry.type == 'Debit';
    final primaryColor = isDebit ? context.success : context.error;
    final bgColor = isDebit ? context.successLight : context.errorLight;
    
    // Parse Date and Time dynamically
    String timeStr = '12:00 PM';
    try {
      final parsed = DateTime.parse(entry.date);
      if (parsed.hour == 0 && parsed.minute == 0) {
        // For date-only strings, check if entry.id has epoch timestamp
        final dt = _extractTimestampFromId(entry.id);
        if (dt != null) {
          final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
          final amPm = dt.hour >= 12 ? 'PM' : 'AM';
          final min = dt.minute.toString().padLeft(2, '0');
          timeStr = '$hour:$min $amPm';
        }
      } else {
        final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
        final amPm = parsed.hour >= 12 ? 'PM' : 'AM';
        final min = parsed.minute.toString().padLeft(2, '0');
        timeStr = '$hour:$min $amPm';
      }
    } catch (_) {
      timeStr = '12:00 PM';
    }

    return InkWell(
      onTap: () {
        TransactionDetailDialog.show(
          context,
          id: displayInvoiceId,
          title: entry.description,
          category: entry.category,
          description: entry.description,
          amount: entry.amount,
          date: entry.date,
          type: entry.type,
          accountName: entry.accountName,
          reference: entry.reference.isNotEmpty && entry.reference != '—' ? entry.reference : displayInvoiceId,
          onDelete: canDelete
              ? () async {
                  if (entry.id.startsWith('led_inc_')) {
                    final realIncId = entry.id.replaceFirst('led_inc_', '');
                    await ref.read(incomeProvider.notifier).deleteIncome(realIncId);
                  } else if (entry.id.startsWith('led_exp_')) {
                    final realExpId = entry.id.replaceFirst('led_exp_', '');
                    await ref.read(expensesProvider.notifier).deleteExpense(realExpId);
                  } else {
                    await ref.read(ledgerProvider.notifier).deleteLedgerEntry(entry.id);
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted successfully')),
                  );
                }
              : null,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: context.cardBg,
        child: Row(
        children: [
          // 1. Type
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: primaryColor,
                ),
              ),
            ),
          ),

          // 2. Invoice / Ref ID
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF111827) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.border),
                ),
                child: Text(
                  displayInvoiceId,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 3. Description (Project Name - Client Name + Installment Type Subtext)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  // Only income records have installment labels such as Advance Payment.
                  // Other debit rows must retain their real category/reference.
                  isDebit
                      ? (entry.installmentType.isNotEmpty
                          ? entry.installmentType
                          : (entry.id.startsWith('led_inc_')
                              ? 'Payment Received'
                              : (entry.category.isNotEmpty ? entry.category : (entry.reference.isNotEmpty && entry.reference != '—' ? entry.reference : 'Inflow'))))
                      : (entry.reference.contains('Expense') || entry.reference.contains('Outflow')
                          ? entry.category
                          : (entry.category.isNotEmpty ? entry.category : entry.reference)),
                  style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Date & Time
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(entry.date.split('T').first, style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(timeStr, style: TextStyle(color: context.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Account
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.accountName,
                  style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.category == 'Cash'
                      ? 'Cash Account'
                      : (entry.category == 'Online' ? 'Online Wallet' : 'Bank Account'),
                  style: TextStyle(color: context.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // 5. Category (Pill)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.category,
                  style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // 6. Reference
          Expanded(
            flex: 2,
            child: Builder(
              builder: (context) {
                String refText = entry.reference;
                if (refText.contains('proj_') || refText.contains('pro_') || refText.contains('rec_')) {
                  final rawId = refText.replaceFirst('Ref:', '').trim();
                  final cleanProj = projects.where((p) => p.id == rawId || p.id == refText).firstOrNull;
                  if (cleanProj != null && cleanProj.name.isNotEmpty) {
                    refText = cleanProj.name;
                  } else {
                    refText = 'Project Payment';
                  }
                }

                final isAddon = refText == 'ADDON';
                final isCleanProject = refText.isNotEmpty && refText != '—' && !isAddon;

                return Text(
                  isAddon
                      ? 'ADDON'
                      : (isCleanProject
                          ? (refText.startsWith('Ref:') ? refText : refText)
                          : '—'),
                  style: TextStyle(
                    color: isAddon ? context.textPrimary : context.textSecondary,
                    fontSize: 12,
                    fontWeight: isAddon ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),

          // 7. Amount
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Rs. ${entry.amount.toStringAsFixed(2)}',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

