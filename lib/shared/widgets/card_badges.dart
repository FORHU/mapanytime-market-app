import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// Small "Open / Closed" status chip used on store covers.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.isOpen, super.key});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.status.success : AppColors.text.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: AppRadius.brPill,
        boxShadow: AppEffects.overlayShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const Gap(5),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              color: AppColors.text.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular favorite (heart) toggle button for card overlays.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({this.onTap, this.isFavorite = false, super.key});

  final VoidCallback? onTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppEffects.overlayShadow,
      ),
      child: Material(
        color: AppColors.ui.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 16,
              color: isFavorite
                  ? AppColors.status.error
                  : AppColors.text.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// An amber chip pairing a star with the numeric rating, so the rating
/// reads as one unit.
class RatingPill extends StatelessWidget {
  const RatingPill({required this.rating, super.key});

  final num rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: AppColors.status.warning.withValues(alpha: 0.14),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppColors.status.warning),
          const Gap(3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.status.warningStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// A category icon on a white rounded tile, lifted off a tinted cover.
class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.color,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 24,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppEffects.tileShadow(size),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// A bold discount tag (e.g. "30% OFF") for deal cards.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.text.onInk,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
