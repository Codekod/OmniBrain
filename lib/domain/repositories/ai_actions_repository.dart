class AiActionResult {
  final String output;
  final int tokenUsage;

  const AiActionResult({
    required this.output,
    required this.tokenUsage,
  });

  @override
  String toString() =>
      'AiActionResult(output: ${output.substring(0, output.length > 50 ? 50 : output.length)}..., tokenUsage: $tokenUsage)';
}

class AiActionHistory {
  final String id;
  final String actionType;
  final String inputText;
  final String outputText;
  final int tokenUsage;
  final DateTime createdAt;

  const AiActionHistory({
    required this.id,
    required this.actionType,
    required this.inputText,
    required this.outputText,
    required this.tokenUsage,
    required this.createdAt,
  });
}

abstract class AiActionsRepository {
  Future<AiActionResult> processAction({
    required String actionType,
    required String inputText,
  });

  Future<List<AiActionHistory>> getHistory();
}
