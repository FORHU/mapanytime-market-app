import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/reward_transaction.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

final _dateFormat = DateFormat('MMM d, yyyy · h:mm a');

const _labels = {
  'EARN': 'Points earned',
  'SPEND': 'Voucher claimed',
  'BONUS': 'Bonus points',
  'REFUND': 'Refund',
  'EXPIRED': 'Points expired',
  'REVERSAL': 'Reversal',
  'ADJUSTMENT': 'Adjustment',
};

const Map<String, IconData> _icons = {
  'EARN': Icons.add_circle_outline_rounded,
  'SPEND': Icons.local_offer_outlined,
  'BONUS': Icons.card_giftcard_rounded,
  'REFUND': Icons.replay_rounded,
  'EXPIRED': Icons.timer_off_outlined,
  'REVERSAL': Icons.undo_rounded,
  'ADJUSTMENT': Icons.tune_rounded,
};

/// One row of the MapPoints ledger.
class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final RewardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount > 0;
    final amountColor = isPositive
        ? AppColors.status.success
        : AppColors.status.error;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _icons[transaction.type] ?? Icons.circle_outlined,
              size: 18,
              color: AppColors.ink,
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labels[transaction.type] ?? transaction.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Gap(2),
                Text(
                  _dateFormat.format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text.tertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.amount} pts',
            style: TextStyle(fontWeight: FontWeight.w700, color: amountColor),
          ),
        ],
      ),
    );
  }
}
