import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

/// Decorative loop: a pencil writes today's workout on a clipboard and ticks
/// each line. Static (everything written) with reduced motion.
class WelcomeAnimation extends StatefulWidget {
  final String title;
  final List<String> lines;
  const WelcomeAnimation({super.key, required this.title, required this.lines});
  @override
  State<WelcomeAnimation> createState() => _WelcomeAnimationState();
}

class _WelcomeAnimationState extends State<WelcomeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!AppMotion.ambient || AppMotion.reduced(context)) {
      loop
        ..stop()
        ..value = .8;
    } else if (!loop.isAnimating) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }

  static const _w = 300.0, _pad = 22.0, _head = 58.0, _row = 46.0;
  static const _textX = _pad + 30 + 12;

  // Timeline (fractions of the loop) for line i.
  static double _start(int i) => .08 + i * .22;
  static const _write = .15;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: TrainForgeTheme.ink,
    );
    final widths = [
      for (final line in widget.lines)
        (TextPainter(
          text: TextSpan(text: line, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: _w - _textX - _pad)).width,
    ];
    final height = _head + _row * widget.lines.length + _pad;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: _w + 60,
          height: height + 60,
          child: AnimatedBuilder(
            animation: loop,
            builder: (context, _) {
              final t = loop.value;
              // Fade the writing out at the end of each loop.
              final fade = t > .9 ? 1 - (t - .9) / .1 : 1.0;
              double progress(int i) =>
                  ((t - _start(i)) / _write).clamp(0.0, 1.0);
              final pencil = _pencil(t, widths);
              double bob(double phase) =>
                  math.sin((t * 2 + phase) * math.pi * 2) * 6;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  _float(Icons.fitness_center, 0, 26 + bob(0), 46),
                  _float(Icons.favorite, _w + 14, 40 + bob(.3), 40),
                  _float(
                    Icons.directions_run,
                    _w + 4,
                    height - 6 + bob(.6),
                    44,
                  ),
                  Positioned(
                    left: 30,
                    top: 30 + math.sin(t * math.pi * 2) * 3,
                    child: Container(
                      width: _w,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: TrainForgeTheme.primary.withValues(
                              alpha: .18,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: _pad,
                            top: 18,
                            right: _pad,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_note,
                                  color: TrainForgeTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: TrainForgeTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (var i = 0; i < widget.lines.length; i++)
                            Positioned(
                              left: _pad,
                              top: _head + i * _row,
                              right: _pad,
                              height: _row,
                              child: Opacity(
                                opacity: fade,
                                child: Row(
                                  children: [
                                    _check(t, i),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ClipRect(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progress(i),
                                          child: Text(
                                            widget.lines[i],
                                            maxLines: 1,
                                            softWrap: false,
                                            style: style,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Ruled lines under each row.
                          for (var i = 0; i < widget.lines.length; i++)
                            Positioned(
                              left: _textX,
                              right: _pad,
                              top: _head + (i + 1) * _row - 6,
                              child: Container(
                                height: 1.2,
                                color: TrainForgeTheme.primary.withValues(
                                  alpha: .12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (pencil != null)
                    Positioned(
                      left: 30 + pencil.dx - 4,
                      top: 30 + pencil.dy - 30,
                      child: const Icon(
                        Icons.edit,
                        size: 34,
                        color: TrainForgeTheme.primary,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Pencil tip inside the card, or null while it is away.
  Offset? _pencil(double t, List<double> widths) {
    final n = widths.length;
    double rowY(int i) => _head + i * _row + _row / 2 + 4;
    for (var i = 0; i < n; i++) {
      final s = _start(i), e = s + _write;
      if (t >= s && t <= e) {
        final p = (t - s) / _write;
        // Small wiggle while writing.
        final wiggle = math.sin(p * math.pi * 14) * 2;
        return Offset(_textX + widths[i] * p, rowY(i) + wiggle);
      }
      final nextStart = i + 1 < n ? _start(i + 1) : .86;
      if (t > e && t < nextStart) {
        final p = Curves.easeInOut.transform((t - e) / (nextStart - e));
        final from = Offset(_textX + widths[i], rowY(i));
        final to = i + 1 < n
            ? Offset(_textX, rowY(i + 1))
            : Offset(_w - 20, _head - 18);
        return Offset.lerp(from, to, p);
      }
    }
    if (t < _start(0)) {
      final p = Curves.easeOut.transform(t / _start(0));
      return Offset.lerp(
        Offset(_w - 20, _head - 18),
        Offset(_textX, rowY(0)),
        p,
      );
    }
    return Offset(_w - 20, _head - 18);
  }

  Widget _check(double t, int i) {
    final at = _start(i) + _write + .01;
    final p = ((t - at) / .05).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(p);
    return SizedBox.square(
      dimension: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: TrainForgeTheme.primary.withValues(alpha: .35),
                width: 2,
              ),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              decoration: const BoxDecoration(
                color: TrainForgeTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 20,
                color: TrainForgeTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _float(IconData icon, double left, double top, double size) =>
      Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: TrainForgeTheme.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: size * .5, color: TrainForgeTheme.primary),
        ),
      );
}
