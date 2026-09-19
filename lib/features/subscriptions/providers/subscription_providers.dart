import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current user subscription tier.
final currentSubscriptionProvider =
    StateProvider<String>((ref) => 'free');

/// Available subscription plans with details.
final availablePlansProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      'id': 'lifetime_pro',
      'name': 'Lifetime Pro',
      'price': '\$19.99',
      'period': 'Tek Seferlik',
      'features': [
        'Sınırsız AI komut',
        'Sınırsız OCR tarama',
        'Gelişmiş analiz',
        'Öncelikli destek',
        'Reklamsız deneyim',
      ],
      'highlighted': true,
    },
    {
      'id': 'ai_premium',
      'name': 'AI Premium',
      'price': '\$4.99',
      'period': 'Aylık',
      'features': [
        'Günlük 100 AI komut',
        'Günlük 50 OCR tarama',
        'Temel analiz',
        'E-posta desteği',
      ],
      'highlighted': false,
    },
  ];
});
