import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import 'discovery_provider.dart';

class ConnectivityModeNotifier extends StateNotifier<ConnectivityMode> {
  final SettingsService _settings;
  final Ref _ref;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  ConnectivityModeNotifier(this._settings, this._ref) : super(_settings.getConnectivityMode()) {
    _syncToNative(state);
  }

  Future<bool> setMode(ConnectivityMode mode) async {
    if (state == mode) return true;
    
    _isSyncing = true;
    state = mode; // Optimistic update
    
    final success = await _syncToNative(mode);
    
    if (success) {
      await _settings.setConnectivityMode(mode);
    } else {
      // Revert if failed (e.g. hardware not capable)
      state = _settings.getConnectivityMode();
    }
    
    _isSyncing = false;
    return success;
  }

  Future<bool> _syncToNative(ConnectivityMode mode) async {
    try {
      final nativeMode = mode == ConnectivityMode.performance ? 'max_speed' : 'keep_internet';
      await _ref.read(discoveryServiceProvider).setDiscoveryMode(nativeMode);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final connectivityModeProvider = StateNotifierProvider<ConnectivityModeNotifier, ConnectivityMode>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return ConnectivityModeNotifier(settings, ref);
});
