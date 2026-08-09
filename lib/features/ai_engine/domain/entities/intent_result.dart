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
  final List<IntentResult> ?actions;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.message,
    this.entities,
    this.requiresConfirmation = false,
    this.actions,
  });

  factory IntentResult.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'];
    return IntentResult(
      intent: IntentType.values.firstWhere(
        (e) => e.name == json['intent'],
        orElse: () => IntentType.unknown,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
      entities: json['entities'],
      requiresConfirmation: json['requires_confirmation'] ?? false,
      actions: (rawActions is List)
          ? rawActions
              .map((a)=> IntentResult.fromJson( a as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}