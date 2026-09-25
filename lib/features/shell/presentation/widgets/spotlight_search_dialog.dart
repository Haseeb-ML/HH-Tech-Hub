import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';

// Import providers
import 'package:software_house_erp/features/clients/clients/presentation/providers/clients_provider.dart';
import 'package:software_house_erp/features/hr/employees/presentation/providers/employees_provider.dart';
import 'package:software_house_erp/features/projects/projects/presentation/providers/projects_provider.dart';
import 'package:software_house_erp/features/projects/tasks/presentation/providers/tasks_provider.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/inventory/assets/presentation/providers/assets_provider.dart';
import 'package:software_house_erp/features/inventory/inventory/presentation/providers/inventory_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class SpotlightSearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
  final String category; // 'Navigation', 'Employees', 'Clients', 'Projects', 'Tasks'

  const SpotlightSearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.path,
    required this.category,
  });
}

class SpotlightSearchDialog extends ConsumerStatefulWidget {
  const SpotlightSearchDialog({super.key});

  @override
  ConsumerState<SpotlightSearchDialog> createState() => _SpotlightSearchDialogState();
}

class _SpotlightSearchDialogState extends ConsumerState<SpotlightSearchDialog> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      final double itemHeight = 64.0;
      final double viewportHeight = 300.0; // matching container height constraints
      final double targetOffset = index * itemHeight;

      final double currentOffset = _scrollController.offset;
      if (targetOffset < currentOffset) {
        _scrollController.animateTo(targetOffset, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
      } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(targetOffset - viewportHeight + itemHeight, duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
      }
    }
  }

  void _navigateTo(SpotlightSearchItem item) {
    Navigator.pop(context);
    context.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final isDark = context.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final adminState = ref.watch(adminProvider);
    final isSuperAdmin = adminState.currentUser?.isSuperAdmin == true ||
        adminState.currentUser?.role.trim().toLowerCase() == 'super admin';

    // Static Navigation Pages
    final staticNavItems = [
      SpotlightSearchItem(title: tr('Dashboard'), subtitle: tr('Here is a quick overview of Software House performance today.'), icon: Icons.dashboard_outlined, path: '/dashboard', category: 'Navigation'),
      SpotlightSearchItem(title: tr('General Ledger'), subtitle: tr('View corporate ledgers and general accounting entries'), icon: Icons.menu_book, path: '/finance/ledger', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Bank Accounts'), subtitle: tr('Configure corporate bank accounts and view balances'), icon: Icons.account_balance_outlined, path: '/finance/accounts', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Personal Wallet'), subtitle: tr('Manage owner personal bank accounts, cash reserves, and transfers'), icon: Icons.account_balance_wallet_outlined, path: '/finance/wallet', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Income Records'), subtitle: tr('Add client payment logs and track accounts receivable'), icon: Icons.trending_up, path: '/finance/income', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Expense Records'), subtitle: tr('Record company bills, payroll payments, and utility bills'), icon: Icons.trending_down, path: '/finance/expenses', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Loans & Credits'), subtitle: tr('Track loans, repayments, and liabilities'), icon: Icons.handshake_outlined, path: '/finance/loans', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Finance Summary & Reports'), subtitle: tr('View Profit & Loss, Balance Sheet, and Income vs Expenses summary'), icon: Icons.analytics_outlined, path: '/finance/reports', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Client Directory'), subtitle: tr('Manage business clients and point of contacts'), icon: Icons.business_center_outlined, path: '/clients/list', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Project Directory'), subtitle: tr('Track ongoing software projects and client deliverables'), icon: Icons.assignment_outlined, path: '/projects/list', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Task Board'), subtitle: tr('Create and assign software development backlogs'), icon: Icons.task_alt, path: '/projects/tasks', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Timesheets Log'), subtitle: tr('Log working hours and developer tasks timeline'), icon: Icons.access_time_outlined, path: '/projects/timesheets', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Employee Directory'), subtitle: tr('Manage company personnel and staff hierarchy'), icon: Icons.people_outline, path: '/hr/employees', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Attendance Log'), subtitle: tr('Daily check-in and check-out tracking'), icon: Icons.calendar_month, path: '/hr/attendance', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Salaries & Payroll'), subtitle: tr('Process employee payroll and generate slip reports'), icon: Icons.payments_outlined, path: '/hr/salaries', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Salary Advances'), subtitle: tr('Track employee salary advance requests and approvals'), icon: Icons.price_change_outlined, path: '/hr/advances', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Employee History'), subtitle: tr('Full employment timeline, salary progression, and dossier'), icon: Icons.badge_outlined, path: '/hr/history', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Inventory & Supplies'), subtitle: tr('Track office supplies levels and stock thresholds'), icon: Icons.inventory_2_outlined, path: '/inventory/list', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Assets Tracker'), subtitle: tr('Track developer laptops, gear, and office hardware'), icon: Icons.computer_outlined, path: '/inventory/assets', category: 'Navigation'),
      SpotlightSearchItem(title: tr('System Settings'), subtitle: tr('Theme, visual configurations, and retention policy'), icon: Icons.settings_outlined, path: '/administration/settings', category: 'Navigation'),
      SpotlightSearchItem(title: tr('Backup & Restore'), subtitle: tr('Export Supabase DB schema/records and SQLite states'), icon: Icons.backup_outlined, path: '/administration/backup', category: 'Navigation'),
      if (isSuperAdmin)
        SpotlightSearchItem(title: tr('Audit Trail Logs'), subtitle: tr('Review system activity trail and IP address headers'), icon: Icons.history_toggle_off_outlined, path: '/administration/audit_logs', category: 'Navigation'),
    ];

    // Dynamic states
    final employees = ref.watch(employeesProvider).employees;
    final clients = ref.watch(clientsProvider).clients;
    final projects = ref.watch(projectsProvider).projects;
    final tasks = ref.watch(tasksProvider).tasks;
    final accounts = ref.watch(accountsProvider).accounts;
    final assets = ref.watch(assetsProvider).assets;
    final inventory = ref.watch(inventoryProvider).items;

    final employeeSearchItems = employees.map((e) => SpotlightSearchItem(
          title: e.name,
          subtitle: '${e.designation} • ${e.department}',
          icon: Icons.person_outline,
          path: '/hr/employees',
          category: 'Employees',
        ));

    final clientSearchItems = clients.map((c) => SpotlightSearchItem(
          title: c.name,
          subtitle: '${c.contactPerson} • ${c.email}',
          icon: Icons.business_outlined,
          path: '/clients/list',
          category: 'Clients',
        ));

    final projectSearchItems = projects.map((p) => SpotlightSearchItem(
          title: p.name,
          subtitle: '${p.clientName} • Status: ${p.status}',
          icon: Icons.assignment_outlined,
          path: '/projects/list',
          category: 'Projects',
        ));

    final taskSearchItems = tasks.map((t) => SpotlightSearchItem(
          title: t.title,
          subtitle: 'Assignee: ${t.assigneeName} • Priority: ${t.priority}',
          icon: Icons.task_alt,
          path: '/projects/tasks',
          category: 'Tasks',
        ));

    final accountSearchItems = accounts.map((a) => SpotlightSearchItem(
          title: a.name,
          subtitle: '${a.type} • ${a.isPersonal ? "Personal" : "Corporate"} • Balance: Rs. ${a.balance.toStringAsFixed(0)}',
          icon: a.isPersonal ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined,
          path: a.isPersonal ? '/finance/wallet/details/${a.id}' : '/finance/accounts/details/${a.id}',
          category: 'Accounts',
        ));

    final assetSearchItems = assets.map((asset) => SpotlightSearchItem(
          title: asset.name,
          subtitle: '${asset.type} • S/N: ${asset.serialNumber} • ${asset.assignedToName != null && asset.assignedToName!.isNotEmpty ? "Assigned: ${asset.assignedToName}" : asset.status}',
          icon: Icons.computer_outlined,
          path: '/inventory/assets',
          category: 'Assets',
        ));

    final inventorySearchItems = inventory.map((item) => SpotlightSearchItem(
          title: item.name,
          subtitle: 'Stock: ${item.quantity} ${item.unit} • ${item.category}',
          icon: Icons.inventory_2_outlined,
          path: '/inventory/list',
          category: 'Inventory',
        ));

    // Combine all indexable items
    final allItems = [
      ...staticNavItems,
      ...employeeSearchItems,
      ...clientSearchItems,
      ...projectSearchItems,
      ...taskSearchItems,
      ...accountSearchItems,
      ...assetSearchItems,
      ...inventorySearchItems,
    ];

    // Fuzzy matching
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = allItems.where((item) {
      if (query.isEmpty) {
        return item.category == 'Navigation'; // Show pages by default when empty
      }
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    // Adjust selected index boundary in case list size shrank
    if (_selectedIndex >= filteredItems.length) {
      _selectedIndex = 0;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.only(
          top: isMobile ? 32 : 80,
          left: isMobile ? 12 : 24,
          right: isMobile ? 12 : 24,
          bottom: isMobile ? 16 : 24,
        ),
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  if (filteredItems.isNotEmpty) {
                    _selectedIndex = (_selectedIndex + 1) % filteredItems.length;
                    _scrollToIndex(_selectedIndex);
                  }
                });
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  if (filteredItems.isNotEmpty) {
                    _selectedIndex = (_selectedIndex - 1 + filteredItems.length) % filteredItems.length;
                    _scrollToIndex(_selectedIndex);
                  }
                });
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                if (filteredItems.isNotEmpty) {
                  _navigateTo(filteredItems[_selectedIndex]);
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            width: isMobile ? double.infinity : 650,
            constraints: const BoxConstraints(maxWidth: 650),
            decoration: BoxDecoration(
              color: context.cardBg.withValues(alpha: isDark ? 0.85 : 0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Search Input Area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 22, color: context.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: tr('Search ERP (e.g. Clients, Transactions)...'),
                            hintStyle: TextStyle(color: context.textMuted, fontSize: 14, fontWeight: FontWeight.normal),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (query.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: context.textMuted),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      // Keyboard shortcuts helpers
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: context.border),
                        ),
                        child: Text(
                          'ESC',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: context.border, height: 1),

                // Results Container
                Flexible(
                  child: filteredItems.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 36, color: context.textMuted),
                              const SizedBox(height: 8),
                              Text(
                                tr('No matching results found.'),
                                style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: filteredItems.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = index == _selectedIndex;

                            IconData categoryIcon = Icons.folder_open;
                            Color categoryColor = context.textSecondary;
                            Color categoryBg = context.scaffoldBg;
                            
                            switch (item.category) {
                              case 'Navigation':
                                categoryIcon = Icons.navigation;
                                categoryColor = context.info;
                                categoryBg = context.infoLight;
                                break;
                              case 'Employees':
                                categoryIcon = Icons.person;
                                categoryColor = Colors.teal;
                                categoryBg = isDark ? Colors.teal.withValues(alpha: 0.15) : const Color(0xFFE6FFFA);
                                break;
                              case 'Clients':
                                categoryIcon = Icons.business;
                                categoryColor = Colors.purple;
                                categoryBg = isDark ? Colors.purple.withValues(alpha: 0.15) : const Color(0xFFF3E8FF);
                                break;
                              case 'Projects':
                                categoryIcon = Icons.assignment;
                                categoryColor = context.warning;
                                categoryBg = context.warningLight;
                                break;
                              case 'Tasks':
                                categoryIcon = Icons.task_alt;
                                categoryColor = context.success;
                                categoryBg = context.successLight;
                                break;
                              case 'Accounts':
                                categoryIcon = Icons.account_balance;
                                categoryColor = const Color(0xFF6366F1);
                                categoryBg = isDark ? const Color(0xFF6366F1).withValues(alpha: 0.15) : const Color(0xFFEEF2FF);
                                break;
                              case 'Assets':
                                categoryIcon = Icons.devices;
                                categoryColor = const Color(0xFF0EA5E9);
                                categoryBg = isDark ? const Color(0xFF0EA5E9).withValues(alpha: 0.15) : const Color(0xFFE0F2FE);
                                break;
                              case 'Inventory':
                                categoryIcon = Icons.inventory_2;
                                categoryColor = const Color(0xFFF97316);
                                categoryBg = isDark ? const Color(0xFFF97316).withValues(alpha: 0.15) : const Color(0xFFFFEDD5);
                                break;
                            }

                            return InkWell(
                              onTap: () => _navigateTo(item),
                              onHover: (hovered) {
                                if (hovered) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: isSelected
                                    ? context.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    // Item Icon
                                    Icon(item.icon, size: 20, color: isSelected ? context.primaryColor : context.textSecondary),
                                    const SizedBox(width: 16),

                                    // Main Titles
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                              color: isSelected ? context.primaryColor : context.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: context.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Category Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(categoryIcon, size: 10, color: categoryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            tr(item.category),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: categoryColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (!isMobile) ...[
                  Divider(color: context.border, height: 1),

                  // Bottom Navigation Instructions Tip
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_arrow_down, size: 14, color: context.textMuted),
                        Icon(Icons.keyboard_arrow_up, size: 14, color: context.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          tr('Navigate with arrows'),
                          style: TextStyle(fontSize: 11, color: context.textMuted),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.keyboard_return, size: 12, color: context.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          tr('Enter to select'),
                          style: TextStyle(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
