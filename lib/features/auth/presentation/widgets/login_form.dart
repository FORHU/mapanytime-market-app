import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../routes/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_input.dart';
import '../controllers/auth_controller.dart';

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

    final success = await ref.read(authControllerProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

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
            label: AppStrings.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
          ),
          AppSpacing.gapMd,
          AppInput(
            label: AppStrings.password,
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: Validators.password,
          ),
          if (state.error != null) ...[
            AppSpacing.gapSm,
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          AppSpacing.gapLg,
          AppButton(
            label: AppStrings.login,
            isLoading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
