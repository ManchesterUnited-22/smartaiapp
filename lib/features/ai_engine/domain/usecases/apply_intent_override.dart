// lib/features/ai_engine/domain/usecases/apply_intent_override.dart
import '../entities/intent_result.dart';

class ApplyIntentOverride {
  static const _performanceKeywords = [
    'hiệu suất', 'đánh giá', 'phân tích', 'thống kê', 'năng suất',
  ];

  IntentResult call(String originalText, IntentResult qwenResult) {
    final normalized = originalText.toLowerCase();

    final hasPerformanceKeyword =
        _performanceKeywords.any((k) => normalized.contains(k));

    // Nếu có từ khóa hiệu suất rõ ràng, nhưng Qwen lại đoán nhầm sang query_tasks/unknown
    if (hasPerformanceKeyword &&
        (qwenResult.intent == IntentType.queryTasks ||
         qwenResult.intent == IntentType.unknown)) {
      return IntentResult(
        intent: IntentType.performanceReport,
        confidence: 0.9,
        message: qwenResult.message,
        entities: qwenResult.entities,
      );
    }

    return qwenResult;
  }
}