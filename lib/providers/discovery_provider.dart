import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/peer.dart';
import '../backend/services/discovery_service.dart';
import '../backend/mock/discovery.dart';
import '../backend/services/discovery_android.dart';
import 'mock_mode_provider.dart';

/// Provides the active DiscoveryService instance (Demo vs Release).
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock) return MockDiscoveryService();
  
  if (defaultTargetPlatform == TargetPlatform.android) {
    return NativeDiscoveryService();
  }
  
  return MockDiscoveryService();
});

/// Provides the stream of discovered peers based on the active mode (Demo/Release).
final discoveryStreamProvider = StreamProvider<List<Peer>>((ref) {
  final service = ref.watch(discoveryServiceProvider);

  ref.onDispose(() {
    service.stopDiscovery();
  });
  
  return service.discoverPeers();
});

/// Tracks which peer ID is currently being connected to (loading state).
final connectingPeerIdProvider = StateProvider<String?>((ref) => null);
