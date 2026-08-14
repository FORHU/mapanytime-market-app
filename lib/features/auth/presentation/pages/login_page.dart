import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/login_form.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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
}
