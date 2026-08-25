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

/// One distinct color per known category name. A shared tone family
/// (consistent saturation/lightness, hues spread around the wheel) rather
/// than each hue at its own max-saturation "brand" tint — a map scattered
/// with a dozen neon dots reads as confetti, not as a legible category key.
/// Kept confident/legible rather than fully desaturated — too muted reads
/// as dull/lifeless at marker scale.
const _categoryColors = <String, Color>{
  'Food & Beverage': Color(0xFFD97C3A), // warm terracotta
  'Shopping & Retail': Color(0xFFD2567F), // rose
  'Electronics': Color(0xFF498AD4), // steel blue
  'Home & Living': Color(0xFF30A68E), // teal
  'Health & Wellness': Color(0xFF3AA64C), // sage green
  'Automotive': Color(0xFFD94A3A), // brick red
  'Pets': Color(0xFFB87A3D), // warm taupe
  'Sports & Outdoors': Color(0xFF309BB5), // teal-blue
  'Entertainment': Color(0xFF905EC9), // plum
  'Baby & Kids': Color(0xFFE08594), // dusty pink
  'Services': Color(0xFF4165C8), // denim
  'Agriculture': Color(0xFF579438), // olive
  'Industrial & Business': Color(0xFF858FA3), // steel gray
};

/// Fallback palette for arbitrary keys (store IDs, unknown category IDs).
/// Uses 8 colors from [_categoryColors] so the visual language stays
/// consistent even for unrecognised categories.
const _fallbackPalette = <Color>[
  Color(0xFFD97C3A),
  Color(0xFF498AD4),
  Color(0xFF3AA64C),
  Color(0xFFD2567F),
  Color(0xFF905EC9),
  Color(0xFF30A68E),
  Color(0xFFB87A3D),
  Color(0xFF309BB5),
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
