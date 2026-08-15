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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chat = context.read<ChatProvider>();
      await chat.checkMorningGreeting();
      await chat.checkUrgentReminder();
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            onPressed: () => _confirmSignOut(context),
          ),
          const SizedBox(width: 4),
        ],
        // Trong suốt để hoà vào theme (AppBarTheme) thay vì đè màu cứng,
        // giữ đồng bộ với app_theme.dart.
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // Gradient nhẹ phía sau AppBar cho cảm giác sinh động, chiều sâu hơn
        // thay vì nền phẳng một màu.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primaryContainer.withValues(alpha: isDark ? 0.16 : 0.35),
              scheme.surface.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.35],
          ),
        ),
        child: SafeArea(
          child: ChatPanel(),
        ),
      ),
    );
  }
}