// lib/features/chat/presentation/widgets/report_skeleton_card.dart
import 'package:flutter/material.dart';

class ReportSkeletonCard extends StatefulWidget {
  const ReportSkeletonCard({super.key});

  @override
  State<ReportSkeletonCard> createState() => _ReportSkeletonCardState();
}

class _ReportSkeletonCardState extends State<ReportSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar({double width = double.infinity, double height = 14}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.35 + _controller.value * 0.25;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(opacity),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
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
                _bar(width: 26, height: 26),
                const SizedBox(width: 10),
                Expanded(child: _bar(height: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _bar(width: 92, height: 92),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _bar(height: 20),
                      const SizedBox(height: 10),
                      _bar(height: 20),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bar(height: 13, width: 140),
            const SizedBox(height: 10),
            _bar(height: 130),
          ],
        ),
      ),
    );
  }
}