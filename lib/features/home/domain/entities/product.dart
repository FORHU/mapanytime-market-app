import 'package:equatable/equatable.dart';

/// A catalog product shown in the Home grid, from `GET /products/all`.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.storeId,
    this.storeName,
    this.imageUrl,
    this.categoryName,
    this.description = '',
    this.tags = const [],
  });

  final String id;
  final String name;
  final double price;
  final String? storeId;
  final String? storeName;
  final String? imageUrl;
  final String? categoryName;
  final String description;
  final List<String> tags;

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    storeId,
    storeName,
    imageUrl,
    categoryName,
    description,
    tags,
  ];
}
