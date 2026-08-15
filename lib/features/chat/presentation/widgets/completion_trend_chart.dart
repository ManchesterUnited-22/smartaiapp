// lib/features/chat/presentation/widgets/completion_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CompletionTrendChart extends StatelessWidget {
  final Map<String, int> completedTasksByWeek;

  const CompletionTrendChart({super.key, required this.completedTasksByWeek});

  static const _lineColor = Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    final weekKeys = completedTasksByWeek.keys.toList()..sort();

    if (weekKeys.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Cần ít nhất 2 tuần dữ liệu để hiển thị xu hướng.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    final spots = <FlSpot>[
      for (int i = 0; i < weekKeys.length; i++)
        FlSpot(i.toDouble(), (completedTasksByWeek[weekKeys[i]] ?? 0).toDouble()),
    ];

    final maxY = completedTasksByWeek.values.isEmpty
        ? 1.0
        : completedTasksByWeek.values.reduce((a, b) => a > b ? a : b).toDouble();

    final isRising = spots.last.y >= spots.first.y;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY + 1,
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => touched.map((s) {
                    final week = weekKeys[s.x.toInt()];
                    return LineTooltipItem(
                      '$week: ${s.y.toInt()} task hoàn thành',
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
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= weekKeys.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
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
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: _lineColor,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: _lineColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_lineColor.withOpacity(0.18), _lineColor.withOpacity(0.0)],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isRising ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isRising ? Icons.check_circle : Icons.info,
                size: 18,
                color: isRising ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRising
                      ? 'Tỷ lệ hoàn thành đang có xu hướng tăng! 🎉'
                      : 'Tỷ lệ hoàn thành đang giảm, thử rà soát lại kế hoạch tuần này nhé.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isRising ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}