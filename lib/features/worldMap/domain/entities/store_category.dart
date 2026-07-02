import 'package:equatable/equatable.dart';

/// A parent category used for the map filter chips (from `GET /categories`).
class StoreCategory extends Equatable {
  const StoreCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
