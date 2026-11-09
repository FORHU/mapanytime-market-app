import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/core/services/api_service.dart';
import 'package:mapanytime_market_app/features/store/data/review_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;
  late ReviewRemoteDataSource dataSource;

  setUp(() {
    mockApi = MockApiService();
    dataSource = ReviewRemoteDataSource(mockApi);
  });

  group('ReviewRemoteDataSource.getProductReviews', () {
    const tReviewsResponse = {
      'success': true,
      'statusCode': 200,
      'data': {
        'items': [
          {
            'id': 'rev-1',
            'rating': 5,
            'comment': 'Fresh and delicious!',
            'createdAt': '2026-11-09T10:00:00.000Z',
            'buyer': {'id': 'buyer-1', 'displayName': 'Maria Santos'},
          },
          {
            'id': 'rev-2',
            'rating': 4,
            'comment': null,
            'createdAt': '2026-11-08T09:00:00.000Z',
            'buyer': {'id': 'buyer-2', 'displayName': ''},
          },
        ],
        'total': 2,
        'averageRating': 4.5,
      },
    };

    test('parses items, total, and averageRating from API envelope', () async {
      when(
        () => mockApi.get('/reviews/products/prod-1'),
      ).thenAnswer((_) async => tReviewsResponse);

      final result = await dataSource.getProductReviews('prod-1');

      expect(result.total, 2);
      expect(result.averageRating, 4.5);
      expect(result.items.length, 2);
      expect(result.items.first.id, 'rev-1');
      expect(result.items.first.rating, 5);
      expect(result.items.first.comment, 'Fresh and delicious!');
      expect(result.items.first.buyerId, 'buyer-1');
      expect(result.items.first.buyerName, 'Maria Santos');
      expect(result.items[1].buyerName, 'Verified Buyer');
    });
  });

  group('ReviewRemoteDataSource.upsertProductReview', () {
    test(
      'sends rating and trimmed comment to PUT /reviews/products/:id',
      () async {
        when(
          () => mockApi.put('/reviews/products/prod-1', any()),
        ).thenAnswer((_) async => const {'success': true});

        await dataSource.upsertProductReview(
          productId: 'prod-1',
          rating: 5,
          comment: '  Great quality  ',
        );

        verify(
          () => mockApi.put('/reviews/products/prod-1', {
            'rating': 5,
            'comment': 'Great quality',
          }),
        ).called(1);
      },
    );
  });

  group('ReviewRemoteDataSource.upsertStoreReview & deleteStoreReview', () {
    test('upserts and deletes store reviews on store endpoints', () async {
      when(
        () => mockApi.put('/reviews/stores/store-1', any()),
      ).thenAnswer((_) async => const {'success': true});
      when(
        () => mockApi.delete('/reviews/stores/reviews/srev-1'),
      ).thenAnswer((_) async => const {'success': true});

      await dataSource.upsertStoreReview(
        storeId: 'store-1',
        rating: 4,
        comment: 'Fast pickup',
      );
      verify(
        () => mockApi.put('/reviews/stores/store-1', {
          'rating': 4,
          'comment': 'Fast pickup',
        }),
      ).called(1);

      await dataSource.deleteStoreReview('srev-1');
      verify(
        () => mockApi.delete('/reviews/stores/reviews/srev-1'),
      ).called(1);
    });
  });
}
