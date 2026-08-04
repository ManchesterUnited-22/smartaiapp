// lib/features/ai_engine/domain/entities/chat_response.dart
import '../../../tasks/domain/entities/task.dart';
import '../../../analytics/domain/entities/performance_report.dart';

class ChatResponse {
  final String message;
  final Task? task;
  final List<Task>? taskList;
  final PerformanceReport? performanceReport;
  final bool requiresConfirmation;
  final Map<String, dynamic>? pendingAction;
  final List<TaskSelectionOption>? selectionOptions;
  final List<String>? quickReplies;

  ChatResponse({
    required this.message,
    this.task,
    this.taskList,
    this.performanceReport,
    this.requiresConfirmation = false,
    this.pendingAction,
    this.selectionOptions,
    this.quickReplies,
  });
}

class TaskSelectionOption {
  final String label;
  final Map<String, dynamic> pendingAction;

  TaskSelectionOption({required this.label, required this.pendingAction});
}