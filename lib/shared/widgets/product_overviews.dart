import 'package:trainforge/core/l10n/localized_context.dart';
import 'evaluation_guide_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/features/home/presentation/pages/today_page.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'figma_components.dart';

const tfBlue = Color(0xffc9eaf7), tfYellow = Color(0xfff8eba5);

class DailyOverview extends StatelessWidget {
  final DailySummaryController controller;
  final String name;
  final bool food;
  final ValueChanged<DateTime>? openDay;
  final VoidCallback openNutrition, openCatalog, openActivity;
  const DailyOverview({
    super.key,
    required this.controller,
    required this.name,
    required this.food,
    this.openDay,
    required this.openNutrition,
    required this.openCatalog,
    required this.openActivity,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!food) {
        return TodayPage(
          controller: controller,
          name: name,
          openNutrition: openNutrition,
          openCatalog: openCatalog,
          openActivity: openActivity,
          openDay: openDay,
        );
      }
      final snapshot = controller.loading ? null : controller.summary;
      final int? count = snapshot?['complete'] == true
          ? (snapshot?['entries'] as int?)
          : null;
      final energy = dailyEnergy(snapshot);
      final state = controller.loading
          ? context.l10n.loadingQuery
          : controller.failed
          ? context.l10n.queryUnavailable
          : context.l10n.sourceSubtotals;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          title: context.l10n.eatSimply,
          subtitle:
              '${context.displayLongDate(controller.now())} · ${food ? context.l10n.foodDiaryUpper : context.l10n.dailyRhythm}',
          children: [
            if (controller.loading)
              AppProgress(label: context.l10n.loadingDayRecords),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.tf.nutrition,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.recordedEnergy,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    energy ?? '—',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  Text(
                    energy == null ? state : context.l10n.energyMethodSubtotal,
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                  if (energy != null &&
                      snapshot?['measuredEntries'] is int &&
                      snapshot?['estimatedEntries'] is int)
                    Text(
                      context.l10n.quantityEvidenceCounts(
                        snapshot!["measuredEntries"] as int,
                        snapshot["estimatedEntries"] as int,
                      ),
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
            if (controller.failed)
              OutlinedButton(
                onPressed: controller.load,
                child: Text(context.l10n.updateDayRecords),
              ),
            FigmaActionCard(
              title: food ? context.l10n.myRecords : context.l10n.myNutrition,
              subtitle: count == null
                  ? state
                  : context.l10n.confirmedDayCount(count),
              asset: 'food',
              color: food ? context.tf.surface : context.tf.nutrition,
              onTap: openNutrition,
            ),
            if (food) ...[
              FilledButton(
                onPressed: openNutrition,
                child: Text(context.l10n.addFood),
              ),
              FigmaActionCard(
                title: context.l10n.hydration,
                subtitle: context.l10n.waterUnavailable,
                asset: 'water',
                color: context.tf.blue,
                onTap: () => showAvailability(
                  context,
                  context.l10n.hydration,
                  context.l10n.waterNotImplemented,
                ),
              ),
              FigmaActionCard(
                title: context.l10n.planLearn,
                subtitle: context.l10n.foodGuidanceUnavailable,
                asset: 'plan',
                onTap: () => showAvailability(
                  context,
                  context.l10n.planningLearning,
                  context.l10n.foodPlansUnavailable,
                ),
              ),
            ] else
              FigmaActionCard(
                title: context.l10n.whatToday,
                subtitle: context.l10n.exploreActivities,
                asset: 'activity',
                color: context.tf.yellow,
                onTap: openActivity,
              ),
          ],
        ),
      );
    },
  );
}

class ActivityOverview extends StatelessWidget {
  const ActivityOverview({super.key});
  @override
  Widget build(BuildContext context) => FigmaContent(
    title: context.l10n.outdoorsCounts,
    subtitle: context.l10n.activityIntro,
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.tf.blue,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          context.l10n.routeUnavailable,
          style: TextStyle(fontSize: 15, height: 1.35),
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: context.l10n.noWalkKm,
              color: context.tf.blue,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: context.l10n.noActivityMinutes,
              color: context.tf.yellow,
            ),
          ),
        ],
      ),
      FilledButton(
        onPressed: () => openEvaluationGuide(context, EvaluationTopic.activity),
        child: Text(context.l10n.startActivity),
      ),
      FigmaActionCard(
        title: context.l10n.quickRecord,
        subtitle: context.l10n.quickUnavailable,
        asset: 'plus',
        onTap: () => openEvaluationGuide(context, EvaluationTopic.activity),
      ),
      FigmaActionCard(
        title: context.l10n.myDevices,
        subtitle: context.l10n.permissionsSync,
        asset: 'activity',
        color: context.tf.soft,
        onTap: () => openEvaluationGuide(context, EvaluationTopic.devices),
      ),
    ],
  );
}

class EvolutionOverview extends StatelessWidget {
  final VoidCallback openNutrition;
  const EvolutionOverview({super.key, required this.openNutrition});
  @override
  Widget build(BuildContext context) => FigmaContent(
    title: context.l10n.yourProgress,
    subtitle: context.l10n.historyWithSource,
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.tf.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '—',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
            ),
            Text(
              context.l10n.chartUnavailable,
              style: TextStyle(fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: context.l10n.workoutsUnavailable,
              color: context.tf.soft,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: FigmaMetric(
              value: '—',
              label: context.l10n.walkingKmUnavailable,
              color: context.tf.blue,
            ),
          ),
        ],
      ),
      FigmaActionCard(
        title: context.l10n.eachRecordCounts,
        subtitle: context.l10n.historyCorrect,
        asset: 'chart',
        color: context.tf.yellow,
        onTap: openNutrition,
      ),
      FigmaActionCard(
        title: context.l10n.measurementsGoals,
        subtitle: context.l10n.configurationUnavailable,
        asset: 'heart',
        onTap: () => openEvaluationGuide(context, EvaluationTopic.firstAccess),
      ),
    ],
  );
}
