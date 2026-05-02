import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/peer.dart';
import '../backend/services/discovery_service.dart';
import '../backend/mock/mock_discovery_service.dart';
import '../backend/services/native_discovery_service.dart';
import 'mock_mode_provider.dart';

/// Provides the active DiscoveryService instance (Demo vs Release).
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final isMock = ref.watch(mockModeProvider);
  return isMock ? MockDiscoveryService() : NativeDiscoveryService();
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
