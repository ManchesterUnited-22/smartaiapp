// lib/features/ai_engine/domain/usecases/check_urgent_tasks_reminder.dart
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/domain/entities/task.dart';
import '../entities/chat_response.dart';

/// Ngưỡng "sắp đến hạn": task còn dưới khoảng thời gian này (và chưa quá hạn)
/// sẽ được nhắc kèm task quá hạn. 2 giờ là mức hợp lý để vẫn kịp xử lý —
/// chỉnh lại con số này nếu muốn nhắc sớm/muộn hơn.
const Duration kDueSoonThreshold = Duration(hours: 2);

/// Quét task quá hạn + task sắp đến hạn, chạy MỖI LẦN MỞ APP
/// (khác với GenerateMorningSummary chỉ chạy 1 lần/ngày).
class CheckUrgentTasksReminder {
  final TaskRepository taskRepository;
  CheckUrgentTasksReminder(this.taskRepository);

  /// Trả về null nếu không có gì cần nhắc (để ChatProvider không thêm
  /// tin nhắn rác vào khung chat).
  Future<ChatResponse?> call() async {
    final now = DateTime.now();
    final allTasks = await taskRepository.watchTasks().first;

    final overdue = allTasks
        .where((t) => t.status != TaskStatus.completed && t.dueDate.isBefore(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final dueSoonCutoff = now.add(kDueSoonThreshold);
    final dueSoon = allTasks
        .where((t) =>
            t.status != TaskStatus.completed &&
            !t.dueDate.isBefore(now) &&
            t.dueDate.isBefore(dueSoonCutoff))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (overdue.isEmpty && dueSoon.isEmpty) return null;

    final parts = <String>[];
    if (overdue.isNotEmpty) {
      parts.add('⚠️ ${overdue.length} task đã quá hạn chưa hoàn thành');
    }
    if (dueSoon.isNotEmpty) {
      parts.add('⏰ ${dueSoon.length} task sắp đến hạn trong ${kDueSoonThreshold.inHours} giờ tới');
    }

    final message = 'Bạn có ${parts.join(' và ')}. Kiểm tra ngay nhé!';
    final combined = [...overdue, ...dueSoon];

    return ChatResponse(message: message, taskList: combined);
  }
}