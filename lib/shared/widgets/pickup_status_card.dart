import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A compact card showing the current order [status] and an estimated time.
class PickupStatusCard extends StatelessWidget {
  const PickupStatusCard({
    required this.status,
    this.etaLabel,
    super.key,
  });

  final OrderStatus status;
  final String? etaLabel;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceDark,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.ui.borderDark),
        boxShadow: AppEffects.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(status.icon, color: color),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text.primaryDark,
                  ),
                ),
                if (etaLabel != null) ...[
                  const Gap(2),
                  Text(
                    etaLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.secondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: AppRadius.brPill,
            ),
            child: Text(
              'Live',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
