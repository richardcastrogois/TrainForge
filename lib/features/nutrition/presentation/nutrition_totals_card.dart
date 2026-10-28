import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../domain/nutrition.dart';

/// Displays authoritative API totals; the client never scales or sums nutrients.
class NutritionTotalsCard extends StatelessWidget {
  final Json totals;
  const NutritionTotalsCard({super.key, required this.totals});
  @override
  Widget build(BuildContext context) => FigmaSection(
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        totals['complete'] == true
            ? context.l10n.daySubtotalCount(totals['entries'] as int)
            : context.l10n.subtotalLimit,
      ),
      children: [
        Text(
          totals['complete'] == true
              ? context.l10n.subtotalNotice
              : context.l10n.summaryLimit,
        ),
        if (totals['complete'] == true &&
            totals['measuredEntries'] is int &&
            totals['estimatedEntries'] is int)
          Text(
            context.l10n.quantityEvidenceCounts(
              totals['measuredEntries'] as int,
              totals['estimatedEntries'] as int,
            ),
          ),
        const SizedBox(height: 12),
        for (final n in objects(totals['nutrients']))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  displayLabel(n['nameOriginal']),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${n['value'] is String ? context.displayDecimal(n['value'] as String) : context.l10n.unknownValue} ${n['unit'] ?? ''}',
                ),
                Text(
                  context.l10n.nutrientCoverage(
                    n['includedEntries'] as int,
                    n['unknownEntries'] as int,
                  ),
                ),
                Text('${context.l10n.column}: ${n['sourceColumnKey']}'),
                const Divider(),
              ],
            ),
          ),
      ],
    ),
  );
}
