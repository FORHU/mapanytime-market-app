import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/price_tag.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Product Detail screen: hero image, info, description and a sticky CTA.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    required this.product,
    this.storeId = '',
    this.storeName = 'Store',
    super.key,
  });

  final StoreProduct product;
  final String storeId;
  final String storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ModernAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Hero(
                  tag: 'product-${product.id}',
                  child: Image.network(
                    product.imageUrl,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 320,
                      color: AppColors.ui.surfaceElevatedDark,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.text.tertiaryDark,
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
                      const Gap(AppSpacing.lg),
                      Text('Description', style: theme.textTheme.titleMedium),
                      const Gap(AppSpacing.sm),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.text.secondaryDark,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _BottomCta(
            onAdd: () {
              ref.read(cartProvider.notifier).add(
                    product: product,
                    storeId: storeId,
                    storeName: storeName,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} added to cart')),
              );
            },
          ),
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
        color: AppColors.brand.primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.brand.primaryBright,
        ),
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
        color: AppColors.ui.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.ui.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: GradientButton(
          label: 'Add to cart',
          icon: Icons.add_shopping_cart_rounded,
          onPressed: onAdd,
        ),
      ),
    );
  }
}
