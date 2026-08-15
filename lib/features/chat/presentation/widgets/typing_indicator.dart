// lib/features/chat/presentation/widgets/typing_indicator.dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/aura_orb.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mỗi chấm nảy lên trễ hơn chấm trước 1 chút -> hiệu ứng "sóng" quen thuộc
  // của các app chat (iMessage, Messenger...), sinh động hơn nhiều so với
  // chữ tĩnh trước đây.
  double _bounceFor(int dotIndex) {
    const dotDelay = 0.15;
    final t = (_controller.value - dotIndex * dotDelay) % 1.0;
    final phase = t < 0 ? t + 1.0 : t;
    return -4 * (phase < 0.5 ? phase : 1 - phase);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuraOrb(size: 22, animate: true),
          const SizedBox(width: 10),
          Text(
            'đang soạn phản hồi',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Transform.translate(
                      offset: Offset(0, _bounceFor(i)),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}