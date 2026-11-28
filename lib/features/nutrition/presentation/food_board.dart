import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/food_reference/presentation/food_labels.dart';
import 'package:trainforge/features/nutrition/domain/day_meals.dart';
import 'package:trainforge/features/nutrition/domain/food_goals.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/features/nutrition/presentation/hydration_card.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/shared/widgets/main_action.dart';
import 'package:trainforge/shared/widgets/shell_labels.dart';

/// The food page. Without a goal (or while changing it): a carousel that
/// explains each goal, a preview of the day it gives and "Escolher". With
/// one: the day card (goal, meals ring, water bottle, protein, energy and
/// the water buttons), the green "Registrar refeição", the ways to record
/// and today's meals. Everything moves lightly while the page is open and
/// stays still when motion is reduced.
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

/// Bottle size until the person sets their own.
const defaultBottleMl = 500;

/// One glass, as written on "+ Copo".
const glassMl = 200;

class _FoodBoardState extends State<FoodBoard>
    with SingleTickerProviderStateMixin {
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  bool _started = false, choosing = false;
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
    if (mounted) setState(() => dayMeals = grouped);
  }

  @override
  Widget build(BuildContext context) {
    final scope = OnboardingScope.maybeOf(context);
    final profile = scope?.profile;
    final goal = FoodGoal.fromId(profile?.foodGoal);
    if (goal == null || choosing) {
      return _GoalPicker(
        initial: goal ?? FoodGoal.gainMuscle,
        weightKg: profile?.weightKg,
        gender: profile?.gender,
        loop: loop,
        onCancel: goal == null ? null : () => setState(() => choosing = false),
        onChoose: scope == null
            ? null
            : (picked) async {
                await scope.saveFoodGoal(picked.id);
                if (mounted) setState(() => choosing = false);
              },
      );
    }
    return _day(context, scope, profile, goal);
  }

  Widget _day(
    BuildContext context,
    OnboardingScope? scope,
    OnboardingProfile? profile,
    FoodGoal goal,
  ) {
    String l(String k) => shellLabel(context, k);
    final summary = widget.controller.summary;
    final kcal = double.tryParse(
      (dailyEnergy(summary) ?? '0').replaceAll(',', '.'),
    );
    final protein = _protein(summary);
    final proteinGoal = goal.proteinGrams(profile?.weightKg);
    final waterGoal = FoodGoal.waterMl(profile?.gender);
    final bottle = profile?.bottleMl ?? defaultBottleMl;
    final compact = MediaQuery.sizeOf(context).height < 800;
    final space = compact ? 8.0 : 10.0;
    Widget card(int? total, ValueChanged<int>? add) => _DayCard(
      loop: loop,
      goal: goal,
      meals: dayMeals,
      water: total,
      waterGoal: waterGoal,
      protein: protein,
      proteinGoal: proteinGoal,
      kcal: kcal,
      bottleMl: bottle,
      add: add,
      openMeals: widget.openNutrition,
      onAdjust: () => setState(() => choosing = true),
      onBottle: scope == null
          ? null
          : () => _editBottle(context, bottle, scope.saveBottleMl),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Enter(
          child: widget.diary == null
              ? card(null, null)
              : HydrationCard(
                  repository: widget.diary!,
                  changed: widget.controller.load,
                  builder: (context, total, add) => card(total, add),
                ),
        ),
        SizedBox(height: space + 4),
        _Enter(
          delay: 1,
          child: MainAction(
            label: l('foodRecord'),
            icon: Icons.add,
            height: compact ? 50 : 56,
            onPressed: widget.openNutrition,
          ),
        ),
        SizedBox(height: space),
        _Enter(
          delay: 2,
          child: Row(
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
        ),
        if (widget.diary != null) ...[
          SizedBox(height: space),
          _Enter(
            delay: 3,
            child: _MealsToday(
              meals: dayMeals,
              target: goal.meals,
              now: widget.controller.now(),
              open: widget.openNutrition,
            ),
          ),
        ],
      ],
    );
  }
}

/// "Quanto cabe na sua garrafa?": four common sizes or another value.
Future<void> _editBottle(
  BuildContext context,
  int current,
  Future<void> Function(int ml) save,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _BottleSheet(current: current, save: save),
);

