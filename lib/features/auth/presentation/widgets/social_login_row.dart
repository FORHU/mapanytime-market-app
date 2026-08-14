import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "Or sign in with" divider + a Google button. No OAuth integration exists
/// yet, so this is visually present but disabled — a tap surfaces a "coming
/// soon" toast instead of doing nothing silently or attempting a real
/// sign-in.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colors.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                context.l10n.orSignInWith,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: colors.outline)),
          ],
        ),
        AppSpacing.md.v,
        _SocialButton(
          label: context.l10n.continueWithGoogle,
          letter: 'G',
          badgeColor: colors.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.letter,
    required this.badgeColor,
  });

  final String label;
  final String letter;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: 0.6,
      child: GestureDetector(
        onTap: () => showTopToast(context, context.l10n.comingSoon),
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: AppRadius.brPill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: badgeColor,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: colors.surface,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppSpacing.sm.h,
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
