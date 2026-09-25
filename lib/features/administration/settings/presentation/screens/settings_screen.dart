import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/theme/theme_provider.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/app_logo.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;
    final theme = Theme.of(context);
    final appearanceAsync = ref.watch(appearanceProvider);
    final appearance = appearanceAsync.value ?? AppearanceSettings(
      themeMode: themeMode,
      accentColor: context.primaryColor,
      backgroundTheme: 'Cyber Sapphire',
    );

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/settings'),

          // Screen Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, outerConstraints) {
                final isMobile = outerConstraints.maxWidth < 1000;
                final pagePadding = isMobile ? 16.0 : 24.0;

                // Build Appearance Settings card
                Widget appearanceCard = GlassCard(
                  title: tr('Appearance Settings'),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dark Theme Mode Switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dark Theme Mode',
                                    style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reduces eye strain in low-light environments.',
                                    style: TextStyle(color: context.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: themeMode == ThemeMode.dark,
                              activeThumbColor: appearance.accentColor,
                              onChanged: (val) {
                                ref.read(themeModeProvider.notifier).toggleTheme();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: context.border),
                        const SizedBox(height: 20),

                        // Premium Color Accents Header
                        Text(
                          'Premium Color Accents',
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Horizontal list of 10 Color Accent chips
                        Wrap(
                          spacing: isMobile ? 8 : 12,
                          runSpacing: isMobile ? 8 : 12,
                          children: [
                            {'name': 'Royal Violet', 'color': const Color(0xFF7C3AED)},
                            {'name': 'Emerald Mint', 'color': const Color(0xFF059669)},
                            {'name': 'Ocean Breeze', 'color': const Color(0xFF0284C7)},
                            {'name': 'Amber Gold', 'color': const Color(0xFFD97706)},
                            {'name': 'Rose Crimson', 'color': const Color(0xFFF43F5E)},
                            {'name': 'Slate Cobalt', 'color': const Color(0xFF3B82F6)},
                            {'name': 'Sunset Coral', 'color': const Color(0xFFF97316)},
                            {'name': 'Teal Forest', 'color': const Color(0xFF14B8A6)},
                            {'name': 'Midnight Lavender', 'color': const Color(0xFFA855F7)},
                            {'name': 'Silver Steel', 'color': const Color(0xFF6B7280)},
                          ].map((item) {
                            final colorName = item['name'] as String;
                            final colorVal = item['color'] as Color;
                            final isSelected = appearance.accentColor == colorVal;

                            return InkWell(
                              onTap: () {
                                ref.read(appearanceProvider.notifier).setAccentColor(colorVal);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorVal.withValues(alpha: 0.1)
                                      : context.scaffoldBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? colorVal : context.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colorVal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      colorName,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: isMobile ? 11 : 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: context.border),
                        const SizedBox(height: 20),

                        // Background Themes Header
                        Text(
                          'Background Themes',
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Horizontal list of 10 Theme selector chips
                        Wrap(
                          spacing: isMobile ? 8 : 12,
                          runSpacing: isMobile ? 8 : 12,
                          children: [
                            {'name': 'Alabaster Pearl', 'color': const Color(0xFFF8FAFC)},
                            {'name': 'Nordic Frost', 'color': const Color(0xFFEAEFF5)},
                            {'name': 'Sakura Blossom', 'color': const Color(0xFFFAF6F0)},
                            {'name': 'Cyber Sapphire', 'color': const Color(0xFF0A0F1D)},
                            {'name': 'Amethyst Eclipse', 'color': const Color(0xFF0C0A12)},
                            {'name': 'Arctic Charcoal', 'color': const Color(0xFF0E1117)},
                            {'name': 'Deep Pine', 'color': const Color(0xFF081C1D)},
                            {'name': 'Obsidian Eclipse', 'color': const Color(0xFF000000)},
                            {'name': 'Dracula Velvet', 'color': const Color(0xFF1E1E2E)},
                            {'name': 'Mocha Desert', 'color': const Color(0xFF1E1A16)},
                          ].map((item) {
                            final themeName = item['name'] as String;
                            final isSelected = appearance.backgroundTheme == themeName;
                            final indicatorBg = item['color'] as Color;

                            return InkWell(
                              onTap: () {
                                ref.read(appearanceProvider.notifier).setBackgroundTheme(themeName);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 8 : 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? appearance.accentColor.withValues(alpha: 0.1)
                                      : context.scaffoldBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? appearance.accentColor : context.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: indicatorBg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      themeName,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: isMobile ? 11 : 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );

                // Build Credentials card
                const Widget credentialsCard = _ChangeCredentialsCard();

                return SingleChildScrollView(
                  key: const PageStorageKey('settings_scroll_key'),
                  padding: EdgeInsets.all(pagePadding),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title, Subtitle and Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Global System Settings',
                                    style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.displaySmall)?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: context.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Configure portal appearance themes and administrator credentials.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: context.border, width: 1),
                                ),
                                child: const AppLogo(
                                  height: 60,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // On mobile: Credentials first, Appearance second
                        // On desktop: Appearance first, Credentials second
                        if (isMobile) ...[
                          credentialsCard,
                          const SizedBox(height: 20),
                          appearanceCard,
                        ] else ...[
                          appearanceCard,
                          const SizedBox(height: 24),
                          credentialsCard,
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeCredentialsCard extends ConsumerStatefulWidget {
  const _ChangeCredentialsCard();

  @override
  ConsumerState<_ChangeCredentialsCard> createState() => _ChangeCredentialsCardState();
}

class _ChangeCredentialsCardState extends ConsumerState<_ChangeCredentialsCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).getAdminUsername().then((name) {
        if (mounted) {
          setState(() {
            _newUsernameController.text = name;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _buildDecoration({
    required BuildContext context,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
      prefixIcon: Icon(prefixIcon, size: 18, color: context.primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: context.scaffoldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.error),
      ),
    );
  }

  Future<void> _handleUpdateCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentPass = _currentPasswordController.text;
      final newUsername = _newUsernameController.text.trim();
      final newPass = _newPasswordController.text;

      final canChangeUsername = ref.read(adminProvider.notifier).canCurrentUserChangeUsername();
      final canChangePassword = ref.read(adminProvider.notifier).canCurrentUserChangePassword();
      final currentUsername = await ref.read(adminProvider.notifier).getAdminUsername();

      if (newUsername.toLowerCase() != currentUsername.toLowerCase() && !canChangeUsername) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Access Denied: Your assigned role does not have permission to change username.'),
              backgroundColor: context.error,
            ),
          );
        }
        return;
      }

      if (newPass.isNotEmpty && !canChangePassword) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Access Denied: Your assigned role does not have permission to change password.'),
              backgroundColor: context.error,
            ),
          );
        }
        return;
      }

      // 1. Verify previous / current password permission
      final isAllowed = await ref.read(adminProvider.notifier).verifyCurrentPassword(currentPass);
      if (!isAllowed) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Permission Denied: Previous password is incorrect. Credentials cannot be updated.'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.error,
            ),
          );
        }
        return;
      }

      // 2. Change credentials
      final success = await ref.read(adminProvider.notifier).changeCredentials(
        currentPassword: currentPass,
        newUsername: newUsername,
        newPassword: newPass.isNotEmpty ? newPass : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Credentials updated successfully! Use your new username and password for future logins.'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update credentials. Please verify your current password or role permissions.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating credentials: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final appearanceAsync = ref.watch(appearanceProvider);
    final appearance = appearanceAsync.value;
    final accentColor = appearance?.accentColor ?? context.primaryColor;
    final canChangeUsername = ref.watch(adminProvider.notifier).canCurrentUserChangeUsername();
    final canChangePassword = ref.watch(adminProvider.notifier).canCurrentUserChangePassword();
    final allRestricted = !canChangeUsername && !canChangePassword;

    return GlassCard(
      title: tr('User Credentials & Password Management'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_person_outlined, size: 20, color: context.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrative Password & Username Security',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'System requires your previous password permission before applying changes. Once updated, new credentials will be required for all future system logins.',
                            style: TextStyle(color: context.textSecondary, fontSize: 11, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (allRestricted)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Credential Modification Restricted: Role-based users cannot change username or password. Only Super Admin has authority to modify or reset credentials.',
                          style: TextStyle(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // Responsive Layout for Inputs
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;

                  Widget currentPassField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text('Current / Previous Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary))),
                          const SizedBox(width: 4),
                          Text('*', style: TextStyle(color: context.error, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        enabled: !allRestricted,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildDecoration(
                          context: context,
                          hint: 'Enter your existing password (default: 123456)',
                          prefixIcon: Icons.key_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18, color: context.textMuted),
                            onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                        ),
                        validator: (val) {
                          if (allRestricted) return null;
                          if (val == null || val.isEmpty) {
                            return 'Current password is required to verify permission';
                          }
                          return null;
                        },
                      ),
                    ],
                  );

                  Widget newUsernameField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text('New Username / Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary))),
                          if (canChangeUsername) ...[
                            const SizedBox(width: 4),
                            Text('*', style: TextStyle(color: context.error, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _newUsernameController,
                        enabled: canChangeUsername,
                        style: TextStyle(color: canChangeUsername ? context.textPrimary : context.textMuted, fontSize: 13),
                        decoration: _buildDecoration(
                          context: context,
                          hint: canChangeUsername ? 'e.g. admin or haseeb' : 'Username editing restricted for your role',
                          prefixIcon: canChangeUsername ? Icons.person_outline : Icons.lock_outline,
                          suffixIcon: !canChangeUsername ? Icon(Icons.lock, size: 16, color: context.textMuted) : null,
                        ),
                        validator: (val) {
                          if (!canChangeUsername) return null;
                          if (val == null || val.trim().isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ],
                  );

                  Widget newPasswordField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Password (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        enabled: canChangePassword,
                        style: TextStyle(color: canChangePassword ? context.textPrimary : context.textMuted, fontSize: 13),
                        decoration: _buildDecoration(
                          context: context,
                          hint: canChangePassword ? 'Leave blank to keep existing password' : 'Password change restricted for your role',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: canChangePassword
                              ? IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18, color: context.textMuted),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                )
                              : Icon(Icons.lock, size: 16, color: context.textMuted),
                        ),
                        validator: (val) {
                          if (!canChangePassword) return null;
                          if (val != null && val.isNotEmpty && val.length < 6) {
                            return 'New password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  );

                  Widget confirmPasswordField = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        enabled: canChangePassword,
                        style: TextStyle(color: canChangePassword ? context.textPrimary : context.textMuted, fontSize: 13),
                        decoration: _buildDecoration(
                          context: context,
                          hint: canChangePassword ? 'Re-enter new password to confirm' : 'Password change restricted for your role',
                          prefixIcon: Icons.lock_reset,
                          suffixIcon: canChangePassword
                              ? IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: context.textMuted),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                )
                              : Icon(Icons.lock, size: 16, color: context.textMuted),
                        ),
                        validator: (val) {
                          if (!canChangePassword) return null;
                          if (_newPasswordController.text.isNotEmpty && val != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  );

                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: currentPassField),
                            const SizedBox(width: 16),
                            Expanded(child: newUsernameField),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: newPasswordField),
                            const SizedBox(width: 16),
                            Expanded(child: confirmPasswordField),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        currentPassField,
                        const SizedBox(height: 14),
                        newUsernameField,
                        const SizedBox(height: 14),
                        newPasswordField,
                        const SizedBox(height: 14),
                        confirmPasswordField,
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              // Submit Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || allRestricted) ? null : _handleUpdateCredentials,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.shield_outlined, size: 18),
                  label: Text(
                    _isLoading ? 'Verifying & Updating...' : 'Update Credentials',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

