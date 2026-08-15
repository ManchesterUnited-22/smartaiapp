// lib/features/speech/data/datasources/text_to_speech_datasource.dart
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechDatasource {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _initialize() async {
    if (_isInitialized) return;
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
     try {
      await _initialize();
      await _tts.stop(); // dừng câu đang đọc dở (nếu có) trước khi đọc câu mới
      await _tts.speak(text);
    } catch (_) {
      // Nuốt lỗi TTS có chủ đích — đọc to chỉ là tính năng phụ,
      // lỗi ở đây không được phép làm gián đoạn luồng chat chính.
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}