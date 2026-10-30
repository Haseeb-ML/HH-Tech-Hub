import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/accounts_provider.dart';
import '../../domain/entities/bank_account.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/projects/domain/entities/project.dart';
import '../../../expenses/presentation/providers/expenses_provider.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../../loans/presentation/providers/loans_provider.dart';
import '../../../loans/domain/entities/loan_record.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../../../../core/utils/export_helper.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SyncState>(cloudSyncStateProvider, (previous, next) {
      if ((next.status == SyncStatus.success || next.status == SyncStatus.offline) &&
          previous?.status == SyncStatus.syncing) {
        ref.invalidate(accountsProvider);
        ref.invalidate(ledgerProvider);
        ref.invalidate(incomeProvider);
        ref.invalidate(expensesProvider);
        ref.invalidate(loansProvider);
      }
    });
    final tr = ref.watch(translationProvider);
    final state = ref.watch(accountsProvider);
    final adminState = ref.watch(adminProvider);
    final canCreateAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.create);
    final theme = Theme.of(context);

    // Watch related providers for accurate balance calculation
    final incomes = ref.watch(incomeProvider).incomes;
    final expenses = ref.watch(expensesProvider).expenses;
    final loans = ref.watch(loansProvider).loans;
    final ledgerEntries = ref.watch(ledgerProvider).entries;

    // Calculate metrics (Company Accounts only)
    final companyAccounts = state.accounts.where((a) => a.isCompany).toList();
    final totalAccounts = companyAccounts.length;
    
    final totalBalance = companyAccounts.fold<double>(
      0.0,
      (sum, acc) => sum + calculateAuthoritativeAccountBalance(
        account: acc,
        incomes: incomes,
        expenses: expenses,
        loans: loans,
        ledgerEntries: ledgerEntries,
      ),
    );
    final bankAccountsCount = companyAccounts.where((acc) => acc.type == 'Bank').length;
    final cashAccountsCount = companyAccounts.where((acc) => acc.type == 'Cash').length;

    final width = MediaQuery.of(context).size.width;
    final isMob = width < 600;
    int crossAxisCount = isMob ? 1 : (width >= 1200 ? 3 : 2);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const FinanceSubNav(activeRoute: '/finance/accounts'),
          Expanded(
            child: (state.isLoading && state.accounts.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(width < 600 ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMob = constraints.maxWidth < 600;
                            final titleCol = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Accounts',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage cash, bank deposits, and mobile wallets.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );
                            final actionsRow = ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<BankAccount>(
                                  context: context,
                                  builder: (context) => const AddEditAccountDialog(
                                    defaultScope: 'Company',
                                    isScopeFixed: true,
                                  ),
                                );
                                if (result != null) {
                                  ref.read(accountsProvider.notifier).addAccount(result);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${tr("Account")} "${result.name}" ${tr("added successfully.")}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            );
                            if (isMob) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleCol,
                                  if (canCreateAccount) ...[
                                    const SizedBox(height: 12),
                                    actionsRow,
                                  ],
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                titleCol,
                                if (canCreateAccount) actionsRow,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 600;
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 4 : 2;
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: isMobile ? 10 : 16,
                                mainAxisSpacing: isMobile ? 10 : 16,
                                childAspectRatio: gridCrossCount >= 4 ? 1.6 : (isMobile ? 0.85 : 1.7),
                              ),
                              children: [
                                StatCard(
                                  title: 'Total Balance',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Balance.',
                                  value: CurrencyFormatter.formatAccountingBalance(totalBalance),
                                  icon: Icons.account_balance_wallet_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                                StatCard(
                                  title: 'Total Accounts',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Accounts.',
                                  value: '$totalAccounts',
                                  icon: Icons.wallet_outlined,
                                  iconColor: Colors.teal,
                                  iconBgColor: context.isDarkMode ? Colors.teal.withValues(alpha: 0.2) : const Color(0xFFE6F4EA),
                                ),
                                StatCard(
                                  title: 'Bank Accounts',
                                  tooltipMessage: 'Detailed statistics and information regarding Bank Accounts.',
                                  value: '$bankAccountsCount',
                                  icon: Icons.account_balance_outlined,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                                StatCard(
                                  title: 'Cash / Wallets',
                                  tooltipMessage: 'Detailed statistics and information regarding Cash / Wallets.',
                                  value: '$cashAccountsCount',
                                  icon: Icons.phone_android_outlined,
                                  iconColor: Colors.purple,
                                  iconBgColor: context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar (Single row with animated auto-expanding search & filter icon on right)
                        const GlassCard(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: _AccountsSearchAndFilterBar(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Accounts Grid (Company Accounts Only)
                        (() {
                          final displayedAccounts = state.filteredAccounts
                              .where((a) => a.isCompany)
                              .toList();
                          return displayedAccounts.isEmpty
                              ? _buildEmptyState(context)
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: isMob ? 10 : 16,
                                    mainAxisSpacing: isMob ? 10 : 16,
                                    childAspectRatio: isMob ? 1.55 : 1.5,
                                  ),
                                  itemCount: displayedAccounts.length,
                                  itemBuilder: (context, index) {
                                    final account = displayedAccounts[index];
                                    return _AccountCard(account: account);
                                  },
                                );
                        })(),
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
            Icon(Icons.account_balance_wallet_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Accounts Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting filters or add a new account.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsSearchAndFilterBar extends ConsumerStatefulWidget {
  const _AccountsSearchAndFilterBar();

  @override
  ConsumerState<_AccountsSearchAndFilterBar> createState() =>
      _AccountsSearchAndFilterBarState();
}

class _AccountsSearchAndFilterBarState
    extends ConsumerState<_AccountsSearchAndFilterBar> {
  final FocusNode _searchFocusNode = FocusNode();
  late final TextEditingController _searchController;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(accountsProvider).searchQuery;
    _searchController = TextEditingController(text: initialQuery);
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context, String currentFilter) {
    final tr = ref.read(translationProvider);
    final state = ref.read(accountsProvider);
    final theme = Theme.of(context);

    final bankCount = state.accounts
        .where((a) => a.isCompany && a.type == 'Bank')
        .length;
    final cashCount = state.accounts
        .where((a) => a.isCompany && a.type == 'Cash')
        .length;
    final walletCount = state.accounts
        .where((a) => a.isCompany && a.type == 'Wallet')
        .length;
    final allCount =
        state.accounts.where((a) => a.isCompany).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final activeType = ref.watch(accountsProvider).typeFilter;

            Widget buildFilterOption({
              required String typeValue,
              required String label,
              required IconData icon,
              required Color color,
              required int count,
            }) {
              final isSelected = activeType == typeValue;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(accountsProvider.notifier).setTypeFilter(typeValue);
                    Navigator.pop(sheetContext);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : (context.isDarkMode
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : context.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count ${count == 1 ? "account" : "accounts"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: color, size: 20)
                        else
                          Icon(Icons.circle_outlined,
                              color: context.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    context.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.tune_rounded,
                                  size: 20, color: context.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter by Type',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Select account category',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (activeType != 'All')
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(accountsProvider.notifier)
                                  .setTypeFilter('All');
                              Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.refresh, size: 14),
                            label: const Text('Reset',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: context.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    buildFilterOption(
                      typeValue: 'All',
                      label: tr('All Accounts'),
                      icon: Icons.apps_rounded,
                      color: context.primaryColor,
                      count: allCount,
                    ),
                    buildFilterOption(
                      typeValue: 'Bank',
                      label: tr('Bank Accounts'),
                      icon: Icons.account_balance_outlined,
                      color: Colors.blue,
                      count: bankCount,
                    ),
                    buildFilterOption(
                      typeValue: 'Cash',
                      label: tr('Cash Accounts'),
                      icon: Icons.wallet_outlined,
                      color: Colors.teal,
                      count: cashCount,
                    ),
                    buildFilterOption(
                      typeValue: 'Wallet',
                      label: tr('Digital Wallets'),
                      icon: Icons.phone_android_outlined,
                      color: Colors.purple,
                      count: walletCount,
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
    final state = ref.watch(accountsProvider);
    final isFilterActive = state.typeFilter != 'All';

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final isMobile = totalWidth < 600;

        if (!isMobile) {
          final searchWidget = Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(accountsProvider.notifier).setSearchQuery(val),
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: tr('Search by account name or bank...'),
                hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
                prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          );

          final typeWidget = Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.border, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.typeFilter,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                items: ['All', tr('Cash'), 'Bank', 'Wallet'].map((t) {
                  return DropdownMenuItem<String>(
                    value: t,
                    child: Text('${tr("Type")}: $t'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(accountsProvider.notifier).setTypeFilter(val);
                  }
                },
              ),
            ),
          );

          return Row(
            children: [
              Expanded(child: searchWidget),
              const SizedBox(width: 16),
              typeWidget,
            ],
          );
        }

        // Mobile layout: auto-expanding search bar + filter icon on right
        final double searchBarWidth = _isFocused ? totalWidth - 52 : totalWidth * 0.64;
        final double filterButtonWidth = _isFocused ? 44 : totalWidth - searchBarWidth - 8;

        return Row(
          children: [
            // Auto-expanding search bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: searchBarWidth,
              height: 42,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF111827)
                    : context.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isFocused ? context.primaryColor : context.border,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: context.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) =>
                    ref.read(accountsProvider.notifier).setSearchQuery(val),
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _isFocused
                      ? tr('Search by account name or bank...')
                      : (isMobile
                          ? tr('Search accounts...')
                          : tr('Search by account name or bank...')),
                  hintStyle: TextStyle(fontSize: 12.5, color: context.textMuted),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color:
                        _isFocused ? context.primaryColor : context.textMuted,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(accountsProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Filter button on the right with icon and field
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: filterButtonWidth,
              height: 42,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      _showFilterBottomSheet(context, state.typeFilter),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (_isFocused && isMobile) ? 0 : 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isFilterActive
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : (context.isDarkMode
                              ? const Color(0xFF111827)
                              : context.scaffoldBg),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFilterActive
                            ? context.primaryColor
                            : context.border,
                        width: isFilterActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: isFilterActive
                                  ? context.primaryColor
                                  : context.textSecondary,
                            ),
                            if (!(_isFocused && isMobile)) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  state.typeFilter == 'All'
                                      ? tr('Type')
                                      : state.typeFilter,
                                  style: TextStyle(
                                    color: isFilterActive
                                        ? context.primaryColor
                                        : context.textPrimary,
                                    fontSize: 12,
                                    fontWeight: isFilterActive
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 16,
                                color: isFilterActive
                                    ? context.primaryColor
                                    : context.textSecondary,
                              ),
                            ],
                          ],
                        ),
                        if (isFilterActive && (_isFocused && isMobile))
                          Positioned(
                            top: 6,
                            right: 8,
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
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final BankAccount account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final canEditAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.edit);
    final canDeleteAccount = adminState.hasPermission(AppModule.accounts, PermissionAction.delete);
    final theme = Theme.of(context);
    final isMob = MediaQuery.of(context).size.width < 600;

    IconData typeIcon;
    Color typeColor;
    if (account.type == 'Bank') {
      typeIcon = Icons.account_balance_outlined;
      typeColor = context.primaryColor;
    } else if (account.type == 'Wallet') {
      typeIcon = Icons.phone_android_outlined;
      typeColor = Colors.purple;
    } else {
      typeIcon = Icons.wallet_outlined;
      typeColor = context.success;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/finance/accounts/details/${account.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMob ? 14 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMob ? 7 : 8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 18, color: typeColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                            fontSize: isMob ? 14 : 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (account.type != 'Cash') ...[
                          const SizedBox(height: 2),
                          Text(
                            '${account.bankName} • ${account.accountNumber}',
                            style: TextStyle(color: context.textSecondary, fontSize: isMob ? 9.5 : 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                    color: context.cardBg,
                    padding: EdgeInsets.zero,
                    onSelected: (val) async {
                      if (val == 'details') {
                        context.push('/finance/accounts/details/${account.id}');
                      } else if (val == 'delete' && canDeleteAccount) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: Text('${tr("Are you sure you want to delete account")} "${account.name}"? ${tr("This action cannot be undone.")}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(tr('Delete'), style: TextStyle(color: context.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(accountsProvider.notifier).deleteAccount(account.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${tr("Account")} "${account.name}" ${tr("deleted.")}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: context.error,
                            ),
                          );
                        }
                      } else if (val == 'edit' && canEditAccount) {
                        final result = await showDialog<BankAccount>(
                          context: context,
                          builder: (context) => AddEditAccountDialog(
                            account: account,
                            defaultScope: account.accountScope,
                            isScopeFixed: true,
                          ),
                        );
                        if (result != null) {
                          await ref.read(accountsProvider.notifier).updateAccount(result);
                        }
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 'details',
                          child: Text('View Details', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                        ),
                        if (canEditAccount)
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(tr('Edit Details'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                          ),
                        if (canDeleteAccount)
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Account', style: TextStyle(color: context.error, fontSize: 13)),
                          ),
                      ];
                    },
                  ),
                ],
              ),
              SizedBox(height: isMob ? 8 : 16),
              const Divider(height: 1),
              SizedBox(height: isMob ? 6 : 12),

              (() {
                final incomes = ref.watch(incomeProvider).incomes;
                final expenses = ref.watch(expensesProvider).expenses;
                final loans = ref.watch(loansProvider).loans;
                final ledgerEntries = ref.watch(ledgerProvider).entries;

                // Inflows
                final incomeInflow = incomes
                    .where((inc) => inc.accountId == account.id)
                    .fold<double>(0.0, (sum, inc) => sum + inc.amount);

                final isPersonalAcc = account.accountScope == 'Personal';
                final companyLoans = loans.where((l) =>
                    (l.accountId == account.id || l.resolvedAccountId == account.id)).toList();
                final personalLoans = isPersonalAcc
                    ? loans.where((l) => l.personalAccountId == account.id).toList()
                    : <LoanRecord>[];

                final borrowedLoans = companyLoans.where((l) => l.type == 'Borrowed').toList();
                final loanBorrowedInflow = borrowedLoans.fold<double>(0.0, (sum, l) => sum + l.amount)
                    + personalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount)
                    + personalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

                final lentRepaymentsInflow = companyLoans
                    .where((l) => l.type == 'Lent')
                    .expand((l) => l.repayments)
                    .where((r) => r.accountId == account.id)
                    .fold<double>(0.0, (sum, r) => sum + r.amount);

                final totalInflow = incomeInflow + loanBorrowedInflow + lentRepaymentsInflow;
                final transferInflow = ledgerEntries
                  .where((entry) => entry.accountId == account.id &&
                      (entry.category == 'Account Transfer' ||
                       entry.category == 'Company Deposit' ||
                       entry.category == 'Personal Deposit' ||
                       entry.category == 'Balance Settlement') &&
                      entry.type == 'Debit')
                  .fold<double>(0.0, (sum, entry) => sum + entry.amount);

                // Outflows
                final expenseOutflow = expenses
                    .where((exp) => exp.accountId == account.id)
                    .fold<double>(0.0, (sum, exp) => sum + exp.amount);

                final lentLoans = companyLoans.where((l) => l.type == 'Lent').toList();
                final loanLentOutflow = lentLoans.fold<double>(0.0, (sum, l) => sum + l.amount)
                    + personalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount)
                    + personalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);

                final borrowedRepaymentsOutflow = companyLoans
                    .where((l) => l.type == 'Borrowed')
                    .expand((l) => l.repayments)
                    .where((r) => r.accountId == account.id)
                    .fold<double>(0.0, (sum, r) => sum + r.amount);

                final totalOutflow = expenseOutflow + loanLentOutflow + borrowedRepaymentsOutflow;
                final transferOutflow = ledgerEntries
                  .where((entry) => entry.accountId == account.id &&
                      (entry.category == 'Account Transfer' ||
                       entry.category == 'Other Expense' ||
                       entry.category == 'Salary Advance' ||
                       entry.category == 'Balance Settlement') &&
                      entry.type == 'Credit')
                  .fold<double>(0.0, (sum, entry) => sum + entry.amount);

                final currentBalance = calculateAuthoritativeAccountBalance(
                  account: account,
                  incomes: incomes,
                  expenses: expenses,
                  loans: loans,
                  ledgerEntries: ledgerEntries,
                );
                final activeBorrowedCount = borrowedLoans.where((l) => l.status == 'Active').length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeBorrowedCount > 0) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.warning.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake_outlined, size: 11, color: context.warning),
                            const SizedBox(width: 4),
                            Text(
                              '$activeBorrowedCount Active Borrowed ${activeBorrowedCount == 1 ? "Loan" : "Loans"}',
                              style: TextStyle(color: context.warning, fontSize: isMob ? 9 : 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Inflow',
                          style: TextStyle(color: context.textMuted, fontSize: isMob ? 10.5 : 10, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs. ${(totalInflow + transferInflow).toStringAsFixed(0)}',
                          style: TextStyle(color: context.success, fontSize: isMob ? 11.5 : 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: isMob ? 3 : 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expenses / Outflow',
                          style: TextStyle(color: context.textMuted, fontSize: isMob ? 10.5 : 10, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rs. ${(totalOutflow + transferOutflow).toStringAsFixed(0)}',
                          style: TextStyle(color: context.error, fontSize: isMob ? 11.5 : 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: isMob ? 5 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Balance',
                          style: TextStyle(color: context.textMuted, fontSize: isMob ? 11 : 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.formatAccountingBalance(currentBalance),
                          style: TextStyle(
                            color: currentBalance >= 0 ? context.success : context.error,
                            fontSize: isMob ? 14 : 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              })(),
            ],
          ),
        ),
      ),
    );
  }
}

class AddEditAccountDialog extends ConsumerStatefulWidget {
  final BankAccount? account;
  final String defaultScope;
  final bool isScopeFixed;

  const AddEditAccountDialog({
    super.key,
    this.account,
    this.defaultScope = 'Company',
    this.isScopeFixed = false,
  });

  @override
  ConsumerState<AddEditAccountDialog> createState() => AddEditAccountDialogState();
}

class AddEditAccountDialogState extends ConsumerState<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bankController;
  late final TextEditingController _numberController;
  late final TextEditingController _balanceController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _ownerNameController;

  String _type = 'Bank';
  String _status = 'Active';
  late String _accountScope;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankController = TextEditingController(text: widget.account?.bankName ?? '');
    _numberController = TextEditingController(text: widget.account?.accountNumber ?? '');
    _balanceController = TextEditingController(
      text: widget.account != null ? widget.account!.balance.toStringAsFixed(0) : '0',
    );
    _openingBalanceController = TextEditingController(
      text: widget.account != null
          ? (widget.account!.openingBalance > 0
              ? widget.account!.openingBalance.toStringAsFixed(0)
              : (widget.account!.balance > 0 ? widget.account!.balance.toStringAsFixed(0) : '0'))
          : '0',
    );
    _ownerNameController = TextEditingController(text: widget.account?.ownerName ?? '');

    if (widget.account != null) {
      _type = widget.account!.type;
      _status = widget.account!.status;
      _accountScope = widget.account!.accountScope;
    } else {
      _accountScope = widget.defaultScope;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _numberController.dispose();
    _balanceController.dispose();
    _openingBalanceController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 550;

    final bankNameField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Bank/Provider Name (optional)'),
        TextFormField(
          controller: _bankController,
          style: TextStyle(color: context.textPrimary),
          decoration: _buildInputDecoration('e.g. Meezan Bank'),
        ),
      ],
    );

    final accountNoField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Account / Mobile No. (optional)'),
        TextFormField(
          controller: _numberController,
          style: TextStyle(color: context.textPrimary),
          decoration: _buildInputDecoration('e.g. 0230100982'),
        ),
      ],
    );

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.account == null
                            ? (_accountScope == 'Personal' ? 'Add Personal Account' : 'Add Financial Account')
                            : (_accountScope == 'Personal' ? 'Edit Personal Account' : 'Edit Account Details'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                const Divider(),
                const SizedBox(height: 16),

                // Account Name
                _buildLabel('Account Label / Name'),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('e.g. HBL Payroll A/C or Cash Vault'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter account label' : null,
                ),
                const SizedBox(height: 16),

                // Owner Name (if Personal Account)
                if (_accountScope == 'Personal') ...[
                  _buildLabel('Account Owner Name (optional)'),
                  TextFormField(
                    controller: _ownerNameController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('e.g. Ali Khan'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Type Select (Only for Company accounts)
                if (_accountScope != 'Personal') ...[
                  _buildLabel('Account Type'),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _type,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration('Select Type'),
                    items: [tr('Cash'), 'Bank', 'Wallet'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _type = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Account Scope Select
                if (!widget.isScopeFixed) ...[
                  _buildLabel('Account Scope'),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _accountScope,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration('Scope'),
                    items: ['Company', 'Personal'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _accountScope = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Bank Details (If not Cash)
                if (_type != 'Cash' || _accountScope == 'Personal') ...[
                  if (isMobile) ...[
                    bankNameField,
                    const SizedBox(height: 16),
                    accountNoField,
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: bankNameField),
                        const SizedBox(width: 16),
                        Expanded(child: accountNoField),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],

                // Opening Balance
                _buildLabel('Opening Balance'),
                TextFormField(
                  controller: _openingBalanceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('e.g. 10000'),
                  validator: (val) {
                    if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Actions Row
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() == true) {
                            final isPersonalScope = _accountScope.toLowerCase() == 'personal';
                            final openingBal = double.tryParse(_openingBalanceController.text.trim().isEmpty ? "0" : _openingBalanceController.text) ?? 0.0;
                            final double calculatedBalance;
                            if (widget.account == null) {
                              calculatedBalance = openingBal;
                            } else if (widget.account!.balance == widget.account!.openingBalance ||
                                (widget.account!.openingBalance == 0.0 && widget.account!.balance == 0.0)) {
                              calculatedBalance = openingBal;
                            } else {
                              final diff = openingBal - widget.account!.openingBalance;
                              calculatedBalance = widget.account!.balance + diff;
                            }
                            final prefix = isPersonalScope ? 'acc_personal_' : 'acc_company_';
                            final acc = BankAccount(
                              id: widget.account?.id ?? '$prefix${DateTime.now().millisecondsSinceEpoch}',
                              name: _nameController.text.trim(),
                              type: _type,
                              accountNumber: _type == 'Cash' ? '' : _numberController.text.trim(),
                              bankName: _type == 'Cash' ? '' : _bankController.text.trim(),
                              balance: calculatedBalance,
                              openingBalance: openingBal,
                              openingBalanceDate: widget.account == null || openingBal != widget.account!.openingBalance
                                ? DateTime.now().toIso8601String()
                                : widget.account!.openingBalanceDate,
                              accountScope: isPersonalScope ? 'Personal' : 'Company',
                              ownerName: isPersonalScope
                                  ? (_ownerNameController.text.trim().isNotEmpty
                                      ? _ownerNameController.text.trim()
                                      : _nameController.text.trim())
                                  : '',
                              status: _status,
                            );
                            Navigator.of(context).pop(acc);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(widget.account == null ? (_accountScope == 'Personal' ? 'Create Personal Account' : 'Create Account') : tr('Save Changes')),
                      ),
                    ],
                  ),
                ),
              ],
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

// -----------------------------------------------------------------------------
// REDESIGNED ACCOUNT DETAILS DIALOG (CLEAN & EXACT MATCH)
// -----------------------------------------------------------------------------

class AccountDetailsDialog extends ConsumerStatefulWidget {
  final BankAccount account;
  final List<Project> accountProjects;
  final double totalInflow;
  final double totalOutflow;
  final double netRemaining;
  final int totalInflowTransactionsCount;
  final int totalOutflowTransactionsCount;

  const AccountDetailsDialog({
    super.key,
    required this.account,
    this.accountProjects = const [],
    this.totalInflow = 0.0,
    this.totalOutflow = 0.0,
    this.netRemaining = 0.0,
    this.totalInflowTransactionsCount = 0,
    this.totalOutflowTransactionsCount = 0,
  });

  @override
  ConsumerState<AccountDetailsDialog> createState() => _AccountDetailsDialogState();
}

class _AccountDetailsDialogState extends ConsumerState<AccountDetailsDialog> {
  int _selectedTab = 0; // 0: Loans & Liabilities, 1: Projects

  @override
  Widget build(BuildContext context) {
    // Watch providers to make the dialog real-time reactive
    final accounts = ref.watch(accountsProvider).accounts;
    final currentAccount = accounts.firstWhere((a) => a.id == widget.account.id, orElse: () => widget.account);

    final incomes = ref.watch(incomeProvider).incomes.where((i) => i.accountId == currentAccount.id).toList();
    final expenses = ref.watch(expensesProvider).expenses.where((e) => e.accountId == currentAccount.id).toList();
    final allLoans = ref.watch(loansProvider).loans;
    final accountTransferEntries = ref.watch(ledgerProvider).entries.where((entry) =>
      entry.accountId == currentAccount.id &&
      (entry.category == 'Account Transfer' ||
       entry.category == 'Personal Deposit' ||
       entry.category == 'Other Expense' ||
       entry.category == 'Balance Settlement')).toList();
    final allProjects = ref.watch(projectsProvider).projects;
    
    final isPersonal = currentAccount.accountScope == 'Personal';

    // Connected loans (borrowed into this account or lent from this account)
    final accountLoans = allLoans.where((l) =>
        (l.accountId == currentAccount.id || l.resolvedAccountId == currentAccount.id || (isPersonal && l.personalAccountId == currentAccount.id))
    ).toList();
    final companyAccountLoans = allLoans.where((l) =>
        (l.accountId == currentAccount.id || l.resolvedAccountId == currentAccount.id)
    ).toList();
    final personalLoans = isPersonal
        ? allLoans.where((l) => l.personalAccountId == currentAccount.id && !l.description.contains('[AutoExpense]')).toList()
        : <LoanRecord>[];

    final borrowedLoans = isPersonal
        ? personalLoans.where((l) => l.type == 'Lent').toList()
        : companyAccountLoans.where((l) => l.type == 'Borrowed').toList();
    final lentLoans = isPersonal
        ? personalLoans.where((l) => l.type == 'Borrowed').toList()
        : companyAccountLoans.where((l) => l.type == 'Lent').toList();

    // Inflows
    final incomeInflow = incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final borrowedLoanInflow = companyAccountLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount)
        + personalLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount)
        + personalLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);
    final lentRepaymentsInflow = companyAccountLoans
        .where((l) => l.type == 'Lent')
        .expand((l) => l.repayments)
        .where((r) => r.accountId == currentAccount.id)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
    final realTotalInflow = currentAccount.openingBalance + incomeInflow + borrowedLoanInflow + lentRepaymentsInflow;
    final transferInflow = accountTransferEntries
      .where((entry) => entry.type == 'Debit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

    // Outflows
    final expenseOutflow = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final lentLoanOutflow = companyAccountLoans.where((l) => l.type == 'Lent').fold<double>(0.0, (sum, l) => sum + l.amount)
        + personalLoans.where((l) => l.type == 'Borrowed').fold<double>(0.0, (sum, l) => sum + l.amount)
        + personalLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).fold<double>(0.0, (sum, r) => sum + r.amount);
    final borrowedRepaymentsOutflow = companyAccountLoans
        .where((l) => l.type == 'Borrowed')
        .expand((l) => l.repayments)
        .where((r) => r.accountId == currentAccount.id)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
    final realTotalOutflow = expenseOutflow + lentLoanOutflow + borrowedRepaymentsOutflow;
    final transferOutflow = accountTransferEntries
      .where((entry) => entry.type == 'Credit')
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

    // Real Authoritative Balance
    final realBalance = realTotalInflow + transferInflow - realTotalOutflow - transferOutflow;

    // Today's summary calculations
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final todayIncomeInflow = incomes.where((inc) => inc.date.startsWith(todayStr)).fold<double>(0.0, (sum, i) => sum + i.amount);
    final todayBorrowedInflow = borrowedLoans.where((l) => l.startDate.startsWith(todayStr)).fold<double>(0.0, (sum, l) => sum + l.amount);
    final todayLentRepayments = allLoans.where((l) => l.type == 'Lent').expand((l) => l.repayments).where((r) => r.accountId == currentAccount.id && r.date.startsWith(todayStr)).fold<double>(0.0, (sum, r) => sum + r.amount);
    final todayTotalInflow = todayIncomeInflow + todayBorrowedInflow + todayLentRepayments;
    final todayTransferInflow = accountTransferEntries
      .where((entry) => entry.type == 'Debit' && entry.date.startsWith(todayStr))
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);

    final todayExpenseOutflow = expenses.where((exp) => exp.date.startsWith(todayStr)).fold<double>(0.0, (sum, e) => sum + e.amount);
    final todayLentOutflow = lentLoans.where((l) => l.startDate.startsWith(todayStr)).fold<double>(0.0, (sum, l) => sum + l.amount);
    final todayBorrowedRepayments = allLoans.where((l) => l.type == 'Borrowed').expand((l) => l.repayments).where((r) => r.accountId == currentAccount.id && r.date.startsWith(todayStr)).fold<double>(0.0, (sum, r) => sum + r.amount);
    final todayTotalOutflow = todayExpenseOutflow + todayLentOutflow + todayBorrowedRepayments;
    final todayTransferOutflow = accountTransferEntries
      .where((entry) => entry.type == 'Credit' && entry.date.startsWith(todayStr))
      .fold<double>(0.0, (sum, entry) => sum + entry.amount);
    final adjustedTodayInflow = todayTotalInflow + todayTransferInflow;
    final adjustedTodayOutflow = todayTotalOutflow + todayTransferOutflow;
    final todayNet = adjustedTodayInflow - adjustedTodayOutflow;

    // Overall Project Payments summary across all projects
    final totalProjectsCount = allProjects.length;
    final totalBudget = allProjects.fold<double>(0.0, (sum, p) => sum + p.budget);
    final allIncomes = ref.watch(incomeProvider).incomes;
    final totalReceived = allProjects.fold<double>(0.0, (sum, p) {
      final pIncomes = allIncomes.where((i) => i.projectId == p.id).toList();
      return sum + (pIncomes.isNotEmpty
          ? pIncomes.fold<double>(0.0, (s, i) => s + i.amount)
          : (p.advancedPayment + p.partialPayments + p.finalPayment));
    });
    final totalDue = totalBudget - totalReceived;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 880,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 6),
          ],
        ),
        child: Column(
          children: [
            // ---------------- HEADER ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      currentAccount.type == 'Wallet' ? Icons.phone_android_outlined : (currentAccount.type == 'Cash' ? Icons.wallet_outlined : Icons.account_balance),
                      size: 28,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentAccount.name,
                          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentAccount.type == 'Cash' ? 'Cash Vault Account' : '${currentAccount.bankName} • ${currentAccount.accountNumber}',
                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.successLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Active Account',
                                style: TextStyle(color: context.success, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (borrowedLoans.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: context.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: context.warning.withValues(alpha: 0.3), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.handshake_outlined, size: 12, color: context.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${borrowedLoans.length} Borrowed ${borrowedLoans.length == 1 ? "Loan" : "Loans"} Active',
                                      style: TextStyle(color: context.warning, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: context.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- CURRENT BALANCE CARD ----------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.isDarkMode ? const Color(0xFF334155) : const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Available Balance',
                                style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CurrencyFormatter.formatAccountingBalance(realBalance),
                                style: TextStyle(
                                  color: realBalance < 0
                                      ? context.error
                                      : const Color(0xFF2563EB),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentAccount.openingBalance > 0
                                    ? 'Includes Rs. ${currentAccount.openingBalance.toStringAsFixed(0)} opening balance'
                                    : 'Official reconciled balance for this account',
                                style: TextStyle(color: context.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 48,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------------- TOTAL INFLOW & OUTFLOW BREAKDOWN ----------------
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? const Color(0xFF111827) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward, color: context.success, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Total Inflow (All Time)', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs. ${(realTotalInflow + transferInflow).toStringAsFixed(0)}',
                                  style: TextStyle(color: context.success, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentAccount.openingBalance > 0 ? "Opening: Rs. ${currentAccount.openingBalance.toStringAsFixed(0)} • " : ""}Income: Rs. ${incomeInflow.toStringAsFixed(0)} • Transfers: Rs. ${transferInflow.toStringAsFixed(0)} • Loans: Rs. ${borrowedLoanInflow.toStringAsFixed(0)}',
                                  style: TextStyle(color: context.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? const Color(0xFF111827) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: context.error, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Total Outflow (All Time)', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rs. ${(realTotalOutflow + transferOutflow).toStringAsFixed(0)}',
                                  style: TextStyle(color: context.error, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expenses: Rs. ${expenseOutflow.toStringAsFixed(0)} • Transfers: Rs. ${transferOutflow.toStringAsFixed(0)} • Loans: Rs. ${lentLoanOutflow.toStringAsFixed(0)}',
                                  style: TextStyle(color: context.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ---------------- TODAY CARD ----------------
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Activity',
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Today's Inflow
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: context.successLight, shape: BoxShape.circle),
                                      child: Icon(Icons.arrow_downward, color: context.success, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Today's Inflow", style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text('Rs. ${adjustedTodayInflow.toStringAsFixed(0)}', style: TextStyle(color: context.success, fontSize: 14, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 36, color: context.border),
                              
                              // Today's Outflow
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: context.errorLight, shape: BoxShape.circle),
                                        child: Icon(Icons.arrow_upward, color: context.error, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Today's Outflow", style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text('Rs. ${adjustedTodayOutflow.toStringAsFixed(0)}', style: TextStyle(color: context.error, fontSize: 14, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 36, color: context.border),

                              // Today's Net
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), shape: BoxShape.circle),
                                        child: const Icon(Icons.drag_handle, color: Colors.orange, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Today's Net", style: TextStyle(color: context.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text('Rs. ${todayNet.toStringAsFixed(0)}', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ---------------- TABS HEADER ----------------
                    Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _buildTabButton(0, 'Loans & Liabilities (${accountLoans.length})', Icons.handshake_outlined),
                          _buildTabButton(1, 'Project Payments ($totalProjectsCount)', Icons.folder_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------------- TAB 0: LOANS & LIABILITIES ----------------
                    if (_selectedTab == 0) ...[
                      // Loan stats row
                      Row(
                        children: [
                          _buildCleanStatCard(
                            context,
                            Icons.handshake_outlined,
                            'Total Borrowed',
                            'Rs. ${borrowedLoans.fold<double>(0.0, (s, l) => s + l.amount).toStringAsFixed(0)}',
                            '${borrowedLoans.length} borrowed credit lines',
                            Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildCleanStatCard(
                            context,
                            Icons.pending_actions,
                            'Remaining Debt',
                            'Rs. ${borrowedLoans.fold<double>(0.0, (s, l) => s + l.remainingBalance).toStringAsFixed(0)}',
                            'To be repaid to lenders',
                            context.error,
                          ),
                          const SizedBox(width: 12),
                          _buildCleanStatCard(
                            context,
                            Icons.call_made,
                            'Total Lent Out',
                            'Rs. ${lentLoans.fold<double>(0.0, (s, l) => s + l.amount).toStringAsFixed(0)}',
                            '${lentLoans.length} advances given',
                            context.primaryColor,
                          ),
                        ],
                      ),
                    ],

                    // ---------------- TAB 1: PROJECT PAYMENTS ----------------
                    if (_selectedTab == 1) ...[
                      Row(
                        children: [
                          _buildCleanStatCard(context, Icons.folder, 'Total Projects', totalProjectsCount.toString(), 'All software house projects', context.primaryColor),
                          const SizedBox(width: 12),
                          _buildCleanStatCard(context, Icons.receipt_long, 'Total Budget', 'Rs. ${totalBudget.toStringAsFixed(0)}', 'Total budget amount', Colors.purple),
                          const SizedBox(width: 12),
                          _buildCleanStatCard(context, Icons.monetization_on, 'Total Received', 'Rs. ${totalReceived.toStringAsFixed(0)}', 'Total revenue received', context.success),
                          const SizedBox(width: 12),
                          _buildCleanStatCard(context, Icons.error_outline, 'Total Due', 'Rs. ${totalDue.toStringAsFixed(0)}', 'Remaining to receive', Colors.orange),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? context.primaryColor : context.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? context.primaryColor : context.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanStatCard(BuildContext context, IconData icon, String title, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: context.textSecondary, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: context.textMuted, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showExportBankStatementDialog(BuildContext context, WidgetRef ref) async {
  final accountsList = ref.read(accountsProvider).accounts.where((a) => a.type == 'Bank' || a.type == 'Wallet').toList();
  
  if (accountsList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No bank or wallet accounts available.')));
    return;
  }

  BankAccount? selectedAccount = accountsList.first;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: context.cardBg,
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined, size: 36, color: context.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Export Account Statement',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Download a consolidated statement containing incomes, expenses, and advance payments for a specific bank or wallet account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BankAccount>(
                    initialValue: selectedAccount,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.primaryColor),
                      ),
                    ),
                    dropdownColor: context.cardBg,
                    items: accountsList.map((acc) => DropdownMenuItem(
                      value: acc,
                      child: Row(
                        children: [
                          Icon(
                            acc.type == 'Wallet' ? Icons.account_balance_wallet : Icons.account_balance,
                            size: 16,
                            color: acc.type == 'Wallet' ? Colors.green : context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${acc.name} - ${acc.bankName}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: acc.type == 'Wallet' ? Colors.green.withValues(alpha: 0.1) : context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              acc.type,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: acc.type == 'Wallet' ? Colors.green : context.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedAccount = val;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: context.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                          label: Text('Cancel', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedAccount == null) return;
                            Navigator.pop(ctx);
                            await _generateBankStatement(context, ref, selectedAccount!, isPdf: false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.table_chart_outlined, size: 18),
                          label: const Text('Excel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedAccount == null) return;
                            Navigator.pop(ctx);
                            await _generateBankStatement(context, ref, selectedAccount!, isPdf: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          label: const Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      );
    }
  );
}

DateTime _resolveTransactionDate(String id, String rawDate) {
  try {
    final match = RegExp(r'\d{12,14}').firstMatch(id);
    if (match != null) {
      final ms = int.tryParse(match.group(0)!);
      if (ms != null && ms > 0 && ms < 8640000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
  } catch (_) {}

  try {
    return DateTime.parse(rawDate);
  } catch (_) {
    final normalized = rawDate.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized) ?? DateTime.now();
  }
}

Future<void> _generateBankStatement(BuildContext context, WidgetRef ref, BankAccount account, {required bool isPdf}) async {
  // Show loading indicator
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Generating ${isPdf ? "PDF" : "Excel"} for ${account.name}...'), duration: const Duration(seconds: 1)),
  );

  // Get Incomes
  final incomes = ref.read(incomeProvider).incomes.where((i) => i.accountId == account.id).toList();
  // Get Expenses
  final expenses = ref.read(expensesProvider).expenses.where((e) => e.accountId == account.id).toList();
  // Get Loans
  final allLoans = ref.read(loansProvider).loans;

  // Create unified transaction list
  List<Map<String, dynamic>> transactions = [];
  double totalInflow = 0.0;
  double totalOutflow = 0.0;
  int totalIncomeTx = 0;
  int totalExpenseTx = 0;

  for (var inc in incomes) {
    try {
      String payType = inc.projectPaymentType ?? '';
      String descPrefix = payType.isNotEmpty ? '$payType Payment' : 'Income';
      String descStr = (inc.projectName?.isNotEmpty == true) ? '$descPrefix - ${inc.projectName}' : '$descPrefix - ${inc.description}';
      
      final resolvedDate = _resolveTransactionDate(inc.id, inc.date);
      transactions.add({
        'id': inc.id,
        'sortKey': inc.id,
        'date': resolvedDate,
        'desc': descStr,
        'type': 'Income',
        'ref': inc.clientName.isNotEmpty ? inc.clientName : '-',
        'inflow': inc.amount,
        'outflow': 0.0,
      });
      totalInflow += inc.amount;
      totalIncomeTx++;
    } catch (_) {}
  }

  for (var exp in expenses) {
    try {
      final resolvedDate = _resolveTransactionDate(exp.id, exp.date);
      transactions.add({
        'id': exp.id,
        'sortKey': exp.id,
        'date': resolvedDate,
        'desc': 'Expense - ${exp.category}',
        'type': 'Expense',
        'ref': exp.vendorName.isNotEmpty ? exp.vendorName : '-',
        'inflow': 0.0,
        'outflow': exp.amount,
      });
      totalOutflow += exp.amount;
      totalExpenseTx++;
    } catch (_) {}
  }

  // Add Borrowed Loans (Inflow)
  final accountBorrowedLoans = allLoans.where((l) => (l.accountId == account.id || l.resolvedAccountId == account.id) && l.type == 'Borrowed').toList();
  for (var loan in accountBorrowedLoans) {
    try {
      final resolvedDate = _resolveTransactionDate(loan.id, loan.startDate);
      transactions.add({
        'id': loan.id,
        'sortKey': loan.id,
        'date': resolvedDate,
        'desc': 'Loan Borrowed - ${loan.borrowerName}',
        'type': 'Loan Borrowed',
        'ref': loan.borrowerName,
        'inflow': loan.amount,
        'outflow': 0.0,
      });
      totalInflow += loan.amount;
      totalIncomeTx++;
    } catch (_) {}
  }

  // Add Lent Loans (Outflow)
  final accountLentLoans = allLoans.where((l) => (l.accountId == account.id || l.resolvedAccountId == account.id) && l.type == 'Lent').toList();
  for (var loan in accountLentLoans) {
    try {
      final resolvedDate = _resolveTransactionDate(loan.id, loan.startDate);
      transactions.add({
        'id': loan.id,
        'sortKey': loan.id,
        'date': resolvedDate,
        'desc': 'Loan Lent - ${loan.borrowerName}',
        'type': 'Loan Lent',
        'ref': loan.borrowerName,
        'inflow': 0.0,
        'outflow': loan.amount,
      });
      totalOutflow += loan.amount;
      totalExpenseTx++;
    } catch (_) {}
  }

  // Add Loan Repayments (Inflow or Outflow)
  for (var loan in allLoans) {
    for (var rep in loan.repayments) {
      if (rep.accountId == account.id) {
        try {
          final resolvedDate = _resolveTransactionDate(rep.id, rep.date);
          final isLent = loan.type == 'Lent';
          transactions.add({
            'id': rep.id,
            'sortKey': rep.id,
            'date': resolvedDate,
            'desc': isLent
                ? 'Loan Repayment Received - ${loan.borrowerName}'
                : 'Loan Repayment Paid - ${loan.borrowerName}',
            'type': isLent ? 'Loan Inflow' : 'Loan Outflow',
            'ref': loan.borrowerName,
            'inflow': isLent ? rep.amount : 0.0,
            'outflow': isLent ? 0.0 : rep.amount,
          });
          if (isLent) {
            totalInflow += rep.amount;
            totalIncomeTx++;
          } else {
            totalOutflow += rep.amount;
            totalExpenseTx++;
          }
        } catch (_) {}
      }
    }
  }

  // Add Direct Ledger Entries (Salary Advances, Deposits, Transfers, Other Expenses, Balance Settlement)
  final accountLedgers = ref.read(ledgerProvider).entries.where((l) =>
    l.accountId == account.id &&
    (l.category == 'Account Transfer' ||
     l.category == 'Personal Deposit' ||
     l.category == 'Company Deposit' ||
     l.category == 'Salary Advance' ||
     l.category == 'Other Expense' ||
     l.category == 'Balance Settlement')).toList();
  for (var entry in accountLedgers) {
    try {
      final isDebit = entry.type == 'Debit';
      final resolvedDate = _resolveTransactionDate(entry.id, entry.date);
      transactions.add({
        'id': entry.id,
        'sortKey': entry.id,
        'date': resolvedDate,
        'desc': entry.description.isNotEmpty ? entry.description : entry.category,
        'type': isDebit ? 'Direct Inflow' : 'Direct Outflow',
        'ref': entry.reference.isNotEmpty ? entry.reference : '-',
        'inflow': isDebit ? entry.amount : 0.0,
        'outflow': isDebit ? 0.0 : entry.amount,
      });
      if (isDebit) {
        totalInflow += entry.amount;
        totalIncomeTx++;
      } else {
        totalOutflow += entry.amount;
        totalExpenseTx++;
      }
    } catch (_) {}
  }

  // Sort by date descending (newest first)
  final sortedTransactions = ExportHelper.sortTransactionsNewestFirst(transactions);

  // Calculate overall balance mathematically
  double openingBalance = account.balance - totalInflow + totalOutflow;

  // Prepare Excel rows
  List<List<dynamic>> rows = [];
  final dateFormat = DateFormat('dd-MM-yyyy, HH:mm');

  for (int i = 0; i < sortedTransactions.length; i++) {
    final t = sortedTransactions[i];
    final inflow = (t['inflow'] as num?)?.toDouble() ?? 0.0;
    final outflow = (t['outflow'] as num?)?.toDouble() ?? 0.0;

    rows.add([
      (i + 1).toString(),
      dateFormat.format(t['date'] as DateTime),
      t['desc'],
      t['ref'],
      inflow > 0 ? inflow : '-',
      outflow > 0 ? outflow : '-',
    ]);
  }

  final headers = ['#', 'Date', 'Description', 'Reference', 'Inflow', 'Outflow'];
  final fileName = 'Bank_Statement_${account.name.replaceAll(" ", "_")}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
  
  try {
    String filePath = '';
    if (isPdf) {
      filePath = await ExportHelper.exportBankStatementPdf(
        account: account,
        transactions: sortedTransactions,
        openingBalance: openingBalance,
        totalInflow: totalInflow,
        totalOutflow: totalOutflow,
        closingBalance: account.balance,
        totalIncomeTx: totalIncomeTx,
        totalExpenseTx: totalExpenseTx,
      );
    } else {
      filePath = await ExportHelper.exportToExcel(
        fileName: fileName,
        headers: headers,
        rows: rows,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isPdf ? "PDF" : "Excel"} Exported: $filePath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => ExportHelper.openFile(filePath),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
