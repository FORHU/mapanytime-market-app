import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// The buyer's saved products (`Profile → Saved`).
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistControllerProvider);

    return Scaffold(
      appBar: const ModernAppBar(title: 'Saved'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(wishlistControllerProvider),
        color: AppColors.ink,
        child: wishlistAsync.when(
          loading: () => const _LoadingState(),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(wishlistControllerProvider),
          ),
          data: (items) =>
              items.isEmpty ? const _EmptyState() : _SavedGrid(items: items),
        ),
      ),
    );
  }
}

class _SavedGrid extends ConsumerWidget {
  const _SavedGrid({required this.items});

  final List<WishlistItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final product = item.product;
        // Every item here is by definition saved — the heart is always
        // filled, and tapping it always removes (there's no "unsaved" state
        // to toggle back to on this particular page).
        return ProductCard(
          name: product.name,
          imageUrl: product.imageUrl,
          price: product.price,
          storeName: product.storeName,
          width: double.infinity,
          isSaved: true,
          onToggleSave: () => ref
              .read(wishlistControllerProvider.notifier)
              .remove(
                product.id,
              ),
          onTap: () {
            unawaited(
              context.push(
                RouteNames.productDetail,
                extra: (
                  product: product,
                  storeId: product.storeId,
                  storeName: product.storeName,
                  promo: null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: Column(
            children: [
              Text(
                "Couldn't load your saved items",
                style: TextStyle(color: AppColors.text.secondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 44,
                color: AppColors.text.tertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nothing saved yet',
                style: TextStyle(color: AppColors.text.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
