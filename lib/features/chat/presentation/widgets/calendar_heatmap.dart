// lib/features/chat/presentation/widgets/calendar_heatmap.dart
import 'package:flutter/material.dart';

class CalendarHeatmap extends StatelessWidget {
  final DateTime month;
  final Map<String, int> completedByDay;

  const CalendarHeatmap({super.key, required this.month, required this.completedByDay});

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _colorFor(int count, int maxCount, BuildContext context) {
    if (count == 0 || maxCount == 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    final ratio = count / maxCount;
    if (ratio > 0.75) return const Color(0xFF16A34A);
    if (ratio > 0.5) return const Color(0xFF4ADE80);
    if (ratio > 0.25) return const Color(0xFF86EFAC);
    return const Color(0xFFBBF7D0);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=T2..7=CN
    final leadingEmpty = firstWeekday - 1;

    final maxCount = completedByDay.values.isEmpty
        ? 0
        : completedByDay.values.reduce((a, b) => a > b ? a : b);

    final totalCells = leadingEmpty + daysInMonth;
    final trailingEmpty = (7 - (totalCells % 7)) % 7;

    if (maxCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa có ngày nào hoàn thành task trong tháng này.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells + trailingEmpty,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = index - leadingEmpty + 1;
            final date = DateTime(month.year, month.month, day);
            final count = completedByDay[_keyFor(date)] ?? 0;

            return Tooltip(
              message: '${date.day}/${date.month}: $count task hoàn thành',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 250 + (day * 6)),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Opacity(
                  opacity: value,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorFor(count, maxCount, context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 9,
                          color: count / maxCount > 0.5 ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Ít', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(width: 4),
            for (final c in [
              const Color(0xFFE5E7EB),
              const Color(0xFFBBF7D0),
              const Color(0xFF86EFAC),
              const Color(0xFF4ADE80),
              const Color(0xFF16A34A),
            ])
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
              ),
            const SizedBox(width: 4),
            Text('Nhiều', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }
}