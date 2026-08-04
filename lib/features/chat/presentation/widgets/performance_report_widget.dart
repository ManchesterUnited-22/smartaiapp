// lib/features/chat/presentation/widgets/performance_report_widget.dart
import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/performance_report.dart';
import 'weekly_completion_chart.dart';
class PerformanceReportWidget extends StatelessWidget {
  final PerformanceReport report;
  const PerformanceReportWidget({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statColumn('Tổng task', '${report.totalTasks}'),
                _statColumn('Hoàn thành', '${report.completedTasks}'),
                _statColumn('Trễ hạn', '${report.overdueTasks}'),
                _statColumn('Tỷ lệ', '${report.completionRate.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Xu hướng hoàn thành theo tuần',
            style:TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox( height: 8),
            WeeklyCompletionChart(tasksByWeek: report.tasksByWeek,),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}