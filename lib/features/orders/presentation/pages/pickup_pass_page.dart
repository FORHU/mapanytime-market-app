import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/orders/data/order_remote_datasource.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';
import 'package:mapanytime_market_app/shared/widgets/qr_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Pickup Pass: the glowing QR + code to show at the store counter.
class PickupPassPage extends ConsumerWidget {
  const PickupPassPage({required this.order, super.key});

  final BuyerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = ordersAsync.maybeWhen(
      data: (orders) => orders.firstWhere(
        (o) => o.id == order.id,
        orElse: () => order,
      ),
      orElse: () => order,
    );

    final showQr =
        currentOrder.status == OrderStatus.ready ||
        currentOrder.status == OrderStatus.pickedUp;

    return Scaffold(
      backgroundColor: AppColors.ui.background,
      appBar: const ModernAppBar(title: 'Pickup Pass'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              if (showQr)
                QrCard(
                  data: 'MAPANYTIME-ORDER-${currentOrder.id}',
                  code: currentOrder.code,
                  glow: true,
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.ui.surfaceDark,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: AppColors.ui.borderDark),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 64,
                        color: AppColors.text.tertiaryDark,
                      ),
                      const Gap(AppSpacing.md),
                      Text(
                        'QR Code Not Active Yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text.primaryDark,
                        ),
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        'Your pickup pass QR code will automatically '
                        'appear here once the store marks your order '
                        'as Ready for Pickup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              const Gap(AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: currentOrder.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentOrder.status.icon,
                      size: 16,
                      color: currentOrder.status.color,
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      currentOrder.status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: currentOrder.status.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentOrder.status == OrderStatus.confirmed) ...[
                const Gap(AppSpacing.xl),
                PrimaryButton(
                  label: 'Simulate Mock Payment',
                  icon: Icons.payments_rounded,
                  onPressed: () async {
                    final api = ref.read(apiServiceProvider);
                    final remote = OrderRemoteDataSource(api);
                    final success = await remote.simulateMockPayment(
                      currentOrder.id,
                    );
                    if (success) {
                      ref.invalidate(ordersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mock Payment Successful! Order is now being '
                              'prepared.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
