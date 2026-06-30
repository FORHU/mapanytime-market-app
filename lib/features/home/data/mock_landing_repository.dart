import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/home/domain/entities/landing_content.dart';
import 'package:mapanytime_market_app/features/home/domain/repositories/landing_repository.dart';

/// Static mock content for the Landing screen. Replace with an API-backed
/// implementation later — the presentation layer depends only on the interface.
class MockLandingRepository implements LandingRepository {
  const MockLandingRepository();

  static const _img = 'https://picsum.photos/seed/mapanytime';

  @override
  Future<LandingContent> getLandingContent() async {
    // Simulate a tiny network delay for a realistic loading state.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    return const LandingContent(
      storesNearbyCount: 24,
      categories: [
        LandingCategory(label: 'All', icon: Icons.grid_view_rounded),
        LandingCategory(label: 'Food', icon: Icons.restaurant_rounded),
        LandingCategory(label: 'Fashion', icon: Icons.checkroom_rounded),
        LandingCategory(label: 'Tech', icon: Icons.devices_rounded),
        LandingCategory(label: 'Home', icon: Icons.chair_rounded),
        LandingCategory(label: 'Beauty', icon: Icons.spa_rounded),
      ],
      featured: [
        FeaturedProduct(
          id: 'p1',
          name: 'Japanese Matcha Kit',
          imageUrl: '$_img-1/400',
          price: 942,
          storeName: 'ZenMarket',
          distanceKm: 1.2,
        ),
        FeaturedProduct(
          id: 'p2',
          name: 'Studio Desk Lamp',
          imageUrl: '$_img-2/400',
          price: 1599,
          storeName: 'Nova Home',
          distanceKm: 3.4,
        ),
        FeaturedProduct(
          id: 'p3',
          name: 'Cold Brew Tower',
          imageUrl: '$_img-4/400',
          price: 2350,
          storeName: 'Daily Grind',
          distanceKm: 0.8,
        ),
        FeaturedProduct(
          id: 'p4',
          name: 'Linen Throw Blanket',
          imageUrl: '$_img-5/400',
          price: 1120,
          storeName: 'Nova Home',
          distanceKm: 3.4,
        ),
      ],
      nearby: [
        NearbyStorePreview(
          id: 's1',
          name: 'ZenMarket',
          imageUrl: '$_img-3/200',
          rating: 4.8,
          distanceKm: 1.2,
          category: 'Specialty • Tea & Coffee',
        ),
        NearbyStorePreview(
          id: 's2',
          name: 'Nova Home',
          imageUrl: '$_img-6/200',
          rating: 4.6,
          distanceKm: 3.4,
          category: 'Home & Living',
        ),
        NearbyStorePreview(
          id: 's3',
          name: 'Daily Grind',
          imageUrl: '$_img-7/200',
          rating: 4.9,
          distanceKm: 0.8,
          category: 'Coffee • Bakery',
        ),
        NearbyStorePreview(
          id: 's4',
          name: 'Pixel Tech',
          imageUrl: '$_img-8/200',
          rating: 4.5,
          distanceKm: 2.1,
          category: 'Electronics',
          isOpen: false,
        ),
      ],
    );
  }
}
