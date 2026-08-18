import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/store/presentation/controllers/store_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/merchant_ad_section.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/icon_button.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Store Details: hero image, store info, category filters and a product grid.
/// Display data is mock-backed via [storeDetailsProvider]; the lean
/// [StoreEntity] (name/distance) comes from the real map API.
class StorefrontPage extends ConsumerStatefulWidget {
  const StorefrontPage({required this.store, super.key});

  final StoreEntity store;

  @override
  ConsumerState<StorefrontPage> createState() => _StorefrontPageState();
}

class _StorefrontPageState extends ConsumerState<StorefrontPage> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(storeDetailsProvider(widget.store.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: AppIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 40,
            iconSize: 18,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          AppIconButton(
            icon: Icons.share_outlined,
            size: 40,
            iconSize: 18,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.shareComingSoon)),
            ),
          ),
          const Gap(AppSpacing.md),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storeDetailsProvider(widget.store.id));
        },
        color: AppColors.ink,
        child: detailsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Gap(200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Gap(120),
              Center(
                child: Text(
                  'Could not load store',
                  style: TextStyle(color: AppColors.text.secondary),
                ),
              ),
            ],
          ),
          data: (details) => _StoreBody(
            store: widget.store,
            details: details,
            selectedCategory: _category,
            onCategory: (i) => setState(() => _category = i),
          ),
        ),
      ),
    );
  }
}

class _StoreBody extends StatelessWidget {
  const _StoreBody({
    required this.store,
    required this.details,
    required this.selectedCategory,
    required this.onCategory,
  });

  final StoreEntity store;
  final StoreDetails details;
  final int selectedCategory;
  final ValueChanged<int> onCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = details.productCategories[selectedCategory];
    final products = selectedLabel == 'All'
        ? details.products
        : details.products.where((p) => p.category == selectedLabel).toList();
    final adsByProduct = details.ads.byProductId;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        NetworkImageBox(url: details.heroImageUrl, height: 260),
        Transform.translate(
          offset: const Offset(0, -AppSpacing.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ui.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    _OpenBadge(isOpen: details.isOpen),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.status.warning,
                    ),
                    const Gap(4),
                    Text(
                      '${details.rating}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text.primary,
                      ),
                    ),
                    Text(
                      ' (${details.ratingCount})',
                      style: TextStyle(color: AppColors.text.tertiary),
                    ),
                    const Gap(AppSpacing.md),
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: AppColors.text.secondary,
                    ),
                    const Gap(4),
                    Text(
                      '${store.distance.toStringAsFixed(1)} km',
                      style: TextStyle(color: AppColors.text.secondary),
                    ),
                  ],
                ),
                const Gap(AppSpacing.sm),
                Text(
                  details.category,
                  style: TextStyle(color: AppColors.text.tertiary),
                ),
                const Gap(AppSpacing.md),
                _EtaPill(label: details.etaLabel),
                const Gap(AppSpacing.lg),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: details.productCategories.length,
                    separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                    itemBuilder: (context, i) => CategoryChip(
                      label: details.productCategories[i],
                      selected: selectedCategory == i,
                      onTap: () => onCategory(i),
                    ),
                  ),
                ),
                const Gap(AppSpacing.lg),
                if (details.ads.isNotEmpty) ...[
                  MerchantAdSection(
                    ads: details.ads,
                    onAdTap: (ad) {
                      if (ad.kind == MerchantAdKind.job) {
                        unawaited(
                          context.push(
                            RouteNames.jobPostingDetail,
                            extra: (
                              ad: ad,
                              storeId: store.id,
                              storeName: store.name,
                            ),
                          ),
                        );
                      } else {
                        showTopToast(context, context.l10n.comingSoon);
                      }
                    },
                  ),
                  const Gap(AppSpacing.lg),
                ],
                const SectionTitle(title: 'Products'),
                const Gap(AppSpacing.md),
                _ProductGrid(
                  products: products,
                  storeId: store.id,
                  storeName: store.name,
                  adsByProduct: adsByProduct,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.storeId,
    required this.storeName,
    required this.adsByProduct,
  });

  final List<StoreProduct> products;
  final String storeId;
  final String storeName;
  final Map<String, MerchantAd> adsByProduct;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            'No products in this category',
            style: TextStyle(color: AppColors.text.tertiary),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final p in products)
              ProductCard(
                name: p.name,
                imageUrl: p.imageUrl,
                price: p.price,
                storeName: p.category,
                width: itemWidth,
                badgeLabel: adsByProduct[p.id]?.displayBadge,
                onTap: () => context.push(
                  RouteNames.productDetail,
                  extra: (
                    product: p,
                    storeId: storeId,
                    storeName: storeName,
                    promo: adsByProduct[p.id],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EtaPill extends StatelessWidget {
  const _EtaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.status.success.withValues(alpha: 0.12),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 15,
            color: AppColors.status.success,
          ),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.status.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.status.success : AppColors.text.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
