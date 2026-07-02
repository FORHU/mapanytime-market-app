import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/home_content.dart';
import 'package:mapanytime_market_app/features/home/domain/repositories/home_repository.dart';

/// Static mock content for the Home screen. Replace with an API-backed
/// implementation later — the presentation layer depends only on the interface.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  static const _seed = 'https://picsum.photos/seed';

  @override
  Future<HomeContent> getHomeContent() async {
    // Simulate a small network delay for a realistic loading state.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const HomeContent(
      greeting: 'Good Morning,',
      userName: 'Sara Smith',
      location: 'Candon City, Ilocos Sur',
      nearbyCount: 138,
      openNowCount: 92,
      dealsCount: 16,
      categories: [
        HomeCategory(
          label: 'Food',
          icon: Icons.restaurant_rounded,
          color: Color(0xFFFF7A59),
        ),
        HomeCategory(
          label: 'Coffee',
          icon: Icons.local_cafe_rounded,
          color: Color(0xFFB07B53),
        ),
        HomeCategory(
          label: 'Shopping',
          icon: Icons.shopping_bag_rounded,
          color: Color(0xFF5E5CE6),
        ),
        HomeCategory(
          label: 'Beauty',
          icon: Icons.spa_rounded,
          color: Color(0xFFEC4899),
        ),
        HomeCategory(
          label: 'Tech',
          icon: Icons.devices_rounded,
          color: Color(0xFF38BDF8),
        ),
        HomeCategory(
          label: 'Health',
          icon: Icons.health_and_safety_rounded,
          color: Color(0xFF34D399),
        ),
        HomeCategory(
          label: 'Services',
          icon: Icons.handyman_rounded,
          color: Color(0xFFFBBF24),
        ),
        HomeCategory(
          label: 'More',
          icon: Icons.grid_view_rounded,
          color: Color(0xFF8B5CF6),
        ),
      ],
      nearby: [
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
      ],
      deals: [
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
      ],
      recommended: [
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
      ],
    );
  }
}
