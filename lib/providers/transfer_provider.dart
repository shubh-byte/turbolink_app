import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/transfer.dart';
import '../core/di/service_locator.dart';

/// Provides the stream of all transfers (active + completed).
final transfersStreamProvider = StreamProvider<List<Transfer>>((ref) {
  return ServiceLocator().transferService.getTransfers();
});
