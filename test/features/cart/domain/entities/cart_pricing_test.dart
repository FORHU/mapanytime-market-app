import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';

void main() {
  group('CartItemPricing.fromJson', () {
    test('parses a nonzero freeUnits count', () {
      final item = CartItemPricing.fromJson(const {
        'productId': 'p1',
        'unitPrice': 2.49,
        'discountAmount': 2.49,
        'appliedAdId': 'ad-1',
        'freeUnits': 1,
      });

      expect(item.freeUnits, 1);
    });

    test('defaults freeUnits to 0 when absent, for older cached responses', () {
      final item = CartItemPricing.fromJson(const {
        'productId': 'p1',
        'unitPrice': 2.49,
        'discountAmount': 0,
        'appliedAdId': null,
      });

      expect(item.freeUnits, 0);
    });
  });
}
