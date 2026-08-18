import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Solid ink CTA button — the only button fill in the system. There is no
/// bordered/outlined variant and no gradient variant; a less-prominent
/// action becomes a plain text button, not a different-colored pill.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return PressableButtonBase(
      onPressed: onPressed,
      expand: expand,
      isLoading: isLoading,
      label: label,
      icon: icon,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadius.brPill,
        boxShadow: AppEffects.softShadow,
      ),
    );
  }
}

/// The shared pressable shape/interaction (scale-on-tap, disabled fade,
/// loading spinner) behind [PrimaryButton]. Reuse this for any new button
/// variant rather than re-implementing the press behavior.
class PressableButtonBase extends StatefulWidget {
  const PressableButtonBase({
    required this.label,
    required this.onPressed,
    required this.decoration,
    required this.expand,
    required this.isLoading,
    this.icon,
    this.foregroundColor = Colors.white,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final BoxDecoration decoration;
  final bool expand;
  final bool isLoading;
  final IconData? icon;
  final Color foregroundColor;

  @override
  State<PressableButtonBase> createState() => _PressableButtonBaseState();
}

class _PressableButtonBaseState extends State<PressableButtonBase> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setDown({required bool value}) => setState(() => _down = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _enabled ? (_) => _setDown(value: true) : null,
      onTapUp: _enabled ? (_) => _setDown(value: false) : null,
      onTapCancel: _enabled ? () => _setDown(value: false) : null,
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.expand ? double.infinity : null,
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: widget.decoration,
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(
                        widget.foregroundColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.foregroundColor,
                          size: 20,
                        ),
                        const Gap(AppSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.foregroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
