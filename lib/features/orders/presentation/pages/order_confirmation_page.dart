import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderConfirmationPage extends ConsumerStatefulWidget {
  const OrderConfirmationPage({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage> {
  // Temporary hardcoded payment method state (Ideally fetched from backend)
  // For demonstration, we'll just show the GCash QR mock if it's not cash,
  // but since we only have orderId we should normally fetch order details.
  // We'll show a combined success screen for now.

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Order ID: ${widget.orderId}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text.tertiaryDark,
            ),
          ),
          const Gap(AppSpacing.xxl),
          GlassCard(
            child: Column(
              children: [
                const Text(
                  'Payment QR (GCash Mock)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const Gap(AppSpacing.lg),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.brLg,
                    ),
                    child: QrImageView(
                      data: 'gcash-mock-payment-for-${widget.orderId}',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const Gap(AppSpacing.lg),
                const Text(
                  'Scan to pay via GCash.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
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
