import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/access_denied_screen.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    // Super Admin Protection: Only Super Admin can access & manage Roles & Permissions
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
            AdminSubNav(activeRoute: '/administration/roles'),
            Expanded(
              child: AccessDeniedScreen(
                attemptedPath: '/administration/roles',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/roles'),

          // Main Header with Action Button
          Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(bottom: BorderSide(color: context.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: context.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tr('Roles & Permission Matrix')} (${state.userRoles.length})',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              tr('Super Admin clearance: create custom roles and configure granular ERP permissions.'),
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCreateRoleDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(isMobile ? tr('New Role') : tr('Create Role')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 18,
                      vertical: isMobile ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Toolbar
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 12, isMobile ? 16 : 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search roles by name or description...',
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: context.cardBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
              ],
            ),
          ),

          // Roles Content
          Expanded(
            child: _buildRolesTab(context, state, isMobile),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TAB 1: ROLES & PERMISSIONS
  // ══════════════════════════════════════════════════════════

  Widget _buildRolesTab(BuildContext context, AdminState state, bool isMobile) {
    final roles = state.userRoles.isNotEmpty
        ? state.userRoles
        : DefaultRoles.getDefaultRoles();

    final filteredRoles = roles.where((r) {
      if (_searchQuery.isEmpty) return true;
      return r.roleName.toLowerCase().contains(_searchQuery) ||
          r.description.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredRoles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 12),
            Text('No roles match "$_searchQuery"', style: TextStyle(color: context.textSecondary)),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRoles.length,
        itemBuilder: (context, idx) {
          final role = filteredRoles[idx];
          return _buildMobileRoleCard(context, role, state);
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DataTable(
            horizontalMargin: 20,
            columnSpacing: 24,
            headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
            dataRowMinHeight: 64,
            dataRowMaxHeight: 64,
            columns: const [
              DataColumn(label: Text('Role Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Assigned Users', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filteredRoles.map((role) {
              final assignedUsers = state.users.where(
                (u) => u.role.trim().toLowerCase() == role.roleName.trim().toLowerCase(),
              ).toList();
              final isSuper = role.isSuperAdmin;

              return DataRow(
                cells: [
                  // Role Name + Description
                  DataCell(
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSuper
                                ? Colors.amber.withValues(alpha: 0.15)
                                : context.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSuper ? Icons.admin_panel_settings : Icons.badge_outlined,
                            size: 18,
                            color: isSuper ? Colors.amber : context.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  role.roleName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                                if (isSuper) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.description.isNotEmpty ? role.description : 'Standard ERP operational role',
                              style: TextStyle(fontSize: 11, color: context.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (role.canChangePassword)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.key, size: 10, color: Colors.green),
                                        SizedBox(width: 3),
                                        Text('Can Change Password', style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                if (role.canChangeUsername)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.alternate_email, size: 10, color: Colors.blue),
                                        SizedBox(width: 3),
                                        Text('Can Change Username', style: TextStyle(fontSize: 9.5, color: Colors.blue, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                if (!isSuper && !role.canChangePassword && !role.canChangeUsername)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_outline, size: 10, color: Colors.amber),
                                        SizedBox(width: 3),
                                        Text('Credentials Super Admin Managed', style: TextStyle(fontSize: 9.5, color: Colors.amber, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Assigned Users
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${assignedUsers.length} Users',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  // Status (Active / Inactive Toggle)
                  DataCell(
                    isSuper
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active (Immutable)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          )
                        : Switch(
                            value: role.isActive,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              try {
                                await ref.read(adminProvider.notifier).toggleRoleStatus(role.roleName, val);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Role "${role.roleName}" status updated to ${val ? "Active" : "Inactive"}.'),
                                      backgroundColor: val ? context.success : Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: context.error),
                                  );
                                }
                              }
                            },
                          ),
                  ),

                  // Actions: Edit Permissions & Delete
                  DataCell(
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showEditRoleDialog(context, role),
                          icon: const Icon(Icons.tune, size: 14),
                          label: const Text('Edit Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor.withValues(alpha: 0.12),
                            foregroundColor: context.primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        if (!isSuper) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: context.error, size: 18),
                            tooltip: 'Delete Role',
                            onPressed: () => _handleDeleteRole(context, role, assignedUsers),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRoleCard(BuildContext context, UserRole role, AdminState state) {
    final assignedUsers = state.users.where(
      (u) => u.role.trim().toLowerCase() == role.roleName.trim().toLowerCase(),
    ).toList();
    final isSuper = role.isSuperAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isSuper ? Icons.admin_panel_settings : Icons.shield_outlined,
                        color: isSuper ? Colors.amber : context.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          role.roleName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                isSuper
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Active (Immutable)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            role.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: role.isActive ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: role.isActive,
                              activeColor: Colors.green,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) async {
                                try {
                                  await ref.read(adminProvider.notifier).toggleRoleStatus(role.roleName, val);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Role "${role.roleName}" status updated to ${val ? "Active" : "Inactive"}.'),
                                        backgroundColor: val ? context.success : Colors.orange,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: context.error),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              role.description.isNotEmpty ? role.description : 'Standard ERP operational role',
              style: TextStyle(fontSize: 11, color: context.textMuted),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (role.canChangePassword)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key, size: 10, color: Colors.green),
                        SizedBox(width: 3),
                        Text('Can Change Password', style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (role.canChangeUsername)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.alternate_email, size: 10, color: Colors.blue),
                        SizedBox(width: 3),
                        Text('Can Change Username', style: TextStyle(fontSize: 9.5, color: Colors.blue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (!isSuper && !role.canChangePassword && !role.canChangeUsername)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 10, color: Colors.amber),
                        SizedBox(width: 3),
                        Text('Credentials SA Managed', style: TextStyle(fontSize: 9.5, color: Colors.amber, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${assignedUsers.length} Users Assigned',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showEditRoleDialog(context, role),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Edit Permissions', style: TextStyle(fontSize: 11)),
                    ),
                    if (!isSuper) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: context.error, size: 18),
                        onPressed: () => _handleDeleteRole(context, role, assignedUsers),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG: CREATE ROLE
  // ══════════════════════════════════════════════════════════

  static const activeMatrixActions = [
    PermissionAction.view,
    PermissionAction.create,
    PermissionAction.edit,
    PermissionAction.delete,
  ];

  void _showCreateRoleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isActive = true;
    bool canChangeUsername = false;
    bool canChangePassword = false;

    // Granular permissions map
    final permissionsMap = <AppModule, Set<PermissionAction>>{
      for (final mod in AppModule.values) mod: <PermissionAction>{},
    };
    permissionsMap[AppModule.dashboard] = {PermissionAction.view};

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMobile = MediaQuery.of(context).size.width < 700;

          return AlertDialog(
            backgroundColor: context.cardBg,
            insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.add_moderator_rounded, color: context.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Create Custom Role',
                    style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: isMobile ? double.maxFinite : 780,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Role Name
                      Text('Role Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. HR Manager, Senior Accountant, Project Lead',
                          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Role name is required';
                          if (val.trim().toLowerCase() == 'super admin') return 'Role name reserved for system root';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description
                      Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Describe scope and responsibilities of this role...',
                          hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                              Text('Active roles allow assigned users to log in', style: TextStyle(fontSize: 11, color: context.textMuted)),
                            ],
                          ),
                          Switch(
                            value: isActive,
                            activeColor: Colors.green,
                            onChanged: (val) => setDialogState(() => isActive = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Credential Modification Controls
                      _buildCredentialModificationControls(
                        context: context,
                        usernameController: usernameController,
                        passwordController: passwordController,
                        confirmPasswordController: confirmPasswordController,
                        obscurePassword: obscurePassword,
                        onToggleObscurePassword: () => setDialogState(() => obscurePassword = !obscurePassword),
                        obscureConfirmPassword: obscureConfirmPassword,
                        onToggleObscureConfirmPassword: () => setDialogState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        isCreateMode: true,
                      ),
                      const Divider(height: 24),

                      // Permissions Matrix Header
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Granular Permissions Matrix',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select allowed actions for each ERP module',
                              style: TextStyle(fontSize: 11, color: context.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      for (final mod in matrixOrderedModules) {
                                        if (mod.isCategoryHeader) continue;
                                        final acts = activeMatrixActions.where((a) => _isActionSupported(mod, a));
                                        permissionsMap[mod] = Set<PermissionAction>.from(acts);
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.select_all, size: 15),
                                  label: const Text('Select All', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      permissionsMap.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all, size: 15),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Granular Permissions Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.primaryColor)),
                                  Text('Select allowed actions (View, Create, Edit, Delete) for each ERP module', style: TextStyle(fontSize: 11, color: context.textMuted), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      for (final mod in matrixOrderedModules) {
                                        if (mod.isCategoryHeader) continue;
                                        final acts = activeMatrixActions.where((a) => _isActionSupported(mod, a));
                                        permissionsMap[mod] = Set<PermissionAction>.from(acts);
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.select_all, size: 16),
                                  label: const Text('Select All', style: TextStyle(fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      permissionsMap.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),

                      // Matrix Table / Cards
                      _buildPermissionsMatrixEditor(context, permissionsMap, setDialogState, isMobile),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final roleName = nameController.text.trim();
                  final desc = descController.text.trim();
                  final uname = usernameController.text.trim();
                  final pass = passwordController.text.trim();
                  final confirmPass = confirmPasswordController.text.trim();

                  if (pass.isNotEmpty) {
                    if (pass.length < 6) {
                      messenger.showSnackBar(
                        SnackBar(content: const Text('Password must be at least 6 characters long.'), backgroundColor: context.error),
                      );
                      return;
                    }
                    if (pass != confirmPass) {
                      messenger.showSnackBar(
                        SnackBar(content: const Text('Passwords do not match.'), backgroundColor: context.error),
                      );
                      return;
                    }
                  }

                  try {
                    await ref.read(adminProvider.notifier).createCustomRole(
                      roleName: roleName,
                      description: desc.isNotEmpty ? desc : 'Custom ERP operational role',
                      permissions: permissionsMap,
                      isActive: isActive,
                      canChangeUsername: canChangeUsername,
                      canChangePassword: canChangePassword,
                    );

                    // If username & password were provided, create the user account immediately
                    if (uname.isNotEmpty && pass.isNotEmpty) {
                      await ref.read(adminProvider.notifier).addUser(
                        AdminUser(
                          id: '',
                          name: roleName,
                          username: uname.toLowerCase(),
                          email: '$uname@hhtech.com',
                          role: roleName,
                          status: 'Active',
                          lastActive: 'Never',
                        ),
                        password: pass,
                      );
                    }

                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          uname.isNotEmpty
                              ? 'Role "$roleName" and user account "@$uname" created successfully!'
                              : 'Role "$roleName" created successfully!',
                        ),
                        backgroundColor: context.success,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to create role: $e'), backgroundColor: context.error),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DIALOG: EDIT ROLE & PERMISSIONS
  // ══════════════════════════════════════════════════════════

  void _showEditRoleDialog(BuildContext context, UserRole role) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: role.roleName);
    final descController = TextEditingController(text: role.description);
    bool isActive = role.isActive;
    bool isSaving = false;
    final isSuper = role.isSuperAdmin;

    final adminState = ref.read(adminProvider);
    final assignedUsers = adminState.users.where(
      (u) => u.role.trim().toLowerCase() == role.roleName.trim().toLowerCase()
    ).toList();
    AdminUser? selectedUser = assignedUsers.firstOrNull;
    final usernameController = TextEditingController(text: selectedUser?.username ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    // Clone existing permissions exactly as stored
    final permissionsMap = <AppModule, Set<PermissionAction>>{};
    for (final mod in AppModule.values) {
      permissionsMap[mod] = Set<PermissionAction>.from(role.permissions[mod] ?? {});
    }
    // Dashboard only supports view
    if (permissionsMap.containsKey(AppModule.dashboard)) {
      permissionsMap[AppModule.dashboard]!.removeWhere((a) => a != PermissionAction.view);
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMobile = MediaQuery.of(context).size.width < 700;

          return AlertDialog(
            backgroundColor: context.cardBg,
            insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.tune, color: context.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit Role: ${role.roleName}',
                    style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: isMobile ? double.maxFinite : 780,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Role Name (Disabled if Super Admin)
                      Text('Role Name *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        enabled: !isSuper,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Finance Lead',
                          filled: true,
                          fillColor: context.scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Role name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description
                      Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Scope and responsibilities...',
                          filled: true,
                          fillColor: context.scaffoldBg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Toggle
                      if (!isSuper) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Role Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                                Text('Inactive roles prevent assigned users from accessing ERP', style: TextStyle(fontSize: 11, color: context.textMuted)),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              activeColor: Colors.green,
                              onChanged: (val) => setDialogState(() => isActive = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Credential Modification Controls
                        _buildCredentialModificationControls(
                          context: context,
                          usernameController: usernameController,
                          passwordController: passwordController,
                          confirmPasswordController: confirmPasswordController,
                          obscurePassword: obscurePassword,
                          onToggleObscurePassword: () => setDialogState(() => obscurePassword = !obscurePassword),
                          obscureConfirmPassword: obscureConfirmPassword,
                          onToggleObscureConfirmPassword: () => setDialogState(() => obscureConfirmPassword = !obscureConfirmPassword),
                          assignedUsers: assignedUsers,
                          selectedUser: selectedUser,
                          onUserSelected: (u) {
                            if (u != null) {
                              setDialogState(() {
                                selectedUser = u;
                                usernameController.text = u.username;
                                passwordController.clear();
                                confirmPasswordController.clear();
                              });
                            }
                          },
                          isCreateMode: false,
                        ),
                        const Divider(height: 24),
                      ],

                      // Permissions Matrix Header
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Granular Permissions Matrix',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSuper
                                  ? 'Super Admin has full unrestricted system access'
                                  : 'Configure exact module access and operation permissions',
                              style: TextStyle(fontSize: 11, color: context.textMuted),
                            ),
                            if (!isSuper) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        for (final mod in matrixOrderedModules) {
                                          if (mod.isCategoryHeader) continue;
                                          final acts = activeMatrixActions.where((a) => _isActionSupported(mod, a));
                                          permissionsMap[mod] = Set<PermissionAction>.from(acts);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.select_all, size: 15),
                                    label: const Text('Select All', style: TextStyle(fontSize: 11)),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        permissionsMap.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all, size: 15),
                                    label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Granular Permissions Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.primaryColor)),
                                  Text(
                                    isSuper
                                        ? 'Super Admin has full unrestricted system access'
                                        : 'Configure exact module access and operation permissions',
                                    style: TextStyle(fontSize: 11, color: context.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!isSuper)
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        for (final mod in matrixOrderedModules) {
                                          if (mod.isCategoryHeader) continue;
                                          final acts = activeMatrixActions.where((a) => _isActionSupported(mod, a));
                                          permissionsMap[mod] = Set<PermissionAction>.from(acts);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.select_all, size: 16),
                                    label: const Text('Select All', style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        permissionsMap.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all, size: 16),
                                    label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      const SizedBox(height: 10),

                      if (isSuper)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.amber, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Root Administrator: Super Admin account has immutable, unrestricted permission across all present and future modules.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildPermissionsMatrixEditor(context, permissionsMap, setDialogState, isMobile),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              if (!isSuper)
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final newRoleName = nameController.text.trim();
                          final desc = descController.text.trim();
                          final pass = passwordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (pass.isNotEmpty) {
                            if (pass.length < 6) {
                              messenger.showSnackBar(
                                SnackBar(content: const Text('New password must be at least 6 characters long.'), backgroundColor: context.error),
                              );
                              return;
                            }
                            if (pass != confirmPass) {
                              messenger.showSnackBar(
                                SnackBar(content: const Text('Passwords do not match.'), backgroundColor: context.error),
                              );
                              return;
                            }
                          }

                          final successColor = context.success;
                          final errorColor = context.error;

                          setDialogState(() => isSaving = true);
                          try {
                            await ref.read(adminProvider.notifier).updateRolePermissionsMatrix(
                              roleName: role.roleName,
                              newRoleName: newRoleName,
                              description: desc.isNotEmpty ? desc : role.description,
                              isActive: isActive,
                              canChangeUsername: false,
                              canChangePassword: false,
                              permissions: permissionsMap,
                            );

                            final newUsername = usernameController.text.trim();
                            if (selectedUser != null) {
                              if (newUsername.isNotEmpty && newUsername != selectedUser!.username) {
                                await ref.read(adminProvider.notifier).updateUser(
                                  selectedUser!.copyWith(
                                    username: newUsername,
                                    email: selectedUser!.email.contains('@')
                                        ? '$newUsername@${selectedUser!.email.split('@').last}'
                                        : '$newUsername@hhtech.com',
                                  ),
                                );
                              }
                              if (pass.isNotEmpty) {
                                await ref.read(adminProvider.notifier).resetUserPassword(
                                  selectedUser!.id,
                                  pass,
                                );
                              }
                            } else if (newUsername.isNotEmpty && pass.isNotEmpty) {
                              final newUser = AdminUser(
                                id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                                name: newRoleName,
                                username: newUsername,
                                email: '$newUsername@hhtech.com',
                                role: newRoleName,
                                status: isActive ? 'Active' : 'Inactive',
                                lastActive: 'Never',
                              );
                              await ref.read(adminProvider.notifier).addUser(newUser, password: pass);
                            }

                            if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Permissions and credentials updated for role "$newRoleName"!'), backgroundColor: successColor),
                            );
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to update role: $e'), backgroundColor: errorColor),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
            ],
          );
        },
      ),
    );
  }

  static const List<AppModule> matrixOrderedModules = [
    AppModule.dashboard,

    // Finance & Accounts
    AppModule.finance,
    AppModule.ledger,
    AppModule.accounts,
    AppModule.income,
    AppModule.expenses,
    AppModule.loans,
    AppModule.personalAccounts,

    // Clients & Relations
    AppModule.clients,

    // Projects & Operations (Module Header + 3 Sub-pages)
    AppModule.projects,
    AppModule.projectsList,
    AppModule.tasks,
    AppModule.timesheets,

    // HR & Employees
    AppModule.hr,
    AppModule.employees,
    AppModule.attendance,
    AppModule.payroll,
    AppModule.advances,
    AppModule.employeeHistory,

    // Inventory & Assets
    AppModule.inventory,
    AppModule.officeInventory,
    AppModule.assets,

    // Finance Reports (Separate Module)
    AppModule.financeReports,

    // Reports & Analytics
    AppModule.reports,
    AppModule.generalReports,

    // Administration & Security
    AppModule.administration,
    AppModule.systemSettings,
    AppModule.databaseBackup,
    AppModule.auditLogs,
  ];

  static bool _isActionSupported(AppModule module, PermissionAction action) {
    if (module.isCategoryHeader) return false;
    if (module == AppModule.dashboard) {
      return action == PermissionAction.view;
    }
    return true;
  }

  Widget _buildPermissionsMatrixEditor(
    BuildContext context,
    Map<AppModule, Set<PermissionAction>> permissionsMap,
    void Function(void Function()) setDialogState,
    bool isMobile,
  ) {
    final modules = matrixOrderedModules;
    final allActions = activeMatrixActions;

    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: Text('ERP Module / Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(
                    width: 36,
                    child: Center(
                      child: Text('All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  ...allActions.map((act) {
                    final targetModules = modules.where((m) => _isActionSupported(m, act));
                    final allColChecked = targetModules.isNotEmpty &&
                        targetModules.every((m) => permissionsMap[m]?.contains(act) ?? false);
                    return Expanded(
                      flex: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          setDialogState(() {
                            if (allColChecked) {
                              for (final m in targetModules) {
                                permissionsMap[m]?.remove(act);
                              }
                            } else {
                              for (final m in targetModules) {
                                permissionsMap.putIfAbsent(m, () => <PermissionAction>{}).add(act);
                              }
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                act.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: allColChecked ? context.primaryColor : context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                allColChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 13,
                                color: allColChecked ? context.primaryColor : context.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            separatorBuilder: (_, idx) {
              final nextIsHeader = (idx + 1 < modules.length) && modules[idx + 1].isCategoryHeader;
              return Divider(
                height: 1,
                thickness: nextIsHeader ? 1.5 : 1,
                color: nextIsHeader
                    ? context.primaryColor.withValues(alpha: 0.25)
                    : context.border.withValues(alpha: 0.4),
              );
            },
            itemBuilder: (context, idx) {
              final module = modules[idx];

              // ══════════════════════════════════════════════════
              // CATEGORY HEADER: Title & Icon ONLY, NO CHECKBOXES!
              // ══════════════════════════════════════════════════
              if (module.isCategoryHeader) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.07),
                  ),
                  child: Row(
                    children: [
                      Icon(module.icon, size: 17, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          module.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'MODULE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ══════════════════════════════════════════════════
              // INDIVIDUAL PAGE ROW (Sub-modules or Standalone)
              // ══════════════════════════════════════════════════
              final granted = permissionsMap[module] ?? {};
              final isSub = module.isSubModule;
              final supportedActions = allActions.where((a) => _isActionSupported(module, a)).toList();
              final allChecked = supportedActions.isNotEmpty &&
                  supportedActions.every((a) => granted.contains(a));

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: isMobile ? 8 : 4),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isSub) const SizedBox(width: 14),
                              if (isSub)
                                Icon(Icons.subdirectory_arrow_right,
                                    size: 14, color: context.textMuted.withValues(alpha: 0.5)),
                              if (isSub) const SizedBox(width: 4),
                              Icon(module.icon,
                                  size: 16,
                                  color: granted.isNotEmpty ? context.primaryColor : context.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  module.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSub ? FontWeight.normal : FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Checkbox(
                                value: allChecked,
                                activeColor: context.primaryColor,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      permissionsMap
                                          .putIfAbsent(module, () => <PermissionAction>{})
                                          .addAll(supportedActions);
                                    } else {
                                      permissionsMap[module]?.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: supportedActions.map((act) {
                              final isSet = granted.contains(act);
                              return FilterChip(
                                label: Text(act.name.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isSet ? context.primaryColor : context.textPrimary)),
                                selected: isSet,
                                selectedColor: context.primaryColor.withValues(alpha: 0.15),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                onSelected: (val) {
                                  setDialogState(() {
                                    if (val) {
                                      permissionsMap.putIfAbsent(module, () => <PermissionAction>{}).add(act);
                                    } else {
                                      permissionsMap[module]?.remove(act);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Module / Page Name
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                if (isSub) const SizedBox(width: 20),
                                if (isSub)
                                  Icon(Icons.subdirectory_arrow_right,
                                      size: 14, color: context.textMuted.withValues(alpha: 0.5)),
                                if (isSub) const SizedBox(width: 6),
                                Icon(module.icon,
                                    size: 16,
                                    color: granted.isNotEmpty ? context.primaryColor : context.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    module.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSub ? FontWeight.normal : FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quick Select Row
                          SizedBox(
                            width: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                allChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 16,
                                color: allChecked ? context.primaryColor : context.textMuted,
                              ),
                              tooltip: allChecked ? 'Deselect Row' : 'Select Row',
                              onPressed: () {
                                setDialogState(() {
                                  if (allChecked) {
                                    permissionsMap[module]?.clear();
                                  } else {
                                    permissionsMap
                                        .putIfAbsent(module, () => <PermissionAction>{})
                                        .addAll(supportedActions);
                                  }
                                });
                              },
                            ),
                          ),

                          // Action Checkboxes: VIEW, CREATE, EDIT, DELETE
                          ...allActions.map((act) {
                            final isSupported = _isActionSupported(module, act);
                            if (!isSupported) {
                              return const Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    '-',
                                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }

                            final isSet = granted.contains(act);
                            return Expanded(
                              flex: 2,
                              child: Center(
                                child: Checkbox(
                                  value: isSet,
                                  activeColor: context.primaryColor,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        permissionsMap.putIfAbsent(module, () => <PermissionAction>{}).add(act);
                                      } else {
                                        permissionsMap[module]?.remove(act);
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // ROLE DELETION SAFETY (Requirement 15)
  // ══════════════════════════════════════════════════════════

  void _handleDeleteRole(BuildContext context, UserRole role, List<AdminUser> assignedUsers) {
    if (role.isSuperAdmin || role.roleName.trim().toLowerCase() == 'super admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Security Warning: Cannot delete the Super Admin role.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (assignedUsers.isNotEmpty) {
      // Users are assigned! Require reassignment before deletion
      _showReassignAndDeleteDialog(context, role, assignedUsers);
    } else {
      // No users assigned, simple confirmation
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: context.cardBg,
          title: const Text('Delete Role'),
          content: Text('Are you sure you want to delete role "${role.roleName}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  await ref.read(adminProvider.notifier).deleteRole(role.roleName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Role "${role.roleName}" deleted.'), backgroundColor: context.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: context.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _showReassignAndDeleteDialog(BuildContext context, UserRole role, List<AdminUser> assignedUsers) {
    final state = ref.read(adminProvider);
    final availableRoles = state.userRoles
        .where((r) => r.roleName.toLowerCase() != role.roleName.toLowerCase())
        .toList();

    String selectedReassignRole = availableRoles.isNotEmpty ? availableRoles.first.roleName : 'Employee';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 10),
                const Text('Role Reassignment Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cannot delete role "${role.roleName}" because ${assignedUsers.length} active users are currently assigned to it:',
                    style: TextStyle(fontSize: 13, color: context.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: assignedUsers.map((u) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.person, size: 14),
                              const SizedBox(width: 6),
                              Text('${u.name} (@${u.username})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Reassign users to new role: *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedReassignRole,
                    dropdownColor: context.cardBg,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.scaffoldBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: availableRoles.map((r) {
                      return DropdownMenuItem<String>(
                        value: r.roleName,
                        child: Text(r.roleName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReassignRole = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(adminProvider.notifier).deleteRole(
                      role.roleName,
                      reassignToRole: selectedReassignRole,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Role "${role.roleName}" deleted and users reassigned to "$selectedReassignRole".'),
                        backgroundColor: context.success,
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: context.error),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: context.error, foregroundColor: Colors.white),
                child: const Text('Reassign & Delete Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCredentialModificationControls({
    required BuildContext context,
    required TextEditingController usernameController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required bool obscurePassword,
    required VoidCallback onToggleObscurePassword,
    required bool obscureConfirmPassword,
    required VoidCallback onToggleObscureConfirmPassword,
    List<AdminUser> assignedUsers = const [],
    AdminUser? selectedUser,
    ValueChanged<AdminUser?>? onUserSelected,
    bool isCreateMode = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.manage_accounts_outlined, size: 16, color: context.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Credential Modification Controls',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Super Admin Managed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.manage_accounts_outlined, size: 16, color: context.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Credential Modification Controls',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.primaryColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Super Admin Managed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            isCreateMode
                ? 'Set login credentials for this role. Only Super Admin can modify or reset these credentials.'
                : 'Modify login username or set/reset password for this role. Role-based users cannot change credentials from their own login.',
            style: TextStyle(fontSize: 11, color: context.textMuted),
          ),
          const SizedBox(height: 12),

          // If multiple users assigned to this role in edit mode, show account selector
          if (!isCreateMode && assignedUsers.length > 1) ...[
            Text(
              'Select User Account to Modify',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<AdminUser>(
              initialValue: selectedUser,
              dropdownColor: context.cardBg,
              isExpanded: true,
              style: TextStyle(color: context.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.scaffoldBg,
                prefixIcon: const Icon(Icons.person_outline, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              items: assignedUsers.map((u) {
                return DropdownMenuItem(
                  value: u,
                  child: Text('${u.name} (@${u.username.isNotEmpty ? u.username : u.email})'),
                );
              }).toList(),
              onChanged: onUserSelected,
            ),
            const SizedBox(height: 12),
          ],

          // Username Field
          Text(
            'Username / Login ID',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: usernameController,
            style: TextStyle(color: context.textPrimary, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'e.g. accountant, hrmanager',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              filled: true,
              fillColor: context.scaffoldBg,
              prefixIcon: const Icon(Icons.alternate_email, size: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Password and Confirm Password Fields
          if (isMobile) ...[
            Text(
              isCreateMode ? 'Password' : 'New Password (leave blank to keep unchanged)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              style: TextStyle(color: context.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: isCreateMode ? 'Min 6 characters' : 'Enter new password',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                filled: true,
                fillColor: context.scaffoldBg,
                prefixIcon: const Icon(Icons.lock_outline, size: 16),
                suffixIcon: IconButton(
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 16),
                  onPressed: onToggleObscurePassword,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              validator: (val) {
                if (val != null && val.isNotEmpty && val.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Confirm Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscureConfirmPassword,
              style: TextStyle(color: context.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Re-enter password',
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                filled: true,
                fillColor: context.scaffoldBg,
                prefixIcon: const Icon(Icons.lock_reset, size: 16),
                suffixIcon: IconButton(
                  icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 16),
                  onPressed: onToggleObscureConfirmPassword,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              validator: (val) {
                if (passwordController.text.isNotEmpty) {
                  if (val == null || val.isEmpty) return 'Confirm password';
                  if (val != passwordController.text) return 'Passwords do not match';
                }
                return null;
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCreateMode ? 'Password' : 'New Password (blank = unchanged)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: TextStyle(color: context.textPrimary, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: isCreateMode ? 'Min 6 characters' : 'Enter new password',
                          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          prefixIcon: const Icon(Icons.lock_outline, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, size: 16),
                            onPressed: onToggleObscurePassword,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        validator: (val) {
                          if (val != null && val.isNotEmpty && val.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Password',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: context.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        style: TextStyle(color: context.textPrimary, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Re-enter password',
                          hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: context.scaffoldBg,
                          prefixIcon: const Icon(Icons.lock_reset, size: 16),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 16),
                            onPressed: onToggleObscureConfirmPassword,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        validator: (val) {
                          if (passwordController.text.isNotEmpty) {
                            if (val == null || val.isEmpty) return 'Confirm password';
                            if (val != passwordController.text) return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),

          // Security Policy Banner
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.amber),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Super Admin Exclusive: Only Super Admin can change credentials from here. Role-based users cannot change their username or password from their own login.',
                    style: TextStyle(fontSize: 10.5, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

