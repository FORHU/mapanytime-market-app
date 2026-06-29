import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_logo.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/login_form.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.edgeInsetsLg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AuthLogo()),
                AppSpacing.lg.v,
                Text(
                  context.l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                AppSpacing.sm.v,
                Text(
                  context.l10n.signInToContinue,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text.secondaryDark),
                ),
                AppSpacing.xl.v,
                const GlassCard(child: LoginForm()),
                AppSpacing.md.v,
                Text(
                  context.l10n.loginHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.tertiaryDark,
                  ),
                ),
                AppSpacing.sm.v,
                _SignUpLink(onTap: () => context.go(RouteNames.register)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpLink extends StatelessWidget {
  const _SignUpLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(color: AppColors.text.secondaryDark),
          children: [
            TextSpan(
              text: 'Sign up',
              style: TextStyle(
                color: AppColors.brand.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
