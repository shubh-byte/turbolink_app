import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aesthetic_provider.dart';

enum ConnectivityMode {
  performance, // Wi-Fi Direct (P2P)
  connected,   // Wi-Fi Aware (NAN)
}

/// Provider for the SharedPreferences instance.
/// Must be initialized in main() before runApp().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main');
});

class SettingsService {
  final SharedPreferences prefs;
  SettingsService(this.prefs);

  static const String _themeModeKey = 'theme_mode';
  static const String _aestheticKey = 'ui_aesthetic';
  static const String _connectivityModeKey = 'connectivity_mode';

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

  // ── Aesthetic ────────────────────────────────────────────
  Aesthetic getAesthetic() {
    final val = prefs.getString(_aestheticKey);
    if (val != null) {
      return Aesthetic.values.firstWhere(
        (e) => e.name == val,
        orElse: () => Aesthetic.industrial,
      );
    }
    return Aesthetic.industrial; // Default
  }

  Future<void> setAesthetic(Aesthetic aesthetic) async {
    await prefs.setString(_aestheticKey, aesthetic.name);
  }

  // ── Connectivity Mode ───────────────────────────────────────
  ConnectivityMode getConnectivityMode() {
    final val = prefs.getString(_connectivityModeKey);
    if (val != null) {
      return ConnectivityMode.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ConnectivityMode.performance,
      );
    }
    return ConnectivityMode.performance; // Default
  }

  Future<void> setConnectivityMode(ConnectivityMode mode) async {
    await prefs.setString(_connectivityModeKey, mode.name);
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});
