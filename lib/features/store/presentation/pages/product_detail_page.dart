import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/price_tag.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Product Detail screen: hero image, info, description and a sticky CTA.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    required this.product,
    this.storeId = '',
    this.storeName = 'Store',
    this.promo,
    super.key,
  });

  final StoreProduct product;
  final String storeId;
  final String storeName;

  /// The merchant ad linked to this product, if any — shown as a banner.
  final MerchantAd? promo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSaved = ref.watch(savedProductIdsProvider).contains(product.id);

    return Scaffold(
      appBar: ModernAppBar(
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isSaved ? Colors.red : null,
            ),
            onPressed: () {
              final notifier = ref.read(wishlistControllerProvider.notifier);
              if (isSaved) {
                unawaited(notifier.remove(product.id));
              } else {
                unawaited(notifier.add(product));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Gap(AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Hero(
                    tag: 'product-${product.id}',
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.ui.surfaceMuted,
                        borderRadius: AppRadius.brXl,
                        border: Border.all(
                          color: AppColors.ink.withValues(alpha: 0.08),
                        ),
                      ),
                      child: NetworkImageBox(
                        url: product.imageUrl,
                        height: 320,
                        borderRadius: AppRadius.brXl,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryPill(label: product.category),
                      const Gap(AppSpacing.md),
                      Text(product.name, style: theme.textTheme.headlineSmall),
                      const Gap(AppSpacing.sm),
                      PriceTag(amount: product.price, fontSize: 24),
                      if (promo != null) ...[
                        const Gap(AppSpacing.md),
                        _PromoBanner(promo: promo!),
                      ],
                      const Gap(AppSpacing.lg),
                      Text(
                        context.l10n.description,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Gap(AppSpacing.sm),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.text.secondary,
                          height: 1.5,
                        ),
                      ),
                      if (product.tags.isNotEmpty) ...[
                        const Gap(AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: product.tags
                              .map((tag) => _TagPill(label: tag))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomCta(
            onAdd: () async {
              final effectiveStoreId = storeId.isNotEmpty
                  ? storeId
                  : product.storeId;
              final effectiveStoreName = storeName != 'Store'
                  ? storeName
                  : product.storeName;

              final cart = ref.read(cartProvider);
              if (cart.isNotEmpty && cart.first.storeId != effectiveStoreId) {
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(context.l10n.clearCartPrompt),
                    content: const Text(
                      'You already have items from another store in your cart. '
                      'Adding this item will clear your current cart. '
                      'Do you want to proceed?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(cartProvider.notifier).clear();
                          ref
                              .read(cartProvider.notifier)
                              .add(
                                product: product,
                                storeId: effectiveStoreId,
                                storeName: effectiveStoreName,
                              );
                          showTopToast(
                            context,
                            context.l10n.productAddedToCart(product.name),
                          );
                        },
                        child: Text(context.l10n.clearAndAdd),
                      ),
                    ],
                  ),
                );
                return;
              }

              ref
                  .read(cartProvider.notifier)
                  .add(
                    product: product,
                    storeId: effectiveStoreId,
                    storeName: effectiveStoreName,
                  );
              showTopToast(
                context,
                context.l10n.productAddedToCart(product.name),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Highlights the merchant ad linked to this product (promo/event) with its
/// title, description, discount badge, and expiry if the ad has one.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.promo});

  final MerchantAd promo;

  @override
  Widget build(BuildContext context) {
    final validUntil = promo.extra['validUntil'];
    final expiry = validUntil != null ? DateTime.tryParse(validUntil) : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: AppColors.text.onInk,
                size: 16,
              ),
              const Gap(6),
              Expanded(
                child: Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text.onInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (promo.displayBadge != null) ...[
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.text.onInk.withValues(alpha: 0.2),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(
                    promo.displayBadge!,
                    style: TextStyle(
                      color: AppColors.text.onInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(4),
          Text(
            promo.description,
            style: TextStyle(color: AppColors.text.onInk, fontSize: 12),
          ),
          if (expiry != null) ...[
            const Gap(4),
            Text(
              'Valid until ${DateFormat.yMMMd().format(expiry)}',
              style: TextStyle(
                color: AppColors.text.onInk.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.1),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        '#$label',
        style: TextStyle(fontSize: 12, color: AppColors.text.secondary),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.onAdd});

  final VoidCallback onAdd;

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
        color: AppColors.ui.surface,
        boxShadow: AppEffects.cardShadow,
      ),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Add to cart',
          icon: Icons.add_shopping_cart_rounded,
          onPressed: onAdd,
        ),
      ),
    );
  }
}
