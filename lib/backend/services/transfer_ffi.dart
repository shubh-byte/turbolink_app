import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import '../models/peer.dart';
import '../models/transfer.dart';
import 'transfer_service.dart';
import '../native/turbolink_ffi.dart';

/// FFI-backed native transfer service.
/// Uses the C++ Native Engine (libturbolink_engine.so) for zero-copy I/O.
class FfiTransferService implements TransferService {
  static const _discoveryChannel = MethodChannel('turbolink/discovery');

  final _transfers = <String, Transfer>{};
  final _transferListController = StreamController<List<Transfer>>.broadcast();

  // Each transfer gets its own StreamController for progress updates.
  final _progressControllers = <String, StreamController<Transfer>>{};

  int _nextTransferId = 1;

  FfiTransferService() {
    TurboLinkEngine.init();
  }

  void dispose() {
    TurboLinkEngine.shutdown();
    _transferListController.close();
    for (var c in _progressControllers.values) {
      c.close();
    }
  }

  void _broadcastList() {
    _transferListController.add(_transfers.values.toList());
  }

  void _updateTransfer(Transfer t) {
    _transfers[t.id] = t;
    _progressControllers[t.id]?.add(t);
    _broadcastList();
  }

  @override
  Stream<List<Transfer>> getTransfers() {
    return _transferListController.stream;
  }

