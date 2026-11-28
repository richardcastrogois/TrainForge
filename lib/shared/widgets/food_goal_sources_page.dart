import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/nutrition/domain/food_goals.dart';
import 'figma_components.dart';
import 'shell_labels.dart';

/// Where every number of the food page comes from: the goal table, water,
/// the published references (with DOI) and the app's own rules, kept
/// apart so nothing reads as a source when it is a convention.
class FoodGoalSourcesPage extends StatelessWidget {
  const FoodGoalSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    String n(double v) => v
        .toStringAsFixed(1)
        .replaceAll(
          '.',
          Localizations.localeOf(context).languageCode == 'en' ? '.' : ',',
        );
    const bold = TextStyle(fontWeight: FontWeight.w700);
    return FigmaRouteFrame(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          FigmaPageHeading(
            title: l('sourcesFoodTitle'),
            subtitle: l('sourcesFoodIntro'),
          ),
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l('sourcesFoodGoals'), style: bold),
                const SizedBox(height: 8),
                for (final goal in FoodGoal.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${l('goal_${goal.id}')}: ${goal.meals} '
                      '${l('foodMeals')} · ${n(goal.proteinPerKg)} '
                      '${l('sourcesFoodPerKg')}',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(l('sourcesFoodWater'), style: bold),
                const SizedBox(height: 8),
                Text(
                  '${l('sourcesFoodWoman')}: ${FoodGoal.waterMl('woman')} ml · '
                  '${l('sourcesFoodMan')}: ${FoodGoal.waterMl('man')} ml · '
                  '${l('sourcesFoodOther')}: ${FoodGoal.waterMl(null)} ml',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final source in foodGoalSources) ...[
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l(source.use), style: bold),
                  const SizedBox(height: 6),
                  Text(source.citation),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(source.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(source.shown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l('sourcesFoodTips'), style: bold),
                const SizedBox(height: 6),
                for (final goal in FoodGoal.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${l('goal_${goal.id}')}: ${l('goalTip_${goal.id}')} '
                      '(${foodGoalSources.firstWhere((s) => s.use == goal.tipSource).citation.split('.').first})',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l('sourcesFoodRules'), style: bold),
                const SizedBox(height: 6),
                for (final rule in const [
                  'sourcesRuleMeal',
                  'sourcesRuleName',
                  'sourcesRuleNext',
                  'sourcesRuleDrops',
                  'sourcesRuleEnergy',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• ${l(rule)}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FigmaSection(child: Text(l('foodGoalNote'))),
          const SizedBox(height: 24),
          Text(
            l('sourcesBodyTitle'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final source in bodySources) ...[
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l(source.use), style: bold),
                  const SizedBox(height: 6),
                  Text(source.citation),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(source.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(source.shown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l('sourcesFoodRules'), style: bold),
                const SizedBox(height: 6),
                for (final rule in const [
                  'sourcesRuleWeek',
                  'sourcesRuleDue',
                  'sourcesRuleProtein',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• ${l(rule)}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
