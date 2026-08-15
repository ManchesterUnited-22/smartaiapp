// lib/core/constants/app_constants.dart

class AppConstants {
  // App info
  static const String appName = 'AI Life Companion';
  static const String appVersion = '1.0.0';

  // Context & timeout
  static const int conversationContextMinutes = 5;
  static const int geminiTimeoutSeconds = 15;
  static const int maxRetryCount = 1;

  // Task defaults
  static const String defaultTaskSource = 'manual';
  static const String aiTaskSource = 'ai_chat';

  // Notification
  static const String notificationChannelId = 'task_reminders';
  static const String notificationChannelName = 'Nhắc việc';
  static const String notificationChannelDesc = 'Thông báo nhắc nhở công việc sắp đến hạn';

  // Quick replies mẫu
  static const List<String> defaultCreateQuickReplies = [
    '9h sáng mai, ưu tiên cao',
    '14h chiều nay, ưu tiên trung bình',
    'Tối nay 20h',
  ];
}