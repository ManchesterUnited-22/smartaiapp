// lib/features/chat/presentation/widgets/weekly_completion_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyCompletionChart extends StatelessWidget {
  final Map<String, int> tasksByWeek; // vd: {"Tuần 1": 5, "Tuần 2": 8}

  const WeeklyCompletionChart({super.key, required this.tasksByWeek});

  @override
  Widget build(BuildContext context) {
    if (tasksByWeek.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Chưa có dữ liệu để hiển thị biểu đồ.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        )
      );
    }

    final entries = tasksByWeek.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[
      for (int i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), entries[i].value.toDouble()),
    ];

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY + 2,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[index].key.replaceAll('Tuần ', 'T'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
