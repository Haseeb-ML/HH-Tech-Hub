import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/core/widgets/app_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedRole = 'Super Admin';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final adminState = ref.read(adminProvider);
    final availableRoles = <String>['Super Admin'];
    for (final r in adminState.userRoles) {
      if (!r.isSuperAdmin && r.isActive && !availableRoles.contains(r.roleName)) {
        availableRoles.add(r.roleName);
      }
    }
    for (final u in adminState.users) {
      if (!u.isSuperAdmin && u.role.isNotEmpty && u.isActive && !availableRoles.contains(u.role)) {
        availableRoles.add(u.role);
      }
    }

    final effectiveRole = (availableRoles.contains(_selectedRole) ? _selectedRole : availableRoles.firstOrNull) ?? _selectedRole;

    try {
      final success = await ref.read(adminProvider.notifier).login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        selectedRole: effectiveRole,
      );

      if (success) {
        if (mounted) {
          final adminState = ref.read(adminProvider);
          final currentUser = adminState.currentUser;
          if (currentUser != null && !currentUser.isSuperAdmin && !adminState.hasPermission(AppModule.dashboard, PermissionAction.view)) {
            final modulePaths = [
              (AppModule.hr, '/hr/employees'),
              (AppModule.finance, '/finance/income'),
              (AppModule.clients, '/clients'),
              (AppModule.projects, '/projects'),
              (AppModule.inventory, '/inventory'),
              (AppModule.reports, '/reports'),
              (AppModule.administration, '/administration/users'),
            ];
            for (final entry in modulePaths) {
              if (adminState.hasPermission(entry.$1, PermissionAction.view)) {
                context.go(entry.$2);
                return;
              }
            }
          }
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _errorMessage = ref.read(adminProvider).authErrorMessage ?? 'Invalid username/email or password.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  IconData _getRoleIcon(String? role) {
    if (role == null) return Icons.person_outline;
    final lower = role.toLowerCase();
    if (lower.contains('super') || lower.contains('admin')) return Icons.admin_panel_settings_rounded;
    if (lower.contains('hr') || lower.contains('people') || lower.contains('staff')) return Icons.badge_outlined;
    if (lower.contains('finance') || lower.contains('account') || lower.contains('ledger')) return Icons.account_balance_wallet_outlined;
    if (lower.contains('project') || lower.contains('manager')) return Icons.work_outline_rounded;
    if (lower.contains('inventory') || lower.contains('stock') || lower.contains('asset')) return Icons.inventory_2_outlined;
    if (lower.contains('sales') || lower.contains('client')) return Icons.receipt_long_outlined;
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final isMobile = MediaQuery.of(context).size.width < 500;

    // Collect Super Admin and only active, actually existing / created roles
    final availableRoles = <String>['Super Admin'];
    for (final r in adminState.userRoles) {
      if (!r.isSuperAdmin && r.isActive && !availableRoles.contains(r.roleName)) {
        availableRoles.add(r.roleName);
      }
    }
    for (final u in adminState.users) {
      if (!u.isSuperAdmin && u.role.isNotEmpty && u.isActive && !availableRoles.contains(u.role)) {
        availableRoles.add(u.role);
      }
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // ── Beautiful Background Accent Orbs ──
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.primaryColor.withValues(alpha: context.isDarkMode ? 0.15 : 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.info.withValues(alpha: context.isDarkMode ? 0.1 : 0.04),
              ),
            ),
          ),
          
          // ── Login Card Layout ──
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 24 : 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: context.cardBg.withValues(alpha: context.isDarkMode ? 0.75 : 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDarkMode ? 0.4 : 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // Header and logo
                      Center(
                        child: SizedBox(
                          width: isMobile ? 210 : 240,
                          height: isMobile ? 82 : 76,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/logo.png',
                              width: isMobile ? 178 : 204,
                              height: isMobile ? 64 : 58,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const AppLogo(
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'HH TECH HUB ERP',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access your ERP workspace.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Role Selection Dropdown
                      _buildInputLabel('Select Account Role'),
                      DropdownButtonFormField<String>(
                        value: availableRoles.contains(_selectedRole) ? _selectedRole : availableRoles.first,
                        isExpanded: true,
                        dropdownColor: context.cardBg,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Select your role',
                          prefixIcon: _getRoleIcon(_selectedRole),
                        ),
                        items: availableRoles.map((roleName) {
                          return DropdownMenuItem<String>(
                            value: roleName,
                            child: Row(
                              children: [
                                Icon(_getRoleIcon(roleName), size: 16, color: context.primaryColor),
                                const SizedBox(width: 10),
                                Text(
                                  roleName,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Username Field
                      _buildInputLabel('Username / Email'),
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter username or email address',
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter username or email'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildInputLabel('Password'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: context.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter password'
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: context.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      prefixIcon: Icon(prefixIcon, size: 18, color: context.textMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: context.scaffoldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor),
      ),
    );
  }
}