class _BottleSheet extends StatefulWidget {
  final int current;
  final Future<void> Function(int ml) save;
  const _BottleSheet({required this.current, required this.save});
  @override
  State<_BottleSheet> createState() => _BottleSheetState();
}

class _BottleSheetState extends State<_BottleSheet> {
  static const sizes = [350, 500, 750, 1000];
  late int picked = widget.current;
  late final other = TextEditingController(
    text: sizes.contains(widget.current) ? '' : '${widget.current}',
  );
  String? error;

  @override
  void dispose() {
    other.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final typed = other.text.trim();
    final ml = typed.isEmpty ? picked : int.tryParse(typed);
    if (ml == null ||
        ml < OnboardingProfile.bottleMin ||
        ml > OnboardingProfile.bottleMax) {
      setState(() => error = shellLabel(context, 'bottleInvalid'));
      return;
    }
    await widget.save(ml);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
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
            l('bottleQuestion'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ml in sizes)
                ChoiceChip(
                  label: Text(ml == 1000 ? '1 L' : '$ml ml'),
                  selected: picked == ml && other.text.trim().isEmpty,
                  onSelected: (_) => setState(() {
                    picked = ml;
                    other.clear();
                    error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: other,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              labelText: l('bottleOther'),
              suffixText: 'ml',
              errorText: error,
            ),
          ),
          const SizedBox(height: 16),
          MainAction(
            label: l('bottleSave'),
            icon: Icons.check,
            height: 50,
            onPressed: submit,
          ),
        ],
      ),
    );
  }
}

/// Fades and lifts a block in when the page opens (instant when motion is
/// reduced); [delay] staggers the blocks.
class _Enter extends StatelessWidget {
  final Widget child;
  final int delay;
  const _Enter({required this.child, this.delay = 0});
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay * 90),
      curve: Interval(delay * .12, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A whole number that counts up to [value] (still when motion is reduced).
class _Count extends StatelessWidget {
  final num value;
  final TextStyle style;
  const _Count(this.value, {required this.style});
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: still ? Duration.zero : const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format.format(v.round()), style: style),
    );
  }
}

/// 0 → 1 → 0 over one loop (0 when the loop is still).
double _wave(AnimationController loop, [double shift = 0]) {
  if (!loop.isAnimating) return 0;
  final v = (loop.value + shift) % 1;
  return Curves.easeInOutSine.transform(v < .5 ? v * 2 : (1 - v) * 2);
}

const _waterBlue = Color(0xff2f7fcf);
const _waterSoft = Color(0xffdcebf9);

