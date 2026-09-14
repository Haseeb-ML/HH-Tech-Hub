import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  String _selectedRoleName = 'System Admin';

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    // Get selected role data
    final selectedRole = state.roles.firstWhere(
      (role) => role.roleName == _selectedRoleName,
      orElse: () => state.roles.first,
    );

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/roles'),

          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Subtitle
                  Text(
                    'System Roles & Permissions',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure granular access permissions for user access classes.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel: Roles Cards list
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: state.roles.map((role) {
                            final isSelected = role.roleName == _selectedRoleName;

                            // Icon for each role type
                            IconData roleIcon = Icons.security;
                            if (role.roleName == 'HR Manager') {
                              roleIcon = Icons.badge_outlined;
                            } else if (role.roleName == 'Finance Manager') {
                              roleIcon = Icons.account_balance_wallet_outlined;
                            } else if (role.roleName == 'Project Manager') {
                              roleIcon = Icons.assignment_outlined;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => setState(() => _selectedRoleName = role.roleName),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? context.primaryColor : context.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? context.primaryColor.withValues(alpha: 0.1)
                                              : context.scaffoldBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          roleIcon,
                                          color: isSelected ? context.primaryColor : context.textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              role.roleName,
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${role.permissions.values.where((v) => v).length} permissions active',
                                              style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: isSelected ? context.primaryColor : context.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Panel: Permissions Checklist Detail
                      Expanded(
                        flex: 5,
                        child: GlassCard(
                          title: '${tr("Permissions configuration for")} "$_selectedRoleName"',
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: selectedRole.permissions.keys.map((permKey) {
                                final isGranted = selectedRole.permissions[permKey] ?? false;

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: context.divider, width: 1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              permKey,
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Enables users to perform operations under this module scope.',
                                              style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: isGranted,
                                        activeThumbColor: context.primaryColor,
                                        onChanged: (val) async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final successColor = context.success;
                                          final errorColor = context.error;
                                          try {
                                            await ref.read(adminProvider.notifier).togglePermission(
                                                  _selectedRoleName,
                                                  permKey,
                                                );
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${tr("Permission")} "$permKey" ${tr("for role")} "$_selectedRoleName" ${val ? tr("is now enabled.") : tr("is now disabled.")}',
                                                ),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: successColor,
                                              ),
                                            );
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${tr("Failed to update permission:")} $e',
                                                ),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: errorColor,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
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
