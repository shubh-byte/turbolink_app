import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/di/service_locator.dart';
import 'backend/native/native_discovery_service.dart';
import 'backend/native/native_transfer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
    const ProviderScope(
      child: TurboLinkApp(),
    ),
  );
}
