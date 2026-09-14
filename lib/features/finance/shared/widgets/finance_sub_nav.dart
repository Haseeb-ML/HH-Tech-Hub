import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';

/// A sub-navigation bar for the Finance & Accounts module.
/// Place this at the top of every Ledger/Accounts/Income/Expenses/Loans screen body.
class FinanceSubNav extends ConsumerWidget {
  final String activeRoute; // e.g. '/finance/ledger'

  const FinanceSubNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    final tabs = [
      _FinanceTab(
        label: 'General Ledger',
        icon: Icons.account_balance_outlined,
        route: '/finance/ledger',
      ),
      _FinanceTab(
        label: 'Accounts',
        icon: Icons.wallet_outlined,
        route: '/finance/accounts',
      ),
      _FinanceTab(
        label: tr('Income'),
        icon: Icons.trending_up_outlined,
        route: '/finance/income',
      ),
      _FinanceTab(
        label: tr('Expenses'),
        icon: Icons.trending_down_outlined,
        route: '/finance/expenses',
      ),
      _FinanceTab(
        label: tr('Loans'),
        icon: Icons.handshake_outlined,
        route: '/finance/loans',
      ),
      _FinanceTab(
        label: 'Personal Account',
        icon: Icons.person_outline,
        route: '/finance/wallet',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeRoute == tab.route;
          return Padding(
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