  @override
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String fileUri,
    required String fileName,
    required int fileSizeBytes,
  }) {
    final transferIdStr = 'tx_${_nextTransferId++}';
    final numericId = _nextTransferId - 1;

    final controller = StreamController<Transfer>.broadcast();
    _progressControllers[transferIdStr] = controller;

    var transfer = Transfer(
      id: transferIdStr,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      status: TransferStatus.queued,
      direction: TransferDirection.sending,
      peerId: peerId,
      peerName: peerName,
    );
    _updateTransfer(transfer);

    // Launch async initialization.
    _startSend(numericId, transferIdStr, peerId, fileUri, fileSizeBytes, fileName).catchError((e) {
      transfer = transfer.copyWith(status: TransferStatus.failed);
      _updateTransfer(transfer);
    });

    return controller.stream;
  }

  Future<void> _startSend(int numericId, String transferIdStr, String peerId,
      String fileUri, int fileSizeBytes, String fileName) async {
    // 1. Resolve peer IP via MethodChannel (Kotlin Discovery layer)
    final connectionInfo = await _discoveryChannel.invokeMapMethod<String, dynamic>(
      'getConnectionInfo',
      {'peerId': peerId},
    );

    if (connectionInfo == null) {
      throw Exception('Failed to resolve peer connection info');
    }

    final peerIp = connectionInfo['ip'] as String?;
    final peerPort = connectionInfo['port'] as int? ?? 42069; // Default UDP port
    final sharedKeyBase64 = connectionInfo['key'] as String?; // Optional derived key

    if (peerIp == null) {
      throw Exception('Peer IP is null');
    }

    // 2. Open file descriptor via ContentResolver
    final fd = await _discoveryChannel.invokeMethod<int>(
      'openFileDescriptor',
      {'uri': fileUri, 'mode': 'r'},
    );

    if (fd == null || fd < 0) {
      throw Exception('Failed to open file descriptor for $fileUri');
    }

    // 3. Prepare FFI arguments
    final pFileName = fileName.toNativeUtf8();
    final pPeerIp = peerIp.toNativeUtf8();

    // Default key if none provided (32 bytes)
    final keyBytes = Uint8List(32);
    // TODO: decode sharedKeyBase64 if needed
    final pKey = calloc<Uint8>(32);
    for (int i = 0; i < 32; i++) {
      pKey[i] = keyBytes[i];
    }

    // Callbacks. Since Dart FFI callbacks cannot have state/closures easily,
    // we use a ReceivePort for the engine to send progress ticks back to Dart's main isolate.
    // For now, to keep it simple, we use a polling mechanism via tl_get_stats.
    
    // Instead of passing C function pointers, we poll stats periodically
    // from Dart while the C++ thread does the heavy lifting.
    
    // Kick off the C++ thread
    final result = TurboLinkEngine.sendFile(
      numericId,
      fd,
      fileSizeBytes,
      pFileName,
      pPeerIp,
      peerPort,
      pKey,
      Pointer.fromAddress(0), // null onProgress
      Pointer.fromAddress(0), // null onError
    );

    calloc.free(pFileName);
    calloc.free(pPeerIp);
    calloc.free(pKey);

    if (result < 0) {
      throw Exception('TurboLinkEngine.sendFile returned $result');
    }

    var t = _transfers[transferIdStr]!;
    t = t.copyWith(status: TransferStatus.active);
    _updateTransfer(t);

    // Poll for progress
    _pollProgress(numericId, transferIdStr);
  }

  void _pollProgress(int numericId, String transferIdStr) {
    final pProgress = calloc<Double>();
    final pSpeed = calloc<Double>();

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      var t = _transfers[transferIdStr];
      if (t == null || t.status != TransferStatus.active) {
        timer.cancel();
        calloc.free(pProgress);
        calloc.free(pSpeed);
        return;
      }

      final res = TurboLinkEngine.getStats(numericId, pProgress, pSpeed);
      if (res < 0) {
        // Transfer finished or not found
        t = t.copyWith(progress: 1.0, status: TransferStatus.completed);
        _updateTransfer(t);
        timer.cancel();
        calloc.free(pProgress);
        calloc.free(pSpeed);
        return;
      }

      final progress = pProgress.value;
      final speed = pSpeed.value;

      t = t.copyWith(progress: progress, speedBytesPerSec: speed);
      _updateTransfer(t);

      if (progress >= 1.0) {
        t = t.copyWith(status: TransferStatus.completed);
        _updateTransfer(t);
        timer.cancel();
        calloc.free(pProgress);
        calloc.free(pSpeed);
      }
    });
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    final t = _transfers[transferId];
    if (t != null) {
      if (transferId.startsWith('tx_')) {
        final numericId = int.tryParse(transferId.substring(3));
        if (numericId != null) {
          TurboLinkEngine.cancelTransfer(numericId);
        }
      }
      _updateTransfer(t.copyWith(status: TransferStatus.failed));
    }
  }

  @override
  Future<void> pauseTransfer(String transferId) async {
    // FFI UDP stream pausing not yet implemented in engine.
  }

  @override
  Future<void> resumeTransfer(String transferId) async {
    // FFI UDP stream resuming not yet implemented in engine.
  }

  @override
  void startListeningForFiles(Peer peer) async {
    // Determine a random/fixed receive port. For this demo, we'll use 42069.
    final listenPort = 42069;
    
    // Assign a unique transfer ID for the incoming file.
    final transferIdStr = 'rx_${_nextTransferId++}';
    final numericId = _nextTransferId - 1;

    final controller = StreamController<Transfer>.broadcast();
    _progressControllers[transferIdStr] = controller;

    // We don't know the file name or size yet, so we use placeholders.
    var transfer = Transfer(
      id: transferIdStr,
      fileName: 'Incoming File...',
      fileSizeBytes: 1024 * 1024, // placeholder
      status: TransferStatus.queued,
      direction: TransferDirection.receiving,
      peerId: peer.id,
      peerName: peer.name,
    );
    _updateTransfer(transfer);

    // Call the engine's receive_file method
    final pSaveDir = '/sdcard/Download'.toNativeUtf8();
    final pKey = calloc<Uint8>(32);
    // TODO: Use actual shared key if available.
    
    final result = TurboLinkEngine.receiveFile(
      numericId,
      listenPort,
      pSaveDir,
      pKey,
      Pointer.fromAddress(0), // onProgress null
      Pointer.fromAddress(0), // onComplete null
      Pointer.fromAddress(0), // onError null
    );

    calloc.free(pSaveDir);
    calloc.free(pKey);

    if (result < 0) {
      transfer = transfer.copyWith(status: TransferStatus.failed);
      _updateTransfer(transfer);
      return;
    }

    transfer = transfer.copyWith(status: TransferStatus.active);
    _updateTransfer(transfer);

    // Poll for progress from the C++ engine
    _pollProgress(numericId, transferIdStr);
  }
}
