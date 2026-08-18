import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/otp_code_field.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Step 2 of the password-reset flow: the user enters the code emailed to
/// them plus a new password.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => context.pop(),
      title: context.l10n.resetPasswordTitle,
      subtitle: context.l10n.resetPasswordSubtitle(email),
      card: _ResetPasswordForm(email: email),
      wideTagline: [
        context.l10n.authTaglineDiscover,
        context.l10n.authTaglineTrack,
        context.l10n.authTaglineCheckout,
      ],
    );
  }
}

class _ResetPasswordForm extends ConsumerStatefulWidget {
  const _ResetPasswordForm({required this.email});

  final String email;

  @override
  ConsumerState<_ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends ConsumerState<_ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String _code = '';
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await ref.read(resetPasswordUseCaseProvider)(
      widget.email,
      _code,
      _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold((failure) => showTopToast(context, failure.message), (_) {
      showTopToast(context, context.l10n.passwordResetSuccess);
      context.go(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OtpCodeField(
            onChanged: (value) => _code = value,
            validator: (v) => (v == null || v.length != 4)
                ? context.l10n.verificationCodeInvalid
                : null,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: context.l10n.newPassword,
            controller: _newPasswordController,
            obscureText: true,
            validator: Validators.password,
          ),
          AppSpacing.md.v,
          ModernTextField(
            hint: context.l10n.confirmPassword,
            controller: _confirmPasswordController,
            obscureText: true,
            validator: (v) => v != _newPasswordController.text
                ? context.l10n.passwordsDoNotMatch
                : null,
          ),
          AppSpacing.lg.v,
          PrimaryButton(
            label: context.l10n.resetPasswordCta,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
