import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/draft_guard.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../domain/meals.dart';
import 'meal_metadata_controller.dart';
import 'nutrition_feedback.dart';
import 'nutrition_forms.dart';

class MealMetadataPage extends StatefulWidget {
  final MealRepository repository;
  final MealMetadata meal;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  const MealMetadataPage({
    super.key,
    required this.repository,
    required this.meal,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
  });
  @override
  State<MealMetadataPage> createState() => _MealMetadataPageState();
}

class _MealMetadataPageState extends State<MealMetadataPage> {
  late final MealMetadataController controller;
  late final TextEditingController title;
  final guard = GlobalKey<DraftGuardState>();
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    controller = MealMetadataController(
      repository: widget.repository,
      original: widget.meal,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
    );
    title = TextEditingController(text: controller.title);
    widget.sessionChanges.addListener(accountChanged);
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active && mounted) {
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

  Future<void> pickTime() async {
    if (!controller.active || controller.locked) return;
    final when = controller.when;
    final date = await showDatePicker(
      context: context,
      initialDate: when,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !mounted || !controller.active) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
    );
    if (time == null || !mounted || !controller.active) return;
    controller.setWhen(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
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
                title: context.l10n.correctMeal,
                subtitle: context.l10n.mealMetadataOnly,
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
                  '${context.displayTimestamp(controller.when.toIso8601String())} · ${controller.timezone}',
                ),
              ),
              CheckboxListTile(
                value: controller.reviewed,
                onChanged: controller.locked
                    ? null
                    : (value) => controller.setReviewed(value ?? false),
                title: Text(context.l10n.mealMetadataReview),
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
                              (!controller.reviewed || !controller.dirty))
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
