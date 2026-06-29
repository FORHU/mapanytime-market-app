import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_logo.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/register_form.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: ModernAppBar(
        onBack: () => context.go(RouteNames.login),
      ),
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
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                AppSpacing.sm.v,
                Text(
                  'Join MapAnytime Market as a buyer',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text.secondaryDark),
                ),
                AppSpacing.xl.v,
                const GlassCard(child: RegisterForm()),
                AppSpacing.md.v,
                _LoginLink(onTap: () => context.go(RouteNames.login)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: TextStyle(color: AppColors.text.secondaryDark),
          children: [
            TextSpan(
              text: 'Log in',
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
