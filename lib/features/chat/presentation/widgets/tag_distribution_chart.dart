// lib/features/chat/presentation/widgets/tag_distribution_chart.dart
import 'package:flutter/material.dart';

class TagDistributionChart extends StatelessWidget {
  final Map<String, int> tasksByTag;

  const TagDistributionChart({super.key, required this.tasksByTag});

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFF59E0B),
    Color(0xFF059669),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    if (tasksByTag.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa có nhãn nào được gắn cho task.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12.5),
        ),
      );
    }

    final entries = tasksByTag.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    final maxVal = top.first.value;

    return Column(
      children: [
        for (int i = 0; i < top.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    top[i].key,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: top[i].value / maxVal),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 14,
                        backgroundColor: Colors.grey.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(_palette[i % _palette.length]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 22,
                  child: Text(
                    '${top[i].value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}