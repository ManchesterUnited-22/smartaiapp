// lib/core/services/daily_greeting_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class DailyGreetingService {
  static const _lastGreetingKey = 'last_morning_greeting_date';

  Future<bool> shouldShowMorningGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastGreetingKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    return lastDateStr != todayStr;
  }

  Future<void> markGreetingShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lastGreetingKey, todayStr);
  }
}