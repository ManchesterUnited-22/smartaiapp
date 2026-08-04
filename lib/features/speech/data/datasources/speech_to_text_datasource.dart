// lib/features/speech/data/datasources/speech_to_text_datasource.dart
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextDatasource {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    String localeId = 'vi_VN',
  }) async {
    final available = await initialize();
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