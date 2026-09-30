import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Flat storefront map pin: roof ledge, scalloped striped awning, display
/// window, door and pavement strip, with walls that narrow into a V whose
/// tip sits just above the store's location dot.
///
/// All geometry below is in the design's own 200-unit space (the same
/// numbers as the approved preview), scaled so the building's full width —
/// the roof ledge, x 28 to 172 — spans the requested marker width. Painting
/// is anchored on the bitmap center, which the icon layer's
/// `IconAnchor.CENTER` places on the store's coordinate.

/// Gap from the V's tip down to the coordinate: the dot layer's 6 dp radius
/// plus its 1 dp white ring plus 2 dp of air. Tune on-device if the pin
/// reads as detached from (or jammed into) its dot.
const double storefrontPinTipGap = 6 + 1 + 2;

const double _designWidth = 144;
const double _centerX = 100;
const double _topY = 38;
// Lowest point of the rounded tip's quadratic curve (t = 0.5).
const double _tipY = 202.75;
const double _selectedScale = 1.08;
const Offset _statusDesignPoint = Offset(165, 40);

const double _outlineWidth = 1.5;
const double _ringRadius = 10;
const double _ringStroke = 2;

const Color _frame = Color(0xFFF4F6FC);
const Color _stripeLight = Color(0xFFF9FAFE);
const Color _pavement = Color(0xFFDDE1EC);
const Color _glass = Color(0xFFBFE3F7);
const Color _glassLit = Color(0xFFFFD063);
const Color _brass = Color(0xFFFFD35C);

/// Logical bitmap size for a pin, centered on the store's coordinate, plus
/// where the parts callers draw on top of it sit relative to that center.
@immutable
class StorefrontPinLayout {
  const StorefrontPinLayout({
    required this.size,
    required this.tipOffset,
    required this.statusOffset,
  });

  final Size size;
  final Offset tipOffset;

  /// Where an open/closed badge goes: the roof ledge's top-right corner.
  final Offset statusOffset;
}

/// [statusReach] is the radius of whatever badge the caller draws at
/// [StorefrontPinLayout.statusOffset], so the bitmap leaves room for it.
StorefrontPinLayout storefrontPinLayout(
  double width, {
  bool selected = false,
  double statusReach = 0,
}) {
  final k = _dpPerUnit(width, selected: selected);
  final status = _toLocal(_statusDesignPoint, k);
  final top = math.min(
    _toLocal(const Offset(_centerX, _topY), k).dy - _outlineWidth,
    status.dy - statusReach,
  );
  final halfWidth = math.max(
    _designWidth / 2 * k + _outlineWidth,
    status.dx + statusReach,
  );
  // Mirrored so the bitmap center stays on the coordinate; the lower half
  // is empty apart from the selected ring around the dot.
  final halfHeight = math.max(-top, _ringRadius + _ringStroke);
  return StorefrontPinLayout(
    size: Size(halfWidth * 2, halfHeight * 2),
    tipOffset: const Offset(0, -storefrontPinTipGap),
    statusOffset: status,
  );
}

/// Paints the pin centered on [center]. [photo], when present, is
/// cover-cropped into the display window in place of the illustrated goods.
/// [selected] grows the building 8%, turns the lights on and rings the dot.
void paintStorefrontPin(
  Canvas canvas,
  Offset center,
  double width, {
  required Color wall,
  bool selected = false,
  ui.Image? photo,
}) {
  if (selected) {
    canvas.drawCircle(
      center,
      _ringRadius,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringStroke,
    );
  }

  final k = _dpPerUnit(width, selected: selected);
  final ledge = Color.lerp(wall, Colors.black, 0.3)!;
  final glass = selected ? _glassLit : _glass;

  final body = _bodyPath();
  final ledgeRect = RRect.fromLTRBR(28, 38, 172, 52, const Radius.circular(7));
  final rodRect = RRect.fromLTRBR(41, 62, 159, 70, const Radius.circular(4));
  final stripes = _awningStripes();

  canvas
    ..save()
    ..translate(center.dx, center.dy - storefrontPinTipGap)
    ..scale(k)
    ..translate(-_centerX, -_tipY);

  // White outline behind the silhouette, 1.5 dp outside it at any size —
  // keeps the pin legible over the Satellite basemap without a shadow.
  final outline = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = _outlineWidth * 2 / k;
  canvas
    ..drawPath(body, outline)
    ..drawRRect(ledgeRect, outline)
    ..drawRRect(rodRect, outline);
  for (final stripe in stripes) {
    canvas.drawPath(stripe, outline);
  }

  canvas
    ..drawPath(body, Paint()..color = wall)
    ..drawRRect(ledgeRect, Paint()..color = ledge);

  _paintWindow(canvas, glass: glass, photo: photo, selected: selected);
  _paintDoor(canvas, glass: glass, wall: wall);

  canvas.drawRRect(
    RRect.fromLTRBR(32, 149, 168, 157, const Radius.circular(4)),
    Paint()..color = _pavement,
  );

  for (var i = 0; i < stripes.length; i++) {
    canvas.drawPath(
      stripes[i],
      Paint()..color = i.isEven ? wall : _stripeLight,
    );
  }
  canvas
    ..drawRRect(rodRect, Paint()..color = ledge)
    ..restore();
}

