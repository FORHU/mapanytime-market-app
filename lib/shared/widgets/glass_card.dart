import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// The general-purpose card surface. Depth comes from fill contrast plus
/// one soft shadow tier ([AppEffects.cardShadow]) — never a border by
/// default and never glassmorphism (there is no blur mode; the system has
/// none, per DESIGN.md). [border] exists only for the rare case a white
/// card needs to separate from an equally-white background.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.card,
    this.onTap,
    this.color,
    this.border = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final colors = Theme.of(context).colorScheme;

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: borderRadius,
        border: border ? Border.all(color: colors.outline) : null,
        boxShadow: AppEffects.cardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    content = ClipRRect(borderRadius: borderRadius, child: content);

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: content),
    );
  }
}
