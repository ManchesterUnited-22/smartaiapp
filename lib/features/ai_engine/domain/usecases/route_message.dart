// lib/features/ai_engine/domain/usecases/route_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:todolist_app/core/error/network_exception_handler.dart';
import 'package:todolist_app/features/ai_engine/domain/entities/conversation_context.dart';
import '../entities/intent_result.dart';
import '../entities/chat_response.dart';
import 'classify_intent.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/usecases/create_task.dart';
import '../../../tasks/domain/usecases/create_recurring_tasks.dart';
import '../../../tasks/domain/usecases/complete_task.dart';
import '../../../tasks/domain/usecases/delete_task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../analytics/domain/usecases/generate_performance_report.dart';

enum TaskMatchResult { none, single, multiple }

class TaskMatchOutcome {
  final TaskMatchResult result;
  final Task? singleTask;
  final List<Task> candidates;

  TaskMatchOutcome({
    required this.result,
    this.singleTask,
    this.candidates = const [],
  });
}

enum PendingType { updateField, createMissingTime }

class PendingClarification {
  final PendingType type;
  final String? taskId;
  final String? title;
  final String? draftTitle;
  final TaskPriority? draftPriority;
  final String? draftRecurrenceType;
  final int? draftRecurrenceCount;

  PendingClarification({
    required this.type,
    this.taskId,
    this.title,
    this.draftTitle,
    this.draftPriority,
    this.draftRecurrenceType,
    this.draftRecurrenceCount,
  });
}

class RouteMessage {
  final ClassifyIntent classifyIntent;
  final CreateTask createTask;
  final CreateRecurringTasks createRecurringTasks;
  final CompleteTask completeTask;
  final DeleteTask deleteTask;
  final TaskRepository taskRepository;
  final GeneratePerformanceReport generateReport;
  final ConversationContext _context = ConversationContext();
  PendingClarification? _pendingClarification;

  static const _contextReferenceKeywords = [
    'task mới', 'việc mới', 'công việc mới', 'vừa tạo', 'vừa thêm', 'vừa rồi',
    'task này', 'task đó', 'việc này', 'việc đó', 'công việc này', 'công việc đó',
    'cái này', 'cái đó', ' nó ', ' nó,', ' nó.', ' nó?',
  ];

  RouteMessage({
    required this.classifyIntent,
    required this.createTask,
    required this.createRecurringTasks,
    required this.completeTask,
    required this.deleteTask,
    required this.taskRepository,
    required this.generateReport,
  });

  bool _mentionsContextReference(String text) {
    final normalized = ' ${text.toLowerCase().trim()} ';
    return _contextReferenceKeywords.any((k) => normalized.contains(k));
  }

  Future<TaskMatchOutcome> _resolveTask(String userMessage, String? hint) async {
    if (_mentionsContextReference(userMessage) &&
        _context.isValid &&
        _context.lastMentionedTask != null) {
      return TaskMatchOutcome(result: TaskMatchResult.single, singleTask: _context.lastMentionedTask);
    }
    if (hint == null || hint.isEmpty) {
      return TaskMatchOutcome(result: TaskMatchResult.none);
    }
    return _matchTasksByHint(hint);
  }

  Future<ChatResponse> call(String userMessage) async {
    if (_pendingClarification != null) {
      final resolved = await _tryResolvePendingClarification(userMessage);
      if (resolved != null) return resolved;
      // slot rỗng -> đã tự xóa pending bên trong, coi như câu mới, rơi xuống luồng bình thường
    }

    final result = await classifyIntent(userMessage, contextHint: _context.contextHint);

    switch (result.intent) {
      case IntentType.createTask:
        return _handleCreateTask(result);
      case IntentType.completeTask:
        return _handleCompleteTask(result, userMessage);
      case IntentType.deleteTask:
        return _handleDeleteTaskRequest(result, userMessage);
      case IntentType.queryTasks:
        return _handleQueryTasks(result);
      case IntentType.performanceReport:
        return _handlePerformanceReport(result);
      case IntentType.updateTask:
        return _handleUpdateTask(result, userMessage);
      case IntentType.batchAction:
        return _handleBatchAction(result);
      case IntentType.chitchat:
      case IntentType.unknown:
      default:
        return ChatResponse(message: result.message);
    }
  }

