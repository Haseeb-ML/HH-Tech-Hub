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

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Nav Tab
          const AdminSubNav(activeRoute: '/administration/users'),
          
          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Account Management',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage administrative portal users and access permission settings.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const _AddUserDialog(),
                          );
                          if (result != null) {
                            final newUser = result['user'] as AdminUser;
                            final password = result['password'] as String;
                            await ref.read(adminProvider.notifier).addUser(newUser, password: password);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("User")} "${newUser.name}" ${tr("added successfully.")}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: successColor,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add, size: 18),
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
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                        columns: [
                          DataColumn(label: Text(tr('Full Name'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(tr('Email Address'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('System Role', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text(tr('Status'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Last Active', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                        ],
                        rows: state.users.map((user) {
                          final isUserActive = user.status == 'Active';
                          
                          // Role colors
                          Color roleColor = context.info;
                          if (user.role == 'System Admin') {
                            roleColor = context.error;
                          } else if (user.role == 'HR Manager') {
                            roleColor = context.success;
                          } else if (user.role == 'Project Manager') {
                            roleColor = context.primaryColor;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: roleColor.withValues(alpha: 0.1),
                                      child: Text(
                                        user.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
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
                                Switch(
                                  value: isUserActive,
                                  activeThumbColor: context.success,
                                  onChanged: (val) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final statusColor = val ? context.success : context.error;
                                    await ref.read(adminProvider.notifier).updateUser(
                                      user.copyWith(status: val ? 'Active' : 'Inactive'),
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${tr("User")} "${user.name}" ${val ? tr("is now Active.") : tr("is now Inactive.")}',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: statusColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              DataCell(Text(user.lastActive, style: TextStyle(color: context.textMuted, fontSize: 12))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, size: 18, color: context.primaryColor),
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
                                      icon: Icon(Icons.delete_outline, size: 18, color: context.error),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        final errorColor = context.error;
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(tr('Delete User Account')),
                                            content: Text('${tr("Are you sure you want to delete administrative account")} "${user.name}"?'),
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
}

class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'System Admin';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
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

              _buildLabel(context, tr('Full Name')),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'e.g. John Doe'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel(context, tr('Email Address')),
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'user@company.com'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter email';
                  if (!val.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(context, tr('Password')),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, '••••••'),
                validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel(context, 'System Access Role'),
              DropdownButtonFormField<String>(
                initialValue: _role,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(context, ''),
                items: const [
                  DropdownMenuItem(value: 'System Admin', child: Text('System Admin')),
                  DropdownMenuItem(value: 'HR Manager', child: Text('HR Manager')),
                  DropdownMenuItem(value: 'Finance Manager', child: Text('Finance Manager')),
                  DropdownMenuItem(value: 'Project Manager', child: Text('Project Manager')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
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
                          id: 'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          role: _role,
                          status: 'Active',
                          lastActive: 'Just Created',
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

class _EditUserDialog extends ConsumerStatefulWidget {
  final AdminUser user;
  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _role;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _role = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
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

              _buildLabel(context, tr('Full Name')),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, tr('Full Name')),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel(context, tr('Email Address')),
              TextFormField(
                controller: _emailController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, tr('Email Address')),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter email';
                  if (!val.contains('@')) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel(context, 'System Access Role'),
              DropdownButtonFormField<String>(
                initialValue: _role,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(context, ''),
                items: const [
                  DropdownMenuItem(value: 'System Admin', child: Text('System Admin')),
                  DropdownMenuItem(value: 'HR Manager', child: Text('HR Manager')),
                  DropdownMenuItem(value: 'Finance Manager', child: Text('Finance Manager')),
                  DropdownMenuItem(value: 'Project Manager', child: Text('Project Manager')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
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
                  Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final updatedUser = widget.user.copyWith(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              role: _role,
                            );
                            ref.read(adminProvider.notifier).updateUser(updatedUser);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('User account updated successfully.')),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.primaryColor,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(tr('Save Changes')),
                      );
                    },
                  ),
                ],
              ),
            ],
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
