import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart'
    show apiServiceProvider;
import 'package:mapanytime_market_app/features/store/data/review_remote_datasource.dart';
import 'package:mapanytime_market_app/features/store/data/store_api_repository.dart';
import 'package:mapanytime_market_app/features/store/data/store_remote_datasource.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/review_item.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/repositories/store_repository.dart';

/// The active store data source — now backed by the real API.
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return StoreApiRepository(StoreRemoteDataSource(api));
});

final reviewRemoteDataSourceProvider = Provider<ReviewRemoteDataSource>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ReviewRemoteDataSource(api);
});

/// Loads storefront details for a given store id from the API.
final FutureProviderFamily<StoreDetails, String> storeDetailsProvider =
    FutureProvider.family<StoreDetails, String>(
      (ref, storeId) =>
          ref.watch(storeRepositoryProvider).getStoreDetails(storeId),
    );

/// Loads verified buyer reviews for a product (`GET /reviews/products/:id`).
final FutureProviderFamily<ReviewListResult, String> productReviewsProvider =
    FutureProvider.family<ReviewListResult, String>(
      (ref, productId) => ref
          .watch(reviewRemoteDataSourceProvider)
          .getProductReviews(productId),
    );

/// Loads verified buyer reviews for a store (`GET /reviews/stores/:id`).
final FutureProviderFamily<ReviewListResult, String> storeReviewsProvider =
    FutureProvider.family<ReviewListResult, String>(
      (ref, storeId) =>
          ref.watch(reviewRemoteDataSourceProvider).getStoreReviews(storeId),
    );
