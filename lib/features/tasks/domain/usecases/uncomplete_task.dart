// lib/features/tasks/domain/usecases/uncomplete_task.dart
import '../repositories/task_repository.dart';

/// Đánh dấu lại 1 task đã hoàn thành thành "pending" (bỏ tick hoàn thành).
/// Đối xứng với [CompleteTask], tránh gọi thẳng repository.updateTask
/// bằng Map thô ngay tại tầng UI — dễ test và mở rộng logic sau này hơn
/// (ví dụ: sau này muốn đặt lại lịch nhắc nhở khi bỏ tick).
class UncompleteTask {
  final TaskRepository repository;

  UncompleteTask(this.repository);

  Future<void> call(String taskId) async {
    await repository.updateTask(taskId, {
      'status': 'pending',
      'completedAt': null,
    });
  }
}