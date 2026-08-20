import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/cart/data/cart_remote_datasource.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mocktail/mocktail.dart';

class MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

const _product = StoreProduct(
  id: 'p1',
  name: 'Coke',
  imageUrl: '',
  price: 10,
  description: '',
  category: 'Drinks',
);

CartPricing _pricingFor(int quantity) => CartPricing(
  items: const [
    CartItemPricing(productId: 'p1', unitPrice: 10, discountAmount: 0),
  ],
  subtotalAmount: 10 * quantity,
  discountAmount: 0,
  totalAmount: 10 * quantity,
);

void main() {
  late MockCartRemoteDataSource mockRemote;
  late ProviderContainer container;

  setUp(() {
    mockRemote = MockCartRemoteDataSource();
    when(
      () => mockRemote.getPricing(productIds: any(named: 'productIds')),
    ).thenAnswer((_) async => _pricingFor(1));
    container = ProviderContainer(
      overrides: [cartRemoteDataSourceProvider.overrideWithValue(mockRemote)],
    );
    addTearDown(container.dispose);
  });

  test(
    'waitForPendingSync only resolves once every queued write has '
    'completed, not just the first',
    () async {
      final firstWrite = Completer<void>();
      final secondWrite = Completer<void>();
      var callCount = 0;
      when(
        () => mockRemote.addToCart(
          storeId: any(named: 'storeId'),
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? firstWrite.future : secondWrite.future;
      });

      final notifier = container.read(cartProvider.notifier)
        ..add(product: _product, storeId: 's1', storeName: 'Store')
        ..setQuantity('p1', 2);

      var settled = false;
      unawaited(notifier.waitForPendingSync().then((_) => settled = true));

      firstWrite.complete();
      await Future<void>.delayed(Duration.zero);
      // A buggy implementation that only tracked the latest-enqueued write
      // (or didn't chain at all) could settle here, before the second write
      // — that's exactly the kind of gap that let pricing be read too early.
      expect(settled, isFalse);

      secondWrite.complete();
      await Future<void>.delayed(Duration.zero);
      expect(settled, isTrue);
    },
  );

  test(
    'cartPricingProvider only reads pricing back after the pending write '
    'completes',
    () async {
      final addCompleter = Completer<void>();
      when(
        () => mockRemote.addToCart(
          storeId: any(named: 'storeId'),
          productId: any(named: 'productId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) => addCompleter.future);

      container
          .read(cartProvider.notifier)
          .add(product: _product, storeId: 's1', storeName: 'Store');

      final pricingFuture = container.read(cartPricingProvider.future);

      // Pump a microtask turn: if the pricing fetch fired before the write
      // completed, getPricing would already have been called by now.
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => mockRemote.getPricing(productIds: any(named: 'productIds')),
      );

      addCompleter.complete();
      await pricingFuture;

      verify(
        () => mockRemote.getPricing(productIds: any(named: 'productIds')),
      ).called(1);
    },
  );
}
