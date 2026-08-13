import 'package:mapanytime_market_app/shared/utils/tag_parser.dart';

/// A product sold by a store.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
    this.tags = const [],
    this.storeId = '',
    this.storeName = 'Store',
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final storeObj = json['store'] as Map<String, dynamic>?;
    return StoreProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: _imageUrlOf(json),
      price: _parsePrice(json['price']),
      description: json['description'] as String? ?? '',
      category: (json['category'] as Map?)?['name'] as String? ?? 'Other',
      tags: parseTagNames(json['tags']),
      storeId:
          (json['storeId'] as String?) ?? (storeObj?['id'] as String?) ?? '',
      storeName: (storeObj?['storeName'] as String?) ?? 'Store',
    );
  }

  static String _imageUrlOf(Map<String, dynamic> json) {
    final images = json['productImages'];
    if (images is List && images.isNotEmpty) {
      final file = (images.first as Map?)?['file'];
      if (file is Map) {
        return (file['url'] ?? file['path'] ?? file['fileUrl']) as String? ??
            '';
      }
    }
    return '';
  }

  static double _parsePrice(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0;
  }

  final String id;
  final String name;
  final String imageUrl;
  final num price;
  final String description;
  final String category;
  final List<String> tags;
  final String storeId;
  final String storeName;
}
