import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current command text being typed.
final commandTextProvider = StateProvider<String>((ref) => '');

/// History of commands executed in this session.
final commandHistoryProvider = StateProvider<List<String>>((ref) => [
      'Bu faturayı hesapla',
      'Bu metni özetle',
      'Toplantı notlarını düzenle',
    ]);

/// Whether an AI command is currently being processed.
final commandLoadingProvider = StateProvider<bool>((ref) => false);

/// The latest AI command response (null when no response yet).
final commandResponseProvider = StateProvider<String?>((ref) => null);
