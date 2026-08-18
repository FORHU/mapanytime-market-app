import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A full-bleed photo card with a legibility scrim behind its text — used
/// for Home's promo/deals carousel. The one place a gradient survives the
/// redesign ([AppEffects.promoScrim]); never use it for a brand wash or a
/// button fill.
class PromoBannerCard extends StatelessWidget {
  const PromoBannerCard({
    required this.imageUrl,
    required this.title,
    required this.ctaLabel,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String imageUrl;
  final String title;
  final String? subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: SizedBox(
          height: 168,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkImageBox(url: imageUrl),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppEffects.promoScrim),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleLarge?.copyWith(
                        color: AppColors.text.onInk,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.text.onInk.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                    const Gap(AppSpacing.sm),
                    PrimaryButton(
                      label: ctaLabel,
                      icon: Icons.arrow_forward_rounded,
                      expand: false,
                      onPressed: onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
