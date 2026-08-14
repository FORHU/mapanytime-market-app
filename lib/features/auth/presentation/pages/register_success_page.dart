import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Shown right after a successful registration, replacing the old bare
/// toast-then-redirect flow with a real confirmation moment.
class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.pop(),
      showLogo: false,
      title: context.l10n.registerSuccessTitle,
      subtitle: context.l10n.registerSuccessSubtitle,
      wideTagline: [
        context.l10n.authTaglineDiscover,
        context.l10n.authTaglineTrack,
        context.l10n.authTaglineCheckout,
      ],
      card: Column(
        children: [
          const _SuccessBadge(),
          AppSpacing.xl.v,
          AuthButton(
            label: context.l10n.continueButton,
            onPressed: () => context.go(RouteNames.login),
          ),
        ],
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Dot(top: 8, left: 24, size: 14, alpha: 0.9, color: colors.onSurface),
          _Dot(
            top: 26,
            right: 12,
            size: 6,
            alpha: 0.5,
            color: colors.onSurface,
          ),
          _Dot(
            bottom: 34,
            left: 4,
            size: 10,
            alpha: 0.6,
            color: colors.onSurface,
          ),
          _Dot(
            bottom: 6,
            right: 36,
            size: 6,
            alpha: 0.4,
            color: colors.onSurface,
          ),
          _Dot(
            top: 50,
            right: 24,
            size: 5,
            alpha: 0.7,
            color: colors.onSurface,
          ),
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.onSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: colors.surface, size: 52),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.size,
    required this.alpha,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final double alpha;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
