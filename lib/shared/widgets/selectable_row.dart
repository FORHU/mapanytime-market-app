import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// The app's one selection rule, as a component: unselected = surface-muted
/// fill + primary text; selected = solid ink fill + white content. Drives
/// CategoryChip (pill shape) and single-select lists like Checkout's
/// payment-method rows (via showCheck). Never introduce a second "this is
/// chosen" treatment — no colored border, no checkbox/radio as the primary
/// signal. Everything that means "selected" uses this.
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    required this.selected,
    required this.onTap,
    required this.label,
    this.icon,
    this.iconSize = 20,
    this.showCheck = false,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
    this.labelStyle,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final double iconSize;

  /// Trailing check/radio glyph that inverts color with the row. Off by
  /// default (pill chips don't need one); Checkout's payment rows turn it on.
  final bool showCheck;

  /// Defaults to [AppRadius.brLg].
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected
        ? AppColors.text.onInk
        : AppColors.text.primary;

    Widget label0 = Text(
      label,
      style:
          (labelStyle ??
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
              .copyWith(color: contentColor),
    );
    if (showCheck) label0 = Expanded(child: label0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.ui.surfaceMuted,
          borderRadius: borderRadius ?? AppRadius.brLg,
        ),
        child: Row(
          mainAxisSize: showCheck ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: contentColor),
              const Gap(AppSpacing.sm),
            ],
            label0,
            if (showCheck) ...[
              const Gap(AppSpacing.sm),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: iconSize,
                color: contentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
