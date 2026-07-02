import 'package:flutter/material.dart';

/// A featured product shown on the Landing screen.
class FeaturedProduct {
  const FeaturedProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.storeName,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String imageUrl;
  final num price;
  final String storeName;
  final double distanceKm;
}

/// A nearby store shown on the Landing screen.
class NearbyStorePreview {
  const NearbyStorePreview({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.distanceKm,
    required this.category,
    this.isOpen = true,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final double distanceKm;
  final String category;
  final bool isOpen;
}

/// A category filter shown on the Landing screen.
class LandingCategory {
  const LandingCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// The full content bundle the Landing screen renders.
class LandingContent {
  const LandingContent({
    required this.categories,
    required this.featured,
    required this.nearby,
    required this.storesNearbyCount,
  });

  final List<LandingCategory> categories;
  final List<FeaturedProduct> featured;
  final List<NearbyStorePreview> nearby;
  final int storesNearbyCount;
}
