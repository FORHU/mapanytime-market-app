import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mapanytime_market_app/features/wishlist/presentation/controllers/wishlist_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// In-memory stand-in for the API. [initialLoad] lets a test hold the first
/// GET open to reproduce a tap that lands before the list has loaded.
class _FakeApi implements WishlistRemoteDataSource {
  Completer<List<WishlistItem>>? initialLoad;
  final products = <String>{};
  final stores = <String>{};
  bool failWrites = false;

  @override
  Future<List<WishlistItem>> getWishlist() async {
    final pending = initialLoad;
    if (pending != null) return pending.future;
    return [
      for (final id in products)
        WishlistItem(id: 'w-$id', product: _product(id)),
    ];
  }

  @override
  Future<void> add(String productId) async {
    if (failWrites) throw Exception('403');
    products.add(productId);
  }

  @override
  Future<void> remove(String productId) async {
    if (failWrites) throw Exception('403');
    products.remove(productId);
  }

  @override
  Future<List<StoreEntity>> getSavedStores() async => [
    for (final id in stores) _store(id),
  ];

  @override
  Future<void> addStore(String storeId) async {
    if (failWrites) throw Exception('403');
    stores.add(storeId);
  }

  @override
  Future<void> removeStore(String storeId) async {
    if (failWrites) throw Exception('403');
    stores.remove(storeId);
  }
}

StoreProduct _product(String id) => StoreProduct(
  id: id,
  name: 'Product $id',
  imageUrl: '',
  price: 100,
  description: '',
  category: 'Other',
);

StoreEntity _store(String id) =>
    StoreEntity(id: id, name: 'Store $id', lat: 0, lng: 0, distance: 0);

void main() {
  late _FakeApi api;
  late ProviderContainer container;

  ProviderContainer make({String? userId = 'user-1'}) => ProviderContainer(
    overrides: [
      wishlistRemoteDataSourceProvider.overrideWithValue(api),
      signedInUserIdProvider.overrideWithValue(userId),
    ],
  );

  setUp(() => api = _FakeApi());
  tearDown(() => container.dispose());

  group('WishlistController (Home hearts)', () {
    test(
      'a save made before the first load keeps the rest of the list',
      () async {
        // p0 is already saved on the server; the tap on p1 lands while the
        // first GET is still in flight, as on a slow connection.
        api.initialLoad = Completer();
        container = make();
        final sub = container.listen(savedProductIdsProvider, (_, _) {});

        final saving = container
            .read(wishlistControllerProvider.notifier)
            .add(_product('p1'));
        api.initialLoad!.complete([
          WishlistItem(id: 'w-p0', product: _product('p0')),
        ]);
        api.initialLoad = null;

        expect(await saving, isTrue);
        expect(sub.read(), {'p0', 'p1'});
      },
    );

    test('a failed save rolls back and reports false', () async {
      api.failWrites = true;
      container = make();
      await container.read(wishlistControllerProvider.future);

      final ok = await container
          .read(wishlistControllerProvider.notifier)
          .add(_product('p1'));

      expect(ok, isFalse);
      expect(container.read(savedProductIdsProvider), isEmpty);
    });

    test('signed out means nothing saved, without calling the API', () async {
      api.products.add('p1');
      container = make(userId: null);

      expect(await container.read(wishlistControllerProvider.future), isEmpty);
    });
  });

  group('SavedStoresController (For You hearts)', () {
    test('toggle saves, then unsaves, on the server', () async {
      container = make();
      final notifier = container.read(savedStoresControllerProvider.notifier);
      await container.read(savedStoresControllerProvider.future);

      expect(await notifier.toggle(_store('s1')), isTrue);
      expect(container.read(savedStoreIdsProvider), {'s1'});
      expect(api.stores, {'s1'});

      expect(await notifier.toggle(_store('s1')), isTrue);
      expect(container.read(savedStoreIdsProvider), isEmpty);
      expect(api.stores, isEmpty);
    });

    test('saved stores come back from the server on reload', () async {
      api.stores.add('s1');
      container = make();

      final stores = await container.read(savedStoresControllerProvider.future);

      expect(stores.map((s) => s.id), ['s1']);
    });

    test('a failed unsave puts the store back and reports false', () async {
      api.stores.add('s1');
      container = make();
      await container.read(savedStoresControllerProvider.future);
      api.failWrites = true;

      final ok = await container
          .read(savedStoresControllerProvider.notifier)
          .remove('s1');

      expect(ok, isFalse);
      expect(container.read(savedStoreIdsProvider), {'s1'});
    });
  });
}
