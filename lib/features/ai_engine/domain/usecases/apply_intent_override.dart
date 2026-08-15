// lib/features/ai_engine/domain/usecases/apply_intent_override.dart
import '../entities/intent_result.dart';

class ApplyIntentOverride {
  static const _performanceKeywords = [
    'hiệu suất', 'đánh giá', 'phân tích', 'thống kê', 'năng suất',
    'biểu đồ', 'báo cáo', 'tổng kết', 'review', 'nhìn lại', 'kết quả làm việc',
  ];

  IntentResult call(String originalText, IntentResult qwenResult) {
    final normalized = originalText.toLowerCase();

    final hasPerformanceKeyword =
        _performanceKeywords.any((k) => normalized.contains(k));

    // Nếu có từ khóa hiệu suất rõ ràng, nhưng Qwen lại đoán nhầm sang query_tasks/unknown
    if (hasPerformanceKeyword &&
        (qwenResult.intent == IntentType.queryTasks ||
         qwenResult.intent == IntentType.unknown)) {
      final entities = Map<String, dynamic>.from(qwenResult.entities ?? {});

      // Nếu Qwen chưa kịp điền reportPeriod (vì lúc đó nó đoán sai intent),
      // tự bắt số tháng bằng regex làm lưới an toàn cuối, không cần gọi AI lại.
      if (entities['reportPeriod'] == null) {
        if (normalized.contains('tháng trước')) {
          entities['reportPeriod'] = 'last_month';
        } else {
          final monthMatch = RegExp(r'tháng\s*(\d{1,2})').firstMatch(normalized);
          if (monthMatch != null) {
            final month = int.tryParse(monthMatch.group(1)!);
            if (month != null && month >= 1 && month <= 12) {
              final year = DateTime.now().year;
              entities['reportPeriod'] = 'specific_month';
              entities['reportMonth'] = '$year-${month.toString().padLeft(2, '0')}';
            } else {
              entities['reportPeriod'] = 'this_month';
            }
          } else {
            entities['reportPeriod'] = 'this_month';
          }
        }
      }

      return IntentResult(
        intent: IntentType.performanceReport,
        confidence: 0.9,
        message: qwenResult.message,
        entities: entities,
      );
    }

    return qwenResult;
  }
}