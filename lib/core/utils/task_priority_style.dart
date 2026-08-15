// lib/core/utils/task_priority_style.dart
import 'package:flutter/material.dart';
import '../../features/tasks/domain/entities/task.dart';

/// Bảng màu & nhãn priority DÙNG CHUNG cho toàn app — mọi nơi hiển thị
/// priority (task card, báo cáo hiệu suất, quick-edit sheet...) đều phải
/// tham chiếu từ đây để tránh lệch màu giữa các màn hình.
extension TaskPriorityStyle on TaskPriority {
  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFDC2626);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.medium:
        return 'Trung bình';
      case TaskPriority.low:
        return 'Thấp';
    }
  }
}