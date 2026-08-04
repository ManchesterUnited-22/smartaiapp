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

    // Lấy thêm task quá hạn từ trước (không thuộc hôm nay nhưng chưa hoàn thành)
    final allTasks = await taskRepository.watchTasks().first;
    final overdueTasks = allTasks.where((t) {
      return t.status != TaskStatus.completed && t.dueDate.isBefore(startOfDay);
    }).toList();

    final pendingToday = todayTasks.where((t) => t.status != TaskStatus.completed).toList();

    final greeting = _timeBasedGreeting(now);

    if (pendingToday.isEmpty && overdueTasks.isEmpty) {
      return ChatResponse(
        message: '$greeting Hôm nay bạn chưa có task nào cả — một ngày thảnh thơi! 🌤️',
      );
    }

    final buffer = StringBuffer(greeting);
    buffer.write('\n\n');

    if (overdueTasks.isNotEmpty) {
      buffer.write('⚠️ Bạn có ${overdueTasks.length} task quá hạn chưa hoàn thành. ');
    }

    if (pendingToday.isNotEmpty) {
      buffer.write('Hôm nay bạn có ${pendingToday.length} việc cần làm:');
    } else {
      buffer.write('Hôm nay không có task mới, nhưng nhớ xử lý các task quá hạn nhé.');
    }

    // Gộp task quá hạn + task hôm nay để hiển thị dạng list, ưu tiên quá hạn lên đầu
    final combinedList = [...overdueTasks, ...pendingToday];

    return ChatResponse(
      message: buffer.toString(),
      taskList: combinedList.isNotEmpty ? combinedList : null,
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