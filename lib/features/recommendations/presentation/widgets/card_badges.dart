import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
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
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: AppRadius.brPill,
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
            style: const TextStyle(
              color: Colors.white,
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
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: isFavorite ? AppColors.status.error : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// A small amber star used next to a numeric rating.
class RatingPill extends StatelessWidget {
  const RatingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, size: 16, color: AppColors.status.warning);
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
