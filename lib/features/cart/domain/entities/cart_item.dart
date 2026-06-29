import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';

/// A single line in the cart: a product, the store it belongs to, and qty.
class CartItem {
  const CartItem({
    required this.product,
    required this.storeId,
    required this.storeName,
    this.quantity = 1,
  });

  final StoreProduct product;
  final String storeId;
  final String storeName;
  final int quantity;

  num get lineTotal => product.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
    product: product,
    storeId: storeId,
    storeName: storeName,
    quantity: quantity ?? this.quantity,
  );
}

/// Cart lines grouped under one store, for the grouped cart view.
class CartStoreGroup {
  const CartStoreGroup({
    required this.storeId,
    required this.storeName,
    required this.items,
  });

  final String storeId;
  final String storeName;
  final List<CartItem> items;

  num get subtotal => items.fold<num>(0, (sum, item) => sum + item.lineTotal);
}
