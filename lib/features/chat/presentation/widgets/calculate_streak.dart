// lib/features/analytics/domain/usecases/calculate_streak.dart
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/domain/entities/task.dart';

/// Tính số tuần liên tiếp (từ tuần gần nhất lùi về trước) có tỷ lệ hoàn thành
/// >= [goodWeekThreshold]. Tuần không có task nào thì bỏ qua (không phá chuỗi),
/// vì thiếu dữ liệu không có nghĩa là làm việc kém.
class CalculateStreak {
  final TaskRepository taskRepository;

  static const goodWeekThreshold = 80.0;
  static const _maxLookbackWeeks = 12;

  CalculateStreak(this.taskRepository);

  Future<int> call({DateTime? asOf}) async {
    final now = asOf ?? DateTime.now();
    int streak = 0;

    for (int i = 0; i < _maxLookbackWeeks; i++) {
      final weekEnd = now.subtract(Duration(days: 7 * i));
      final weekStart = weekEnd.subtract(const Duration(days: 7));

      final tasks = await taskRepository.queryTasksByDateRange(weekStart, weekEnd);
      if (tasks.isEmpty) continue; // tuần trống — bỏ qua, không tính là gãy chuỗi

      final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
      final rate = (completed / tasks.length) * 100;

      if (rate >= goodWeekThreshold) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}