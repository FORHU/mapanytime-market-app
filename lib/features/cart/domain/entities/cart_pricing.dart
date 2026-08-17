/// Server-computed price for a single cart line: current unit price plus
/// any auto-applied merchant discount.
class CartItemPricing {
  const CartItemPricing({
    required this.productId,
    required this.unitPrice,
    required this.discountAmount,
    this.appliedAdId,
    this.freeUnits = 0,
  });

  factory CartItemPricing.fromJson(Map<String, dynamic> json) {
    return CartItemPricing(
      productId: json['productId'] as String? ?? '',
      unitPrice: _numOf(json['unitPrice']),
      discountAmount: _numOf(json['discountAmount']),
      appliedAdId: json['appliedAdId'] as String?,
      freeUnits: _numOf(json['freeUnits']).toInt(),
    );
  }

  final String productId;
  final num unitPrice;
  final num discountAmount;
  final String? appliedAdId;
  final int freeUnits;
}

/// Server-verified pricing breakdown for the cart (or a selected subset of
/// it) — the exact numbers `POST /orders` will charge for the same
/// selection, per `mapanytime-api`'s `CartService.previewPricing`.
class CartPricing {
  const CartPricing({
    required this.items,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory CartPricing.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CartPricing(
      items: rawItems is List
          ? rawItems
                .map(
                  (e) => CartItemPricing.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
      subtotalAmount: _numOf(json['subtotalAmount']),
      discountAmount: _numOf(json['discountAmount']),
      taxAmount: _numOf(json['taxAmount']),
      totalAmount: _numOf(json['totalAmount']),
    );
  }

  final List<CartItemPricing> items;
  final num subtotalAmount;
  final num discountAmount;
  final num taxAmount;
  final num totalAmount;

  Map<String, CartItemPricing> get byProductId => {
    for (final item in items) item.productId: item,
  };
}

num _numOf(Object? raw) {
  if (raw is num) return raw;
  if (raw is String) return num.tryParse(raw) ?? 0;
  return 0;
}
