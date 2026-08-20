import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_hours.dart';
import 'package:mapanytime_market_app/features/store/presentation/controllers/store_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/merchant_ad_section.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/icon_button.dart';
import 'package:mapanytime_market_app/shared/widgets/network_image_box.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Airbnb-style floating card shown over the map when a marker is tapped:
/// a photo carousel (store photo + product photos, each tapping through to
/// its own page) plus the essentials — name, rating, today's hours.
class StoreFloatingCard extends ConsumerStatefulWidget {
  const StoreFloatingCard({
    required this.store,
    required this.onClose,
    required this.onNavigate,
    super.key,
  });

  final StoreEntity store;
  final VoidCallback onClose;
  final VoidCallback onNavigate;

  @override
  ConsumerState<StoreFloatingCard> createState() => _StoreFloatingCardState();
}

class _StoreFloatingCardState extends ConsumerState<StoreFloatingCard> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StoreFloatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store.id != widget.store.id) {
      _page = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    }
  }

  List<_Slide> _slidesFor(StoreDetails details) {
    final slides = <_Slide>[
      _Slide(
        imageUrl: details.heroImageUrl,
        onTap: () =>
            context.push(RouteNames.storefront, extra: widget.store),
      ),
    ];
    for (final product in details.products) {
      if (product.imageUrl.isEmpty) continue;
      slides.add(
        _Slide(
          imageUrl: product.imageUrl,
          onTap: () => context.push(
            RouteNames.productDetail,
            extra: (
              product: product,
              storeId: widget.store.id,
              storeName: widget.store.name,
              promo: null,
            ),
          ),
        ),
      );
    }
    return slides;
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(storeDetailsProvider(widget.store.id));
    final details = detailsAsync.value;
    final hasError = detailsAsync.hasError;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brLg,
        boxShadow: AppEffects.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (details != null)
                  _Carousel(
                    slides: _slidesFor(details),
                    controller: _pageController,
                    page: _page,
                    onPageChanged: (i) => setState(() => _page = i),
                  )
                else if (hasError)
                  _ErrorSlide(
                    onRetry: () => ref.invalidate(
                      storeDetailsProvider(widget.store.id),
                    ),
                  )
                else
                  const _LoadingSlide(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: Icons.near_me_rounded,
                        size: 32,
                        iconSize: 15,
                        onTap: widget.onNavigate,
                      ),
                      const SizedBox(width: 8),
                      AppIconButton(
                        icon: Icons.close_rounded,
                        size: 32,
                        iconSize: 16,
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RatingRow(store: widget.store, details: details),
                    const SizedBox(width: 10),
                    _HoursRow(details: details),
                  ],
                ),
                if (details != null && details.ads.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  MerchantAdSection(
                    ads: details.ads,
                    onAdTap: (ad) {
                      if (ad.kind == MerchantAdKind.job) {
                        unawaited(
                          context.push(
                            RouteNames.jobPostingDetail,
                            extra: (
                              ad: ad,
                              storeId: widget.store.id,
                              storeName: widget.store.name,
                            ),
                          ),
                        );
                      } else {
                        unawaited(
                          context.push(
                            RouteNames.storefront,
                            extra: widget.store,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;
}

class _Carousel extends StatelessWidget {
  const _Carousel({
    required this.slides,
    required this.controller,
    required this.page,
    required this.onPageChanged,
  });

  final List<_Slide> slides;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          onPageChanged: onPageChanged,
          itemCount: slides.length,
          itemBuilder: (context, i) {
            final slide = slides[i];
            return GestureDetector(
              onTap: slide.onTap,
              child: NetworkImageBox(url: slide.imageUrl),
            );
          },
        ),
        if (slides.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ui.surface,
                  borderRadius: AppRadius.brPill,
                  boxShadow: AppEffects.cardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: page == i ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: page == i
                              ? AppColors.ink
                              : AppColors.ui.borderHairline,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingSlide extends StatelessWidget {
  const _LoadingSlide();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ui.surfaceMuted,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.text.tertiary,
          ),
        ),
      ),
    );
  }
}

class _ErrorSlide extends StatelessWidget {
  const _ErrorSlide({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ui.surfaceMuted,
      child: Center(
        child: GestureDetector(
          onTap: onRetry,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 22,
                color: AppColors.text.tertiary,
              ),
              const SizedBox(height: 6),
              Text(
                "Couldn't load photos — tap to retry",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.store, required this.details});

  final StoreEntity store;
  final StoreDetails? details;

  @override
  Widget build(BuildContext context) {
    final useDetails = details != null && details!.ratingCount > 0;
    final rating = useDetails ? details!.rating : store.rating;
    final count = useDetails ? details!.ratingCount : store.ratingCount;
    if (rating == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 14, color: AppColors.status.warning),
        const SizedBox(width: 2),
        Text(
          count != null
              ? '${rating.toStringAsFixed(1)} ($count)'
              : rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text.secondary,
          ),
        ),
      ],
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.details});

  final StoreDetails? details;

  @override
  Widget build(BuildContext context) {
    final today = details?.hours.today();
    if (today == null) return const SizedBox.shrink();

    final closed = today.isClosed;
    final label = closed ? 'Closed today' : details!.hours.formatted(today);
    final color = closed ? AppColors.text.tertiary : AppColors.status.success;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
