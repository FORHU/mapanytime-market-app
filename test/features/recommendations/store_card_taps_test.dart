import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/nearby_store_card.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/widgets/recommended_store_card.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';

const _store = StoreEntity(
  id: 's1',
  name: 'Kalye Roasters',
  lat: 0,
  lng: 0,
  distance: 0.4,
  categoryName: 'Food & Beverage',
  rating: 4.8,
  isOpen: true,
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(height: 314, child: child)),
  ),
);

void main() {
  group('NearbyStoreCard', () {
    late int visits;
    late int favorites;

    Future<void> pump(WidgetTester t, {bool isFavorite = false}) async {
      visits = 0;
      favorites = 0;
      await t.pumpWidget(
        _host(
          NearbyStoreCard(
            store: _store,
            isFavorite: isFavorite,
            onVisit: () => visits++,
            onFavorite: () => favorites++,
          ),
        ),
      );
    }

    testWidgets('tapping the card body, name or cover does nothing', (t) async {
      await pump(t);

      await t.tap(find.text('Kalye Roasters'));
      await t.tap(find.text('Food & Beverage'));
      await t.tap(find.text('Open'));
      await t.pump();

      expect(visits, 0);
      expect(favorites, 0);
    });

    testWidgets('the heart only toggles saved — it never visits', (t) async {
      await pump(t);

      await t.tap(find.byIcon(Icons.favorite_border_rounded));
      await t.pump();

      expect(favorites, 1);
      expect(visits, 0);
    });

    testWidgets('a saved store shows a filled heart', (t) async {
      await pump(t, isFavorite: true);

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('Visit Store is the only way in', (t) async {
      await pump(t);

      await t.tap(find.text('Visit Store'));
      await t.pump();

      expect(visits, 1);
      expect(favorites, 0);
    });
  });

  group('RecommendedStoreCard', () {
    testWidgets('row taps do nothing; Visit opens the store', (t) async {
      var visits = 0;
      await t.pumpWidget(
        _host(RecommendedStoreCard(store: _store, onVisit: () => visits++)),
      );

      await t.tap(find.text('Kalye Roasters'));
      await t.tap(find.text('Food & Beverage'));
      await t.pump();
      expect(visits, 0);

      await t.tap(find.text('Visit'));
      await t.pump();
      expect(visits, 1);
    });

    testWidgets('has no heart unless the caller asks for one', (t) async {
      await t.pumpWidget(_host(const RecommendedStoreCard(store: _store)));

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('the Saved page heart unsaves without visiting', (t) async {
      var visits = 0;
      var unsaves = 0;
      await t.pumpWidget(
        _host(
          RecommendedStoreCard(
            store: _store,
            isSaved: true,
            onToggleSave: () => unsaves++,
            onVisit: () => visits++,
          ),
        ),
      );

      await t.tap(find.byIcon(Icons.favorite_rounded));
      await t.pump();

      expect(unsaves, 1);
      expect(visits, 0);
    });
  });
}