  Future<ChatResponse?> _tryResolvePendingClarification(String userMessage) async {
    final pending = _pendingClarification!;
    Map<String, dynamic> slot;
    try {
      slot = await classifyIntent.extractSlot(userMessage);
    } catch (_) {
      slot = {'dueDate': null, 'priority': null};
    }

    final hasInfo = slot['dueDate'] != null || slot['priority'] != null;
    if (!hasInfo) {
      _pendingClarification = null;
      return null;
    }

    _pendingClarification = null;

    if (pending.type == PendingType.updateField) {
      final updates = <String, dynamic>{};
      if (slot['dueDate'] != null) {
        try {
          updates['dueDate'] = Timestamp.fromDate(DateTime.parse(slot['dueDate']));
        } catch (_) {}
      }
      if (slot['priority'] != null) {
        updates['priority'] = slot['priority'];
      }

      if (updates.isEmpty) return null;

      try {
        await taskRepository.updateTask(pending.taskId!, updates);
        final updatedTask = await taskRepository.getTaskById(pending.taskId!);
        if (updatedTask != null) _context.updateWithTask(updatedTask);
        return ChatResponse(message: 'Đã cập nhật task "${pending.title}":', task: updatedTask);
      } catch (e) {
        return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
      }
    }

    if (pending.type == PendingType.createMissingTime) {
      DateTime dueDate;
      try {
        dueDate = slot['dueDate'] != null
            ? DateTime.parse(slot['dueDate'])
            : DateTime.now().add(const Duration(hours: 1));
      } catch (_) {
        dueDate = DateTime.now().add(const Duration(hours: 1));
      }

      final priority = slot['priority'] != null
          ? _parsePriority(slot['priority'])
          : (pending.draftPriority ?? TaskPriority.medium);

      return _createTaskOrRecurring(
        title: pending.draftTitle!,
        dueDate: dueDate,
        priority: priority,
        recurrenceType: pending.draftRecurrenceType,
        recurrenceCount: pending.draftRecurrenceCount,
      );
    }

    return null;
  }

  Future<ChatResponse> _handleCreateTask(IntentResult result) async {
    final entities = result.entities ?? {};
    final title = entities['title'] as String?;

    if (title == null || title.isEmpty) {
      return ChatResponse(message: 'Bạn muốn tạo task gì, cho mình biết tên task nhé?');
    }

    final priority = _parsePriority(entities['priority']);
    final recurrenceType = entities['recurrenceType'] as String?;
    final rawCount = entities['recurrenceCount'];
    final recurrenceCount = rawCount is int ? rawCount : int.tryParse('$rawCount');

    if (entities['dueDate'] == null) {
      _pendingClarification = PendingClarification(
        type: PendingType.createMissingTime,
        draftTitle: title,
        draftPriority: entities['priority'] != null ? priority : null,
        draftRecurrenceType: recurrenceType,
        draftRecurrenceCount: recurrenceCount,
      );
      final recurrenceNote = recurrenceType != null ? ' (lặp lại ${_recurrenceLabel(recurrenceType)})' : '';
      return ChatResponse(
        message:
            'Task "$title"$recurrenceNote vào lúc nào vậy? Bạn có thể nói luôn độ ưu tiên nếu muốn (vd "9h sáng mai, ưu tiên cao").',
        quickReplies: ['9h sáng mai, ưu tiên cao', '14h chiều nay, ưu tiên trung bình'],
      );
    }

    DateTime dueDate;
    try {
      dueDate = DateTime.parse(entities['dueDate']);
    } catch (_) {
      dueDate = DateTime.now().add(const Duration(days: 1));
    }

    return _createTaskOrRecurring(
      title: title,
      dueDate: dueDate,
      priority: priority,
      recurrenceType: recurrenceType,
      recurrenceCount: recurrenceCount,
    );
  }

