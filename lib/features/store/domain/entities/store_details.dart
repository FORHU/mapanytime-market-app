import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_hours.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// Display-level details for a storefront, supplementing the lean
/// `StoreEntity` from the map API with mock presentation data.
class StoreDetails {
  const StoreDetails({
    required this.heroImageUrl,
    required this.rating,
    required this.ratingCount,
    required this.category,
    required this.isOpen,
    required this.etaLabel,
    required this.productCategories,
    required this.products,
    required this.hours,
    required this.ads,
  });

  final String heroImageUrl;
  final double rating;
  final int ratingCount;
  final String category;
  final bool isOpen;
  final String etaLabel;
  final List<String> productCategories;
  final List<StoreProduct> products;

  /// Real per-day schedule from the backend (unlike the fields above, this
  /// one already has live API support — see `store_remote_datasource.dart`).
  final List<StoreDayHours> hours;

  /// Merchant promos/deals, limited-time events, and job postings. Backed by
  /// the real `merchantAds` field on `GET /stores/:id` (see
  /// `store_remote_datasource.dart`); `MockStoreRepository` still synthesizes
  /// these via `mock_merchant_ads.dart` for the offline/demo repository.
  final List<MerchantAd> ads;
}
