/// A product sold by a store. Mock-backed for now.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
  });

  final String id;
  final String name;
  final String imageUrl;
  final num price;
  final String description;
  final String category;
}
