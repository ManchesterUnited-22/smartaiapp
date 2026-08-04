// lib/features/analytics/domain/usecases/generate_performance_report.dart
import '../entities/performance_report.dart';
import '../../data/datasources/analytics_aggregation_datasource.dart';
import '../../data/datasources/insight_generation_datasource.dart';
import '../../../tasks/domain/repositories/task_repository.dart';

class GeneratePerformanceReport {
  final TaskRepository taskRepository;
  final AnalyticsAggregationDatasource aggregationDatasource;
  final InsightGenerationDatasource insightDatasource;

  GeneratePerformanceReport(
    this.taskRepository,
    this.aggregationDatasource,
    this.insightDatasource,
  );

  Future<PerformanceReport> call(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // Bước 1: lấy task + tính số liệu bằng code
    final tasks = await taskRepository.queryTasksByDateRange(startOfMonth, endOfMonth);
    final report = aggregationDatasource.aggregateMonthlyStats(tasks, month);

    // Bước 2: AI diễn giải từ số liệu đã tính (không đưa raw task list)
    final insight = await insightDatasource.generateInsight(report);

    return PerformanceReport(
      totalTasks: report.totalTasks,
      completedTasks: report.completedTasks,
      overdueTasks: report.overdueTasks,
      completionRate: report.completionRate,
      tasksByWeek: report.tasksByWeek,
      tasksByPriority: report.tasksByPriority,
      insightText: insight,
    );
  }
}