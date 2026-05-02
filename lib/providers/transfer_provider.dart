import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/transfer.dart';
import '../backend/services/transfer_service.dart';
import '../backend/mock/transfer.dart';
import '../backend/services/transfer_android.dart';
import 'mock_mode_provider.dart';

/// Provides the active TransferService instance (Demo vs Release).
final transferServiceProvider = Provider<TransferService>((ref) {
  final isMock = ref.watch(mockModeProvider);
  if (isMock) {
    return MockTransferService(
      getMinSpeed: () => ref.read(mockMinSpeedProvider),
      getMaxSpeed: () => ref.read(mockMaxSpeedProvider),
    );
  }
  
  if (defaultTargetPlatform == TargetPlatform.android) {
    return NativeTransferService();
  }
  
  return MockTransferService(
    getMinSpeed: () => ref.read(mockMinSpeedProvider),
    getMaxSpeed: () => ref.read(mockMaxSpeedProvider),
  );
});

/// Provides the stream of all transfers (active + completed) based on active mode.
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  final service = ref.watch(transferServiceProvider);

  ref.onDispose(() {
    // service.dispose(); if needed
  });
  
  return service.getTransfers();
});
