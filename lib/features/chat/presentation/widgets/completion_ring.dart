// lib/features/chat/presentation/widgets/completion_ring.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompletionRing extends StatelessWidget {
  final double percent; // 0-100
  final double? previousPercent; // null nếu không có dữ liệu tháng trước

  const CompletionRing({super.key, required this.percent, this.previousPercent});

  Color _colorFor(double p) {
    if (p >= 80) return const Color(0xFF16A34A);
    if (p >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(percent);
    final trend = previousPercent == null ? null : percent - previousPercent!;

    return SizedBox(
      width: 92,
      height: 92,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percent.clamp(0, 100)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(92, 92),
                painter: _RingPainter(percent: value, color: color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  if (trend != null && trend.abs() >= 0.5)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 11,
                          color: trend > 0 ? Colors.green : Colors.redAccent,
                        ),
                        Text(
                          '${trend.abs().round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: trend > 0 ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  _RingPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * (percent / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}