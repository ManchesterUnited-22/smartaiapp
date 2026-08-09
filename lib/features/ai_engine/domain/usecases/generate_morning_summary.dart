// lib/features/ai_engine/domain/usecases/generate_morning_summary.dart
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/domain/entities/task.dart';
import '../entities/chat_response.dart';

class GenerateMorningSummary {
  final TaskRepository taskRepository;
  GenerateMorningSummary(this.taskRepository);

  Future<ChatResponse> call() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayTasks = await taskRepository.queryTasksByDateRange(startOfDay, endOfDay);
    final pendingToday = todayTasks.where((t) => t.status != TaskStatus.completed).toList();

    final greeting = _timeBasedGreeting(now);

    if (pendingToday.isEmpty) {
      return ChatResponse(
        message: '$greeting Hôm nay bạn chưa có task nào cả — một ngày thảnh thơi! 🌤️',
      );
    }

    return ChatResponse(
      message: '$greeting\n\nHôm nay bạn có ${pendingToday.length} việc cần làm:',
      taskList: pendingToday,
    );
  }

  String _timeBasedGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Chào buổi sáng! ☀️';
    if (hour < 14) return 'Chào buổi trưa! 🌤️';
    if (hour < 18) return 'Chào buổi chiều! 🌇';
    return 'Chào buổi tối! 🌙';
  }
}