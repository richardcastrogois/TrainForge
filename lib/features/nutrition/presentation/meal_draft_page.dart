import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/draft_guard.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../../food_reference/domain/food_reference.dart';
import '../../food_reference/presentation/food_labels.dart';
import '../../food_reference/presentation/food_page.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import 'meal_controllers.dart';
import 'nutrition_feedback.dart';
import 'nutrition_forms.dart';

class MealDraftPage extends StatefulWidget {
  final MealRepository repository;
  final NutritionRepository nutrition;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final Future<FoodReference?> Function(BuildContext)? chooseFood;
  final DateTime? initialWhen;
  const MealDraftPage({
    super.key,
    required this.repository,
    required this.nutrition,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    this.chooseFood,
    this.initialWhen,
  });
  @override
  State<MealDraftPage> createState() => _MealDraftPageState();
}

class _MealDraftPageState extends State<MealDraftPage> {
  late final MealDraftController controller;
  final guard = GlobalKey<DraftGuardState>();
  final title = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    controller = MealDraftController(
      repository: widget.repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
      occurredAt: widget.initialWhen ?? DateTime.now(),
    );
    widget.sessionChanges.addListener(accountChanged);
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active) {
      title.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  void dispose() {
    widget.sessionChanges.removeListener(accountChanged);
    controller.dispose();
    title.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (!controller.active ||
        controller.locked ||
        controller.items.length >= 32) {
      return;
    }
    final FoodReference? food;
    if (widget.chooseFood != null) {
      food = await widget.chooseFood!(context);
    } else {
      food = await Navigator.push<FoodReference>(
        context,
        MaterialPageRoute(
          builder: (_) => const FoodPage(selectForConsumption: true),
        ),
      );
    }
    if (!mounted) return;
    final selectedFood = food;
    if (!controller.active || selectedFood == null) return;
    final input = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(
          food: selectedFood,
          repository: widget.nutrition,
          prepareForMeal: true,
          initialWhen: controller.when,
        ),
      ),
    );
    if (!mounted || !controller.active || input == null) return;
    controller.add(selectedFood, input);
  }

  Future<void> pickTime() async {
    if (controller.locked) return;
    final when = controller.when;
    final day = await showDatePicker(
      context: context,
      initialDate: when,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (day == null || !mounted || !controller.active) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
    );
    if (time != null && mounted && controller.active) {
      controller.setWhen(
        DateTime(day.year, day.month, day.day, time.hour, time.minute),
      );
    }
  }

  Future<void> submit() async {
    if (!controller.uncertain && !validateNutritionForm(form, context)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await controller.submit();
    if (mounted && controller.active && controller.confirmed != null) {
      guard.currentState!.complete(controller.confirmed);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => DraftGuard(
      key: guard,
      dirty: controller.dirty,
      busy: controller.busy,
      uncertain: controller.uncertain,
      uncertainMessage: controller.conflict
          ? context.l10n.mealConflictNotice
          : null,
      child: FigmaRouteFrame(
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              FigmaPageHeading(
                title: context.l10n.recordMeal,
                subtitle: context.l10n.mealDraftNotice,
              ),
              TextFormField(
                controller: title,
                enabled: !controller.locked,
                maxLength: 80,
                decoration: InputDecoration(labelText: context.l10n.mealTitle),
                onChanged: controller.setTitle,
                validator: (value) => value != null && value.runes.length <= 80
                    ? null
                    : context.l10n.nutritionCheckFields,
              ),
              OutlinedButton.icon(
                onPressed: controller.locked ? null : pickTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  '${context.displayTimestamp(controller.when.toIso8601String())} · ${offsetZone(controller.when)}',
                ),
              ),
              Text(context.l10n.mealMetadataOnly),
              const SizedBox(height: 16),
              if (controller.items.isEmpty) Text(context.l10n.mealNoItems),
              for (var i = 0; i < controller.items.length; i++)
                FigmaSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        controller.items[i].food.localizedName(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${context.displayDecimal(controller.items[i].input['quantity'] as String)} ${controller.items[i].input['unit']}',
                      ),
                      Text(context.l10n.mealItemPending),
                      TextButton.icon(
                        onPressed: controller.locked
                            ? null
                            : () => controller.remove(i),
                        icon: const Icon(Icons.remove_circle_outline),
                        label: Text(context.l10n.removeMealItem),
                      ),
                    ],
                  ),
                ),
              if (controller.items.length >= 32)
                Text(context.l10n.mealDraftLimit),
              OutlinedButton.icon(
                onPressed: controller.locked || controller.items.length >= 32
                    ? null
                    : add,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addMealItem),
              ),
              CheckboxListTile(
                value: controller.reviewed,
                onChanged: controller.locked
                    ? null
                    : (value) => controller.setReviewed(value ?? false),
                title: Text(context.l10n.mealReviewConfirmation),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (controller.error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    controller.conflict
                        ? context.l10n.mealConflictNotice
                        : localizedNutritionFeedback(
                            context,
                            controller.error!,
                          ),
                  ),
                ),
              if (controller.uncertain && !controller.conflict)
                Text(context.l10n.intakeUncertain),
              if (controller.conflict)
                OutlinedButton(
                  onPressed: () => guard.currentState!.complete(null),
                  child: Text(context.l10n.leaveCheckHistory),
                )
              else
                FilledButton(
                  onPressed:
                      controller.busy ||
                          (!controller.uncertain &&
                              (!controller.reviewed ||
                                  controller.items.isEmpty))
                      ? null
                      : submit,
                  child: Text(
                    controller.busy
                        ? context.l10n.confirming
                        : controller.uncertain
                        ? context.l10n.retryConfirmation
                        : context.l10n.confirmMeal,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
