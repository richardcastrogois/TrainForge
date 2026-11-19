import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

/// "Batimento" monogram: slanted T and F sharing one bar, the F arm drawn as
/// a heartbeat. Coordinates live in a 120x120 box (same as the native icons).
abstract final class HeartbeatGlyph {
  static const strokes = <List<Offset>>[
    [Offset(20, 37), Offset(100, 37)],
    [Offset(44, 37), Offset(44, 97)],
    [Offset(74, 37), Offset(74, 97)],
    [
      Offset(74, 67),
      Offset(82, 67),
      Offset(87, 56),
      Offset(94, 80),
      Offset(99, 67),
      Offset(107, 67),
    ],
  ];
  static const strokeWidth = 11.0;
  static final _skew = Float64List.fromList([
    1, 0, 0, 0, //
    -0.15838, 1, 0, 0, // tan(-9 deg) on the x axis per y
    0, 0, 1, 0,
    0, 0, 0, 1,
  ]);

  /// Paints the glyph inside [rect]; [progress] < 1 draws the strokes in order.
  static void paint(
    Canvas canvas,
    Rect rect,
    Color color, {
    double progress = 1,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / 120, rect.height / 120);
    canvas.translate(5.7, -7); // centres the slanted glyph in the box
    canvas.transform(_skew);
    for (var i = 0; i < strokes.length; i++) {
      final local = ((progress - i * .18) / .46).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final points = strokes[i];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      if (local >= 1) {
        canvas.drawPath(path, paint);
      } else {
        for (final metric in path.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * local), paint);
        }
      }
    }
    canvas.restore();
  }
}

/// Product line icons (24x24, stroke) shared by the entry scene and the grid.
abstract final class BrandIcons {
  static const dumbbell = 'M6.5 7v10M3.5 9.5v5M17.5 7v10M20.5 9.5v5M6.5 12h11';
  static const apple =
      'M12 8.2c-1.9-1.6-6.5-1.2-6.5 3.6 0 3.7 2.7 8.2 4.6 8.2 1 0 1.3-.5 1.9-.5s.9.5 1.9.5c1.9 0 4.6-4.5 4.6-8.2 0-4.8-4.6-5.2-6.5-3.6zM12 8.2c0-2 1-3.4 2.8-4';
  static const drop =
      'M12 3C6.5 9.3 5 13.5 6.5 16.8c3.6 3.6 7.4 3.6 11 0C19 13.5 17.5 9.3 12 3Z';
  static const heart = 'M12 20C-1.5 11.5 5 2.2 12 8.2 19 2.2 25.5 11.5 12 20Z';
  static const leaf =
      'M5 19C5 10.5 10.5 5 19 5c0 8.5-5.5 14-14 14zM5 19l7.5-7.5';
  static const food =
      'M6 3v6c0 2 1 3 3 3M9 12v9M9 12c2 0 3-1 3-3V3M9 3v6M18 3c-3.3 3.3-3.3 6.7 0 10v8';
  static const pulse = 'M2 13h5l3-8 4 15 3-9h5';
  static const all = [dumbbell, apple, drop, heart, leaf, food, pulse];

  static final _cache = <String, Path>{};
  static Path path(String data) => _cache[data] ??= parseSvgPath(data);

  /// Strokes [data] centred on [center] at [size] logical pixels.
  static void paint(
    Canvas canvas,
    String data,
    Offset center,
    double size,
    Color color, {
    double strokeWidth = 1.9,
  }) {
    final k = size / 24;
    canvas.save();
    canvas.translate(center.dx - size / 2, center.dy - size / 2);
    canvas.scale(k);
    canvas.drawPath(
      path(data),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }
}

/// Minimal SVG path parser for the commands used by [BrandIcons]
/// (M L H V C S Z, absolute and relative).
Path parseSvgPath(String data) {
  final tokens = RegExp(
    r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)',
  ).allMatches(data).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0, cmd = 'M';
  var cur = Offset.zero, start = Offset.zero, ctrl = Offset.zero;
  double n() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    Offset pt(double x, double y) => rel ? cur + Offset(x, y) : Offset(x, y);
    switch (cmd.toUpperCase()) {
      case 'M':
        cur = pt(n(), n());
        start = cur;
        path.moveTo(cur.dx, cur.dy);
        cmd = rel ? 'l' : 'L';
      case 'L':
        cur = pt(n(), n());
        path.lineTo(cur.dx, cur.dy);
      case 'H':
        final x = n();
        cur = Offset(rel ? cur.dx + x : x, cur.dy);
        path.lineTo(cur.dx, cur.dy);
      case 'V':
        final y = n();
        cur = Offset(cur.dx, rel ? cur.dy + y : y);
        path.lineTo(cur.dx, cur.dy);
      case 'C':
        final c1 = pt(n(), n()), c2 = pt(n(), n()), end = pt(n(), n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        ctrl = c2;
        cur = end;
      case 'S':
        final c1 = cur * 2 - ctrl, c2 = pt(n(), n()), end = pt(n(), n());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        ctrl = c2;
        cur = end;
      case 'Z':
        path.close();
        cur = start;
      default:
        i++;
    }
    if (cmd.toUpperCase() != 'C' && cmd.toUpperCase() != 'S') ctrl = cur;
  }
  return path;
}

/// Heartbeat scale ("lub-dub") within the first [span] of a beat, [t] in 0..1.
double heartScale(double t, {double span = .55}) {
  if (t <= 0 || t >= span) return 1;
  const points = [
    (0.0, 1.0),
    (.218, 1.1),
    (.473, 1.0),
    (.691, 1.06),
    (1.0, 1.0),
  ];
  final x = t / span;
  for (var k = 0; k < points.length - 1; k++) {
    final (x0, y0) = points[k];
    final (x1, y1) = points[k + 1];
    if (x <= x1) {
      final f = (x - x0) / (x1 - x0);
      return y0 + (y1 - y0) * (1 - math.pow(1 - f, 2));
    }
  }
  return 1;
}
