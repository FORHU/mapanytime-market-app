import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/order_timeline.dart';
import 'package:mapanytime_market_app/shared/widgets/pickup_status_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Order Tracking: live status, timeline, items and a pickup-pass CTA.
class OrderTrackingPage extends ConsumerWidget {
  const OrderTrackingPage({required this.order, super.key});

  final BuyerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = ordersAsync.maybeWhen(
      data: (list) =>
          list.firstWhere((o) => o.id == order.id, orElse: () => order),
      orElse: () => order,
    );

    return Scaffold(
      appBar: ModernAppBar(title: currentOrder.storeName),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              children: [
                PickupStatusCard(
                  status: currentOrder.status,
                  etaLabel: currentOrder.etaLabel,
                ),
                const Gap(AppSpacing.lg),
                const SectionTitle(title: 'Progress'),
                const Gap(AppSpacing.md),
                GlassCard(
                  child: OrderTimeline(
                    current: currentOrder.status,
                    timestamps: currentOrder.timestamps,
                  ),
                ),
                const Gap(AppSpacing.lg),
                const SectionTitle(title: 'Items'),
                const Gap(AppSpacing.md),
                GlassCard(
                  child: Column(
                    children: [
                      for (final line in currentOrder.lines) ...[
                        _ItemRow(
                          name: line.name,
                          quantity: line.quantity,
                          total: line.lineTotal,
                        ),
                        if (line != currentOrder.lines.last)
                          const Gap(AppSpacing.sm),
                      ],
                      const Gap(AppSpacing.sm),
                      Divider(color: AppColors.ui.borderHairline, height: 1),
                      const Gap(AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            Money.peso(currentOrder.total),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (currentOrder.isActive)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.ui.surface,
                boxShadow: AppEffects.cardShadow,
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  label: 'Show pickup pass',
                  icon: Icons.qr_code_rounded,
                  onPressed: () =>
                      context.push(RouteNames.pickupPass, extra: order),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final int quantity;
  final num total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$quantity×',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.text.secondary),
          ),
        ),
        Text(
          Money.peso(total),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.text.primary,
          ),
        ),
      ],
    );
  }
}
