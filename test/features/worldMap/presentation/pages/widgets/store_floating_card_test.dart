import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_details.dart';
import 'package:mapanytime_market_app/features/store/presentation/controllers/store_controller.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/widgets/store_floating_card.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';

const _testStore = StoreEntity(
  id: 'store-123',
  name: 'Baguio Craft Coffee',
  lat: 16.4023,
  lng: 120.5960,
  distance: 1.5,
  categoryName: 'Cafes',
  rating: 4.9,
  ratingCount: 42,
  isOpen: true,
);

const _testDetails = StoreDetails(
  heroImageUrl: '',
  rating: 4.9,
  ratingCount: 42,
  category: 'Cafes',
  isOpen: true,
  etaLabel: '15 mins',
  productCategories: ['All', 'Coffee'],
  products: [],
  hours: [],
  ads: [],
);

void main() {
  group('StoreFloatingCard', () {
    testWidgets('renders store name and distance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeDetailsProvider(_testStore.id).overrideWith(
              (ref) async => _testDetails,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StoreFloatingCard(
                store: _testStore,
                onClose: () {},
                onNavigate: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Baguio Craft Coffee'), findsOneWidget);
      expect(find.text('1.5 km away'), findsOneWidget);
    });

    testWidgets('triggers onNavigate and onClose callbacks', (tester) async {
      var navigated = false;
      var closed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeDetailsProvider(_testStore.id).overrideWith(
              (ref) async => _testDetails,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StoreFloatingCard(
                store: _testStore,
                onClose: () => closed = true,
                onNavigate: () => navigated = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.near_me_rounded));
      expect(navigated, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('tapping card body pushes RouteNames.storefront', (
      tester,
    ) async {
      var pushedStorefront = false;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: StoreFloatingCard(
                store: _testStore,
                onClose: () {},
                onNavigate: () {},
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.storefront,
            builder: (context, state) {
              pushedStorefront = true;
              return const Scaffold(body: Text('Storefront Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeDetailsProvider(_testStore.id).overrideWith(
              (ref) async => _testDetails,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Baguio Craft Coffee'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(pushedStorefront, isTrue);
      expect(find.text('Storefront Page'), findsOneWidget);
    });
  });
}
