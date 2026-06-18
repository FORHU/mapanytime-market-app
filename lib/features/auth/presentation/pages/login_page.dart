import 'package:flutter/material.dart';
import 'package:flutter_template/core/theme/app_spacing.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/widgets/login_form.dart';

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
                AppSpacing.gapLg,
                Text(
                  context.l10n.welcomeBack,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                AppSpacing.gapSm,
                Text(
                  context.l10n.signInToContinue,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                AppSpacing.gapXl,
                const LoginForm(),
                AppSpacing.gapMd,
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
