import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Merchant promo/event/job ad cards, shown in both the map bottom sheet and
/// the full storefront page. Renders nothing when [ads] is empty.
class MerchantAdSection extends StatelessWidget {
  const MerchantAdSection({required this.ads, this.onAdTap, super.key});

  final List<MerchantAd> ads;

  /// Called when a card is tapped. Falls back to a "coming soon" toast when
  /// not supplied.
  final void Function(MerchantAd ad)? onAdTap;

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'From this merchant'),
        const Gap(AppSpacing.sm),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, i) => _AdCard(
              ad: ads[i],
              onTap: onAdTap == null ? null : () => onAdTap!(ads[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad, this.onTap});

  final MerchantAd ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isJob = ad.kind == MerchantAdKind.job;

    return GestureDetector(
      onTap: onTap ?? () => showTopToast(context, context.l10n.comingSoon),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          borderRadius: AppRadius.brLg,
          boxShadow: AppEffects.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ad.displayBadge != null)
              _AdBadge(label: ad.displayBadge!, isJob: isJob),
            const Gap(6),
            Text(
              ad.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Gap(2),
            Expanded(
              child: Text(
                ad.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.secondary,
                ),
              ),
            ),
            if (ad.ctaLabel != null)
              Text(
                ad.ctaLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge({required this.label, required this.isJob});

  final String label;
  final bool isJob;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.text.onInk,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
