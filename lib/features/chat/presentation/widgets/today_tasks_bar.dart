// lib/features/chat/presentation/widgets/today_tasks_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/domain/usecases/complete_task.dart';

class TodayTasksBar extends StatefulWidget {
  const TodayTasksBar({super.key});

  @override
  State<TodayTasksBar> createState() => _TodayTasksBarState();
}

class _TodayTasksBarState extends State<TodayTasksBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final taskRepository = context.read<TaskRepository>();

    return StreamBuilder<List<Task>>(
      stream: taskRepository.watchTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        final todayTasks = snapshot.data!.where((t) {
          return t.dueDate.year == now.year &&
              t.dueDate.month == now.month &&
              t.dueDate.day == now.day;
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        if (todayTasks.isEmpty) return const SizedBox.shrink();

        final completedCount = todayTasks.where((t) => t.status == TaskStatus.completed).length;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.today_rounded, size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hôm nay · $completedCount/${todayTasks.length} hoàn thành',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Column(
                    children: todayTasks.map((t) => _TodayTaskRow(task: t)).toList(),
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayTaskRow extends StatefulWidget {
  final Task task;
  const _TodayTaskRow({required this.task});

  @override
  State<_TodayTaskRow> createState() => _TodayTaskRowState();
}

class _TodayTaskRowState extends State<_TodayTaskRow> {
  bool _isBusy = false;

  Future<void> _toggle() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (widget.task.status == TaskStatus.completed) {
        await context.read<TaskRepository>().updateTask(widget.task.id, {
          'status': 'pending',
          'completedAt': null,
        });
      } else {
        await context.read<CompleteTask>()(widget.task.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật, thử lại nhé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Color _priorityColor(BuildContext context) {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = widget.task.status == TaskStatus.completed;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isDone ? scheme.tertiary : _priorityColor(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.task.title,
                style: TextStyle(
                  fontSize: 13,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
            Text(
              '${widget.task.dueDate.hour.toString().padLeft(2, '0')}:${widget.task.dueDate.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}