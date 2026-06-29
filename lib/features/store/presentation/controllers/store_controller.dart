import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_app/features/store/data/mock_store_repository.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/repositories/store_repository.dart';

/// The active store data source. Swap to an API-backed repository here later.
final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => const MockStoreRepository(),
);

/// Loads storefront details for a given store id (mock for now).
final FutureProviderFamily<StoreDetails, String> storeDetailsProvider =
    FutureProvider.family<StoreDetails, String>((ref, storeId) {
  return ref.watch(storeRepositoryProvider).getStoreDetails(storeId);
});
