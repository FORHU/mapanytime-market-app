import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider, authControllerProvider;
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

final wishlistRemoteDataSourceProvider = Provider<WishlistRemoteDataSource>(
  (ref) => WishlistRemoteDataSource(ref.watch(apiServiceProvider)),
);

/// The signed-in user's id, or null when signed out. Saved lists rebuild
/// when it changes, so a new login never sees the previous account's items.
final signedInUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)),
);

/// The current list to mutate from. Waits for the first load: setting state
/// while it is in flight makes Riverpod discard that load, so a heart tapped
/// early would leave the list holding only the new item. Falls back to what
/// is on screen if the load failed.
Future<List<T>> _settled<T>(
  Future<List<T>> future,
  AsyncValue<List<T>> state,
) async {
  try {
    return await future;
  } on Object {
    return state.value ?? <T>[];
  }
}

/// The signed-in buyer's saved products. Add/remove are optimistic — the
/// heart flips immediately and flips back only if the server call fails.
/// Both return whether the change stuck, so callers can say so when it
/// didn't instead of the heart silently reverting.
class WishlistController extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() async {
    if (ref.watch(signedInUserIdProvider) == null) return const [];
    return ref.read(wishlistRemoteDataSourceProvider).getWishlist();
  }

  /// Save a product. The caller already has the full [StoreProduct] on
  /// screen (that's how they got a heart to tap), so this skips a re-fetch.
  /// The item keeps a placeholder id (`POST /wishlist/items` only returns
  /// the raw `WishlistItems` row) — nothing reads [WishlistItem.id] yet.
  Future<bool> add(StoreProduct product) async {
    final current = await _settled(future, state);
    if (current.any((item) => item.product.id == product.id)) return true;

    state = AsyncData([
      WishlistItem(id: 'pending-${product.id}', product: product),
      ...current,
    ]);
    try {
      await ref.read(wishlistRemoteDataSourceProvider).add(product.id);
      return true;
    } on Exception {
      // Didn't stick server-side — pull the optimistic entry back out,
      // from whatever the *current* state is (see [remove] for why).
      final latest = state.value ?? const <WishlistItem>[];
      state = AsyncData(
        latest.where((item) => item.product.id != product.id).toList(),
      );
      return false;
    }
  }

  Future<bool> remove(String productId) async {
    final current = await _settled(future, state);
    final removedMatches = current.where(
      (item) => item.product.id == productId,
    );
    if (removedMatches.isEmpty) return true;
    final removedItem = removedMatches.first;

    state = AsyncData(
      current.where((item) => item.product.id != productId).toList(),
    );
    try {
      await ref.read(wishlistRemoteDataSourceProvider).remove(productId);
      return true;
    } on Exception {
      // Put just this item back, into whatever the *current* state is —
      // not the stale pre-removal snapshot. A concurrent remove of a
      // different item may have already changed state while this one was
      // in flight; restoring the old snapshot would silently resurrect it.
      final latest = state.value ?? const <WishlistItem>[];
      final alreadyBack = latest.any((item) => item.product.id == productId);
      if (!alreadyBack) {
        state = AsyncData([...latest, removedItem]);
      }
      return false;
    }
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, List<WishlistItem>>(
      WishlistController.new,
    );

/// Just the count, for the profile page's stats row — reads the same cached
/// state as the full list rather than issuing a second request.
final wishlistCountProvider = Provider<int?>((ref) {
  return ref.watch(wishlistControllerProvider).value?.length;
});

/// Saved product ids, for the heart icon on any `ProductCard`/detail page —
/// same cached state as the full list, no extra request. Empty (not null)
/// while loading, so a heart never renders "filled" speculatively.
final savedProductIdsProvider = Provider<Set<String>>((ref) {
  final items = ref.watch(wishlistControllerProvider).value ?? const [];
  return items.map((item) => item.product.id).toSet();
});

/// The signed-in buyer's saved stores (Profile → Saved → Stores), backed by
/// `/wishlist/stores`. Same optimistic rules as [WishlistController].
class SavedStoresController extends AsyncNotifier<List<StoreEntity>> {
  @override
  Future<List<StoreEntity>> build() async {
    if (ref.watch(signedInUserIdProvider) == null) return const [];
    return ref.read(wishlistRemoteDataSourceProvider).getSavedStores();
  }

  /// Save [store] if it isn't saved, unsave it if it is.
  Future<bool> toggle(StoreEntity store) async {
    final current = await _settled(future, state);
    return current.any((s) => s.id == store.id) ? remove(store.id) : add(store);
  }

  Future<bool> add(StoreEntity store) async {
    final current = await _settled(future, state);
    if (current.any((s) => s.id == store.id)) return true;

    state = AsyncData([store, ...current]);
    try {
      await ref.read(wishlistRemoteDataSourceProvider).addStore(store.id);
      return true;
    } on Exception {
      final latest = state.value ?? const <StoreEntity>[];
      state = AsyncData(latest.where((s) => s.id != store.id).toList());
      return false;
    }
  }

  Future<bool> remove(String storeId) async {
    final current = await _settled(future, state);
    final index = current.indexWhere((s) => s.id == storeId);
    if (index == -1) return true;
    final removed = current[index];

    state = AsyncData(current.where((s) => s.id != storeId).toList());
    try {
      await ref.read(wishlistRemoteDataSourceProvider).removeStore(storeId);
      return true;
    } on Exception {
      // Same "restore into the latest state" rule as WishlistController.
      final latest = state.value ?? const <StoreEntity>[];
      if (!latest.any((s) => s.id == storeId)) {
        state = AsyncData([...latest, removed]);
      }
      return false;
    }
  }
}

final savedStoresControllerProvider =
    AsyncNotifierProvider<SavedStoresController, List<StoreEntity>>(
      SavedStoresController.new,
    );

/// Saved store ids, for the heart on store cards. Empty while loading, like
/// [savedProductIdsProvider].
final savedStoreIdsProvider = Provider<Set<String>>((ref) {
  final stores = ref.watch(savedStoresControllerProvider).value ?? const [];
  return stores.map((s) => s.id).toSet();
});
