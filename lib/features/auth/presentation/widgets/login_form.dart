import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/app_button.dart';
import 'package:mapanytime_market_app/shared/widgets/app_input.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'buyer@example.com');
  final _passwordController = TextEditingController(text: 'Buyer123');

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
    if (success) context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            label: context.l10n.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
          ),
          AppSpacing.md.v,
          AppInput(
            label: context.l10n.password,
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: Validators.password,
          ),
          if (state.error != null) ...[
            AppSpacing.sm.v,
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          AppSpacing.lg.v,
          AppButton(
            label: context.l10n.login,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
