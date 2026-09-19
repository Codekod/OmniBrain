import 'package:omnibrain_ai/domain/entities/document_entity.dart';

class DocumentModel {
  final String id;
  final String title;
  final String rawText;
  final String summary;
  final DocumentSourceType sourceType;
  final DateTime createdAt;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.rawText,
    this.summary = '',
    required this.sourceType,
    required this.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      rawText: json['raw_text'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      sourceType: DocumentSourceType.fromString(
          json['source_type'] as String? ?? 'file'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'raw_text': rawText,
      'summary': summary,
      'source_type': sourceType.toJsonString(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DocumentEntity toEntity() {
    return DocumentEntity(
      id: id,
      title: title,
      rawText: rawText,
      summary: summary,
      sourceType: sourceType,
      createdAt: createdAt,
    );
  }

  factory DocumentModel.fromEntity(DocumentEntity entity) {
    return DocumentModel(
      id: entity.id,
      title: entity.title,
      rawText: entity.rawText,
      summary: entity.summary,
      sourceType: entity.sourceType,
      createdAt: entity.createdAt,
    );
  }

  @override
  String toString() =>
      'DocumentModel(id: $id, title: $title, sourceType: $sourceType)';
}
