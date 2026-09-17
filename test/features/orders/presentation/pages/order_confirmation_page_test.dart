import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_confirmation_page.dart';
import 'package:mapanytime_market_app/features/payments/domain/entities/order_payment_status.dart';
import 'package:mapanytime_market_app/features/payments/presentation/controllers/payment_controller.dart';

const Map<String, Object?> _pricingJson = {
  'items': [
    {
      'productId': 'p1',
      'quantity': 2,
      'unitPrice': 2.49,
      'discountAmount': 0.996,
      'appliedAdId': 'ad-1',
    },
  ],
  'subtotalAmount': 4.98,
  'discountAmount': 0.996,
  'taxAmount': 0.6,
  'totalAmount': 4.58,
};

OrderPaymentStatus _status(
  String orderId, {
  required PaymentStatusValue payment,
  String order = 'PENDING',
}) {
  return OrderPaymentStatus(
    orderId: orderId,
    paymentStatus: payment,
    orderStatus: order,
  );
}

Widget _router(OrderConfirmationArgs args) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => OrderConfirmationPage(args: args),
        ),
      ],
    ),
  );
}

/// An online order whose payment status is pinned to [payment].
Widget _online(
  String orderId, {
  required PaymentStatusValue payment,
  String order = 'PENDING',
  String? checkoutUrl,
}) {
  final args = OrderConfirmationArgs(
    orderId: orderId,
    paymentMethodLabel: 'GCash',
    isCashOnDelivery: false,
    pricing: CartPricing.fromJson(_pricingJson),
    checkoutUrl: checkoutUrl,
  );

  return ProviderScope(
    overrides: [
      paymentStatusPollProvider(orderId).overrideWith(
        (ref) => Stream.value(_status(orderId, payment: payment, order: order)),
      ),
    ],
    child: _router(args),
  );
}

void main() {
  testWidgets('shows the pay-on-pickup card for a COD order', (tester) async {
    final args = OrderConfirmationArgs(
      orderId: 'order-1',
      paymentMethodLabel: 'Payment on pickup',
      isCashOnDelivery: true,
      pricing: CartPricing.fromJson(_pricingJson),
    );

    await tester.pumpWidget(ProviderScope(child: _router(args)));

    expect(find.text('Pay on pickup'), findsOneWidget);
    expect(find.textContaining('Pay ₱4.58 in cash'), findsOneWidget);
    expect(find.text('Seller Pickup Pass'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vouchers & Discounts'), 300);
    expect(find.text('Vouchers & Discounts'), findsOneWidget);
  });

  /// Cash never reaches a gateway, so it must not be made to wait on a payment
  /// status that will never arrive.
  testWidgets('a COD order never consults the payment status', (tester) async {
    var built = false;
    final args = OrderConfirmationArgs(
      orderId: 'order-1',
      paymentMethodLabel: 'Payment on pickup',
      isCashOnDelivery: true,
      pricing: CartPricing.fromJson(_pricingJson),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentStatusPollProvider('order-1').overrideWith((ref) {
            built = true;
            return const Stream<OrderPaymentStatus>.empty();
          }),
        ],
        child: _router(args),
      ),
    );

    expect(built, isFalse);
    expect(find.text('Seller Pickup Pass'), findsOneWidget);
  });

  testWidgets('shows the online payment card, not the pay-on-pickup one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online('order-2', payment: PaymentStatusValue.completed),
    );
    await tester.pump();

    expect(find.text('Online Payment (GCash)'), findsOneWidget);
    expect(find.text('Pay on pickup'), findsNothing);
  });

  testWidgets('releases the pickup pass once the payment is confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online(
        'order-3',
        payment: PaymentStatusValue.completed,
        order: 'PROCESSING',
      ),
    );
    await tester.pump();

    expect(find.text('Order Placed!'), findsOneWidget);
    expect(find.text('Seller Pickup Pass'), findsOneWidget);
    expect(find.textContaining('confirmed'), findsWidgets);
  });

  /// The whole point of the rework: an unconfirmed payment must not hand the
  /// buyer something that looks like proof of purchase.
  testWidgets('withholds the pickup pass while payment is unconfirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online('order-4', payment: PaymentStatusValue.pending),
    );
    await tester.pump();

    expect(find.text('Confirming payment'), findsOneWidget);
    expect(find.text('Seller Pickup Pass'), findsNothing);
    expect(find.text('Order Placed!'), findsNothing);
  });

  testWidgets('withholds the pickup pass when the payment failed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online('order-5', payment: PaymentStatusValue.failed, order: 'FAILED'),
    );
    await tester.pump();

    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Seller Pickup Pass'), findsNothing);
  });

  /// No failure webhook is emitted for an abandoned session, so the order being
  /// moved to FAILED is the only signal that ever arrives.
  testWidgets('treats a failed order as failure while the payment is PENDING', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online('order-6', payment: PaymentStatusValue.pending, order: 'FAILED'),
    );
    await tester.pump();

    expect(find.text('Payment failed'), findsOneWidget);
    expect(find.text('Seller Pickup Pass'), findsNothing);
  });

  testWidgets('offers a way back to the gateway while unconfirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online(
        'order-7',
        payment: PaymentStatusValue.pending,
        checkoutUrl: 'https://checkout.test/pay/abc',
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Resume payment'), 300);

    expect(find.text('Resume payment'), findsOneWidget);
    expect(find.text("I've paid — check now"), findsOneWidget);
  });

  testWidgets('offers no resume button once the payment is confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _online(
        'order-8',
        payment: PaymentStatusValue.completed,
        checkoutUrl: 'https://checkout.test/pay/abc',
      ),
    );
    await tester.pump();
    // Scroll the action area into view first, so this asserts the button is
    // absent rather than merely unbuilt below the fold.
    await tester.scrollUntilVisible(find.text('Back to Home'), 300);

    expect(find.text('Back to Home'), findsOneWidget);
    expect(find.text('Resume payment'), findsNothing);
    expect(find.text('Try payment again'), findsNothing);
  });
}
