import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── SharedPreferences keys ───────────────────────────
const _kThemeKey = 'app_theme_mode';
const _kAccentKey = 'app_accent_color';
const _kBgThemeKey = 'app_background_theme';

class AppearanceSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final String backgroundTheme; // 'Alabaster Pearl', 'Cyber Sapphire', 'Amethyst Eclipse', 'Arctic Charcoal'

  AppearanceSettings({
    required this.themeMode,
    required this.accentColor,
    required this.backgroundTheme,
  });

  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    String? backgroundTheme,
  }) {
    return AppearanceSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
    );
  }
}

class AppearanceNotifier extends AsyncNotifier<AppearanceSettings> {
  @override
  Future<AppearanceSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_kThemeKey) ?? 'dark';
    final savedAccent = prefs.getString(_kAccentKey) ?? '0xFF2563EB'; // default Soft Blue
    final savedBg = prefs.getString(_kBgThemeKey) ?? 'Cyber Sapphire'; // default Cyber Sapphire

    return AppearanceSettings(
      themeMode: savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light,
      accentColor: Color(int.parse(savedAccent)),
      backgroundTheme: savedBg,
    );
  }

  Future<void> setAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final hexString = '0x${color.toARGB32().toRadixString(16).toUpperCase()}';
    await prefs.setString(_kAccentKey, hexString);
    ref.invalidateSelf();
  }

  Future<void> setBackgroundTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBgThemeKey, themeName);

    // Sync themeMode
    final isLight = themeName == 'Alabaster Pearl' ||
                    themeName == 'Nordic Frost' ||
                    themeName == 'Sakura Blossom';
    final nextMode = isLight ? ThemeMode.light : ThemeMode.dark;
    await prefs.setString(_kThemeKey, nextMode == ThemeMode.dark ? 'dark' : 'light');

    ref.invalidate(themeModeProvider);
    ref.invalidateSelf();
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, 'dark');
    await prefs.setString(_kAccentKey, '0xFF2563EB');
    await prefs.setString(_kBgThemeKey, 'Cyber Sapphire');

    ref.invalidate(themeModeProvider);
    ref.invalidateSelf();
  }
}

final appearanceProvider = AsyncNotifierProvider<AppearanceNotifier, AppearanceSettings>(() {
  return AppearanceNotifier();
});

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark; // Default to dark mode
  }

  Future<void> toggleTheme() async {
    final current = state.value ?? ThemeMode.dark;
    final next = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _save(next);
    state = AsyncData(next);

    // Sync appearance background theme
    final prefs = await SharedPreferences.getInstance();
    if (next == ThemeMode.light) {
      await prefs.setString(_kBgThemeKey, 'Alabaster Pearl');
    } else {
      await prefs.setString(_kBgThemeKey, 'Cyber Sapphire');
    }
    ref.invalidate(appearanceProvider);
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _save(mode);
    state = AsyncData(mode);

    // Sync appearance background theme
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString(_kBgThemeKey, 'Alabaster Pearl');
    } else {
      await prefs.setString(_kBgThemeKey, 'Cyber Sapphire');
    }
    ref.invalidate(appearanceProvider);
  }

  Future<void> _save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
