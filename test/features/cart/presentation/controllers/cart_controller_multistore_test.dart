import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/cart/data/cart_remote_datasource.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mocktail/mocktail.dart';

class MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

/// The cart may hold several stores; an order may not. These cover the client
/// side of that split — the grouping the cart page renders, and the gate that
/// stops a buyer reaching payment with a selection `POST /orders` will reject.
StoreProduct _product(String id) => StoreProduct(
  id: id,
  name: id,
  imageUrl: '',
  price: 10,
  description: '',
  category: 'Drinks',
);

void main() {
  late MockCartRemoteDataSource mockRemote;
  late ProviderContainer container;

  setUp(() {
    mockRemote = MockCartRemoteDataSource();
    when(
      () => mockRemote.addToCart(
        storeId: any(named: 'storeId'),
        productId: any(named: 'productId'),
        quantity: any(named: 'quantity'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockRemote.getPricing(productIds: any(named: 'productIds')),
    ).thenAnswer(
      (_) async => const CartPricing(
        items: [],
        subtotalAmount: 0,
        discountAmount: 0,
        totalAmount: 0,
      ),
    );
    container = ProviderContainer(
      overrides: [cartRemoteDataSourceProvider.overrideWithValue(mockRemote)],
    );
    addTearDown(container.dispose);
  });

  void addFrom(String storeId, String productId) {
    container
        .read(cartProvider.notifier)
        .add(
          product: _product(productId),
          storeId: storeId,
          storeName: storeId,
        );
  }

  test('holds items from more than one store at a time', () {
    addFrom('store-1', 'p1');
    addFrom('store-2', 'p2');

    expect(container.read(cartProvider), hasLength(2));
    expect(
      container.read(cartGroupsProvider).map((group) => group.storeId),
      ['store-1', 'store-2'],
    );
  });

  test('counts the stores the selection spans', () {
    addFrom('store-1', 'p1');
    addFrom('store-2', 'p2');

    // Everything is selected by default, so the selection spans both stores.
    expect(container.read(cartSelectedStoreCountProvider), 2);

    container
        .read(cartDeselectedProvider.notifier)
        .setSelected(
          'p2',
          selected: false,
        );

    expect(container.read(cartSelectedStoreCountProvider), 1);
  });

  test('reports one store for a single-store cart', () {
    addFrom('store-1', 'p1');
    addFrom('store-1', 'p2');

    expect(container.read(cartSelectedStoreCountProvider), 1);
    expect(container.read(cartGroupsProvider), hasLength(1));
  });

  test('reports no stores once everything is deselected', () {
    addFrom('store-1', 'p1');
    container
        .read(cartDeselectedProvider.notifier)
        .setSelected(
          'p1',
          selected: false,
        );

    expect(container.read(cartSelectedStoreCountProvider), 0);
  });
}
