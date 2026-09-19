import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source value text (user input).
final sourceValueProvider = StateProvider<String>((ref) => '');

/// Converted target value text.
final targetValueProvider = StateProvider<String>((ref) => '');

/// Currently selected conversion category.
final selectedCategoryProvider =
    StateProvider<String>((ref) => 'Para Birimi');

/// Source unit code.
final sourceUnitProvider = StateProvider<String>((ref) => 'TRY');

/// Target unit code.
final targetUnitProvider = StateProvider<String>((ref) => 'USD');

/// Available conversion categories.
final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'Para Birimi',
    'Uzunluk',
    'Ağırlık',
    'Sıcaklık',
    'Hacim',
    'Alan',
    'Zaman',
    'Veri',
    'Hız',
  ];
});
