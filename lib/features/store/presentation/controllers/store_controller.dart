import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/store/data/store_api_repository.dart';
import 'package:mapanytime_market_app/features/store/data/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/repositories/store_repository.dart';

/// The active store data source — now backed by the real API.
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return StoreApiRepository(StoreRemoteDataSource(api));
});

/// Loads storefront details for a given store id from the API.
final FutureProviderFamily<StoreDetails, String> storeDetailsProvider =
    FutureProvider.family<StoreDetails, String>(
      (ref, storeId) =>
          ref.watch(storeRepositoryProvider).getStoreDetails(storeId),
    );
