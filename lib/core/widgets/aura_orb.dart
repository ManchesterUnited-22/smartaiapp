// lib/core/widgets/aura_orb.dart
import 'package:flutter/material.dart';

class AuraOrb extends StatefulWidget {
  final double size;
  final bool animate;

  const AuraOrb({super.key, this.size = 36, this.animate = false});

  @override
  State<AuraOrb> createState() => _AuraOrbState();
}

class _AuraOrbState extends State<AuraOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AuraOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.animate ? _controller.value : 0.4;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                scheme.primary,
                scheme.secondary.withOpacity(0.85),
              ],
              radius: 0.95,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.25 + t * 0.25),
                blurRadius: widget.size * (0.5 + t * 0.4),
                spreadRadius: widget.size * 0.02,
              ),
            ],
          ),
        );
      },
    );
  }
}