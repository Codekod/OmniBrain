import 'package:omnibrain_ai/domain/entities/reminder_entity.dart';

class ReminderModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String? sourceDocumentId;
  final bool isCompleted;
  final String priority;
  final String category;
  final String repeat;

  const ReminderModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.sourceDocumentId,
    this.isCompleted = false,
    this.priority = 'medium',
    this.category = 'Genel',
    this.repeat = 'none',
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      sourceDocumentId: json['source_document_id'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'Genel',
      repeat: json['repeat'] as String? ?? 'none',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'source_document_id': sourceDocumentId,
      'is_completed': isCompleted,
      'priority': priority,
      'category': category,
      'repeat': repeat,
    };
  }

  ReminderEntity toEntity() {
    return ReminderEntity(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      sourceDocumentId: sourceDocumentId,
      isCompleted: isCompleted,
      priority: priority,
      category: category,
      repeat: repeat,
    );
  }

  factory ReminderModel.fromEntity(ReminderEntity entity) {
    return ReminderModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      sourceDocumentId: entity.sourceDocumentId,
      isCompleted: entity.isCompleted,
      priority: entity.priority,
      category: entity.category,
      repeat: entity.repeat,
    );
  }

  @override
  String toString() =>
      'ReminderModel(id: $id, title: $title, dueDate: $dueDate, priority: $priority, isCompleted: $isCompleted)';
}
