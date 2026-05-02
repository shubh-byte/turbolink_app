import '../models/peer.dart';

/// Abstract interface for peer discovery.
///
/// Agent 1 will implement the real version using Wi-Fi Aware/Direct.
/// The mock version simulates peer discovery for Mac/Web development.
abstract class DiscoveryService {
  /// Start scanning for nearby peers. Returns a stream of discovered peers.
  Stream<List<Peer>> discoverPeers();

  /// Stop the discovery scan.
  Future<void> stopDiscovery();

  /// Connect to a specific peer by ID.
  Future<bool> connectToPeer(String peerId);

  /// Disconnect from a connected peer.
  Future<void> disconnectFromPeer(String peerId);
}
