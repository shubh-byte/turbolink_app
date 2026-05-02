import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to toggle between Mock and Release modes for the prototype.
final mockModeProvider = StateProvider<bool>((ref) => true);
