import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/currency.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:mapanytime_market_app/features/orders/presentation/controllers/orders_controller.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/order_payment_status.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/payment_method.dart';
import 'package:mapanytime_market_app/features/payments/presentation/controllers/payment_controller.dart';
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
import 'package:url_launcher/url_launcher.dart';

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

/// Where the buyer lands after placing an order.
///
/// For an online payment this screen does not know the outcome when it opens.
/// Checkout launches the gateway in a browser and returns immediately — the
/// buyer might pay, or close the tab — and the payment is settled by a webhook
/// that lands on the server, not here. So the screen asks the backend until it
/// gets a real answer, and until then it withholds the pickup pass: a QR code
/// for an order that was never paid is worse than no QR code at all.
class OrderConfirmationPage extends ConsumerStatefulWidget {
  const OrderConfirmationPage({required this.args, super.key});

  final OrderConfirmationArgs args;

  @override
  ConsumerState<OrderConfirmationPage> createState() =>
      _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends ConsumerState<OrderConfirmationPage> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // The buyer spends the decisive moments of this flow in another app. iOS in
    // particular suspends timers behind the browser overlay, so coming back is
    // the cue to re-read rather than wait out whatever gap was pending.
    if (!widget.args.isCashOnDelivery) {
      _lifecycle = AppLifecycleListener(onResume: _recheck);
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  void _recheck() {
    if (!mounted) return;
    ref.invalidate(paymentStatusPollProvider(widget.args.orderId));
  }

  Future<void> _openCheckout() async {
    final url = widget.args.checkoutUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } on Object catch (_) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    // Cash is settled at the stall: no gateway, no checkout session, no webhook
    // and so nothing to wait for. Returning before anything is watched is what
    // keeps this path from polling an endpoint that has nothing to say.
    if (args.isCashOnDelivery) {
      return _buildPage(outcome: PaymentOutcome.paid, isCash: true);
    }

    ref
      ..listen(paymentStatusPollProvider(args.orderId), (_, next) {
        if (next.value?.outcome == PaymentOutcome.paid) {
          ref.invalidate(ordersProvider);
        }
      })
      // The push beats the next scheduled poll, so it is used to jump the
      // queue rather than to decide anything — the status read settles it.
      ..listen(incomingNotificationProvider, (_, next) {
        final metadata = next.value?.metadata;
        if (metadata == null) return;
        if (metadata['type'] == 'PAYMENT_COMPLETED' &&
            metadata['orderId'] == args.orderId) {
          _recheck();
        }
      });

    final status = ref.watch(paymentStatusPollProvider(args.orderId));

    return _buildPage(
      outcome: status.value?.outcome ?? PaymentOutcome.waiting,
      isCash: false,
      hasError: status.hasError && !status.hasValue,
    );
  }

