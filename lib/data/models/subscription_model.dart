import 'package:omnibrain_ai/domain/entities/subscription_entity.dart';
import 'package:omnibrain_ai/domain/entities/user_entity.dart';

class SubscriptionModel {
  final UserPlan planType;
  final bool isActive;
  final DateTime? expiresAt;
  final List<String> features;

  const SubscriptionModel({
    required this.planType,
    required this.isActive,
    this.expiresAt,
    this.features = const [],
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      planType: UserPlan.fromString(json['plan_type'] as String? ?? 'free'),
      isActive: json['is_active'] as bool? ?? false,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_type': planType.toJsonString(),
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'features': features,
    };
  }

  SubscriptionEntity toEntity() {
    return SubscriptionEntity(
      planType: planType,
      isActive: isActive,
      expiresAt: expiresAt,
      features: features,
    );
  }

  factory SubscriptionModel.fromEntity(SubscriptionEntity entity) {
    return SubscriptionModel(
      planType: entity.planType,
      isActive: entity.isActive,
      expiresAt: entity.expiresAt,
      features: entity.features,
    );
  }

  @override
  String toString() =>
      'SubscriptionModel(planType: $planType, isActive: $isActive)';
}

class SubscriptionPlanModel {
  final String id;
  final String name;
  final double price;
  final String currency;
  final List<String> features;
  final UserPlan planType;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'USD',
    this.features = const [],
    required this.planType,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      planType: UserPlan.fromString(json['plan_type'] as String? ?? 'free'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'currency': currency,
      'features': features,
      'plan_type': planType.toJsonString(),
    };
  }

  SubscriptionPlan toEntity() {
    return SubscriptionPlan(
      id: id,
      name: name,
      price: price,
      currency: currency,
      features: features,
      planType: planType,
    );
  }

  @override
  String toString() =>
      'SubscriptionPlanModel(id: $id, name: $name, price: $price $currency)';
}
