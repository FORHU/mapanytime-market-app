import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_confirmation_page.dart';

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

Widget _wrap(OrderConfirmationArgs args) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => OrderConfirmationPage(args: args),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows the pay-on-pickup card for a COD order, no QR', (
    tester,
  ) async {
    final args = OrderConfirmationArgs(
      orderId: 'order-1',
      paymentMethodLabel: 'Payment on pickup',
      isCashOnDelivery: true,
      pricing: CartPricing.fromJson(_pricingJson),
    );

    await tester.pumpWidget(_wrap(args));

    expect(find.text('Pay on pickup'), findsOneWidget);
    expect(find.textContaining('Pay ₱4.58 in cash'), findsOneWidget);
    expect(find.text('Vouchers & Discounts'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the GCash QR card for a GCash order, no pay-on-pickup', (
    tester,
  ) async {
    final args = OrderConfirmationArgs(
      orderId: 'order-2',
      paymentMethodLabel: 'GCash',
      isCashOnDelivery: false,
      pricing: CartPricing.fromJson(_pricingJson),
    );

    await tester.pumpWidget(_wrap(args));

    expect(find.text('Payment QR (GCash Mock)'), findsOneWidget);
    expect(find.text('Scan to pay via GCash.'), findsOneWidget);
    expect(find.text('Pay on pickup'), findsNothing);
  });
}
