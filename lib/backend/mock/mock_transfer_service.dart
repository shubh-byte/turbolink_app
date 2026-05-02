import 'dart:async';
import 'dart:math';
import '../models/transfer.dart';
import '../services/transfer_service.dart';

/// Mock transfer service that simulates file transfers with realistic progress.
///
/// Fakes speed fluctuations and progress updates so the UI can be
/// fully tested on Mac/Web without real file I/O.
class MockTransferService implements TransferService {
  final _random = Random();
  final List<Transfer> _transfers = [];
  final _transfersController = StreamController<List<Transfer>>.broadcast();
  final Map<String, Timer> _activeTimers = {};
  int _nextId = 0;

  @override
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String filePath,
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
    _emitTransfers();

    // Simulate progress ticking up over time.
    var progress = 0.0;
    final timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      // Simulate variable speed: 5-80 MB/s.
      final speedMbps = 5.0 + _random.nextDouble() * 75.0;
      final speedBps = speedMbps * 1024 * 1024;
      final chunkBytes = speedBps * 0.1; // per 100ms tick
      progress += chunkBytes / fileSizeBytes;

      if (progress >= 1.0) {
        progress = 1.0;
        transfer = transfer.copyWith(
          progress: 1.0,
          speedBytesPerSec: 0,
          status: TransferStatus.completed,
        );
        _updateTransfer(transfer);
        controller.add(transfer);
        controller.close();
        t.cancel();
        _activeTimers.remove(id);
        return;
      }

      transfer = transfer.copyWith(
        progress: progress,
        speedBytesPerSec: speedBps,
      );
      _updateTransfer(transfer);
      controller.add(transfer);
    });

    _activeTimers[id] = timer;
    return controller.stream;
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
      );
      _emitTransfers();
    }
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
