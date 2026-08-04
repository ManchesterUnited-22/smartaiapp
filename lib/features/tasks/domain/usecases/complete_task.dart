// lib/features/tasks/domain/usecases/complete_task.dart
import '../repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';

class CompleteTask {
  final TaskRepository repository;
  final NotificationService notificationService;

  CompleteTask(this.repository, this.notificationService);

  Future<void> call(String taskId) async {
    await notificationService.cancelReminder(taskId);
    await repository.updateTask(taskId, {
      'status': 'completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
  }
}