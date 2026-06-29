import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A gradient FAB with a soft glow and press animation. Optionally extended
/// with a [label].
class AnimatedFab extends StatefulWidget {
  const AnimatedFab({
    required this.icon,
    required this.onPressed,
    this.label,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? label;

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab> {
  bool _down = false;

  void _setDown({required bool value}) => setState(() => _down = value);

  @override
  Widget build(BuildContext context) {
    final extended = widget.label != null;
    return GestureDetector(
      onTapDown: (_) => _setDown(value: true),
      onTapUp: (_) => _setDown(value: false),
      onTapCancel: () => _setDown(value: false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 56,
          width: extended ? null : 56,
          padding: extended
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
              : null,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.brPill,
            boxShadow: AppEffects.primaryGlow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 24),
              if (extended) ...[
                const Gap(AppSpacing.sm),
                Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
