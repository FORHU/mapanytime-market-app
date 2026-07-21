import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/cart/data/cart_remote_datasource.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSource(ref.watch(apiServiceProvider));
});

/// In-memory cart state synced to the remote API.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

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
    unawaited(
      ref
          .read(cartRemoteDataSourceProvider)
          .addToCart(
            storeId: storeId,
            productId: product.id,
            quantity: quantity,
          )
          .catchError((_) {}), // fire-and-forget
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
    unawaited(
      ref
          .read(cartRemoteDataSourceProvider)
          .addToCart(
            storeId: storeId,
            productId: productId,
            quantity: quantity,
          )
          .catchError((_) {}),
    );
  }

  void remove(String productId) {
    state = [
      for (final item in state)
        if (item.product.id != productId) item,
    ];
  }

  void removeMany(Iterable<String> productIds) {
    final ids = productIds.toSet();
    state = [
      for (final item in state)
        if (!ids.contains(item.product.id)) item,
    ];
  }

  void clear() {
    state = const [];
    unawaited(
      ref.read(cartRemoteDataSourceProvider).clearCart().catchError((_) {}),
    );
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
