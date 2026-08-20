import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/cart/data/cart_remote_datasource.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_pricing.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSource(ref.watch(apiServiceProvider));
});

/// In-memory cart state synced to the remote API.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  // Every server write is chained onto this instead of fired independently,
  // so (a) rapid successive writes reach the server in the order the buyer
  // made them, and (b) there's a single future callers can await to know
  // every write dispatched so far has actually landed — see
  // waitForPendingSync, used by cartPricingProvider to avoid reading pricing
  // back before the write it depends on has been applied server-side.
  Future<void> _syncQueue = Future.value();

  void _enqueueSync(Future<void> Function() write) {
    _syncQueue = _syncQueue.then((_) => write()).catchError((_) {});
  }

  /// Resolves once every cart write dispatched so far has completed
  /// (successfully or not — failures are still swallowed, see [_enqueueSync]).
  Future<void> waitForPendingSync() => _syncQueue;

  void add({
    required StoreProduct product,
    required String storeId,
    required String storeName,
  }) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(product: product, storeId: storeId, storeName: storeName),
      ];
    }
    final quantity = state
        .firstWhere((i) => i.product.id == product.id)
        .quantity;
    _enqueueSync(
      () => ref
          .read(cartRemoteDataSourceProvider)
          .addToCart(
            storeId: storeId,
            productId: product.id,
            quantity: quantity,
          ),
    );

    // A newly added item is "unseen" until the buyer opens the cart.
    ref.read(cartSeenProvider.notifier).markUnseen();
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];

    final storeId = state.firstWhere((i) => i.product.id == productId).storeId;
    _enqueueSync(
      () => ref
          .read(cartRemoteDataSourceProvider)
          .addToCart(
            storeId: storeId,
            productId: productId,
            quantity: quantity,
          ),
    );
  }

  void remove(String productId) {
    CartItem? item;
    for (final i in state) {
      if (i.product.id == productId) {
        item = i;
        break;
      }
    }
    state = [
      for (final item in state)
        if (item.product.id != productId) item,
    ];
    if (item != null) {
      final removed = item;
      _enqueueSync(
        () => ref
            .read(cartRemoteDataSourceProvider)
            .addToCart(
              storeId: removed.storeId,
              productId: productId,
              quantity: 0,
            ),
      );
    }
  }

  void removeMany(Iterable<String> productIds) {
    final ids = productIds.toSet();
    final itemsToRemove = <CartItem>[];
    for (final i in state) {
      if (ids.contains(i.product.id)) {
        itemsToRemove.add(i);
      }
    }
    state = [
      for (final item in state)
        if (!ids.contains(item.product.id)) item,
    ];
    for (final item in itemsToRemove) {
      _enqueueSync(
        () => ref
            .read(cartRemoteDataSourceProvider)
            .addToCart(
              storeId: item.storeId,
              productId: item.product.id,
              quantity: 0,
            ),
      );
    }
  }

  void clear() {
    state = const [];
    _enqueueSync(() => ref.read(cartRemoteDataSourceProvider).clearCart());
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Cart lines grouped by store, for the grouped cart view.
final cartGroupsProvider = Provider<List<CartStoreGroup>>((ref) {
  final items = ref.watch(cartProvider);
  final byStore = <String, List<CartItem>>{};
  for (final item in items) {
    byStore.putIfAbsent(item.storeId, () => []).add(item);
  }
  return [
    for (final entry in byStore.entries)
      CartStoreGroup(
        storeId: entry.key,
        storeName: entry.value.first.storeName,
        items: entry.value,
      ),
  ];
});

/// Total item count across the cart.
final cartCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartProvider)
      .fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Cart subtotal across all stores.
final cartSubtotalProvider = Provider<num>((ref) {
  return ref
      .watch(cartProvider)
      .fold<num>(0, (sum, item) => sum + item.lineTotal);
});

/// Whether the buyer has seen the cart since the last item was added.
/// `true` = seen (no badge); flips to `false` when a new item is added.
class CartSeenNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void markSeen() => state = true;
  void markUnseen() => state = false;
}

final cartSeenProvider = NotifierProvider<CartSeenNotifier, bool>(
  CartSeenNotifier.new,
);

/// True when the cart has items the buyer hasn't seen yet — drives the nav
/// badge/notification dot.
final cartHasUnseenProvider = Provider<bool>((ref) {
  return ref.watch(cartCountProvider) > 0 && !ref.watch(cartSeenProvider);
});

/// Product ids the buyer has *unchecked* in the cart. Anything not in this set
/// counts as selected, so newly added items default to selected.
class CartDeselectedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void setSelected(String productId, {required bool selected}) {
    final next = {...state};
    if (selected) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
  }

  void setManySelected(Iterable<String> productIds, {required bool selected}) {
    final next = {...state};
    for (final id in productIds) {
      if (selected) {
        next.remove(id);
      } else {
        next.add(id);
      }
    }
    state = next;
  }
}

final cartDeselectedProvider =
    NotifierProvider<CartDeselectedNotifier, Set<String>>(
      CartDeselectedNotifier.new,
    );

/// Cart items currently selected (checked) for checkout.
final cartSelectedItemsProvider = Provider<List<CartItem>>((ref) {
  final deselected = ref.watch(cartDeselectedProvider);
  return [
    for (final item in ref.watch(cartProvider))
      if (!deselected.contains(item.product.id)) item,
  ];
});

/// Selected cart lines grouped by store, for checkout.
final cartSelectedGroupsProvider = Provider<List<CartStoreGroup>>((ref) {
  final byStore = <String, List<CartItem>>{};
  for (final item in ref.watch(cartSelectedItemsProvider)) {
    byStore.putIfAbsent(item.storeId, () => []).add(item);
  }
  return [
    for (final entry in byStore.entries)
      CartStoreGroup(
        storeId: entry.key,
        storeName: entry.value.first.storeName,
        items: entry.value,
      ),
  ];
});

/// Number of selected items (summed by quantity).
final cartSelectedCountProvider = Provider<int>((ref) {
  return ref
      .watch(cartSelectedItemsProvider)
      .fold<int>(0, (sum, item) => sum + item.quantity);
});

/// Subtotal across the selected items only.
final cartSelectedSubtotalProvider = Provider<num>((ref) {
  return ref
      .watch(cartSelectedItemsProvider)
      .fold<num>(0, (sum, item) => sum + item.lineTotal);
});

/// Server-verified pricing (subtotal, auto-applied discount, total) for
/// the currently-selected items — refetches whenever selection or quantities
/// change. `null` when nothing is selected. This is the single source of
/// truth the cart and checkout pages both read for the breakdown, so what a
/// buyer sees is always what checkout will actually charge.
final cartPricingProvider = FutureProvider<CartPricing?>((ref) async {
  final selected = ref.watch(cartSelectedItemsProvider);
  if (selected.isEmpty) return null;

  // Otherwise this can race the write it depends on: local state (and thus
  // this provider) updates the instant the buyer taps +/-, but the server
  // write is a separate in-flight request — reading pricing before it lands
  // would show a discount computed from the previous quantity.
  await ref.read(cartProvider.notifier).waitForPendingSync();

  final productIds = [for (final item in selected) item.product.id];
  return ref
      .read(cartRemoteDataSourceProvider)
      .getPricing(productIds: productIds);
});