  Future<ChatResponse> _createTaskOrRecurring({
    required String title,
    required DateTime dueDate,
    required TaskPriority priority,
    String? recurrenceType,
    int? recurrenceCount,
  }) async {
    try {
      if (recurrenceType != null) {
        final createdTasks = await createRecurringTasks(
          title: title,
          firstDueDate: dueDate,
          recurrenceType: recurrenceType,
          priority: priority,
          count: recurrenceCount,
        );
        if (createdTasks.isNotEmpty) _context.updateWithTask(createdTasks.first);
        return ChatResponse(
          message: 'Đã tạo ${createdTasks.length} task lặp lại "$title" (${_recurrenceLabel(recurrenceType)}), '
              'bắt đầu từ ${DateFormat('dd/MM HH:mm').format(dueDate)}.',
          taskList: createdTasks,
        );
      }

      final task = await createTask(title: title, dueDate: dueDate, priority: priority, source: 'ai_chat');
      _context.updateWithTask(task);
      return ChatResponse(
        message: 'Đã tạo task "${task.title}" vào ${DateFormat('dd/MM HH:mm').format(task.dueDate)}.',
        task: task,
      );
    } catch (e) {
      return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
    }
  }

  String _recurrenceLabel(String type) {
    switch (type) {
      case 'daily':
        return 'hàng ngày';
      case 'weekly':
        return 'hàng tuần';
      case 'monthly':
        return 'hàng tháng';
      default:
        return type;
    }
  }

  Future<ChatResponse> _handleUpdateTask(IntentResult result, String userMessage) async {
    final entities = result.entities ?? {};
    final hint = entities['taskIdHint'] as String?;

    final outcome = await _resolveTask(userMessage, hint);

    switch (outcome.result) {
      case TaskMatchResult.none:
        return ChatResponse(message: 'Bạn muốn sửa task nào? Cho mình biết tên task nhé.');

      case TaskMatchResult.multiple:
        return ChatResponse(
          message: 'Có ${outcome.candidates.length} task khớp, bạn muốn sửa task nào?',
          selectionOptions: outcome.candidates
              .map((t) => TaskSelectionOption(
                    label: t.title,
                    pendingAction: {
                      'action': 'update_task',
                      'taskId': t.id,
                      'title': t.title,
                      'newDueDate': entities['dueDate'],
                      'newPriority': entities['priority'],
                    },
                  ))
              .toList(),
        );

      case TaskMatchResult.single:
        final task = outcome.singleTask!;
        _context.updateWithTask(task);

        final updates = <String, dynamic>{};
        if (entities['dueDate'] != null) {
          try {
            updates['dueDate'] = Timestamp.fromDate(DateTime.parse(entities['dueDate']));
          } catch (_) {}
        }
        if (entities['priority'] != null) {
          updates['priority'] = entities['priority'];
        }

        if (updates.isEmpty) {
          _pendingClarification = PendingClarification(
            type: PendingType.updateField,
            taskId: task.id,
            title: task.title,
          );
          return ChatResponse(message: 'Bạn muốn đổi gì cho task "${task.title}"? (giờ, độ ưu tiên...)',
          quickReplies: const ['Sau 1 giờ nữa', 'Tối nay 19h', 'Sáng mai 8h', 'Ưu tiên cao', 'Ưu tiên thấp'],
          
          );
        }

        try {
          await taskRepository.updateTask(task.id, updates);
          final updatedTask = await taskRepository.getTaskById(task.id);
          if (updatedTask != null) _context.updateWithTask(updatedTask);
          return ChatResponse(message: 'Đã cập nhật task "${task.title}":', task: updatedTask);
        } catch (e) {
          return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
        }
    }
  }

