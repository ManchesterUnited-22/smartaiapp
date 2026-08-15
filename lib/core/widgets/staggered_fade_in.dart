// lib/core/widgets/staggered_fade_in.dart
import 'package:flutter/material.dart';

/// Hiện lần lượt từng phần tử con với hiệu ứng fade + trượt nhẹ,
/// dùng cho các khối biểu đồ khi mở ExpansionTile để tạo nhịp điệu mượt mà.
class StaggeredFadeIn extends StatefulWidget {
  final List<Widget> children;
  final Duration stagger;

  const StaggeredFadeIn({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 90),
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  final Set<int> _visible = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.children.length; i++) {
      Future.delayed(widget.stagger * i, () {
        if (mounted) setState(() => _visible.add(i));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          AnimatedOpacity(
            opacity: _visible.contains(i) ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            child: AnimatedSlide(
              offset: _visible.contains(i) ? Offset.zero : const Offset(0, 0.08),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}