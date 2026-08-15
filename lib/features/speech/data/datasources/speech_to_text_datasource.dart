// lib/features/speech/data/datasources/speech_to_text_datasource.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextDatasource {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  final List<void Function(String status)> _statusListeners = [];

  void addStatusListener(void Function(String status) callback) {
    _statusListeners.add(callback);
  }

  void removeStatusListener(void Function(String status) callback) {
    _statusListeners.remove(callback);
  }

  Future<bool> initialize({void Function(String message)? onError}) async {
    if (_isInitialized) return true;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      onError?.call('Cần quyền truy cập micro để dùng tính năng này. Vui lòng cấp quyền trong Cài đặt.');
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => onError?.call('Không nhận diện được giọng nói, thử lại nhé.'),
      onStatus: (status) {
        for (final listener in _statusListeners) {
          listener(status);
        }
      },
    );

    if (!_isInitialized) {
      onError?.call('Thiết bị không hỗ trợ nhận diện giọng nói.');
    }

    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    void Function(String message)? onError,
    String localeId = 'vi_VN',
  }) async {
    final available = await initialize(onError: onError);
    if (!available) return;

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}