  Future<ChatResponse> _handleCompleteTask(IntentResult result, String userMessage) async {
    final hint = result.entities?['taskIdHint'] as String?;
    final outcome = await _resolveTask(userMessage, hint);

    switch (outcome.result) {
      case TaskMatchResult.none:
        return ChatResponse(message: 'Bạn muốn hoàn thành task nào?');

      case TaskMatchResult.single:
        final task = outcome.singleTask!;
        _context.updateWithTask(task);
        try {
          await completeTask(task.id);
          return ChatResponse(message: 'Đã đánh dấu hoàn thành task "${task.title}" 🎉');
        } catch (e) {
          return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
        }

      case TaskMatchResult.multiple:
        return ChatResponse(
          message: 'Có ${outcome.candidates.length} task khớp, bạn muốn hoàn thành task nào?',
          selectionOptions: outcome.candidates
              .map((t) => TaskSelectionOption(
                    label: t.title,
                    pendingAction: {'action': 'complete_task', 'taskId': t.id, 'title': t.title},
                  ))
              .toList(),
        );
    }
  }

  Future<ChatResponse> _handleDeleteTaskRequest(IntentResult result, String userMessage) async {
    final hint = result.entities?['taskIdHint'] as String?;
    final outcome = await _resolveTask(userMessage, hint);

    switch (outcome.result) {
      case TaskMatchResult.none:
        return ChatResponse(message: 'Bạn muốn xóa task nào?');

      case TaskMatchResult.single:
        final task = outcome.singleTask!;
        return ChatResponse(
          message: 'Bạn có chắc muốn xóa task "${task.title}" không?',
          requiresConfirmation: true,
          pendingAction: {'action': 'delete_task', 'taskId': task.id, 'title': task.title},
        );

      case TaskMatchResult.multiple:
        return ChatResponse(
          message: 'Có ${outcome.candidates.length} task khớp, bạn muốn xóa task nào?',
          selectionOptions: outcome.candidates
              .map((t) => TaskSelectionOption(
                    label: t.title,
                    pendingAction: {'action': 'delete_task', 'taskId': t.id, 'title': t.title},
                  ))
              .toList(),
        );
    }
  }

