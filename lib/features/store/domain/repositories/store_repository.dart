import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';

/// Source of storefront details. Swap the implementation (mock → API) without
/// touching the presentation layer.
// ignore: one_member_abstracts
abstract class StoreRepository {
  Future<StoreDetails> getStoreDetails(String storeId);
}
