// lib/features/tasks/domain/usecases/create_recurring_tasks.dart
import 'package:todolist_app/features/tasks/domain/entities/task.dart';
import 'package:todolist_app/features/tasks/domain/usecases/create_task.dart';

class CreateRecurringTasks {
  final CreateTask createTask;
  CreateRecurringTasks(this.createTask);

  Future<List<Task>> call({
    required String title,
    required DateTime firstDueDate,
    required String recurrenceType, // daily | weekly | monthly
    TaskPriority priority = TaskPriority.medium,
    int? count,
  }) async {
    final occurrences = _generateOccurrences(firstDueDate, recurrenceType, count);
    final createdTasks = <Task>[];

    for (final dueDate in occurrences) {
      final task = await createTask(
        title: title,
        dueDate: dueDate,
        priority: priority,
        source: 'ai_chat',
        tags: const ['recurring'],
      );
      createdTasks.add(task);
    }

    return createdTasks;
  }

  List<DateTime> _generateOccurrences(DateTime start, String type, int? count) {
    switch (type) {
      case 'daily':
        final total = count ?? 14;
        return List.generate(total, (i) => start.add(Duration(days: i)));

      case 'weekly':
        final total = count ?? 8;
        return List.generate(total, (i) => start.add(Duration(days: i * 7)));

      case 'monthly':
        final total = count ?? 6;
        return List.generate(
          total,
          (i) => DateTime(start.year, start.month + i, start.day, start.hour, start.minute),
        );

      default:
        final total = count ?? 8;
        return List.generate(total, (i) => start.add(Duration(days: i * 7)));
    }
  }
}