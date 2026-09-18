import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mapanytime_market_app/core/config/app_config.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// "Or sign in with" divider + Google and Facebook buttons.
///
/// Both exchange a provider token for our own session via
/// `AuthController.loginWithFacebook`/`loginWithGoogle`, which post to
/// POST /auth/facebook and POST /auth/google respectively — the API verifies
/// each token server-side (against the Graph API, and against Google's public
/// keys) rather than trusting anything this client asserts about its own
/// identity.
class SocialLoginRow extends ConsumerWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: colors.outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                context.l10n.orSignInWith,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: colors.outline)),
          ],
        ),
        AppSpacing.md.v,
        _FacebookButton(label: context.l10n.continueWithFacebook),
        AppSpacing.sm.v,
        _GoogleButton(label: context.l10n.continueWithGoogle),
      ],
    );
  }
}

class _FacebookButton extends ConsumerStatefulWidget {
  const _FacebookButton({required this.label});

  final String label;

  @override
  ConsumerState<_FacebookButton> createState() => _FacebookButtonState();
}

class _FacebookButtonState extends ConsumerState<_FacebookButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success || result.accessToken == null) {
        if (result.status != LoginStatus.cancelled && mounted) {
          showTopToast(
            context,
            result.message ?? 'Facebook sign-in failed.',
          );
        }
        return;
      }

      final success = await ref
          .read(authControllerProvider.notifier)
          .loginWithFacebook(result.accessToken!.tokenString);

      if (!mounted) return;
      if (success) {
        context.go(RouteNames.home);
      } else {
        final error = ref.read(authControllerProvider).error;
        showTopToast(context, error ?? 'Facebook sign-in failed.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.brPill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSurface,
                ),
              )
            else
              CircleAvatar(
                radius: 11,
                backgroundColor: colors.surface,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: _FacebookLogo(),
                ),
              ),
            AppSpacing.sm.h,
            Text(
              widget.label,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Guards `GoogleSignIn.initialize` so it runs exactly once app-wide — the
/// package's contract is undefined behavior if it's called again, or if
/// anything else on the singleton is called before its future completes.
Future<void>? _googleSignInInit;

Future<void> _ensureGoogleSignInInitialized() {
  return _googleSignInInit ??= GoogleSignIn.instance.initialize(
    // The *Web application* client ID, shared with the API and the web app —
    // see AppConfig.googleServerClientId for why this is `serverClientId`
    // rather than a platform-specific `clientId`.
    serverClientId: AppConfig.instance.googleServerClientId,
  );
}

class _GoogleButton extends ConsumerStatefulWidget {
  const _GoogleButton({required this.label});

  final String label;

  @override
  ConsumerState<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<_GoogleButton> {
  bool _isLoading = false;

  Future<void> _handleTap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        if (mounted) {
          showTopToast(context, 'Google sign-in failed.');
        }
        return;
      }

      final success = await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogle(idToken);

      if (!mounted) return;
      if (success) {
        context.go(RouteNames.home);
      } else {
        final error = ref.read(authControllerProvider).error;
        showTopToast(context, error ?? 'Google sign-in failed.');
      }
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        showTopToast(context, 'Google sign-in failed.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: AppRadius.brPill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSurface,
                ),
              )
            else
              CircleAvatar(
                radius: 11,
                backgroundColor: colors.surface,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: _GoogleLogo(),
                ),
              ),
            AppSpacing.sm.h,
            Text(
              widget.label,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The official multi-color Google "G" mark, embedded as inline SVG data
/// rather than an asset file — this is the only place it's used.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.874 2.6836-6.615z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1023-1.17.2823-1.71V4.9582H.9573A8.9965 8.9965 0 0 0 0 9c0 1.4523.3477 2.8268.9573 4.0418L3.964 10.71z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29C4.6718 5.1627 6.656 3.5795 9 3.5795z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 14, height: 14);
  }
}

/// The official Facebook "f" mark, embedded as inline SVG — same treatment as
/// [_GoogleLogo] above.
class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
  <path fill="#1877F2" d="M18 9a9 9 0 1 0-10.406 8.89v-6.29H5.309V9h2.285V7.017c0-2.256 1.344-3.502 3.4-3.502.985 0 2.014.176 2.014.176v2.215h-1.135c-1.118 0-1.467.694-1.467 1.406V9h2.496l-.399 2.6h-2.097v6.29A9.002 9.002 0 0 0 18 9Z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: 14, height: 14);
  }
}
