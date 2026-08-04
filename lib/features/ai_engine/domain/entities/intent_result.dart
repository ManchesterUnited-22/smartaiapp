enum IntentType {
  createTask,
  updateTask,
  deleteTask,
  completeTask,
  queryTasks,
  performanceReport,
  batchAction,
  chitchat,
  unknown,
}

class IntentResult {
  final IntentType intent;
  final double confidence;
  final String message;
  final Map<String, dynamic>? entities;
  final bool requiresConfirmation;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.message,
    this.entities,
    this.requiresConfirmation = false,
  });

  factory IntentResult.fromJson(Map<String, dynamic> json) {
    return IntentResult(
      intent: IntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => IntentType.unknown,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
      entities: json['entities'],
      requiresConfirmation: json['requires_confirmation'] ?? false,
    );
  }
}