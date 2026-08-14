import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// A solid ink-colored pill CTA — matches the monochrome reference exactly
/// (solid black button in light mode). Resolves from
/// `Theme.of(context).colorScheme` instead of a literal so it stays legible
/// in dark mode too (near-white button, dark label) rather than rendering an
/// invisible black-on-black button.
class AuthButton extends StatelessWidget {
  const AuthButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PressableButtonBase(
      onPressed: onPressed,
      isLoading: isLoading,
      label: label,
      expand: true,
      foregroundColor: colors.surface,
      decoration: BoxDecoration(
        color: colors.onSurface,
        borderRadius: AppRadius.brPill,
      ),
    );
  }
}
