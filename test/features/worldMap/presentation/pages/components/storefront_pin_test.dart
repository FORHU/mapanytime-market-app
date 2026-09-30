import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/components/storefront_pin.dart';

const _wall = Color(0xFF17A566);

/// Paints a pin into a bitmap the size its layout asks for, the way
/// MapboxStyleManager does (1 dp = 1 px here), and returns the RGBA bytes.
Future<({ByteData bytes, int width, int height})> _render({
  required double width,
  bool selected = false,
  ui.Image? photo,
}) async {
  final layout = storefrontPinLayout(width, selected: selected);
  final pixelWidth = layout.size.width.ceil();
  final pixelHeight = layout.size.height.ceil();
  final recorder = ui.PictureRecorder();
  paintStorefrontPin(
    Canvas(recorder),
    Offset(pixelWidth / 2, pixelHeight / 2),
    width,
    wall: _wall,
    selected: selected,
    photo: photo,
  );
  final image = await recorder.endRecording().toImage(
    pixelWidth,
    pixelHeight,
  );
  final bytes = await image.toByteData();
  return (bytes: bytes!, width: pixelWidth, height: pixelHeight);
}

Color _pixel(ByteData bytes, int width, int x, int y) {
  final i = (y * width + x) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

Future<ui.Image> _solidImage(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 4, 4),
    Paint()..color = color,
  );
  return recorder.endRecording().toImage(4, 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('storefrontPinLayout', () {
    for (final width in [48 * 0.9, 68 * 0.9]) {
      test('puts the V tip just above the coordinate at width $width', () {
        final layout = storefrontPinLayout(width);
        expect(layout.tipOffset, const Offset(0, -storefrontPinTipGap));
        // The whole building sits above the tip, inside the bitmap's top
        // half; the bitmap is mirrored so its center is the coordinate.
        expect(layout.size.height / 2, greaterThan(storefrontPinTipGap));
        expect(layout.size.width, greaterThanOrEqualTo(width));
      });

      test('leaves room for the status badge at width $width', () {
        const reach = 6.5;
        final layout = storefrontPinLayout(width, statusReach: reach);
        expect(
          layout.statusOffset.dx + reach,
          lessThanOrEqualTo(layout.size.width / 2),
        );
        expect(
          -layout.statusOffset.dy + reach,
          lessThanOrEqualTo(layout.size.height / 2),
        );
      });
    }

    test('a selected pin is larger than an unselected one', () {
      final normal = storefrontPinLayout(60);
      final selected = storefrontPinLayout(60, selected: true);
      expect(selected.size.height, greaterThan(normal.size.height));
      expect(selected.size.width, greaterThan(normal.size.width));
    });
  });

  group('paintStorefrontPin', () {
    test(
      'paints the wall color just above the tip and nothing below',
      () async {
        final r = await _render(width: 60);
        final cx = r.width ~/ 2;
        final cy = r.height ~/ 2;

        // Inside the V, a few dp above the tip.
        final aboveTip = _pixel(r.bytes, r.width, cx, cy - 15);
        expect(aboveTip, _wall);

        // The coordinate itself and the bitmap's lower half stay empty, so
        // the map's dot shows through below the pin.
        expect(_pixel(r.bytes, r.width, cx, cy).a, 0);
        expect(_pixel(r.bytes, r.width, cx, cy + 5).a, 0);
      },
    );

    test('rings the dot when selected', () async {
      final r = await _render(width: 60, selected: true);
      final cx = r.width ~/ 2;
      final cy = r.height ~/ 2;
      // The ring is 10 dp out from the coordinate, below the building.
      expect(_pixel(r.bytes, r.width, cx, cy + 10).a, greaterThan(0));
      expect(_pixel(r.bytes, r.width, cx, cy).a, 0);
    });

    test('draws every state without throwing', () async {
      final photo = await _solidImage(const Color(0xFFFF0000));
      for (final selected in [false, true]) {
        for (final withPhoto in [false, true]) {
          final r = await _render(
            width: 48 * 0.9,
            selected: selected,
            photo: withPhoto ? photo : null,
          );
          expect(r.width, greaterThan(0));
          expect(r.height, greaterThan(0));
        }
      }
    });
  });
}
