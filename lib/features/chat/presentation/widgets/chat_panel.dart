// lib/features/chat/presentation/widgets/chat_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'chat_input_bar.dart';
import 'empty_chat_state.dart';
import 'typing_indicator.dart';

/// Khung chat AI thuần (không Scaffold/AppBar) — nhúng vào bottom sheet
/// mở ra từ nút AI nổi trên HomeScreen.
class ChatPanel extends StatefulWidget {
  final ScrollController? scrollController;
  const ChatPanel({super.key, this.scrollController});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  ScrollController? _internalController;
  ScrollController get _controller => widget.scrollController ?? (_internalController ??= ScrollController());

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        _scrollToBottom();
        return Column(
          children: [
            Expanded(
              child: chat.messages.isEmpty
                  ? EmptyChatState(onSuggestionTap: (text) => chat.sendMessage(text))
                  : ListView.builder(
                      controller: _controller,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) => MessageBubble(
                        message: chat.messages[index],
                        onConfirm: (action) => chat.confirmAction(action),
                        onQuickReply: (text) => chat.sendMessage(text),
                        onCancel: (message) => chat.cancelPendingAction(message),
                      ),
                    ),
            ),
            if (chat.isLoading) const TypingIndicator(),
            ChatInputBar(onSend: (text) => chat.sendMessage(text)),
          ],
        );
      },
    );
  }
}