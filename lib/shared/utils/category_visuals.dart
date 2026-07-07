import 'package:flutter/material.dart';

/// Visual mapping for backend-driven categories so chips look consistent
/// wherever they appear (map filter, home filter, …). The backend only sends
/// `{ id, name }`; the icon and accent colour are derived here.

/// Maps a category name to a chip icon. Unknown names fall back to a generic
/// storefront glyph.
IconData iconForCategory(String name) {
  switch (name) {
    case 'Food & Beverage':
      return Icons.restaurant_rounded;
    case 'Shopping & Retail':
      return Icons.checkroom_rounded;
    case 'Electronics':
      return Icons.devices_rounded;
    case 'Home & Living':
      return Icons.chair_rounded;
    case 'Health & Wellness':
      return Icons.spa_rounded;
    case 'Automotive':
      return Icons.directions_car_rounded;
    case 'Pets':
      return Icons.pets_rounded;
    case 'Sports & Outdoors':
      return Icons.sports_basketball_rounded;
    case 'Entertainment':
      return Icons.movie_rounded;
    case 'Baby & Kids':
      return Icons.child_care_rounded;
    case 'Services':
      return Icons.handyman_rounded;
    case 'Agriculture':
      return Icons.agriculture_rounded;
    case 'Industrial & Business':
      return Icons.factory_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

/// A stable accent colour for a category chip, cycled from a fixed palette by
/// [index] so the same position always gets the same colour.
Color colorForCategory(int index) {
  const palette = <Color>[
    Color(0xFFFF7A59),
    Color(0xFFB07B53),
    Color(0xFF5E5CE6),
    Color(0xFFEC4899),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFF8B5CF6),
  ];
  return palette[index % palette.length];
}
