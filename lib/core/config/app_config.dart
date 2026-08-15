// lib/core/config/app_config.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env.dart';

class AppConfig {
  // Gemini
  static String get geminiApiKey => Env.geminiApiKey;
  static bool get isGeminiConfigured => Env.isGeminiKeyValid;

  // Model
  static const String geminiModel = 'gemini-2.5-flash';
  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent';

  // Timeout
  static const Duration apiTimeout = Duration(seconds: 15);

  // App
  static const String appName = 'AI Life Companion';
}