// lib/core/config/env.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static bool get isGeminiKeyValid => geminiApiKey.isNotEmpty && geminiApiKey.startsWith('AIza');

  /// Load .env file. Gọi ở main() trước khi chạy app.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}