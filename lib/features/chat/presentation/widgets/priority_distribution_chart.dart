// lib/features/chat/presentation/widgets/priority_distribution_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PriorityDistributionChart extends StatelessWidget {
  final Map<String, int> tasksByPriority;

  const PriorityDistributionChart({super.key, required this.tasksByPriority});

  static const _order = ['high', 'medium', 'low'];
  static const _labels = {'high': 'Cao', 'medium': 'Trung bình', 'low': 'Thấp'};
  static const _colors = {
    'high': Color(0xFFDC2626),
    'medium': Color(0xFFF59E0B),
    'low': Color(0xFF10B981),
  };

  Color _colorFor(String key) => _colors[key] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final total = tasksByPriority.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(Icons.pie_chart_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Chưa có dữ liệu ưu tiên để hiển thị.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    final keys = _order.where((k) => (tasksByPriority[k] ?? 0) > 0).toList();
    final dominantKey = keys.reduce(
      (a, b) => (tasksByPriority[a] ?? 0) >= (tasksByPriority[b] ?? 0) ? a : b,
    );

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 200,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 48,
                    startDegreeOffset: -90,
                    sections: [
                      for (final k in keys)
                        PieChartSectionData(
                          value: (tasksByPriority[k] ?? 0).toDouble(),
                          color: _colorFor(k),
                          title: '',
                          radius: 34,
                          badgeWidget: k == dominantKey
                              ? _percentBadge(
                                  '${(((tasksByPriority[k] ?? 0) / total) * 100).round()}%',
                                  _colorFor(k),
                                )
                              : null,
                          badgePositionPercentageOffset: 1.25,
                        ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 450),
                  swapAnimationCurve: Curves.easeOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            for (final k in keys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _colorFor(k), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_labels[k]} (${tasksByPriority[k]})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _percentBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}