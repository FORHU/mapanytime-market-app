import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';

/// Client-side merchant ads, deterministic per [storeId] so the same store
/// always shows the same cards. Used only by `MockStoreRepository` for the
/// offline/demo repository — `StoreApiRepository` uses the real
/// `merchantAds` field from `GET /stores/:id` instead (see
/// `store_remote_datasource.dart`).
List<MerchantAd> mockMerchantAdsForStore(String storeId, {String? category}) {
  final seed = storeId.isEmpty ? 'store' : storeId;
  final categoryLabel = (category == null || category.isEmpty)
      ? 'this store'
      : category;

  return [
    MerchantAd(
      id: '$seed-promo',
      kind: MerchantAdKind.promo,
      title: 'Weekend special: 15% off',
      description: 'Save on your next order from $categoryLabel this weekend.',
      badgeLabel: '15% OFF',
      ctaLabel: 'View deal',
      extra: const {'validUntil': 'This Sunday'},
    ),
    MerchantAd(
      id: '$seed-job',
      kind: MerchantAdKind.job,
      title: 'Hiring: Part-time Staff',
      description:
          'This merchant is looking for part-time help. Flexible hours.',
      badgeLabel: 'Hiring',
      ctaLabel: 'Apply now',
      extra: const {'salaryLabel': 'Competitive pay'},
    ),
  ];
}
