class AiActionModel {
  final String id;
  final String actionType;
  final String inputText;
  final String outputText;
  final int tokenUsage;
  final DateTime createdAt;

  const AiActionModel({
    required this.id,
    required this.actionType,
    required this.inputText,
    required this.outputText,
    required this.tokenUsage,
    required this.createdAt,
  });

  factory AiActionModel.fromJson(Map<String, dynamic> json) {
    return AiActionModel(
      id: json['id'] as String,
      actionType: json['action_type'] as String? ?? '',
      inputText: json['input_text'] as String? ?? '',
      outputText: json['output_text'] as String? ?? '',
      tokenUsage: json['token_usage'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'input_text': inputText,
      'output_text': outputText,
      'token_usage': tokenUsage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'AiActionModel(id: $id, actionType: $actionType, tokenUsage: $tokenUsage)';
}
