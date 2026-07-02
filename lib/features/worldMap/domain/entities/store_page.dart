import 'package:equatable/equatable.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

/// One page of nearby stores, mirroring the API's paginated `/stores/nearby`
/// envelope (`{ items, total, hasMore, limit, offset }`).
class StorePage extends Equatable {
  const StorePage({
    required this.stores,
    required this.total,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });

  final List<StoreEntity> stores;

  /// Total stores in the viewport (across all pages).
  final int total;

  /// Whether more pages exist beyond this one.
  final bool hasMore;

  final int limit;
  final int offset;

  @override
  List<Object?> get props => [stores, total, hasMore, limit, offset];
}
