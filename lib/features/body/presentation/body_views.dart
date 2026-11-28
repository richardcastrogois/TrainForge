import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/body/domain/body.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/main_action.dart';
import 'package:trainforge/shared/widgets/shell_labels.dart';

/// Body data needs the health-data consent, like height and weight in the
/// first questions.
bool bodyAllowed(BuildContext context) {
  final scope = OnboardingScope.maybeOf(context);
  if (scope == null) return false;
  return LegalScope.maybeOf(context)?.healthGranted(scope.accountId) == true;
}

String _kg(BuildContext context, double kg) => NumberFormat(
  '0.0',
  Localizations.localeOf(context).toLanguageTag(),
).format(kg);

String _signed(BuildContext context, double kg) {
  final r = (kg * 10).round() / 10;
  final sign = r > 0
      ? '+'
      : r < 0
      ? '−'
      : '';
  return '$sign${_kg(context, r.abs())}';
}

/// "Quanto você pesa hoje?": starts at the last weight, ±0,1 kg buttons, a
/// ruler to drag and the day (today or another).
Future<void> showWeighIn(BuildContext context) {
  final scope = OnboardingScope.maybeOf(context);
  if (scope == null) return Future.value();
  final profile = scope.profile;
  final start = profile?.weighIns.isNotEmpty == true
      ? profile!.weighIns.last.kg
      : (profile?.weightKg ?? 70).toDouble();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WeighInSheet(start: start, save: scope.saveWeighIn),
  );
}

class _WeighInSheet extends StatefulWidget {
  final double start;
  final Future<void> Function(WeighIn entry) save;
  const _WeighInSheet({required this.start, required this.save});
  @override
  State<_WeighInSheet> createState() => _WeighInSheetState();
}

class _WeighInSheetState extends State<_WeighInSheet> {
  late double kg = widget.start;
  DateTime? day;
  double drag = 0;

