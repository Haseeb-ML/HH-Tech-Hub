import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Nav Tab
          const AdminSubNav(activeRoute: '/administration/roles'),

          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Add Button
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage ERP user accounts, assigned roles, and credentials.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openCreateUserDialog(context, ref),
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: Text(tr('Create User')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Management',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage ERP user accounts, assigned roles, and access credentials.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openCreateUserDialog(context, ref),
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                          label: Text(tr('Create User')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Users Table
                  GlassCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                        columns: [
                          DataColumn(label: Text(tr('Full Name'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Username', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(tr('Email Address'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('System Role', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(tr('Status'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Last Active', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                        ],
                        rows: state.users.map((user) {
                          final isUserActive = user.status == 'Active';
                          final isSuper = user.isSuperAdmin || user.role.toLowerCase() == 'super admin';

                          // Role colors
                          Color roleColor = context.info;
                          if (isSuper) {
                            roleColor = Colors.purple;
                          } else if (user.role.contains('HR')) {
                            roleColor = context.success;
                          } else if (user.role.contains('Finance')) {
                            roleColor = Colors.teal;
                          } else if (user.role.contains('Project')) {
                            roleColor = context.primaryColor;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: roleColor.withValues(alpha: 0.12),
                                      child: Text(
                                        user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
                                        style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      user.name,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    if (isSuper) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('SUPER', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.username.isNotEmpty ? user.username : user.email.split('@').first,
                                  style: TextStyle(color: context.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                              DataCell(Text(user.email, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSuper
                                            ? Colors.amber.withValues(alpha: 0.15)
                                            : (isUserActive
                                                ? Colors.green.withValues(alpha: 0.15)
                                                : Colors.red.withValues(alpha: 0.15)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSuper
                                              ? Colors.amber.withValues(alpha: 0.4)
                                              : (isUserActive
                                                  ? Colors.green.withValues(alpha: 0.4)
                                                  : Colors.red.withValues(alpha: 0.4)),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSuper
                                                ? Icons.shield_rounded
                                                : (isUserActive ? Icons.check_circle_rounded : Icons.block_rounded),
                                            size: 13,
                                            color: isSuper
                                                ? Colors.amber
                                                : (isUserActive ? Colors.green : Colors.redAccent),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isSuper
                                                ? 'ROOT'
                                                : (isUserActive ? 'ACTIVE' : 'BLOCKED'),
                                            style: TextStyle(
                                              color: isSuper
                                                  ? Colors.amber
                                                  : (isUserActive ? Colors.green : Colors.redAccent),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isSuper)
                                      Tooltip(
                                        message: isUserActive ? 'Click to Block User' : 'Click to Grant Access (Unblock)',
                                        child: InkWell(
                                          onTap: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final newStatus = isUserActive ? 'Inactive' : 'Active';
                                            await ref.read(adminProvider.notifier).updateUser(
                                              user.copyWith(status: newStatus),
                                            );
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${user.name} has been ${isUserActive ? "BLOCKED (Access revoked)" : "ACTIVATED (Access granted)"}.',
                                                ),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: isUserActive ? Colors.redAccent : Colors.green,
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isUserActive
                                                  ? Colors.red.withValues(alpha: 0.08)
                                                  : Colors.green.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isUserActive
                                                    ? Colors.red.withValues(alpha: 0.3)
                                                    : Colors.green.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Text(
                                              isUserActive ? 'Block' : 'Unblock',
                                              style: TextStyle(
                                                color: isUserActive ? Colors.redAccent : Colors.green,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(Text(user.lastActive, style: TextStyle(color: context.textMuted, fontSize: 12))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, size: 18, color: context.primaryColor),
                                      tooltip: 'Edit User',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => _EditUserDialog(user: user),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.lock_reset_rounded, size: 18, color: Colors.amber),
                                      tooltip: 'Reset Password',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => _ResetPasswordDialog(user: user),
                                        );
                                      },
                                    ),
                                    if (!isSuper) ...[
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 18, color: context.error),
                                        tooltip: 'Delete User',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final errorColor = context.error;
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(tr('Delete User Account')),
                                              content: Text('${tr("Are you sure you want to delete account")} "${user.name}"?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: Text(tr('Delete'), style: TextStyle(color: context.error)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            ref.read(adminProvider.notifier).deleteUser(user.id);
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text('${tr("User")} "${user.name}" ${tr("deleted.")}'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: errorColor,
                                              ),
                                            );
                                          }
                                        },
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateUserDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.success;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddUserDialog(),
    );
    if (result != null) {
      final newUser = result['user'] as AdminUser;
      final password = result['password'] as String;
      try {
        await ref.read(adminProvider.notifier).addUser(newUser, password: password);
        messenger.showSnackBar(
          SnackBar(
            content: Text('User "${newUser.name}" added successfully.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: successColor,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _role;
  bool _isActive = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);

    final availableRoles = adminState.userRoles.isNotEmpty
        ? adminState.userRoles.map((r) => r.roleName).toList()
        : ['Super Admin'];

    final defaultRole = availableRoles.where((r) => r != 'Super Admin').firstOrNull ?? availableRoles.first;
    if (_role == null || !availableRoles.contains(_role)) {
      _role = defaultRole;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create User Account',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Full Name
                _buildLabel(context, tr('Full Name') + ' *'),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'e.g. Ali Ahmed'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 14),

                // Username
                _buildLabel(context, 'Username *'),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'e.g. ali'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter username' : null,
                ),
                const SizedBox(height: 14),

                // Email Address
                _buildLabel(context, tr('Email Address') + ' *'),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'ali@hhtech.com'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter email';
                    if (!val.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                _buildLabel(context, tr('Password') + ' *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(
                    context,
                    '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 14),

                // Confirm Password
                _buildLabel(context, 'Confirm Password *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, '••••••••'),
                  validator: (val) {
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // System Role
                _buildLabel(context, 'Assigned Role *'),
                DropdownButtonFormField<String>(
                  value: _role,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(context, ''),
                  items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _role = val);
                  },
                ),
                const SizedBox(height: 14),

                // Active Status Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Active Status',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: context.success,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newUser = AdminUser(
                            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                            name: _nameController.text.trim(),
                            username: _usernameController.text.trim().toLowerCase(),
                            email: _emailController.text.trim().toLowerCase(),
                            role: _role ?? 'Super Admin',
                            status: _isActive ? 'Active' : 'Inactive',
                            lastActive: 'Never',
                            isSuperAdmin: (_role ?? '') == 'Super Admin',
                          );
                          Navigator.pop(context, {
                            'user': newUser,
                            'password': _passwordController.text,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add User'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.scaffoldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late String _role;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username.isNotEmpty ? widget.user.username : widget.user.email.split('@').first);
    _emailController = TextEditingController(text: widget.user.email);
    _role = widget.user.role;
    _isActive = widget.user.status == 'Active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final isSuper = widget.user.isSuperAdmin || widget.user.role.toLowerCase() == 'super admin';

    final availableRoles = adminState.userRoles.isNotEmpty
        ? adminState.userRoles.map((r) => r.roleName).toList()
        : ['Super Admin'];

    if (!availableRoles.contains(_role)) {
      _role = availableRoles.first;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit User Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                _buildLabel(context, tr('Full Name')),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'Full Name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                ),
                const SizedBox(height: 14),

                _buildLabel(context, 'Username'),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'Username (for login)'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter username' : null,
                ),
                const SizedBox(height: 14),

                _buildLabel(context, tr('Email Address')),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(context, 'Email Address'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter email';
                    if (!val.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildLabel(context, 'Assigned Role'),
                DropdownButtonFormField<String>(
                  value: _role,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(context, ''),
                  items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: isSuper
                      ? null // Super Admin cannot change their own primary role
                      : (val) {
                          if (val != null) setState(() => _role = val);
                        },
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Account Active',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: context.success,
                      onChanged: isSuper
                          ? null // Super Admin cannot be deactivated
                          : (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final updatedUser = widget.user.copyWith(
                            name: _nameController.text.trim(),
                            username: _usernameController.text.trim().toLowerCase(),
                            email: _emailController.text.trim(),
                            role: _role,
                            status: _isActive ? 'Active' : 'Inactive',
                          );
                          await ref.read(adminProvider.notifier).updateUser(updatedUser);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('User account updated successfully.')),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.primaryColor,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(tr('Save Changes')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.scaffoldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
    );
  }
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _ResetPasswordDialog({required this.user});

  @override
  ConsumerState<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.lock_reset_rounded, color: Colors.amber),
          const SizedBox(width: 10),
          Text('Reset Password', style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set new password for ${widget.user.name} (${widget.user.email}):',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'New Password (min 6 chars)',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: context.scaffoldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscure,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: context.scaffoldBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(adminProvider.notifier).resetUserPassword(
                widget.user.id,
                _passwordController.text,
              );
              Navigator.pop(context);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Password for "${widget.user.name}" updated successfully.'),
                  backgroundColor: context.success,
                ),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to reset password: $e'),
                  backgroundColor: context.error,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update Password'),
        ),
      ],
    );
  }
}
