import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? eventDate; // Custom date for meeting, lesson, deadline, etc.
  final String category;
  final bool isPinned;
  final List<String> imagePaths;
  final String? audioPath;
  final int? audioDurationSeconds;
  final List<String> tags;

  Note({
    required this.id,
    this.title = '',
    required this.content,
    required this.createdAt,
    this.eventDate,
    this.category = 'Genel',
    this.isPinned = false,
    this.imagePaths = const [],
    this.audioPath,
    this.audioDurationSeconds,
    this.tags = const [],
  });

  /// Returns clean title: either `title`, or the first markdown heading in `content`, or first line.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.replaceFirst('# ', '').trim();
      }
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'Başlıksız Not';
  }

  /// Returns content without the duplicated first title heading if present.
  String get displayBody {
    if (title.trim().isNotEmpty) return content;
    final lines = content.split('\n');
    if (lines.isNotEmpty && lines.first.trim().startsWith('# ')) {
      return lines.sublist(1).join('\n').trim();
    }
    return content;
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? eventDate,
    bool clearEventDate = false,
    String? category,
    bool? isPinned,
    List<String>? imagePaths,
    String? audioPath,
    bool clearAudioPath = false,
    int? audioDurationSeconds,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      audioDurationSeconds: clearAudioPath ? null : (audioDurationSeconds ?? this.audioDurationSeconds),
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'eventDate': eventDate?.toIso8601String(),
      'category': category,
      'isPinned': isPinned,
      'imagePaths': imagePaths,
      'audioPath': audioPath,
      'audioDurationSeconds': audioDurationSeconds,
      'tags': tags,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    // Backward compatibility: derive title from markdown header if empty
    String rawTitle = (map['title'] ?? '').toString();
    final rawContent = (map['content'] ?? '').toString();

    if (rawTitle.isEmpty && rawContent.startsWith('# ')) {
      rawTitle = rawContent.split('\n').first.replaceFirst('# ', '').trim();
    }

    return Note(
      id: (map['id'] ?? '').toString(),
      title: rawTitle,
      content: rawContent,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      eventDate: map['eventDate'] != null ? DateTime.tryParse(map['eventDate']) : null,
      category: (map['category'] ?? 'Genel').toString(),
      isPinned: map['isPinned'] ?? false,
      imagePaths: (map['imagePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      audioPath: map['audioPath']?.toString(),
      audioDurationSeconds: map['audioDurationSeconds'] as int?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
