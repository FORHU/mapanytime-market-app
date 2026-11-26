import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_name_match.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_scanner.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/auth_switch_link.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/register/id_review_step.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/register/id_upload_step.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/social_login_row.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Buyer registration, one task per step: account (email, name, phone) →
/// valid ID photo, whose name must match the one entered → check the details
/// read from the ID → password. The name always comes from the buyer, never
/// from the ID. Nothing is sent until Sign Up on the last step.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const _stepCount = 4;
  static const _accountStep = 0;
  static const _idStep = 1;
  static const _reviewStep = 2;
  static const _passwordStep = 3;

  int _step = _accountStep;
  var _formKey = GlobalKey<FormState>();
  final _reviewKey = GlobalKey<IdReviewStepState>();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _details = IdReviewFields();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _acceptedTerms = false;
  var _isLoading = false;

  /// The last ID photo that was read successfully.
  String? _idPhotoPath;

  /// The photo being read right now, if any.
  String? _pendingPhotoPath;

  /// Why the last photo was refused; shown until the next pick.
  IdRejection? _idRejection;

  bool get _isReadingId => _pendingPhotoPath != null;

  /// Bumped per photo, so a read that finishes after the buyer backed out or
  /// picked another photo is ignored.
  var _scanRun = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _details.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goTo(int step) => setState(() {
    _step = step;
    _formKey = GlobalKey<FormState>();
  });

  void _back() {
    if (_step == _accountStep) {
      context.go(RouteNames.login);
    } else if (_isReadingId) {
      _cancelReading();
    } else {
      _goTo(_step - 1);
    }
  }

  void _cancelReading() => setState(() {
    _scanRun++;
    _pendingPhotoPath = null;
  });

  /// Whether [id] carries the name entered on the account step.
  bool _nameMatches(ScannedId id) => idNameMatches(
    enteredFirst: _firstNameController.text,
    enteredLast: _lastNameController.text,
    id: id,
  );

  String get _fullName => [
    _firstNameController.text,
    _middleNameController.text,
    _lastNameController.text,
  ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

  Future<void> _pickId(ImageSource source) async {
    final l10n = context.l10n;
    final String? path;
    try {
      path = await ref.read(idPhotoPickerProvider).pick(source);
    } on PlatformException catch (e) {
      if (!mounted) return;
      final cameraRefused =
          source == ImageSource.camera && e.code != 'photo_access_denied';
      showTopToast(
        context,
        cameraRefused ? l10n.idCameraDenied : l10n.idPhotosDenied,
      );
      return;
    }
    if (path == null || !mounted) return;

    final run = ++_scanRun;
    setState(() {
      _pendingPhotoPath = path;
      _idRejection = null;
    });

    IdRejection? rejection;
    ScannedId? scanned;
    try {
      scanned = await ref.read(idScannerProvider).scan(path);
      rejection =
          scanned.rejection ??
          (_nameMatches(scanned) ? null : IdRejection.nameMismatch);
    } on Exception {
      rejection = IdRejection.unreadable;
    }
    if (!mounted || run != _scanRun) return;

    if (rejection != null || scanned == null) {
      // Refused: stay here. A photo accepted earlier (before a Retake) and
      // the details read from it are kept.
      setState(() {
        _pendingPhotoPath = null;
        _idRejection = rejection ?? IdRejection.unreadable;
      });
      return;
    }

    _details.fill(scanned, (date) => formatDateOfBirth(context, date));
    setState(() {
      _idPhotoPath = path;
      _pendingPhotoPath = null;
    });
    _goTo(_reviewStep);
  }

  /// The name may have been edited since the ID was accepted: an ID that no
  /// longer matches has to be uploaded again. A stale mismatch message is
  /// cleared, since the name it was about has changed.
  void _recheckNameAgainstId() {
    if (_idRejection == IdRejection.nameMismatch) _idRejection = null;
    if (_idPhotoPath != null && !_nameMatches(_details.scanned)) {
      _idPhotoPath = null;
      _idRejection = IdRejection.nameMismatch;
    }
  }

  Future<void> _next() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) {
      if (_step == _reviewStep) {
        _reviewKey.currentState?.scrollToFirstError();
        showTopToast(context, context.l10n.reviewFixFields);
      }
      return;
    }

    if (_step == _accountStep) _recheckNameAgainstId();

    // The name is editable on the review step too: it still has to be the
    // name on the ID that was just read.
    if (_step == _reviewStep && !_nameMatches(_details.scanned)) {
      _reviewKey.currentState?.scrollToName();
      showTopToast(context, context.l10n.idNameMismatch);
      return;
    }

    if (_step < _passwordStep) {
      _goTo(_step + 1);
      return;
    }

    if (!_acceptedTerms) {
      showTopToast(context, context.l10n.acceptTerms);
      return;
    }

    setState(() => _isLoading = true);
    final d = _details;
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
          profile: RegistrationProfile(
            phoneNumber: Validators.normalizePhMobile(_phoneController.text)!,
            dateOfBirth: d.dateOfBirth!,
            sex: d.sex,
            address: d.address.text.trim(),
            idType: d.idType!,
            idNumber: d.idNumber.text.trim(),
            idPhotoPath: _idPhotoPath!,
          ),
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
    final l10n = context.l10n;
    final (title, subtitle) = switch (_step) {
      _accountStep => (
        l10n.registerStepAccountTitle,
        l10n.registerStepAccountSubtitle,
      ),
      _idStep => (l10n.registerStepIdTitle, l10n.registerStepIdSubtitle),
      _reviewStep => (
        l10n.registerStepReviewTitle,
        l10n.registerStepReviewSubtitle,
      ),
      _ => (
        l10n.registerStepPasswordTitle,
        l10n.registerStepPasswordSubtitle,
      ),
    };

    return AuthScaffold(
      onBack: _back,
      title: title,
      subtitle: subtitle,
      showLogo: false,
      wideTagline: [
        l10n.authTaglineDiscover,
        l10n.authTaglineTrack,
        l10n.authTaglineCheckout,
      ],
      footer: _step == _reviewStep
          ? null
          : AuthSwitchLink(
              prompt: l10n.alreadyHaveAccount,
              actionLabel: l10n.logIn,
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
            Form(key: _formKey, child: _stepBody()),
          ],
        ),
      ),
      actions: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Column(
          key: ValueKey('$_step|$_isReadingId|${_idPhotoPath != null}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _stepActions(),
        ),
      ),
    );
  }

  List<Widget> _stepActions() {
    final l10n = context.l10n;
    switch (_step) {
      case _accountStep:
        return [
          PrimaryButton(label: l10n.nextCta, onPressed: _next),
          AppSpacing.lg.v,
          const SocialLoginRow(),
        ];
      case _idStep:
        if (_isReadingId) {
          return [
            _SecondaryButton(
              label: l10n.idUseDifferentPhoto,
              onPressed: _cancelReading,
            ),
          ];
        }
        return [
          // Back from the review step with a photo already read: carry on
          // without re-reading (and without losing any edits).
          if (_idPhotoPath != null) ...[
            PrimaryButton(label: l10n.nextCta, onPressed: _next),
            AppSpacing.md.v,
          ],
          _Hint(icon: Icons.lock_outline_rounded, text: l10n.idPrivacyHint),
        ];
      case _reviewStep:
        return [
          PrimaryButton(label: l10n.reviewContinueCta, onPressed: _next),
          AppSpacing.md.v,
          _Hint(text: l10n.reviewNotSubmitted),
        ];
      default:
        return [
          _TermsCheckbox(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v),
          ),
          AppSpacing.md.v,
          PrimaryButton(
            label: l10n.signUpCta,
            isLoading: _isLoading,
            onPressed: _next,
          ),
        ];
    }
  }

  Widget _stepBody() {
    final l10n = context.l10n;
    switch (_step) {
      case _accountStep:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernTextField(
              key: const ValueKey('email'),
              label: l10n.email,
              hint: l10n.emailHint,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('firstName'),
              label: l10n.firstName,
              hint: l10n.firstNameHint,
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              validator: Validators.notEmpty,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('middleName'),
              label: l10n.middleName,
              hint: l10n.middleNameHint,
              controller: _middleNameController,
              textCapitalization: TextCapitalization.words,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('lastName'),
              label: l10n.lastName,
              hint: l10n.lastNameHint,
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              validator: Validators.notEmpty,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('phone'),
              label: l10n.phoneNumber,
              hint: l10n.phoneNumberHint,
              controller: _phoneController,
              prefixText: '+63 ',
              keyboardType: TextInputType.phone,
              validator: Validators.phMobile,
            ),
          ],
        );
      case _idStep:
        final rejection = _idRejection;
        return IdUploadStep(
          photoPath: _pendingPhotoPath ?? _idPhotoPath,
          isReading: _isReadingId,
          onPick: _pickId,
          errorMessage: switch (rejection) {
            IdRejection.notAnId => l10n.idRejectedNotAnId,
            IdRejection.unreadable => l10n.idRejectedUnreadable,
            IdRejection.nameMismatch => l10n.idNameMismatch,
            null => null,
          },
          errorActionLabel: rejection == IdRejection.nameMismatch
              ? l10n.idEditName
              : null,
          onErrorAction: () => _goTo(_accountStep),
        );
      case _reviewStep:
        return IdReviewStep(
          key: _reviewKey,
          fields: _details,
          firstName: _firstNameController,
          lastName: _lastNameController,
          photoPath: _idPhotoPath,
          onRetake: () => _goTo(_idStep),
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SignupSummaryCard(
              name: _fullName,
              email: _emailController.text.trim(),
              onEdit: () => _goTo(_reviewStep),
            ),
            AppSpacing.lg.v,
            ModernTextField(
              key: const ValueKey('password'),
              label: l10n.password,
              hint: l10n.createPasswordHint,
              controller: _passwordController,
              obscureText: true,
              validator: Validators.password,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('confirmPassword'),
              label: l10n.confirmPassword,
              hint: l10n.confirmPasswordHint,
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (v) => v != _passwordController.text
                  ? l10n.passwordsDoNotMatch
                  : null,
            ),
          ],
        );
    }
  }
}

/// Who's signing up, with a way back to the details before confirming.
class _SignupSummaryCard extends StatelessWidget {
  const _SignupSummaryCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        border: Border.all(color: AppColors.ui.borderHairline),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.text.onInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.md.h,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.text.secondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: Text(
              context.l10n.editDetails,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill with a hairline border — the quieter sibling of
/// [PrimaryButton].
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableButtonBase(
      label: label,
      onPressed: onPressed,
      expand: true,
      isLoading: false,
      foregroundColor: AppColors.text.primary,
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.ui.borderHairline),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.text.secondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: color),
          ),
        ),
      ],
    );
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
