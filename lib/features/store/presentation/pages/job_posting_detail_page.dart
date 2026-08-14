import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Job posting detail screen: full description, salary, and posting window
/// for a [MerchantAdKind.job] ad — the compact rail card only shows a title
/// and a two-line snippet.
class JobPostingDetailPage extends StatelessWidget {
  const JobPostingDetailPage({
    required this.ad,
    required this.storeId,
    required this.storeName,
    super.key,
  });

  final MerchantAd ad;
  final String storeId;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salaryLabel = ad.extra['salaryLabel'];
    final validUntil = ad.extra['validUntil'];
    final expiry = validUntil != null ? DateTime.tryParse(validUntil) : null;
    final badge = ad.displayBadge;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ModernAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(imageUrl: ad.imageUrl),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Posted by $storeName',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(ad.title, style: theme.textTheme.headlineSmall),
                      const Gap(AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          if (salaryLabel != null)
                            _Chip(
                              icon: Icons.payments_outlined,
                              label: salaryLabel,
                            ),
                          if (badge != null)
                            _Chip(
                              icon: Icons.work_outline_rounded,
                              label: badge,
                            ),
                        ],
                      ),
                      const Gap(AppSpacing.lg),
                      Text(
                        context.l10n.description,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        ad.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.text.secondaryDark,
                          height: 1.5,
                        ),
                      ),
                      if (expiry != null) ...[
                        const Gap(AppSpacing.lg),
                        Text(
                          'Posted until ${DateFormat.yMMMd().format(expiry)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.text.tertiaryDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            ctaLabel: ad.ctaLabel ?? 'Apply now',
            onApply: () => showTopToast(context, context.l10n.comingSoon),
            onVisitStore: () => context.push(
              RouteNames.storefront,
              extra: StoreEntity(
                id: storeId,
                name: storeName,
                lat: 0,
                lng: 0,
                distance: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return NetworkImageBox(url: imageUrl!, height: 220);
    }
    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.brand.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(
        Icons.work_outline_rounded,
        size: 56,
        color: AppColors.brand.primary,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand.primaryBright),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.brand.primaryBright,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.ctaLabel,
    required this.onApply,
    required this.onVisitStore,
  });

  final String ctaLabel;
  final VoidCallback onApply;
  final VoidCallback onVisitStore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.ui.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: 'Visit store',
                icon: Icons.storefront_rounded,
                onTap: onVisitStore,
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: GradientButton(
                label: ctaLabel,
                icon: Icons.send_rounded,
                onPressed: onApply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ui.surfaceElevatedDark,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.ui.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.text.primaryDark),
            const Gap(AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text.primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
