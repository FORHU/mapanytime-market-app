import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/social_login_row.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    if (success) {
      context.go(RouteNames.home);
    } else {
      final error = ref.read(authControllerProvider).error;
      showTopToast(context, error ?? 'Login failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModernTextField(
            label: context.l10n.email,
            hint: context.l10n.emailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          AppSpacing.md.v,
          ModernTextField(
            label: context.l10n.password,
            hint: context.l10n.enterPasswordHint,
            controller: _passwordController,
            obscureText: true,
            validator: Validators.password,
          ),
          AppSpacing.sm.v,
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.push(RouteNames.forgotPassword),
              child: Text(
                context.l10n.forgotPassword,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          AppSpacing.md.v,
          PrimaryButton(
            label: context.l10n.signInCta,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
          AppSpacing.lg.v,
          const SocialLoginRow(),
        ],
      ),
    );
  }
}
