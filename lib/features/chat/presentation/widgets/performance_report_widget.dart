// lib/features/chat/presentation/widgets/performance_report_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:todolist_app/features/chat/presentation/widgets/weekly_comparison_chart.dart';
import '../../../analytics/domain/entities/performance_report.dart';
import '../../../../core/widgets/aura_orb.dart';
import '../../../../core/widgets/staggered_fade_in.dart';
import 'priority_distribution_chart.dart';
import 'tag_distribution_chart.dart';
import 'overdue_trend_chart.dart';
import 'completion_trend_chart.dart';
import 'completion_ring.dart';
import 'weekday_productivity_chart.dart';
import 'achievement_badges.dart';
import 'calendar_heatmap.dart';

class PerformanceReportWidget extends StatefulWidget {
  final PerformanceReport report;

  const PerformanceReportWidget({super.key, required this.report});

  @override
  State<PerformanceReportWidget> createState() => _PerformanceReportWidgetState();
}

class _PerformanceReportWidgetState extends State<PerformanceReportWidget> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late final ConfettiController _confettiController;

  PerformanceReport get report => widget.report;

  // Mốc đẹp để ăn mừng: hoàn thành 100% task trong tháng (và có ít nhất 1 task).
  bool get _isPerfectMonth => report.totalTasks > 0 && report.completionRate >= 100.0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (_isPerfectMonth) {
      // Chờ 1 nhịp để card render xong rồi mới bắn, tránh giật khi mở.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Color> _moodColors(double rate) {
    if (rate >= 80) return [const Color(0xFF22C55E), const Color(0xFF16A34A)];
    if (rate >= 50) return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
  }

  Future<void> _shareReport(BuildContext context) async {
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (bytes == null) return;
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'bao_cao_hieu_suat.png', mimeType: 'image/png')],
        text: 'Báo cáo hiệu suất công việc của tôi 📊',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chia sẻ báo cáo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Screenshot(
          controller: _screenshotController,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AuraOrb(
                        size: 26,
                        animate: report.completionRate >= 80,
                        colors: _moodColors(report.completionRate),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng quan tháng này',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            if (report.avgPunctualityHours != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  report.avgPunctualityHours! >= 0
                                      ? 'Trung bình hoàn thành sớm ${report.avgPunctualityHours!.toStringAsFixed(1)}h'
                                      : 'Trung bình trễ ${report.avgPunctualityHours!.abs().toStringAsFixed(1)}h',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: report.avgPunctualityHours! >= 0
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  AchievementBadges(report: report),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CompletionRing(
                        percent: report.completionRate,
                        previousPercent: report.previousMonthCompletionRate,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _statColumn('Tổng task', report.totalTasks),
                                _statDivider(scheme),
                                _statColumn('Hoàn thành', report.completedTasks),
                                _statDivider(scheme),
                                _statColumn(
                                  'Trễ hạn',
                                  report.overdueTasks,
                                  valueColor: report.overdueTasks > 0 ? Colors.redAccent : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 10, bottom: 4),
                      title: Text(
                        'Xem biểu đồ chi tiết',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: scheme.primary,
                        ),
                      ),
                      iconColor: scheme.primary,
                      collapsedIconColor: scheme.primary,
                      initiallyExpanded: false,
                      onExpansionChanged: (_) => HapticFeedback.lightImpact(),
                      children: [
                        StaggeredFadeIn(
                          children: [
                            Row(
                              children: [
                                const Text('Tổng vs. hoàn thành theo tuần',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const Spacer(),
                                _legendDot(scheme.primary.withOpacity(0.30), 'Tổng'),
                                const SizedBox(width: 10),
                                _legendDot(scheme.primary, 'Hoàn thành'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            WeeklyComparisonChart(
                              totalTasksByWeek: report.totalTasksByWeek,
                              completedTasksByWeek: report.tasksByWeek,
                            ),
                            const SizedBox(height: 20),
                            const Text('Phân bổ theo nhãn',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 10),
                            TagDistributionChart(tasksByTag: report.tasksByTag),
                            const SizedBox(height: 20),
                            const Text('Phân bổ theo độ ưu tiên',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            PriorityDistributionChart(tasksByPriority: report.tasksByPriority),
                            const SizedBox(height: 20),
                            const Text('Xu hướng hoàn thành',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            CompletionTrendChart(completedTasksByWeek: report.tasksByWeek),
                            const SizedBox(height: 20),
                            const Text('Xu hướng trễ hạn theo tuần',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            OverdueTrendChart(overdueTasksByWeek: report.overdueTasksByWeek),
                            const SizedBox(height: 20),
                            const Text('Hiệu quả theo ngày trong tuần',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            WeekdayProductivityChart(completedByWeekday: report.completedByWeekday),
                             const SizedBox(height: 20),
                            const Text('Bản đồ hoạt động trong tháng',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 8),
                            CalendarHeatmap(
                              month: report.reportMonth ?? DateTime.now(),
                              completedByDay: report.completedByDay,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(Icons.ios_share_rounded, size: 18, color: scheme.onSurfaceVariant),
              tooltip: 'Chia sẻ báo cáo',
              onPressed: () => _shareReport(context),
            ),
          ),
        ),
        if (_isPerfectMonth)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: math.pi / 2,
                  emissionFrequency: 0.08,
                  numberOfParticles: 18,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  gravity: 0.25,
                  shouldLoop: false,
                  colors: const [
                    Color(0xFF22C55E),
                    Color(0xFFF59E0B),
                    Color(0xFF2563EB),
                    Color(0xFFDB2777),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statColumn(String label, int value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '$v',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(ColorScheme scheme) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: scheme.outlineVariant.withOpacity(0.6),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}