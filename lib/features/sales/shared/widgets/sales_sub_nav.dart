import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';

/// A sub-navigation bar for the Sales & Purchases module.
/// Place this at the top of every Sales/Purchases screen body.
class SalesSubNav extends ConsumerWidget {
  final String activeRoute; // e.g. '/sales/products'

  const SalesSubNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    final tabs = [
      _SalesTab(
        label: tr('Products & Services'),
        icon: Icons.inventory_2_outlined,
        route: '/sales/products',
      ),
      _SalesTab(
        label: tr('Sales Invoices'),
        icon: Icons.receipt_long_outlined,
        route: '/sales/list',
      ),
      _SalesTab(
        label: tr('Purchase Orders'),
        icon: Icons.shopping_cart_outlined,
        route: '/sales/purchases',
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
                debugPrint('SalesSubNav: Tapped tab ${tab.label} with route ${tab.route}');
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

class _SalesTab {
  final String label;
  final IconData icon;
  final String route;

  const _SalesTab({
    required this.label,
    required this.icon,
    required this.route,
  });
}
