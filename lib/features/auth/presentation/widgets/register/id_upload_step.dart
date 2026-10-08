import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// ID cards are ISO/IEC 7810 ID-1: 85.6 × 54 mm.
const double _idCardAspectRatio = 85.6 / 54;

/// Sign-up step 2: take or choose a photo of a valid ID. While the photo is
/// being read ([isReading]) the step shows it with a scanning sweep; the page
/// moves on to the review step by itself when reading finishes.
class IdUploadStep extends StatelessWidget {
  const IdUploadStep({
    required this.photoPath,
    required this.isReading,
    required this.onPick,
    this.errorMessage,
    this.errorActionLabel,
    this.onErrorAction,
    super.key,
  });

  final String? photoPath;
  final bool isReading;
  final ValueChanged<ImageSource> onPick;

  /// Why the last photo was refused, shown above the frame.
  final String? errorMessage;

  /// Optional fix offered under [errorMessage], e.g. "Edit your name".
  final String? errorActionLabel;
  final VoidCallback? onErrorAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = photoPath;

    if (isReading && path != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IdFrame(
            child: Stack(
              fit: StackFit.expand,
              children: [IdPhoto(path), const _ScanSweep()],
            ),
          ),
          AppSpacing.lg.v,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.ink,
                ),
              ),
              AppSpacing.sm.h,
              Text(
                l10n.idReading,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AppSpacing.sm.v,
          Text(
            l10n.idReadingHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text.secondary, fontSize: 13.5),
          ),
        ],
      );
    }

    final error = errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          _ErrorBanner(
            error,
            actionLabel: errorActionLabel,
            onAction: onErrorAction,
          ),
          AppSpacing.md.v,
        ],
        _IdFrame(
          corners: path == null,
          child: path != null
              ? IdPhoto(path)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 36,
                      color: AppColors.text.tertiary,
                    ),
                    AppSpacing.xs.v,
                    Text(
                      l10n.idFrontOfId,
                      style: TextStyle(
                        color: AppColors.text.tertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
        AppSpacing.md.v,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SourceTile(
                key: const ValueKey('takeIdPhoto'),
                icon: Icons.photo_camera_outlined,
                title: l10n.idTakePhoto,
                hint: l10n.idTakePhotoHint,
                primary: true,
                onTap: () => onPick(ImageSource.camera),
              ),
            ),
            AppSpacing.md.h,
            Expanded(
              child: _SourceTile(
                key: const ValueKey('chooseIdPhoto'),
                icon: Icons.photo_library_outlined,
                title: l10n.idChooseGallery,
                hint: l10n.idChooseGalleryHint,
                onTap: () => onPick(ImageSource.gallery),
              ),
            ),
          ],
        ),
        AppSpacing.lg.v,
        Text(
          l10n.idAcceptedIds,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text.secondary,
          ),
        ),
        AppSpacing.sm.v,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final type in IdType.values)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ui.surface,
                  border: Border.all(color: AppColors.ui.borderHairline),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(type.label, style: const TextStyle(fontSize: 12.5)),
              ),
          ],
        ),
        AppSpacing.md.v,
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.ui.surface,
            border: Border.all(color: AppColors.ui.borderHairline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final (i, tip) in [
                l10n.idTipFlat,
                l10n.idTipCorners,
                l10n.idTipGlare,
              ].indexed) ...[
                if (i > 0) AppSpacing.sm.v,
                Row(
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.status.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.text.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message, {this.actionLabel, this.onAction});

  final String message;

  /// A way to fix the problem from here, e.g. "Edit your name".
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.status.errorStrong;
    final label = actionLabel;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('idRejection'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.status.error.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: color,
                    ),
                  ),
                  if (label != null && onAction != null)
                    TextButton(
                      key: const ValueKey('idRejectionAction'),
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ID photo, filling its box. Falls back to an icon if the file can't be
/// decoded.
class IdPhoto extends StatelessWidget {
  const IdPhoto(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.ui.surfaceMutedCool,
        child: Icon(Icons.badge_outlined, color: AppColors.text.tertiary),
      ),
    );
  }
}

/// A card-shaped frame, with corner guides while it's waiting for a photo.
class _IdFrame extends StatelessWidget {
  const _IdFrame({required this.child, this.corners = false});

  final Widget child;
  final bool corners;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _idCardAspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          border: Border.all(color: AppColors.ui.borderHairline),
          borderRadius: BorderRadius.circular(18),
        ),
        child: corners
            ? CustomPaint(
                foregroundPainter: _CornerGuidesPainter(),
                child: child,
              )
            : child,
      ),
    );
  }
}

class _CornerGuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 14.0;
    const arm = 22.0;
    const r = 8.0;
    final paint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTRB(
      inset,
      inset,
      size.width - inset,
      size.height - inset,
    );
    // One rounded "L" per corner, mirrored with the canvas.
    for (final (sx, sy) in [
      (1.0, 1.0),
      (-1.0, 1.0),
      (1.0, -1.0),
      (-1.0, -1.0),
    ]) {
      canvas
        ..save()
        ..translate(
          sx > 0 ? rect.left : rect.right,
          sy > 0 ? rect.top : rect.bottom,
        )
        ..scale(sx, sy)
        ..drawPath(
          Path()
            ..moveTo(0, arm)
            ..lineTo(0, r)
            ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
            ..lineTo(arm, 0),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A band of the brand blue sweeping down the photo while it's read. Static
/// when the system asks for reduced motion.
class _ScanSweep extends StatefulWidget {
  const _ScanSweep();

  @override
  State<_ScanSweep> createState() => _ScanSweepState();
}

class _ScanSweepState extends State<_ScanSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.6;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Align(
        alignment: Alignment(0, -1.4 + 2.8 * _controller.value),
        child: FractionallySizedBox(
          heightFactor: 0.36,
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ink.withValues(alpha: 0),
                  AppColors.ink.withValues(alpha: 0.22),
                  AppColors.ink.withValues(alpha: 0.9),
                ],
                stops: const [0, 0.85, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.primary = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.text.onInk : AppColors.text.primary;
    final hintColor = primary
        ? AppColors.text.onInk.withValues(alpha: 0.78)
        : AppColors.text.secondary;
    final radius = BorderRadius.circular(18);

    return Material(
      color: primary ? AppColors.ink : AppColors.ui.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: primary ? AppColors.ink : AppColors.ui.borderHairline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary
                      ? AppColors.text.onInk.withValues(alpha: 0.16)
                      : AppColors.ink.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: primary ? AppColors.text.onInk : AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              Text(hint, style: TextStyle(fontSize: 12.5, color: hintColor)),
            ],
          ),
        ),
      ),
    );
  }
}
