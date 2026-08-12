import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/home/presentation/controllers/home_products_controller.dart';
import 'package:mapanytime_market_app/features/home/presentation/home_mock_data.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/fade_slide_in.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/hero_banner.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/home_app_bar.dart';
import 'package:mapanytime_market_app/features/home/presentation/widgets/quick_category_item.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_feed_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/category_tree.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/utils/category_visuals.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

const _hPad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

/// Neutral accent for the leading "All" / back chips, distinct from the
/// colourful per-category discs.
const _neutralColor = Color(0xFF64748B);

/// Buyer Home (Discover) tab — hero landing plus a product search grid.
///
/// The category filter row is driven by the backend's category tree
/// ([categoryTreeProvider]). It starts on the root categories; tapping a root
/// with children drills into a row of that root's children (with a back chip).
/// Selecting a chip re-fetches the product grid from the buyer catalog
/// (via `HomeProductsController`) for that category — a parent expands to all
/// of its descendants; "All" clears the filter. The grid is paginated and
/// loads more as it nears the bottom. The search box filters the already-loaded
/// results locally by product / store name.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  /// Index of the root we've drilled into (into the roots list). Null means the
  /// filter row is showing the root categories.
  int? _drillRootIndex;

  /// Id of the active category filter; null means "All".
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads the next page as the grid nears the bottom (infinite scroll).
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      unawaited(ref.read(homeProductsControllerProvider.notifier).loadMore());
    }
  }

  void _openMap() => context.go(RouteNames.worldMap);

  /// Debounced server-side search: reloads the grid for the typed term.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(
        ref
            .read(homeProductsControllerProvider.notifier)
            .setSearch(value.trim()),
      );
    });
  }

  /// Highlights the chosen category and reloads the product grid for it
  /// (null = All / whole catalog).
  void _applyCategory(String? id) {
    setState(() => _selectedId = id);
    unawaited(
      ref.read(homeProductsControllerProvider.notifier).setCategory(id ?? ''),
    );
  }

  /// Selecting a root filters by it and, if it has children, drills into them.
  void _onRootTap(int index, CategoryTree root) {
    if (root.children.isNotEmpty) {
      setState(() => _drillRootIndex = index);
    }
    _applyCategory(root.id);
  }

  /// Builds the current chip row from the category tree and the drill state.
  List<_Chip> _buildChips(List<CategoryTree> roots) {
    final drill = _drillRootIndex;

    // Root level: [All] + root categories.
    if (drill == null || drill >= roots.length) {
      return [
        _Chip(
          label: 'All',
          icon: Icons.grid_view_rounded,
          color: _neutralColor,
          selected: _selectedId == null,
          onTap: () => _applyCategory(null),
        ),
        for (var i = 0; i < roots.length; i++)
          _Chip(
            label: roots[i].name,
            icon: iconForCategory(roots[i].name),
            color: colorForKey(roots[i].id),
            selected: _selectedId == roots[i].id,
            onTap: () => _onRootTap(i, roots[i]),
          ),
      ];
    }

    // Drill level: [< root] + [All <root>] + the root's children.
    final root = roots[drill];
    return [
      _Chip(
        label: root.name,
        icon: Icons.chevron_left_rounded,
        color: _neutralColor,
        selected: false,
        onTap: () => setState(() => _drillRootIndex = null),
      ),
      _Chip(
        label: 'All',
        icon: Icons.grid_view_rounded,
        color: colorForKey(root.id),
        selected: _selectedId == root.id,
        onTap: () => _applyCategory(root.id),
      ),
      for (var i = 0; i < root.children.length; i++)
        _Chip(
          label: root.children[i].name,
          icon: iconForCategory(root.children[i].name),
          color: colorForKey(root.children[i].id),
          selected: _selectedId == root.children[i].id,
          onTap: () => _applyCategory(root.children[i].id),
        ),
    ];
  }

  Future<void> _onRefresh() async {
    ref.invalidate(categoryTreeProvider);
    await ref.read(homeProductsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    // Category tree from the API; empty while loading or on error, in which
    // case the row still shows the "All" chip.
    final roots =
        ref.watch(categoryTreeProvider).value ?? const <CategoryTree>[];
    final chips = _buildChips(roots);
    final signature = '$_drillRootIndex|$_selectedId|${chips.length}';

    // Paginated products for the selected category; appends on scroll.
    final productsState = ref.watch(homeProductsControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.brand.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
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
                          unreadCount: ref.watch(
                            notificationFeedControllerProvider.select(
                              (s) => s.unreadCount,
                            ),
                          ),
                          onNotifications: () =>
                              context.go(RouteNames.notifications),
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
                  onChanged: _onSearchChanged,
                  chips: chips,
                  signature: signature,
                ),
              ),

              // --- Scrolls under the pinned header: product grid ---
              // A minimum height keeps the scrollable content taller than
              // the viewport, so the pinned filter header stays pinned when
              // the grid shrinks (e.g. while a filter reloads into a small
              // spinner) instead of bouncing back up and revealing the hero
              // above it.
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        _StickySearchHeader._height,
                  ),
                  child: Column(
                    children: [
                      const Gap(AppSpacing.md),
                      const Padding(
                        padding: _hPad,
                        child: SectionTitle(title: 'Products'),
                      ),
                      const Gap(AppSpacing.md),
                      productsState.when(
                        loading: () => const _LoadingResults(),
                        error: (_, _) => const _ErrorResults(),
                        data: (data) {
                          final products = data.items;
                          if (products.isEmpty) return const _EmptyResults();
                          return Column(
                            children: [
                              Padding(
                                padding: _hPad,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final itemWidth =
                                        (constraints.maxWidth - AppSpacing.md) /
                                        2;
                                    return Wrap(
                                      spacing: AppSpacing.md,
                                      runSpacing: AppSpacing.md,
                                      children: [
                                        for (final p in products)
                                          ProductCard(
                                            name: p.name,
                                            imageUrl: p.imageUrl ?? '',
                                            price: p.price,
                                            storeName: p.storeName,
                                            width: itemWidth,
                                            onTap: () {
                                              if (p.storeId != null &&
                                                  p.storeId!.isNotEmpty) {
                                                unawaited(
                                                  context.push(
                                                    RouteNames.productDetail,
                                                    extra: (
                                                      product: StoreProduct(
                                                        id: p.id,
                                                        name: p.name,
                                                        imageUrl:
                                                            p.imageUrl ?? '',
                                                        price: p.price,
                                                        description: '',
                                                        category:
                                                            p.categoryName ??
                                                            'Other',
                                                        storeId: p.storeId!,
                                                        storeName:
                                                            p.storeName ??
                                                            'Store',
                                                      ),
                                                      storeId: p.storeId!,
                                                      storeName:
                                                          p.storeName ??
                                                          'Store',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                _openMap();
                                              }
                                            },
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              if (data.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.lg,
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          );
                        },
                      ),
                      const Gap(AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single category filter chip descriptor built by the page from the tree +
/// drill state. Keeps [_Filters] a dumb renderer.
class _Chip {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
}

/// Pinned header holding the product search bar and category filter row. Fixed
/// height (no shrink) so it stays put while the grid scrolls beneath it.
class _StickySearchHeader extends SliverPersistentHeaderDelegate {
  _StickySearchHeader({
    required this.controller,
    required this.onChanged,
    required this.chips,
    required this.signature,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<_Chip> chips;

  /// Cheap change key (drill index + selected id + chip count) so the header
  /// only rebuilds when the filter row actually changes.
  final String signature;

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
          _Filters(chips: chips),
          const Gap(AppSpacing.sm),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickySearchHeader oldDelegate) =>
      controller != oldDelegate.controller ||
      signature != oldDelegate.signature;
}

class _Filters extends StatelessWidget {
  const _Filters({required this.chips});

  final List<_Chip> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) {
          final c = chips[i];
          return QuickCategoryItem(
            label: c.label,
            icon: c.icon,
            color: c.color,
            selected: c.selected,
            onTap: c.onTap,
          );
        },
      ),
    );
  }
}

class _LoadingResults extends StatelessWidget {
  const _LoadingResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorResults extends StatelessWidget {
  const _ErrorResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
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
              "Couldn't load products",
              style: TextStyle(color: AppColors.text.secondaryDark),
            ),
          ],
        ),
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