  void nudge(double by) => setState(
    () => kg = double.parse(
      (kg + by).clamp(WeighIn.minKg, WeighIn.maxKg).toStringAsFixed(1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final today = DateTime.now();
    final picked = day;
    Widget step(IconData icon, double by, String label) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: context.tf.soft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => nudge(by),
          child: SizedBox.square(
            dimension: 52,
            child: Icon(icon, color: context.tf.primary, size: 26),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l('weighQuestion'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              step(Icons.remove, -.1, l('weighLess')),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _kg(context, kg),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          TextSpan(
                            text: ' kg',
                            style: TextStyle(
                              fontSize: 16,
                              color: context.tf.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              step(Icons.add, .1, l('weighMore')),
            ],
          ),
          const SizedBox(height: 12),
          // Drag sideways: every 10 px is 0,1 kg.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              drag -= d.delta.dx;
              while (drag.abs() >= 10) {
                nudge(drag > 0 ? .1 : -.1);
                drag -= drag > 0 ? 10 : -10;
              }
            },
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _Ruler(
                  offset: (kg * 100) % 100,
                  tick: context.tf.primary,
                  fill: context.tf.soft,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l('weighToday')),
                selected: picked == null,
                onSelected: (_) => setState(() => day = null),
              ),
              ChoiceChip(
                label: Text(
                  picked == null
                      ? l('weighOtherDay')
                      : MaterialLocalizations.of(
                          context,
                        ).formatShortDate(picked),
                ),
                selected: picked != null,
                onSelected: (_) async {
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: picked ?? today,
                    firstDate: DateTime(today.year - 5),
                    lastDate: today,
                  );
                  if (chosen != null && mounted) setState(() => day = chosen);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l('weighTip'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.tf.muted),
          ),
          const SizedBox(height: 14),
          MainAction(
            label: l('bottleSave'),
            icon: Icons.check,
            height: 50,
            onPressed: () async {
              await widget.save(WeighIn(day ?? today, kg));
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _Ruler extends CustomPainter {
  final double offset;
  final Color tick, fill;
  const _Ruler({required this.offset, required this.tick, required this.fill});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = fill,
    );
    final paint = Paint()
      ..color = tick.withValues(alpha: .4)
      ..strokeWidth = 1.5;
    final shift = (offset % 10) / 10 * 10;
    for (var x = -shift; x < size.width; x += 10) {
      final long = ((x + shift) / 10).round() % 5 == 0;
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (long ? .35 : .6)),
        paint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 3,
          height: size.height - 8,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = TrainForgeTheme.highlight,
    );
  }

  @override
  bool shouldRepaint(_Ruler old) => old.offset != offset;
}

/// Evolução's "Corpo": current weight, change in the week, the line of the
/// last weeks and the BMI band. Opens the body page; without a weigh-in it
/// invites the first one. Hidden without health-data consent.
class BodyCard extends StatelessWidget {
  const BodyCard({super.key});
  @override
  Widget build(BuildContext context) {
    if (!bodyAllowed(context)) return const SizedBox.shrink();
    String l(String k) => shellLabel(context, k);
    final scope = OnboardingScope.maybeOf(context)!;
    final profile = scope.profile;
    final all = profile?.weighIns ?? const <WeighIn>[];
    final weeks = weeklyAverages(all);
    final now = DateTime.now();
    final due = (profile?.weighReminder ?? true) && weighInDue(all, now);
    final last = all.isEmpty ? null : all.last;
    final index = last == null ? null : bmi(last.kg, profile?.heightCm);
    final change = weeks.length < 2
        ? null
        : weeks.last.kg - weeks[weeks.length - 2].kg;
    return _Panel(
      onTap: () => openBody(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: context.tf.primary),
              const SizedBox(width: 8),
              Text(
                l('bodyTitle'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (due && last != null)
                _Chip(l('weighDue'), orange: true)
              else if (last != null)
                Flexible(
                  child: Text(
                    MaterialLocalizations.of(context).formatShortDate(last.day),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: context.tf.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (last == null) ...[
            Text(
              l('bodyEmpty'),
              style: TextStyle(fontSize: 12.5, color: context.tf.muted),
            ),
            const SizedBox(height: 10),
            MainAction(
              label: l('weighRecord'),
              icon: Icons.add,
              height: 46,
              onPressed: () => showWeighIn(context),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _KgCount(last.kg, size: 30),
                      ),
                      if (change != null)
                        _Chip(
                          '${_signed(context, change)} kg ${l('bodyInWeek')}',
                          orange: change > 0,
                        ),
                      if (index != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'IMC',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.tf.muted,
                              ),
                            ),
                            Text(
                              _kg(context, index),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            _Chip(l('bmi_${BmiBand.of(index).name}')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (weeks.length >= 2)
                  SizedBox(
                    width: 120,
                    height: 56,
                    child: _WeekLine(weeks: weeks, spark: true),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Opens the body page with the same answers in scope (routes sit above
/// the signed-in tree).
void openBody(BuildContext context) {
  final scope = OnboardingScope.maybeOf(context);
  final legal = LegalScope.maybeOf(context);
  if (scope == null) return;
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) {
        Widget page = OnboardingScope(
          controller: scope.notifier!,
          accountId: scope.accountId,
          child: const BodyPage(),
        );
        if (legal != null) {
          page = LegalScope(controller: legal, child: page);
        }
        return page;
      },
    ),
  );
}

/// "Corpo": weekly average and its change, the 8-week line (each weigh-in a
/// faint dot, the week's average on the line), the BMI band, "Registrar
/// peso", the weekly reminder and the list of weeks.
class BodyPage extends StatelessWidget {
  const BodyPage({super.key});
  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final scope = OnboardingScope.maybeOf(context);
    final profile = scope?.profile;
    final all = profile?.weighIns ?? const <WeighIn>[];
    final weeks = weeklyAverages(all);
    final recent = weeks.length > 8 ? weeks.sublist(weeks.length - 8) : weeks;
    final last = all.isEmpty ? null : all.last;
    final index = last == null ? null : bmi(last.kg, profile?.heightCm);
    final muted = TextStyle(fontSize: 12, color: context.tf.muted);
    return FigmaRouteFrame(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(
            l('bodyTitle'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (weeks.isEmpty)
                  Text(l('bodyEmpty'), style: muted)
                else ...[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l('bodyWeekAverage'), style: muted),
                          _KgCount(weeks.last.kg, size: 32),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (weeks.length >= 2)
                            _Chip(
                              '${_signed(context, weeks.last.kg - weeks[weeks.length - 2].kg)} kg',
                              orange:
                                  weeks.last.kg > weeks[weeks.length - 2].kg,
                            ),
                          if (recent.length >= 2)
                            Text(
                              '${_signed(context, recent.last.kg - recent.first.kg)} kg '
                              '${l('bodyInWeeks').replaceAll('{n}', '${recent.length}')}',
                              style: muted,
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (recent.length >= 2) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: _WeekLine(
                        weeks: recent,
                        points: [
                          for (final w in all)
                            if (!w.day.isBefore(recent.first.monday)) w,
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (index != null) ...[
            const SizedBox(height: 12),
            _Panel(child: _BmiBlock(value: index)),
          ] else if (last != null) ...[
            const SizedBox(height: 12),
            _Panel(child: Text(l('bmiNeedHeight'), style: muted)),
          ],
          const SizedBox(height: 14),
          MainAction(
            label: l('weighRecord'),
            icon: Icons.add,
            onPressed: () => showWeighIn(context),
          ),
          const SizedBox(height: 12),
          _Panel(
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none,
                  color: TrainForgeTheme.highlight,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l('weighReminder'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(l('weighReminderHint'), style: muted),
                    ],
                  ),
                ),
                Switch(
                  value: profile?.weighReminder ?? true,
                  onChanged: scope?.saveWeighReminder,
                ),
              ],
            ),
          ),
          if (weeks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l('bodyWeeks'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final (i, w) in weeks.reversed.take(12).indexed) ...[
                    if (i > 0) Divider(height: 1, color: context.tf.soft),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l('bodyWeekOf').replaceAll(
                                    '{d}',
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatShortMonthDay(w.monday),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${_kg(context, w.kg)} kg · ${l(w.count == 1 ? 'bodyCountOne' : 'bodyCount').replaceAll('{n}', '${w.count}')}',
                                  style: muted,
                                ),
                              ],
                            ),
                          ),
                          if (weeks.length - 1 - i > 0)
                            Builder(
                              builder: (context) {
                                final before = weeks[weeks.length - 2 - i].kg;
                                return _Chip(
                                  _signed(context, w.kg - before),
                                  orange: w.kg > before,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(l('bodySourceNote'), style: muted),
        ],
      ),
    );
  }
}

class _BmiBlock extends StatelessWidget {
  final double value;
  const _BmiBlock({required this.value});
  static const lo = 15.0, hi = 35.0;
  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final band = BmiBand.of(value);
    final at = ((value - lo) / (hi - lo)).clamp(0.0, 1.0);
    const colors = [
      Color(0xffcfe0f3),
      Color(0xff9fc9a8),
      Color(0xffffd7b5),
      Color(0xfff6b39a),
    ];
    const cuts = [lo, 18.5, 25.0, 30.0, hi];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'IMC',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              _kg(context, value),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            _Chip(l('bmi_${band.name}')),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 3,
                    height: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Expanded(
                              flex: ((cuts[i + 1] - cuts[i]) * 10).round(),
                              child: Container(color: colors[i]),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? at : 0, end: at),
                    duration: still
                        ? Duration.zero
                        : const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Positioned(
                      left: v * w - 9,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: TrainForgeTheme.highlight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.tf.surface,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final c in cuts)
                    Positioned(
                      top: 24,
                      left: ((c - lo) / (hi - lo)) * w - 14,
                      width: 28,
                      child: Text(
                        NumberFormat(
                          '0.#',
                          Localizations.localeOf(context).toLanguageTag(),
                        ).format(c),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: context.tf.muted),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Text(
          l('bmiNote'),
          style: TextStyle(fontSize: 11.5, color: context.tf.muted),
        ),
      ],
    );
  }
}

/// A weight that counts to its value with one decimal.
class _KgCount extends StatelessWidget {
  final double kg;
  final double size;
  const _KgCount(this.kg, {required this.size});
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? kg : kg + 2, end: kg),
      duration: still ? Duration.zero : const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _kg(context, v),
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            TextSpan(
              text: ' kg',
              style: TextStyle(fontSize: 13, color: context.tf.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weekly averages as a line drawn from left to right, the last week in
/// orange; [points] adds each weigh-in as a faint dot. [spark] is the
/// small version without labels.
class _WeekLine extends StatelessWidget {
  final List<WeekAverage> weeks;
  final List<WeighIn> points;
  final bool spark;
  const _WeekLine({
    required this.weeks,
    this.points = const [],
    this.spark = false,
  });
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : const Duration(milliseconds: 1700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(
          weeks: weeks,
          points: points,
          spark: spark,
          t: t,
          green: context.tf.primary,
          grid: context.tf.soft,
          label: context.tf.muted,
          surface: context.tf.surface,
          locale: Localizations.localeOf(context).toLanguageTag(),
          font: DefaultTextStyle.of(context).style.fontFamily,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<WeekAverage> weeks;
  final List<WeighIn> points;
  final bool spark;
  final double t;
  final Color green, grid, label, surface;
  final String locale;
  final String? font;
  const _LinePainter({
    this.font,
    required this.weeks,
    required this.points,
    required this.spark,
    required this.t,
    required this.green,
    required this.grid,
    required this.label,
    required this.surface,
    required this.locale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.length < 2) return;
    final values = [for (final w in weeks) w.kg, for (final p in points) p.kg];
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    if (hi - lo < 1) {
      final mid = (hi + lo) / 2;
      lo = mid - .5;
      hi = mid + .5;
    }
    final pad = (hi - lo) * .15;
    lo -= pad;
    hi += pad;
    final left = spark ? 4.0 : 30.0, right = size.width - 8;
    final top = 8.0, bottom = size.height - (spark ? 6 : 20);
    final first = weeks.first.monday;
    final span = weeks.last.monday.difference(first).inDays.clamp(1, 1 << 30);
    double x(DateTime d) =>
        (left + (right - left) * d.difference(first).inDays / span).clamp(
          left,
          right,
        );
    double y(double v) => bottom - (bottom - top) * (v - lo) / (hi - lo);
    final text = TextPainter(textDirection: TextDirection.ltr);
    if (!spark) {
      final step = hi - lo > 6 ? 2 : 1;
      for (var v = lo.ceil(); v <= hi; v += step) {
        canvas.drawLine(
          Offset(left, y(v.toDouble())),
          Offset(right, y(v.toDouble())),
          Paint()..color = grid,
        );
        text
          ..text = TextSpan(
            text: '$v',
            style: TextStyle(fontSize: 10, color: label, fontFamily: font),
          )
          ..layout();
        text.paint(canvas, Offset(0, y(v.toDouble()) - 6));
      }
      final date = DateFormat.Md(locale);
      for (final w in [weeks.first, weeks.last]) {
        text
          ..text = TextSpan(
            text: date.format(w.monday),
            style: TextStyle(fontSize: 10, color: label, fontFamily: font),
          )
          ..layout();
        text.paint(
          canvas,
          Offset(
            (x(w.monday) - text.width / 2).clamp(0, size.width - text.width),
            size.height - 13,
          ),
        );
      }
      for (final p in points) {
        canvas.drawCircle(
          Offset(x(p.day), y(p.kg)),
          2.6,
          Paint()..color = green.withValues(alpha: .28 * t),
        );
      }
    }
    final path = Path();
    for (final (i, w) in weeks.indexed) {
      final o = Offset(x(w.monday), y(w.kg));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * t);
    if (spark) {
      final area = Path.from(drawn)
        ..lineTo(
          metric.getTangentForOffset(metric.length * t)!.position.dx,
          bottom,
        )
        ..lineTo(left, bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [green.withValues(alpha: .22), green.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(left, top, right, bottom)),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spark ? 2.5 : 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = green,
    );
    for (final (i, w) in weeks.indexed) {
      final share = weeks.length == 1 ? 1.0 : i / (weeks.length - 1);
      if (share > t + .001) break;
      final o = Offset(x(w.monday), y(w.kg));
      final lastOne = i == weeks.length - 1;
      if (!spark || lastOne) {
        canvas.drawCircle(
          o,
          lastOne ? 5.5 : 3.6,
          Paint()..color = lastOne ? TrainForgeTheme.highlight : surface,
        );
        if (!lastOne) {
          canvas.drawCircle(
            o,
            3.6,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = green,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t || old.weeks != weeks || old.points != points;
}

class _Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Panel({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: context.tf.surface,
    shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String text;
  final bool orange;
  const _Chip(this.text, {this.orange = false});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: orange
          ? TrainForgeTheme.highlight.withValues(alpha: .16)
          : context.tf.soft,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: orange ? const Color(0xffb4520f) : context.tf.primary,
      ),
    ),
  );
}
