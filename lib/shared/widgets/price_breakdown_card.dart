import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Server-verified Subtotal / Discount / Tax / Total breakdown, shared by
/// the cart and checkout pages so both always show the exact numbers
/// checkout will charge — never a client-side guess.
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({required this.pricing, this.onRetry, super.key});

  final AsyncValue<CartPricing?> pricing;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: pricing.when(
        loading: () => const _SkeletonRows(),
        error: (_, _) => _ErrorRows(onRetry: onRetry),
        data: (value) => value == null
            ? const _Row(label: 'Total', value: '—', bold: true)
            : _BreakdownRows(pricing: value),
      ),
    );
  }
}

class _BreakdownRows extends StatelessWidget {
  const _BreakdownRows({required this.pricing});

  final CartPricing pricing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Row(label: 'Subtotal', value: Money.peso(pricing.subtotalAmount)),
        if (pricing.discountAmount > 0) ...[
          const Gap(AppSpacing.sm),
          _Row(
            label: 'Discount',
            value: '-${Money.peso(pricing.discountAmount)}',
            icon: Icons.local_offer_rounded,
            valueColor: AppColors.status.success,
          ),
        ],
        const Gap(AppSpacing.sm),
        _Row(label: 'Tax', value: Money.peso(pricing.taxAmount)),
        const Gap(AppSpacing.sm),
        Divider(color: AppColors.ui.borderDark, height: 1),
        const Gap(AppSpacing.sm),
        _Row(
          label: 'Total',
          value: Money.peso(pricing.totalAmount),
          bold: true,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final labelStyle = (bold ? tt.bodyLarge : tt.bodyMedium)?.copyWith(
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.text.primaryDark : AppColors.text.secondaryDark,
    );
    final valueStyle = labelStyle?.copyWith(
      color: valueColor ?? labelStyle.color,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: valueColor),
              const Gap(4),
            ],
            Text(label, style: labelStyle),
          ],
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows();

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceElevatedDark,
        borderRadius: AppRadius.brSm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_bar(70, 14), _bar(60, 14)],
        ),
        const Gap(AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_bar(50, 14), _bar(50, 14)],
        ),
        const Gap(AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_bar(90, 18), _bar(80, 18)],
        ),
      ],
    );
  }
}

class _ErrorRows extends StatelessWidget {
  const _ErrorRows({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: AppColors.status.error,
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            "Couldn't load pricing",
            style: TextStyle(color: AppColors.text.secondaryDark),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
