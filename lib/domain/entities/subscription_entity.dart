import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class SubscriptionEntity {
  final UserPlan planType;
  final bool isActive;
  final DateTime? expiresAt;
  final List<String> features;

  const SubscriptionEntity({
    required this.planType,
    required this.isActive,
    this.expiresAt,
    this.features = const [],
  });

  SubscriptionEntity copyWith({
    UserPlan? planType,
    bool? isActive,
    DateTime? expiresAt,
    List<String>? features,
  }) {
    return SubscriptionEntity(
      planType: planType ?? this.planType,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      features: features ?? this.features,
    );
  }

  bool get isFree => planType == UserPlan.free;

  bool get isPremium =>
      planType == UserPlan.lifetime || planType == UserPlan.aiPremium;

  bool get hasExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionEntity &&
          runtimeType == other.runtimeType &&
          planType == other.planType &&
          isActive == other.isActive &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode =>
      planType.hashCode ^ isActive.hashCode ^ expiresAt.hashCode;

  @override
  String toString() =>
      'SubscriptionEntity(planType: $planType, isActive: $isActive, expiresAt: $expiresAt)';
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final List<String> features;
  final UserPlan planType;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'USD',
    this.features = const [],
    required this.planType,
  });

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    List<String>? features,
    UserPlan? planType,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      planType: planType ?? this.planType,
    );
  }

  bool get isFree => price == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          planType == other.planType;

  @override
  int get hashCode => id.hashCode ^ planType.hashCode;

  @override
  String toString() =>
      'SubscriptionPlan(id: $id, name: $name, price: $price $currency, planType: $planType)';
}
