// lib/features/tasks/domain/usecases/delete_task.dart
import '../repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';

class DeleteTask {
  final TaskRepository repository;
  final NotificationService notificationService;

  DeleteTask(this.repository, this.notificationService);

  Future<void> call(String taskId) async {
    await notificationService.cancelReminder(taskId);
    await repository.deleteTask(taskId);
  }
}