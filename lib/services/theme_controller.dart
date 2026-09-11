import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode controller. Persists the user's choice so it
/// survives app restarts.
///
/// Three states: System (follows the phone's OS setting — this is the
/// default for a fresh install, so login/signup respect the device's
/// dark/light setting the first time the app is ever opened), Light,
/// and Dark (both explicit overrides set from Profile).
class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _prefsKey = 'theme_mode';

  /// Call once at startup, before runApp, to restore the saved preference.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    switch (saved) {
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      case 'light':
        mode.value = ThemeMode.light;
        break;
      default:
        // No saved preference yet (fresh install) — follow the system.
        mode.value = ThemeMode.system;
    }
  }

  static Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    switch (newMode) {
      case ThemeMode.dark:
        await prefs.setString(_prefsKey, 'dark');
        break;
      case ThemeMode.light:
        await prefs.setString(_prefsKey, 'light');
        break;
      case ThemeMode.system:
        await prefs.setString(_prefsKey, 'system');
        break;
    }
  }

  /// Kept for backward compatibility with any existing callers —
  /// prefer setMode() for the new 3-way picker.
  static Future<void> setDark(bool isDark) =>
      setMode(isDark ? ThemeMode.dark : ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;
}