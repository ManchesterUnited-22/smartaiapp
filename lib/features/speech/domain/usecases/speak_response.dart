// lib/features/speech/domain/usecases/speak_response.dart
import '../../data/datasources/text_to_speech_datasource.dart';

class SpeakResponse {
  final TextToSpeechDatasource datasource;
  SpeakResponse(this.datasource);

  Future<void> call(String text) => datasource.speak(text);
  Future<void> stop() => datasource.stop();
}