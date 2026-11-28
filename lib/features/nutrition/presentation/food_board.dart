import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/food_reference/presentation/food_labels.dart';
import 'package:trainforge/features/nutrition/domain/day_meals.dart';
import 'package:trainforge/features/nutrition/domain/food_goals.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/features/nutrition/presentation/hydration_card.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/shared/widgets/glass_surface.dart';
import 'package:trainforge/shared/widgets/shell_labels.dart';

/// The food page: the goal (asked once, then shown as the day's targets),
/// the day's rings (meals outside, water inside), water in drops, one
/// orange "Registrar refeição" and the ways to record (talk, photo, search).
class FoodBoard extends StatefulWidget {
  final DailySummaryController controller;

  /// The offline diary: water and the meals of the day are read from it.
  final NutritionRepository? diary;
  final VoidCallback openNutrition;
  final VoidCallback? openVoice, openPhoto;
  const FoodBoard({
    super.key,
    required this.controller,
    required this.diary,
    required this.openNutrition,
    this.openVoice,
    this.openPhoto,
  });

  @override
  State<FoodBoard> createState() => _FoodBoardState();
}

class _FoodBoardState extends State<FoodBoard>
    with SingleTickerProviderStateMixin {
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  bool _started = false, choosing = false;
  int? meals, water;
  List<DayMeal> dayMeals = const [];
  Json? _seenSummary;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_summaryChanged);
    loadMeals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_summaryChanged);
    loop.dispose();
    super.dispose();
  }

  void _summaryChanged() {
    if (identical(_seenSummary, widget.controller.summary)) return;
    _seenSummary = widget.controller.summary;
    loadMeals();
  }

  /// Meals of today: food (not water) recorded within an hour of each other
  /// counts as one meal.
  Future<void> loadMeals() async {
    final repository = widget.diary;
    if (repository == null) return;
    final now = widget.controller.now();
    final items = <Json>[];
    String? cursor;
    try {
      do {
        final page = await repository.entries(
          localDay(now),
          offsetZone(now),
          cursor: cursor,
        );
        items.addAll(page.items);
        cursor = page.cursor;
      } while (cursor != null);
    } catch (_) {
      return;
    }
    final grouped = groupMeals(items, waterId: waterFoodId);
    if (mounted) {
      setState(() {
        dayMeals = grouped;
        meals = grouped.length;
      });
    }
  }

  /// 0 → 1 → 0 over one loop (still when motion is reduced).
  double wave([double shift = 0]) {
    if (!loop.isAnimating) return 0;
    final v = (loop.value + shift) % 1;
    return Curves.easeInOutSine.transform(v < .5 ? v * 2 : (1 - v) * 2);
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final scope = OnboardingScope.maybeOf(context);
    final profile = scope?.profile;
    final goal = FoodGoal.fromId(profile?.foodGoal);
    final summary = widget.controller.summary;
    final kcal = dailyEnergy(summary);
    final protein = _protein(summary);
    final mealTarget = goal?.meals ?? 4;
    final waterGoal = goal == null ? null : FoodGoal.waterMl(profile?.gender);
    final proteinGoal = goal?.proteinGrams(profile?.weightKg);
    final compact = MediaQuery.sizeOf(context).height < 800;
    final space = compact ? 8.0 : 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goal == null || choosing)
          _goals(context, l, scope, goal)
        else
          _Card(
            border: context.tf.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 18,
                      color: context.tf.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${l('foodGoalTitle')} · ${l('goal_${goal.id}')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => choosing = true),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l('foodGoalChange')),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Progress(
                        label: l('foodProtein'),
                        value: protein == null ? '—' : '$protein',
                        // The protein target needs the weight from the
                        // first questions.
                        target: proteinGoal == null
                            ? l('foodNeedWeight')
                            : '$proteinGoal g',
                        share: protein == null || proteinGoal == null
                            ? 0
                            : protein / proteinGoal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      // No energy target yet (it needs age and activity):
                      // today's total only.
                      child: _Progress(
                        label: l('foodEnergy'),
                        value: kcal ?? '0',
                        target: null,
                        unit: l('foodEnergyToday'),
                        share: null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: space),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 23,
                child: Semantics(
                  button: true,
                  label:
                      '${meals ?? 0}/$mealTarget ${l('foodMeals')}, ${water ?? 0} ml',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.openNutrition,
                    child: _Card(
                      child: Column(
                        children: [
                          SizedBox.square(
                            dimension: compact ? 100 : 112,
                            child: AnimatedBuilder(
                              animation: loop,
                              builder: (context, _) => CustomPaint(
                                painter: _Rings(
                                  meals: meals ?? 0,
                                  target: mealTarget,
                                  water: waterGoal == null || water == null
                                      ? null
                                      : water! / waterGoal,
                                  pulse: [
                                    for (var i = 0; i < mealTarget; i++)
                                      wave(-i * .12),
                                  ],
                                  waterPulse: wave(-.06),
                                  green: context.tf.primary,
                                  track: context.tf.soft,
                                ),
                                // Large text shrinks to stay inside the ring.
                                child: Padding(
                                  padding: const EdgeInsets.all(26),
                                  child: FittedBox(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${meals ?? 0}/$mealTarget',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          l('foodMeals'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.tf.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              children: [
                                _Dot(context.tf.primary),
                                Text(
                                  ' ${l('foodMeals')}   ',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const _Dot(_waterBlue),
                                Text(
                                  ' ${l('foodWater')}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: space),
              Expanded(
                flex: 20,
                child: _Card(
                  child: widget.diary == null
                      ? const SizedBox.shrink()
                      : HydrationCard(
                          repository: widget.diary!,
                          compact: true,
                          goalMl: waterGoal,
                          changed: widget.controller.load,
                          onTotal: (ml) {
                            if (mounted) setState(() => water = ml);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space + 4),
        // The one orange block of the page; a slow glow breathes around it.
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
            label: l('foodRecord'),
            color: TrainForgeTheme.highlight,
            foreground: TrainForgeTheme.ink,
            height: compact ? 48 : 56,
            onPressed: widget.openNutrition,
          ),
        ),
        SizedBox(height: space),
        Row(
          spacing: space,
          children: [
            if (widget.openVoice != null)
              Expanded(
                child: _Way(
                  icon: Icons.mic_none,
                  label: l('foodTalk'),
                  onTap: widget.openVoice!,
                ),
              ),
            if (widget.openPhoto != null)
              Expanded(
                child: _Way(
                  icon: Icons.photo_camera_outlined,
                  label: l('foodPhoto'),
                  onTap: widget.openPhoto!,
                ),
              ),
            Expanded(
              child: _Way(
                icon: Icons.search,
                label: l('foodSearch'),
                onTap: widget.openNutrition,
              ),
            ),
          ],
        ),
        if (widget.diary != null) ...[
          SizedBox(height: space),
          _MealsToday(
            meals: dayMeals,
            target: mealTarget,
            now: widget.controller.now(),
            open: widget.openNutrition,
          ),
        ],
      ],
    );
  }

  /// "Qual é o seu objetivo?": six cards like Evolução's small cards.
  Widget _goals(
    BuildContext context,
    String Function(String) l,
    OnboardingScope? scope,
    FoodGoal? current,
  ) {
    const icons = {
      FoodGoal.loseFat: Icons.trending_down,
      FoodGoal.maintain: Icons.balance,
      FoodGoal.gainMuscle: Icons.fitness_center,
      FoodGoal.recomposition: Icons.swap_vert,
      FoodGoal.performance: Icons.directions_run,
      FoodGoal.eatBetter: Icons.eco_outlined,
    };
    final goals = FoodGoal.values;
    final columns = MediaQuery.sizeOf(context).height < 860 ? 3 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l('foodGoalQuestion'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        // Three per row on shorter screens so the page still fits.
        for (var r = 0; r < goals.length; r += columns) ...[
          if (r > 0) const SizedBox(height: 6),
          Row(
            spacing: 6,
            children: [
              for (final goal in goals.sublist(r, r + columns))
                Expanded(
                  child: _GoalCard(
                    tall: columns == 3,
                    icon: icons[goal]!,
                    label: l('goal_${goal.id}'),
                    selected: goal == current,
                    onTap: scope == null
                        ? null
                        : () async {
                            await scope.saveFoodGoal(goal.id);
                            if (mounted) setState(() => choosing = false);
                          },
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          l('foodGoalNote'),
          style: TextStyle(fontSize: 11, height: 1.3, color: context.tf.muted),
        ),
      ],
    );
  }
}

/// Protein of today in grams, only when every entry has it.
int? _protein(Json? summary) {
  if (summary == null || summary['complete'] != true) return null;
  if (summary['entries'] == 0) return 0;
  for (final n in objects(summary['nutrients'])) {
    if (n['nutrientId'] == 'protein_g' &&
        n['unit'] == 'g' &&
        n['value'] != null &&
        n['unknownEntries'] == 0) {
      return double.tryParse('${n['value']}')?.round();
    }
  }
  return null;
}

const _waterBlue = Color(0xff2f7fcf);

class _Card extends StatelessWidget {
  final Widget child;
  final Color? border;
  const _Card({required this.child, this.border});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.tf.surface,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(22),
        side: border == null
            ? BorderSide.none
            : BorderSide(color: border!, width: 1.5),
      ),
    ),
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Room for a name on two lines (three cards per row).
  final bool tall;
  const _GoalCard({
    this.tall = false,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: context.tf.surface,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? context.tf.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        customBorder: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tall ? 64 : 46),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 7),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(icon, size: 17, color: context.tf.primary),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  final String label, value;
  final String? target, unit;

  /// Share of the target reached; null shows no bar.
  final double? share;
  const _Progress({
    required this.label,
    required this.value,
    required this.target,
    required this.share,
    this.unit,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: context.tf.muted)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (target != null || unit != null)
                TextSpan(
                  text: target != null ? ' / $target' : ' $unit',
                  style: TextStyle(fontSize: 11, color: context.tf.muted),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      if (share != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 5,
            child: LinearProgressIndicator(
              value: (share ?? 0).clamp(0.0, 1.0),
              backgroundColor: context.tf.soft,
              color: context.tf.primary,
            ),
          ),
        ),
    ],
  );
}

class _Way extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Way({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Material(
      color: context.tf.surface,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        customBorder: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: context.tf.primary),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// Outer ring: one slice per planned meal, solid once eaten (a soft pulse
/// previews the empty ones). Inner ring: water, as the share of the goal.
class _Rings extends CustomPainter {
  final int meals, target;
  final double? water;
  final List<double> pulse;
  final double waterPulse;
  final Color green, track;
  const _Rings({
    required this.meals,
    required this.target,
    required this.water,
    required this.pulse,
    required this.waterPulse,
    required this.green,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .1;
    final gap = .07;
    final slice = math.pi * 2 / target;
    for (var i = 0; i < target; i++) {
      final done = i < meals;
      final alpha = done ? 1.0 : .14 + .5 * (meals == 0 ? pulse[i] : 0);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: outer),
        -math.pi / 2 + i * slice + gap / 2,
        slice - gap,
        false,
        paint..color = done ? green : Color.lerp(track, green, alpha)!,
      );
    }
    final inner = outer - size.width * .14;
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .065
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: c, radius: inner);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      thin..color = _waterBlue.withValues(alpha: .14),
    );
    final share = water == null || water == 0
        ? .25 * waterPulse
        : water!.clamp(0.0, 1.0);
    if (share > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * share,
        false,
        thin
          ..color = _waterBlue.withValues(
            alpha: water == null || water == 0 ? .5 : 1,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_Rings old) => true;
}

/// "Refeições de hoje": one row per meal (name by the time of day, time,
/// what was eaten, kcal) and, while meals are missing, when the next fits.
class _MealsToday extends StatelessWidget {
  final List<DayMeal> meals;
  final int target;
  final DateTime now;
  final VoidCallback open;
  const _MealsToday({
    required this.meals,
    required this.target,
    required this.now,
    required this.open,
  });

  static const _icons = {
    'breakfast': Icons.free_breakfast_outlined,
    'morningSnack': Icons.apple,
    'lunch': Icons.restaurant,
    'afternoonSnack': Icons.cookie_outlined,
    'dinner': Icons.dinner_dining_outlined,
    'supper': Icons.nightlight_outlined,
  };

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final locale = foodContentLocale(context);
    String time(DateTime at) =>
        MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(at.toLocal()),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
    final energy = [for (final m in meals) m.kcal];
    final total = meals.isEmpty || energy.contains(null)
        ? null
        : energy.fold<double>(0, (a, b) => a + b!).round();
    final next = nextMeal(meals, target);
    final muted = TextStyle(fontSize: 11.5, color: context.tf.muted);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l('mealsToday'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${meals.length} ${l('mealsOf')} $target'
                '${total == null ? '' : ' · $total kcal'}',
                style: muted,
              ),
            ],
          ),
          if (meals.isEmpty) ...[
            const SizedBox(height: 12),
            Row(
              spacing: 6,
              children: [
                for (var i = 0; i < target; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.tf.soft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l('mealsEmpty'), textAlign: TextAlign.center, style: muted),
          ],
          for (final (i, meal) in meals.indexed) ...[
            if (i > 0) Divider(height: 1, color: context.tf.soft),
            InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _Round(
                      icon: _icons[meal.slot]!,
                      fill: context.tf.soft,
                      color: context.tf.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l('meal_${meal.slot}'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${time(meal.start)} · '
                            '${meal.entries.map((e) => entryDisplayName(e, locale)).join(', ')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    if (meal.kcal != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${meal.kcal!.round()} kcal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.tf.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (next != null) ...[
            Divider(height: 1, color: context.tf.soft),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _Round(
                    icon: Icons.schedule,
                    fill: Colors.transparent,
                    color: context.tf.muted,
                    outlined: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.isAfter(now)
                              ? '${l('mealsNext')} ${time(next)}'
                              : l('mealsNow'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.tf.muted,
                          ),
                        ),
                        Text(l('mealsEvery'), style: muted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  final IconData icon;
  final Color fill, color;
  final bool outlined;
  const _Round({
    required this.icon,
    required this.fill,
    required this.color,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: outlined ? Border.all(color: color.withValues(alpha: .5)) : null,
    ),
    child: Icon(icon, size: 17, color: color),
  );
}
