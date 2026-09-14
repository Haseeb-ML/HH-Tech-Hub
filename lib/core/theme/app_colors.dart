import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2563EB); // Soft Blue Accent
  static const Color primaryLight = Color(0xFFEFF6FF); // Very Light Blue for Hover/Selects
  
  // Backgrounds
  static const Color background = Color(0xFFF9FAFB); // Soft Grayish-White
  static const Color cardBg = Color(0xFFFFFFFF); // Pure White for Cards/Sheets
  static const Color sidebarBg = Color(0xFFFFFFFF); // Pure White for Sidebar
  static const Color topBarBg = Color(0xFFFFFFFF); // Pure White for Top Bar
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Dark Slate Gray (High contrast)
  static const Color textSecondary = Color(0xFF4B5563); // Medium Gray for descriptions
  static const Color textMuted = Color(0xFF9CA3AF); // Light Muted Gray
  
  // Accents / Status Colors
  static const Color success = Color(0xFF059669); // Emerald Green for Income/Positive
  static const Color successLight = Color(0xFFECFDF5);
  
  static const Color error = Color(0xFFDC2626); // Soft Red for Expense/Critical Alert
  static const Color errorLight = Color(0xFFFEF2F2);
  
  static const Color warning = Color(0xFFD97706); // Amber for Warning/Low Stock
  static const Color warningLight = Color(0xFFFFFBEB);
  
  static const Color info = Color(0xFF2563EB); // Info soft blue
  static const Color infoLight = Color(0xFFEFF6FF);
  
  // UI Borders & Dividers
  static const Color border = Color(0xFFE5E7EB); // Soft gray border line
  static const Color divider = Color(0xFFF3F4F6); // Even softer divider line
}

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  bool get isDarkMode => theme.brightness == Brightness.dark;

  Color get primaryColor => theme.colorScheme.primary;
  Color get scaffoldBg => theme.scaffoldBackgroundColor;
  Color get cardBg => theme.cardColor;
  Color get sidebarBg => theme.canvasColor;
  Color get topBarBg => isDarkMode ? theme.scaffoldBackgroundColor : theme.cardColor;
  Color get border => isDarkMode ? theme.dividerColor : const Color(0xFFE5E7EB);
  Color get divider => theme.dividerColor;

  Color get textPrimary => theme.textTheme.bodyLarge?.color ?? (isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827));
  Color get textSecondary => theme.textTheme.bodyMedium?.color ?? (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563));
  Color get textMuted => theme.textTheme.labelMedium?.color ?? (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));

  // Status colors
  Color get success => isDarkMode ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get successLight => isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
  
  Color get error => isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  Color get errorLight => isDarkMode ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2);
  
  Color get warning => isDarkMode ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
  Color get warningLight => isDarkMode ? const Color(0xFF78350F) : const Color(0xFFFFFBEB);

  Color get info => isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  Color get infoLight => isDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF);
}
