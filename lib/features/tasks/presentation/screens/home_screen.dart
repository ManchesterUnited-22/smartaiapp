// lib/features/tasks/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/widgets/aura_orb.dart';
import '../../../../core/services/auth_services.dart';
import '../../../../core/providers/theme_provider.dart';

/// Màn hình DUY NHẤT của app: toàn bộ tương tác (tạo/sửa/xóa/xem task,
/// báo cáo hiệu suất, nhắc việc...) đều đi qua AI chat — không còn
/// list task hay form nhập liệu thủ công.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().checkMorningGreeting();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const AuraOrb(size: 26, animate: true),
            const SizedBox(width: 10),
            const Text('Trợ lý AI', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chat, _) => IconButton(
              tooltip: chat.voiceReplyEnabled ? 'Tắt đọc trả lời' : 'Bật đọc trả lời',
              icon: Icon(chat.voiceReplyEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              onPressed: chat.toggleVoiceReply,
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              tooltip: 'Đổi giao diện',
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: themeProvider.toggleTheme,
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
          const SizedBox(width: 4),
        ],
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ChatPanel(),
      ),
    );
  }
}