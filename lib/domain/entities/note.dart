import 'dart:convert';

class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final String category;
  final bool isPinned;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category = 'Genel',
    this.isPinned = false,
  });

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    String? category,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'isPinned': isPinned,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      category: map['category'] ?? 'Genel',
      isPinned: map['isPinned'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
