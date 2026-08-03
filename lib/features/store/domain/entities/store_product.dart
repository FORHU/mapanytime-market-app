/// A product sold by a store.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
    this.storeId = '',
    this.storeName = 'Store',
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final storeObj = json['store'] as Map<String, dynamic>?;
    return StoreProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      // The API stores the image as a related file URL; fall back to empty.
      imageUrl: (json['productFile'] as Map?)?['fileUrl'] as String? ?? '',
      price: _toDouble(json['price']),
      description: json['description'] as String? ?? '',
      category: (json['category'] as Map?)?['name'] as String? ?? 'Other',
      storeId:
          (json['storeId'] as String?) ?? (storeObj?['id'] as String?) ?? '',
      storeName: (storeObj?['storeName'] as String?) ?? 'Store',
    );
  }

  final String id;
  final String name;
  final String imageUrl;
  final num price;
  final String description;
  final String category;
  final String storeId;
  final String storeName;

  /// Coerces a JSON value to a double. The backend serializes money either as
  /// a number or a numeric string (e.g. `"1950"`), so both must be accepted.
  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
