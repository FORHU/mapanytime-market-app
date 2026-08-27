import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_voucher.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

String discountSummary(RewardVoucher voucher) {
  if (voucher.discountType == RewardDiscountType.fixed) {
    return '${Money.peso(voucher.discountValue)} off';
  }
  final cap = voucher.maxDiscountAmount;
  return cap != null
      ? '${voucher.discountValue}% off, up to ${Money.peso(cap)}'
      : '${voucher.discountValue}% off';
}

/// A catalog voucher, with a Claim action. Disabled with an inline reason
/// when the buyer can't afford it.
class VoucherCard extends StatelessWidget {
  const VoucherCard({
    required this.voucher,
    required this.pointsBalance,
    required this.onClaim,
    this.isClaiming = false,
    super.key,
  });

  final RewardVoucher voucher;
  final int pointsBalance;
  final VoidCallback? onClaim;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final canAfford = pointsBalance >= voucher.pointCost;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: AppColors.ink,
              size: 22,
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Gap(2),
                Text(
                  discountSummary(voucher),
                  style: TextStyle(
                    color: AppColors.text.secondary,
                    fontSize: 13,
                  ),
                ),
                if (voucher.minOrderAmount != null) ...[
                  const Gap(2),
                  Text(
                    'Min. order ${Money.peso(voucher.minOrderAmount!)}',
                    style: TextStyle(
                      color: AppColors.text.tertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Gap(AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.toll_rounded,
                      size: 14,
                      color: canAfford
                          ? AppColors.ink
                          : AppColors.text.tertiary,
                    ),
                    const Gap(4),
                    Text(
                      '${voucher.pointCost} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: canAfford
                            ? AppColors.text.primary
                            : AppColors.text.tertiary,
                      ),
                    ),
                    if (!canAfford) ...[
                      const Gap(6),
                      Text(
                        'Need ${voucher.pointCost - pointsBalance} more',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.status.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          SizedBox(
            width: 84,
            child: FilledButton(
              onPressed: canAfford && !isClaiming ? onClaim : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: isClaiming
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Claim', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
