import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'spotlight_search_dialog.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final StatefulNavigationShell navigationShell;

  const TopAppBar({
    super.key,
    required this.navigationShell,
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

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: context.topBarBg,
        border: Border(
          bottom: BorderSide(color: context.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumbs (Module Title)
          Row(
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
              Text(
                tr(_getBreadcrumbText(activeIndex)),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          
          // Right components: Search, Notification, Profile
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    width: 320,
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
              const SizedBox(width: 24),
              
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
              const SizedBox(width: 24),
              
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
                          Text(
                            currentUser?.name ?? 'Guest User',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            currentUser?.role ?? 'Guest',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500,
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
                          _getInitials(currentUser?.name ?? 'Guest User'),
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
                          currentUser?.name ?? 'Guest User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          currentUser?.email ?? 'guest@hhtech.com',
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
            ),
          ),
        ],
      ),
    );
  }
}
