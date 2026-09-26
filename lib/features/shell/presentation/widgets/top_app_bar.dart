import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:intl/intl.dart';
import 'spotlight_search_dialog.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/core/widgets/app_logo.dart';
import 'sync_options_dialog.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final StatefulNavigationShell navigationShell;
  final bool isMobile;

  const TopAppBar({
    super.key,
    required this.navigationShell,
    this.isMobile = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  String _getBreadcrumbText(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Finance & Accounts';
      case 2:
        return 'Clients & Relations';
      case 3:
        return 'Projects & Operations';
      case 4:
        return 'HR & Employees';
      case 5:
        return 'Inventory & Assets';
      case 6:
        return 'Finance Reports';
      case 7:
        return 'Reports & Analytics';
      case 8:
        return 'Administration';
      default:
        return 'Dashboard';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeIndex = navigationShell.currentIndex;
    final adminState = ref.watch(adminProvider);
    final currentUser = adminState.currentUser;
    final tr = ref.watch(translationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final mobileMode = isMobile || screenWidth < 768;
    final compactDesktop = !mobileMode && screenWidth < 1500;

    return Container(
      height: mobileMode ? 60 : 70,
      decoration: BoxDecoration(
        color: context.topBarBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: mobileMode ? 12 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Left: Hamburger (if mobile) + Company Logo + Breadcrumbs / Title
          if (mobileMode)
            Expanded(
              child: Row(
                children: [
                  Builder(
                    builder: (scaffoldContext) => Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        color: context.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                      ),
                    ),
                  ),
                  // Mobile HH Tech Hub Company Logo
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.92)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const AppLogo(
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      tr(_getBreadcrumbText(activeIndex)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Text(
                    'ERP',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: context.textMuted,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      tr(_getBreadcrumbText(activeIndex)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          // Right components: Search, Notification, Profile
          if (mobileMode) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Spotlight Search Interactive Trigger
                IconButton(
                  icon: Icon(Icons.search, color: context.textSecondary, size: 20),
                  tooltip: tr('Search ERP'),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (context) => const SpotlightSearchDialog(),
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Manual Cloud Sync Button (Mobile)
                const _TopBarSyncButton(isMobile: true),
                const SizedBox(width: 8),

                // Mobile Profile / Actions Menu
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  tooltip: 'Options',
                  color: theme.cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.border, width: 1),
                  ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(currentUser?.name ?? 'Guest User'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'logout') {
                      ref.read(adminProvider.notifier).logout();
                    } else if (value == 'theme') {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    } else if (value == 'en' || value == 'ur' || value == 'ru') {
                      ref.read(languageProvider.notifier).setLanguage(value);
                    }
                  },
                  itemBuilder: (context) {
                    final themeMode = ref.read(themeModeProvider);
                    final isDark = themeMode.value == ThemeMode.dark;
                    return [
                      PopupMenuItem<String>(
                        value: 'profile_info',
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? 'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            if (currentUser?.email != null &&
                                currentUser!.email.isNotEmpty &&
                                currentUser.email.toLowerCase() != (currentUser.name.toLowerCase()) &&
                                currentUser.email.contains('@'))
                              Text(
                                currentUser.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            const Divider(),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18, color: context.primaryColor),
                            const SizedBox(width: 8),
                            Text(isDark ? 'Light Mode' : 'Dark Mode', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'en',
                        child: Row(
                          children: [
                            const Text('🇺🇸', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('English', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'ur',
                        child: Row(
                          children: [
                            const Text('🇵🇰', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('اردو (Asan)', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'ru',
                        child: Row(
                          children: [
                            const Text('✍️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('Roman Urdu', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: context.error),
                            const SizedBox(width: 8),
                            Text('Sign Out', style: TextStyle(color: context.error)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ] else ...[
            const SizedBox(width: 16),
            // Spotlight Search Interactive Trigger
            GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => const SpotlightSearchDialog(),
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: compactDesktop ? 280 : 360,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: IgnorePointer(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: tr('Search ERP (e.g. Clients, Transactions)...'),
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: context.textMuted,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: context.textMuted,
                                ),
                                suffixIcon: Container(
                                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: context.border),
                                  ),
                                  child: Text(
                                    'Ctrl + K',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Auto Explain Toggle Button
              Consumer(
                builder: (context, ref, child) {
                  final isAutoExplain = ref.watch(autoExplainProvider);
                  return Tooltip(
                    message: isAutoExplain ? 'Disable Auto Explain' : 'Enable Auto Explain',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAutoExplain ? context.primaryColor.withValues(alpha: 0.1) : (context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAutoExplain ? context.primaryColor : context.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAutoExplain ? Icons.tips_and_updates : Icons.tips_and_updates_outlined,
                            size: 16,
                            color: isAutoExplain ? context.primaryColor : context.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          if (!compactDesktop)
                            Text(
                              'Auto Explain',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAutoExplain ? context.primaryColor : context.textPrimary,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Switch(
                            value: isAutoExplain,
                            onChanged: (val) => ref.read(autoExplainProvider.notifier).toggle(val),
                            activeThumbColor: context.primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Theme Toggle Button
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  final isDark = themeMode.value == ThemeMode.dark;
                  
                  return Tooltip(
                    message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                    child: InkWell(
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111827) : context.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.border,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 20,
                          color: isDark ? Colors.amber : context.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Language Switcher Dropdown
              Consumer(
                builder: (context, ref, child) {
                  final currentLang = ref.watch(languageProvider);
                  
                  String getLanguageLabel(String code) {
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
                    tooltip: 'Change Language / زبان تبدیل کریں',
                    color: Theme.of(context).cardColor,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: context.border, width: 1),
                    ),
                    offset: const Offset(0, 50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate, size: 18, color: context.primaryColor),
                          const SizedBox(width: 6),
                          if (!compactDesktop) ...[
                            Text(
                              getLanguageLabel(currentLang),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: context.textSecondary),
                          ],
                        ],
                      ),
                    ),
                    onSelected: (langCode) {
                      ref.read(languageProvider.notifier).setLanguage(langCode);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            const Text('🇺🇸', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Text('English', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ur',
                        child: Row(
                          children: [
                            const Text('🇵🇰', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Text('اردو (Asan)', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ru',
                        child: Row(
                          children: [
                            const Text('✍️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Text('Roman Urdu', style: TextStyle(color: context.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 14),

              // Manual Cloud Sync Button (Desktop)
              const _TopBarSyncButton(isMobile: false),
              const SizedBox(width: 14),
              
              // Vertical Divider
              Container(
                width: 1,
                height: 36,
                color: context.border,
              ),
              const SizedBox(width: 24),
              
              // User Profile Section (Interactive Sign Out menu)
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                tooltip: 'Profile options',
                color: theme.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: context.border, width: 1),
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!compactDesktop)
                            Text(
                              currentUser?.name ?? 'Admin',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Avatar with initials
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getInitials(currentUser?.name ?? 'Admin'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    ref.read(adminProvider.notifier).logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'profile_info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.name ?? 'Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        if (currentUser?.email != null &&
                            currentUser!.email.isNotEmpty &&
                            currentUser.email.toLowerCase() != (currentUser.name.toLowerCase()) &&
                            currentUser.email.contains('@'))
                          Text(
                            currentUser.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        const Divider(),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 18,
                          color: context.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: context.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    ),
    );
  }
}

class _TopBarSyncButton extends ConsumerStatefulWidget {
  final bool isMobile;
  const _TopBarSyncButton({required this.isMobile});

  @override
  ConsumerState<_TopBarSyncButton> createState() => _TopBarSyncButtonState();
}

class _TopBarSyncButtonState extends ConsumerState<_TopBarSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerSync(BuildContext ctx, {bool force = false, bool pushOnly = false}) async {
    final messenger = ScaffoldMessenger.of(ctx);
    final notifier = ref.read(cloudSyncStateProvider.notifier);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pushOnly
                    ? 'Pushing local changes to cloud...'
                    : (force ? 'Force pushing all records to cloud...' : 'Syncing data with cloud (Pull & Push)...'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      if (pushOnly) {
        await notifier.pushChangesOnly();
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: const Text('Push complete! Local changes pushed to cloud.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } else if (force) {
        await notifier.forceSync();
      } else {
        await notifier.syncNow();
      }
    } catch (e) {
      debugPrint('Sync trigger error: $e');
    }

    if (!mounted) return;
    final state = ref.read(cloudSyncStateProvider);
    messenger.clearSnackBars();
    if (state.status == SyncStatus.error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(state.message ?? 'Sync failed or server error.'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            state.syncedCount > 0
                ? (force ? 'Force push complete! ${state.syncedCount} records pushed.' : 'Sync complete! ${state.syncedCount} changes synced.')
                : (force ? 'Force push complete! All records up to date.' : 'Sync complete! Everything is up to date.'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Never';
    return DateFormat('hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(cloudSyncStateProvider);
    final isSyncing = syncState.status == SyncStatus.syncing;

    if (isSyncing) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
        _animController.reset();
      }
    }

    Color statusColor;
    if (isSyncing) {
      statusColor = context.primaryColor;
    } else if (syncState.status == SyncStatus.error) {
      statusColor = context.error;
    } else if (syncState.lastSyncedAt != null) {
      statusColor = Colors.green.shade600;
    } else {
      statusColor = context.textSecondary;
    }

    return widget.isMobile
        ? Tooltip(
            message: isSyncing
                ? 'Syncing in progress...'
                : 'Cloud Sync Options (Tap for Pull & Push)\nLast: ${_formatTime(syncState.lastSyncedAt)}',
            child: InkWell(
              onTap: isSyncing ? null : () => showCloudSyncOptions(context, ref),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _animController.value * 2 * 3.14159,
                          child: Icon(
                            Icons.sync,
                            color: statusColor,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      color: statusColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border.all(
                color: isSyncing ? context.primaryColor.withValues(alpha: 0.5) : context.border,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: isSyncing ? null : () => _triggerSync(context),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animController.value * 2 * 3.14159,
                              child: Icon(
                                Icons.sync,
                                color: statusColor,
                                size: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSyncing ? 'Syncing...' : 'Sync Now',
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
                Container(
                  width: 1,
                  height: 16,
                  color: context.border,
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sync Options\nLast: ${_formatTime(syncState.lastSyncedAt)}',
                  offset: const Offset(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: context.border, width: 1),
                  ),
                  color: context.cardBg,
                  onSelected: (value) {
                    if (value == 'sync_now') {
                      _triggerSync(context, force: false);
                    } else if (value == 'force_sync') {
                      _triggerSync(context, force: true);
                    } else if (value == 'push_changes') {
                      _triggerSync(context, pushOnly: true);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cloud_done_outlined, size: 16, color: statusColor),
                              const SizedBox(width: 8),
                              Text(
                                'Cloud Sync (Manual)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: context.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last Synced: ${_formatTime(syncState.lastSyncedAt)}',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                          if (syncState.message != null && syncState.message!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              syncState.message!,
                              style: TextStyle(fontSize: 11, color: statusColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Divider(),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'sync_now',
                      enabled: !isSyncing,
                      child: Row(
                        children: [
                          Icon(Icons.sync, size: 18, color: context.primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            'Sync Now (Pull & Push)',
                            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'force_sync',
                      enabled: !isSyncing,
                      child: Row(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 18, color: context.primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            'Force Push All (Local to Cloud)',
                            style: TextStyle(color: context.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'push_changes',
                      enabled: !isSyncing,
                      child: Row(
                        children: [
                          Icon(Icons.upload_file_rounded, size: 18, color: context.primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            'Push Changes Only',
                            style: TextStyle(color: context.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
