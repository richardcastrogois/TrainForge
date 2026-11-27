import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/features/home/presentation/pages/today_page.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'figma_components.dart';
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

  /// One-tap water, when the offline diary is available.
  final Widget? hydration;
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
    this.hydration,
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
      String l(String k) => shellLabel(context, k);
      return RefreshIndicator(
        onRefresh: controller.load,
        child: FigmaContent(
          title: context.l10n.eatSimply,
          subtitle: context.displayLongDate(controller.now()),
          children: [
            if (controller.loading)
              AppProgress(label: context.l10n.loadingDayRecords),
            // The energy total only once there is something to add up.
            if (energy != null)
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      energy,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    Text(
                      context.l10n.energyMethodSubtotal,
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                    if (snapshot?['measuredEntries'] is int &&
                        snapshot?['estimatedEntries'] is int)
                      Text(
                        context.l10n.quantityEvidenceCounts(
                          snapshot!["measuredEntries"] as int,
                          snapshot["estimatedEntries"] as int,
                        ),
                        style: TextStyle(fontSize: 13),
                      ),
                  ],
                ),
              ),
            if (controller.failed) ...[
              Text(state),
              OutlinedButton(
                onPressed: controller.load,
                child: Text(context.l10n.updateDayRecords),
              ),
            ],
            SizedBox(
              height: 60,
              child: FilledButton.icon(
                onPressed: openNutrition,
                icon: const Icon(Icons.add, size: 26),
                label: Text(l('addMeal'), style: const TextStyle(fontSize: 18)),
              ),
            ),
            if (openVoice != null || openPhoto != null)
              Row(
                children: [
                  if (openVoice != null)
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.mic_none,
                        label: l('addVoice'),
                        color: context.tf.blue,
                        onTap: openVoice!,
                      ),
                    ),
                  if (openVoice != null && openPhoto != null)
                    const SizedBox(width: 10),
                  if (openPhoto != null)
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.photo_camera_outlined,
                        label: l('addPhoto'),
                        color: context.tf.yellow,
                        onTap: openPhoto!,
                      ),
                    ),
                ],
              ),
            ?hydration,
            FigmaActionCard(
              title: context.l10n.myRecords,
              subtitle: count == null
                  ? state
                  : count == 0
                  ? l('foodEmpty')
                  : context.l10n.confirmedDayCount(count),
              asset: 'food',
              onTap: openNutrition,
            ),
          ],
        ),
      );
    },
  );
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: TrainForgeTheme.ink),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TrainForgeTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Evolução tab: workout sessions history (the former Atividade tab) plus
/// the food diary. With nothing recorded, one friendly line and one button.
class EvolutionPage extends StatelessWidget {
  final ActivityRepository? activity;
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
  });

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final empty = FigmaSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.insights, size: 40, color: context.tf.primary),
          const SizedBox(height: 10),
          Text(
            l('evolutionEmpty'),
            style: const TextStyle(fontSize: 17, height: 1.35),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: openWorkouts, child: Text(l('goWorkouts'))),
        ],
      ),
    );
    final diary = FigmaActionCard(
      title: l('foodDiary'),
      subtitle: l('foodDiaryHint'),
      asset: 'food',
      color: context.tf.nutrition,
      onTap: openNutrition,
    );
    final repository = activity;
    if (repository == null) {
      return FigmaContent(
        title: l('evolutionTitle'),
        subtitle: l('evolutionIntro'),
        children: [empty, diary],
      );
    }
    return ActivityPage(
      repository: repository,
      accountId: accountId,
      currentAccountId: currentAccountId,
      sessionChanges: sessionChanges,
      title: l('evolutionTitle'),
      intro: l('evolutionIntro'),
      empty: empty,
      extra: [diary],
    );
  }
}
