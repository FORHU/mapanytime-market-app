import 'package:equatable/equatable.dart';

/// A category with its nested sub-categories, from `GET /categories/trees`.
/// Used by the Home filter's root → children drill-down.
class CategoryTree extends Equatable {
  const CategoryTree({
    required this.id,
    required this.name,
    this.children = const [],
  });

  final String id;
  final String name;
  final List<CategoryTree> children;

  @override
  List<Object?> get props => [id, name, children];
}
