import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui_theme_provider.dart';

/// Provider for the SharedPreferences instance.
/// Must be initialized in main() before runApp().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

class SettingsService {
  final SharedPreferences prefs;
  SettingsService(this.prefs);

  static const String _themeModeKey = 'theme_mode';
  static const String _uiAestheticKey = 'ui_aesthetic';

  // ── Theme Mode ──────────────────────────────────────────────
  ThemeMode getThemeMode() {
    final val = prefs.getString(_themeModeKey);
    if (val == 'dark') return ThemeMode.dark;
    if (val == 'light') return ThemeMode.light;
    return ThemeMode.dark; // Default
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await prefs.setString(_themeModeKey, mode.name);
  }

  // ── UI Aesthetic ────────────────────────────────────────────
  UIAesthetic getUIAesthetic() {
    final val = prefs.getString(_uiAestheticKey);
    if (val != null) {
      return UIAesthetic.values.firstWhere(
        (e) => e.name == val,
        orElse: () => UIAesthetic.industrial,
      );
    }
    return UIAesthetic.industrial; // Default
  }

  Future<void> setUIAesthetic(UIAesthetic aesthetic) async {
    await prefs.setString(_uiAestheticKey, aesthetic.name);
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});
