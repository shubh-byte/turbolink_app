import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/transfer.dart';
import '../core/di/service_locator.dart';

/// Provides the stream of all transfers (active + completed).
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  // If the service needs explicit cleanup of listeners, add it here.
  // For the mock, we don't have a stop method, but we add the hook for QA readiness.
  ref.onDispose(() {
    // ServiceLocator().transferService.dispose(); 
  });
  return ServiceLocator().transferService.getTransfers();
});
