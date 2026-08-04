// lib/features/ai_engine/domain/entities/conversation_context.dart
import '../../../tasks/domain/entities/task.dart';

class ConversationContext {
  Task? lastMentionedTask;
  DateTime? lastInteractionTime;

  void updateWithTask(Task task) {
    lastMentionedTask = task;
    lastInteractionTime = DateTime.now();
  }

  void clear() {
    lastMentionedTask = null;
    lastInteractionTime = null;
  }

  /// Ngữ cảnh hết hạn sau 5 phút không tương tác, tránh nhầm sang chủ đề cũ
  bool get isValid {
    if (lastInteractionTime == null) return false;
    return DateTime.now().difference(lastInteractionTime!).inMinutes < 5;
  }

  String? get contextHint {
    if (!isValid || lastMentionedTask == null) return null;
    return lastMentionedTask!.title;
  }
}