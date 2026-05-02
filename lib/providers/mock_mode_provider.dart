import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to toggle between Mock and Release modes for the prototype.
final mockModeProvider = StateProvider<bool>((ref) => true);

/// Min and Max speed bounds for mock transfers in MB/s
final mockMinSpeedProvider = StateProvider<double>((ref) => 2.0);
final mockMaxSpeedProvider = StateProvider<double>((ref) => 25.0);
