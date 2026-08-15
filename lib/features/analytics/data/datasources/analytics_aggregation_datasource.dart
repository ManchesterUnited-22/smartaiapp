// lib/features/analytics/data/datasources/analytics_aggregation_datasource.dart
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/performance_report.dart';

class AnalyticsAggregationDatasource {
  static const _weekdayLabels = [
    'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật',
  ];
  PerformanceReport aggregateMonthlyStats(List<Task> tasks, DateTime month) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = tasks.where((t) {
      return t.status != TaskStatus.completed && t.dueDate.isBefore(DateTime.now());
    }).length;

    final completionRate = total == 0 ? 0.0 : (completed / total) * 100;

    // Nhóm theo tuần trong tháng (dựa trên ngày hoàn thành)
    final tasksByWeek = <String, int>{};
    for (var t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final weekNum = ((t.completedAt!.day - 1) / 7).floor() + 1;
      final key = 'Tuần $weekNum';
      tasksByWeek[key] = (tasksByWeek[key] ?? 0) + 1;
    }

    // Tổng số task đến hạn trong từng tuần (mẫu số để tính % hoàn thành theo tuần)
    final totalTasksByWeek = <String, int>{};
    for (var t in tasks) {
      if (t.dueDate.month != month.month || t.dueDate.year != month.year) continue;
      final weekNum = ((t.dueDate.day - 1) / 7).floor() + 1;
      final key = 'Tuần $weekNum';
      totalTasksByWeek[key] = (totalTasksByWeek[key] ?? 0) + 1;
    }

    // Số task trễ hạn theo từng tuần (dựa trên tuần đến hạn)
    final overdueTasksByWeek = <String, int>{};
    for (var t in tasks) {
      if (t.status == TaskStatus.completed) continue;
      if (!t.dueDate.isBefore(DateTime.now())) continue;
      if (t.dueDate.month != month.month || t.dueDate.year != month.year) continue;
      final weekNum = ((t.dueDate.day - 1) / 7).floor() + 1;
      final key = 'Tuần $weekNum';
      overdueTasksByWeek[key] = (overdueTasksByWeek[key] ?? 0) + 1;
    }

    // Nhóm theo priority
    final tasksByPriority = <String, int>{};
    for (var t in tasks) {
      final key = t.priority.name;
      tasksByPriority[key] = (tasksByPriority[key] ?? 0) + 1;
    }
// Số task hoàn thành theo từng thứ trong tuần, để biết ngày nào làm việc hiệu quả nhất
    final completedByWeekday = <String, int>{};
    for (var t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final label = _weekdayLabels[t.completedAt!.weekday - 1];
      completedByWeekday[label] = (completedByWeekday[label] ?? 0) + 1;
    }
     final completedByDay = <String, int>{};
    for (var t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final d = t.completedAt!;
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      completedByDay[key] = (completedByDay[key] ?? 0) + 1;
    }


    // Chỉ số đúng giờ trung bình: so completedAt với dueDate của các task đã hoàn thành.
    // Nhóm theo tag/nhãn — task không gắn tag nào sẽ gộp vào "Khác"
     double? avgPunctualityHours;
    final punctualityDiffs = <double>[];
    for (var t in tasks) {
      if (t.status != TaskStatus.completed || t.completedAt == null) continue;
      final diffHours = t.dueDate.difference(t.completedAt!).inMinutes / 60.0;
      punctualityDiffs.add(diffHours);
    }
    if (punctualityDiffs.isNotEmpty) {
      avgPunctualityHours = punctualityDiffs.reduce((a, b) => a + b) / punctualityDiffs.length;
    }

    final tasksByTag = <String, int>{};
    for (var t in tasks) {
      if (t.tags.isEmpty) {
        tasksByTag['Khác'] = (tasksByTag['Khác'] ?? 0) + 1;
      } else {
        for (final tag in t.tags) {
          tasksByTag[tag] = (tasksByTag[tag] ?? 0) + 1;
        }
      }
    }

    return PerformanceReport(
      totalTasks: total,
      completedTasks: completed,
      overdueTasks: overdue,
      completionRate: completionRate,
      tasksByWeek: tasksByWeek,
      totalTasksByWeek: totalTasksByWeek,
      overdueTasksByWeek: overdueTasksByWeek,
      tasksByPriority: tasksByPriority,
      tasksByTag: tasksByTag,
      avgPunctualityHours: avgPunctualityHours,
      completedByWeekday: completedByWeekday,
      completedByDay: completedByDay,
      reportMonth: month,
    );
  }
}