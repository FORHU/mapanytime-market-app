import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/features/rewards/domain/entities/user_voucher.dart'
    show UserVoucher, UserVoucherStatus;
import 'package:mapanytime_market_app/features/rewards/presentation/widgets/voucher_card.dart'
    show discountSummary;
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

final _dateFormat = DateFormat('MMM d, yyyy');

class _StatusChipStyle {
  const _StatusChipStyle(this.label, this.color);
  final String label;
  final Color color;
}

_StatusChipStyle _styleFor(UserVoucherStatus status) {
  switch (status) {
    case UserVoucherStatus.active:
      return _StatusChipStyle('Active', AppColors.status.success);
    case UserVoucherStatus.used:
      return _StatusChipStyle('Used', AppColors.text.tertiary);
    case UserVoucherStatus.expired:
      return _StatusChipStyle('Expired', AppColors.status.error);
  }
}

/// One claimed voucher — the "My Vouchers" tab's row. [onApply] is only
/// meaningful for an active, unexpired voucher (e.g. from the checkout
/// picker); omit it to render as read-only history.
class ClaimedVoucherCard extends StatelessWidget {
  const ClaimedVoucherCard({
    required this.userVoucher,
    this.onApply,
    this.selected = false,
    super.key,
  });

  final UserVoucher userVoucher;
  final VoidCallback? onApply;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(userVoucher.status);
    final voucher = userVoucher.voucher;

    return GlassCard(
      color: selected ? AppColors.ink.withValues(alpha: 0.06) : null,
      onTap: onApply,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: style.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  discountSummary(voucher),
                  style: TextStyle(
                    color: AppColors.text.secondary,
                    fontSize: 13,
                  ),
                ),
                const Gap(2),
                Text(
                  userVoucher.status == UserVoucherStatus.active
                      ? 'Expires ${_dateFormat.format(userVoucher.expiresAt)}'
                      : userVoucher.usedAt != null
                      ? 'Used ${_dateFormat.format(userVoucher.usedAt!)}'
                      : 'Expired ${_dateFormat.format(userVoucher.expiresAt)}',
                  style: TextStyle(
                    color: AppColors.text.tertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onApply != null) ...[
            const Gap(AppSpacing.sm),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.ink : AppColors.text.tertiary,
            ),
          ],
        ],
      ),
    );
  }
}
