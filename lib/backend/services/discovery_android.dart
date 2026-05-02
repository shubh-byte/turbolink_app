import 'dart:async';
import 'package:flutter/services.dart';
import '../models/peer.dart';
import 'discovery_service.dart';

/// Real discovery service backed by the native Kotlin backend.
///
/// Uses [MethodChannel] for commands (start/stop/connect) and
/// [EventChannel] for the continuous peer-list stream.
/// Only active on Android — other platforms use [MockDiscoveryService].
class NativeDiscoveryService implements DiscoveryService {
  static const _methodChannel = MethodChannel('turbolink/discovery');
  static const _eventChannel = EventChannel('turbolink/discovery/peers');

  @override
  Stream<List<Peer>> discoverPeers() {
    // Tell the native side to start scanning.
    _methodChannel.invokeMethod('startDiscovery');

    // Listen to the EventChannel for peer updates.
    return _eventChannel.receiveBroadcastStream().map((event) {
      final rawList = event as List<dynamic>;
      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Peer(
          id: map['id'] as String,
          name: map['name'] as String,
          deviceType: (map['deviceType'] as String?) ?? 'phone',
          signalStrength: (map['signalStrength'] as num?)?.toDouble() ?? 0.5,
          isConnected: (map['isConnected'] as bool?) ?? false,
        );
      }).toList();
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await _methodChannel.invokeMethod('stopDiscovery');
  }

  @override
  Future<bool> connectToPeer(String peerId) async {
    final result = await _methodChannel.invokeMethod<bool>(
      'connectToPeer',
      {'peerId': peerId},
    );
    return result ?? false;
  }

  @override
  Future<void> disconnectFromPeer(String peerId) async {
    await _methodChannel.invokeMethod(
      'disconnectFromPeer',
      {'peerId': peerId},
    );
  }

  @override
  Future<void> setDiscoveryMode(String mode) async {
    await _methodChannel.invokeMethod(
      'setMode',
      {'mode': mode},
    );
  }
}
