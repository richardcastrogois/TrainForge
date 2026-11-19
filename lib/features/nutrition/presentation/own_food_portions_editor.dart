import 'package:flutter/material.dart';

import '../../../core/l10n/localized_context.dart';
import '../domain/nutrition.dart';
import 'food_offline_labels.dart';

class FoodPortionDraft {
  final String id = mutationKey();
  final label = TextEditingController(),
      quantity = TextEditingController(),
      condition = TextEditingController();
  String unit = 'g';
  Json toJson() => {
    'id': id,
    'label': label.text.trim(),
    'quantity': decimal(quantity.text),
    'unit': unit,
    'condition': condition.text.trim(),
    'sourceId': 'personal',
  };
  void dispose() {
    label.dispose();
    quantity.dispose();
    condition.dispose();
  }
}

class OwnFoodPortionsEditor extends StatelessWidget {
  final List<FoodPortionDraft> portions;
  final bool locked;
  final VoidCallback changed;
  const OwnFoodPortionsEditor({
    super.key,
    required this.portions,
    required this.locked,
    required this.changed,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      Text(
        foodOfflineLabel(context, 'portion'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(foodOfflineLabel(context, 'personalPortionNotice')),
      for (final portion in portions)
        Card(
          key: ObjectKey(portion),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextFormField(
                  controller: portion.label,
                  enabled: !locked,
                  maxLength: 180,
                  decoration: InputDecoration(
                    labelText: foodOfflineLabel(context, 'portionLabel'),
                  ),
                  validator: (value) => (value ?? '').trim().isNotEmpty
                      ? null
                      : context.l10n.enterName,
                ),
                TextFormField(
                  controller: portion.quantity,
                  enabled: !locked,
                  maxLength: 14,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: context.l10n.quantity),
                  validator: (value) =>
                      validDecimal(decimal(value ?? ''), positive: true)
                      ? null
                      : context.l10n.nutritionCheckFields,
                ),
                DropdownButtonFormField<String>(
                  initialValue: portion.unit,
                  decoration: InputDecoration(
                    labelText: context.l10n.quantityUnit,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'g', child: Text('g')),
                    DropdownMenuItem(value: 'ml', child: Text('ml')),
                  ],
                  onChanged: locked
                      ? null
                      : (value) {
                          portion.unit = value!;
                          changed();
                        },
                ),
                TextFormField(
                  controller: portion.condition,
                  enabled: !locked,
                  maxLength: 180,
                  decoration: InputDecoration(
                    labelText: foodOfflineLabel(context, 'portionCondition'),
                  ),
                ),
                TextButton(
                  onPressed: locked
                      ? null
                      : () {
                          portions.remove(portion);
                          portion.dispose();
                          changed();
                        },
                  child: Text(context.l10n.removeField),
                ),
              ],
            ),
          ),
        ),
      OutlinedButton.icon(
        onPressed: locked || portions.length >= 32
            ? null
            : () {
                portions.add(FoodPortionDraft());
                changed();
              },
        icon: const Icon(Icons.add),
        label: Text(foodOfflineLabel(context, 'addPortion')),
      ),
    ],
  );
}
