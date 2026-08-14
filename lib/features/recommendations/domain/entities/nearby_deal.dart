import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';

/// An active discount ad linked to a nearby store's product — powers the
/// "For You" page's "Today's Deals" rail. Wraps the same [MerchantAd] model
/// already used on the storefront/product-detail pages.
class NearbyDeal {
  const NearbyDeal({
    required this.ad,
    required this.storeId,
    required this.storeName,
    required this.distanceKm,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.productPrice,
  });

  factory NearbyDeal.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;

    return NearbyDeal(
      ad: MerchantAd.fromJson(json),
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? 'Store',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      productId: product?['id'] as String?,
      productName: product?['name'] as String?,
      productImageUrl: product?['imageUrl'] as String?,
      productPrice: MerchantAd.parseNum(product?['price']),
    );
  }

  final MerchantAd ad;
  final String storeId;
  final String storeName;
  final double distanceKm;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final num? productPrice;

  /// The discounted unit price when computable (%, fixed-amount off); null
  /// for BOGO or when the product price is unknown — there's no single
  /// "discounted price" for a buy-X-get-Y-free deal.
  num? get discountedPrice {
    if (productPrice == null) return null;
    return switch (ad.discountType) {
      'PERCENTAGE' => productPrice! * (1 - (ad.discountValue ?? 0) / 100),
      'FIXED_AMOUNT' => (productPrice! - (ad.discountValue ?? 0)).clamp(
        0,
        productPrice!,
      ),
      _ => null,
    };
  }
}