  Widget _buildPage({
    required PaymentOutcome outcome,
    required bool isCash,
    bool hasError = false,
  }) {
    final args = widget.args;
    final paidAmount =
        args.selectedMethod?.buyerTotalAmount ?? args.pricing.totalAmount;
    final isConfirmed = outcome == PaymentOutcome.paid;

    return Scaffold(
      appBar: ModernAppBar(
        title: isConfirmed ? 'Order Confirmed' : 'Payment Status',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Gap(AppSpacing.xl),
          _Header(outcome: outcome, orderId: args.orderId),
          const Gap(AppSpacing.xxl),
          if (isCash)
            _cashCard()
          else
            _onlineCard(outcome: outcome, paidAmount: paidAmount),
          if (hasError) ...[
            const Gap(AppSpacing.md),
            Text(
              "We couldn't reach the server to check this payment. "
              'Trying again shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.text.tertiary),
            ),
          ],
          // The pickup pass is proof of a paid order, so it appears only once
          // the payment is actually confirmed.
          if (isConfirmed) ...[const Gap(AppSpacing.lg), _pickupPassCard()],
          const Gap(AppSpacing.xxl),
          const SectionTitle(title: 'Order summary'),
          const Gap(AppSpacing.sm),
          PriceBreakdownCard(
            pricing: AsyncData(args.pricing),
            selectedMethod: args.selectedMethod,
          ),
          const Gap(AppSpacing.xxl),
          ..._actions(outcome: outcome, isCash: isCash),
        ],
      ),
    );
  }

  List<Widget> _actions({
    required PaymentOutcome outcome,
    required bool isCash,
  }) {
    final canRetry =
        !isCash &&
        outcome != PaymentOutcome.paid &&
        (widget.args.checkoutUrl?.isNotEmpty ?? false);

    return [
      if (canRetry) ...[
        PrimaryButton(
          label: outcome == PaymentOutcome.waiting
              ? 'Resume payment'
              : 'Try payment again',
          onPressed: _openCheckout,
        ),
        const Gap(AppSpacing.sm),
      ],
      if (!isCash && outcome == PaymentOutcome.waiting)
        TextButton(
          onPressed: _recheck,
          child: const Text("I've paid — check now"),
        ),
      if (outcome == PaymentOutcome.paid || isCash)
        PrimaryButton(
          label: 'Back to Home',
          onPressed: () => context.go(RouteNames.home),
        )
      else
        TextButton(
          onPressed: () => context.go(RouteNames.home),
          child: const Text('Back to Home'),
        ),
    ];
  }

  Widget _cashCard() {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.payments_rounded, color: AppColors.ink, size: 40),
          const Gap(AppSpacing.md),
          const Text(
            'Pay on pickup',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Pay ${Money.peso(widget.args.pricing.totalAmount)} in cash '
            'when you collect your order.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _onlineCard({
    required PaymentOutcome outcome,
    required num paidAmount,
  }) {
    final detail = switch (outcome) {
      PaymentOutcome.paid => 'Payment of ${Money.peso(paidAmount)} confirmed.',
      PaymentOutcome.waiting =>
        'Waiting for ${Money.peso(paidAmount)} to be confirmed by your '
            'e-wallet. This updates by itself.',
      PaymentOutcome.failed =>
        'This payment did not go through. Nothing was charged.',
      PaymentOutcome.cancelled =>
        'The payment was cancelled. Nothing was charged.',
    };

    final icon = switch (outcome) {
      PaymentOutcome.paid => Icons.check_circle_outline_rounded,
      PaymentOutcome.waiting => Icons.hourglass_top_rounded,
      PaymentOutcome.failed => Icons.error_outline_rounded,
      PaymentOutcome.cancelled => Icons.cancel_outlined,
    };

    return GlassCard(
      child: Column(
        children: [
          Text(
            'Online Payment (${widget.args.paymentMethodLabel})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Gap(AppSpacing.md),
          if (outcome == PaymentOutcome.waiting)
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            Icon(icon, color: _toneOf(outcome), size: 40),
          const Gap(AppSpacing.sm),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _pickupPassCard() {
    return GlassCard(
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
                data: 'MAPANYTIME-ORDER-${widget.args.orderId}',
                size: 180,
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Present this QR code to the merchant at the stall.',
            style: TextStyle(fontSize: 12, color: AppColors.text.secondary),
          ),
        ],
      ),
    );
  }
}

Color _toneOf(PaymentOutcome outcome) => switch (outcome) {
  PaymentOutcome.paid => AppColors.status.success,
  PaymentOutcome.waiting => AppColors.status.warning,
  PaymentOutcome.failed => AppColors.status.error,
  PaymentOutcome.cancelled => AppColors.status.error,
};

class _Header extends StatelessWidget {
  const _Header({required this.outcome, required this.orderId});

  final PaymentOutcome outcome;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = switch (outcome) {
      PaymentOutcome.paid => (Icons.check_circle_rounded, 'Order Placed!'),
      PaymentOutcome.waiting => (
        Icons.hourglass_top_rounded,
        'Confirming payment',
      ),
      PaymentOutcome.failed => (Icons.error_rounded, 'Payment failed'),
      PaymentOutcome.cancelled => (Icons.cancel_rounded, 'Payment cancelled'),
    };

    return Column(
      children: [
        Center(child: Icon(icon, color: _toneOf(outcome), size: 80)),
        const Gap(AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const Gap(AppSpacing.sm),
        Text(
          'Order ID: $orderId',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.text.tertiary),
        ),
      ],
    );
  }
}
