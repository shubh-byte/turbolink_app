import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import '../core/themes/industrial_theme.dart';
import '../core/themes/cyberpunk_theme.dart';
import '../core/themes/minimalist_theme.dart';
import '../core/themes/ocean_theme.dart';

/// Defines the overall aesthetic of the UI.
enum Aesthetic {
  industrial,
  cyberpunk,
  minimalist,
  ocean,
}

extension AestheticExtension on Aesthetic {
  String get displayName {
    switch (this) {
      case Aesthetic.industrial:
        return 'Industrial Tech';
      case Aesthetic.cyberpunk:
        return 'Cyberpunk';
      case Aesthetic.minimalist:
        return 'Minimalist';
      case Aesthetic.ocean:
        return 'Ocean Depths';
    }
  }

  ThemeData getTheme(Brightness brightness) {
    switch (this) {
      case Aesthetic.industrial:
        return IndustrialTheme.build(brightness);
      case Aesthetic.cyberpunk:
        return CyberpunkTheme.build(brightness);
      case Aesthetic.minimalist:
        return MinimalistTheme.build(brightness);
      case Aesthetic.ocean:
        return OceanTheme.build(brightness);
    }
  }
}

/// Provider to switch between Aesthetics.
final aestheticProvider = StateNotifierProvider<AestheticNotifier, Aesthetic>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return AestheticNotifier(settingsService);
});

class AestheticNotifier extends StateNotifier<Aesthetic> {
  final SettingsService _settingsService;

  AestheticNotifier(this._settingsService) : super(_settingsService.getAesthetic());

  void setAesthetic(Aesthetic aesthetic) {
    state = aesthetic;
    _settingsService.setAesthetic(aesthetic);
  }
}
