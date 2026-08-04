// lib/features/task/domain/repositories/task_repository.dart
import '../entities/task.dart';

abstract class TaskRepository {
  Future<Task> createTask(Task task);
  Future<void> updateTask(String taskId, Map<String, dynamic> updates);
  Future<void> deleteTask(String taskId);
  Future<Task?> getTaskById(String taskId);
  Stream<List<Task>> watchTasks({TaskStatus? status});
  Future<List<Task>> queryTasksByDateRange(DateTime from, DateTime to);
}