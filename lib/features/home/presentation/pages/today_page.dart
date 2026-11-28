import 'package:trainforge/core/l10n/localized_context.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/onboarding/onboarding_page.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import '../widgets/home_cards.dart';
import 'package:trainforge/shared/widgets/shell_labels.dart';

class TodayPage extends StatefulWidget {
  final DailySummaryController controller;
  final String name;
  final VoidCallback openNutrition, openCatalog, openActivity;
  final ValueChanged<DateTime>? openDay;
  const TodayPage({
    super.key,
    required this.controller,
    required this.name,
    required this.openNutrition,
    required this.openCatalog,
    required this.openActivity,
    this.openDay,
  });
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  Timer? midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleMidnight();
  }

  void scheduleMidnight() {
    midnight?.cancel();
    final now = widget.controller.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    final wait = next.difference(now) + Duration(milliseconds: 100);
    midnight = Timer(wait.isNegative ? Duration(seconds: 1) : wait, () {
      if (!mounted) return;
      widget.controller.load();
      setState(() {});
      scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleMidnight();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Opens the first questions again to fill what is missing; answers stay editable.
  void completeAnswers(BuildContext context, OnboardingScope? scope) {
    if (scope == null) return;
    final controller = scope.notifier!, id = scope.accountId;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (route) => OnboardingPage(
          initial: scope.profile,
          askBody: LegalScope.maybeOf(context)?.healthGranted(id) == true,
          onDone: (answers) {
            controller.save(id, answers);
            Navigator.pop(route);
          },
        ),
      ),
    );
  }

  bool _showDay = false;

  /// Whether one load has finished, so a first-use screen never flashes for
  /// someone who already has records.
  bool _known = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller, now = controller.now();
      final snapshot = controller.loading ? null : controller.summary;
      final complete = snapshot?['complete'] == true;
      final int? count = complete ? (snapshot?['entries'] as int?) : null;
      final energy = dailyEnergy(snapshot);
      final scope = OnboardingScope.maybeOf(context);
      final answers = scope?.profile;
      // Failures and partial summaries stay visible; only a quiet, empty day is
      // hidden. While reloading, keep whatever the last answer showed.
      if (!controller.loading) {
        _known = _known || snapshot != null || controller.failed;
        _showDay =
            (count ?? 0) > 0 ||
            energy != null ||
            controller.failed ||
            (snapshot != null && !complete);
      }
      final hasRecords = _showDay;
      // First use: one card and one action, nothing else.
      final first = _known && !hasRecords;
      final name = widget.name
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty);
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          title: name.isEmpty
              ? context.l10n.moveNow
              : context.l10n.moveWithName(name.first),
          subtitle: first
              ? shellLabel(context, 'firstQuestion')
              : context.displayLongDate(now),
          children: [
            TrainingHeroCard(
              profile: answers,
              first: first,
              completeAnswers: () => completeAnswers(context, scope),
            ),
            // First use: the week only shows where each day will be; today
            // in orange. Nothing to tap yet.
            if (first)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _Week(now: now),
              ),
            // Week strip and day numbers only once there is something recorded.
            if (hasRecords) ...[
              Text(
                context.l10n.yourWeek,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              Text(
                context.l10n.diaryByDate,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: context.tf.muted,
                ),
              ),
              _Week(
                now: now,
                onSelected: (date) {
                  if (widget.openDay != null) {
                    widget.openDay!(date);
                  } else {
                    widget.openNutrition();
                  }
                },
              ),
              if (controller.loading ||
                  controller.failed ||
                  energy != null ||
                  (snapshot != null && !complete))
                Text(
                  context.l10n.yourDay,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              if (controller.loading) ...[
                AppMetricSkeleton(label: context.l10n.loadingDayData),
                AppProgress(label: context.l10n.loadingDayRecords),
              ] else if (controller.failed)
                FigmaSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          context.l10n.dayUpdateFailed,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(context.l10n.dayUnconfirmed),
                      SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: controller.load,
                        child: Text(context.l10n.retryUpdate),
                      ),
                    ],
                  ),
                )
              else ...[
                // Only numbers that exist; no "—" or "unavailable" boxes.
                if (energy != null)
                  _Metric(
                    value: energy,
                    label: context.l10n.energySourceMethod,
                    color: context.tf.nutrition,
                    onTap: widget.openNutrition,
                  ),
                if (snapshot != null && !complete)
                  Text(
                    context.l10n.summaryLimit,
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                if (energy != null &&
                    snapshot?['measuredEntries'] is int &&
                    snapshot?['estimatedEntries'] is int)
                  Text(
                    '${context.l10n.quantityEvidenceCounts(snapshot!["measuredEntries"] as int, snapshot["estimatedEntries"] as int)}. ${context.l10n.originMethodDiary}',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
              ],
            ],
            if (hasRecords)
              FigmaActionCard(
                title: context.l10n.myNutrition,
                asset: 'food',
                color: context.tf.nutrition,
                subtitle: controller.loading
                    ? context.l10n.loadingRecords
                    : controller.failed
                    ? context.l10n.openHistoryRetry
                    : count == 0
                    ? context.l10n.noConfirmedToday
                    : count == null
                    ? context.l10n.viewRecordsOrigin
                    : context.l10n.confirmedDayCount(count),
                onTap: widget.openNutrition,
              ),
            if (hasRecords) ...[
              TextButton(
                onPressed: controller.loading ? null : controller.load,
                child: Text(context.l10n.updateDay),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _Week extends StatelessWidget {
  final DateTime now;

  /// Null shows the week only (first use), without opening days.
  final ValueChanged<DateTime>? onSelected;
  const _Week({required this.now, this.onSelected});
  @override
  Widget build(BuildContext context) {
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    if (onSelected == null) {
      // Display only: seven days across the width, today in orange.
      return Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = DateTime(
                    monday.year,
                    monday.month,
                    monday.day + i,
                  );
                  final today = localDay(day) == localDay(now);
                  final style = TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: today ? TrainForgeTheme.ink : context.tf.ink,
                  );
                  return Semantics(
                    label: context.displayDate(day),
                    selected: today,
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: ShapeDecoration(
                        color: today
                            ? TrainForgeTheme.highlight
                            : context.tf.surface.withValues(alpha: .55),
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              context.weekdayInitial(day),
                              style: style.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          FittedBox(child: Text('${day.day}', style: style)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) SizedBox(width: 1),
            Builder(
              builder: (context) {
                final day = DateTime(monday.year, monday.month, monday.day + i);
                final selected = localDay(day) == localDay(now);
                return Semantics(
                  label: context.l10n.viewFoodDay(context.displayDate(day)),
                  button: true,
                  selected: selected,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 48,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onSelected!(day),
                        borderRadius: BorderRadius.circular(17),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 2,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.tf.accent
                                  : context.tf.surface,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.weekdayInitial(day),
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value, label;
  final Color color;
  final VoidCallback onTap;
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, height: 1.35)),
          ],
        ),
      ),
    ),
  );
}
