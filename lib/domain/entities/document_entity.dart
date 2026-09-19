enum DocumentSourceType {
  camera,
  file,
  clipboard;

  String get displayName {
    switch (this) {
      case DocumentSourceType.camera:
        return 'Kamera';
      case DocumentSourceType.file:
        return 'Dosya';
      case DocumentSourceType.clipboard:
        return 'Pano';
    }
  }

  static DocumentSourceType fromString(String value) {
    switch (value) {
      case 'camera':
        return DocumentSourceType.camera;
      case 'file':
        return DocumentSourceType.file;
      case 'clipboard':
        return DocumentSourceType.clipboard;
      default:
        return DocumentSourceType.file;
    }
  }

  String toJsonString() {
    switch (this) {
      case DocumentSourceType.camera:
        return 'camera';
      case DocumentSourceType.file:
        return 'file';
      case DocumentSourceType.clipboard:
        return 'clipboard';
    }
  }
}

class DocumentEntity {
  final String id;
  final String title;
  final String rawText;
  final String summary;
  final DocumentSourceType sourceType;
  final DateTime createdAt;

  const DocumentEntity({
    required this.id,
    required this.title,
    required this.rawText,
    this.summary = '',
    required this.sourceType,
    required this.createdAt,
  });

  DocumentEntity copyWith({
    String? id,
    String? title,
    String? rawText,
    String? summary,
    DocumentSourceType? sourceType,
    DateTime? createdAt,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      rawText: rawText ?? this.rawText,
      summary: summary ?? this.summary,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          rawText == other.rawText &&
          summary == other.summary &&
          sourceType == other.sourceType &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      rawText.hashCode ^
      summary.hashCode ^
      sourceType.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'DocumentEntity(id: $id, title: $title, sourceType: $sourceType)';
}
