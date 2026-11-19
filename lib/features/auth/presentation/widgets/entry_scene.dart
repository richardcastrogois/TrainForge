import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/brand_mark.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

/// Timeline of the signed-out entry, in milliseconds (approved prototype
/// "Batimento"). Splash and entry share one canvas: nothing is a route change.
abstract final class EntryTimeline {
  static const total = 6000.0;
  static const beat = Duration(milliseconds: 2000);
  static const idleBeat = Duration(milliseconds: 4000);
  static const settle = 3900.0;
  static const bigEnd = 5120.0;
  static const headerIn = 4840.0;
  static const reveal = 4500.0;

  /// 0..1 progress of [t] inside [a]..[b], eased.
  static double span(
    double t,
    double a,
    double b, [
    Curve curve = Curves.easeOutCubic,
  ]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
  static const glide = Cubic(.65, 0, .2, 1);
}

/// Grid of product icons that light up in a wave from the TF on every beat,
/// plus the ECG line and the halo around the mark.
class EntryBackdropPainter extends CustomPainter {
  final double t, beat, gridOpacity;
  final Offset markCenter;
  final double markSize;
  EntryBackdropPainter({
    required this.t,
    required this.beat,
    required this.gridOpacity,
    required this.markCenter,
    required this.markSize,
  });

  static const _lime = TrainForgeTheme.accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final kx = size.width / 390;
    if (gridOpacity > 0) {
      var index = 0;
      for (var y = 70.0; y < size.height - 30; y += 60) {
        for (var c = 0; c < 6; c++) {
          final x = (33 + c * 65) * kx;
          final p = Offset(x, y);
          final d = (p - center).distance;
          final wordBand =
              y > center.dy + 66 &&
              y < center.dy + 158 &&
              (x - center.dx).abs() < 150;
          if (d < 85 || wordBand) {
            index++;
            continue;
          }
          final f = math.min(d / 470, 1.0) * .55;
          final b = beat;
          final glow = b < f
              ? 0.0
              : b < f + .06
              ? (b - f) / .06
              : b < f + .32
              ? 1 - (b - f - .06) / .26
              : 0.0;
          final opacity = (.08 + .67 * glow) * gridOpacity;
          BrandIcons.paint(
            canvas,
            BrandIcons.all[index % BrandIcons.all.length],
            p,
            26 * (1 + .18 * glow),
            _lime.withValues(alpha: opacity),
            strokeWidth: 1.8,
          );
          index++;
        }
      }
      // Halo leaving the mark on each beat.
      final h = (beat / .6).clamp(0.0, 1.0);
      if (h < 1) {
        final s = markSize * (1 + 1.6 * Curves.easeOut.transform(h));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: markCenter, width: s, height: s),
            Radius.circular(s * 38 / 124),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = _lime.withValues(alpha: .75 * (1 - h) * gridOpacity),
        );
      }
    }
    // ECG line across the screen, through the mark.
    final ecg = EntryTimeline.span(t, 1900, 4200, Curves.linear);
    if (ecg > 0 && ecg < 1) {
      final draw = (ecg / .55).clamp(0.0, 1.0);
      final fade = ecg < .8 ? 1.0 : 1 - (ecg - .8) / .2;
      const pts = [
        (-10.0, 0.0),
        (58.0, 0.0),
        (68.0, 0.0),
        (76.0, -22.0),
        (84.0, 0.0),
        (92.0, 0.0),
        (100.0, -62.0),
        (110.0, 56.0),
        (120.0, -18.0),
        (128.0, 0.0),
        (262.0, 0.0),
        (270.0, 0.0),
        (278.0, -22.0),
        (286.0, 0.0),
        (294.0, 0.0),
        (302.0, -62.0),
        (312.0, 56.0),
        (322.0, -18.0),
        (330.0, 0.0),
        (400.0, 0.0),
      ];
      final path = Path()..moveTo(pts.first.$1 * kx, center.dy + pts.first.$2);
      for (final (x, y) in pts.skip(1)) {
        path.lineTo(x * kx, center.dy + y);
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _lime.withValues(alpha: fade);
      for (final m in path.computeMetrics()) {
        final part = m.extractPath(0, m.length * draw);
        canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = _lime.withValues(alpha: .18 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawPath(part, paint);
      }
    }
  }

  @override
  bool shouldRepaint(EntryBackdropPainter old) => true;
}

