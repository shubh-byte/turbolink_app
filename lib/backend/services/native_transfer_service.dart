import 'dart:async';
import '../models/transfer.dart';
import 'transfer_service.dart';

/// Native implementation of TransferService for Release Mode.
/// 
/// This stub will eventually use MethodChannels to communicate with 
/// the actual Android Kotlin Zero-Copy I/O backend built by Agent 1.
class NativeTransferService implements TransferService {
  final _controller = StreamController<List<Transfer>>.broadcast();

  @override
  Stream<Transfer> sendFile({
    required String peerId,
    required String peerName,
    required String filePath,
    required String fileName,
    required int fileSizeBytes,
  }) {
    // Stub
    return const Stream.empty();
  }

  @override
  Stream<List<Transfer>> getTransfers() {
    // Stub
    return _controller.stream;
  }

  @override
  Future<void> cancelTransfer(String transferId) async {
    // Stub
  }
}
