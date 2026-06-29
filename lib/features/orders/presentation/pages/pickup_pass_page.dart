import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/qr_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Pickup Pass: the glowing QR + code to show at the store counter.
class PickupPassPage extends StatelessWidget {
  const PickupPassPage({required this.order, super.key});

  final BuyerOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'Pickup Pass'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Show this at ${order.storeName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Gap(AppSpacing.xs),
              Text(
                'Staff will scan it to release your order.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text.tertiaryDark),
              ),
              const Gap(AppSpacing.xl),
              QrCard(data: order.code, code: order.code, glow: true),
              const Gap(AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: order.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.status.icon,
                      size: 16,
                      color: order.status.color,
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      order.status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: order.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
