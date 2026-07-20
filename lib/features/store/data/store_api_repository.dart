import 'package:mapanytime_market_app/features/store/data/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/repositories/store_repository.dart';

/// API-backed implementation of [StoreRepository].
/// Delegates to [StoreRemoteDataSource] for all network calls.
class StoreApiRepository implements StoreRepository {
  const StoreApiRepository(this._datasource);

  final StoreRemoteDataSource _datasource;

  @override
  Future<StoreDetails> getStoreDetails(String storeId) =>
      _datasource.getStoreDetails(storeId);
}
