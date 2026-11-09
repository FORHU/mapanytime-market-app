import 'package:mapanytime_market_app/core/constants/api_endpoints.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/review_item.dart';

class ReviewRemoteDataSource {
  const ReviewRemoteDataSource(this._api);

  final ApiService _api;

  Future<ReviewListResult> getProductReviews(String productId) async {
    final response = await _api.get(ApiEndpoints.productReviews(productId));
    final data = response is Map ? response['data'] : null;
    if (data is Map) {
      return ReviewListResult.fromJson(data.cast<String, dynamic>());
    }
    return ReviewListResult.empty;
  }

  Future<void> upsertProductReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    final trimmed = comment?.trim();
    await _api.put(ApiEndpoints.productReviews(productId), <String, dynamic>{
      'rating': rating,
      if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
    });
  }

  Future<void> deleteProductReview(String reviewId) =>
      _api.delete(ApiEndpoints.deleteProductReview(reviewId));

  Future<ReviewListResult> getStoreReviews(String storeId) async {
    final response = await _api.get(ApiEndpoints.storeReviews(storeId));
    final data = response is Map ? response['data'] : null;
    if (data is Map) {
      return ReviewListResult.fromJson(data.cast<String, dynamic>());
    }
    return ReviewListResult.empty;
  }

  Future<void> upsertStoreReview({
    required String storeId,
    required int rating,
    String? comment,
  }) async {
    final trimmed = comment?.trim();
    await _api.put(ApiEndpoints.storeReviews(storeId), <String, dynamic>{
      'rating': rating,
      if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
    });
  }

  Future<void> deleteStoreReview(String reviewId) =>
      _api.delete(ApiEndpoints.deleteStoreReview(reviewId));
}
