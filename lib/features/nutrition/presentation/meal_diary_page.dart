import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import '../../food_reference/presentation/food_labels.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import 'entry_detail_page.dart';
import 'meal_controllers.dart';
import 'meal_draft_page.dart';
import 'meal_detail_page.dart';
import 'nutrition_feedback.dart';
import 'nutrition_totals_card.dart';

class MealDiaryPage extends StatefulWidget {
  final bool evidenceMode;
  final MealRepository repository;
  final NutritionRepository nutrition;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final DateTime initialDate;
  const MealDiaryPage({
    super.key,
    required this.repository,
    required this.nutrition,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    required this.initialDate,
    this.evidenceMode = false,
  });
  @override
  State<MealDiaryPage> createState() => _MealDiaryPageState();
}

class _MealDiaryPageState extends State<MealDiaryPage>
    with WidgetsBindingObserver {
  late final MealDiaryController controller;
  String? _locale;
  bool byMeal = true;
  @override
  void initState() {
    super.initState();
    controller = MealDiaryController(
      repository: widget.repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
      date: widget.initialDate,
      locale: 'pt-BR',
    );
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = foodContentLocale(context);
    if (value != _locale) {
      _locale = value;
      controller.load(selectedLocale: value);
    }
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      accountChanged();
      if (controller.active) controller.load();
    }
  }

  @override
  void dispose() {
    widget.sessionChanges.removeListener(accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null && mounted && controller.active) {
      await controller.load(selectedDate: date);
    }
  }

  Future<void> record() async {
    final now = DateTime.now();
    final day = controller.date;
    final result = await Navigator.push<ConfirmedMeal>(
      context,
      MaterialPageRoute(
        builder: (_) => MealDraftPage(
          repository: widget.repository,
          nutrition: widget.nutrition,
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
          sessionChanges: widget.sessionChanges,
          initialWhen: DateTime(
            day.year,
            day.month,
            day.day,
            now.hour,
            now.minute,
          ),
        ),
      ),
    );
    if (!mounted || !controller.active) return;
    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.mealSaved)));
    }
    await controller.load(
      selectedDate: result == null
          ? null
          : DateTime.parse(
              result.entries.first['occurredAt'] as String,
            ).toLocal(),
    );
    if (result != null && mounted && controller.active) {
      await meal(result.meal.id);
    }
  }

  Future<void> entry(Json value) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(
          entry: value,
          repository: widget.nutrition,
          evidenceMode: widget.evidenceMode,
        ),
      ),
    );
    if (mounted && controller.active) await controller.load();
  }

  Future<void> meal(String id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MealDetailPage(
          evidenceMode: widget.evidenceMode,
          id: id,
          repository: widget.repository,
          nutrition: widget.nutrition,
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
          sessionChanges: widget.sessionChanges,
        ),
      ),
    );
    if (mounted && controller.active) await controller.load();
  }

  Widget entryRow(Json value) => FlowRecord(
    title: entryDisplayName(value, foodContentLocale(context)),
    subtitle:
        '${context.displayDecimal(value['quantity'] as String)} ${value['unit']} · ${context.displayTimestamp(value['occurredAt'] as String)}',
    onTap: () => entry(value),
  );
  List<Widget> records(MealDay day) {
    final byId = {
      for (final value in day.entries) value['id'] as String: value,
    };
    if (!byMeal) return day.entries.map(entryRow).toList();
    return [
      for (final group in day.meals)
        FlowRecord(
          title: group.meal.title.isEmpty
              ? context.l10n.mealUnnamed
              : group.meal.title,
          subtitle:
              '${context.l10n.mealItemCount(group.meal.totalActiveItems)} · ${context.displayTimestamp(group.meal.occurredAt)}${group.otherActiveItems == 0 ? '' : '\n${context.l10n.mealOtherItems(group.otherActiveItems)}'}',
          onTap: () => meal(group.meal.id),
        ),
      if (day.ungroupedEntryIds.isNotEmpty)
        FlowSectionTitle(context.l10n.ungroupedIntakes),
      for (final id in day.ungroupedEntryIds) entryRow(byId[id]!),
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => FigmaRouteFrame(
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            FigmaPageHeading(
              title: context.l10n.mealDiary,
              subtitle: context.l10n.mealDayScope,
            ),
            OutlinedButton.icon(
              onPressed: chooseDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${context.displayDate(controller.date)} · ${offsetZone(controller.date)}',
              ),
            ),
            FilledButton.icon(
              onPressed: record,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.recordMeal),
            ),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.byMeal),
                  selected: byMeal,
                  onSelected: (_) => setState(() => byMeal = true),
                ),
                ChoiceChip(
                  label: Text(context.l10n.byFood),
                  selected: !byMeal,
                  onSelected: (_) => setState(() => byMeal = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.loading)
              AppLoading(label: context.l10n.loadingNutrition),
            if (controller.error != null)
              FlowStatus(
                title: context.l10n.queryUnavailable,
                message: localizedNutritionFeedback(context, controller.error!),
                actionLabel: context.l10n.retry,
                onAction: controller.load,
              ),
            if (controller.day != null) ...[
              if (controller.day!.entries.isEmpty)
                FlowStatus(
                  title: context.l10n.noIntakeDay,
                  message: context.l10n.noIntakeHint,
                ),
              ...records(controller.day!),
              NutritionTotalsCard(totals: controller.day!.totals),
            ],
          ],
        ),
      ),
    ),
  );
}
