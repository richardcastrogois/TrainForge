import 'package:flutter/material.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'package:trainforge/features/activity/domain/activity_session.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/features/nutrition/presentation/hydration_card.dart'
    show waterFoodId;
import 'package:trainforge/shared/widgets/evolution_preview.dart';

/// What the food diary holds for one day: a meal (any food that is not
/// water) and the water drunk, in ml (1 g of water ≈ 1 ml).
class DiaryDay {
  final bool ate;
  final int waterMl;
  const DiaryDay({this.ate = false, this.waterMl = 0});
}

/// Reads the diary of every day of the current month up to today. A day that
/// cannot be read is left out (unknown), never counted as empty.
Future<Map<int, DiaryDay>> loadDiaryMonth(
  NutritionRepository repository,
  DateTime now,
) async {
  final days = <int, DiaryDay>{};
  for (var n = 1; n <= now.day; n++) {
    final date = DateTime(now.year, now.month, n, 12);
    var ate = false, water = 0.0;
    String? cursor;
    try {
      do {
        final page = await repository.entries(
          localDay(date),
          offsetZone(date),
          cursor: cursor,
        );
        for (final item in page.items) {
          if (item['deletedAt'] != null) continue;
          if (item['foodId'] == waterFoodId) {
            water += double.tryParse('${item['quantity']}') ?? 0;
          } else {
            ate = true;
          }
        }
        cursor = page.cursor;
      } while (cursor != null);
    } catch (_) {
      continue;
    }
    days[n] = DiaryDay(ate: ate, waterMl: water.round());
  }
  return days;
}

/// Energy of today from the diary summary, only when it is complete.
Future<int?> loadKcalToday(NutritionRepository repository, DateTime now) async {
  try {
    final text = dailyEnergy(
      await repository.summary(localDay(now), offsetZone(now)),
    );
    return text == null
        ? null
        : double.tryParse(text.replaceAll(',', '.'))?.round();
  } catch (_) {
    return null;
  }
}

/// Turns real records into what Evolução shows. Everything counts within the
/// current month, the same span as the consistency grid.
///
/// * A day scores a third for each of: a workout done (completed or partly
///   done), a meal recorded and water recorded. All three = full green.
/// * The streak counts days in a row with something recorded, ending today
///   (or yesterday, while today is still empty).
/// * Water has no goal yet, so its card shows the amount without a level.
EvolutionData buildEvolution({
  required Iterable<ActivityDetail> sessions,
  required DateTime now,
  Map<int, DiaryDay>? diary,
  int? kcal,
}) {
  bool sameMonth(DateTime d) => d.year == now.year && d.month == now.month;
  final trained = <int>{};
  var minutes = 0, sets = 0;
  for (final session in sessions) {
    final s = session.snapshot;
    final start = s.startedAt.toLocal();
    if (!sameMonth(start) || start.day > now.day) continue;
    if (s.state == ActivityState.completed ||
        s.state == ActivityState.partial) {
      trained.add(start.day);
    }
    if (s.state != ActivityState.cancelled) {
      minutes += (s.activeMilliseconds / 60000).round();
      sets += s.sets.length;
    }
  }
  final scores = <int, double>{};
  for (var n = 1; n <= now.day; n++) {
    final day = diary?[n];
    final parts = [
      trained.contains(n),
      day?.ate ?? false,
      (day?.waterMl ?? 0) > 0,
    ].where((done) => done).length;
    scores[n] = parts / 3;
  }
  var streak = 0;
  var n = (scores[now.day] ?? 0) > 0 ? now.day : now.day - 1;
  for (; n >= 1 && (scores[n] ?? 0) > 0; n--) {
    streak++;
  }
  final anything = scores.values.any((v) => v > 0);
  return EvolutionData(
    streakDays: streak,
    minutes: minutes,
    sets: sets,
    kcal: kcal,
    waterMl: diary?[now.day]?.waterMl,
    // Before any record the grid keeps its preview.
    dayScores: anything ? scores : null,
  );
}

/// Evolução's dashboard fed with real records: workouts from the loaded
/// feed, meals, water and energy read from the diary of this month.
class EvolutionBoard extends StatefulWidget {
  final List<ActivityDetail> sessions;
  final NutritionRepository? nutrition;
  final VoidCallback onStart;
  final DateTime Function() now;

  /// Shown under the month (the body card).
  final Widget? body;
  const EvolutionBoard({
    super.key,
    required this.sessions,
    required this.nutrition,
    required this.onStart,
    this.now = DateTime.now,
    this.body,
  });

  @override
  State<EvolutionBoard> createState() => _EvolutionBoardState();
}

class _EvolutionBoardState extends State<EvolutionBoard> {
  Map<int, DiaryDay>? diary;
  int? kcal;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final repository = widget.nutrition;
    if (repository == null) return;
    final now = widget.now();
    final days = await loadDiaryMonth(repository, now);
    final energy = await loadKcalToday(repository, now);
    if (!mounted) return;
    setState(() {
      diary = days;
      kcal = energy;
    });
  }

  @override
  Widget build(BuildContext context) => EvolutionPreview(
    now: widget.now,
    body: widget.body,
    // The first-workout button only until there is a workout.
    onStart: widget.sessions.isEmpty ? widget.onStart : null,
    data: buildEvolution(
      sessions: widget.sessions,
      now: widget.now(),
      diary: diary,
      kcal: kcal,
    ),
  );
}
