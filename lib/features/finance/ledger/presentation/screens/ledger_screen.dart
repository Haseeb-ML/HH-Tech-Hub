import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/ledger_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/projects/presentation/screens/projects_screen.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import 'package:software_house_erp/features/finance/shared/widgets/transaction_detail_dialog.dart';
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(ledgerProvider);
    final accountsState = ref.watch(accountsProvider);
    final clientAccounts = ref.watch(clientAccountsProvider);
    final incomes = ref.watch(incomeProvider).incomes;
    final expenses = ref.watch(expensesProvider).expenses;
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expensesProvider.notifier).syncAssetsAndInventoryExpenses();
    });

    // Build account lookup map
    final accountMap = {
      for (var a in accountsState.accounts) a.id: a.name,
      for (var ca in clientAccounts) ca.id: ca.name,
    };

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

      // Determine accurate Account Name & Account ID
      String actualAccountId = inc.accountId;
      String actualAccountName = accountMap[inc.accountId] ?? '';

      if (matchedClientAccount != null) {
        actualAccountId = matchedClientAccount.id;
        actualAccountName = matchedClientAccount.name;
        if (matchedClientAccount.bankName.isNotEmpty && !actualAccountName.toLowerCase().contains(matchedClientAccount.bankName.toLowerCase())) {
          actualAccountName = '${matchedClientAccount.name} (${matchedClientAccount.bankName})';
        }
      } else if (matchedProj != null && matchedProj.clientPaymentSource.isNotEmpty && matchedProj.clientPaymentSource != 'Cash') {
        actualAccountName = matchedProj.clientPaymentSource;
      } else if (matchedProj != null && matchedProj.bankAccountName.isNotEmpty && (pMethod != 'Bank' || !matchedProj.bankAccountName.toLowerCase().contains('cash'))) {
        actualAccountName = matchedProj.bankAccountName;
      } else if (actualAccountName.isEmpty || (pMethod == 'Bank' && actualAccountName.toLowerCase().contains('cash'))) {
        actualAccountName = pMethod == 'Bank' ? 'Bank Account' : (pMethod == 'Cash' ? 'Cash Account' : 'Online Wallet');
      }

      // Determine clean, meaningful Reference
      String actualRef = '';
      if (inc.invoiceNumber.isNotEmpty) {
        actualRef = inc.invoiceNumber;
      } else if (inc.projectId != null && inc.projectId!.isNotEmpty) {
        actualRef = inc.projectId!;
      } else if (matchedProj != null && matchedProj.name.isNotEmpty) {
        actualRef = matchedProj.name;
      } else {
        actualRef = '—';
      }

      String isoDate = inc.date.isNotEmpty ? inc.date : DateTime.now().toIso8601String();
      final idNumStr = inc.id.replaceAll(RegExp(r'[^0-9]'), '');
      if (idNumStr.length > 10) {
        final ms = int.tryParse(idNumStr);
        if (ms != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ms);
          if (isoDate.length == 10) {
            isoDate += dt.toIso8601String().substring(10);
          } else if (isoDate.endsWith('T00:00:00.000') || isoDate.endsWith('T00:00:00') || isoDate.endsWith(':00.000')) {
            // Keep chosen date, hour and minute, but incorporate real creation seconds/milliseconds
            final p = DateTime.tryParse(isoDate);
            if (p != null && p.second == 0 && p.millisecond == 0) {
              isoDate = DateTime(p.year, p.month, p.day, p.hour, p.minute, dt.second, dt.millisecond).toIso8601String();
            }
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
        final idNumStr = exp.id.replaceAll(RegExp(r'[^0-9]'), '');
        if (idNumStr.length > 10) {
          final ms = int.tryParse(idNumStr);
          if (ms != null) {
            isoDate += DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String().substring(10);
          }
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
        final idNumStr = e.id.replaceAll(RegExp(r'[^0-9]'), '');
        if (idNumStr.length > 10) {
          final ms = int.tryParse(idNumStr);
          if (ms != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ms);
            final pDate = DateTime.tryParse(e.date) ?? dt;
            return e.copyWith(
              date: DateTime(pDate.year, pDate.month, pDate.day, dt.hour, dt.minute, dt.second, dt.millisecond).toIso8601String(),
            );
          }
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
              date: a.openingBalanceDate.isNotEmpty ? a.openingBalanceDate : DateTime.now().toIso8601String(),
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
      final matchesSearch = state.searchQuery.isEmpty ||
          e.description.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(state.searchQuery.toLowerCase()) ||
          e.reference.toLowerCase().contains(state.searchQuery.toLowerCase());

      final matchesAccount = state.accountFilter == 'All' || e.accountId == state.accountFilter;
      final matchesType = state.typeFilter == 'All' || e.type == state.typeFilter;

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
        .where((a) => a.accountScope != 'Personal')
        .fold<double>(0.0, (sum, acc) => sum + acc.balance);
    
    final todayDateString = DateTime.now().toIso8601String().substring(0, 10);

    final double todayInflow = filteredEntries
        .where((e) => e.type == 'Debit' && e.date.startsWith(todayDateString.substring(0,10)))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final double todayOutflow = filteredEntries
        .where((e) => e.type == 'Credit' && e.date.startsWith(todayDateString.substring(0,10)))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final double totalInflow = filteredEntries
        .where((e) => e.type == 'Debit')
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const FinanceSubNav(activeRoute: '/finance/ledger'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Column(
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
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 5 : (constraints.maxWidth >= 800 ? 3 : (constraints.maxWidth >= 500 ? 2 : 1));
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: gridCrossCount >= 4 ? 1.9 : 1.6,
                              ),
                              children: [
                                StatCard(
                                  title: 'Current Balance',
                                  tooltipMessage: 'Detailed statistics and information regarding Current Balance.',
                                  value: 'Rs. ${totalBalance.toStringAsFixed(0)}',
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
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Search
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 40,
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
                                Expanded(
                                  flex: 2,
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
                                      height: 40,
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
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.border, width: 1),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: state.accountFilter,
                                        dropdownColor: context.cardBg,
                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        items: [
                                          const DropdownMenuItem(value: 'All', child: Text('All Accounts')),
                                          ...accountMap.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
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

                                // Type Filter (Debit/Credit)
                                Expanded(
                                  child: Container(
                                    height: 40,
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
                        const SizedBox(height: 24),

                        // Ledger Table/List
                        Container(
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.border),
                          ),
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
                                    Expanded(flex: 3, child: Text('Description', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Row(children: [Text('Date & Time', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Icon(Icons.arrow_downward, size: 14, color: context.textPrimary)])),
                                    Expanded(flex: 2, child: Text('Account', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Category', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('Reference', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('Amount', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)))),
                                    Expanded(flex: 1, child: Align(alignment: Alignment.centerRight, child: Text('Action', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)))),
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
                                // Pagination Controls
                                if (totalPages > 1)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade50,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      border: Border(top: BorderSide(color: context.border)),
                                    ),
                                    child: Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    final isDebit = entry.type == 'Debit';
    final primaryColor = isDebit ? context.success : context.error;
    final bgColor = isDebit ? context.successLight : context.errorLight;
    
    // Parse Date and Time dynamically
    String timeStr = '12:00 PM';
    try {
      final parsed = DateTime.parse(entry.date);
      if (parsed.hour == 0 && parsed.minute == 0) {
        // For date-only strings, check if entry.id has epoch timestamp
        final idNumStr = entry.id.replaceAll(RegExp(r'[^0-9]'), '');
        if (idNumStr.length > 10) {
          final ms = int.tryParse(idNumStr);
          if (ms != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ms);
            final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
            final amPm = dt.hour >= 12 ? 'PM' : 'AM';
            final min = dt.minute.toString().padLeft(2, '0');
            timeStr = '$hour:$min $amPm';
          }
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
          id: entry.id,
          title: entry.description,
          category: entry.category,
          description: entry.description,
          amount: entry.amount,
          date: entry.date,
          type: entry.type,
          accountName: entry.accountName,
          reference: entry.reference,
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

          // 2. Description (Project Name - Client Name + Installment Type Subtext)
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
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
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
            child: Text(
              (entry.reference.isNotEmpty &&
                      entry.reference != '—' &&
                      !entry.reference.contains('Expense Outflow') &&
                      !entry.reference.contains('Payment Received') &&
                      !entry.reference.contains('Advance Payment') &&
                      !entry.reference.contains('Partial Payment') &&
                      !entry.reference.contains('Full Payment'))
                  ? (entry.reference.startsWith('Ref:') ? entry.reference : 'Ref: ${entry.reference}')
                  : '—',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

          // 8. Action (3 dots with Delete Warning)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Text('Are you sure you want to delete transaction "${entry.description}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (entry.id.startsWith('led_inc_')) {
                        final realIncId = entry.id.replaceFirst('led_inc_', '');
                        await ref.read(incomeProvider.notifier).deleteIncome(realIncId);
                      } else if (entry.id.startsWith('led_exp_')) {
                        final realExpId = entry.id.replaceFirst('led_exp_', '');
                        await ref.read(expensesProvider.notifier).deleteExpense(realExpId);
                      } else {
                        await ref.read(ledgerProvider.notifier).deleteLedgerEntry(entry.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted successfully')),
                      );
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

