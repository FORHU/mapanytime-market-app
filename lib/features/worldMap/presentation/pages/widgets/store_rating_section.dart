import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Ratings & reviews section shown in the map bottom sheet.
class StoreRatingSection extends StatelessWidget {
  const StoreRatingSection({
    required this.rating,
    required this.ratingCount,
    super.key,
  });

  final double rating;
  final int ratingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Ratings & Reviews'),
        const Gap(AppSpacing.sm),
        if (ratingCount == 0)
          Text(
            'No reviews yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.text.secondary,
            ),
          )
        else
          Row(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(AppSpacing.sm),
              _StarRow(rating: rating),
              const Gap(AppSpacing.sm),
              Text(
                '($ratingCount)',
                style: TextStyle(color: AppColors.text.secondary),
              ),
            ],
          ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final threshold = i + 1;
        IconData icon;
        if (rating >= threshold) {
          icon = Icons.star_rounded;
        } else if (rating >= threshold - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }
        return Icon(icon, size: 18, color: AppColors.status.warning);
      }),
    );
  }
}
