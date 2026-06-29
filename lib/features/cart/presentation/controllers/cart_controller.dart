import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/cart/domain/entities/cart_item.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// In-memory cart state. Mock for now — persist / sync to a backend later.
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
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(product: product, storeId: storeId, storeName: storeName),
      ];
    }
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
  }

  void remove(String productId) {
    state = [
      for (final item in state)
        if (item.product.id != productId) item,
    ];
  }

  void clear() => state = const [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

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
