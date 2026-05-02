import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/peer.dart';
import '../core/di/service_locator.dart';

/// Provides the stream of discovered peers from the active discovery service.
final discoveryStreamProvider = StreamProvider<List<Peer>>((ref) {
  return ServiceLocator().discoveryService.discoverPeers();
});

/// Tracks which peer ID is currently being connected to (loading state).
final connectingPeerIdProvider = StateProvider<String?>((ref) => null);
