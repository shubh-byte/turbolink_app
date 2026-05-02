import 'dart:async';
import '../models/peer.dart';
import 'discovery_service.dart';

/// Native implementation of DiscoveryService for Release Mode.
/// 
/// This stub will eventually use MethodChannels to communicate with 
/// the actual Android Kotlin Wi-Fi Direct backend built by Agent 1.
class NativeDiscoveryService implements DiscoveryService {
  final _controller = StreamController<List<Peer>>.broadcast();

  @override
  Stream<List<Peer>> discoverPeers() {
    // Currently a stub. In Release Mode, the radar will show nothing 
    // until the Kotlin backend is fully integrated.
    return _controller.stream;
  }

  @override
  Future<void> stopDiscovery() async {
    // MethodChannel call will go here.
  }

  @override
  Future<bool> connectToPeer(String peerId) async {
    // MethodChannel call will go here.
    return false;
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    // MethodChannel call will go here.
  }
}
