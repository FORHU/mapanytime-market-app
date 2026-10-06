import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

void main() {
  testWidgets('renders name, store and price on a white card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductCard(
            name: 'Cable Ties',
            imageUrl: '',
            price: 66,
            storeName: 'Tomay Trading Co',
            width: 180,
          ),
        ),
      ),
    );

    expect(find.text('Cable Ties'), findsOneWidget);
    expect(find.text('Tomay Trading Co'), findsOneWidget);

    final card = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ProductCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.ui.surface);
    expect(decoration.boxShadow, isNotEmpty);
  });
}
