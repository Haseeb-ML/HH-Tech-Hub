import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/widgets/access_denied_screen.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class AuditlogsScreen extends ConsumerStatefulWidget {
  const AuditlogsScreen({super.key});

  @override
  ConsumerState<AuditlogsScreen> createState() => _AuditlogsScreenState();
}

class _AuditlogsScreenState extends ConsumerState<AuditlogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 25;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(adminProvider).searchQuery;
    _searchController.text = currentQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickSingleDate(BuildContext context) async {
    final state = ref.read(adminProvider);
    final initial = state.startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Specific Day for Audit Logs',
    );
    if (picked != null) {
      ref.read(adminProvider.notifier).setDateFilter(start: picked, end: picked);
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final state = ref.read(adminProvider);
    final initialRange = (state.startDate != null && state.endDate != null)
        ? DateTimeRange(start: state.startDate!, end: state.endDate!)
        : DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Date Range for Audit Logs',
    );
    if (picked != null) {
      ref.read(adminProvider.notifier).setDateFilter(start: picked.start, end: picked.end);
    }
  }

  void _showDateFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date Filter Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.today, color: context.primaryColor),
                  title: Text('Single Day', style: TextStyle(color: context.textPrimary)),
                  subtitle: Text('Pick one specific day to see what happened', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickSingleDate(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.date_range, color: context.info),
                  title: Text('Date Range', style: TextStyle(color: context.textPrimary)),
                  subtitle: Text('Pick start date and end date', style: TextStyle(color: context.textMuted, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDateRange(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogDetailsDialog(BuildContext context, AuditLog log) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.cardBg,
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: context.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audit Log Details',
                  style: TextStyle(color: context.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: isMobile ? double.maxFinite : 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailTile(context, 'Log ID', log.id, Icons.tag),
                  _detailTile(context, 'Timestamp', log.timestamp, Icons.schedule),
                  _detailTile(context, 'User Account / Operator', log.user, Icons.person_outline),
                  _detailTile(context, 'Module Scope', log.module, Icons.layers_outlined),
                  _detailTile(context, 'IP Address', log.ipAddress, Icons.wifi),
                  const SizedBox(height: 12),
                  Text(
                    'Action Performed',
                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border),
                    ),
                    child: SelectableText(
                      log.action,
                      style: TextStyle(color: context.textPrimary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailTile(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textMuted),
          const SizedBox(width: 8),
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
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    // Super Admin Protection: Only Super Admin can view Audit Trail Logs
    final currentUser = state.currentUser;
    final isSuperAdmin = currentUser != null &&
        (currentUser.isSuperAdmin ||
            currentUser.role.trim().toLowerCase() == 'super admin' ||
            currentUser.role.trim().toLowerCase() == 'system admin');

    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Column(
          children: const [
            AdminSubNav(activeRoute: '/administration/audit_logs'),
            Expanded(
              child: AccessDeniedScreen(
                attemptedPath: '/administration/audit_logs',
              ),
            ),
          ],
        ),
      );
    }

    // Gather only assigned roles from actual existing users created by Admin
    final Set<String> distinctRoles = {};
    for (final u in state.users) {
      final role = u.role.trim();
      if (role.isNotEmpty) {
        distinctRoles.add(role);
      }
    }
    if (state.currentUser != null && state.currentUser!.role.trim().isNotEmpty) {
      distinctRoles.add(state.currentUser!.role.trim());
    }
    final sortedRoles = distinctRoles.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final activeRoleValue = (state.roleFilter == 'All' || sortedRoles.contains(state.roleFilter))
        ? state.roleFilter
        : 'All';

    // Calculate quick stats
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayCount = state.logs.where((l) => l.timestamp.startsWith(todayStr)).length;
    final uniqueActors = state.logs.map((l) => l.user.split('(').first.trim()).toSet().length;

    // Check if any filter is active
    final hasActiveFilter = state.searchQuery.isNotEmpty ||
        state.moduleFilter != 'All' ||
        state.roleFilter != 'All' ||
        state.actionTypeFilter != 'All' ||
        state.startDate != null ||
        state.endDate != null;

    int activeFilterCount = 0;
    if (state.searchQuery.isNotEmpty) activeFilterCount++;
    if (state.moduleFilter != 'All') activeFilterCount++;
    if (state.roleFilter != 'All') activeFilterCount++;
    if (state.actionTypeFilter != 'All') activeFilterCount++;
    if (state.startDate != null || state.endDate != null) activeFilterCount++;

    // Memoize filtered logs and pagination to keep UI at 60 FPS
    final filteredLogs = state.filteredLogs;
    final totalFiltered = filteredLogs.length;
    final totalPages = (totalFiltered / _pageSize).ceil().clamp(1, 9999);
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final paginatedLogs = filteredLogs.skip(startIndex).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/audit_logs'),

          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Subtitle, and Top Actions
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      final headerText = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Audit Trail Logs',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time compliance logs tracking user actions, employee operations, and records across all ERP modules.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );

                      final headerActions = Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Export Button for Audit Trail
                          ExportButton(
                            title: 'System Audit Trail Report',
                            fileName: 'audit_logs_$todayStr',
                            headers: const [
                              'Timestamp',
                              'User Account',
                              'Action Performed',
                              'Module Scope',
                              'IP Address'
                            ],
                            rows: filteredLogs.map((log) => [
                              log.timestamp,
                              log.user,
                              log.action,
                              log.module,
                              log.ipAddress,
                            ]).toList(),
                          ),
                          // Refresh button
                          IconButton.outlined(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Refresh Logs',
                            onPressed: () => ref.read(adminProvider.notifier).reloadData(),
                          ),
                        ],
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerText,
                            const SizedBox(height: 16),
                            headerActions,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: headerText),
                          const SizedBox(width: 16),
                          headerActions,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Stat Cards ──────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 800;
                      final cards = [
                        StatCard(
                          title: 'Total Logs Recorded',
                          value: state.logs.length.toString(),
                          icon: Icons.history,
                          iconColor: context.primaryColor,
                          iconBgColor: context.primaryColor.withValues(alpha: 0.1),
                          tooltipMessage: 'All-time audit logs saved in the database',
                        ),
                        StatCard(
                          title: 'Filtered Results',
                          value: totalFiltered.toString(),
                          icon: Icons.filter_alt_outlined,
                          iconColor: context.info,
                          iconBgColor: context.info.withValues(alpha: 0.1),
                          tooltipMessage: 'Logs matching your current filter criteria',
                        ),
                        StatCard(
                          title: "Today's Activities",
                          value: todayCount.toString(),
                          icon: Icons.today,
                          iconColor: context.success,
                          iconBgColor: context.success.withValues(alpha: 0.1),
                          tooltipMessage: 'Actions performed on the ERP today',
                        ),
                        StatCard(
                          title: 'Active Operators',
                          value: uniqueActors.toString(),
                          icon: Icons.people_outline,
                          iconColor: context.warning,
                          iconBgColor: context.warning.withValues(alpha: 0.1),
                          tooltipMessage: 'Number of unique staff and users logged',
                        ),
                      ];

                      if (isSmall) {
                        return Column(
                          children: cards.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c,
                          )).toList(),
                        );
                      }

                      return Row(
                        children: cards.map((c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: c,
                          ),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Comprehensive Filter Panel ─────────────────────────
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Header Row with Active Count & Clear Button
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune, size: 20, color: context.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Filters & Search',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (hasActiveFilter) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$activeFilterCount active',
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (hasActiveFilter)
                                TextButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(adminProvider.notifier).clearAuditFilters();
                                  },
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: const Text('Reset All Filters', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: context.error,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Row 1: Search, Module, User/Employee, Role Dropdowns
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 900;

                              // 1. Search Bar
                              final searchField = TextField(
                                controller: _searchController,
                                onChanged: (val) => ref.read(adminProvider.notifier).setSearchQuery(val),
                                style: TextStyle(color: context.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: tr('Search action, user, keyword, or IP...'),
                                  hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                                  prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(adminProvider.notifier).setSearchQuery('');
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  filled: true,
                                  fillColor: context.scaffoldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                ),
                              );

                              // 2. Module Scope Dropdown
                              final moduleDropdown = DropdownButtonFormField<String>(
                                value: state.moduleFilter,
                                dropdownColor: context.cardBg,
                                isExpanded: true,
                                style: TextStyle(color: context.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: tr('Module Scope'),
                                  labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: context.scaffoldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'All', child: Text('All Modules', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'HR', child: Text('HR & Attendance', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Finance', child: Text('Finance & Accounts', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Projects', child: Text('Projects & Tasks', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Inventory', child: Text('Inventory & Assets', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Sales', child: Text('Sales & Purchases', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Clients', child: Text('Clients Directory', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Administration', child: Text('Administration', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Security', child: Text('Security & Logins', overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(adminProvider.notifier).setModuleFilter(val);
                                  }
                                },
                              );

                              // 3. Role Dropdown (Showing only assigned roles from existing users)
                              final roleDropdown = DropdownButtonFormField<String>(
                                value: activeRoleValue,
                                dropdownColor: context.cardBg,
                                isExpanded: true,
                                style: TextStyle(color: context.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'User Role',
                                  labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: context.scaffoldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'All', child: Text('All Assigned Roles', overflow: TextOverflow.ellipsis)),
                                  ...sortedRoles.map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r, overflow: TextOverflow.ellipsis),
                                  )),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(adminProvider.notifier).setRoleFilter(val);
                                  }
                                },
                              );

                              final isMobile = constraints.maxWidth < 600;

                              if (isMobile) {
                                return Column(
                                  children: [
                                    searchField,
                                    const SizedBox(height: 12),
                                    moduleDropdown,
                                    const SizedBox(height: 12),
                                    roleDropdown,
                                  ],
                                );
                              }

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    searchField,
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: moduleDropdown),
                                        const SizedBox(width: 12),
                                        Expanded(child: roleDropdown),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(flex: 3, child: searchField),
                                  const SizedBox(width: 14),
                                  Expanded(flex: 2, child: moduleDropdown),
                                  const SizedBox(width: 14),
                                  Expanded(flex: 2, child: roleDropdown),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Row 2: Date Selector Button + Quick Date Chips + Action Type Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Date Picker Action Button
                              InkWell(
                                onTap: () => _showDateFilterOptions(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: (state.startDate != null || state.endDate != null)
                                        ? context.primaryColor.withValues(alpha: 0.12)
                                        : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: (state.startDate != null || state.endDate != null)
                                          ? context.primaryColor
                                          : context.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        size: 16,
                                        color: (state.startDate != null || state.endDate != null)
                                            ? context.primaryColor
                                            : context.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        state.startDate == null && state.endDate == null
                                            ? 'Select Date / Range'
                                            : (state.startDate != null &&
                                                    state.endDate != null &&
                                                    state.startDate!.year == state.endDate!.year &&
                                                    state.startDate!.month == state.endDate!.month &&
                                                    state.startDate!.day == state.endDate!.day)
                                                ? _formatDate(state.startDate!)
                                                : '${state.startDate != null ? _formatDate(state.startDate!) : ''} → ${state.endDate != null ? _formatDate(state.endDate!) : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: (state.startDate != null || state.endDate != null)
                                              ? context.primaryColor
                                              : context.textPrimary,
                                        ),
                                      ),
                                      if (state.startDate != null || state.endDate != null) ...[
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () => ref.read(adminProvider.notifier).setDateFilter(start: null, end: null),
                                          child: Icon(Icons.close, size: 14, color: context.primaryColor),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 4),

                              // Quick Date Chips
                              _quickDateChip(
                                context,
                                label: 'All Dates',
                                isSelected: state.startDate == null && state.endDate == null,
                                onTap: () => ref.read(adminProvider.notifier).setDateFilter(start: null, end: null),
                              ),
                              _quickDateChip(
                                context,
                                label: 'Today',
                                isSelected: state.startDate != null &&
                                    state.endDate != null &&
                                    _formatDate(state.startDate!) == todayStr &&
                                    _formatDate(state.endDate!) == todayStr,
                                onTap: () => ref.read(adminProvider.notifier).setDateFilter(start: now, end: now),
                              ),
                              _quickDateChip(
                                context,
                                label: 'Yesterday',
                                isSelected: false,
                                onTap: () {
                                  final yest = now.subtract(const Duration(days: 1));
                                  ref.read(adminProvider.notifier).setDateFilter(start: yest, end: yest);
                                },
                              ),
                              _quickDateChip(
                                context,
                                label: 'Last 7 Days',
                                isSelected: false,
                                onTap: () {
                                  ref.read(adminProvider.notifier).setDateFilter(
                                    start: now.subtract(const Duration(days: 7)),
                                    end: now,
                                  );
                                },
                              ),
                              _quickDateChip(
                                context,
                                label: 'This Month',
                                isSelected: false,
                                onTap: () {
                                  final firstDayOfMonth = DateTime(now.year, now.month, 1);
                                  ref.read(adminProvider.notifier).setDateFilter(
                                    start: firstDayOfMonth,
                                    end: now,
                                  );
                                },
                              ),

                              const SizedBox(width: 8),

                              // Action Type Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: context.scaffoldBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: state.actionTypeFilter,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    items: const [
                                      DropdownMenuItem(value: 'All', child: Text('Action: All Types')),
                                      DropdownMenuItem(value: 'Create', child: Text('Action: Added / Created')),
                                      DropdownMenuItem(value: 'Update', child: Text('Action: Updated / Edited')),
                                      DropdownMenuItem(value: 'Delete', child: Text('Action: Deleted / Removed')),
                                      DropdownMenuItem(value: 'Auth', child: Text('Action: Login / Session')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).setActionTypeFilter(val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Audit Logs List Table ─────────────────────────────
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table Header with row count
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LayoutBuilder(
                              builder: (context, thConstraints) {
                                final isCompact = thConstraints.maxWidth < 550;
                                if (isCompact) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Showing $totalFiltered of ${state.logs.length} audit logs',
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (filteredLogs.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Click any row to view full details',
                                          style: TextStyle(color: context.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing $totalFiltered of ${state.logs.length} audit logs',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (filteredLogs.isNotEmpty)
                                      Text(
                                        'Click any row to view full details',
                                        style: TextStyle(color: context.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Table or Empty State
                          filteredLogs.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(48),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off, size: 48, color: context.textMuted),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No audit logs match your search and filter criteria.',
                                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try resetting filters or adjusting your date range.',
                                          style: TextStyle(color: context.textSecondary, fontSize: 13),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(adminProvider.notifier).clearAuditFilters();
                                          },
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('Reset All Filters'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    showCheckboxColumn: false,
                                    headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                                    columns: [
                                      DataColumn(label: Text('Timestamp', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('User Account', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Action Performed', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Module Scope', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('IP Address', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Details', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: paginatedLogs.map((log) {
                                      // Module scope color
                                      Color moduleColor = context.info;
                                      final mod = log.module.toLowerCase();
                                      if (mod.contains('hr') || mod.contains('attend') || mod.contains('salary')) {
                                        moduleColor = context.success;
                                      } else if (mod.contains('finance') || mod.contains('account') || mod.contains('loan')) {
                                        moduleColor = context.warning;
                                      } else if (mod.contains('project') || mod.contains('task')) {
                                        moduleColor = context.primaryColor;
                                      } else if (mod.contains('inventory') || mod.contains('asset')) {
                                        moduleColor = Colors.teal;
                                      } else if (mod.contains('sale') || mod.contains('purchase') || mod.contains('invoice')) {
                                        moduleColor = Colors.deepOrange;
                                      } else if (mod.contains('client')) {
                                        moduleColor = Colors.indigo;
                                      } else if (mod.contains('security') || mod.contains('system') || mod.contains('admin')) {
                                        moduleColor = context.error;
                                      }

                                      // Action icon
                                      IconData actionIcon = Icons.info_outline;
                                      Color actionIconColor = context.info;
                                      final act = log.action.toLowerCase();
                                      if (act.contains('created') || act.contains('added') || act.contains('check-in')) {
                                        actionIcon = Icons.add_circle_outline;
                                        actionIconColor = context.success;
                                      } else if (act.contains('deleted') || act.contains('removed')) {
                                        actionIcon = Icons.delete_outline;
                                        actionIconColor = context.error;
                                      } else if (act.contains('updated') || act.contains('edited') || act.contains('modified') || act.contains('disburs')) {
                                        actionIcon = Icons.edit_note;
                                        actionIconColor = context.warning;
                                      } else if (act.contains('logged in') || act.contains('login') || act.contains('signed out')) {
                                        actionIcon = Icons.lock_clock;
                                        actionIconColor = context.primaryColor;
                                      }

                                      return DataRow(
                                        onSelectChanged: (_) => _showLogDetailsDialog(context, log),
                                        cells: [
                                          // Timestamp
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: context.textMuted),
                                                const SizedBox(width: 6),
                                                Text(log.timestamp, style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          // User Account
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                                                  child: Text(
                                                    log.user.isNotEmpty ? log.user[0].toUpperCase() : 'U',
                                                    style: TextStyle(
                                                      color: context.primaryColor,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  log.user,
                                                  style: TextStyle(
                                                    color: context.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Action Performed
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(actionIcon, size: 16, color: actionIconColor),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 320,
                                                  child: Text(
                                                    log.action,
                                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Module Scope
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: moduleColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: moduleColor.withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                log.module,
                                                style: TextStyle(
                                                  color: moduleColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // IP Address
                                          DataCell(
                                            Text(
                                              log.ipAddress,
                                              style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          // Details Action
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, size: 18),
                                              tooltip: 'View Log Details',
                                              onPressed: () => _showLogDetailsDialog(context, log),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),

                          // Pagination Controls
                          if (filteredLogs.isNotEmpty && totalPages > 1) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, pConstraints) {
                                if (pConstraints.maxWidth < 500) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Showing ${startIndex + 1} to ${math.min(startIndex + _pageSize, totalFiltered)} of $totalFiltered entries',
                                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton.outlined(
                                            icon: const Icon(Icons.chevron_left, size: 18),
                                            tooltip: 'Previous Page',
                                            onPressed: currentPage > 1
                                                ? () => setState(() => _currentPage = currentPage - 1)
                                                : null,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Page $currentPage of $totalPages',
                                            style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.outlined(
                                            icon: const Icon(Icons.chevron_right, size: 18),
                                            tooltip: 'Next Page',
                                            onPressed: currentPage < totalPages
                                                ? () => setState(() => _currentPage = currentPage + 1)
                                                : null,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Showing ${startIndex + 1} to ${math.min(startIndex + _pageSize, totalFiltered)} of $totalFiltered entries',
                                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                                    ),
                                    Row(
                                      children: [
                                        IconButton.outlined(
                                          icon: const Icon(Icons.chevron_left, size: 18),
                                          tooltip: 'Previous Page',
                                          onPressed: currentPage > 1
                                              ? () => setState(() => _currentPage = currentPage - 1)
                                              : null,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Page $currentPage of $totalPages',
                                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton.outlined(
                                          icon: const Icon(Icons.chevron_right, size: 18),
                                          tooltip: 'Next Page',
                                          onPressed: currentPage < totalPages
                                              ? () => setState(() => _currentPage = currentPage + 1)
                                              : null,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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

  Widget _quickDateChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : context.scaffoldBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? context.primaryColor : context.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
