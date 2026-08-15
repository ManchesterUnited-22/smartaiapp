// lib/features/chat/presentation/widgets/weekday_productivity_chart.dart
import 'package:flutter/material.dart';

class WeekdayProductivityChart extends StatelessWidget {
  final Map<String, int> completedByWeekday;

  const WeekdayProductivityChart({super.key, required this.completedByWeekday});

  static const _order = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
  static const _shortLabels = {
    'Thứ 2': 'T2', 'Thứ 3': 'T3', 'Thứ 4': 'T4', 'Thứ 5': 'T5',
    'Thứ 6': 'T6', 'Thứ 7': 'T7', 'Chủ nhật': 'CN',
  };

  @override
  Widget build(BuildContext context) {
    final total = completedByWeekday.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa đủ dữ liệu để xác định ngày hiệu quả nhất.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    final maxVal = completedByWeekday.values.reduce((a, b) => a > b ? a : b);
    final bestDay = _order.reduce(
      (a, b) => (completedByWeekday[a] ?? 0) >= (completedByWeekday[b] ?? 0) ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((completedByWeekday[bestDay] ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  'Hiệu quả nhất: $bestDay (${completedByWeekday[bestDay]} task)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 90,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in _order)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${completedByWeekday[day] ?? 0}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: day == bestDay ? FontWeight.bold : FontWeight.normal,
                            color: day == bestDay ? const Color(0xFF2563EB) : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: maxVal == 0 ? 0 : (completedByWeekday[day] ?? 0) / maxVal,
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Container(
                            height: 40 * value + 4,
                            decoration: BoxDecoration(
                              color: day == bestDay
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF2563EB).withOpacity(0.25),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _shortLabels[day]!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
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