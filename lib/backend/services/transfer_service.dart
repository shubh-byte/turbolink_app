import '../models/transfer.dart';

/// Abstract interface for file transfers.
///
/// Agent 1 will implement the real version using Zero-Copy I/O.
/// The mock version simulates transfers for Mac/Web development.
abstract class TransferService {
  /// Send a file to a connected peer. Returns a stream of transfer progress.
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String fileUri,
    required String fileName,
    required int fileSizeBytes,
  });

  /// Get a stream of all active and recent transfers.
  Stream<List<Transfer>> getTransfers();

  /// Cancel an active transfer.
  Future<void> cancelTransfer(String transferId);

  /// Pause an active transfer.
  Future<void> pauseTransfer(String transferId);

  /// Resume a paused transfer.
  Future<void> resumeTransfer(String transferId);
}
