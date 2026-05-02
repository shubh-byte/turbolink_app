import 'package:flutter/foundation.dart';
import '../../backend/services/discovery_service.dart';
import '../../backend/services/transfer_service.dart';
import '../../backend/mock/mock_discovery_service.dart';
import '../../backend/mock/mock_transfer_service.dart';

/// Simple service locator for Dependency Injection.
///
/// On non-Android platforms (Mac, Web, Linux), this returns mock services.
/// On Android, Agent 1 will register the real Kotlin-backed services here.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  factory ServiceLocator() => _instance;
  ServiceLocator._();

  DiscoveryService? _discoveryService;
  TransferService? _transferService;

  /// Register a custom discovery service (used by Agent 1 for real backend).
  void registerDiscoveryService(DiscoveryService service) {
    _discoveryService = service;
  }

  /// Register a custom transfer service (used by Agent 1 for real backend).
  void registerTransferService(TransferService service) {
    _transferService = service;
  }

  /// Get the discovery service. Falls back to mock on non-Android.
  DiscoveryService get discoveryService {
    if (_discoveryService != null) return _discoveryService!;

    // On Android with real backend registered, this won't be reached.
    // For Mac/Web/Linux dev, always use mock.
    if (defaultTargetPlatform != TargetPlatform.android || _discoveryService == null) {
      _discoveryService = MockDiscoveryService();
    }
    return _discoveryService!;
  }

  /// Get the transfer service. Falls back to mock on non-Android.
  TransferService get transferService {
    if (_transferService != null) return _transferService!;

    if (defaultTargetPlatform != TargetPlatform.android || _transferService == null) {
      _transferService = MockTransferService();
    }
    return _transferService!;
  }
}
