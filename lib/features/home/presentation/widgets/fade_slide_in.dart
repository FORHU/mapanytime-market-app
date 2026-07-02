import 'package:flutter/material.dart';

/// A lightweight one-shot entrance animation: fades and slides its [child] up
/// on first build. Stateless-friendly (uses [TweenAnimationBuilder]) and safe
/// to nest — pass a small [delay] per section to stagger a list.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
    super.key,
  });

  final Widget child;
  final Duration delay;

  /// Initial downward offset in logical pixels (animates to 0).
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        // Apply the per-section [delay] by clamping progress until it elapses.
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
