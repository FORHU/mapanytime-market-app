import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

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

const _categoryPalette = <Color>[
  Color(0xFFFF7A59),
  Color(0xFFB07B53),
  Color(0xFF5E5CE6),
  Color(0xFFEC4899),
  Color(0xFF38BDF8),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFF8B5CF6),
];

/// A stable accent colour for [key] (a category id, store id, or similar),
/// cycled from a fixed palette by hashing the string. Unlike a positional
/// index, the same key always maps to the same colour regardless of where it
/// falls in a list.
Color colorForKey(String key) {
  return _categoryPalette[key.hashCode % _categoryPalette.length];
}

/// A merchant's marker/accent colour: keyed off its category once the
/// backend provides one, falling back to the store id so distinct merchants
/// still get distinct, stable colours before then.
Color colorForStore(StoreEntity store) {
  return colorForKey(store.categoryId ?? store.id);
}

/// A merchant's marker icon: its category icon once the backend provides a
/// category name, falling back to a generic storefront glyph.
IconData iconForStore(StoreEntity store) {
  final categoryName = store.categoryName;
  return categoryName == null
      ? Icons.storefront_rounded
      : iconForCategory(categoryName);
}

/// Initials used as a marker avatar fallback when a merchant has no logo.
String monogramForStore(StoreEntity store) {
  final trimmed = store.name.trim();
  if (trimmed.isEmpty) return '?';
  final words = trimmed.split(RegExp(r'\s+'));
  final first = words.first[0];
  if (words.length == 1) return first.toUpperCase();
  final second = words[1][0];
  return (first + second).toUpperCase();
}
