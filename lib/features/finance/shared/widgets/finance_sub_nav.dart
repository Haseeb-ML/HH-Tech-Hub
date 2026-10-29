import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

/// A sub-navigation bar for the Finance & Accounts module.
/// Automatically scrolls to ensure the active tab is visible and centered on mobile.
class FinanceSubNav extends ConsumerStatefulWidget {
  final String activeRoute; // e.g. '/finance/ledger'

  const FinanceSubNav({super.key, required this.activeRoute});

  @override
  ConsumerState<FinanceSubNav> createState() => _FinanceSubNavState();
}

class _FinanceSubNavState extends ConsumerState<FinanceSubNav> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
  }

  @override
  void didUpdateWidget(covariant FinanceSubNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRoute != widget.activeRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveTab();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTab() {
    if (!mounted) return;
    final tabContext = _activeTabKey.currentContext;
    if (tabContext != null) {
      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);

    final tabs = [
      if (adminState.hasPermission(AppModule.ledger, PermissionAction.view))
        _FinanceTab(
          label: tr('General Ledger'),
          icon: Icons.account_balance_outlined,
          route: '/finance/ledger',
        ),
      if (adminState.hasPermission(AppModule.accounts, PermissionAction.view))
        _FinanceTab(
          label: tr('Accounts'),
          icon: Icons.wallet_outlined,
          route: '/finance/accounts',
        ),
      if (adminState.hasPermission(AppModule.income, PermissionAction.view))
        _FinanceTab(
          label: tr('Income'),
          icon: Icons.trending_up_outlined,
          route: '/finance/income',
        ),
      if (adminState.hasPermission(AppModule.expenses, PermissionAction.view))
        _FinanceTab(
          label: tr('Expenses'),
          icon: Icons.trending_down_outlined,
          route: '/finance/expenses',
        ),
      if (adminState.hasPermission(AppModule.loans, PermissionAction.view))
        _FinanceTab(
          label: tr('Loans'),
          icon: Icons.handshake_outlined,
          route: '/finance/loans',
        ),
      if (adminState.hasPermission(AppModule.personalAccounts, PermissionAction.view))
        _FinanceTab(
          label: tr('Personal Account'),
          icon: Icons.person_outline,
          route: '/finance/wallet',
        ),
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 12, isMobile ? 12 : 24, 0),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isActive = widget.activeRoute == tab.route || widget.activeRoute.startsWith(tab.route);
            return Padding(
              key: isActive ? _activeTabKey : null,
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  debugPrint('FinanceSubNav: Tapped tab ${tab.label} with route ${tab.route}');
                  context.go(tab.route);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isActive ? context.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color: isActive
                            ? context.primaryColor
                            : context.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? context.primaryColor
                              : context.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FinanceTab {
  final String label;
  final IconData icon;
  final String route;

  const _FinanceTab({
    required this.label,
    required this.icon,
    required this.route,
  });
}
