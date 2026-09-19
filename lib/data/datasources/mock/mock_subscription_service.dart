import 'package:omnibrain_ai/data/models/subscription_model.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class MockSubscriptionService {
  SubscriptionModel _currentSubscription = const SubscriptionModel(
    planType: UserPlan.free,
    isActive: true,
    expiresAt: null,
    features: [
      'Günde 5 AI işlemi',
      '10 not saklama',
      '3 belge tarama',
      'Temel OCR',
    ],
  );

  final List<SubscriptionPlanModel> _availablePlans = [
    const SubscriptionPlanModel(
      id: 'plan_free',
      name: 'Ücretsiz',
      price: 0,
      currency: 'USD',
      features: [
        'Günde 5 AI işlemi',
        '10 not saklama',
        '3 belge tarama',
        'Temel OCR',
      ],
      planType: UserPlan.free,
    ),
    const SubscriptionPlanModel(
      id: 'plan_lifetime',
      name: 'Ömür Boyu',
      price: 19.99,
      currency: 'USD',
      features: [
        'Sınırsız AI işlemi',
        'Sınırsız not saklama',
        'Sınırsız belge tarama',
        'Gelişmiş OCR',
        'Öncelikli destek',
        'Tüm gelecek güncellemeler',
        'Reklamsız deneyim',
      ],
      planType: UserPlan.lifetime,
    ),
    const SubscriptionPlanModel(
      id: 'plan_ai_premium',
      name: 'AI Premium Aylık',
      price: 4.99,
      currency: 'USD',
      features: [
        'Sınırsız AI işlemi',
        'Sınırsız not saklama',
        'Sınırsız belge tarama',
        'Gelişmiş OCR',
        'GPT-4 erişimi',
        'Sesli komut desteği',
      ],
      planType: UserPlan.aiPremium,
    ),
  ];

  Future<SubscriptionModel> getCurrentPlan() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentSubscription;
  }

  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_availablePlans);
  }

  Future<SubscriptionModel> purchase(String planId) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final plan = _availablePlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => throw Exception('Plan bulunamadı: $planId'),
    );

    _currentSubscription = SubscriptionModel(
      planType: plan.planType,
      isActive: true,
      expiresAt: plan.planType == UserPlan.aiPremium
          ? DateTime.now().add(const Duration(days: 30))
          : null,
      features: plan.features,
    );

    return _currentSubscription;
  }

  Future<SubscriptionModel> restore() async {
    await Future.delayed(const Duration(milliseconds: 700));

    // Simulate restoring a lifetime purchase
    _currentSubscription = SubscriptionModel(
      planType: UserPlan.lifetime,
      isActive: true,
      expiresAt: null,
      features: _availablePlans
          .firstWhere((p) => p.planType == UserPlan.lifetime)
          .features,
    );

    return _currentSubscription;
  }
}
