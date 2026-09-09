import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode controller. Persists the user's choice so it
/// survives app restarts.
class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static const _prefsKey = 'theme_mode';

  /// Call once at startup, before runApp, to restore the saved preference.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'dark') {
      mode.value = ThemeMode.dark;
    } else {
      mode.value = ThemeMode.light;
    }
  }

  static Future<void> setDark(bool isDark) async {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, isDark ? 'dark' : 'light');
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}