import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A muted rounded block that stands in for content while it loads. Every
/// [SkeletonPulse] below it fades in and out together.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ui.borderHairline),
      ),
    );
  }
}

/// Slowly pulses its child's opacity — wrap a whole skeleton layout once.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({required this.child, super.key});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _controller, child: widget.child);
}

/// A compact notice that fills a deals slot when there is nothing to show
/// ("No deals today") or the deals fetch failed (with a retry).
class DealsNotice extends StatelessWidget {
  const DealsNotice.empty({super.key}) : onRetry = null;

  const DealsNotice.failed({required VoidCallback this.onRetry, super.key});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failed = onRetry != null;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.ui.borderHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ui.surface,
              borderRadius: AppRadius.brSm,
            ),
            child: Icon(
              failed ? Icons.cloud_off_rounded : Icons.local_offer_outlined,
              size: 20,
              color: AppColors.text.secondary,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed ? "Couldn't load deals" : 'No deals today',
                  style: tt.titleSmall?.copyWith(color: AppColors.text.primary),
                ),
                const Gap(2),
                Text(
                  failed
                      ? 'Check your connection and try again.'
                      : 'Check back later for discounts from stores near you.',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.text.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (failed) ...[
            const Gap(AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}
