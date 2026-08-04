// lib/features/analytics/data/datasources/analytics_aggregation_datasource.dart
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/performance_report.dart';

class AnalyticsAggregationDatasource {
  PerformanceReport aggregateMonthlyStats(List<Task> tasks, DateTime month) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = tasks.where((t) {
      return t.status != TaskStatus.completed && t.dueDate.isBefore(DateTime.now());
    }).length;

    final completionRate = total == 0 ? 0.0 : (completed / total) * 100;

    // Nhóm theo tuần trong tháng
    final tasksByWeek = <String, int>{};
    for (var t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final weekNum = ((t.completedAt!.day - 1) / 7).floor() + 1;
      final key = 'Tuần $weekNum';
      tasksByWeek[key] = (tasksByWeek[key] ?? 0) + 1;
    }

    // Nhóm theo priority
    final tasksByPriority = <String, int>{};
    for (var t in tasks) {
      final key = t.priority.name;
      tasksByPriority[key] = (tasksByPriority[key] ?? 0) + 1;
    }

    return PerformanceReport(
      totalTasks: total,
      completedTasks: completed,
      overdueTasks: overdue,
      completionRate: completionRate,
      tasksByWeek: tasksByWeek,
      tasksByPriority: tasksByPriority,
    );
  }
}