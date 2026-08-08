// lib/features/tasks/domain/usecases/update_task.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';

/// Cổng DUY NHẤT để sửa giờ/độ ưu tiên của task — đảm bảo mỗi lần sửa giờ
/// deadline đều huỷ nhắc nhở cũ và lên lịch lại nhắc nhở mới cho đúng giờ.
class UpdateTask {
  final TaskRepository repository;
  final NotificationService notificationService;

  UpdateTask(this.repository, this.notificationService);

  Future<void> call({
    required String taskId,
    required String title,
    required DateTime newDueDate,
    required TaskPriority newPriority,
  }) async {
    // Huỷ cả 2 thông báo cũ (nhắc trước + quá hạn) trước khi đổi giờ.
    await notificationService.cancelReminder(taskId);

    final newReminderTime = newDueDate.subtract(const Duration(minutes: 15));

    await repository.updateTask(taskId, {
      'dueDate': Timestamp.fromDate(newDueDate),
      'priority': newPriority.name,
      'reminderTime': Timestamp.fromDate(newReminderTime),
    });

    await notificationService.scheduleTaskReminder(
      taskId: taskId,
      title: title,
      reminderTime: newReminderTime,
    );
    await notificationService.scheduleOverdueAlert(
      taskId: taskId,
      title: title,
      dueDate: newDueDate,
    );
  }
}