/// Geometry shared by the rings painter and the touch handling.
class RingGeometry {
  final Offset center;
  final double k;
  RingGeometry(Size size)
    : center = size.center(Offset.zero),
      k = math.min(math.min(size.width, size.height), 320.0) / 300;
  double radius(int i) => EntryRingsPainter.rings[i].$1 * k;
  double get tileSize => 64 * k;

  /// Ring under [p] (with a finger-sized tolerance), or null.
  int? ringAt(Offset p) {
    final d = (p - center).distance;
    int? best;
    var gap = 9 * k + 10;
    for (var i = 0; i < EntryRingsPainter.rings.length; i++) {
      final g = (d - radius(i)).abs();
      if (g <= gap) {
        gap = g;
        best = i;
      }
    }
    return best;
  }

  bool onTile(Offset p) => (p - center).distance <= tileSize / 2 + 8;

  /// 0..1 clockwise from 12 o'clock.
  double fraction(Offset p) {
    final a = math.atan2(p.dy - center.dy, p.dx - center.dx) + math.pi / 2;
    return (a < 0 ? a + 2 * math.pi : a) / (2 * math.pi);
  }
}

/// Three progress rings (training lime, food cream, progress light green) with
/// their icons riding the arc ends and, once settled, the TF at the centre.
/// [values] are what the person set by dragging; [pulse] runs after a tap on
/// the TF (heartbeat plus ripples).
class EntryRingsPainter extends CustomPainter {
  final double t, idle, pulse;
  final List<double> values;
  final bool showCenter;
  EntryRingsPainter({
    required this.t,
    required this.idle,
    required this.values,
    required this.showCenter,
    this.pulse = 0,
  });

  static const rings = [
    (128.0, Color(0xffd8eb90), .78, BrandIcons.dumbbell),
    (100.0, Color(0xfff6f6f1), .62, BrandIcons.apple),
    (72.0, Color(0xffa9c46a), .86, BrandIcons.pulse),
  ];
  static List<double> get initialValues => [for (final r in rings) r.$3];

  @override
  void paint(Canvas canvas, Size size) {
    final g = RingGeometry(size);
    if (g.k * 300 < 60) return;
    final k = g.k, c = g.center;
    final track = EntryTimeline.span(t, 4300, 4700);
    for (var i = 0; i < rings.length; i++) {
      final (_, color, _, icon) = rings[i];
      final r = g.radius(i);
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18 * k
          ..color = color.withValues(alpha: .14 * track),
      );
      final p =
          values[i] *
          EntryTimeline.span(
            t,
            4500 + i * 140,
            5700 + i * 140,
            const Cubic(.3, .7, .2, 1),
          );
      if (p <= 0) continue;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        p * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18 * k
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      final a = -math.pi / 2 + p * 2 * math.pi;
      final bob = math.sin((idle + i * .1) * 2 * math.pi) * 3 * k;
      final rider = c + Offset(math.cos(a) * r, math.sin(a) * r + bob);
      canvas.drawCircle(rider, 17 * k, Paint()..color = TrainForgeTheme.deep);
      canvas.drawCircle(
        rider,
        17 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * k
          ..color = color,
      );
      BrandIcons.paint(canvas, icon, rider, 21 * k, color, strokeWidth: 2.1);
    }
    if (!showCenter) return;
    // Ripples leaving the TF after a tap: the app "alive".
    if (pulse > 0 && pulse < 1) {
      for (var j = 0; j < 3; j++) {
        final q = ((pulse - j * .14) / .62).clamp(0.0, 1.0);
        if (q <= 0 || q >= 1) continue;
        final s = g.tileSize * (1 + 2.4 * Curves.easeOut.transform(q));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: s, height: s),
            Radius.circular(s * 11 / 34),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = TrainForgeTheme.accent.withValues(alpha: .7 * (1 - q)),
        );
      }
    }
    final beat = pulse > 0 && pulse < 1
        ? heartScale(pulse, span: .45)
        : heartScale(idle, span: .154);
    final s = g.tileSize * beat;
    final tile = Rect.fromCenter(center: c, width: s, height: s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tile, Radius.circular(s * 11 / 34)),
      Paint()..color = TrainForgeTheme.deep,
    );
    HeartbeatGlyph.paint(canvas, tile.deflate(s * .1), TrainForgeTheme.accent);
  }

  @override
  bool shouldRepaint(EntryRingsPainter old) =>
      old.t != t ||
      old.idle != idle ||
      old.pulse != pulse ||
      old.showCenter != showCenter ||
      !_same(old.values, values);
  static bool _same(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
