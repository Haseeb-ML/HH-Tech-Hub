import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

/// A sub-navigation bar for the Administration module.
/// Place this at the top of every Administration screen body.
class AdminSubNav extends ConsumerWidget {
  final String activeRoute;

  const AdminSubNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    final adminState = ref.watch(adminProvider);
    final isSuperAdmin = adminState.currentUser?.isSuperAdmin == true ||
        adminState.currentUser?.role.trim().toLowerCase() == 'super admin';

    final tabs = [
      _AdminTab(
        label: tr('System Settings'),
        icon: Icons.settings_outlined,
        route: '/administration/settings',
      ),
      if (isSuperAdmin)
        _AdminTab(
          label: tr('Roles & Permissions'),
          icon: Icons.admin_panel_settings_outlined,
          route: '/administration/roles',
        ),
      _AdminTab(
        label: 'Database Backup',
        icon: Icons.backup_outlined,
        route: '/administration/backup',
      ),
      if (isSuperAdmin)
        _AdminTab(
          label: 'Audit Logs',
          icon: Icons.history_outlined,
          route: '/administration/audit_logs',
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
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isActive = activeRoute == tab.route;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  debugPrint('AdminSubNav: Tapped tab ${tab.label} with route ${tab.route}');
                  context.go(tab.route);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? context.primaryColor : Colors.transparent,
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
                        color: isActive ? context.primaryColor : context.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isActive ? context.primaryColor : context.textSecondary,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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

class _AdminTab {
  final String label;
  final IconData icon;
  final String route;

  const _AdminTab({
    required this.label,
    required this.icon,
    required this.route,
  });
}
