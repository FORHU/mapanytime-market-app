import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/mapbox_style_manager.dart';

void main() {
  group('MapboxStyleManager.sizeFor', () {
    test('lands on a ~79dp square for a typical phone width', () {
      final size = MapboxStyleManager.sizeFor(375);
      expect(size.width, closeTo(78.75, 0.01));
      expect(size.height, size.width);
    });

    test('clamps to the minimum card width on very small screens', () {
      final size = MapboxStyleManager.sizeFor(200);
      expect(size.width, 64);
      expect(size.height, 64);
    });

    test('clamps to the maximum card width on very large screens', () {
      final size = MapboxStyleManager.sizeFor(1000);
      expect(size.width, 92);
      expect(size.height, 92);
    });
  });

  group('MapboxStyleManager.iconSizeExpression', () {
    test('is a zoom-interpolate expression with the tuned stop values', () {
      final expression = MapboxStyleManager.iconSizeExpression;

      expect(expression[0], 'interpolate');
      expect(expression[1], ['linear']);
      expect(expression[2], ['zoom']);
      // [minZoom, minScale, maxZoom, maxScale] — smallest zoomed out,
      // reaching full size by a comfortable zoom and staying there.
      expect(expression[3], 12);
      expect(expression[4], 0.5);
      expect(expression[5], 17);
      expect(expression[6], 1);
    });

    test('is monotonic: the max-zoom stop is never smaller than the min', () {
      final expression = MapboxStyleManager.iconSizeExpression;
      final minScale = expression[4] as num;
      final maxScale = expression[6] as num;
      expect(
        maxScale,
        greaterThanOrEqualTo(minScale),
        reason: 'zooming in must never shrink a marker',
      );
    });
  });
}
