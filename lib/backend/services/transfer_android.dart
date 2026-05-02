import 'dart:async';
import 'package:flutter/services.dart';
import '../models/transfer.dart';
import 'transfer_service.dart';

/// Real transfer service backed by the native Kotlin backend.
///
/// Uses [MethodChannel] for commands (sendFile/cancelTransfer) and
/// [EventChannel] streams for progress and the full transfer list.
/// Only active on Android — other platforms use [MockTransferService].
class NativeTransferService implements TransferService {
  static const _methodChannel = MethodChannel('turbolink/transfer');
  static const _progressChannel = EventChannel('turbolink/transfer/progress');
  static const _allChannel = EventChannel('turbolink/transfer/all');

  @override
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String fileUri,
    required String fileName,
    required int fileSizeBytes,
  }) {
    // Start the transfer on the native side.
    _methodChannel.invokeMethod('sendFile', {
      'peerId': peerId,
      'peerName': peerName,
      'fileUri': fileUri,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
    });

    // Listen for per-transfer progress events.
    return _progressChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return Transfer(
        id: map['id'] as String,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        speedBytesPerSec: (map['speedBytesPerSec'] as num?)?.toDouble() ?? 0.0,
        status: _parseStatus(map['status'] as String?),
        direction: TransferDirection.sending,
        peerId: peerId,
        peerName: peerName,
      );
    });
  }

  @override
  Stream<List<Transfer>> getTransfers() {
    return _allChannel.receiveBroadcastStream().map((event) {
      final rawList = event as List<dynamic>;
      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return Transfer(
          id: map['id'] as String,
          fileName: map['fileName'] as String,
          fileSizeBytes: (map['fileSizeBytes'] as num).toInt(),
          progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
          speedBytesPerSec: (map['speedBytesPerSec'] as num?)?.toDouble() ?? 0.0,
          status: _parseStatus(map['status'] as String?),
          direction: _parseDirection(map['direction'] as String?),
          peerId: map['peerId'] as String,
          peerName: map['peerName'] as String,
        );
      }).toList();
    });
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    await _methodChannel.invokeMethod(
      'cancelTransfer',
      {'transferId': transferId},
    );
  }

  @override
  Future<void> pauseTransfer(String transferId) async {
    await _methodChannel.invokeMethod(
      'pauseTransfer',
      {'transferId': transferId},
    );
  }

  @override
  Future<void> resumeTransfer(String transferId) async {
    await _methodChannel.invokeMethod(
      'resumeTransfer',
      {'transferId': transferId},
    );
  }

  TransferStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return TransferStatus.active;
      case 'paused':
        return TransferStatus.paused;
      case 'completed':
        return TransferStatus.completed;
      case 'failed':
        return TransferStatus.failed;
      default:
        return TransferStatus.queued;
    }
  }

  TransferDirection _parseDirection(String? direction) {
    switch (direction) {
      case 'receiving':
        return TransferDirection.receiving;
      default:
        return TransferDirection.sending;
    }
  }
}
