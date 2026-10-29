import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/navigation_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/theme/theme_provider.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';

import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/widgets/app_logo.dart';
import 'sync_options_dialog.dart';

class CollapsibleSidebar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final bool isDrawer;

  const CollapsibleSidebar({
    super.key,
    required this.navigationShell,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = isDrawer ? false : ref.watch(sidebarCollapsedProvider);
    final theme = Theme.of(context);
    final activeIndex = navigationShell.currentIndex;
    final tr = ref.watch(translationProvider);

    final adminState = ref.watch(adminProvider);

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
      _SidebarItem(9, 'Data Recovery', Icons.restore_from_trash_outlined, true),
    ];

    final canViewFinance = adminState.hasPermission(AppModule.finance, PermissionAction.view) ||
        adminState.hasPermission(AppModule.ledger, PermissionAction.view) ||
        adminState.hasPermission(AppModule.accounts, PermissionAction.view) ||
        adminState.hasPermission(AppModule.income, PermissionAction.view) ||
        adminState.hasPermission(AppModule.expenses, PermissionAction.view) ||
        adminState.hasPermission(AppModule.loans, PermissionAction.view) ||
        adminState.hasPermission(AppModule.personalAccounts, PermissionAction.view);

    final canViewHr = adminState.hasPermission(AppModule.hr, PermissionAction.view) ||
        adminState.hasPermission(AppModule.employees, PermissionAction.view) ||
        adminState.hasPermission(AppModule.attendance, PermissionAction.view) ||
        adminState.hasPermission(AppModule.payroll, PermissionAction.view) ||
        adminState.hasPermission(AppModule.advances, PermissionAction.view) ||
        adminState.hasPermission(AppModule.employeeHistory, PermissionAction.view);

    final canViewInventory = adminState.hasPermission(AppModule.inventory, PermissionAction.view) ||
        adminState.hasPermission(AppModule.officeInventory, PermissionAction.view) ||
        adminState.hasPermission(AppModule.assets, PermissionAction.view);

    final canViewProjects = adminState.hasPermission(AppModule.projects, PermissionAction.view) ||
        adminState.hasPermission(AppModule.projectsList, PermissionAction.view) ||
        adminState.hasPermission(AppModule.tasks, PermissionAction.view) ||
        adminState.hasPermission(AppModule.timesheets, PermissionAction.view);

    final canViewReports = adminState.hasPermission(AppModule.reports, PermissionAction.view) ||
        adminState.hasPermission(AppModule.generalReports, PermissionAction.view);

    final isSuper = adminState.currentUser != null &&
        (adminState.currentUser!.isSuperAdmin ||
            adminState.currentUser!.role.trim().toLowerCase() == 'super admin' ||
            adminState.currentUser!.role.trim().toLowerCase() == 'system admin');

    final canViewAdmin = isSuper ||
        adminState.hasPermission(AppModule.administration, PermissionAction.view) ||
        adminState.hasPermission(AppModule.auditLogs, PermissionAction.view) ||
        adminState.hasPermission(AppModule.databaseBackup, PermissionAction.view) ||
        adminState.hasPermission(AppModule.systemSettings, PermissionAction.view);

    final items = allItems.where((item) {
      switch (item.index) {
        case 0: // Dashboard
          return adminState.hasPermission(AppModule.dashboard, PermissionAction.view);
        case 1: // Finance & Accounts
          return canViewFinance;
        case 6: // Finance Reports
          return adminState.hasPermission(AppModule.financeReports, PermissionAction.view) ||
              canViewReports || canViewFinance;
        case 2: // Clients & Relations
          return adminState.hasPermission(AppModule.clients, PermissionAction.view);
        case 3: // Projects & Operations
          return canViewProjects;
        case 4: // HR & Employees
          return canViewHr;
        case 5: // Inventory & Assets
          return canViewInventory;
        case 7: // Reports & Analytics
          return canViewReports;
        case 8: // Administration
          return canViewAdmin;
        case 9: // Data Recovery
          return isSuper;
        default:
          return true;
      }
    }).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isDrawer
          ? (MediaQuery.of(context).size.width * 0.78).clamp(240, 300).toDouble()
          : (isCollapsed ? 76 : 260),
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
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.border, width: 1),
              ),
            ),
            child: isCollapsed
                ? Center(
                    child: Image.asset(
                      'assets/app_icon_foreground.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.hub, color: Color(0xFFFF6B00), size: 28),
                    ),
                  )
                : ClipRect(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppLogo(
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                        if (isDrawer)
                          IconButton(
                            icon: Icon(Icons.close, color: context.textSecondary),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
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
          
          // Universal Sync Button (Desktop & Mobile)
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Consumer(
              builder: (context, ref, _) {
                final syncState = ref.watch(cloudSyncStateProvider);
                final isSyncing = syncState.status == SyncStatus.syncing;
                
                final widget = InkWell(
                  onTap: isSyncing
                      ? null
                      : () => showCloudSyncOptions(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSyncing ? context.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        isSyncing 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor))
                          : Icon(Icons.sync, size: 20, color: context.textSecondary),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isSyncing ? tr('Syncing...') : tr('Sync Data'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isSyncing ? context.primaryColor : context.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );

                if (isCollapsed) {
                  return Tooltip(
                    message: isSyncing ? tr('Syncing...') : tr('Sync Data'),
                    child: widget,
                  );
                }
                return widget;
              },
            ),
          ),
          
          // Mobile Specific Actions (Theme)
          if (isDrawer) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Consumer(
                builder: (context, ref, _) {
                  final isDark = ref.watch(themeModeProvider).value == ThemeMode.dark;
                  return InkWell(
                    onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        children: [
                          Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20, color: context.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            isDark ? tr('Light Mode') : tr('Dark Mode'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Collapse / Expand Toggle Button (desktop only, hidden on mobile drawer)
          if (!isDrawer) ...[
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
          onTap: () {
            navigationShell.goBranch(item.index);
            if (isDrawer) Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(8),
          child: buttonContent,
        ),
      );
    }
 
    return InkWell(
      onTap: () {
        navigationShell.goBranch(item.index);
        if (isDrawer) Navigator.of(context).pop();
      },
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
