/// Presentational dummy data for the Home page.
///
/// No business logic / no networking — these are plain view models with static
/// sample content so the UI can be built and reviewed in isolation. Swap for
/// real repositories/providers later.
library;

import 'package:flutter/material.dart';

const _seed = 'https://picsum.photos/seed';

/// A circular quick-access category.
class HomeCategory {
  const HomeCategory({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// A product shown in the Home search grid.
class HomeProduct {
  const HomeProduct({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.storeName,
    required this.distanceKm,
  });

  final String name;
  final String imageUrl;
  final double price;
  final String storeName;
  final double distanceKm;
}

/// Static sample content for the Home page.
abstract final class HomeMock {
  static const greeting = 'Good Morning,';
  static const userName = 'Sara Smith';
  static const location = 'Candon City, Ilocos Sur';

  static const nearbyCount = 138;
  static const openNowCount = 92;
  static const dealsCount = 16;

  static const categories = <HomeCategory>[
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
  ];

  static const products = <HomeProduct>[
    HomeProduct(
      name: 'Japanese Matcha Kit',
      imageUrl: '$_seed/matcha/400/400',
      price: 24.5,
      storeName: 'ZenMarket',
      distanceKm: 1.2,
    ),
    HomeProduct(
      name: 'Studio Desk Lamp',
      imageUrl: '$_seed/desklamp/400/400',
      price: 39.99,
      storeName: 'Nova Home',
      distanceKm: 3.4,
    ),
    HomeProduct(
      name: 'Cold Brew Tower',
      imageUrl: '$_seed/coldbrew/400/400',
      price: 58,
      storeName: 'Daily Grind',
      distanceKm: 0.8,
    ),
    HomeProduct(
      name: 'Linen Throw Blanket',
      imageUrl: '$_seed/linen/400/400',
      price: 28,
      storeName: 'Nova Home',
      distanceKm: 3.4,
    ),
    HomeProduct(
      name: 'Artisan Sourdough',
      imageUrl: '$_seed/sourdough/400/400',
      price: 6.5,
      storeName: 'Café Nero',
      distanceKm: 0.6,
    ),
    HomeProduct(
      name: 'Wireless Earbuds',
      imageUrl: '$_seed/earbuds/400/400',
      price: 79,
      storeName: 'Pulse Electronics',
      distanceKm: 2,
    ),
    HomeProduct(
      name: 'Vitamin C Serum',
      imageUrl: '$_seed/serum/400/400',
      price: 32,
      storeName: 'Glow Theory',
      distanceKm: 1.1,
    ),
    HomeProduct(
      name: 'Ceramic Pour-Over',
      imageUrl: '$_seed/pourover/400/400',
      price: 21,
      storeName: 'Daily Grind',
      distanceKm: 0.8,
    ),
  ];
}