double _dpPerUnit(double width, {required bool selected}) =>
    width / _designWidth * (selected ? _selectedScale : 1);

/// Design-space point to an offset from the bitmap center, in dp.
Offset _toLocal(Offset design, double k) => Offset(
  (design.dx - _centerX) * k,
  (design.dy - _tipY) * k - storefrontPinTipGap,
);

Path _bodyPath() => Path()
  ..moveTo(48, 46)
  ..lineTo(152, 46)
  ..quadraticBezierTo(164, 46, 164, 58)
  ..lineTo(164, 150)
  ..lineTo(107.5, 199.5)
  ..quadraticBezierTo(100, 206, 92.5, 199.5)
  ..lineTo(36, 150)
  ..lineTo(36, 58)
  ..quadraticBezierTo(36, 46, 48, 46)
  ..close();

/// Seven stripes fanning out from the rod, each ending in a half-circle
/// scallop.
List<Path> _awningStripes() {
  const n = 7;
  const topLeft = 44.0;
  const topRight = 156.0;
  const bottomLeft = 34.0;
  const bottomRight = 166.0;
  const yTop = 68.0;
  const yBottom = 92.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final tx0 = topLeft + (topRight - topLeft) * i / n;
        final tx1 = topLeft + (topRight - topLeft) * (i + 1) / n;
        final bx0 = bottomLeft + (bottomRight - bottomLeft) * i / n;
        final bx1 = bottomLeft + (bottomRight - bottomLeft) * (i + 1) / n;
        return Path()
          ..moveTo(tx0, yTop)
          ..lineTo(tx1, yTop)
          ..lineTo(bx1, yBottom)
          ..arcToPoint(
            Offset(bx0, yBottom),
            radius: Radius.circular((bx1 - bx0) / 2),
          )
          ..close();
      }(),
  ];
}

void _paintWindow(
  Canvas canvas, {
  required Color glass,
  required bool selected,
  ui.Image? photo,
}) {
  const glassRect = Rect.fromLTWH(50, 110, 54, 36);
  final glassRRect = RRect.fromRectAndRadius(
    glassRect,
    const Radius.circular(4),
  );
  // With a photo the glass can't glow, so the frame carries "lights on".
  final frameColor = selected && photo != null ? _glassLit : _frame;

  canvas
    ..drawRRect(
      RRect.fromLTRBR(46, 106, 108, 150, const Radius.circular(6)),
      Paint()..color = frameColor,
    )
    ..save()
    ..clipRRect(glassRRect);

  if (photo != null) {
    canvas.drawImageRect(
      photo,
      _coverCrop(photo, glassRect),
      glassRect,
      Paint()..filterQuality = FilterQuality.medium,
    );
  } else {
    canvas
      ..drawRect(glassRect, Paint()..color = glass)
      ..drawRRect(
        RRect.fromLTRBR(55, 117, 64, 130, const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFB547),
      )
      ..drawCircle(
        const Offset(73, 124),
        6,
        Paint()..color = const Color(0xFFFF7A93),
      )
      ..drawRRect(
        RRect.fromLTRBR(84, 114, 91, 130, const Radius.circular(3)),
        Paint()..color = const Color(0xFF4FCB95),
      )
      ..drawRRect(
        RRect.fromLTRBR(95, 119, 101, 130, const Radius.circular(2)),
        Paint()..color = _brass,
      )
      ..drawRect(
        const Rect.fromLTWH(50, 130, 54, 2.5),
        Paint()..color = const Color(0x471B2350),
      )
      ..drawRRect(
        RRect.fromLTRBR(55, 135, 70, 143, const Radius.circular(2)),
        Paint()..color = const Color(0xFF7C8CFF),
      )
      ..drawRRect(
        RRect.fromLTRBR(74, 137, 92, 143, const Radius.circular(2)),
        Paint()..color = _brass,
      );
  }
  canvas.restore();
}

void _paintDoor(Canvas canvas, {required Color glass, required Color wall}) {
  canvas
    ..drawRRect(
      RRect.fromLTRBR(118, 104, 150, 154, const Radius.circular(5)),
      Paint()..color = _frame,
    )
    ..drawRRect(
      RRect.fromLTRBR(122, 108, 146, 152, const Radius.circular(3)),
      Paint()..color = glass,
    )
    ..drawRect(
      const Rect.fromLTWH(122, 129, 24, 2),
      Paint()..color = wall.withValues(alpha: 0.45),
    )
    ..drawCircle(const Offset(141, 134), 2.4, Paint()..color = _brass);
}

/// Source rect that fills [dest] without stretching, like CSS
/// `object-fit: cover`: trims the image's wider dimension, centered.
Rect _coverCrop(ui.Image image, Rect dest) {
  final destAspect = dest.width / dest.height;
  final srcAspect = image.width / image.height;
  final srcWidth = srcAspect > destAspect
      ? image.height * destAspect
      : image.width.toDouble();
  final srcHeight = srcAspect > destAspect
      ? image.height.toDouble()
      : image.width / destAspect;
  return Rect.fromCenter(
    center: Offset(image.width / 2, image.height / 2),
    width: srcWidth,
    height: srcHeight,
  );
}
