// lib/features/chat/presentation/widgets/overdue_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverdueTrendChart extends StatelessWidget {
  final Map<String, int> overdueTasksByWeek;

  const OverdueTrendChart({super.key, required this.overdueTasksByWeek});

  @override
  Widget build(BuildContext context) {
    final weekKeys = overdueTasksByWeek.keys.toList()..sort();
    final total = overdueTasksByWeek.values.fold<int>(0, (a, b) => a + b);

    if (weekKeys.isEmpty || total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            Text(
              'Không có task trễ hạn trong kỳ này 🎉',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < weekKeys.length; i++)
        FlSpot(i.toDouble(), (overdueTasksByWeek[weekKeys[i]] ?? 0).toDouble()),
    ];
    final maxY = overdueTasksByWeek.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 90,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final week = weekKeys[s.x.toInt()];
                return LineTooltipItem(
                  '$week: trễ ${s.y.toInt()} task',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= weekKeys.length) return const SizedBox.shrink();
                  return Text(weekKeys[index].replaceAll('Tuần ', 'T'),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.12)),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}