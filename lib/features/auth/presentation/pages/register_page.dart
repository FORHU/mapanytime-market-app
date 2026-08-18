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
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _acceptedTerms = false;
  var _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
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
          name: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
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
            _StepDots(current: _step, total: _stepCount),
            AppSpacing.lg.v,
            Form(key: _formKey, child: _stepField()),
            if (_step == _stepCount - 1) ...[
              AppSpacing.md.v,
              _TermsCheckbox(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v),
              ),
            ],
            AppSpacing.lg.v,
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
          hint: context.l10n.email,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        );
      case 1:
        return ModernTextField(
          key: const ValueKey('name'),
          hint: context.l10n.fullNameOptional,
          controller: _nameController,
        );
      default:
        return ModernTextField(
          key: const ValueKey('password'),
          hint: context.l10n.password,
          controller: _passwordController,
          obscureText: true,
          validator: Validators.password,
        );
    }
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) AppSpacing.xs.h,
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= current ? colors.onSurface : colors.outline,
              borderRadius: BorderRadius.circular(4),
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
            activeColor: colors.onSurface,
            side: BorderSide(color: colors.outline),
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
