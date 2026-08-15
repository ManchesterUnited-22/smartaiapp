// classify_intent.dart — bản đầy đủ
import '../entities/intent_result.dart';
import '../../data/datasources/gemini_intent_datasource.dart';
import 'apply_intent_override.dart';

class ClassifyIntent {
  final GeminiIntentDatasource datasource;
  final ApplyIntentOverride _applyOverride;

  ClassifyIntent(this.datasource, [ApplyIntentOverride? applyOverride])
      : _applyOverride = applyOverride ?? ApplyIntentOverride();

  Future<IntentResult> call(String userMessage, {String? contextHint}) async {
    try {
      final json = await datasource.classifyIntent(userMessage, contextHint: contextHint);
      final result = IntentResult.fromJson(json);
      // Lưới an toàn: sửa lại nếu Gemini đoán nhầm ý định "xem báo cáo
      // hiệu suất" thành intent khác dù câu có từ khóa rõ ràng.
      return _applyOverride(userMessage, result);
    } on GeminiException catch (e) {
      return IntentResult(intent: IntentType.unknown, confidence: 0.0, message: e.userMessage);
    } catch (e) {
      return IntentResult(
        intent: IntentType.unknown,
        confidence: 0.0,
        message: 'Xin lỗi, mình chưa hiểu ý bạn. Bạn có thể nói rõ hơn không?',
      );
    }
  }

  Future<Map<String, dynamic>> extractSlot(String text) async {
    try {
      return await datasource.extractSlotInfo(text);
    } catch (_) {
      return {'dueDate': null, 'priority': null};
    }
  }
}