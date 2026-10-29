import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/widgets/app_logo.dart';
import 'package:software_house_erp/core/routing/app_router.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';

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
  bool _isManualSyncing = false;
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
          final targetPath = getDefaultAllowedPath(adminState);
          context.go(targetPath);
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
    final tr = ref.watch(translationProvider);
    final isMobile = MediaQuery.of(context).size.width < 500;

    // Selective Riverpod watching to prevent unnecessary rebuilds when background sync or audit logs update
    final userRoles = ref.watch(adminProvider.select((s) => s.userRoles));
    final users = ref.watch(adminProvider.select((s) => s.users));

    // Collect Super Admin and only active, actually existing / created roles
    final availableRoles = <String>['Super Admin'];
    for (final r in userRoles) {
      if (!r.isSuperAdmin && r.isActive && !availableRoles.contains(r.roleName)) {
        availableRoles.add(r.roleName);
      }
    }
    for (final u in users) {
      if (!u.isSuperAdmin && u.role.isNotEmpty && u.isActive && !availableRoles.contains(u.role)) {
        availableRoles.add(u.role);
      }
    }

    final isDarkMode = context.isDarkMode;
    final primaryColor = context.primaryColor;
    final infoColor = context.info;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // ── Background Accent Orbs (Optimized for Mobile GPU) ──
          if (!isMobile) ...[
            Positioned(
              top: -150,
              left: -150,
              child: RepaintBoundary(
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: isDarkMode ? 0.12 : 0.05),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              right: -100,
              child: RepaintBoundary(
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: infoColor.withValues(alpha: isDarkMode ? 0.08 : 0.03),
                  ),
                ),
              ),
            ),
          ],

          // ── Login Card Layout ──
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: isMobile ? 16 : 24,
                right: isMobile ? 16 : 24,
                top: isMobile ? 40 : 32,
                bottom: isMobile ? 24 : 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: RepaintBoundary(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 20 : 36),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.06),
                          blurRadius: isMobile ? 12 : 24,
                          offset: const Offset(0, 8),
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
                            child: AppLogo(
                              height: isMobile ? 80 : 180,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in to access your ERP workspace.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),

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
                      _buildInputLabel(tr('Select Role for Clearance')),
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
                          hintText: tr('Select Role for Clearance'),
                          prefixIcon: _getRoleIcon(_selectedRole),
                        ),
                        items: availableRoles.map((roleName) {
                          return DropdownMenuItem<String>(
                            value: roleName,
                            child: Text(
                              roleName,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Username Field
                      _buildInputLabel(tr('Username or Email')),
                      TextFormField(
                        controller: _usernameController,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration(
                          hintText: tr('Please enter username or email'),
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? tr('Please enter username or email')
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildInputLabel(tr('Password')),
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
                            ? tr('Please enter password')
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
                            : Text(
                                tr('Sign In'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

          // ── Top Action Buttons (Sync & Language) ──
          Positioned(
            top: isMobile ? 12 : 24,
            right: isMobile ? 12 : 24,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isManualSyncing
                          ? null
                          : () async {
                              setState(() => _isManualSyncing = true);
                              try {
                                await ref.read(cloudSyncStateProvider.notifier).syncNow();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('Sync complete! Data updated.')),
                                      backgroundColor: Colors.green.shade700,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(tr('Sync failed. Please check connection.')),
                                      backgroundColor: Colors.red.shade700,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isManualSyncing = false);
                              }
                            },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _isManualSyncing
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: context.primaryColor),
                                  )
                                : Icon(Icons.sync, size: 16, color: context.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              tr('Sync Now'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Language Dropdown
                  Consumer(
                    builder: (context, ref, child) {
                      final currentLang = ref.watch(languageProvider);
                      String getLangLabel(String code) {
                        switch (code) {
                          case 'ur':
                            return 'اردو (Asan)';
                          case 'ru':
                            return 'Roman Urdu';
                          default:
                            return 'English';
                        }
                      }

                      return PopupMenuButton<String>(
                        tooltip: tr('Change Language'),
                        color: context.cardBg,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.border),
                        ),
                        offset: const Offset(0, 40),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.translate, size: 16, color: context.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                getLangLabel(currentLang),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 16, color: context.textSecondary),
                            ],
                          ),
                        ),
                        onSelected: (code) {
                          ref.read(languageProvider.notifier).setLanguage(code);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                const Text('🇺🇸', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text('English', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ur',
                            child: Row(
                              children: [
                                const Text('🇵🇰', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text('اردو (Asan)', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'ru',
                            child: Row(
                              children: [
                                const Text('✍️', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text('Roman Urdu', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
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
