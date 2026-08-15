// lib/features/analytics/domain/usecases/generate_performance_report.dart
import '../entities/performance_report.dart';
import '../../data/datasources/analytics_aggregation_datasource.dart';
import '../../data/datasources/insight_generation_datasource.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../chat/presentation/widgets/calculate_streak.dart';
class _CachedReport {
  final PerformanceReport report;
  final DateTime cachedAt;
  _CachedReport(this.report, this.cachedAt);
}

class GeneratePerformanceReport {
  final TaskRepository taskRepository;
  final AnalyticsAggregationDatasource aggregationDatasource;
  final InsightGenerationDatasource insightDatasource;
  final CalculateStreak calculateStreak;
  GeneratePerformanceReport(
    this.taskRepository,
    this.aggregationDatasource,
    this.insightDatasource,
    this.calculateStreak,
  );

  // Cache trong bộ nhớ, sống trong suốt phiên app. Tránh gọi lại Gemini
  // nhiều lần nếu người dùng hỏi lại cùng 1 tháng trong thời gian ngắn.
  final Map<String, _CachedReport> _cache = {};
  static const _cacheTtl = Duration(minutes: 5);

  Future<PerformanceReport> call(DateTime month, {bool forceRefresh = false}) async {
    final cacheKey = '${month.year}-${month.month}';
    final cached = _cache[cacheKey];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      return cached.report;
    }

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // Bước 1: lấy task + tính số liệu bằng code
    final tasks = await taskRepository.queryTasksByDateRange(startOfMonth, endOfMonth);
    final report = aggregationDatasource.aggregateMonthlyStats(tasks, month);

    // Bước 1.5: lấy tỷ lệ hoàn thành tháng trước để so sánh (không bắt buộc phải có)
    double? previousRate;
    try {
      final prevMonth = DateTime(month.year, month.month - 1, 1);
      final prevStart = DateTime(prevMonth.year, prevMonth.month, 1);
      final prevEnd = DateTime(prevMonth.year, prevMonth.month + 1, 0, 23, 59, 59);
      final prevTasks = await taskRepository.queryTasksByDateRange(prevStart, prevEnd);
      if (prevTasks.isNotEmpty) {
        previousRate =
            aggregationDatasource.aggregateMonthlyStats(prevTasks, prevMonth).completionRate;
      }
    } catch (_) {
      previousRate = null; // Không có dữ liệu tháng trước cũng không sao
    }
    final streakFuture = calculateStreak(asOf: month.isAfter(DateTime.now()) ? DateTime.now() : month);

    // Bước 2: AI diễn giải từ số liệu đã tính (không đưa raw task list)
    final insight = await insightDatasource.generateInsight(report);
    final streakWeeks = await streakFuture;
    final result = PerformanceReport(
      totalTasks: report.totalTasks,
      completedTasks: report.completedTasks,
      overdueTasks: report.overdueTasks,
      completionRate: report.completionRate,
      tasksByWeek: report.tasksByWeek,
      totalTasksByWeek: report.totalTasksByWeek,
      overdueTasksByWeek: report.overdueTasksByWeek,
      tasksByPriority: report.tasksByPriority,
      tasksByTag: report.tasksByTag,
      previousMonthCompletionRate: previousRate,
      avgPunctualityHours: report.avgPunctualityHours,
      completedByWeekday: report.completedByWeekday,
      insightText: insight,
      streakWeeks: streakWeeks,
      completedByDay: report.completedByDay,
      reportMonth: month,
    );

    _cache[cacheKey] = _CachedReport(result, DateTime.now());
    return result;
  }
}