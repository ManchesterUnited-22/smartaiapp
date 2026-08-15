// lib/features/chat/presentation/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../../../ai_engine/domain/entities/chat_response.dart';
import '../../../ai_engine/domain/usecases/route_message.dart';
import '../../../speech/domain/usecases/speak_response.dart';
import '../../../ai_engine/domain/usecases/generate_morning_summary.dart';
import '../../../ai_engine/domain/usecases/check_urgent_tasks_reminder.dart';
import '../../../../core/services/daily_greeting_service.dart';
enum MessageSender { user, ai }

class ChatMessage {
  final String? text;
  final MessageSender sender;
  final ChatResponse? response;
  final bool isReportSkeleton;

  ChatMessage({this.text, required this.sender, this.response, this.isReportSkeleton = false});
}

class ChatProvider extends ChangeNotifier {
  final RouteMessage routeMessage;
  final SpeakResponse speakResponse;
  final GenerateMorningSummary generateMorningSummary;
  final DailyGreetingService dailyGreetingService;
  final CheckUrgentTasksReminder checkUrgentTasksReminder;
  bool voiceReplyEnabled = true;

  ChatProvider(
    this.routeMessage,
    this.speakResponse,
    this.generateMorningSummary,
    this.dailyGreetingService,
    this.checkUrgentTasksReminder,
  );

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

  /// Nhắc task quá hạn + sắp đến hạn — chạy MỖI LẦN mở app, không giới hạn
  /// 1 lần/ngày như lời chào buổi sáng. Không hiện gì nếu không có gì khẩn.
  Future<void> checkUrgentReminder() async {
    final response = await checkUrgentTasksReminder();
    if (response == null) return;

    messages.add(ChatMessage(sender: MessageSender.ai, response: response));
    notifyListeners();

    if (voiceReplyEnabled) {
      speakResponse(response.message);
    }
  }
  

// Heuristic CHỈ để quyết định UI hiện skeleton sớm — không ảnh hưởng tới
  // việc phân loại ý định thật sự (vẫn do routeMessage/Gemini quyết định).
  static const _reportHintKeywords = [
    'hiệu suất', 'đánh giá', 'phân tích', 'thống kê', 'năng suất',
    'biểu đồ', 'báo cáo', 'tổng kết', 'review', 'nhìn lại', 'kết quả làm việc',
  ];

  bool _looksLikeReportRequest(String text) {
    final normalized = text.toLowerCase();
    return _reportHintKeywords.any((k) => normalized.contains(k));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, sender: MessageSender.user));

    final showSkeleton = _looksLikeReportRequest(text);
    ChatMessage? skeletonMessage;
    if (showSkeleton) {
      skeletonMessage = ChatMessage(sender: MessageSender.ai, isReportSkeleton: true);
      messages.add(skeletonMessage);
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await routeMessage(text);

      if (skeletonMessage != null) {
        messages.remove(skeletonMessage);
      }
      messages.add(ChatMessage(sender: MessageSender.ai, response: response));

      if (voiceReplyEnabled) {
        speakResponse(response.message);
      }
    } catch (e) {
      if (skeletonMessage != null) {
        messages.remove(skeletonMessage);
      }
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

  /// Huỷ 1 hành động đang chờ xác nhận (nút "Hủy" trong MessageBubble).
  /// Thay message đó bằng bản đã gỡ nút xác nhận/lựa chọn, kèm ghi chú
  /// "Đã hủy" để người dùng biết chắc là không có gì bị thực thi.
  void cancelPendingAction(ChatMessage message) {
    final index = messages.indexOf(message);
    if (index == -1) return;

    final oldResponse = message.response;
    if (oldResponse == null) return;

    messages[index] = ChatMessage(
      sender: message.sender,
      response: ChatResponse(
        message: '${oldResponse.message}\n\n_Đã hủy, không có gì thay đổi._',
        task: oldResponse.task,
        taskList: oldResponse.taskList,
        performanceReport: oldResponse.performanceReport,
        // requiresConfirmation/pendingAction/selectionOptions/quickReplies
        // mặc định null/false -> gỡ hết các nút hành động khỏi bubble này.
      ),
    );
    notifyListeners();
  }
  // lib/features/chat/presentation/providers/chat_provider.dart — thêm vào cuối class
  void reset() {
    messages.clear();
    notifyListeners();
  }
}