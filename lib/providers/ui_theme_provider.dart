import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';

/// Defines the overall aesthetic of the UI.
enum UIAesthetic {
  industrial,
  cyberpunk,
  minimalist,
  ocean,
}

extension UIAestheticExtension on UIAesthetic {
  String get displayName {
    switch (this) {
      case UIAesthetic.industrial:
        return 'Industrial Tech';
      case UIAesthetic.cyberpunk:
        return 'Cyberpunk';
      case UIAesthetic.minimalist:
        return 'Minimalist';
      case UIAesthetic.ocean:
        return 'Ocean Depths';
    }
  }
}

/// Provider to switch between UI Aesthetics.
final uiThemeProvider = StateNotifierProvider<UIAestheticNotifier, UIAesthetic>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return UIAestheticNotifier(settingsService);
});

class UIAestheticNotifier extends StateNotifier<UIAesthetic> {
  final SettingsService _settingsService;

  UIAestheticNotifier(this._settingsService) : super(_settingsService.getUIAesthetic());

  void setAesthetic(UIAesthetic aesthetic) {
    state = aesthetic;
    _settingsService.setUIAesthetic(aesthetic);
  }
}
