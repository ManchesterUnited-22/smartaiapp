// lib/core/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Dùng key có tiền tố rõ ràng để tránh 2 loại thông báo (nhắc trước / quá hạn)
  // của cùng 1 task bị trùng ID và ghi đè lên nhau.
  int _reminderId(String taskId) => 'reminder_$taskId'.hashCode;
  int _overdueId(String taskId) => 'overdue_$taskId'.hashCode;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  /// Nhắc trước khi đến hạn (mặc định 15 phút trước giờ deadline).
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime reminderTime,
  }) async {
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _reminderId(taskId),
      'Sắp đến giờ làm việc',
      '"$title" sắp đến hạn — 15 phút nữa thôi!',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Nhắc nhở task',
          channelDescription: 'Thông báo nhắc nhở công việc sắp đến hạn',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cảnh báo đúng thời điểm task quá hạn (bắn đúng lúc dueDate trôi qua).
  /// Nếu lúc đó task đã hoàn thành/bị xóa, thông báo này đã được huỷ từ trước
  /// (xem cancelReminder), nên sẽ không bắn nhầm.
  Future<void> scheduleOverdueAlert({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {
    if (dueDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _overdueId(taskId),
      '⚠️ Task đã quá hạn',
      '"$title" đã đến hạn nhưng có thể bạn chưa hoàn thành. Kiểm tra ngay nhé!',
      tz.TZDateTime.from(dueDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_overdue',
          'Task quá hạn',
          channelDescription: 'Cảnh báo khi công việc đã trễ hạn nhưng chưa hoàn thành',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Huỷ CẢ 2 loại thông báo (nhắc trước + quá hạn) của 1 task —
  /// dùng khi task hoàn thành, bị xoá, hoặc cần lên lịch lại sau khi sửa giờ.
  Future<void> cancelReminder(String taskId) async {
    await _plugin.cancel(_reminderId(taskId));
    await _plugin.cancel(_overdueId(taskId));
  }
}