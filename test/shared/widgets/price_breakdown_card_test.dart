import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/shared/widgets/price_breakdown_card.dart';

void main() {
  // Real response captured from POST /cart/pricing against a local dev stack
  // with a 20%-off ad linked to the cart's product.
  const liveApiResponse = {
    'items': [
      {
        'productId': 'cmsptfg3n0006nz0iwaa83yvt',
        'quantity': 2,
        'unitPrice': 2.49,
        'discountAmount': 0.9960000000000001,
        'appliedAdId': 'test-verify-ad-001',
      },
    ],
    'subtotalAmount': 4.98,
    'discountAmount': 0.9960000000000001,
    'taxAmount': 0.6,
    'totalAmount': 4.58,
  };

  testWidgets(
    'renders the Vouchers & Discounts row for a real discounted pricing '
    'payload',
    (tester) async {
      final pricing = CartPricing.fromJson(liveApiResponse);
      expect(pricing.discountAmount, greaterThan(0));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PriceBreakdownCard(pricing: AsyncData(pricing)),
            ),
          ),
        ),
      );

      expect(find.text('Vouchers & Discounts'), findsOneWidget);
      expect(find.textContaining('-'), findsWidgets);
    },
  );

  testWidgets('shows "None applied" when discountAmount is zero', (
    tester,
  ) async {
    const noDiscountResponse = {
      'items': [
        {
          'productId': 'p1',
          'quantity': 1,
          'unitPrice': 10,
          'discountAmount': 0,
          'appliedAdId': null,
        },
      ],
      'subtotalAmount': 10,
      'discountAmount': 0,
      'taxAmount': 1.2,
      'totalAmount': 11.2,
    };
    final pricing = CartPricing.fromJson(noDiscountResponse);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PriceBreakdownCard(pricing: AsyncData(pricing)),
          ),
        ),
      ),
    );

    expect(find.text('Vouchers & Discounts'), findsOneWidget);
    expect(find.text('None applied'), findsOneWidget);
  });
}
