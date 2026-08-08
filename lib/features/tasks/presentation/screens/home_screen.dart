// lib/features/tasks/presentation/screens/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../../chat/presentation/widgets/task_card_widget.dart';
import '../../../chat/presentation/widgets/chat_panel.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../../core/widgets/aura_orb.dart';
import '../../../../core/services/auth_services.dart';
import '../../../../core/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().checkMorningGreeting();
    });
  }

  void _openAiChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiChatSheet(),
    );
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddTaskSheet(),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng ☀️';
    if (hour < 14) return 'Chào buổi trưa 🌤️';
    if (hour < 18) return 'Chào buổi chiều 🌥️';
    return 'Chào buổi tối 🌙';
  }

  List<Task> _sortedTasks(List<Task> tasks) {
    final sorted = [...tasks]..sort((a, b) {
        if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) return 1;
        if (b.status == TaskStatus.completed && a.status != TaskStatus.completed) return -1;
        return a.dueDate.compareTo(b.dueDate);
      });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<TaskRepository>();

    return Scaffold(
      body: StreamBuilder<List<Task>>(
        stream: repository.watchTasks(status: _filter),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final sorted = _sortedTasks(tasks);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeaderStats(greeting: _greeting()),
                ),
                actions: [
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: Colors.white,
                      ),
                      onPressed: themeProvider.toggleTheme,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () => context.read<AuthService>().signOut(),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm việc'),
                        onPressed: _showAddTaskSheet,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: {
                              'Tất cả': null,
                              'Đang chờ': TaskStatus.pending,
                              'Đang làm': TaskStatus.inProgress,
                              'Hoàn thành': TaskStatus.completed,
                            }.entries.map((e) {
                              final selected = _filter == e.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(e.key),
                                  selected: selected,
                                  onSelected: (_) => setState(() => _filter = e.value),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (snapshot.hasError)
  SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Có lỗi khi tải danh sách:\n${snapshot.error}', textAlign: TextAlign.center),
      ),
    ),
  )
              else if (tasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Chưa có công việc nào. Bấm "Thêm việc" để bắt đầu!')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TaskCardWidget(task: sorted[index]),
                      childCount: sorted.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _AiFabButton(onTap: _openAiChat),
    );
  }
}

/// Header gradient hiển thị lời chào + vòng tròn % hoàn thành hôm nay.
/// Tách StatefulWidget riêng và gọi Future 1 lần trong initState —
/// KHÔNG gọi thẳng trong build(), vì FlexibleSpaceBar rebuild liên tục
/// khi cuộn, gọi Firestore lặp lại sẽ rất tốn tài nguyên.
class _HeaderStats extends StatefulWidget {
  final String greeting;
  const _HeaderStats({required this.greeting});

  @override
  State<_HeaderStats> createState() => _HeaderStatsState();
}

class _HeaderStatsState extends State<_HeaderStats> {
  late final Future<List<Task>> _todayTasksFuture;

  @override
  void initState() {
    super.initState();
    final repository = context.read<TaskRepository>();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    _todayTasksFuture = repository.queryTasksByDateRange(startOfDay, endOfDay);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(widget.greeting, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              const Text('Công việc của tôi',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              FutureBuilder<List<Task>>(
                future: _todayTasksFuture,
                builder: (context, snapshot) {
                  final todayTasks = snapshot.data ?? [];
                  final completed = todayTasks.where((t) => t.status == TaskStatus.completed).length;
                  final total = todayTasks.length;
                  final ratio = total == 0 ? 0.0 : completed / total;
                  return Row(
                    children: [
                      SizedBox(
                        width: 44, height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: ratio,
                              strokeWidth: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                            Text('${(ratio * 100).round()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          total == 0 ? 'Chưa có việc nào hôm nay' : 'Hoàn thành $completed/$total việc hôm nay',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút tròn AI nổi — gradient + glow, dùng lại AuraOrb sẵn có để đồng bộ
/// hình ảnh thương hiệu AI trong toàn app.
class _AiFabButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AiFabButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: scheme.primary.withOpacity(0.5), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: AuraOrb(size: 40, animate: true),
        ),
      ),
    );
  }
}

/// Bottom sheet chứa khung chat AI, mở lên khi bấm nút tròn nổi.
class _AiChatSheet extends StatelessWidget {
  const _AiChatSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final scheme = Theme.of(context).colorScheme;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: scheme.surface.withOpacity(0.97),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: scheme.outline, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      const AuraOrb(size: 22),
                      const SizedBox(width: 8),
                      const Text('Trợ lý AI', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Consumer<ChatProvider>(
                        builder: (context, chat, _) => IconButton(
                          icon: Icon(chat.voiceReplyEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                          onPressed: chat.toggleVoiceReply,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  Expanded(child: ChatPanel(scrollController: scrollController)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Form tạo task thủ công — giữ nguyên như bản trước, chỉ chuyển sang file mới.
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(hours: 1));
  TaskPriority _priority = TaskPriority.medium;
  bool _isSaving = false;

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.low:
        return 'Thấp';
    }
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate));
    if (time == null) return;
    setState(() => _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chưa nhập tên task.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<CreateTask>()(title: title, dueDate: _dueDate, priority: _priority, source: 'manual');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tạo task, thử lại nhé.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: scheme.outline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Task mới', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Tên công việc...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          Text('Thời gian', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ActionChip(label: const Text('Sau 1 giờ'), onPressed: () => setState(() => _dueDate = now.add(const Duration(hours: 1)))),
              ActionChip(label: const Text('Tối nay 19h'), onPressed: () => setState(() => _dueDate = DateTime(now.year, now.month, now.day, 19))),
              ActionChip(label: const Text('Sáng mai 8h'), onPressed: () => setState(() => _dueDate = DateTime(now.year, now.month, now.day + 1, 8))),
              ActionChip(label: const Text('Chọn khác...'), onPressed: _pickCustomDateTime),
            ],
          ),
          const SizedBox(height: 6),
          Text('Đã chọn: ${DateFormat('dd/MM/yyyy HH:mm').format(_dueDate)}',
              style: TextStyle(fontSize: 12.5, color: scheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Text('Độ ưu tiên', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TaskPriority.values.map((p) => ChoiceChip(
                  label: Text(_priorityLabel(p)),
                  selected: p == _priority,
                  onSelected: (_) => setState(() => _priority = p),
                )).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tạo task'),
            ),
          ),
        ],
      ),
    );
  }
}