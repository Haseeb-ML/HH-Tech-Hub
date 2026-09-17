import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/theme/theme_provider.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
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
            child: SingleChildScrollView(
              key: const PageStorageKey('settings_scroll_key'),
              padding: const EdgeInsets.all(24),
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
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Configure portal layout themes, database automatic backups, and security policies.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 1. Theme Configuration
                    GlassCard(
                      title: tr('Appearance Settings'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dark Theme Mode Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
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
                            const Divider(),
                            const SizedBox(height: 20),

                            // Premium Color Accents Header
                            Text(
                              'Premium Color Accents',
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Horizontal list of 10 Color Accent chips
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                            fontSize: 12,
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
                            const Divider(),
                            const SizedBox(height: 20),

                            // Background Themes Header
                            Text(
                              'Background Themes',
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            // Horizontal list of 10 Theme selector chips
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                            fontSize: 12,
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
                    ),
                    const SizedBox(height: 24),

                    // 2. System and Database Backups Configurations
                    GlassCard(
                      title: tr('System & Database Configurations'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Maintenance mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Maintenance Mode',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Temporarily block access to all clients and standard workers during updates.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: state.maintenanceMode,
                                  activeThumbColor: appearance.accentColor,
                                  onChanged: (val) {
                                    ref.read(adminProvider.notifier).updateSettings(maintenanceMode: val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Auto backup interval
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Automatic Database Backup Frequency',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Configure automated database compression backups schedule.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 140,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: state.autoBackupInterval,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: context.scaffoldBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 'Daily', child: Text(tr('Daily'))),
                                      DropdownMenuItem(value: 'Weekly', child: Text(tr('Weekly'))),
                                      DropdownMenuItem(value: 'Monthly', child: Text(tr('Monthly'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).updateSettings(autoBackupInterval: val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Security Settings
                    GlassCard(
                      title: tr('Security & Access Policies'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Session timeout
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Inactivity Session Timeout',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Log administrative users out automatically after inactivity.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 140,
                                  child: DropdownButtonFormField<int>(
                                    initialValue: state.sessionTimeout,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: context.scaffoldBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 15, child: Text(tr('15 Minutes'))),
                                      DropdownMenuItem(value: 30, child: Text(tr('30 Minutes'))),
                                      DropdownMenuItem(value: 60, child: Text(tr('60 Minutes'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).updateSettings(sessionTimeout: val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // MFA Policy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Multi-Factor Authentication (MFA)',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enforce MFA login codes verification for user role profiles.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: state.mfaPolicy,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: context.scaffoldBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 'Disabled', child: Text(tr('Disabled'))),
                                      DropdownMenuItem(value: 'Required for Admins', child: Text(tr('Required (Admins)'))),
                                      DropdownMenuItem(value: 'Required for All Users', child: Text(tr('Required (All)'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).updateSettings(mfaPolicy: val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Audit Retention Policy
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Audit Retention Policy',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Choose how long data logging trails are preserved on database.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 140,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: state.auditRetention,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: context.scaffoldBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: '30 Days', child: Text(tr('30 Days'))),
                                      DropdownMenuItem(value: '90 Days', child: Text(tr('90 Days'))),
                                      DropdownMenuItem(value: '365 Days', child: Text(tr('365 Days'))),
                                      DropdownMenuItem(value: 'Never', child: Text(tr('Never'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).updateSettings(auditRetention: val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Cloud Synchronizations
                    GlassCard(
                      title: tr('Database Sync & Sandbox Configurations'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Data Sync Schedule
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Database Cloud Sync Schedule',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Synchronize local tables and transaction archives with remote cloud backups.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: state.dataSyncSchedule,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: context.scaffoldBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: context.border)),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 'Real-time stream', child: Text(tr('Real-time Stream'))),
                                      DropdownMenuItem(value: 'Every 4 hours', child: Text(tr('Every 4 Hours'))),
                                      DropdownMenuItem(value: 'Manual sync only', child: Text(tr('Manual Sync Only'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(adminProvider.notifier).updateSettings(dataSyncSchedule: val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Developer Sandbox Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'API Developer Sandbox Mode',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Enables mock network sandboxes and verbose error reporting consoles.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: state.developerSandbox,
                                  activeThumbColor: appearance.accentColor,
                                  onChanged: (val) {
                                    ref.read(adminProvider.notifier).updateSettings(developerSandbox: val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Global Email Alerts
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Global Email Alerts',
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Send automated audit logs, alerts, and backup errors via server email.',
                                      style: TextStyle(color: context.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: state.emailNotifications,
                                  activeThumbColor: appearance.accentColor,
                                  onChanged: (val) {
                                    ref.read(adminProvider.notifier).updateSettings(emailNotifications: val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons (Reset & Save)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Reset Theme Settings?'),
                                content: const Text(
                                  'This will revert the color accent, background theme, and light/dark mode back to the original brand defaults.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(tr('Cancel')),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(tr('Reset')),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(appearanceProvider.notifier).resetToDefault();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Theme settings reset to brand defaults.'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: context.info,
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textSecondary,
                            side: BorderSide(color: context.border),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                          label: const Text('Reset to Default', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('System parameters saved successfully.')),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.success,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appearance.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Apply & Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
