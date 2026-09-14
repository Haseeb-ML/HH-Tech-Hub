import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThemeColors {
  final Color scaffoldBg;
  final Color cardBg;
  final Color sidebarBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const ThemeColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.sidebarBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });
}

const Map<String, ThemeColors> backgroundThemes = {
  'Alabaster Pearl': ThemeColors(
    scaffoldBg: Color(0xFFF8FAFC),
    cardBg: Color(0xFFFFFFFF),
    sidebarBg: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    border: Color(0xFFE2E8F0),
  ),
  'Nordic Frost': ThemeColors(
    scaffoldBg: Color(0xFFEAEFF5),
    cardBg: Color(0xFFF3F6FA),
    sidebarBg: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    border: Color(0xFFCBD5E1),
  ),
  'Sakura Blossom': ThemeColors(
    scaffoldBg: Color(0xFFFAF6F0),
    cardBg: Color(0xFFFFFFFF),
    sidebarBg: Color(0xFFF5EFE6),
    textPrimary: Color(0xFF2C2520),
    textSecondary: Color(0xFF5C524B),
    border: Color(0xFFE6DFD5),
  ),
  'Cyber Sapphire': ThemeColors(
    scaffoldBg: Color(0xFF0A0F1D),
    cardBg: Color(0xFF111827),
    sidebarBg: Color(0xFF0D1322),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF1E293B),
  ),
  'Amethyst Eclipse': ThemeColors(
    scaffoldBg: Color(0xFF0C0A12),
    cardBg: Color(0xFF13101E),
    sidebarBg: Color(0xFF0F0C18),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFA78BFA),
    border: Color(0xFF2E2248),
  ),
  'Arctic Charcoal': ThemeColors(
    scaffoldBg: Color(0xFF0E1117),
    cardBg: Color(0xFF161A22),
    sidebarBg: Color(0xFF10141B),
    textPrimary: Color(0xFFE6EDF0),
    textSecondary: Color(0xFF8B949E),
    border: Color(0xFF21262D),
  ),
  'Deep Pine': ThemeColors(
    scaffoldBg: Color(0xFF081C1D),
    cardBg: Color(0xFF0C292A),
    sidebarBg: Color(0xFF0A2223),
    textPrimary: Color(0xFFE0F2F1),
    textSecondary: Color(0xFF80CBC4),
    border: Color(0xFF153F41),
  ),
  'Obsidian Eclipse': ThemeColors(
    scaffoldBg: Color(0xFF000000),
    cardBg: Color(0xFF0A0A0A),
    sidebarBg: Color(0xFF121212),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
    border: Color(0xFF1E1E1E),
  ),
  'Dracula Velvet': ThemeColors(
    scaffoldBg: Color(0xFF1E1E2E),
    cardBg: Color(0xFF252538),
    sidebarBg: Color(0xFF181825),
    textPrimary: Color(0xFFCDD6F4),
    textSecondary: Color(0xFFBAC2DE),
    border: Color(0xFF313244),
  ),
  'Mocha Desert': ThemeColors(
    scaffoldBg: Color(0xFF1E1A16),
    cardBg: Color(0xFF28231E),
    sidebarBg: Color(0xFF181512),
    textPrimary: Color(0xFFD4C5B9),
    textSecondary: Color(0xFFA8998C),
    border: Color(0xFF3C342E),
  ),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with user credentials
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  final container = ProviderContainer();
  // Initialize SQLite Database
  await container.read(databaseServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.dark;

    final appearanceAsync = ref.watch(appearanceProvider);
    
    // Simple loader while theme loads
    if (appearanceAsync.value == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final appearance = appearanceAsync.value ?? AppearanceSettings(
      themeMode: ThemeMode.dark,
      accentColor: const Color(0xFF2563EB),
      backgroundTheme: 'Cyber Sapphire',
    );

    final themeColors = backgroundThemes[appearance.backgroundTheme] ?? backgroundThemes['Cyber Sapphire']!;

    final lightTheme = AppTheme.getTheme(
      brightness: Brightness.light,
      primaryColor: appearance.accentColor,
      scaffoldBg: themeColors.scaffoldBg,
      cardBg: themeColors.cardBg,
      sidebarBg: themeColors.sidebarBg,
      textPrimary: themeColors.textPrimary,
      textSecondary: themeColors.textSecondary,
      border: themeColors.border,
    );

    final darkTheme = AppTheme.getTheme(
      brightness: Brightness.dark,
      primaryColor: appearance.accentColor,
      scaffoldBg: themeColors.scaffoldBg,
      cardBg: themeColors.cardBg,
      sidebarBg: themeColors.sidebarBg,
      textPrimary: themeColors.textPrimary,
      textSecondary: themeColors.textSecondary,
      border: themeColors.border,
    );

    return MaterialApp.router(
      title: 'HH TECH HUB',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
