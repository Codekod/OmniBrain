import 'package:omnibrain_ai/data/datasources/mock/mock_subscription_service.dart';
import 'package:omnibrain_ai/domain/entities/subscription_entity.dart';
import 'package:omnibrain_ai/domain/repositories/subscription_repository.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final MockSubscriptionService _subscriptionService;

  SubscriptionRepositoryImpl(this._subscriptionService);

  @override
  Future<SubscriptionEntity> getCurrentPlan() async {
    final model = await _subscriptionService.getCurrentPlan();
    return model.toEntity();
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    final models = await _subscriptionService.getAvailablePlans();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SubscriptionEntity> purchase(String planId) async {
    final model = await _subscriptionService.purchase(planId);
    return model.toEntity();
  }

  @override
  Future<SubscriptionEntity> restore() async {
    final model = await _subscriptionService.restore();
    return model.toEntity();
  }
}
