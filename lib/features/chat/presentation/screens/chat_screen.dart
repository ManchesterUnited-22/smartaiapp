// lib/features/chat/presentation/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/core/services/auth_services.dart';
import 'package:todolist_app/features/chat/presentation/widgets/today_tasks_bar.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/typing_indicator.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/aura_orb.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().checkMorningGreeting();
    });
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 19, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const AuraOrb(size: 26),
            const SizedBox(width: 10),
            const Text('AI Life Companion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => _iconButton(
              chat.voiceReplyEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              chat.toggleVoiceReply,
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => _iconButton(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              themeProvider.toggleTheme,
            ),
          ),
          _iconButton(Icons.logout_rounded, () => context.read<AuthService>().signOut()),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          _scrollToBottom();
          return Column(
            children: [
              const TodayTasksBar(),
              Expanded(
                child: chat.messages.isEmpty
                    ? EmptyChatState(onSuggestionTap: (text) => chat.sendMessage(text))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                            message: chat.messages[index],
                            onConfirm: (action) => chat.confirmAction(action),
                            onQuickReply: (text) => chat.sendMessage(text),
                          );
                        },
                      ),
              ),
              if (chat.isLoading) const TypingIndicator(),
              ChatInputBar(onSend: (text) => chat.sendMessage(text)),
            ],
          );
        },
      ),
    );
  }
}