/// Goal, meals ring, water bottle, protein, energy and the water buttons.
class _DayCard extends StatelessWidget {
  final AnimationController loop;
  final FoodGoal goal;
  final List<DayMeal> meals;
  final int? water, protein, proteinGoal;
  final int waterGoal, bottleMl;
  final double? kcal;
  final ValueChanged<int>? add;
  final VoidCallback openMeals, onAdjust;
  final VoidCallback? onBottle;
  const _DayCard({
    required this.loop,
    required this.goal,
    required this.meals,
    required this.water,
    required this.waterGoal,
    required this.protein,
    required this.proteinGoal,
    required this.kcal,
    required this.bottleMl,
    required this.add,
    required this.openMeals,
    required this.onAdjust,
    required this.onBottle,
  });

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final compact = MediaQuery.sizeOf(context).height < 800;
    final ringSize = compact ? 112.0 : 124.0;
    final muted = TextStyle(fontSize: 11.5, color: context.tf.muted);
    final number = const TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w800,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final energy = [
      for (final m in meals)
        if (m.kcal != null && m.kcal! > 0) m.kcal!,
    ];
    return _Card(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: _GoalPill(
                  icon: _goalIcons[goal]!,
                  label: l('goal_${goal.id}'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onAdjust,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l('foodGoalChange')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label:
                      '${meals.length} ${l('mealsOf')} ${goal.meals} '
                      '${l('foodMeals')}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: openMeals,
                    child: Center(
                      child: _MealRing(
                        loop: loop,
                        size: ringSize,
                        share: meals.length / goal.meals,
                        label: '${meals.length} ${l('mealsOf')} ${goal.meals}',
                        sub: l('foodMeals'),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label:
                      '${l('foodWaterTitle')}: ${water ?? 0} / $waterGoal ml',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      SizedBox(
                        width: ringSize * .52,
                        height: ringSize * .86,
                        child: _Bottle(
                          loop: loop,
                          share: (water ?? 0) / waterGoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _Count(
                              water ?? 0,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ' / ${NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag()).format(waterGoal)} ml',
                              style: muted,
                            ),
                          ],
                        ),
                      ),
                      Text(l('foodWaterTitle'), style: muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Measure(
                  label: l('foodProtein'),
                  value: protein,
                  // The target needs the weight from the first questions.
                  target: proteinGoal == null
                      ? l('foodNeedWeight')
                      : '/ $proteinGoal g',
                  number: number,
                  bar: _GrowBar(
                    loop: loop,
                    shares: [
                      if (protein != null && proteinGoal != null)
                        (protein! / proteinGoal!).clamp(0.0, 1.0),
                    ],
                    colors: [context.tf.primary],
                    tip: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                // No energy target yet (it needs age and activity): the bar
                // splits today's kcal by meal.
                child: _Measure(
                  label: l('foodEnergy'),
                  value: kcal?.round(),
                  target: l('foodEnergyToday'),
                  number: number,
                  bar: _GrowBar(
                    loop: loop,
                    shares: [
                      for (final k in energy)
                        k / energy.fold<double>(0, (a, b) => a + b),
                    ],
                    colors: const [
                      Color(0xfff3c9a8),
                      Color(0xffffad73),
                      TrainForgeTheme.highlight,
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WaterButton(
                  label: l('foodGlass'),
                  ml: glassMl,
                  onTap: add == null ? null : () => add!(glassMl),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WaterButton(
                  label: l('foodBottle'),
                  ml: bottleMl,
                  onTap: add == null ? null : () => add!(bottleMl),
                  onEdit: onBottle,
                  editLabel: l('bottleEdit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _goalIcons = {
  FoodGoal.loseFat: Icons.trending_down,
  FoodGoal.maintain: Icons.balance,
  FoodGoal.gainMuscle: Icons.fitness_center,
  FoodGoal.recomposition: Icons.swap_vert,
  FoodGoal.performance: Icons.directions_run,
  FoodGoal.eatBetter: Icons.eco_outlined,
};

const _goalTints = {
  FoodGoal.loseFat: Color(0xffe8eee3),
  FoodGoal.maintain: Color(0xffeaf1fb),
  FoodGoal.gainMuscle: Color(0xffffe9d9),
  FoodGoal.recomposition: Color(0xffeef0e0),
  FoodGoal.performance: Color(0xffe5f3ee),
  FoodGoal.eatBetter: Color(0xfff1f6dc),
};

class _GoalPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GoalPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: TrainForgeTheme.highlight.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xffb4520f)),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xffb4520f),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Measure extends StatelessWidget {
  final String label;
  final int? value;
  final String target;
  final TextStyle number;
  final Widget bar;
  const _Measure({
    required this.label,
    required this.value,
    required this.target,
    required this.number,
    required this.bar,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11.5, color: context.tf.muted)),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            value == null
                ? Text('—', style: number)
                : _Count(value!, style: number),
            Text(
              ' $target',
              style: TextStyle(fontSize: 11.5, color: context.tf.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      bar,
    ],
  );
}

/// A bar that grows to its [shares] (one segment each) with an orange tip
/// that pulses; an empty track when there is nothing yet.
class _GrowBar extends StatelessWidget {
  final AnimationController loop;
  final List<double> shares;
  final List<Color> colors;
  final bool tip;
  const _GrowBar({
    required this.loop,
    required this.shares,
    required this.colors,
    this.tip = false,
  });
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final total = shares.fold<double>(0, (a, b) => a + b).clamp(0.0, 1.0);
    return SizedBox(
      height: 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: total),
        duration: still ? Duration.zero : const Duration(milliseconds: 1300),
        curve: Curves.easeOutCubic,
        builder: (context, grown, _) => LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final scale = total == 0 ? 0.0 : grown / total;
            var x = 0.0;
            final parts = <Widget>[];
            for (var i = 0; i < shares.length; i++) {
              final width = w * shares[i] * scale;
              parts.add(
                Positioned(
                  left: x,
                  top: 2.5,
                  width: width,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
              x += width;
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 2.5,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.tf.soft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                ...parts,
                if (tip && grown > 0)
                  Positioned(
                    left: (x - 6).clamp(0.0, w - 12),
                    top: 0,
                    child: AnimatedBuilder(
                      animation: loop,
                      builder: (context, _) => Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: TrainForgeTheme.highlight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: TrainForgeTheme.highlight.withValues(
                                alpha: .45 * (1 - _wave(loop)),
                              ),
                              spreadRadius: 6 * _wave(loop),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final int ml;
  final VoidCallback? onTap, onEdit;
  final String? editLabel;
  const _WaterButton({
    required this.label,
    required this.ml,
    required this.onTap,
    this.onEdit,
    this.editLabel,
  });
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff1c4f83);
    final volume = ml >= 1000 && ml % 1000 == 0 ? '${ml ~/ 1000} L' : '$ml ml';
    return Material(
      color: _waterSoft.withValues(alpha: .55),
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _waterBlue.withValues(alpha: .25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '$label, $volume',
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        volume,
                        style: const TextStyle(fontSize: 11, color: ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onEdit != null)
            Semantics(
              button: true,
              label: editLabel,
              excludeSemantics: true,
              child: InkWell(
                onTap: onEdit,
                child: const SizedBox(
                  width: 40,
                  height: 50,
                  child: Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: TrainForgeTheme.highlight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Meals of the day as one continuous ring with a green gradient and an
/// orange tip that glows; the count stays in the middle with room around it.
class _MealRing extends StatelessWidget {
  final AnimationController loop;
  final double size, share;
  final String label, sub;
  const _MealRing({
    required this.loop,
    required this.size,
    required this.share,
    required this.label,
    required this.sub,
  });
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final stroke = size * .095;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: share.clamp(0.0, 1.0)),
        duration: still ? Duration.zero : const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (context, grown, _) => AnimatedBuilder(
          animation: loop,
          builder: (context, _) => CustomPaint(
            painter: _RingPainter(
              share: grown,
              // Before the first meal a faint arc breathes to invite one.
              idle: share == 0 ? .06 + .05 * _wave(loop) : 0,
              glow: _wave(loop, .25),
              stroke: stroke,
              track: context.tf.soft,
              start: context.tf.primary,
            ),
            child: Padding(
              padding: EdgeInsets.all(stroke + 12),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(fontSize: 11, color: context.tf.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double share, idle, glow, stroke;
  final Color track, start;
  const _RingPainter({
    required this.share,
    required this.idle,
    required this.glow,
    required this.stroke,
    required this.track,
    required this.start,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke / 2 - 6;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final sweep = math.pi * 2 * math.max(share, idle);
    if (sweep <= 0) return;
    // Angle taken by the round cap, so the gradient starts behind it.
    final cap = stroke / 2 / r;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      // The gradient spans only the drawn arc, so the start cap stays green.
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.max(sweep, .01) + 2 * cap,
        transform: GradientRotation(-math.pi / 2 - cap),
        colors: [
          start,
          Color.lerp(start, const Color(0xff4f9a6e), .9)!,
          const Color(0xffc9e27a),
        ],
        stops: const [0, .6, 1],
      ).createShader(rect);
    if (share == 0) {
      paint
        ..shader = null
        ..color = start.withValues(alpha: .5);
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, paint);
    if (share <= 0) return;
    final end = -math.pi / 2 + sweep;
    final tip = c + Offset(math.cos(end), math.sin(end)) * r;
    canvas.drawCircle(
      tip,
      stroke * .55 + 5 * glow,
      Paint()..color = TrainForgeTheme.highlight.withValues(alpha: .28),
    );
    canvas.drawCircle(
      tip,
      stroke * .42,
      Paint()..color = TrainForgeTheme.highlight,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share || old.idle != idle || old.glow != glow;
}

/// A bottle filling with water whose surface moves in two slow waves.
class _Bottle extends StatelessWidget {
  final AnimationController loop;
  final double share;
  const _Bottle({required this.loop, required this.share});
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: share.clamp(0.0, 1.0)),
      duration: still ? Duration.zero : const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, level, _) => AnimatedBuilder(
        animation: loop,
        builder: (context, _) => CustomPaint(
          painter: _BottlePainter(
            level: level,
            phase: loop.isAnimating ? loop.value : 0,
            surface: context.tf.surface,
          ),
        ),
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final double level, phase;
  final Color surface;
  const _BottlePainter({
    required this.level,
    required this.phase,
    required this.surface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const line = Color(0xff9cc3ea);
    final w = size.width, h = size.height;
    final capW = w * .36, capH = h * .11;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - capW) / 2, 0, capW, capH),
        const Radius.circular(5),
      ),
      Paint()..color = line,
    );
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(1.5, capH + 2, w - 3, h - capH - 3.5),
      topLeft: Radius.circular(w * .26),
      topRight: Radius.circular(w * .26),
      bottomLeft: Radius.circular(w * .22),
      bottomRight: Radius.circular(w * .22),
    );
    canvas.drawRRect(body, Paint()..color = surface);
    canvas.save();
    canvas.clipRRect(body);
    final top = body.bottom - body.height * level;
    if (level > 0) {
      for (final (shift, alpha, amp) in [(0.0, .55, 3.0), (.5, 1.0, 2.4)]) {
        final path = Path()..moveTo(body.left, body.bottom);
        for (var x = body.left; x <= body.right + 1; x += 2) {
          final y =
              top +
              amp *
                  math.sin(
                    (x / body.width) * math.pi * 2 +
                        (phase + shift) * math.pi * 2,
                  );
          path.lineTo(x, y);
        }
        path
          ..lineTo(body.right, body.bottom)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(_waterSoft, const Color(0xffb9d7f3), alpha)!,
        );
      }
    }
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(_BottlePainter old) =>
      old.level != level || old.phase != phase || old.surface != surface;
}

/// "Qual é o seu objetivo?": a carousel of cards that explain each goal
/// (for whom, meals, protein, water and a sourced tip), the day it gives
/// right below, and "Escolher". It turns by itself until touched.
class _GoalPicker extends StatefulWidget {
  final FoodGoal initial;
  final int? weightKg;
  final String? gender;
  final AnimationController loop;
  final VoidCallback? onCancel;
  final ValueChanged<FoodGoal>? onChoose;
  const _GoalPicker({
    required this.initial,
    required this.weightKg,
    required this.gender,
    required this.loop,
    required this.onCancel,
    required this.onChoose,
  });
  @override
  State<_GoalPicker> createState() => _GoalPickerState();
}

class _GoalPickerState extends State<_GoalPicker> {
  late int current = widget.initial.index;
  late final pages = PageController(
    viewportFraction: .78,
    initialPage: current,
  );
  Timer? turn;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      turn = Timer.periodic(const Duration(milliseconds: 3400), (_) {
        if (!pages.hasClients) return;
        pages.animateToPage(
          (current + 1) % FoodGoal.values.length,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    turn?.cancel();
    pages.dispose();
    super.dispose();
  }

  void stop() {
    turn?.cancel();
    turn = null;
  }

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final goal = FoodGoal.values[current];
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.4);
    final waterMl = FoodGoal.waterMl(widget.gender);
    final liters = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(waterMl / 1000);
    final protein = goal.proteinGrams(widget.weightKg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l('foodGoalQuestion'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l('foodGoalSwipe'),
                    style: TextStyle(fontSize: 12, color: context.tf.muted),
                  ),
                ],
              ),
            ),
            if (widget.onCancel != null)
              TextButton(
                onPressed: widget.onCancel,
                child: Text(l('foodCancel')),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Listener(
          onPointerDown: (_) => stop(),
          child: SizedBox(
            height: 262 * scale,
            child: PageView.builder(
              controller: pages,
              itemCount: FoodGoal.values.length,
              onPageChanged: (i) => setState(() => current = i),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: pages,
                builder: (context, child) {
                  final page = pages.hasClients && pages.position.haveDimensions
                      ? pages.page ?? current.toDouble()
                      : current.toDouble();
                  final d = (page - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - .45 * d,
                    child: Transform.scale(scale: 1 - .1 * d, child: child),
                  );
                },
                child: _GoalCard(
                  goal: FoodGoal.values[i],
                  active: i == current,
                  liters: liters,
                  waterShare: waterMl / 2500,
                  loop: widget.loop,
                  onTap: () {
                    stop();
                    pages.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < FoodGoal.values.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == current
                      ? TrainForgeTheme.highlight
                      : context.tf.soft,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _Card(
          padding: 12,
          child: Row(
            children: [
              _MealRing(
                loop: widget.loop,
                size: 84,
                share: 0,
                label: '0 ${l('mealsOf')} ${goal.meals}',
                sub: l('foodMeals'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .08),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(goal),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l('foodDayPreview'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PreviewLine(
                        l('foodMealsTitle'),
                        '${goal.meals} ${l('foodPerDay')}',
                      ),
                      _PreviewLine(
                        l('foodProtein'),
                        protein == null
                            ? '${NumberFormat('0.0', Localizations.localeOf(context).toLanguageTag()).format(goal.proteinPerKg)} g/kg'
                            : '$protein g',
                      ),
                      _PreviewLine(l('foodWaterTitle'), '$liters L'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MainAction(
          label: '${l('foodChoose')} ${l('goal_${goal.id}')}',
          icon: Icons.check,
          onPressed: widget.onChoose == null
              ? null
              : () => widget.onChoose!(goal),
        ),
        const SizedBox(height: 8),
        Text(
          l('foodGoalNote'),
          style: TextStyle(fontSize: 11, height: 1.3, color: context.tf.muted),
        ),
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final String label, value;
  const _PreviewLine(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.tf.muted)),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _GoalCard extends StatelessWidget {
  final FoodGoal goal;
  final bool active;
  final String liters;
  final double waterShare;
  final AnimationController loop;
  final VoidCallback onTap;
  const _GoalCard({
    required this.goal,
    required this.active,
    required this.liters,
    required this.waterShare,
    required this.loop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final muted = TextStyle(fontSize: 11.5, color: context.tf.muted);
    final perKg = NumberFormat(
      '0.0',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(goal.proteinPerKg);
    // Very large text: the label goes above its bar.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    Widget fact(String label, Widget visual, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, style: muted),
                Row(
                  children: [
                    Expanded(child: visual),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: Text(label, style: muted)),
                Expanded(flex: 4, child: visual),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
    Widget bar(double share, List<Color> colors) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: context.tf.soft)),
            TweenAnimationBuilder<double>(
              tween: Tween(end: active ? share : 0),
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v.clamp(0.0, 1.0),
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: active,
      label:
          '${l('goal_${goal.id}')}. ${l('goalFor_${goal.id}')} '
          '${goal.meals} ${l('foodMeals')}, $perKg g/kg. ${l('goalTip_${goal.id}')}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: context.tf.surface,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(26),
                side: BorderSide(
                  color: active ? context.tf.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
            // Very large text can outgrow the card: it scrolls inside then.
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: loop,
                                builder: (context, child) =>
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        active ? -3 * _wave(loop) : 0,
                                      ),
                                      child: child,
                                    ),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: ShapeDecoration(
                                    color: _goalTints[goal],
                                    shape: RoundedSuperellipseBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Icon(
                                    _goalIcons[goal],
                                    size: 25,
                                    color: TrainForgeTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l('goal_${goal.id}'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      l('goalFor_${goal.id}'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: muted,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          fact(
                            l('foodMealsTitle'),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  for (var i = 0; i < goal.meals; i++)
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey('$active$i'),
                                      tween: Tween(
                                        begin: active && !still ? 0 : 1,
                                        end: 1,
                                      ),
                                      duration: Duration(
                                        milliseconds: 300 + i * 90,
                                      ),
                                      curve: Curves.easeOutBack,
                                      builder: (context, v, child) =>
                                          Transform.scale(
                                            scale: v,
                                            child: child,
                                          ),
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: context.tf.primary,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            '${goal.meals}',
                          ),
                          fact(
                            l('foodProtein'),
                            bar(goal.proteinPerKg / 2.0, [
                              context.tf.primary,
                              TrainForgeTheme.highlight,
                            ]),
                            '$perKg g/kg',
                          ),
                          fact(
                            l('foodWaterTitle'),
                            bar(waterShare, const [
                              Color(0xff9cc3ea),
                              _waterBlue,
                            ]),
                            '$liters L',
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: context.tf.soft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 17,
                                  color: TrainForgeTheme.highlight,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    l('goalTip_${goal.id}'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
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

class _Card extends StatelessWidget {
  final Widget child;
  final double padding;
  const _Card({required this.child, this.padding = 12});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: context.tf.surface,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(22)),
    ),
    child: Padding(padding: EdgeInsets.all(padding), child: child),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                l('mealsToday'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
