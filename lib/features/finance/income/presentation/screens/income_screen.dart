import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/income_provider.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../clients/clients/presentation/providers/clients_provider.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/income_record.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/utils/transaction_id_helper.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  static const int _itemsPerPage = 10;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  String _formatIncomeDateTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      if (dt.hour != 0 || dt.minute != 0) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  void _showIncomeDetails(
    BuildContext context,
    IncomeRecord income,
    String accountName,
    String accountScope,
    String projectName,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => _IncomeDetailsDialog(
        income: income,
        accountName: accountName,
        accountScope: accountScope,
        projectName: projectName,
        formattedDateTime: _formatIncomeDateTime(income.date),
      ),
    );
  }

  void _showIncomeFilterBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(incomeProvider);
            final clientsState = ref.watch(clientsProvider);
            final accountsState = ref.watch(accountsProvider);

            return Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Income Records',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      'Client',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.clientFilter,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Clients')),
                            ...clientsState.clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(incomeProvider.notifier).setClientFilter(val);
                              setState(() => _currentPage = 0);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Deposit Account',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.accountIdFilter,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Deposit Accounts')),
                            ...accountsState.accounts.map((acc) {
                              final scopeLabel = acc.accountScope.isNotEmpty ? ' (${acc.accountScope})' : '';
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                child: Text('${acc.name}$scopeLabel'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(incomeProvider.notifier).setAccountIdFilter(val);
                              setState(() => _currentPage = 0);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Payment Status',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.statusFilter,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                            DropdownMenuItem(value: 'Received', child: Text('Received')),
                            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(incomeProvider.notifier).setStatusFilter(val);
                              setState(() => _currentPage = 0);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Date Range',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.fromDateFilter != null ? (DateTime.tryParse(state.fromDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                final dateStr = picked.toIso8601String().substring(0, 10);
                                ref.read(incomeProvider.notifier).setDateRange(dateStr, state.toDateFilter);
                                setState(() => _currentPage = 0);
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.fromDateFilter != null ? context.primaryColor : context.textMuted),
                            label: Text(
                              state.fromDateFilter != null ? 'From: ${state.fromDateFilter}' : 'From Date',
                              style: TextStyle(fontSize: 11.5, color: state.fromDateFilter != null ? context.primaryColor : context.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: state.toDateFilter != null ? (DateTime.tryParse(state.toDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                final dateStr = picked.toIso8601String().substring(0, 10);
                                ref.read(incomeProvider.notifier).setDateRange(state.fromDateFilter, dateStr);
                                setState(() => _currentPage = 0);
                              }
                            },
                            icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.toDateFilter != null ? context.primaryColor : context.textMuted),
                            label: Text(
                              state.toDateFilter != null ? 'To: ${state.toDateFilter}' : 'To Date',
                              style: TextStyle(fontSize: 11.5, color: state.toDateFilter != null ? context.primaryColor : context.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(incomeProvider.notifier).clearFilters();
                              setState(() => _currentPage = 0);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.error),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Reset Filters', style: TextStyle(color: context.error)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(incomeProvider);
    final accountsState = ref.watch(accountsProvider);
    final clientsState = ref.watch(clientsProvider);
    final projectsState = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalIncomes = state.incomes.length;
    final totalAmount = state.incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final pendingAmount = state.incomes
        .where((i) => i.status == 'Pending')
        .fold<double>(0.0, (sum, i) => sum + i.amount);
    final receivedAmount = totalAmount - pendingAmount;

    // Pagination calculations
    final filteredIncomes = state.filteredIncomes;
    final totalPages = (filteredIncomes.length / _itemsPerPage).ceil();
    final validPage = totalPages == 0
        ? 0
        : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
    final paginatedIncomes = filteredIncomes
        .skip(validPage * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/income'),
          Expanded(
            child: (state.isLoading && state.incomes.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Action Buttons Row (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final titleCol = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Income Registry',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Record client receipts, invoices paid, and project revenues.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );
                            final adminState = ref.watch(adminProvider);
                            final canCreateIncome = adminState.hasPermission(AppModule.income, PermissionAction.create);
                            final canExportIncome = adminState.hasPermission(AppModule.income, PermissionAction.export);

                            final actionsRow = SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (canCreateIncome)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (context) => const _RecordIncomeDialog(),
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Record Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                    ),
                                  if (canCreateIncome && canExportIncome) const SizedBox(width: 12),
                                  if (canExportIncome)
                                    ExportButton(
                                      title: 'Income Registry',
                                      fileName: 'income_registry_export',
                                      headers: ['Receipt ID', tr('Date'), 'Client Name', 'Amount', 'Account ID', 'Invoice Number', tr('Description'), tr('Status')],
                                      rows: state.filteredIncomes.map((i) {
                                         final rcpId = TransactionIdHelper.getReceiptId(i, state.incomes);
                                         final invId = TransactionIdHelper.getIncomeId(i, state.incomes);
                                        return [
                                           rcpId,
                                          i.date,
                                          i.clientName,
                                          'Rs. ${i.amount.toStringAsFixed(0)}',
                                          i.accountId,
                                          invId,
                                          i.description,
                                          i.status,
                                        ];
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleCol,
                                  const SizedBox(height: 12),
                                  actionsRow,
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [titleCol, actionsRow],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final gridCrossCount = isMobile ? 2 : (constraints.maxWidth >= 1200 ? 4 : 2);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: isMobile ? 10 : 16,
                                mainAxisSpacing: isMobile ? 10 : 16,
                                childAspectRatio: isMobile ? 0.85 : (gridCrossCount >= 4 ? 1.6 : 1.7),
                              ),
                              children: [
                                StatCard(
                                  title: 'Total Invoiced',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Invoiced.',
                                  value: CurrencyFormatter.formatCurrency(totalAmount),
                                  icon: Icons.assignment_turned_in_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                                StatCard(
                                  title: tr('Received Inflow'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Received Inflow')}.",
                                  value: CurrencyFormatter.formatCurrency(receivedAmount),
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                ),
                                StatCard(
                                  title: tr('Pending Inflow'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Pending Inflow')}.",
                                  value: CurrencyFormatter.formatCurrency(pendingAmount),
                                  icon: Icons.hourglass_empty,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                                StatCard(
                                  title: 'Registry Count',
                                  tooltipMessage: 'Detailed statistics and information regarding Registry Count.',
                                  value: '$totalIncomes Receipts',
                                  icon: Icons.receipt_outlined,
                                  iconColor: Colors.purple,
                                  iconBgColor: context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Comprehensive Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: isMobile
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (val) {
                                              ref.read(incomeProvider.notifier).setSearchQuery(val);
                                              setState(() => _currentPage = 0);
                                            },
                                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: 'Search client, invoice...',
                                              hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                              prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                              suffixIcon: state.searchQuery.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.clear, size: 16),
                                                      color: context.textMuted,
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        ref.read(incomeProvider.notifier).setSearchQuery('');
                                                        setState(() => _currentPage = 0);
                                                      },
                                                    )
                                                  : null,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Stack(
                                        children: [
                                          InkWell(
                                            onTap: () => _showIncomeFilterBottomSheet(context),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                color: (state.clientFilter != 'All' || state.accountIdFilter != 'All' || state.statusFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                    ? context.primaryColor.withValues(alpha: 0.15)
                                                    : (context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: (state.clientFilter != 'All' || state.accountIdFilter != 'All' || state.statusFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                      ? context.primaryColor
                                                      : context.border,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.filter_list,
                                                size: 20,
                                                color: (state.clientFilter != 'All' || state.accountIdFilter != 'All' || state.statusFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                                    ? context.primaryColor
                                                    : context.textSecondary,
                                              ),
                                            ),
                                          ),
                                          if (state.clientFilter != 'All' || state.accountIdFilter != 'All' || state.statusFilter != 'All' || state.fromDateFilter != null || state.toDateFilter != null)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: context.primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // Search Field
                                        Container(
                                          width: 240,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (val) {
                                              ref.read(incomeProvider.notifier).setSearchQuery(val);
                                              setState(() => _currentPage = 0);
                                            },
                                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: 'Search client, invoice...',
                                              hintStyle: TextStyle(fontSize: 12, color: context.textMuted),
                                              prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                              suffixIcon: state.searchQuery.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.clear, size: 16),
                                                      color: context.textMuted,
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        ref.read(incomeProvider.notifier).setSearchQuery('');
                                                        setState(() => _currentPage = 0);
                                                      },
                                                    )
                                                  : null,
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Client Filter Dropdown
                                        Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: state.clientFilter,
                                              dropdownColor: context.cardBg,
                                              style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                              items: [
                                                const DropdownMenuItem(value: 'All', child: Text('Client: All')),
                                                ...clientsState.clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref.read(incomeProvider.notifier).setClientFilter(val);
                                                  setState(() => _currentPage = 0);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Deposit Account Filter Dropdown
                                        Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: state.accountIdFilter,
                                              dropdownColor: context.cardBg,
                                              style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                              items: [
                                                const DropdownMenuItem(value: 'All', child: Text('Account: All')),
                                                ...accountsState.accounts.map((acc) {
                                                  final scopeLabel = acc.accountScope.isNotEmpty ? ' (${acc.accountScope})' : '';
                                                  return DropdownMenuItem<String>(
                                                    value: acc.id,
                                                    child: Text('${acc.name}$scopeLabel'),
                                                  );
                                                }),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref.read(incomeProvider.notifier).setAccountIdFilter(val);
                                                  setState(() => _currentPage = 0);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Status Filter Dropdown
                                        Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.border, width: 1),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: state.statusFilter,
                                              dropdownColor: context.cardBg,
                                              style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                              items: const [
                                                DropdownMenuItem(value: 'All', child: Text('Status: All')),
                                                DropdownMenuItem(value: 'Received', child: Text('Received')),
                                                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  ref.read(incomeProvider.notifier).setStatusFilter(val);
                                                  setState(() => _currentPage = 0);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // From Date Button
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: state.fromDateFilter != null ? (DateTime.tryParse(state.fromDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2030),
                                            );
                                            if (picked != null) {
                                              final dateStr = picked.toIso8601String().substring(0, 10);
                                              ref.read(incomeProvider.notifier).setDateRange(dateStr, state.toDateFilter);
                                              setState(() => _currentPage = 0);
                                            }
                                          },
                                          icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.fromDateFilter != null ? context.primaryColor : context.textMuted),
                                          label: Text(
                                            state.fromDateFilter != null ? 'From: ${state.fromDateFilter}' : 'From Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: state.fromDateFilter != null ? context.primaryColor : context.textSecondary,
                                              fontWeight: state.fromDateFilter != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 40),
                                            side: BorderSide(color: state.fromDateFilter != null ? context.primaryColor : context.border),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            backgroundColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // To Date Button
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: state.toDateFilter != null ? (DateTime.tryParse(state.toDateFilter!) ?? DateTime.now()) : DateTime.now(),
                                              firstDate: DateTime(2020),
                                              lastDate: DateTime(2030),
                                            );
                                            if (picked != null) {
                                              final dateStr = picked.toIso8601String().substring(0, 10);
                                              ref.read(incomeProvider.notifier).setDateRange(state.fromDateFilter, dateStr);
                                              setState(() => _currentPage = 0);
                                            }
                                          },
                                          icon: Icon(Icons.calendar_today_outlined, size: 14, color: state.toDateFilter != null ? context.primaryColor : context.textMuted),
                                          label: Text(
                                            state.toDateFilter != null ? 'To: ${state.toDateFilter}' : 'To Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: state.toDateFilter != null ? context.primaryColor : context.textSecondary,
                                              fontWeight: state.toDateFilter != null ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 40),
                                            side: BorderSide(color: state.toDateFilter != null ? context.primaryColor : context.border),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            backgroundColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                          ),
                                        ),

                                        // Clear Filters Button
                                        if (state.clientFilter != 'All' || state.accountIdFilter != 'All' || state.statusFilter != 'All' || state.searchQuery.isNotEmpty || state.fromDateFilter != null || state.toDateFilter != null) ...[
                                          const SizedBox(width: 12),
                                          TextButton.icon(
                                            onPressed: () {
                                              _searchController.clear();
                                              ref.read(incomeProvider.notifier).clearFilters();
                                              setState(() => _currentPage = 0);
                                            },
                                            icon: Icon(Icons.filter_alt_off_outlined, size: 16, color: context.error),
                                            label: Text(
                                              'Clear Filters',
                                              style: TextStyle(color: context.error, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Income Table
                        filteredIncomes.isEmpty
                            ? _buildEmptyState(context)
                            : Container(
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Column(
                                    children: [
                                      Scrollbar(
                                        controller: _horizontalScrollController,
                                        child: SingleChildScrollView(
                                          controller: _horizontalScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(minWidth: 1180),
                                            child: DataTable(
                                              showCheckboxColumn: false,
                                              columnSpacing: 14,
                                              headingRowHeight: 48,
                                              dataRowMaxHeight: 58,
                                              headingRowColor: WidgetStateProperty.all(
                                                context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                              ),
                                              columns: const [
                                                DataColumn(label: SizedBox(width: 105, child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                 DataColumn(label: SizedBox(width: 160, child: Text('Client & Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 130, child: Text('Income Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 160, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 120, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 130, child: Text('Deposit Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 95, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
                                                DataColumn(label: SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: Text('Amount (PKR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))))),
                                              ],
                                              rows: paginatedIncomes.map((inc) {
                                                final account = accountsState.accounts.where((a) => a.id == inc.accountId).firstOrNull;
                                                final accountName = account?.name ?? 'Unknown Account';
                                                final accountScope = account?.accountScope ?? 'Company';
                                                final project = inc.projectId != null ? projectsState.projects.where((p) => p.id == inc.projectId).firstOrNull : null;
                                                final projectName = project?.name ?? '';
                                                final isReceived = inc.status.toLowerCase() == 'received';

                                                return DataRow(
                                                  onSelectChanged: (_) {
                                                    _showIncomeDetails(context, inc, accountName, accountScope, projectName);
                                                  },
                                                  cells: [
                                                    // 0. Invoice / ID (Unique)
                                                     DataCell(
                                                       SizedBox(
                                                         width: 105,
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
                                                               TransactionIdHelper.getIncomeId(inc, state.incomes),
                                                               style: TextStyle(
                                                                 color: context.textPrimary,
                                                                 fontSize: 11.5,
                                                                 fontWeight: FontWeight.bold,
                                                               ),
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),

                                                     // 1. Client & Project
                                                    DataCell(
                                                      SizedBox(
                                                        width: 160,
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              inc.clientName,
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              projectName.isNotEmpty ? projectName : 'Direct Payment',
                                                              style: TextStyle(fontSize: 11, color: context.textMuted),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // 2. Income Type & Installment
                                                    DataCell(
                                                      SizedBox(
                                                        width: 130,
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                color: inc.projectId != null ? context.primaryColor.withValues(alpha: 0.15) : context.infoLight,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                inc.incomeType,
                                                                style: TextStyle(
                                                                  fontSize: 10.5,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: inc.projectId != null ? context.primaryColor : context.info,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            if (inc.installmentType != null) ...[
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                '${inc.installmentType} Payment',
                                                                style: TextStyle(fontSize: 10, color: context.textMuted, fontWeight: FontWeight.w500),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // 3. Description
                                                     DataCell(
                                                       SizedBox(
                                                         width: 160,
                                                         child: Align(
                                                           alignment: Alignment.centerLeft,
                                                           child: Tooltip(
                                                             message: inc.description.isNotEmpty ? inc.description : 'No description',
                                                             waitDuration: const Duration(milliseconds: 250),
                                                             child: Text(
                                                               inc.description.isEmpty ? '—' : inc.description,
                                                               style: TextStyle(fontSize: 12, color: context.textPrimary),
                                                               maxLines: 1,
                                                               overflow: TextOverflow.ellipsis,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),

                                                     // 4. Date & Time
                                                    DataCell(
                                                      SizedBox(
                                                        width: 120,
                                                        child: Text(
                                                          _formatIncomeDateTime(inc.date),
                                                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),

                                                    // 5. Deposit Account
                                                    DataCell(
                                                      SizedBox(
                                                        width: 130,
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              accountName,
                                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              '$accountScope Account',
                                                              style: TextStyle(fontSize: 10, color: context.textMuted),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // 6. Status Pill
                                                    DataCell(
                                                      SizedBox(
                                                        width: 95,
                                                        child: Align(
                                                          alignment: Alignment.centerLeft,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isReceived ? context.successLight : context.warningLight,
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(
                                                                color: isReceived ? context.success.withValues(alpha: 0.3) : context.warning.withValues(alpha: 0.3),
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  isReceived ? Icons.check_circle_outline : Icons.hourglass_empty,
                                                                  size: 12,
                                                                  color: isReceived ? context.success : context.warning,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  inc.status,
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: isReceived ? context.success : context.warning,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // 7. Amount
                                                    DataCell(
                                                      SizedBox(
                                                        width: 110,
                                                        child: Align(
                                                          alignment: Alignment.centerRight,
                                                          child: Text(
                                                            'Rs. ${inc.amount.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w800,
                                                              color: context.success,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Pagination Bar
                                      if (filteredIncomes.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            border: Border(top: BorderSide(color: context.border)),
                                          ),
                                          child: isMobile
                                              ? Column(
                                                  children: [
                                                    Text(
                                                      'Showing ${filteredIncomes.isEmpty ? 0 : validPage * _itemsPerPage + 1}–${(validPage * _itemsPerPage + paginatedIncomes.length).clamp(0, filteredIncomes.length)} of ${filteredIncomes.length} entries',
                                                      style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.chevron_left, size: 20),
                                                          onPressed: validPage > 0
                                                              ? () => setState(() => _currentPage = validPage - 1)
                                                              : null,
                                                        ),
                                                        Text(
                                                          '${validPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                                                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.chevron_right, size: 20),
                                                          onPressed: validPage < totalPages - 1
                                                              ? () => setState(() => _currentPage = validPage + 1)
                                                              : null,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Showing ${filteredIncomes.isEmpty ? 0 : validPage * _itemsPerPage + 1}–${(validPage * _itemsPerPage + paginatedIncomes.length).clamp(0, filteredIncomes.length)} of ${filteredIncomes.length} entries',
                                                      style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                                    ),
                                                    Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.chevron_left, size: 20),
                                                          onPressed: validPage > 0
                                                              ? () => setState(() => _currentPage = validPage - 1)
                                                              : null,
                                                        ),
                                                        Text(
                                                          '${validPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
                                                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.chevron_right, size: 20),
                                                          onPressed: validPage < totalPages - 1
                                                              ? () => setState(() => _currentPage = validPage + 1)
                                                              : null,
                                                        ),
                                                      ],
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
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Incomes Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a new client invoice/revenue entry to start tracking.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeDetailsDialog extends ConsumerWidget {
  final IncomeRecord income;
  final String accountName;
  final String accountScope;
  final String projectName;
  final String formattedDateTime;

  const _IncomeDetailsDialog({
    required this.income,
    required this.accountName,
    required this.accountScope,
    required this.projectName,
    required this.formattedDateTime,
  });

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value, Widget? trailing, bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        value,
                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          label,
                          style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final incomes = ref.watch(incomeProvider).incomes;
    final displayInvoiceId = TransactionIdHelper.getIncomeId(income, incomes);
    final canDelete = adminState.hasPermission(AppModule.income, PermissionAction.delete);
    final isReceived = income.status.toLowerCase() == 'received';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isReceived ? context.successLight : context.warningLight,
                        child: Icon(
                          isReceived ? Icons.receipt_long_outlined : Icons.hourglass_bottom,
                          size: 18,
                          color: isReceived ? context.success : context.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income Receipt Details',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Invoice #: $displayInvoiceId',
                            style: TextStyle(color: context.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isReceived ? context.successLight : context.warningLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReceived ? context.success.withValues(alpha: 0.3) : context.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isReceived ? context.success : context.warning,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${income.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isReceived ? context.success : context.warning,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isReceived ? context.success : context.warning,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        income.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Detail List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(context, isMobile: isMobile, icon: Icons.person_outline, label: 'Client Name', value: income.clientName.isNotEmpty ? income.clientName : 'Direct Income (No Client)'),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.category_outlined,
                      label: 'Income Type',
                      value: income.installmentType != null
                          ? '${income.incomeType} (${income.installmentType} Payment)'
                          : income.incomeType,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.folder_open_outlined,
                      label: 'Project',
                      value: projectName.isNotEmpty ? projectName : 'Direct Payment (No Project)',
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.tag,
                      label: 'Invoice #',
                      value: displayInvoiceId,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.account_balance_outlined,
                      label: 'Deposit Account',
                      value: '$accountName ($accountScope)',
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.calendar_today_outlined,
                      label: 'Date & Time',
                      value: formattedDateTime,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      isMobile: isMobile,
                      icon: Icons.notes_outlined,
                      label: 'Description / Notes',
                      value: income.description.isNotEmpty ? income.description : 'No notes entered.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions (Close & Delete with RBAC)
              Row(
                children: [
                  if (canDelete) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(incomeProvider.notifier).deleteIncome(income.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Income receipt "${income.id}" deleted.'), backgroundColor: context.success),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: context.error),
                              );
                            }
                          }
                        },
                        icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                        label: Text('Delete', style: TextStyle(color: context.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordIncomeDialog extends ConsumerStatefulWidget {
  final IncomeRecord? initialRecord;
  const _RecordIncomeDialog({this.initialRecord});

  @override
  ConsumerState<_RecordIncomeDialog> createState() => _RecordIncomeDialogState();
}

class _RecordIncomeDialogState extends ConsumerState<_RecordIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _invoiceController;
  late final TextEditingController _descController;

  late String _selectedIncomeType;
  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedAccountId;
  String? _selectedProjectId;
  String? _selectedProjectName;
  String _selectedInstallmentType = 'Advance';
  late DateTime _date;
  bool _isSubmitting = false;

  static const List<String> _incomeTypes = [
    'Project Payment',
    'Consulting Services',
    'Maintenance & Support',
    'Commission / Referral',
    'Other Income',
  ];

  @override
  void initState() {
    super.initState();
    final rec = widget.initialRecord;
    _amountController = TextEditingController(text: rec != null ? rec.amount.toStringAsFixed(0) : '');
    _invoiceController = TextEditingController(text: rec?.invoiceNumber ?? '');
    _descController = TextEditingController(text: rec?.description ?? '');

    _selectedIncomeType = rec != null ? rec.incomeType : 'Project Payment';
    _selectedClientId = (rec?.clientId.isNotEmpty == true) ? rec!.clientId : null;
    _selectedClientName = (rec?.clientName.isNotEmpty == true) ? rec!.clientName : null;
    _selectedProjectId = (rec?.projectId?.isNotEmpty == true) ? rec!.projectId : null;
    _selectedProjectName = (rec?.projectName?.isNotEmpty == true) ? rec!.projectName : null;
    _selectedAccountId = rec?.accountId;
    _selectedInstallmentType = (rec?.installmentType != null) ? rec!.installmentType! : 'Advance';
    _date = (rec != null ? DateTime.tryParse(rec.date) : null) ?? DateTime.now();

    _amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Widget _buildBreakdownCard({
    required double total,
    required double received,
    required double newPay,
    required double remaining,
  }) {
      final isMobile = MediaQuery.of(context).size.width < 600;
      final isFullyPaid = remaining <= 0 && (received + newPay) > 0;
      final isOverpaid = remaining < 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFullyPaid
                ? context.success.withValues(alpha: 0.4)
                : (context.isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 17, color: context.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Project Payment Summary',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverpaid
                        ? context.errorLight
                        : (isFullyPaid ? context.successLight : context.warningLight),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOverpaid
                        ? 'Overpaid'
                        : (isFullyPaid ? 'Fully Paid' : 'Partially Paid'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOverpaid
                          ? context.error
                          : (isFullyPaid ? context.success : context.warning),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMobile)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildBreakdownItem(
                          title: 'Project Total',
                          amount: total,
                          color: context.textPrimary,
                          icon: Icons.business_center_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBreakdownItem(
                          title: 'Already Received',
                          amount: received,
                          color: context.info,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBreakdownItem(
                          title: 'New Payment',
                          amount: newPay,
                          color: context.primaryColor,
                          icon: Icons.add_card_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildBreakdownItem(
                          title: 'Remaining Payment',
                          amount: remaining.clamp(0.0, double.infinity),
                          color: remaining <= 0 ? context.success : Colors.orange,
                          icon: remaining <= 0 ? Icons.task_alt : Icons.hourglass_top,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildBreakdownItem(
                      title: 'Project Total',
                      amount: total,
                      color: context.textPrimary,
                      icon: Icons.business_center_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBreakdownItem(
                      title: 'Already Received',
                      amount: received,
                      color: context.info,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBreakdownItem(
                      title: 'New Payment',
                      amount: newPay,
                      color: context.primaryColor,
                      icon: Icons.add_card_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildBreakdownItem(
                      title: 'Remaining Payment',
                      amount: remaining.clamp(0.0, double.infinity),
                      color: remaining <= 0 ? context.success : Colors.orange,
                      icon: remaining <= 0 ? Icons.task_alt : Icons.hourglass_top,
                    ),
                  ),
                ],
              ),
          if (isOverpaid) ...[
            const SizedBox(height: 8),
            Text(
              'Notice: Amount exceeds project budget by Rs. ${NumberFormat('#,##0').format(-remaining)}',
              style: TextStyle(color: context.error, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ] else if (isFullyPaid) ...[
            const SizedBox(height: 8),
            Text(
              'Success: Project will be fully paid with this payment.',
              style: TextStyle(color: context.success, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: context.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Rs. ${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(BuildContext context, Widget child1, Widget child2) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 14),
        Expanded(child: child2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isEditing = widget.initialRecord != null;

    final clients = ref.watch(clientsProvider).clients.where((c) => c.status == 'Active').toList();
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
    final allProjects = ref.watch(projectsProvider).projects;
    final allIncomes = ref.watch(incomeProvider).incomes;
    final allExpenses = ref.watch(expensesProvider).expenses;
    final allLoans = ref.watch(loansProvider).loans;
    final allLedgers = ref.watch(ledgerProvider).entries;

    // Prioritize Company accounts over Personal accounts for business income
    final companyAccounts = accounts.where((a) => a.isCompany).toList();
    final personalAccounts = accounts.where((a) => a.isPersonal).toList();
    final orderedAccounts = [...companyAccounts, ...personalAccounts];

    // Set default account: prioritize company accounts
    if (_selectedAccountId == null) {
      if (companyAccounts.isNotEmpty) {
        _selectedAccountId = companyAccounts.first.id;
      } else if (accounts.isNotEmpty) {
        _selectedAccountId = accounts.first.id;
      }
    }

    final isProjectIncome = _selectedIncomeType == 'Project Payment';

    // Filter projects for client or show all active
    final availableProjects = _selectedClientId != null
        ? allProjects.where((p) => p.clientId == _selectedClientId).toList()
        : allProjects;

    // If client selected and project is not in client's project list, reset project
    if (_selectedProjectId != null && _selectedClientId != null) {
      final exists = availableProjects.any((p) => p.id == _selectedProjectId);
      if (!exists) {
        _selectedProjectId = null;
        _selectedProjectName = null;
      }
    }

    // Live calculation for project
    final selectedProj = allProjects.where((p) => p.id == _selectedProjectId).firstOrNull;
    double projectTotal = 0.0;
    double alreadyReceived = 0.0;
    final double newPayment = double.tryParse(_amountController.text.trim()) ?? 0.0;
    double remainingPayment = 0.0;

    if (selectedProj != null) {
      projectTotal = selectedProj.budget;
      final projectIncomes = allIncomes.where((i) => i.projectId == selectedProj.id && (!isEditing || i.id != widget.initialRecord!.id)).toList();
      alreadyReceived = projectIncomes.isNotEmpty
          ? projectIncomes.fold(0.0, (sum, i) => sum + i.amount)
          : (selectedProj.advancedPayment + selectedProj.partialPayments + selectedProj.finalPayment);
      remainingPayment = projectTotal - alreadyReceived - newPayment;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 580, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                isEditing ? Icons.edit_note : Icons.add_card,
                                size: 18,
                                color: context.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing ? 'Edit Income Record' : 'Record Business Income',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isEditing ? 'Modify receipt and recalculate balances' : 'Add revenue entry to accounts & ledgers',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Income Type Selector
                  _buildLabel('Income Type *'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('type_$_selectedIncomeType'),
                    initialValue: _selectedIncomeType,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration('Select Income Type'),
                    items: _incomeTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              t == 'Project Payment' ? Icons.folder_special_outlined : Icons.monetization_on_outlined,
                              size: 16,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(t),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedIncomeType = val;
                          if (val != 'Project Payment') {
                            _selectedProjectId = null;
                            _selectedProjectName = null;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Client & Project Row
                  _buildFormRow(
                    context,
                    // Client Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(isProjectIncome ? 'Customer / Client *' : 'Customer / Client (Optional)'),
                        DropdownButtonFormField<String?>(
                          key: ValueKey('client_$_selectedClientId'),
                          initialValue: _selectedClientId,
                          dropdownColor: context.cardBg,
                          isExpanded: true,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Select Client'),
                          validator: (val) {
                            if (isProjectIncome && (val == null || val.isEmpty)) {
                              return 'Client is required for Project Income';
                            }
                            return null;
                          },
                          items: [
                            if (!isProjectIncome)
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('— None (Direct Income) —', style: TextStyle(fontStyle: FontStyle.italic)),
                              ),
                            ...clients.map((c) {
                              return DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedClientId = val;
                              if (val != null) {
                                final cl = clients.where((c) => c.id == val).firstOrNull;
                                _selectedClientName = cl?.name;
                              } else {
                                _selectedClientName = null;
                              }
                              _selectedProjectId = null;
                              _selectedProjectName = null;
                            });
                          },
                        ),
                      ],
                    ),
                    // Project Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(isProjectIncome ? 'Project *' : 'Project (Optional)'),
                        DropdownButtonFormField<String?>(
                          key: ValueKey('project_${_selectedClientId}_$_selectedProjectId'),
                          initialValue: _selectedProjectId,
                          dropdownColor: context.cardBg,
                          isExpanded: true,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Select Project'),
                          validator: (val) {
                            if (isProjectIncome && (val == null || val.isEmpty)) {
                              return 'Please select a project';
                            }
                            return null;
                          },
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('— No Project —', style: TextStyle(fontStyle: FontStyle.italic)),
                            ),
                            ...availableProjects.map((p) {
                              return DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text('${p.name} (Rs. ${NumberFormat('#,##0').format(p.budget)})', overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedProjectId = val;
                              if (val != null) {
                                final pr = allProjects.where((p) => p.id == val).firstOrNull;
                                _selectedProjectName = pr?.name;
                                if (_selectedClientId == null && pr != null) {
                                  _selectedClientId = pr.clientId;
                                  _selectedClientName = pr.clientName;
                                }
                                // Auto-pick installment type if new entry
                                if (!isEditing && pr != null) {
                                  final prIncs = allIncomes.where((i) => i.projectId == pr.id).toList();
                                  final recvd = prIncs.isNotEmpty
                                      ? prIncs.fold(0.0, (s, i) => s + i.amount)
                                      : (pr.advancedPayment + pr.partialPayments + pr.finalPayment);
                                  if (recvd == 0) {
                                    _selectedInstallmentType = 'Advance';
                                  } else if (recvd + newPayment >= pr.budget) {
                                    _selectedInstallmentType = 'Final';
                                  } else {
                                    _selectedInstallmentType = 'Partial';
                                  }
                                }
                              } else {
                                _selectedProjectName = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // LIVE CALCULATION CARD (When project is selected)
                  if (selectedProj != null)
                    _buildBreakdownCard(
                      total: projectTotal,
                      received: alreadyReceived,
                      newPay: newPayment,
                      remaining: remainingPayment,
                    ),

                  // If project is selected, show Installment Type
                  if (selectedProj != null) ...[
                    _buildLabel('Payment Milestone / Installment Type'),
                    DropdownButtonFormField<String>(
                      key: ValueKey('installment_$_selectedInstallmentType'),
                      initialValue: _selectedInstallmentType,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Installment Type'),
                      items: const [
                        DropdownMenuItem(value: 'Advance', child: Text('Advance Payment')),
                        DropdownMenuItem(value: 'Partial', child: Text('Partial Payment / Milestone')),
                        DropdownMenuItem(value: 'Final', child: Text('Final / Full Payment')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedInstallmentType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amount & Invoice Number Row
                  _buildFormRow(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Amount Received (PKR) *'),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                          decoration: _buildInputDecoration('e.g. 20000'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter payment amount';
                            final num = double.tryParse(val.trim());
                            if (num == null || num <= 0) return 'Invalid amount (> 0)';
                            return null;
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Reference / Invoice No.'),
                        TextFormField(
                          controller: _invoiceController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: _buildInputDecoration('e.g. INV-2026-004'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deposit Account (REQUIRED) & Date Row
                  _buildFormRow(
                    context,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Received In Account (REQUIRED) *'),
                        DropdownButtonFormField<String>(
                          key: ValueKey('account_$_selectedAccountId'),
                          isExpanded: true,
                          initialValue: _selectedAccountId,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Select Account'),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Deposit account is required';
                            return null;
                          },
                          items: orderedAccounts.map((a) {
                            final isCompany = a.isCompany;
                            final scopeLabel = isCompany ? 'Company' : 'Personal';
                            final subLabel = a.bankName.isNotEmpty ? a.bankName : a.type;
                            final realBal = calculateAuthoritativeAccountBalance(
                              account: a,
                              incomes: allIncomes,
                              expenses: allExpenses,
                              loans: allLoans,
                              ledgerEntries: allLedgers,
                            );
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.name} ($scopeLabel • $subLabel) • Bal: Rs. ${NumberFormat('#,##0').format(realBal)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => _selectedAccountId = val);
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date Received *'),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() => _date = picked);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(_date),
                                style: TextStyle(color: context.textPrimary, fontSize: 13),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes / Description
                  _buildLabel('Notes / Description'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('Enter notes, milestone description or details...'),
                  ),
                  const SizedBox(height: 24),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                      ),
                      Builder(
                        builder: (context) {
                          final canCreate = ref.watch(adminProvider).hasPermission(AppModule.income, PermissionAction.create);
                          final canEdit = ref.watch(adminProvider).hasPermission(AppModule.income, PermissionAction.edit);
                          final hasPerm = isEditing ? canEdit : canCreate;
                          if (!hasPerm) return const SizedBox.shrink();
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () async {
                                        if (_formKey.currentState?.validate() == true) {
                                          setState(() => _isSubmitting = true);
                                          try {
                                            final recordId = widget.initialRecord?.id ?? 'inc_${DateTime.now().millisecondsSinceEpoch}';
                                            final pPaymentType = isProjectIncome
                                                ? _selectedInstallmentType
                                                : _selectedIncomeType;

                                            final income = IncomeRecord(
                                              id: recordId,
                                              date: _date.toIso8601String().substring(0, 10),
                                              clientId: _selectedClientId ?? '',
                                              clientName: _selectedClientName ?? (_selectedClientId != null ? 'Client' : 'Direct Income'),
                                              amount: double.parse(_amountController.text.trim()).abs(),
                                              accountId: _selectedAccountId!,
                                              invoiceNumber: _invoiceController.text.trim(),
                                              description: _descController.text.trim().isNotEmpty
                                                  ? _descController.text.trim()
                                                  : (selectedProj != null ? '${selectedProj.name} Payment' : _selectedIncomeType),
                                              status: 'Received',
                                              projectId: _selectedProjectId,
                                              projectName: _selectedProjectName,
                                              projectPaymentType: pPaymentType,
                                            );

                                            if (widget.initialRecord == null) {
                                              await ref.read(incomeProvider.notifier).addIncome(income);
                                            } else {
                                              await ref.read(incomeProvider.notifier).updateIncome(widget.initialRecord!, income);
                                            }

                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(isEditing
                                                      ? 'Income record updated successfully.'
                                                      : 'Income payment of Rs. ${NumberFormat('#,##0').format(income.amount)} recorded successfully.'),
                                                  backgroundColor: context.success,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              setState(() => _isSubmitting = false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: context.error,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        isEditing ? 'Update Income' : tr('Record Inflow'),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}