/// Presentational dummy data for the "For You" page.
///
/// No business logic / no networking — plain view models with static sample
/// content so the UI can be built and reviewed in isolation. Swap for real
/// repositories/providers later.
library;

const _seed = 'https://picsum.photos/seed';

/// A merchant shown in the horizontal "Nearby Merchants" rail.
class NearbyMerchant {
  const NearbyMerchant({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.logoUrl,
    required this.rating,
    required this.distanceKm,
    required this.travelTime,
    required this.isOpen,
  });

  final String name;
  final String category;
  final String imageUrl;
  final String logoUrl;
  final double rating;
  final double distanceKm;
  final String travelTime;
  final bool isOpen;
}

/// A promotional deal card.
class HomeDeal {
  const HomeDeal({
    required this.merchant,
    required this.imageUrl,
    required this.discountLabel,
    required this.price,
    required this.oldPrice,
    required this.distanceKm,
  });

  final String merchant;
  final String imageUrl;
  final String discountLabel;
  final double price;
  final double oldPrice;
  final double distanceKm;
}

/// A store in the vertical "Recommended" list.
class RecommendedStore {
  const RecommendedStore({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.distanceKm,
    required this.isOpen,
  });

  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final double distanceKm;
  final bool isOpen;
}

/// Static sample content for the "For You" page.
abstract final class RecommendationsMock {
  static const nearby = <NearbyMerchant>[
    NearbyMerchant(
      name: 'Greenhouse Bistro',
      category: 'Italian · Healthy · Organic',
      imageUrl: '$_seed/greenhouse/600/400',
      logoUrl: '$_seed/greenhouselogo/100/100',
      rating: 4.8,
      distanceKm: 0.4,
      travelTime: '6 min',
      isOpen: true,
    ),
    NearbyMerchant(
      name: 'Luxe Atelier',
      category: 'Fashion · Boutique',
      imageUrl: '$_seed/luxe/600/400',
      logoUrl: '$_seed/luxelogo/100/100',
      rating: 4.6,
      distanceKm: 1.2,
      travelTime: '11 min',
      isOpen: true,
    ),
    NearbyMerchant(
      name: 'Pulse Electronics',
      category: 'Tech · Gadgets',
      imageUrl: '$_seed/pulse/600/400',
      logoUrl: '$_seed/pulselogo/100/100',
      rating: 4.4,
      distanceKm: 2,
      travelTime: '18 min',
      isOpen: false,
    ),
  ];

  static const deals = <HomeDeal>[
    HomeDeal(
      merchant: 'Café Nero',
      imageUrl: '$_seed/cafenero/600/400',
      discountLabel: '30% OFF',
      price: 4.5,
      oldPrice: 6.5,
      distanceKm: 0.6,
    ),
    HomeDeal(
      merchant: 'Glow Theory',
      imageUrl: '$_seed/glow/600/400',
      discountLabel: 'BOGO',
      price: 18,
      oldPrice: 36,
      distanceKm: 1.1,
    ),
  ];

  static const recommended = <RecommendedStore>[
    RecommendedStore(
      name: 'Harbor Market',
      category: 'Grocery · Local',
      imageUrl: '$_seed/harbor/300/300',
      rating: 4.7,
      distanceKm: 0.9,
      isOpen: true,
    ),
    RecommendedStore(
      name: 'Stitch & Co.',
      category: 'Tailoring · Services',
      imageUrl: '$_seed/stitch/300/300',
      rating: 4.5,
      distanceKm: 1.5,
      isOpen: true,
    ),
    RecommendedStore(
      name: 'Bloom Florals',
      category: 'Florist · Gifts',
      imageUrl: '$_seed/bloom/300/300',
      rating: 4.9,
      distanceKm: 2.3,
      isOpen: false,
    ),
  ];
}
