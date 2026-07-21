import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/landing_content.dart';
import 'package:mapanytime_market_app/features/home/presentation/controllers/landing_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/store_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Buyer Landing screen (the Home tab): greeting, hero, stats, categories,
/// featured products and nearby stores. Content is mock-backed for now.
class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(landingContentProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: content.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(landingContentProvider),
          ),
          data: (data) => _LandingBody(
            data: data,
            selectedCategory: _selectedCategory,
            onCategory: (i) => setState(() => _selectedCategory = i),
          ),
        ),
      ),
    );
  }
}

class _LandingBody extends ConsumerWidget {
  const _LandingBody({
    required this.data,
    required this.selectedCategory,
    required this.onCategory,
  });

  final LandingContent data;
  final int selectedCategory;
  final ValueChanged<int> onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).user?.name ?? 'there';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        _Header(name: name),
        const Gap(AppSpacing.md),
        _HeroCard(onTap: () => context.go(RouteNames.worldMap)),
        const Gap(AppSpacing.md),
        _StatsRow(storesNearby: data.storesNearbyCount),
        const Gap(AppSpacing.md),
        FloatingSearchBar(onTap: () => context.go(RouteNames.worldMap)),
        const Gap(AppSpacing.lg),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.categories.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, i) {
              final c = data.categories[i];
              return CategoryChip(
                label: c.label,
                icon: c.icon,
                selected: selectedCategory == i,
                onTap: () => onCategory(i),
              );
            },
          ),
        ),
        const Gap(AppSpacing.lg),
        SectionTitle(
          title: 'Featured',
          actionLabel: 'See all',
          onAction: () => context.go(RouteNames.worldMap),
        ),
        const Gap(AppSpacing.md),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: data.featured.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.md),
            itemBuilder: (context, i) {
              final p = data.featured[i];
              return ProductCard(
                name: p.name,
                imageUrl: p.imageUrl,
                price: p.price,
                storeName: p.storeName,
                distanceKm: p.distanceKm,
                onTap: () => context.go(RouteNames.worldMap),
              );
            },
          ),
        ),
        const Gap(AppSpacing.lg),
        SectionTitle(
          title: 'Stores near you',
          actionLabel: 'Map',
          onAction: () => context.go(RouteNames.worldMap),
        ),
        const Gap(AppSpacing.md),
        for (final s in data.nearby) ...[
          StoreCard(
            name: s.name,
            imageUrl: s.imageUrl,
            rating: s.rating,
            distanceKm: s.distanceKm,
            category: s.category,
            isOpen: s.isOpen,
            onTap: () => context.go(RouteNames.worldMap),
          ),
          const Gap(AppSpacing.sm),
        ],
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good to see you,',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text.secondaryDark,
                ),
              ),
              const Gap(2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.sm),
        GestureDetector(
          onTap: () => context.go(RouteNames.profile),
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppEffects.primaryGlow,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.brXl,
          boxShadow: AppEffects.primaryGlow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover stores\naround you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Open the live map to explore nearby shops.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore map',
                          style: TextStyle(
                            color: AppColors.brand.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.brand.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            const Icon(
              Icons.map_rounded,
              color: Colors.white,
              size: 64,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.storesNearby});

  final int storesNearby;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.storefront_rounded,
            value: '$storesNearby',
            label: 'Nearby',
          ),
        ),
        const Gap(AppSpacing.sm),
        const Expanded(
          child: _StatTile(
            icon: Icons.local_mall_rounded,
            value: '8',
            label: 'Orders',
          ),
        ),
        const Gap(AppSpacing.sm),
        const Expanded(
          child: _StatTile(
            icon: Icons.stars_rounded,
            value: '320',
            label: 'Points',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brand.primary, size: 22),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text.primaryDark,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.text.tertiaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.text.tertiaryDark,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Could not load content',
            style: TextStyle(color: AppColors.text.secondaryDark),
          ),
          const Gap(AppSpacing.sm),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
