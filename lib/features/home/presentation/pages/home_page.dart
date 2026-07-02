import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/home/presentation/home_mock_data.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/fade_slide_in.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/hero_banner.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/home_app_bar.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/quick_category_item.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

/// Buyer Home (Discover) tab — hero landing plus a product search grid.
///
/// Presentational only: static dummy data ([HomeMock]). The search box filters
/// the grid live by product or store name; taps route to the live map for now.
/// The search bar + category filters pin to the top while the grid scrolls.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMap() => context.go(RouteNames.worldMap);

  List<HomeProduct> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return HomeMock.products;
    return HomeMock.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.storeName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filtered;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // --- Scrolls away: top bar + hero ---
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const Gap(AppSpacing.sm),
                  Padding(
                    padding: _hPad,
                    child: FadeSlideIn(
                      child: HomeAppBar(
                        greeting: HomeMock.greeting,
                        name: HomeMock.userName,
                        location: HomeMock.location,
                        onProfile: () => context.go(RouteNames.profile),
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  Padding(
                    padding: _hPad,
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: HeroBanner(
                        nearbyCount: HomeMock.nearbyCount,
                        openNowCount: HomeMock.openNowCount,
                        dealsCount: HomeMock.dealsCount,
                        onOpenMap: _openMap,
                        onBrowseCategories: _openMap,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
                ],
              ),
            ),

            // --- Pinned: search + category filters ---
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchHeader(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                onFilterTap: _openMap,
              ),
            ),

            // --- Scrolls under the pinned header: product grid ---
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const Gap(AppSpacing.md),
                  const Padding(
                    padding: _hPad,
                    child: SectionTitle(title: 'Products'),
                  ),
                  const Gap(AppSpacing.md),
                  if (products.isEmpty)
                    const _EmptyResults()
                  else
                    Padding(
                      padding: _hPad,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth =
                              (constraints.maxWidth - AppSpacing.md) / 2;
                          return Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              for (final p in products)
                                ProductCard(
                                  name: p.name,
                                  imageUrl: p.imageUrl,
                                  price: p.price,
                                  storeName: p.storeName,
                                  distanceKm: p.distanceKm,
                                  width: itemWidth,
                                  onTap: _openMap,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  const Gap(AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned header holding the product search bar and category filter row. Fixed
/// height (no shrink) so it stays put while the grid scrolls beneath it.
class _StickySearchHeader extends SliverPersistentHeaderDelegate {
  _StickySearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  // sm(8) + search(54) + md(16) + filters(92) + sm(8)
  static const double _height = 178;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const Gap(AppSpacing.sm),
          Padding(
            padding: _hPad,
            child: FloatingSearchBar(
              hint: 'Search products...',
              controller: controller,
              onChanged: onChanged,
            ),
          ),
          const Gap(AppSpacing.md),
          _Filters(onTap: onFilterTap),
          const Gap(AppSpacing.sm),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickySearchHeader oldDelegate) =>
      controller != oldDelegate.controller;
}

class _Filters extends StatelessWidget {
  const _Filters({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: HomeMock.categories.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) {
          final c = HomeMock.categories[i];
          return QuickCategoryItem(
            label: c.label,
            icon: c.icon,
            color: c.color,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.text.tertiaryDark,
            ),
            const Gap(AppSpacing.sm),
            Text(
              'No products found',
              style: TextStyle(color: AppColors.text.secondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
