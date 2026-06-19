import 'package:flutter/material.dart';
import 'package:mapanytime_market_web/theme/tokens/spacing.dart';
import 'package:mapanytime_market_web/core/utils/context_extensions.dart';
import 'package:mapanytime_market_web/features/auth/presentation/widgets/login_form.dart';

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
                const Icon(Icons.flutter_dash, size: AppSpacing.xxxl),
                AppSpacing.lg.v,
                Text(
                  context.l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                AppSpacing.sm.v,
                Text(
                  context.l10n.signInToContinue,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppSpacing.xl.v,
                const LoginForm(),
                AppSpacing.md.v,
                Text(
                  context.l10n.loginHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
