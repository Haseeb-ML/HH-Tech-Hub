import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class AuditlogsScreen extends ConsumerWidget {
  const AuditlogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/audit_logs'),

          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Subtitle
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
                    'Security logs tracking administrative actions, payments, and system updates.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filters
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Search field
                          Expanded(
                            flex: 3,
                            child: TextField(
                              onChanged: (val) => ref.read(adminProvider.notifier).setSearchQuery(val),
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: tr('Search logs by action, email, or IP...'),
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                                prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Module Filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: state.moduleFilter,
                              dropdownColor: context.cardBg,
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: tr('Filter Module'),
                                labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                DropdownMenuItem(value: 'All', child: Text(tr('All Modules'))),
                                DropdownMenuItem(value: 'HR', child: Text(tr('HR Management'))),
                                DropdownMenuItem(value: 'Finance', child: Text(tr('Finance'))),
                                DropdownMenuItem(value: 'Projects', child: Text('Projects')),
                                DropdownMenuItem(value: 'Inventory', child: Text(tr('Inventory'))),
                                DropdownMenuItem(value: 'System', child: Text(tr('System Operations'))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(adminProvider.notifier).setModuleFilter(val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Audit logs list table
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: state.filteredLogs.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No audit logs match your search criteria.',
                                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                                  columns: [
                                    DataColumn(label: Text('Timestamp', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('User Account', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Action Performed', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Module Scope', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('IP Address', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                  ],
                                  rows: state.filteredLogs.map((log) {
                                    // Module scope color
                                    Color moduleColor = context.info;
                                    if (log.module == 'HR') {
                                      moduleColor = context.success;
                                    } else if (log.module == 'Finance') {
                                      moduleColor = context.warning;
                                    } else if (log.module == 'Projects') {
                                      moduleColor = context.primaryColor;
                                    } else if (log.module == 'System') {
                                      moduleColor = context.error;
                                    }

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(log.timestamp, style: TextStyle(color: context.textSecondary, fontSize: 12))),
                                        DataCell(Text(log.user, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
                                        DataCell(
                                          SizedBox(
                                            width: 320,
                                            child: Text(
                                              log.action,
                                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: moduleColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              log.module,
                                              style: TextStyle(color: moduleColor, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(log.ipAddress, style: TextStyle(color: context.textMuted, fontSize: 12))),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
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
}
