// lib/features/chat/presentation/widgets/empty_chat_state.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/aura_orb.dart';

class EmptyChatState extends StatelessWidget {
  final void Function(String) onSuggestionTap;
  const EmptyChatState({super.key, required this.onSuggestionTap});

  static const _suggestions = [
    'Tạo task họp nhóm lúc 9h sáng mai',
    'Hôm nay tôi có việc gì?',
    'Đánh giá hiệu suất tháng này',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AuraOrb(size: 56, animate: true),
            const SizedBox(height: 20),
            Text(
              'Chào bạn 👋',
              style: GoogleFonts.fraunces(
                fontSize: 24, fontWeight: FontWeight.w600, color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mình là trợ lý đồng hành quản lý công việc của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return Material(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSuggestionTap(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(s, style: TextStyle(fontSize: 13, color: scheme.onSurface)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}