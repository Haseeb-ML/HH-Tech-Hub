import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return getTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBg: AppColors.background,
      cardBg: AppColors.cardBg,
      sidebarBg: AppColors.sidebarBg,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      border: AppColors.border,
    );
  }

  static ThemeData get darkTheme {
    return getTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBg: const Color(0xFF090D16),
      cardBg: const Color(0xFF111827),
      sidebarBg: const Color(0xFF0B0F19),
      textPrimary: const Color(0xFFF9FAFB),
      textSecondary: const Color(0xFF9CA3AF),
      border: const Color(0xFF1F2937),
    );
  }

  static ThemeData getTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color scaffoldBg,
    required Color cardBg,
    required Color sidebarBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final textMuted = brightness == Brightness.dark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final divider = brightness == Brightness.dark ? border.withValues(alpha: 0.8) : const Color(0xFFF3F4F6);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: brightness,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardBg,
      canvasColor: sidebarBg, // Sidebar uses canvasColor
      dialogTheme: DialogThemeData(backgroundColor: cardBg),
      dividerColor: divider,
      
      // Text Theme
      textTheme: GoogleFonts.interTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ).copyWith(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: textSecondary, height: 1.5),
        labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: textMuted),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: brightness == Brightness.dark ? const Color(0xFF111827) : Colors.white,
          fontSize: 11
        ),
      ),
    );
  }
}
