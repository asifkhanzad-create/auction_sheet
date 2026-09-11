import 'package:flutter/material.dart';

/// Self-contained theme for the admin panel.
///
/// The admin app is a separate entry point (admin_main.dart) and does
/// NOT share the customer app's theme. By default it now follows the
/// system brightness (light on light devices, dark on dark devices) —
/// no manual toggle. Same purple accent in both modes for visual
/// continuity with the customer app.
class AdminTheme {
  // Brand accent — same purple as the customer app.
  static const Color purple = Color(0xFF6C63FF);

  // Light surfaces (matches the original admin panel look).
  static const Color lightBg = Color(0xFFFAFAFC);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFE0E0E8);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Colors.black54;
  static const Color lightFieldFill = Color(0xFFF5F5F8);
  static const Color lightLilac = Color(0xFFEDEBFF);

  // Dark surfaces — soft charcoal/navy, not AMOLED black.
  static const Color darkBg = Color(0xFF17171F);
  static const Color darkCard = Color(0xFF1E1E2B);
  static const Color darkBorder = Color(0xFF2E2E3E);
  static const Color darkTextPrimary = Color(0xFFF2F2F7);
  static const Color darkTextSecondary = Color(0xFFA3A3B5);
  static const Color darkFieldFill = Color(0xFF23232F);
  static const Color darkLilac = Color(0xFF2A2740);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightTextPrimary,
        elevation: 0,
      ),
      dividerColor: lightBorder,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        brightness: Brightness.dark,
        surface: darkCard,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkTextPrimary,
        elevation: 0,
      ),
      dividerColor: darkBorder,
    );
  }
}

/// Convenience accessor that returns the right palette based on the
/// active ThemeData's brightness — mirrors the customer app's pattern
/// so screens switch automatically with the system setting.
extension AdminThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AdminTheme.darkBg : AdminTheme.lightBg;
  Color get card => isDark ? AdminTheme.darkCard : AdminTheme.lightCard;
  Color get border => isDark ? AdminTheme.darkBorder : AdminTheme.lightBorder;
  Color get textPrimary =>
      isDark ? AdminTheme.darkTextPrimary : AdminTheme.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AdminTheme.darkTextSecondary : AdminTheme.lightTextSecondary;
  Color get fieldFill =>
      isDark ? AdminTheme.darkFieldFill : AdminTheme.lightFieldFill;
  Color get lilac => isDark ? AdminTheme.darkLilac : AdminTheme.lightLilac;
}
