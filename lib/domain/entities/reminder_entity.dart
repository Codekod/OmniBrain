class ReminderEntity {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String? sourceDocumentId;
  final bool isCompleted;
  final String priority; // 'high', 'medium', 'low'
  final String category; // 'İş', 'Kişisel', 'Ödeme', 'Sağlık', 'Genel'
  final String repeat;   // 'none', 'daily', 'weekdays', 'monthly'

  const ReminderEntity({
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

  ReminderEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? sourceDocumentId,
    bool? isCompleted,
    String? priority,
    String? category,
    String? repeat,
  }) {
    return ReminderEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      repeat: repeat ?? this.repeat,
    );
  }

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isUpcoming =>
      !isCompleted && dueDate.isAfter(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          dueDate == other.dueDate &&
          sourceDocumentId == other.sourceDocumentId &&
          isCompleted == other.isCompleted &&
          priority == other.priority &&
          category == other.category &&
          repeat == other.repeat;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      dueDate.hashCode ^
      sourceDocumentId.hashCode ^
      isCompleted.hashCode ^
      priority.hashCode ^
      category.hashCode ^
      repeat.hashCode;

  @override
  String toString() =>
      'ReminderEntity(id: $id, title: $title, dueDate: $dueDate, priority: $priority, category: $category, isCompleted: $isCompleted)';
}
