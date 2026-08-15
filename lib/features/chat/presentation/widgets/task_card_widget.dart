// lib/features/chat/presentation/widgets/task_card_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:todolist_app/features/tasks/domain/usecases/update_task.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/usecases/complete_task.dart';
import '../../../tasks/domain/usecases/delete_task.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../../core/utils/task_priority_style.dart';
import '../../../tasks/domain/usecases/create_task.dart';
import '../../../tasks/domain/usecases/uncomplete_task.dart';
import 'package:flutter/services.dart';
class TaskCardWidget extends StatefulWidget {
  final Task task;
  const TaskCardWidget({super.key, required this.task});

  @override
  State<TaskCardWidget> createState() => _TaskCardWidgetState();
}

class _TaskCardWidgetState extends State<TaskCardWidget> {
  late bool _isCompleted;
  late TaskPriority _priority;
  late DateTime _dueDate;
  bool _isDeleted = false;
  bool _isRestored = false;
  bool _isBusy = false;
  bool get _isOverdue => !_isCompleted && _dueDate.isBefore(DateTime.now());

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.status == TaskStatus.completed;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
  }
Future<void> _toggleComplete() async {
    if (_isBusy) return;
    final newValue = !_isCompleted;

    HapticFeedback.lightImpact();
    setState(() {
      _isCompleted = newValue;
      _isBusy = true;
    });

    try {
      if (newValue) {
        await context.read<CompleteTask>()(widget.task.id);
      } else {
        await context.read<UncompleteTask>()(widget.task.id);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCompleted = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật, thử lại nhé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

 

  Future<bool> _confirmDelete() async {
    final scheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa task này?'),
            content: Text('"${widget.task.title}" sẽ bị xóa vĩnh viễn.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Xóa', style: TextStyle(color: scheme.error)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleDelete() async {
    final original = widget.task;
    try {
      await context.read<DeleteTask>()(widget.task.id);
      if (mounted) setState(() => _isDeleted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text( 'Đã xóa task '),
          duration: const Duration(seconds:4),
          action: SnackBarAction(
            label:'Hoàn tác',
            onPressed:() => _undoDelete(original),
          )
        )
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa, thử lại nhé.')),
        );
      }
    }
  }
   Future<void> _undoDelete(Task original) async {
    try {
      await context.read<CreateTask>()(
        title: original.title,
        description: original.description,
        dueDate: original.dueDate,
        priority: original.priority,
        tags: original.tags,
        source: original.source,
      );
      if (!mounted) return;
      setState(() => _isRestored = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã khôi phục task ✅')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể khôi phục, thử tạo lại task nhé.')),
        );
      }
    }
  }

  void _openQuickEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _QuickEditSheet(
        title: widget.task.title,
        initialDueDate: _dueDate,
        initialPriority: _priority,
        onSave: (newDueDate, newPriority) async {
          Navigator.pop(sheetContext);
          setState(() {
            _dueDate = newDueDate;
            _priority = newPriority;
          });
          try {
            await context.read<UpdateTask>()(
      taskId: widget.task.id,
      title: widget.task.title,
      newDueDate: newDueDate,
      newPriority: newPriority,
    );
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không thể cập nhật, thử lại nhé.')),
              );
            }
          }
        },
        onDelete: () async {
          Navigator.pop(sheetContext);
          final confirmed = await _confirmDelete();
          if (confirmed) await _handleDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
if (_isRestored) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '"${widget.task.title}" đã được khôi phục thành task mới.',
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    return Dismissible(
      key: ValueKey('task_${widget.task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _handleDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openQuickEditSheet,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isOverdue ? const Color(0xFFDC2626).withOpacity(0.05) : scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                 color: _isOverdue ? const Color(0xFFDC2626).withOpacity(0.5) : scheme.outline.withOpacity(0.4),
                width: _isOverdue ? 1.2 : 1,
                ),
            ),
            child: Row(
              children: [
               GestureDetector(
                  onTap: _toggleComplete,
                  child: AnimatedScale(
                    scale: _isCompleted ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        key: ValueKey(_isCompleted),
                        color: _isCompleted ? scheme.tertiary : _priority.color,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: _isCompleted ? TextDecoration.lineThrough : null,
                          color: _isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
                        ),
                        child: Text(widget.task.title),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                             size: 12, 
                             color: _isOverdue ? const Color ( 0xFFDC2626 ):scheme.onSurfaceVariant
                             ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('dd/MM HH:mm').format(_dueDate),
                            style: TextStyle(fontSize: 11.5, color: _isOverdue ? const Color ( 0xFFDC2626 ):scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                         Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _priority.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _priority.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: _priority.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_isOverdue)...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal:6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Trễ hạn',
                                style: TextStyle(fontSize:10.5, color: Color(0xFFDC2626),fontWeight: FontWeight.w600,)
                              )
                              )
                            
                          ],
                        ],
                      ),
                      if (widget.task.tags.isNotEmpty)...[
                        const SizedBox( height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children:[
                            for (final tag in widget.task.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: scheme.secondaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(fontSize: 10, color: scheme.onSecondaryContainer),
                              ),
                            )
                          ]
                        )
                      ]
                  ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickEditSheet extends StatefulWidget {
  final String title;
  final DateTime initialDueDate;
  final TaskPriority initialPriority;
  final void Function(DateTime dueDate, TaskPriority priority) onSave;
  final VoidCallback onDelete;

  const _QuickEditSheet({
    required this.title,
    required this.initialDueDate,
    required this.initialPriority,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_QuickEditSheet> createState() => _QuickEditSheetState();
}

class _QuickEditSheetState extends State<_QuickEditSheet> {
  late DateTime _dueDate;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDueDate;
    _priority = widget.initialPriority;
  }

  Future<void> _pickCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          Text('Thời gian', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Sau 1 giờ'),
                onPressed: () => setState(() => _dueDate = now.add(const Duration(hours: 1))),
              ),
              ActionChip(
                label: const Text('Tối nay 19h'),
                onPressed: () => setState(() => _dueDate = DateTime(now.year, now.month, now.day, 19)),
              ),
              ActionChip(
                label: const Text('Sáng mai 8h'),
                onPressed: () => setState(() => _dueDate = DateTime(now.year, now.month, now.day + 1, 8)),
              ),
              ActionChip(label: const Text('Chọn khác...'), onPressed: _pickCustomDateTime),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Đã chọn: ${DateFormat('dd/MM/yyyy HH:mm').format(_dueDate)}',
            style: TextStyle(fontSize: 12.5, color: scheme.primary, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),
          Text('Độ ưu tiên', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TaskPriority.values.map((p) {
              return ChoiceChip(
                label: Text(p.label),
                selected: p == _priority,
                onSelected: (_) => setState(() => _priority = p),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  label: Text('Xóa', style: TextStyle(color: scheme.error)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onSave(_dueDate, _priority),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}