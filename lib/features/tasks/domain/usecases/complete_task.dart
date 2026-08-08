// lib/features/tasks/domain/usecases/complete_task.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
      'completedAt': Timestamp.fromDate(DateTime.now()),   // ✅ đúng kiểu Timestamp
    });
  }
}