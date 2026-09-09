import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/login_form.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/fade_slide_in.dart';
import 'package:mapanytime_market_app/theme/tokens/breakpoints.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The hero-photo treatment is a phone-first pattern; tablets keep the
        // existing two-pane brand+form layout shared with the other auth
        // screens.
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return AuthScaffold(
            title: context.l10n.welcomeBack,
            subtitle: context.l10n.signInToContinue,
            card: const LoginForm(),
            wideTagline: [
              context.l10n.authTaglineDiscover,
              context.l10n.authTaglineTrack,
              context.l10n.authTaglineCheckout,
            ],
            footer: AuthSwitchLink(
              prompt: context.l10n.dontHaveAccount,
              actionLabel: context.l10n.signUp,
              onTap: () => context.go(RouteNames.register),
            ),
          );
        }
        return const _LoginHeroLayout();
      },
    );
  }
}

/// Phone layout: a full-bleed hero photo behind the status bar, with a
/// rounded white sheet sliding up over it to hold the sign-in form.
class _LoginHeroLayout extends StatelessWidget {
  const _LoginHeroLayout();

  static const _heroHeight = 260.0;
  static const _sheetOverlap = 32.0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _HeroHeader.placeholderColor,
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _heroHeight,
              child: _HeroHeader(),
            ),
            Positioned(
              top: _heroHeight - _sheetOverlap,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ui.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.welcomeBack,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                              AppSpacing.xs.v,
                              Text(
                                context.l10n.signInToContinue,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.xl.v,
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 80),
                          child: LoginForm(),
                        ),
                        AppSpacing.lg.v,
                        AuthSwitchLink(
                          prompt: context.l10n.dontHaveAccount,
                          actionLabel: context.l10n.signUp,
                          onTap: () => context.go(RouteNames.register),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder hero background — no storefront/pickup-counter photo asset
/// exists in this app yet. Uses the same fallback tone the design mockup
/// itself specifies for an unloaded image slot, so swapping in a real photo
/// later is a drop-in change, not a restructure.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  static const placeholderColor = Color(0xFF1E2230);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: placeholderColor,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // rgba(13,13,15,0.45) -> rgba(13,13,15,0)
                  colors: [Color(0x730D0D0F), Color(0x000D0D0F)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: MediaQuery.of(context).padding.top + 18,
            child: Text(
              context.l10n.wordmark,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
