// lib/features/tasks/domain/usecases/create_task.dart
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../../../core/services/notification_service.dart';

class CreateTask {
  final TaskRepository repository;
  final NotificationService notificationService;

  CreateTask(this.repository, this.notificationService);

  Future<Task> call({
    required String title,
    String? description,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
    String source = 'manual',
    bool reminderEnabled = true, // mặc định bật nhắc nhở
  }) async {
    // Mặc định nhắc trước 15 phút so với dueDate
    final reminderTime = dueDate.subtract(const Duration(minutes: 15));

    final task = Task(
      id: '',
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      tags: tags,
      source: source,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );

    final createdTask = await repository.createTask(task);

    if (reminderEnabled) {
      await notificationService.scheduleTaskReminder(
        taskId: createdTask.id,
        title: createdTask.title,
        reminderTime: reminderTime,
      );
      await notificationService.scheduleOverdueAlert(
        taskId: task.id,
        title: title,
        dueDate: dueDate,
      );
    }

    return createdTask;
  }
}