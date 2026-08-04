// lib/features/chat/presentation/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import '../providers/chat_provider.dart';
import '../../../../core/widgets/aura_orb.dart';
import 'task_card_widget.dart';
import 'performance_report_widget.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(Map<String, dynamic>) onConfirm;
  final void Function(String) onQuickReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.sender == MessageSender.user;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(colors: [scheme.primary, scheme.primary.withOpacity(0.85)])
            : null,
        color: isUser ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 18 : 4),
          topRight: Radius.circular(isUser ? 4 : 18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text ?? message.response?.message ?? '',
            style: TextStyle(
              color: isUser ? Colors.white : scheme.onSurface,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),

          if (message.response?.task != null) ...[
            const SizedBox(height: 8),
            TaskCardWidget(task: message.response!.task!),
          ],

          if (message.response?.taskList != null)
            ...message.response!.taskList!.map((t) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TaskCardWidget(task: t),
                )),

          if (message.response?.performanceReport != null) ...[
            const SizedBox(height: 8),
            PerformanceReportWidget(report: message.response!.performanceReport!),
          ],

          // Chip gợi ý nhanh — tap là gửi luôn, không cần gõ
          if (message.response?.quickReplies != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.response!.quickReplies!.map((reply) {
                  return _pillButton(
                    context,
                    label: reply,
                    onTap: () => onQuickReply(reply),
                    filled: false,
                  );
                }).toList(),
              ),
            ),

          if (message.response?.selectionOptions != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.response!.selectionOptions!.map((option) {
                  return _pillButton(
                    context,
                    label: option.label,
                    onTap: () => onConfirm(option.pendingAction),
                    filled: false,
                  );
                }).toList(),
              ),
            ),

          if (message.response?.requiresConfirmation == true)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pillButton(
                    context,
                    label: 'Xác nhận',
                    onTap: () => onConfirm(message.response!.pendingAction!),
                    filled: true,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 8),
                  _pillButton(context, label: 'Hủy', onTap: () {}, filled: false),
                ],
              ),
            ),
        ],
      ),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AuraOrb(size: 26),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _pillButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool filled,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = color ?? scheme.primary;

    return Material(
      color: filled ? baseColor : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: filled ? null : Border.all(color: scheme.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}