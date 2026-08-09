// lib/injection/injection_container.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:todolist_app/core/services/daily_greeting_service.dart';
import 'package:todolist_app/core/services/notification_service.dart';

import 'package:todolist_app/features/ai_engine/data/datasources/gemini_intent_datasource.dart';
import 'package:todolist_app/features/ai_engine/domain/usecases/classify_intent.dart';
import 'package:todolist_app/features/speech/data/datasources/speech_to_text_datasource.dart';
import 'package:todolist_app/features/tasks/domain/usecases/update_task.dart';
import '../features/tasks/domain/usecases/create_recurring_tasks.dart';
import 'package:todolist_app/features/ai_engine/domain/usecases/generate_morning_summary.dart';
import 'package:todolist_app/features/ai_engine/domain/usecases/check_urgent_tasks_reminder.dart';
import 'package:todolist_app/features/ai_engine/domain/usecases/route_message.dart';
import 'package:todolist_app/features/analytics/domain/usecases/generate_performance_report.dart';
import 'package:todolist_app/features/analytics/data/datasources/analytics_aggregation_datasource.dart';
import 'package:todolist_app/features/analytics/data/datasources/insight_generation_datasource.dart';
import 'package:todolist_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:todolist_app/features/speech/data/datasources/text_to_speech_datasource.dart';
import 'package:todolist_app/features/speech/domain/usecases/speak_response.dart';
import 'package:todolist_app/features/tasks/domain/usecases/delete_task.dart';
import '../core/services/auth_services.dart';
import '../features/tasks/data/datasources/task_firestore_datasources.dart';
import '../features/tasks/domain/repositories/task_repository_impl.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/domain/usecases/create_task.dart';
import '../features/tasks/domain/usecases/complete_task.dart';
import '../features/tasks/domain/usecases/watch_today_task.dart';
import '../core/providers/theme_provider.dart';

List<SingleChildWidget> get appProviders {
  final authService = AuthService();
  final datasource = TaskFirestoreDatasource(FirebaseFirestore.instance);
  final taskRepository = TaskRepositoryImpl(datasource, authService);
  final geminiDatasource = GeminiIntentDatasource();
  final ttsDatasource = TextToSpeechDatasource();
  final sttDatasource = SpeechToTextDatasource();
  final aggregationDatasource = AnalyticsAggregationDatasource();
  final insightDatasource = InsightGenerationDatasource();
  final notificationService = NotificationService();
  final dailyGreetingService = DailyGreetingService();
  return [
    Provider<AuthService>.value(value: authService),
    Provider<TaskRepository>.value(value: taskRepository),
    Provider<NotificationService>.value(value: notificationService),

    Provider<SpeakResponse>(
      create: (_) => SpeakResponse(ttsDatasource),
    ),
    Provider<CreateTask>(
      create: (_) => CreateTask(taskRepository, notificationService),
    ),
    Provider<SpeechToTextDatasource>.value(value: sttDatasource),
    Provider<CompleteTask>(
      create: (_) => CompleteTask(taskRepository, notificationService),
    ),
    Provider<DeleteTask>(
      create: (_) => DeleteTask(taskRepository, notificationService),
    ),
    Provider<UpdateTask>(
      create: (_) => UpdateTask(taskRepository, notificationService),
    ),
    Provider<WatchTodayTask>(
      create: (_) => WatchTodayTask(taskRepository),
    ),
    Provider<ClassifyIntent>(
      create: (_) => ClassifyIntent(geminiDatasource),
    ),
    Provider<CreateRecurringTasks>(
  create: (context) => CreateRecurringTasks(context.read<CreateTask>()),
),

    // ⚠️ Phải đứng TRƯỚC RouteMessage vì RouteMessage cần đọc nó
    Provider<GeneratePerformanceReport>(
      create: (context) => GeneratePerformanceReport(
        context.read<TaskRepository>(),
        aggregationDatasource,
        insightDatasource,
      ),
    ),

    Provider<RouteMessage>(
      create: (context) => RouteMessage(
        classifyIntent: context.read<ClassifyIntent>(),
        createTask: context.read<CreateTask>(),
        completeTask: context.read<CompleteTask>(),
        deleteTask: context.read<DeleteTask>(),
        taskRepository: context.read<TaskRepository>(),
        generateReport: context.read<GeneratePerformanceReport>(),
        createRecurringTasks: context.read<CreateRecurringTasks>(),
      ),
    ),
    Provider<DailyGreetingService>.value(value: dailyGreetingService),
Provider<GenerateMorningSummary>(
  create: (context) => GenerateMorningSummary(context.read<TaskRepository>()),
),
Provider<CheckUrgentTasksReminder>(
  create: (context) => CheckUrgentTasksReminder(context.read<TaskRepository>()),
),

    ChangeNotifierProvider<ChatProvider>(
      create: (context) => ChatProvider(
        context.read<RouteMessage>(),
        context.read<SpeakResponse>(),
        context.read<GenerateMorningSummary>(),
        context.read<DailyGreetingService>(),
        context.read<CheckUrgentTasksReminder>(),
      ),
    ),
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
    ),
  ];
}