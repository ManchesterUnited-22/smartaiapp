// lib/features/chat/presentation/widgets/typing_indicator.dart
import 'package:flutter/material.dart';
import '../../../../core/widgets/aura_orb.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

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
            'đang soạn phản hồi…',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}