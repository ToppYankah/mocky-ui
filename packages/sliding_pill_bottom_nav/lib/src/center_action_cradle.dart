import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Builds the outline of a pill that morphs around a circle centred on it.
///
/// [band] is the pill's rectangle and [radius] the circle's radius (the
/// button radius plus its gap). When the circle is taller than the pill it
/// bulges out of both the top and bottom edges, blended in with concave
/// fillets of radius [smoothing]; otherwise the pill is returned unchanged.
Path centerActionCradlePath({
  required Rect band,
  required BorderRadius borderRadius,
  required double radius,
  required double smoothing,
}) {
  final rrect = borderRadius.toRRect(band).scaleRadii();
  final halfHeight = band.height / 2;
  final centre = band.center;
  if (radius <= halfHeight + 0.01) {
    return Path()..addRRect(rrect);
  }

  // Each fillet circle (radius s) touches the pill's edge and the cradle
  // circle from outside: |F - C| = R + s, so its horizontal offset is d.
  final r = radius;
  final straightHalf =
      band.width / 2 -
      math.max(
        math.max(rrect.tlRadiusX, rrect.trRadiusX),
        math.max(rrect.blRadiusX, rrect.brRadiusX),
      );
  var s = smoothing;
  double offsetFor(double s) =>
      math.sqrt(math.pow(r + s, 2) - math.pow(halfHeight + s, 2));
  // Keep the fillets on the straight part of the pill.
  while (s > 0 && offsetFor(s) > straightHalf) {
    s = math.max(0, s - 1);
  }
  final d = offsetFor(s);
  // Angle (from the fillet centre) at which a fillet meets the circle.
  final a = math.atan2(halfHeight + s, d);
  final cx = centre.dx;
  final top = band.top;
  final bottom = band.bottom;

  // Top edge, left to right, over the cradle.
  final path = Path()
    ..moveTo(band.left + rrect.tlRadiusX, top)
    ..lineTo(cx - d, top);
  if (s > 0) {
    path.arcTo(
      Rect.fromCircle(center: Offset(cx - d, top - s), radius: s),
      math.pi / 2,
      a - math.pi / 2,
      false,
    );
  }
  path.arcTo(
    Rect.fromCircle(center: centre, radius: r),
    -(math.pi - a),
    math.pi - 2 * a,
    false,
  );
  if (s > 0) {
    path.arcTo(
      Rect.fromCircle(center: Offset(cx + d, top - s), radius: s),
      math.pi - a,
      a - math.pi / 2,
      false,
    );
  }
  path
    ..lineTo(band.right - rrect.trRadiusX, top)
    ..arcToPoint(
      Offset(band.right, top + rrect.trRadiusY),
      radius: Radius.elliptical(rrect.trRadiusX, rrect.trRadiusY),
    )
    ..lineTo(band.right, bottom - rrect.brRadiusY)
    ..arcToPoint(
      Offset(band.right - rrect.brRadiusX, bottom),
      radius: Radius.elliptical(rrect.brRadiusX, rrect.brRadiusY),
    )
    // Bottom edge, right to left, under the cradle.
    ..lineTo(cx + d, bottom);
  if (s > 0) {
    path.arcTo(
      Rect.fromCircle(center: Offset(cx + d, bottom + s), radius: s),
      -math.pi / 2,
      a - math.pi / 2,
      false,
    );
  }
  path.arcTo(
    Rect.fromCircle(center: centre, radius: r),
    a,
    math.pi - 2 * a,
    false,
  );
  if (s > 0) {
    path.arcTo(
      Rect.fromCircle(center: Offset(cx - d, bottom + s), radius: s),
      -a,
      a - math.pi / 2,
      false,
    );
  }
  path
    ..lineTo(band.left + rrect.blRadiusX, bottom)
    ..arcToPoint(
      Offset(band.left, bottom - rrect.blRadiusY),
      radius: Radius.elliptical(rrect.blRadiusX, rrect.blRadiusY),
    )
    ..lineTo(band.left, top + rrect.tlRadiusY)
    ..arcToPoint(
      Offset(band.left + rrect.tlRadiusX, top),
      radius: Radius.elliptical(rrect.tlRadiusX, rrect.tlRadiusY),
    )
    ..close();
  return path;
}

/// Paints the morphed bar: shadows, fill, then an inside-aligned border,
/// all following [centerActionCradlePath].
class CenterActionCradlePainter extends CustomPainter {
  CenterActionCradlePainter({
    required this.band,
    required this.borderRadius,
    required this.radius,
    required this.smoothing,
    required this.fill,
    required this.borderColor,
    required this.borderWidth,
    required this.shadows,
  });

  final Rect band;
  final BorderRadius borderRadius;
  final double radius;
  final double smoothing;
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  Path get _path => centerActionCradlePath(
    band: band,
    borderRadius: borderRadius,
    radius: radius,
    smoothing: smoothing,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path;
    for (final shadow in shadows) {
      canvas.drawPath(path.shift(shadow.offset), shadow.toPaint());
    }
    canvas.drawPath(path, Paint()..color = fill);
    if (borderWidth > 0 && borderColor.a > 0) {
      // Clip and double the stroke so the border sits inside the outline,
      // like BoxDecoration's Border.
      canvas
        ..save()
        ..clipPath(path)
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth * 2
            ..color = borderColor,
        )
        ..restore();
    }
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(CenterActionCradlePainter oldDelegate) =>
      band != oldDelegate.band ||
      borderRadius != oldDelegate.borderRadius ||
      radius != oldDelegate.radius ||
      smoothing != oldDelegate.smoothing ||
      fill != oldDelegate.fill ||
      borderColor != oldDelegate.borderColor ||
      borderWidth != oldDelegate.borderWidth ||
      !_sameShadows(shadows, oldDelegate.shadows);

  static bool _sameShadows(List<BoxShadow> a, List<BoxShadow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
