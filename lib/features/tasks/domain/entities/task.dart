// lib/features/task/domain/entities/task.dart
enum TaskStatus { pending, inProgress, completed, overdue }
enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> tags;
  final String source;
  final bool reminderEnabled;
  final DateTime? reminderTime;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.tags = const [],
    this.source = 'manual',
    this.reminderEnabled = false,
    this.reminderTime,
  });

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      source: source,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );
  }
}