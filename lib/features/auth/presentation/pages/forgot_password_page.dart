import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Step 1 of the password-reset flow: collects the account email and
/// requests a one-time verification code be sent to it.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.pop(),
      title: context.l10n.forgotPasswordTitle,
      subtitle: context.l10n.forgotPasswordSubtitle,
      card: const _ForgotPasswordForm(),
      wideTagline: [
        context.l10n.authTaglineDiscover,
        context.l10n.authTaglineTrack,
        context.l10n.authTaglineCheckout,
      ],
    );
  }
}

class _ForgotPasswordForm extends ConsumerStatefulWidget {
  const _ForgotPasswordForm();

  @override
  ConsumerState<_ForgotPasswordForm> createState() =>
      _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<_ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final result = await ref.read(requestPasswordResetUseCaseProvider)(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold((failure) => showTopToast(context, failure.message), (_) {
      showTopToast(context, context.l10n.resetCodeSent);
      unawaited(context.push(RouteNames.resetPassword, extra: email));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            hint: context.l10n.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          AppSpacing.lg.v,
          PrimaryButton(
            label: context.l10n.nextCta,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
