import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/recommendations/data/datasources/deals_remote_datasource.dart';
import 'package:mapanytime_market_app/features/recommendations/domain/entities/nearby_deal.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/controllers/world_map_controller.dart'
    show getNearbyStoresUseCaseProvider;

/// "For You" page content: nearby/rated stores plus active nearby deals.
/// Ranking is simple and location-based (distance, rating) — not per-user
/// purchase-history personalization.
class RecommendationsFeed {
  const RecommendationsFeed({
    this.nearby = const [],
    this.recommended = const [],
    this.deals = const [],
  });

  final List<StoreEntity> nearby;
  final List<StoreEntity> recommended;
  final List<NearbyDeal> deals;

  bool get isEmpty => nearby.isEmpty && recommended.isEmpty && deals.isEmpty;
}

final dealsRemoteDataSourceProvider = Provider<DealsRemoteDataSource>(
  (ref) => DealsRemoteDataSource(ref.watch(apiServiceProvider)),
);

final recommendationsFeedProvider = FutureProvider<RecommendationsFeed>((
  ref,
) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final lat = position.latitude;
    final lng = position.longitude;
    final north = lat + 0.05;
    final south = lat - 0.05;
    final east = lng + 0.05;
    final west = lng - 0.05;

    final storesResult = await ref.read(getNearbyStoresUseCaseProvider)(
      north: north,
      south: south,
      east: east,
      west: west,
      centerLat: lat,
      centerLng: lng,
      limit: 30,
    );
    final stores = storesResult.fold((_) => <StoreEntity>[], (p) => p.stores);

    final nearby = [...stores]
      ..sort((a, b) => a.distance.compareTo(b.distance));
    final recommended = [...stores]
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    var deals = const <NearbyDeal>[];
    try {
      deals = await ref
          .read(dealsRemoteDataSourceProvider)
          .getNearbyDeals(
            north: north,
            south: south,
            east: east,
            west: west,
            lat: lat,
            lng: lng,
          );
    } on Exception {
      // Deals are supplementary — a failed fetch shouldn't blank the rest
      // of the page.
    }

    return RecommendationsFeed(
      nearby: nearby,
      recommended: recommended,
      deals: deals,
    );
  } on Exception {
    // GPS unavailable/denied — show an empty state rather than an error.
    return const RecommendationsFeed();
  }
});
