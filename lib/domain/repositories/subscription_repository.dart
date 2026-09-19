import 'package:omnibrain_ai/domain/entities/subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionEntity> getCurrentPlan();

  Future<List<SubscriptionPlan>> getAvailablePlans();

  Future<SubscriptionEntity> purchase(String planId);

  Future<SubscriptionEntity> restore();
}
