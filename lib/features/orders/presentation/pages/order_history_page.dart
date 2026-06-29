import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Order History: active orders (tap → tracking) and past orders.
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: const ModernAppBar(title: 'My Orders'),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Could not load orders',
            style: TextStyle(color: AppColors.text.secondaryDark),
          ),
        ),
        data: (orders) {
          final active = orders.where((o) => o.isActive).toList();
          final past = orders.where((o) => !o.isActive).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              if (active.isNotEmpty) ...[
                const SectionTitle(title: 'Active'),
                const Gap(AppSpacing.md),
                for (final o in active) ...[
                  _OrderCard(order: o),
                  const Gap(AppSpacing.sm),
                ],
                const Gap(AppSpacing.md),
              ],
              const SectionTitle(title: 'Past orders'),
              const Gap(AppSpacing.md),
              for (final o in past) ...[
                _OrderCard(order: o),
                const Gap(AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final BuyerOrder order;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push(RouteNames.orderTracking, extra: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.storeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(order: order),
            ],
          ),
          const Gap(6),
          Text(
            '${order.placedLabel} • ${order.itemCount} '
            'item${order.itemCount == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: AppColors.text.tertiaryDark),
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Text(
                Money.peso(order.total),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text.primaryDark,
                ),
              ),
              const Spacer(),
              Text(
                order.isActive ? 'Track order' : 'View details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand.primary,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.brand.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.order});

  final BuyerOrder order;

  @override
  Widget build(BuildContext context) {
    final color = order.status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        order.status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
