import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

/// Provider to manage the application's theme mode (Light / Dark).
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeNotifier(settingsService);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeNotifier(this._settingsService) : super(_settingsService.getThemeMode());

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    _settingsService.setThemeMode(newMode);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    _settingsService.setThemeMode(mode);
  }
}
