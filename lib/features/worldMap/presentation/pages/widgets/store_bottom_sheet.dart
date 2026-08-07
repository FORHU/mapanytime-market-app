import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class StoreBottomSheet extends StatelessWidget {
  const StoreBottomSheet({required this.store, this.onNavigate, super.key});

  final StoreEntity store;
  final VoidCallback? onNavigate;

  static Future<void> show(
    BuildContext context,
    StoreEntity store, {
    VoidCallback? onNavigate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          StoreBottomSheet(store: store, onNavigate: onNavigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: AppColors.ui.borderDark),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ui.borderDark,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderBadge(store: store),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          if (store.isOpen != null) ...[
                            const Gap(AppSpacing.sm),
                            _OpenBadge(isOpen: store.isOpen!),
                          ],
                        ],
                      ),
                      const Gap(4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 15,
                                color: AppColors.brand.primary,
                              ),
                              const Gap(4),
                              Text(
                                '${store.distance.toStringAsFixed(1)} km away',
                                style: TextStyle(
                                  color: AppColors.text.secondaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (store.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.status.warning,
                                ),
                                const Gap(2),
                                Text(
                                  store.ratingCount != null
                                      ? '${store.rating!.toStringAsFixed(1)} '
                                            '(${store.ratingCount})'
                                      : store.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: AppColors.text.secondaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    label: 'Navigate',
                    icon: Icons.navigation_rounded,
                    onTap: () {
                      Navigator.of(context).pop();
                      onNavigate?.call();
                    },
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: GradientButton(
                    label: 'Shop Now',
                    icon: Icons.shopping_bag_rounded,
                    onPressed: () {
                      Navigator.of(context).pop();
                      unawaited(
                        context.push(RouteNames.storefront, extra: store),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo when present, else the merchant's category icon on its accent
/// color, else the generic storefront gradient badge.
class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.store});

  final StoreEntity store;

  @override
  Widget build(BuildContext context) {
    final logoUrl = store.logoUrl;
    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: AppRadius.brMd,
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => _CategoryBadge(store: store),
          placeholder: (context, url) => _CategoryBadge(store: store),
        ),
      );
    }

    if (store.categoryName != null) {
      return _CategoryBadge(store: store);
    }

    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.brMd,
        boxShadow: AppEffects.primaryGlow,
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.store});

  final StoreEntity store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorForStore(store),
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(iconForStore(store), color: Colors.white),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen
        ? AppColors.status.success
        : AppColors.text.tertiaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
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
            Icon(icon, size: 20, color: AppColors.text.primaryDark),
            const Gap(AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
