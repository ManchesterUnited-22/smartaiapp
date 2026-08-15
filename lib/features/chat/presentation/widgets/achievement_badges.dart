// lib/features/chat/presentation/widgets/achievement_badges.dart
import 'package:flutter/material.dart';
import '../../../analytics/domain/entities/performance_report.dart';

class _Badge {
  final String emoji;
  final String label;
  final Color color;
  const _Badge(this.emoji, this.label, this.color);
}

class AchievementBadges extends StatelessWidget {
  final PerformanceReport report;

  const AchievementBadges({super.key, required this.report});

  List<_Badge> _computeBadges() {
    final badges = <_Badge>[];

    if (report.streakWeeks >= 2) {
      badges.add(_Badge('🔥', '${report.streakWeeks} tuần liên tiếp', const Color(0xFFF97316)));
    }
    if (report.totalTasks > 0 && report.completionRate >= 100) {
      badges.add(const _Badge('🏆', 'Hoàn thành 100%', Color(0xFFEAB308)));
    }
    if (report.totalTasks > 0 && report.overdueTasks == 0) {
      badges.add(const _Badge('✅', 'Không trễ hạn', Color(0xFF16A34A)));
    }
    if (report.avgPunctualityHours != null && report.avgPunctualityHours! >= 2) {
      badges.add(const _Badge('⏱️', 'Luôn hoàn thành sớm', Color(0xFF2563EB)));
    }
    if (report.previousMonthCompletionRate != null &&
        report.completionRate - report.previousMonthCompletionRate! >= 10) {
      badges.add(const _Badge('📈', 'Tiến bộ vượt bậc', Color(0xFF7C3AED)));
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final badges = _computeBadges();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final b in badges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: b.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: b.color.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(b.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    b.label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: b.color),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}