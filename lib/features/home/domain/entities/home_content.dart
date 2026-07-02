import 'package:flutter/material.dart';

/// Domain models for the Home (Discover) screen. The presentation layer depends
/// only on these; swap the repository implementation (mock → API) without
/// touching the UI.

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

/// The full content bundle the Home screen renders.
class HomeContent {
  const HomeContent({
    required this.greeting,
    required this.userName,
    required this.location,
    required this.nearbyCount,
    required this.openNowCount,
    required this.dealsCount,
    required this.categories,
    required this.nearby,
    required this.deals,
    required this.recommended,
  });

  final String greeting;
  final String userName;
  final String location;

  final int nearbyCount;
  final int openNowCount;
  final int dealsCount;

  final List<HomeCategory> categories;
  final List<NearbyMerchant> nearby;
  final List<HomeDeal> deals;
  final List<RecommendedStore> recommended;
}
