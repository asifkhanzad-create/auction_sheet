import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared brand colors — used across both light and dark themes so the
/// purple accent stays consistent.
class AppColors {
  static const purple = Color(0xFF6C63FF);

  // Light theme surfaces
  static const lightBg = Color(0xFFFAFAFC);
  static const lightCard = Colors.white;
  static const lightBorder = Color(0xFFE0E0E8);
  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecondary = Colors.black54;
  static const lightFieldFill = Color(0xFFF5F5F8);
  static const lightLilac = Color(0xFFEDEBFF);

  // Dark theme surfaces — soft charcoal/navy, not AMOLED black
  static const darkBg = Color.fromARGB(255, 23, 23, 31);
  static const darkCard = Color(0xFF1E1E2B);
  static const darkBorder = Color(0xFF2E2E3E);
  static const darkTextPrimary = Color(0xFFF2F2F7);
  static const darkTextSecondary = Color(0xFFA3A3B5);
  static const darkFieldFill = Color(0xFF23232F);
  static const darkLilac = Color(0xFF2A2740);
}

class AppTheme {
  static ThemeData light() {
    final baseText = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: baseText.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F6F7),
      cardColor: AppColors.lightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCard,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      dividerColor: AppColors.lightBorder,
    );
  }

  static ThemeData dark() {
    final baseText = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: baseText.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        surface: AppColors.darkCard,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}

/// Convenience accessor so screens can pick the right shade without
/// importing Theme.of(context) boilerplate everywhere.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get card => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get fieldFill => isDark ? AppColors.darkFieldFill : AppColors.lightFieldFill;
  Color get lilac => isDark ? AppColors.darkLilac : AppColors.lightLilac;
}