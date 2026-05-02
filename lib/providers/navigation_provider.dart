import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the application's current navigation index.
final navigationProvider = StateProvider<int>((ref) => 0);
