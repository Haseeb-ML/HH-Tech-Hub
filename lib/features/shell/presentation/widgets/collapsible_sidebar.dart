import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/navigation_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';

class CollapsibleSidebar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const CollapsibleSidebar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);
    final theme = Theme.of(context);
    final activeIndex = navigationShell.currentIndex;
    final tr = ref.watch(translationProvider);

    final adminState = ref.watch(adminProvider);
    final userRole = adminState.currentUser?.role ?? 'System Admin';
    final activeRolePermissions = adminState.roles.firstWhere(
      (r) => r.roleName == userRole,
      orElse: () => adminState.roles.firstWhere((r) => r.roleName == 'System Admin'),
    ).permissions;

    bool hasPermission(String permission) {
      return activeRolePermissions[permission] ?? false;
    }

    final allItems = [
      _SidebarItem(0, 'Dashboard', Icons.dashboard_outlined, false),
      _SidebarItem(1, 'Finance & Accounts', Icons.account_balance_wallet_outlined, true),
      _SidebarItem(2, 'Clients & Relations', Icons.business_center_outlined, true),
      _SidebarItem(3, 'Projects & Operations', Icons.assignment_outlined, true),
      _SidebarItem(4, 'HR & Employees', Icons.people_outline, true),
      _SidebarItem(5, 'Inventory & Assets', Icons.inventory_2_outlined, true),
      _SidebarItem(6, 'Finance Reports', Icons.analytics_outlined, true),
      _SidebarItem(7, 'Reports & Analytics', Icons.bar_chart_outlined, true),
      _SidebarItem(8, 'Administration', Icons.security_outlined, true),
    ];

    final items = allItems.where((item) {
      switch (item.index) {
        case 1: // Finance & Accounts
        case 6: // Finance Reports
          return hasPermission('Manage Finance');
        case 3: // Projects & Operations
          return hasPermission('Manage Projects');
        case 4: // HR & Employees
          return hasPermission('Manage HR');
        case 8: // Administration
          return hasPermission('Configure System');
        default:
          return true; // Dashboard, Clients, Inventory, Reports visible to all
      }
    }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCollapsed ? 76 : 260,
      decoration: BoxDecoration(
        color: context.sidebarBg,
        border: Border(
          right: BorderSide(color: context.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.border, width: 1),
              ),
            ),
            child: isCollapsed
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.border),
                      ),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.6,
                          child: Image.asset(
                            'assets/logo.png',
                            width: 28,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: context.isDarkMode ? Border.all(color: context.border) : null,
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
          ),
          
          // Navigation Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = activeIndex == item.index;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: _buildSidebarButton(
                    context: context,
                    item: item,
                    isSelected: isSelected,
                    isCollapsed: isCollapsed,
                    tr: tr,
                  ),
                );
              },
            ),
          ),
          
          // Collapse / Expand Toggle Button
          const Divider(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Tooltip(
              message: isCollapsed ? tr('Expand Sidebar') : tr('Collapse Sidebar'),
              child: InkWell(
                onTap: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Icon(
                        isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                        size: 16,
                        color: context.textSecondary,
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('Collapse Sidebar'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildSidebarButton({
    required BuildContext context,
    required _SidebarItem item,
    required bool isSelected,
    required bool isCollapsed,
    required TranslationHelper tr,
  }) {
    final theme = Theme.of(context);
    final buttonContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? context.infoLight : Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: isSelected ? context.primaryColor : context.textSecondary,
            size: 20,
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tr(item.title),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? context.primaryColor : context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
 
          ],
        ],
      ),
    );
 
    if (isCollapsed) {
      return Tooltip(
        message: tr(item.title),
        child: InkWell(
          onTap: () => navigationShell.goBranch(item.index),
          borderRadius: BorderRadius.circular(8),
          child: buttonContent,
        ),
      );
    }
 
    return InkWell(
      onTap: () => navigationShell.goBranch(item.index),
      borderRadius: BorderRadius.circular(8),
      child: buttonContent,
    );
  }
}

class _SidebarItem {
  final int index;
  final String title;
  final IconData icon;
  final bool isFuturePlaceholder;

  _SidebarItem(this.index, this.title, this.icon, this.isFuturePlaceholder);
}
