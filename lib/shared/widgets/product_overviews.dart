import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/features/home/presentation/pages/today_page.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'figma_bottom_nav.dart';
import 'figma_components.dart';
import 'package:trainforge/features/activity/presentation/evolution_source.dart';
import 'package:trainforge/features/nutrition/presentation/food_board.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'shell_labels.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'package:trainforge/features/activity/presentation/activity_page.dart';

const tfBlue = Color(0xffc9eaf7), tfYellow = Color(0xfff8eba5);

class DailyOverview extends StatelessWidget {
  final DailySummaryController controller;
  final String name;
  final bool food;
  final ValueChanged<DateTime>? openDay;
  final VoidCallback openNutrition, openCatalog, openActivity;

  /// Voice and photo entry, only when this build can do them.
  final VoidCallback? openVoice, openPhoto;

  /// The offline diary (water and today's meals), when available.
  final NutritionRepository? diary;
  const DailyOverview({
    super.key,
    required this.controller,
    required this.name,
    required this.food,
    this.openDay,
    required this.openNutrition,
    required this.openCatalog,
    required this.openActivity,
    this.openVoice,
    this.openPhoto,
    this.diary,
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
      final state = controller.loading
          ? context.l10n.loadingQuery
          : controller.failed
          ? context.l10n.queryUnavailable
          : context.l10n.sourceSubtotals;
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          // Short title, like Evolução, so the page fits one screen.
          title: TrainForgeDestination.food.localizedLabel(context),
          subtitle: context.displayLongDate(controller.now()),
          children: [
            if (controller.loading)
              AppProgress(label: context.l10n.loadingDayRecords),
            if (controller.failed) ...[
              Text(state),
              OutlinedButton(
                onPressed: controller.load,
                child: Text(context.l10n.updateDayRecords),
              ),
            ],
            FoodBoard(
              controller: controller,
              diary: diary,
              openNutrition: openNutrition,
              openVoice: openVoice,
              openPhoto: openPhoto,
            ),
          ],
        ),
      );
    },
  );
}

/// Evolução tab: workout sessions history (the former Atividade tab) plus
/// the food diary. With nothing recorded, one friendly line and one button.
class EvolutionPage extends StatelessWidget {
  final ActivityRepository? activity;
  final NutritionRepository? nutrition;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final VoidCallback openNutrition, openWorkouts;
  const EvolutionPage({
    super.key,
    required this.activity,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    required this.openNutrition,
    required this.openWorkouts,
    this.nutrition,
  });

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    // The dashboard on top, fed by real records; while there are none, its
    // cards preview how they fill and one button starts the first workout.
    Widget board(List<ActivityDetail> sessions) => EvolutionBoard(
      sessions: sessions,
      nutrition: nutrition,
      onStart: openWorkouts,
    );
    final repository = activity;
    if (repository == null) {
      return FigmaContent(
        title: l('evolutionTitle'),
        subtitle: l('evolutionIntro'),
        children: [board(const [])],
      );
    }
    return ActivityPage(
      repository: repository,
      accountId: accountId,
      currentAccountId: currentAccountId,
      sessionChanges: sessionChanges,
      title: l('evolutionTitle'),
      intro: l('evolutionIntro'),
      header: (feed) => board(feed.sessions),
      // Nothing else while the history is empty: the board says it all.
      empty: const SizedBox.shrink(),
    );
  }
}
