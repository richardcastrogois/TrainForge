import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/core/l10n/localized_context.dart';

import 'glass_surface.dart';
import 'shell_labels.dart';

/// Evolução before the first workout: every card the page will have, with
/// the real values of an empty history (0) and a gentle looping preview of
/// how each one fills up. Fits one phone screen; with reduced motion it is
/// still.
///
/// Energy and water are not zero for sure (meals can exist without a
/// workout), so those two show only what they will measure, never a number.
class EvolutionPreview extends StatefulWidget {
  /// The first-workout button; null once there are workouts.
  final VoidCallback? onStart;
  final DateTime Function() now;

  /// What is already known; [EvolutionData.empty] before the first record.
  final EvolutionData data;
  const EvolutionPreview({
    super.key,
    required this.onStart,
    required this.now,
    this.data = EvolutionData.empty,
  });

  @override
  State<EvolutionPreview> createState() => _EvolutionPreviewState();
}

/// Numbers behind Evolução. Null means "not known", never zero: those cards
/// show only what they measure.
class EvolutionData {
  /// Days in a row with the day's goals met.
  final int streakDays;
  final int minutes, sets;
  final int? kcal, waterMl, waterGoalMl;

  /// Day of the current month -> share of the day's goals met (0 to 1:
  /// workout, food and water). Null before any record: the grid only
  /// previews how it fills.
  final Map<int, double>? dayScores;
  const EvolutionData({
    this.streakDays = 0,
    this.minutes = 0,
    this.sets = 0,
    this.kcal,
    this.waterMl,
    this.waterGoalMl,
    this.dayScores,
  });
  static const empty = EvolutionData();
}

