import 'package:omnibrain_ai/data/datasources/mock/mock_ai_actions_service.dart';
import 'package:omnibrain_ai/domain/repositories/ai_actions_repository.dart';

class AiActionsRepositoryImpl implements AiActionsRepository {
  final MockAiActionsService _aiActionsService;

  AiActionsRepositoryImpl(this._aiActionsService);

  @override
  Future<AiActionResult> processAction({
    required String actionType,
    required String inputText,
  }) async {
    final model = await _aiActionsService.processAction(
      actionType: actionType,
      inputText: inputText,
    );
    return AiActionResult(
      output: model.outputText,
      tokenUsage: model.tokenUsage,
    );
  }

  @override
  Future<List<AiActionHistory>> getHistory() async {
    final models = await _aiActionsService.getHistory();
    return models
        .map((m) => AiActionHistory(
              id: m.id,
              actionType: m.actionType,
              inputText: m.inputText,
              outputText: m.outputText,
              tokenUsage: m.tokenUsage,
              createdAt: m.createdAt,
            ))
        .toList();
  }
}
