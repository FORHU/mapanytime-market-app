import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/wishlist/data/datasources/wishlist_remote_datasource.dart';
import 'package:mapanytime_market_app/features/wishlist/domain/entities/wishlist_item.dart';

final wishlistRemoteDataSourceProvider = Provider<WishlistRemoteDataSource>(
  (ref) => WishlistRemoteDataSource(ref.watch(apiServiceProvider)),
);

/// The signed-in buyer's saved products. Remove is optimistic — the item
/// disappears immediately and only comes back if the server call fails.
class WishlistController extends AsyncNotifier<List<WishlistItem>> {
  @override
  Future<List<WishlistItem>> build() =>
      ref.read(wishlistRemoteDataSourceProvider).getWishlist();

  /// Save a product. Optimistic, like [remove] — the caller already has the
  /// full [StoreProduct] on screen (that's how they got a heart to tap), so
  /// this skips a round trip rather than re-fetching it. The item keeps a
  /// placeholder id (`POST /wishlist/items` only returns the raw
  /// `WishlistItems` row, not the joined product) — nothing in the app reads
  /// [WishlistItem.id] for anything yet, so this is harmless.
  Future<void> add(StoreProduct product) async {
    final current = state.value ?? const <WishlistItem>[];
    if (current.any((item) => item.product.id == product.id)) return;

    state = AsyncData([
      WishlistItem(id: 'pending-${product.id}', product: product),
      ...current,
    ]);
    try {
      await ref.read(wishlistRemoteDataSourceProvider).add(product.id);
    } on Exception {
      // Didn't stick server-side — pull the optimistic entry back out,
      // from whatever the *current* state is (see [remove] for why).
      final latest = state.value ?? const <WishlistItem>[];
      state = AsyncData(
        latest.where((item) => item.product.id != product.id).toList(),
      );
    }
  }

  Future<void> remove(String productId) async {
    final current = state.value ?? const <WishlistItem>[];
    final removedMatches = current.where(
      (item) => item.product.id == productId,
    );
    if (removedMatches.isEmpty) return;
    final removedItem = removedMatches.first;

    state = AsyncData(
      current.where((item) => item.product.id != productId).toList(),
    );
    try {
      await ref.read(wishlistRemoteDataSourceProvider).remove(productId);
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
