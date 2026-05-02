import 'dart:async';
import 'dart:math';
import '../models/peer.dart';
import '../services/discovery_service.dart';

/// Mock discovery service that simulates peers appearing/disappearing.
///
/// Used for Mac/Web development so the UI can be tested at 120fps
/// without needing a real Android device or Wi-Fi Aware hardware.
class MockDiscoveryService implements DiscoveryService {
  final _random = Random();
  StreamController<List<Peer>>? _controller;
  Timer? _ticker;
  final List<Peer> _activePeers = [];
  final Set<String> _connectedPeerIds = {};

  // Pool of fake peer names for realistic simulation.
  static const _peerNames = [
    'Arjun\'s Galaxy S24',
    'Priya\'s Pixel 9',
    'Rahul\'s OnePlus 13',
    'Sneha\'s Moto Edge',
    'Vikram\'s Samsung Tab',
    'Ananya\'s Redmi Note',
    'Karthik\'s Realme GT',
    'Divya\'s Nothing Phone',
  ];

  static const _deviceTypes = [
    'phone',
    'phone',
    'phone',
    'tablet',
    'phone',
    'phone',
    'phone',
    'phone',
  ];

  @override
  Stream<List<Peer>> discoverPeers() {
    _controller?.close();
    _ticker?.cancel();

    _controller = StreamController<List<Peer>>.broadcast();
    _activePeers.clear();

    // Emit initial empty state.
    _controller!.add(List.unmodifiable(_activePeers));

    // Simulate peers appearing one-by-one over time.
    var peerIndex = 0;
    _ticker = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (peerIndex < _peerNames.length && _random.nextDouble() > 0.2) {
        _activePeers.add(Peer(
          id: 'mock_peer_$peerIndex',
          name: _peerNames[peerIndex],
          deviceType: _deviceTypes[peerIndex],
          signalStrength: 0.3 + _random.nextDouble() * 0.7,
          isConnected: _connectedPeerIds.contains('mock_peer_$peerIndex'),
        ));
        peerIndex++;
      }

      // Randomly fluctuate signal strengths for realism.
      for (var i = 0; i < _activePeers.length; i++) {
        final peer = _activePeers[i];
        final delta = (_random.nextDouble() - 0.5) * 0.15;
        _activePeers[i] = peer.copyWith(
          signalStrength: (peer.signalStrength + delta).clamp(0.1, 1.0),
          isConnected: _connectedPeerIds.contains(peer.id),
        );
      }

      if (!_controller!.isClosed) {
        _controller!.add(List.unmodifiable(_activePeers));
      }
    });

    return _controller!.stream;
  }

  @override
  Future<void> stopDiscovery() async {
    _ticker?.cancel();
    _ticker = null;
    _controller?.close();
    _controller = null;
    _activePeers.clear();
  }

  @override
  Future<bool> connectToPeer(String peerId) async {
    // Simulate a short connection delay.
    await Future.delayed(const Duration(milliseconds: 800));
    _connectedPeerIds.add(peerId);

    // Update the peer's connected state in the active list.
    for (var i = 0; i < _activePeers.length; i++) {
      if (_activePeers[i].id == peerId) {
        _activePeers[i] = _activePeers[i].copyWith(isConnected: true);
        break;
      }
    }

    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(List.unmodifiable(_activePeers));
    }
    return true;
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _connectedPeerIds.remove(peerId);

    for (var i = 0; i < _activePeers.length; i++) {
      if (_activePeers[i].id == peerId) {
        _activePeers[i] = _activePeers[i].copyWith(isConnected: false);
        break;
      }
    }

    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(List.unmodifiable(_activePeers));
    }
  }
}
