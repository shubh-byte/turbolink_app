import 'dart:async';
import 'dart:math';
import '../models/transfer.dart';
import '../services/transfer_service.dart';

/// Mock transfer service that simulates file transfers with realistic progress.
///
/// Fakes speed fluctuations and progress updates so the UI can be
/// fully tested on Mac/Web without real file I/O.
/// Speed is capped at 25 MB/s in demo mode so transfers are observable.
class MockTransferService implements TransferService {
  final _random = Random();
  final List<Transfer> _transfers = [];
  final _transfersController = StreamController<List<Transfer>>.broadcast();
  final Map<String, Timer> _activeTimers = {};
  final Map<String, _TransferState> _transferStates = {};
  int _nextId = 0;

  @override
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String fileUri,
    required String fileName,
    required int fileSizeBytes,
  }) {
    final id = 'transfer_${_nextId++}';
    final controller = StreamController<Transfer>();

    var transfer = Transfer(
      id: id,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      status: TransferStatus.active,
      direction: TransferDirection.sending,
      peerId: peerId,
      peerName: peerName,
    );

    _transfers.add(transfer);
    _transferStates[id] = _TransferState(
      progress: 0.0,
      controller: controller,
      fileSizeBytes: fileSizeBytes,
    );
    _emitTransfers();

    _startTransferTimer(id);
    return controller.stream;
  }

  void _startTransferTimer(String id) {
    final state = _transferStates[id];
    if (state == null) return;

    final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final currentState = _transferStates[id];
      if (currentState == null) {
        t.cancel();
        return;
      }

      // Cap speed at 25 MB/s. Range: 2-25 MB/s for observable transfers.
      final speedMbps = 2.0 + _random.nextDouble() * 23.0;
      final speedBps = speedMbps * 1024 * 1024;
      final chunkBytes = speedBps * 0.1; // per 100ms tick
      currentState.progress += chunkBytes / currentState.fileSizeBytes;

      if (currentState.progress >= 1.0) {
        currentState.progress = 1.0;
        final completed = _findTransfer(id)!.copyWith(
          progress: 1.0,
          speedBytesPerSec: 0,
          status: TransferStatus.completed,
        );
        _updateTransfer(completed);
        currentState.controller.add(completed);
        currentState.controller.close();
        t.cancel();
        _activeTimers.remove(id);
        _transferStates.remove(id);
        return;
      }

      final updated = _findTransfer(id)!.copyWith(
        progress: currentState.progress,
        speedBytesPerSec: speedBps,
      );
      _updateTransfer(updated);
      currentState.controller.add(updated);
    });

    _activeTimers[id] = timer;
  }

  @override
  Stream<List<Transfer>> getTransfers() {
    // Emit current state immediately, then updates.
    Future.microtask(() => _emitTransfers());
    return _transfersController.stream;
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    _activeTimers[transferId]?.cancel();
    _activeTimers.remove(transferId);

    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx != -1) {
      _transfers[idx] = _transfers[idx].copyWith(
        status: TransferStatus.failed,
        speedBytesPerSec: 0,
      );
      _emitTransfers();
    }

    _transferStates[transferId]?.controller.close();
    _transferStates.remove(transferId);
  }

  @override
  Future<void> pauseTransfer(String transferId) async {
    // Stop the timer but keep the state so we can resume.
    _activeTimers[transferId]?.cancel();
    _activeTimers.remove(transferId);

    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx != -1) {
      _transfers[idx] = _transfers[idx].copyWith(
        status: TransferStatus.paused,
        speedBytesPerSec: 0,
      );
      _emitTransfers();
    }
  }

  @override
  Future<void> resumeTransfer(String transferId) async {
    final idx = _transfers.indexWhere((t) => t.id == transferId);
    if (idx != -1) {
      _transfers[idx] = _transfers[idx].copyWith(
        status: TransferStatus.active,
      );
      _emitTransfers();
      _startTransferTimer(transferId);
    }
  }

  Transfer? _findTransfer(String id) {
    final idx = _transfers.indexWhere((t) => t.id == id);
    return idx != -1 ? _transfers[idx] : null;
  }

  void _updateTransfer(Transfer transfer) {
    final idx = _transfers.indexWhere((t) => t.id == transfer.id);
    if (idx != -1) {
      _transfers[idx] = transfer;
      _emitTransfers();
    }
  }

  void _emitTransfers() {
    if (!_transfersController.isClosed) {
      _transfersController.add(List.unmodifiable(_transfers));
    }
  }
}

/// Internal mutable state for an in-progress transfer.
class _TransferState {
  double progress;
  final StreamController<Transfer> controller;
  final int fileSizeBytes;

  _TransferState({
    required this.progress,
    required this.controller,
    required this.fileSizeBytes,
  });
}
