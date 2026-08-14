import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_logo.dart';
import 'package:mapanytime_market_app/shared/widgets/fade_slide_in.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/theme/app_theme.dart';
import 'package:mapanytime_market_app/theme/tokens/breakpoints.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Shared shell for the five auth screens (login/register/forgot/reset
/// password/register-success): a plain flat canvas (matching the reference
/// mocks exactly — no decorative backdrop), staggered entrance, and a
/// single-column phone layout that switches to a two-pane brand+form layout
/// at [AppBreakpoints.tablet] and above.
///
/// Renders under a **locally-scoped** light [Theme] override — this is the
/// only place in the app that runs light; the rest of the app stays on the
/// app-wide (dark) `MaterialApp` theme, untouched. There's no user-facing
/// toggle; auth is always light.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.card,
    required this.wideTagline,
    this.footer,
    this.onBack,
    this.showLogo = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget card;

  /// Feature bullets shown in the brand panel on wide screens only.
  final List<String> wideTagline;
  final Widget? footer;
  final VoidCallback? onBack;

  /// Whether the small brand logo renders above the title on narrow (phone)
  /// layouts. The wide brand panel always shows its own larger logo
  /// regardless. Set false for moments that already have their own hero
  /// visual (e.g. a success-screen badge) so the two don't compete.
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: ModernAppBar(showBack: onBack != null, onBack: onBack),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
              final form = _FormColumn(
                title: title,
                subtitle: subtitle,
                card: card,
                footer: footer,
                showLogo: !isWide && showLogo,
              );

              if (!isWide) {
                return SingleChildScrollView(
                  padding: AppSpacing.edgeInsetsLg,
                  child: form,
                );
              }

              return Row(
                children: [
                  Expanded(child: _BrandPanel(taglines: wideTagline)),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: AppSpacing.edgeInsetsXl,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.subtitle,
    required this.card,
    required this.showLogo,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget card;
  final bool showLogo;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLogo) ...[
          const FadeSlideIn(child: Center(child: AuthLogo())),
          AppSpacing.lg.v,
        ],
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              AppSpacing.sm.v,
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.xl.v,
        FadeSlideIn(delay: const Duration(milliseconds: 160), child: card),
        if (footer != null) ...[AppSpacing.lg.v, footer!],
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.taglines});

  final List<String> taglines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.edgeInsetsXl,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthLogo(size: 96),
              AppSpacing.lg.v,
              Text(
                context.l10n.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              AppSpacing.md.v,
              for (final line in taglines) ...[
                _TaglineRow(text: line),
                AppSpacing.sm.v,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaglineRow extends StatelessWidget {
  const _TaglineRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.brand.primary,
        ),
        AppSpacing.sm.h,
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
