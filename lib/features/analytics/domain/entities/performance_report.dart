// lib/features/analytics/domain/entities/performance_report.dart
class PerformanceReport {
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;
  final double completionRate; // %
  final Map<String, int> tasksByWeek; // "Tuần 1" -> số task hoàn thành
  final Map<String, int> totalTasksByWeek; // "Tuần 1" -> tổng số task đến hạn (mẫu số)
  final Map<String, int> overdueTasksByWeek; // "Tuần 1" -> số task trễ hạn trong tuần đó
  final Map<String, int> tasksByPriority; // "high" -> số lượng
  final Map<String, int> tasksByTag; // "công việc" -> số lượng, task không tag gộp vào "Khác"
  final double? previousMonthCompletionRate; // % tháng trước, null nếu chưa có dữ liệu
  final double? avgPunctualityHours;
  final String? insightText; // AI diễn giải, null nếu chưa gọi AI
  final Map<String, int> completedByWeekday;
  final int streakWeeks;
  final Map<String, int> completedByDay; // "yyyy-MM-dd" -> số task hoàn thành trong ngày đó
  final DateTime? reportMonth;
  PerformanceReport({
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.tasksByWeek,
    this.totalTasksByWeek = const {},
    this.overdueTasksByWeek = const {},
    required this.tasksByPriority,
    this.tasksByTag = const {},
    this.previousMonthCompletionRate,
    this.avgPunctualityHours,
    this.insightText,
    this.completedByWeekday = const {},
    this.streakWeeks = 0,
    this.completedByDay = const {},
    this.reportMonth,
  });
}