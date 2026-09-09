import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/social_login_row.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Registration, one field per step (email → name → password) instead of a
/// single wall of fields.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const _stepCount = 3;

  var _step = 0;
  var _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _acceptedTerms = false;
  var _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0) {
      context.go(RouteNames.login);
    } else {
      setState(() {
        _step -= 1;
        _formKey = GlobalKey<FormState>();
      });
    }
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    if (_step < _stepCount - 1) {
      setState(() {
        _step += 1;
        _formKey = GlobalKey<FormState>();
      });
      return;
    }

    if (!_acceptedTerms) {
      showTopToast(context, context.l10n.acceptTerms);
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          _emailController.text,
          _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          middleName: _middleNameController.text.trim().isEmpty
              ? null
              : _middleNameController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go(RouteNames.registerSuccess);
    } else {
      final error = ref.read(authControllerProvider).error;
      showTopToast(context, error ?? 'Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      0 => (
        context.l10n.registerStepEmailTitle,
        context.l10n.registerStepEmailSubtitle,
      ),
      1 => (
        context.l10n.registerStepNameTitle,
        context.l10n.registerStepNameSubtitle,
      ),
      _ => (
        context.l10n.registerStepPasswordTitle,
        context.l10n.registerStepPasswordSubtitle,
      ),
    };

    return AuthScaffold(
      onBack: _back,
      title: title,
      subtitle: subtitle,
      showLogo: false,
      wideTagline: [
        context.l10n.authTaglineDiscover,
        context.l10n.authTaglineTrack,
        context.l10n.authTaglineCheckout,
      ],
      footer: AuthSwitchLink(
        prompt: context.l10n.alreadyHaveAccount,
        actionLabel: context.l10n.logIn,
        onTap: () => context.go(RouteNames.login),
      ),
      card: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Column(
          key: ValueKey(_step),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepProgressBar(current: _step, total: _stepCount),
            AppSpacing.lg.v,
            Form(key: _formKey, child: _stepField()),
          ],
        ),
      ),
      actions: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Column(
          key: ValueKey(_step),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step == _stepCount - 1) ...[
              _TermsCheckbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v),
              ),
              AppSpacing.md.v,
            ],
            PrimaryButton(
              label: _step == _stepCount - 1
                  ? context.l10n.signUpCta
                  : context.l10n.nextCta,
              isLoading: _isLoading,
              onPressed: _next,
            ),
            if (_step == 0) ...[AppSpacing.lg.v, const SocialLoginRow()],
          ],
        ),
      ),
    );
  }

  Widget _stepField() {
    switch (_step) {
      case 0:
        return ModernTextField(
          key: const ValueKey('email'),
          label: context.l10n.email,
          hint: context.l10n.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernTextField(
              key: const ValueKey('firstName'),
              label: context.l10n.firstName,
              hint: context.l10n.firstNameHint,
              controller: _firstNameController,
              validator: Validators.notEmpty,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('middleName'),
              label: context.l10n.middleName,
              hint: context.l10n.middleNameHint,
              controller: _middleNameController,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('lastName'),
              label: context.l10n.lastName,
              hint: context.l10n.lastNameHint,
              controller: _lastNameController,
              validator: Validators.notEmpty,
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernTextField(
              key: const ValueKey('password'),
              label: context.l10n.password,
              hint: context.l10n.createPasswordHint,
              controller: _passwordController,
              obscureText: true,
              validator: Validators.password,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('confirmPassword'),
              label: context.l10n.confirmPassword,
              hint: context.l10n.confirmPasswordHint,
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (v) => v != _passwordController.text
                  ? context.l10n.passwordsDoNotMatch
                  : null,
            ),
          ],
        );
    }
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) AppSpacing.xs.h,
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= current ? colors.primary : colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: colors.primary,
            side: BorderSide(color: colors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.acceptTerms,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
