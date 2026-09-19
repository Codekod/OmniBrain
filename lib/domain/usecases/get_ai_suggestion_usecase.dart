import 'package:omnibrain_ai/domain/repositories/ai_command_repository.dart';

class GetAiSuggestionUseCase {
  final AiCommandRepository _aiCommandRepository;

  const GetAiSuggestionUseCase(this._aiCommandRepository);

  Future<List<String>> call() {
    return _aiCommandRepository.getSuggestions();
  }
}
