import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';

typedef NutritionFact = ({String name, String value, String unit});

/// Displays API values without converting units, combining methods or recalculating.
class NutritionFacts extends StatelessWidget {
  final List<NutritionFact> values;
  const NutritionFacts({super.key, required this.values});
  String? category(String name) {
    final v = name.toLowerCase();
    if (RegExp(r'^(energy|énergie|energie|energ[ií]a)').hasMatch(v)) {
      return 'energy';
    }
    if (RegExp(r'^(prot[eé][ií]n)').hasMatch(v)) return 'protein';
    if (RegExp(
      r'^(carbohydrate|glucide|carboidrato|carbohidrato|hidratos de carbono)',
    ).hasMatch(v)) {
      return 'carbs';
    }
    if (RegExp(
      r'^(fat\b|lipid|lipide|l[ií]pido|gorduras?(?:$| totais| total)|grasas?(?:$| total))',
    ).hasMatch(v)) {
      return 'fat';
    }
    if (RegExp(r'^(fibr[ae]|fiber)').hasMatch(v)) return 'fiber';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String label(String k) => switch (k) {
      'energy' => context.l10n.nutrientEnergy,
      'protein' => context.l10n.nutrientProtein,
      'carbs' => context.l10n.nutrientCarbs,
      'fat' => context.l10n.nutrientFat,
      _ => context.l10n.nutrientFiber,
    };
    final groups = <String, List<NutritionFact>>{};
    for (final n in values) {
      final k = category(n.name);
      if (k != null) groups.putIfAbsent('$k|${n.unit}', () => []).add(n);
    }
    Widget row(String name, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(name)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
    return FigmaSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.nutritionFacts,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final g in groups.entries) ...[
            row(
              label(g.key.split('|').first),
              g.value
                          .map((n) => '${n.value} ${n.unit}'.trim())
                          .toSet()
                          .length ==
                      1
                  ? '${g.value.first.value} ${g.value.first.unit}'.trim()
                  : context.l10n.multipleNutrientMethods,
            ),
            const Divider(height: 1),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.l10n.moreNutrients),
            children: [
              for (final n in values)
                row(n.name, '${n.value} ${n.unit}'.trim()),
            ],
          ),
        ],
      ),
    );
  }
}