  Future<ChatResponse> _handleQueryTasks(IntentResult result) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final tasks = await taskRepository.queryTasksByDateRange(startOfDay, endOfDay);
      if (tasks.isEmpty) {
        return ChatResponse(message: 'Hôm nay bạn chưa có task nào cả 🎉');
      }
      return ChatResponse(message: 'Bạn có ${tasks.length} task hôm nay:', taskList: tasks);
    } catch (e) {
      return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
    }
  }

  Future<ChatResponse> _handlePerformanceReport(IntentResult result) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final tasksInMonth = await taskRepository.queryTasksByDateRange(startOfMonth, endOfMonth);
      if (tasksInMonth.isEmpty) {
        return ChatResponse(
          message: 'Tháng này bạn chưa có task nào để đánh giá cả. Hãy thử tạo vài task rồi quay lại nhé!',
        );
      }

      final report = await generateReport(now);
      return ChatResponse(
        message: report.insightText ?? 'Đã phân tích xong hiệu suất tháng này.',
        performanceReport: report,
      );
    } catch (e) {
      return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
    }
  }

  Future<ChatResponse> _handleBatchAction(IntentResult result) async {
    final entities = result.entities ?? {};
    final scope = entities['batchScope'] as String? ?? 'today';
    final operation = entities['batchOperation'] as String? ?? 'complete';

    try {
      final targetTasks = await _resolveBatchScope(scope);
      if (targetTasks.isEmpty) {
        return ChatResponse(message: 'Không có task nào phù hợp với yêu cầu này.');
      }

      if (operation == 'delete') {
        return ChatResponse(
          message: 'Bạn có chắc muốn xóa ${targetTasks.length} task sau không?',
          requiresConfirmation: true,
          taskList: targetTasks,
          pendingAction: {
            'action': 'batch_delete_tasks',
            'taskIds': targetTasks.map((t) => t.id).toList(),
          },
        );
      }

      if (operation == 'complete') {
        for (final t in targetTasks) {
          await completeTask(t.id);
        }
        return ChatResponse(message: 'Đã đánh dấu hoàn thành ${targetTasks.length} task 🎉');
      }

      return ChatResponse(message: 'Mình chưa hiểu rõ bạn muốn thực hiện hành động gì với các task này.');
    } catch (e) {
      return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
    }
  }

  Future<List<Task>> _resolveBatchScope(String scope) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    switch (scope) {
      case 'this_week':
        final endOfWeek = startOfDay.add(const Duration(days: 7));
        final tasks = await taskRepository.queryTasksByDateRange(startOfDay, endOfWeek);
        return tasks.where((t) => t.status != TaskStatus.completed).toList();

      case 'overdue':
        final allTasks = await taskRepository.watchTasks().first;
        return allTasks
            .where((t) => t.status != TaskStatus.completed && t.dueDate.isBefore(startOfDay))
            .toList();

      case 'today':
      default:
        final endOfDay = startOfDay.add(const Duration(days: 1));
        final tasks = await taskRepository.queryTasksByDateRange(startOfDay, endOfDay);
        return tasks.where((t) => t.status != TaskStatus.completed).toList();
    }
  }

  String _normalize(String input) => input.toLowerCase().trim();

  Future<TaskMatchOutcome> _matchTasksByHint(String hint) async {
    final allTasks = await taskRepository.watchTasks().first;
    final normalizedHint = _normalize(hint);

    final exactMatches = allTasks.where((t) => _normalize(t.title) == normalizedHint).toList();
    if (exactMatches.length == 1) {
      return TaskMatchOutcome(result: TaskMatchResult.single, singleTask: exactMatches.first);
    }

    final partialMatches = allTasks.where((t) {
      final title = _normalize(t.title);
      return title.contains(normalizedHint) || normalizedHint.contains(title);
    }).toList();

    if (partialMatches.isEmpty) {
      return TaskMatchOutcome(result: TaskMatchResult.none);
    }
    if (partialMatches.length == 1) {
      return TaskMatchOutcome(result: TaskMatchResult.single, singleTask: partialMatches.first);
    }

    return TaskMatchOutcome(result: TaskMatchResult.multiple, candidates: partialMatches.take(5).toList());
  }

  TaskPriority _parsePriority(dynamic value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  Future<ChatResponse> confirmPendingAction(Map<String, dynamic> pendingAction) async {
    final action = pendingAction['action'];

    try {
      if (action == 'delete_task') {
        final title = pendingAction['title'] as String;
        final taskId = pendingAction['taskId'] as String;
        await deleteTask(taskId);
        return ChatResponse(message: 'Đã xóa task "$title".');
      }

      if (action == 'complete_task') {
        final title = pendingAction['title'] as String;
        final taskId = pendingAction['taskId'] as String;
        await completeTask(taskId);
        final updatedTask = await taskRepository.getTaskById(taskId);
        if (updatedTask != null) _context.updateWithTask(updatedTask);
        return ChatResponse(message: 'Đã đánh dấu hoàn thành task "$title" 🎉', task: updatedTask);
      }

      if (action == 'update_task') {
        final title = pendingAction['title'] as String;
        final taskId = pendingAction['taskId'] as String;
        final updates = <String, dynamic>{};
        if (pendingAction['newDueDate'] != null) {
          try {
            updates['dueDate'] = Timestamp.fromDate(DateTime.parse(pendingAction['newDueDate']));
          } catch (_) {}
        }
        if (pendingAction['newPriority'] != null) {
          updates['priority'] = pendingAction['newPriority'];
        }
        if (updates.isNotEmpty) {
          await taskRepository.updateTask(taskId, updates);
        }
        final updatedTask = await taskRepository.getTaskById(taskId);
        if (updatedTask != null) _context.updateWithTask(updatedTask);
        return ChatResponse(message: 'Đã cập nhật task "$title":', task: updatedTask);
      }

      if (action == 'batch_delete_tasks') {
        final taskIds = (pendingAction['taskIds'] as List).cast<String>();
        for (final id in taskIds) {
          await deleteTask(id);
        }
        return ChatResponse(message: 'Đã xóa ${taskIds.length} task.');
      }

      return ChatResponse(message: 'Không rõ hành động cần xác nhận.');
    } catch (e) {
      return ChatResponse(message: NetworkExceptionHandler.getFriendlyMessage(e));
    }
  }
}