class _EvolutionPreviewState extends State<EvolutionPreview>
    with TickerProviderStateMixin {
  /// Cards rise one after the other, once.
  late final enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1035),
  );

  /// Slow loop of the "how it fills" preview.
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      enter.value = 1;
    } else {
      enter.forward();
      // Keeps moving while the page is on screen; the shell pauses tickers
      // of hidden tabs, so it costs nothing elsewhere.
      loop.repeat();
    }
  }

  @override
  void dispose() {
    enter.dispose();
    loop.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 over one loop, eased.
  double wave([double shift = 0]) {
    // At rest everything shows the real, empty state.
    if (!loop.isAnimating) return 0;
    final v = (loop.value + shift) % 1;
    return Curves.easeInOutSine.transform(v < .5 ? v * 2 : (1 - v) * 2);
  }

  Widget rise(int index, Widget child) => AnimatedBuilder(
    animation: enter,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(
        ((enter.value - index * .08) / .6).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      );
    },
    child: child,
  );

  EvolutionData get data => widget.data;

  /// Height of the water in its card: the real share of the day's goal with
  /// a gentle surface wave; without a goal, a preview that fills and empties.
  double water() {
    final ml = data.waterMl, goal = data.waterGoalMl;
    if (ml == null) return .12 + .5 * wave(.5);
    // Water recorded but no goal yet: a calm low wave, no level implied.
    if (goal == null || goal <= 0) return ml > 0 ? .3 : 0;
    final level = (ml / goal).clamp(0.0, 1.0);
    return level;
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    String count(String key, int n) =>
        shellLabel(context, n == 1 ? '${key}One' : key).replaceAll('{n}', '$n');
    // Calendar squares sized by the screen so the page never scrolls.
    final cell = _compact(context)
        ? (MediaQuery.sizeOf(context).height * .018).clamp(12.0, 26.0)
        : (MediaQuery.sizeOf(context).height * .021).clamp(14.0, 26.0);
    // Short screens get tighter gaps so the page still fits without scrolling.
    final space = _compact(context) ? 6.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rise(0, _Card(child: _month(context, cell))),
        SizedBox(height: space),
        rise(
          1,
          Row(
            children: [
              Expanded(
                child: _Card(
                  child: _Stat(
                    leading: AnimatedBuilder(
                      animation: loop,
                      builder: (context, _) =>
                          _Flame(days: data.streakDays, t: loop.value),
                    ),
                    value: count('evolutionDays', data.streakDays),
                    label: l('evolutionStreak'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Card(
                  child: _Stat(
                    leading: SizedBox.square(
                      dimension: 30,
                      child: AnimatedBuilder(
                        animation: loop,
                        builder: (context, _) => CustomPaint(
                          painter: _Ring(
                            value: .7 * wave(),
                            track: context.tf.soft,
                            color: context.tf.primary,
                          ),
                        ),
                      ),
                    ),
                    value: '${data.minutes} min',
                    label: l('evolutionMinutes'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space),
        rise(
          2,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Card(
                    child: _Small(
                      icon: Icons.layers_outlined,
                      value: '${data.sets}',
                      label: l('evolutionSets'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Card(
                    child: AnimatedBuilder(
                      animation: loop,
                      builder: (context, _) => _Small(
                        icon: Icons.bolt_outlined,
                        value: data.kcal?.toString(),
                        label: l('evolutionEnergy'),
                        iconScale: 1 + .15 * wave(.25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Card(
                    // The glass fills and empties like a cup of water.
                    background: AnimatedBuilder(
                      animation: loop,
                      builder: (context, _) => CustomPaint(
                        painter: _Water(
                          level: water(),
                          phase: loop.value,
                          color: context.tf.blue,
                        ),
                      ),
                    ),
                    child: _Small(
                      icon: Icons.water_drop_outlined,
                      value: data.waterMl == null ? null : '${data.waterMl} ml',
                      label: l('evolutionWater'),
                      iconColor: const Color(0xff2f7fcf),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.onStart != null) ...[
          SizedBox(height: space + 4),
          rise(
            3,
            // The one orange block of the page, so the eye lands on it; a slow
            // glow breathes around it.
            AnimatedBuilder(
              animation: loop,
              builder: (context, child) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: TrainForgeTheme.highlight.withValues(
                        alpha: .22 * wave(),
                      ),
                      spreadRadius: 4 * wave(),
                    ),
                  ],
                ),
                child: child,
              ),
              child: LiquidButton(
                label: l('evolutionStart'),
                color: TrainForgeTheme.highlight,
                foreground: TrainForgeTheme.ink,
                height: _compact(context) ? 46 : 56,
                onPressed: widget.onStart,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Consistency of the month: one square per day, Monday first, filling
  /// green with each workout. Empty for now; the loop only previews it.
  Widget _month(BuildContext context, double cell) {
    final now = widget.now();
    final first = DateTime(now.year, now.month);
    final days = DateTime(now.year, now.month + 1, 0).day;
    final lead = first.weekday - 1;
    final rows = ((lead + days) / 7).ceil();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final green = context.tf.primary;
    final gap = _compact(context) ? 4.0 : 6.0;
    final scores = data.dayScores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shellLabel(context, 'evolutionConsistency'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Long month names and large text shrink instead of overflowing.
            Flexible(
              fit: FlexFit.tight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  MaterialLocalizations.of(context).formatMonthYear(now),
                  style: TextStyle(fontSize: 13, color: context.tf.muted),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Seven columns share the card width with the same small gap between
        // tiles and between rows, so there are no empty lanes.
        Row(
          spacing: gap,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.weekdayInitial(
                        DateTime(monday.year, monday.month, monday.day + i),
                      ),
                      style: TextStyle(fontSize: 12, color: context.tf.muted),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: gap),
        AnimatedBuilder(
          animation: loop,
          builder: (context, _) => Column(
            spacing: gap,
            children: [
              for (var r = 0; r < rows; r++)
                Row(
                  spacing: gap,
                  children: [
                    for (var c = 0; c < 7; c++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final n = r * 7 + c - lead + 1;
                            if (n < 1 || n > days) {
                              return SizedBox(height: cell);
                            }
                            final day = DateTime(now.year, now.month, n);
                            final today = n == now.day;
                            // Real: the share of the day's goals met, in four
                            // steps (all met = full green). Before any record,
                            // a stable pseudo-random preview rolls across the
                            // month in a wave.
                            final share = scores != null
                                ? (scores[n] ?? 0)
                                : ((n * 37) % 10) / 10 * wave(-n * .015);
                            final fill =
                                (share * 4).floorToDouble().clamp(0.0, 4.0) / 4;
                            return Semantics(
                              label: context.displayDate(day),
                              selected: today,
                              excludeSemantics: true,
                              child: Container(
                                height: cell,
                                decoration: ShapeDecoration(
                                  color: Color.lerp(
                                    context.tf.soft,
                                    green,
                                    fill,
                                  ),
                                  shape: RoundedSuperellipseBorder(
                                    borderRadius: BorderRadius.circular(
                                      cell * .32,
                                    ),
                                    side: today
                                        ? BorderSide(color: green, width: 1.5)
                                        : BorderSide.none,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Widget? background;
  const _Card({required this.child, this.background});
  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(22),
    child: ColoredBox(
      color: context.tf.surface,
      child: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          Padding(
            padding: EdgeInsets.all(_compact(context) ? 10 : 14),
            child: child,
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  final Widget leading;
  final String value, label;
  const _Stat({
    required this.leading,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      leading,
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: context.tf.muted),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Small extends StatelessWidget {
  final IconData icon;
  final String? value;
  final String label;
  final double iconScale;
  final Color? iconColor;
  const _Small({
    required this.icon,
    required this.label,
    this.value,
    this.iconScale = 1,
    this.iconColor,
  });
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Same height for the three cards, whatever they hold.
    constraints: BoxConstraints(minHeight: _compact(context) ? 60 : 74),
    child: Stack(
      children: [
        // Icon in the top right corner (the card padding keeps it off the
        // edge).
        Align(
          alignment: Alignment.topRight,
          child: Transform.scale(
            scale: iconScale,
            child: Icon(icon, size: 22, color: iconColor ?? context.tf.primary),
          ),
        ),
        // The number in the very middle of the card.
        if (value != null)
          Positioned.fill(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        // What it is, centred at the bottom.
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: context.tf.muted),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Ring extends CustomPainter {
  final double value;
  final Color track, color;
  const _Ring({required this.value, required this.track, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .16;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring old) =>
      old.value != value || old.color != color || old.track != track;
}

/// The streak fire: always flickering, and as big and bright as the streak.
/// At zero it is a faint flame going out; a week or more is a full fire with
/// a warm glow.
class _Flame extends StatelessWidget {
  final int days;

  /// Loop position (0 to 1); whole-number frequencies keep the loop seamless.
  final double t;
  const _Flame({required this.days, required this.t});

  @override
  Widget build(BuildContext context) {
    final (icon, size, amp, alpha) = switch (days) {
      0 => (Icons.local_fire_department_outlined, 24.0, .05, .65),
      1 || 2 => (Icons.local_fire_department_outlined, 28.0, .08, 1.0),
      < 7 => (Icons.local_fire_department, 30.0, .1, 1.0),
      _ => (Icons.local_fire_department, 34.0, .13, 1.0),
    };
    double sin(int k, [double phase = 0]) =>
        math.sin(t * math.pi * 2 * k + phase);
    // Going out: the light dips now and then.
    final dim = days == 0 ? .75 + .25 * sin(3) : 1.0;
    final flame = Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..rotateZ(.06 * sin(4, 1))
        ..scaleByDouble(
          1 - amp * .5 * sin(7, 2),
          1 + amp * sin(5) + amp * .5 * sin(9, 1),
          1,
          1,
        ),
      child: Icon(
        icon,
        size: size,
        color: TrainForgeTheme.highlight.withValues(alpha: alpha * dim),
      ),
    );
    return SizedBox.square(
      dimension: 34,
      child: Center(
        child: days >= 7
            ? DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TrainForgeTheme.highlight.withValues(
                        alpha: .25 + .1 * sin(5),
                      ),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: flame,
              )
            : flame,
      ),
    );
  }
}

/// Water filling its card: two soft sine waves drifting across the surface
/// (the back one lighter), rising to [level] of the height.
class _Water extends CustomPainter {
  final double level, phase;
  final Color color;
  const _Water({required this.level, required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final top = size.height * (1 - level);
    Path wave(double amp, int cycles, double shift) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 2) {
        final y =
            top +
            amp *
                math.sin(
                  (x / size.width * cycles + phase * 2 + shift) * math.pi * 2,
                );
        path.lineTo(x, y);
      }
      return path
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(
      wave(7, 1, .5),
      Paint()..color = color.withValues(alpha: .35),
    );
    canvas.drawPath(
      wave(6, 1, 0),
      Paint()..color = color.withValues(alpha: .6),
    );
  }

  @override
  bool shouldRepaint(_Water old) =>
      old.level != level || old.phase != phase || old.color != color;
}

/// Phones shorter than 800 points (the page must still fit without scrolling).
bool _compact(BuildContext context) => MediaQuery.sizeOf(context).height < 800;
