// lib/features/chat/presentation/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../../../ai_engine/domain/entities/chat_response.dart';
import '../../../ai_engine/domain/usecases/route_message.dart';
import '../../../speech/domain/usecases/speak_response.dart';
import '../../../ai_engine/domain/usecases/generate_morning_summary.dart';
import '../../../../core/services/daily_greeting_service.dart';
enum MessageSender { user, ai }

class ChatMessage {
  final String? text;
  final MessageSender sender;
  final ChatResponse? response;

  ChatMessage({this.text, required this.sender, this.response});
}

class ChatProvider extends ChangeNotifier {
  final RouteMessage routeMessage;
  final SpeakResponse speakResponse;
  final GenerateMorningSummary generateMorningSummary;
  final DailyGreetingService dailyGreetingService;
  bool voiceReplyEnabled = true;

  ChatProvider(this.routeMessage, this.speakResponse, this.generateMorningSummary, this.dailyGreetingService);

  final List<ChatMessage> messages = [];
  bool isLoading = false;
  Future<void> checkMorningGreeting()=> _checkMorningGreeting();
   Future<void> _checkMorningGreeting() async {
    final shouldShow = await dailyGreetingService.shouldShowMorningGreeting();
    if (!shouldShow) return;

    isLoading = true;
    notifyListeners();

    final response = await generateMorningSummary();
    messages.add(ChatMessage(sender: MessageSender.ai, response: response));
    await dailyGreetingService.markGreetingShown();

    isLoading = false;
    notifyListeners();

    if (voiceReplyEnabled) {
      speakResponse(response.message);
    }
  }
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, sender: MessageSender.user));
    isLoading = true;
    notifyListeners();

    try {
      final response = await routeMessage(text);
      messages.add(ChatMessage(sender: MessageSender.ai, response: response));

      if (voiceReplyEnabled) {
        speakResponse(response.message);
      }
    } catch (e) {
      final errorMsg = 'Có lỗi xảy ra: $e';
      messages.add(ChatMessage(
        sender: MessageSender.ai,
        response: ChatResponse(message: errorMsg),
      ));
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> confirmAction(Map<String, dynamic> pendingAction) async {
    isLoading = true;
    notifyListeners();

    final response = await routeMessage.confirmPendingAction(pendingAction);
    messages.add(ChatMessage(sender: MessageSender.ai, response: response));

    if (voiceReplyEnabled) {
      speakResponse(response.message);
    }

    isLoading = false;
    notifyListeners();
  }

  void toggleVoiceReply() {
    voiceReplyEnabled = !voiceReplyEnabled;
    if (!voiceReplyEnabled) speakResponse.stop();
    notifyListeners();
  }
}