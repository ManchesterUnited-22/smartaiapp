// lib/features/chat/presentation/widgets/weekly_comparison_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyComparisonChart extends StatelessWidget {
  final Map<String, int> totalTasksByWeek;
  final Map<String, int> completedTasksByWeek;

  const WeeklyComparisonChart({
    super.key,
    required this.totalTasksByWeek,
    required this.completedTasksByWeek,
  });

  static const _totalColor = Color(0xFFBFDBFE); // xanh nhạt
  static const _completedColor = Color(0xFF1D4ED8); // xanh đậm

  @override
  Widget build(BuildContext context) {
    final weekKeys = <String>{...totalTasksByWeek.keys, ...completedTasksByWeek.keys}.toList()
      ..sort();

    if (weekKeys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Chưa có dữ liệu để hiển thị biểu đồ.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    final rawMax = weekKeys
        .map((k) => totalTasksByWeek[k] ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxVal = rawMax < 4 ? 4 : rawMax;
     final completedList = [for (final k in weekKeys) completedTasksByWeek[k] ?? 0];
    int bestIndex = 0;
    for (int i = 1; i < completedList.length; i++) {
      if (completedList[i] > completedList[bestIndex]) bestIndex = i;
    }
    final hasHighlight = completedList.isNotEmpty && completedList[bestIndex] > 0;

    return 
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasHighlight)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  'Tuần tốt nhất: ${weekKeys[bestIndex].replaceAll('Tuần ', 'T')} · ${completedList[bestIndex]} task hoàn thành',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
    SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: (maxVal + 1).toDouble(),
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final week = weekKeys[groupIndex];
                final label = rodIndex == 0 ? 'Tổng' : 'Hoàn thành';
                return BarTooltipItem(
                  '$week\n$label: ${rod.toY.round()}',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekKeys.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weekKeys[index].replaceAll('Tuần ', 'T'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < weekKeys.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 6,
                barRods: [
                  BarChartRodData(
                    toY: (totalTasksByWeek[weekKeys[i]] ?? 0).toDouble(),
                    color: _totalColor,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                  BarChartRodData(
                    toY: (completedTasksByWeek[weekKeys[i]] ?? 0).toDouble(),
                    color: _completedColor,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                ],
              ),
          ],
        ),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
     )],
      );
      
  }
}