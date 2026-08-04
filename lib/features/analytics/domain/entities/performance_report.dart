// lib/features/analytics/domain/entities/performance_report.dart
class PerformanceReport {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final double completionRate; // %
  final Map<String, int> tasksByWeek; // "Tuần 1" -> số task hoàn thành
  final Map<String, int> tasksByPriority; // "high" -> số lượng
  final String? insightText; // AI diễn giải, null nếu chưa gọi AI

  PerformanceReport({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.tasksByWeek,
    required this.tasksByPriority,
    this.insightText,
  });
}
