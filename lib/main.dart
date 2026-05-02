import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'backend/services/native_discovery_service.dart';
import 'backend/services/native_transfer_service.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences before running the app.
  final sharedPrefs = await SharedPreferences.getInstance();

  // On Android, wire up the real Kotlin-backed services.
  // On all other platforms, the ServiceLocator falls back to mocks.
  if (defaultTargetPlatform == TargetPlatform.android) {
    ServiceLocator().registerDiscoveryService(NativeDiscoveryService());
    ServiceLocator().registerTransferService(NativeTransferService());
  }

  // Lock to portrait and set system UI style for immersive dark theme.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF161619),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const RestartWidget(
        child: TurboLinkApp(),
      ),
    ),
  );
}

/// A widget that enables simulating an app restart.
/// Rebuilding this widget with a new Key completely destroys the old widget tree
/// and builds a fresh one from scratch.
class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}
