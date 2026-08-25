import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Visual mapping for backend-driven categories so chips look consistent
/// wherever they appear (map filter, home filter, …). The backend only sends
/// `{ id, name }`; the icon and accent colour are derived here.

// ---------------------------------------------------------------------------
// Icons
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

/// One distinct color per known category name. Chosen to be visually
/// separable from each other, from the brand gradient (indigo → violet), and
/// from the status palette (error red, success green, warning amber).
const _categoryColors = <String, Color>{
  'Food & Beverage': Color(0xFFF97316), // orange
  'Shopping & Retail': Color(0xFFEC4899), // hot pink
  'Electronics': Color(0xFF38BDF8), // sky blue
  'Home & Living': Color(0xFF14B8A6), // teal
  'Health & Wellness': Color(0xFF84CC16), // lime
  'Automotive': Color(0xFFEF4444), // red
  'Pets': Color(0xFFCD7C3A), // warm brown
  'Sports & Outdoors': Color(0xFF06B6D4), // cyan
  'Entertainment': Color(0xFFA855F7), // purple
  'Baby & Kids': Color(0xFFF472B6), // light pink
  'Services': Color(0xFF3B82F6), // royal blue
  'Agriculture': Color(0xFF22C55E), // green
  'Industrial & Business': Color(0xFF94A3B8), // steel
};

/// Fallback palette for arbitrary keys (store IDs, unknown category IDs).
/// Uses the first 8 colors from [_categoryColors] so the visual language stays
/// consistent even for unrecognised categories.
const _fallbackPalette = <Color>[
  Color(0xFFF97316),
  Color(0xFF38BDF8),
  Color(0xFF84CC16),
  Color(0xFFEC4899),
  Color(0xFFA855F7),
  Color(0xFF14B8A6),
  Color(0xFFCD7C3A),
  Color(0xFF06B6D4),
];

/// Returns the canonical color for a known category [name].
/// Falls back to a hash-stable color from [_fallbackPalette] for unknowns.
Color colorForCategory(String name) =>
    _categoryColors[name] ??
    _fallbackPalette[name.hashCode.abs() % _fallbackPalette.length];

/// Hash-stable color for an arbitrary [key] (e.g. a store ID).
/// Prefer [colorForCategory] when the category name is known.
Color colorForKey(String key) =>
    _fallbackPalette[key.hashCode.abs() % _fallbackPalette.length];

// ---------------------------------------------------------------------------
// Store helpers
// ---------------------------------------------------------------------------

/// A merchant's accent color: derived from its category name when known,
/// falling back to a hash of the store ID so distinct merchants still get
/// stable, distinct colors before the category is available.
Color colorForStore(StoreEntity store) {
  final name = store.categoryName;
  return name != null ? colorForCategory(name) : colorForKey(store.id);
}

/// A merchant's marker icon: its category icon when the category name is
/// known, falling back to a generic storefront glyph.
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
