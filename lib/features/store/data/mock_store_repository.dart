import 'package:mapanytime_market_app/features/store/data/mock_merchant_ads.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_hours.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/store/domain/repositories/store_repository.dart';

/// Static mock storefront details. Products are seeded by store id so each
/// store shows a stable set of images. Replace with an API impl later.
class MockStoreRepository implements StoreRepository {
  const MockStoreRepository();

  static const _img = 'https://picsum.photos/seed';

  @override
  Future<StoreDetails> getStoreDetails(String storeId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final seed = storeId.isEmpty ? 'store' : storeId;

    return StoreDetails(
      heroImageUrl: '$_img/$seed-hero/800/400',
      rating: 4.8,
      ratingCount: 412,
      category: 'Specialty • Grocery & Essentials',
      isOpen: true,
      etaLabel: 'Pickup in ~15 min',
      productCategories: const ['All', 'Produce', 'Bakery', 'Dairy', 'Snacks'],
      hours: const [
        StoreDayHours(dayOfWeek: 0, isClosed: true),
        StoreDayHours(
          dayOfWeek: 1,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
        StoreDayHours(
          dayOfWeek: 2,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
        StoreDayHours(
          dayOfWeek: 3,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
        StoreDayHours(
          dayOfWeek: 4,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
        StoreDayHours(
          dayOfWeek: 5,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
        StoreDayHours(
          dayOfWeek: 6,
          isClosed: false,
          openMinutes: 540,
          closeMinutes: 1260,
        ),
      ],
      ads: mockMerchantAdsForStore(
        storeId,
        category: 'Specialty • Grocery & Essentials',
      ),
      products: [
        StoreProduct(
          id: '$seed-1',
          name: 'Fresh Avocados (3pc)',
          imageUrl: '$_img/$seed-1/400',
          price: 180,
          category: 'Produce',
          description:
              'Hand-picked ripe avocados, perfect for toast or salads. '
              'Sourced from local farms and delivered fresh daily.',
        ),
        StoreProduct(
          id: '$seed-2',
          name: 'Sourdough Loaf',
          imageUrl: '$_img/$seed-2/400',
          price: 240,
          category: 'Bakery',
          description:
              'Slow-fermented artisan sourdough with a crisp crust and '
              'airy crumb. Baked fresh every morning.',
        ),
        StoreProduct(
          id: '$seed-3',
          name: 'Farm Eggs (dozen)',
          imageUrl: '$_img/$seed-3/400',
          price: 150,
          category: 'Dairy',
          description:
              'Free-range eggs from pasture-raised hens. Rich golden yolks, '
              'great for any meal.',
        ),
        StoreProduct(
          id: '$seed-4',
          name: 'Sea Salt Chips',
          imageUrl: '$_img/$seed-4/400',
          price: 95,
          category: 'Snacks',
          description:
              'Kettle-cooked potato chips with flaky sea salt. '
              'Satisfyingly crunchy.',
        ),
        StoreProduct(
          id: '$seed-5',
          name: 'Greek Yogurt',
          imageUrl: '$_img/$seed-5/400',
          price: 130,
          category: 'Dairy',
          description:
              'Thick, creamy Greek yogurt packed with protein. '
              'Unsweetened and versatile.',
        ),
        StoreProduct(
          id: '$seed-6',
          name: 'Cherry Tomatoes',
          imageUrl: '$_img/$seed-6/400',
          price: 110,
          category: 'Produce',
          description:
              'Sweet, vine-ripened cherry tomatoes. A burst of flavor in '
              'every bite.',
        ),
      ],
    );
  }
}
