import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently active bottom navigation tab index.
/// 0 = Home, 1 = Tools, 2 = Brain (AI Command), 3 = Notes, 4 = Profile
final currentTabIndexProvider = StateProvider<int>((ref) => 0);
