import 'package:equatable/equatable.dart';

/// A catalog product shown in the Home grid, from `GET /products/all`.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.storeName,
    this.imageUrl,
    this.categoryName,
  });

  final String id;
  final String name;
  final double price;
  final String? storeName;
  final String? imageUrl;
  final String? categoryName;

  @override
  List<Object?> get props => [
    id,
    name,
    price,
    storeName,
    imageUrl,
    categoryName,
  ];
}
