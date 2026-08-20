import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/price_breakdown_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Everything the confirmation screen needs, handed off directly by the
/// checkout page — avoids a second round-trip for pricing that was already
/// fetched (and guaranteed to match what was just charged) moments earlier.
class OrderConfirmationArgs {
  const OrderConfirmationArgs({
    required this.orderId,
    required this.paymentMethodLabel,
    required this.isCashOnDelivery,
    required this.pricing,
    this.selectedMethod,
    this.checkoutUrl,
  });

  final String orderId;
  final String paymentMethodLabel;
  final bool isCashOnDelivery;
  final CartPricing pricing;
  final PaymentMethod? selectedMethod;
  final String? checkoutUrl;
}

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({required this.args, super.key});

  final OrderConfirmationArgs args;

  @override
  Widget build(BuildContext context) {
    final paidAmount =
        args.selectedMethod?.buyerTotalAmount ?? args.pricing.totalAmount;

    return Scaffold(
      appBar: const ModernAppBar(title: 'Order Confirmed'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Gap(AppSpacing.xl),
          Center(
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.status.success,
              size: 80,
            ),
          ),
          const Gap(AppSpacing.md),
          const Text(
            'Order Placed!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Order ID: ${args.orderId}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text.tertiary),
          ),
          const Gap(AppSpacing.xxl),
          if (args.isCashOnDelivery)
            GlassCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: AppColors.ink,
                    size: 40,
                  ),
                  const Gap(AppSpacing.md),
                  const Text(
                    'Pay on pickup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Pay ${Money.peso(args.pricing.totalAmount)} in cash '
                    'when you collect your order.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              child: Column(
                children: [
                  Text(
                    'Online Payment (${args.paymentMethodLabel})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Gap(AppSpacing.md),
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.status.success,
                    size: 40,
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Payment initiated for ${Money.peso(paidAmount)}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          const Gap(AppSpacing.lg),
          GlassCard(
            child: Column(
              children: [
                const Text(
                  'Seller Pickup Pass',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Gap(AppSpacing.md),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.brLg,
                    ),
                    child: QrImageView(
                      data: 'MAPANYTIME-ORDER-${args.orderId}',
                      size: 180,
                    ),
                  ),
                ),
                const Gap(AppSpacing.sm),
                Text(
                  'Present this QR code to the merchant at the stall.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.xxl),
          const SectionTitle(title: 'Order summary'),
          const Gap(AppSpacing.sm),
          PriceBreakdownCard(
            pricing: AsyncData(args.pricing),
            selectedMethod: args.selectedMethod,
          ),
          const Gap(AppSpacing.xxl),
          PrimaryButton(
            label: 'Back to Home',
            onPressed: () => context.go(RouteNames.home),
          ),
        ],
      ),
    );
  }
}
