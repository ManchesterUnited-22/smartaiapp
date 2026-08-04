// lib/features/task/data/models/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    required super.priority,
    required super.dueDate,
    required super.createdAt,
    super.completedAt,
    super.tags,
    super.source,
    super.reminderEnabled,
    super.reminderTime,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      tags: List<String>.from(data['tags'] ?? []),
      source: data['source'] ?? 'manual',
      reminderEnabled: data['reminderEnabled'] ?? false,
      reminderTime: data['reminderTime'] != null
          ? (data['reminderTime'] as Timestamp).toDate()
          : null,
    );
  }

  factory TaskModel.fromEntity(Task task) => TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        dueDate: task.dueDate,
        createdAt: task.createdAt,
        completedAt: task.completedAt,
        tags: task.tags,
        source: task.source,
        reminderEnabled: task.reminderEnabled,
        reminderTime: task.reminderTime,
      );

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'tags': tags,
      'source': source,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
    };
  }
}