import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/pages/saved_page.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// Serves a fixed saved-products list, the way `GET /wishlist` does.
class _FakeApi implements WishlistRemoteDataSource {
  _FakeApi(this.products);

  final List<StoreProduct> products;
  final removed = <String>[];

  @override
  Future<List<WishlistItem>> getWishlist() async => [
    for (final p in products) WishlistItem(id: 'w-${p.id}', product: p),
  ];

  @override
  Future<void> remove(String productId) async => removed.add(productId);

  @override
  Future<void> add(String productId) async {}

  @override
  Future<List<StoreEntity>> getSavedStores() async => const [];

  @override
  Future<void> addStore(String storeId) async {}

  @override
  Future<void> removeStore(String storeId) async {}
}

StoreProduct _product(String id, String name) => StoreProduct(
  id: id,
  name: name,
  // No image, like every product in the dev data — the error-box path.
  imageUrl: '',
  price: 66,
  description: '',
  category: 'Other',
  storeName: 'Tomay Trading Co',
);

void main() {
  testWidgets('Saved → Products draws every saved product', (t) async {
    final api = _FakeApi([
      _product('p1', 'Cable Ties (Pack of 12)'),
      _product('p2', 'Safety Helmet (Heavy Duty)'),
    ]);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          wishlistRemoteDataSourceProvider.overrideWithValue(api),
          signedInUserIdProvider.overrideWithValue('user-1'),
        ],
        child: const MaterialApp(home: SavedPage()),
      ),
    );
    // Not pumpAndSettle: an image's loading spinner animates indefinitely.
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(t.takeException(), isNull);
    expect(find.text('Cable Ties (Pack of 12)'), findsOneWidget);
    expect(find.text('Safety Helmet (Heavy Duty)'), findsOneWidget);

    // Unsaving from Saved removes it on the server and from the grid.
    await t.tap(find.byIcon(Icons.favorite_rounded).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(api.removed, ['p1']);
    expect(find.text('Cable Ties (Pack of 12)'), findsNothing);
    expect(find.text('Safety Helmet (Heavy Duty)'), findsOneWidget);
  });
}
