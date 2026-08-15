// lib/core/constants/intent_types.dart

// Re-export để các nơi khác có thể import từ constants
import 'package:todolist_app/features/ai_engine/domain/entities/intent_result.dart';

export '../../features/ai_engine/domain/entities/intent_result.dart' show IntentType;

/// Helper chuyển string từ Gemini sang IntentType an toàn
IntentType parseIntentType(String? value) {
  if (value == null) return IntentType.unknown;
  return IntentType.values.firstWhere(
    (e) => e.name.toLowerCase() == value.toLowerCase(),
    orElse: () => IntentType.unknown,
  );
}