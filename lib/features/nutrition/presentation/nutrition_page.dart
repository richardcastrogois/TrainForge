import 'nutrition_totals_card.dart';
import 'meal_diary_page.dart';
import '../domain/meals.dart';
import 'package:trainforge/features/food_reference/presentation/food_labels.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'nutrition_controller.dart';
import 'nutrition_feedback.dart';
import '../domain/nutrition.dart';
import 'nutrition_forms.dart';
import 'entry_detail_page.dart';

class NutritionPage extends StatefulWidget {
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final NutritionRepository? repository;
  final DateTime? initialDate;
  const NutritionPage({
    super.key,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    this.repository,
    this.initialDate,
  });
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver {
  late final NutritionRepository repository;
  late final NutritionController controller;
  final search = TextEditingController();
  bool get active => mounted && controller.active;

  @override
  void initState() {
    super.initState();
    repository =
        widget.repository ??
        AppDependencyScope.read(context).createNutritionRepository(
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
        );
    controller = NutritionController(
      repository: repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
      initialDate: widget.initialDate,
    );
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    controller.searchOwn();
  }

  String? _contentLocale;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = foodContentLocale(context);
    if (value == _contentLocale) return;
    final first = _contentLocale == null;
    _contentLocale = value;
    if (value != controller.locale) {
      controller.selectLocale(value);
    } else if (first) {
      controller.load();
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
      if (active) {
        controller.load();
        controller.searchOwn();
      }
    }
  }

  @override
  void dispose() {
    search.dispose();
    widget.sessionChanges.removeListener(accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Future<void> record(FoodReference food) async {
    if (!active) return;
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(food: food, repository: repository),
      ),
    );
    if (!active) return;
    await controller.load();
    if (active && result != null) await detail(result);
  }

  Future<void> detail(Json entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(entry: entry, repository: repository),
      ),
    );
    if (active) await controller.load();
  }

  Future<void> chooseReference() async {
    final food = await Navigator.push<FoodReference>(
      context,
      MaterialPageRoute(
        builder: (_) => const FoodPage(selectForConsumption: true),
      ),
    );
    if (active && food != null) await record(food);
  }

  Future<void> meals() async {
    final source = repository;
    if (!active || source is! MealRepository) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MealDiaryPage(
          repository: source as MealRepository,
          nutrition: repository,
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
          sessionChanges: widget.sessionChanges,
          initialDate: controller.date,
        ),
      ),
    );
    if (active) await controller.load();
  }

  Future<void> createFood() async {
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnFoodFormPage(repository: repository),
      ),
    );
    if (!active) return;
    await controller.searchOwn();
    if (mounted && active && result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.ownFoodSaved)));
    }
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: controller.date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (chosen != null && active) {
      await controller.selectDate(chosen);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => DefaultTabController(
      length: 2,
      child: FigmaRouteFrame(
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: context.l10n.intake),
                Tab(text: context.l10n.myFoods),
              ],
            ),
            Expanded(
              child: TabBarView(children: [consumptionList(), ownFoodList()]),
            ),
          ],
        ),
      ),
    ),
  );

  Widget heading(String subtitle) =>
      FigmaPageHeading(title: context.l10n.myNutrition, subtitle: subtitle);

  Widget consumptionList() => RefreshIndicator(
    onRefresh: controller.load,
    child: ListView(
      key: const PageStorageKey('nutrition-consumption'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading(context.l10n.confirmedDiaryUpper),
        if (repository is MealRepository)
          OutlinedButton.icon(
            onPressed: meals,
            icon: const Icon(Icons.restaurant),
            label: Text(context.l10n.viewMeals),
          ),
        OutlinedButton.icon(
          onPressed: chooseDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            '${context.displayDate(controller.date)} · ${offsetZone(controller.date)}',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: chooseReference,
          icon: const Icon(Icons.search),
          label: Text(context.l10n.searchRecordFood),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.diaryNoPrescription),
        const SizedBox(height: 16),
        if (controller.loading)
          AppLoading(label: context.l10n.loadingNutrition),
        if (controller.error != null) _error(),
        if (!controller.loading &&
            controller.error == null &&
            controller.entries.isEmpty)
          FlowStatus(
            title: context.l10n.noIntakeDay,
            message: context.l10n.noIntakeHint,
          ),
        for (final entry in controller.entries)
          FlowRecord(
            title: entryDisplayName(entry, foodContentLocale(context)),
            subtitle:
                '''${context.displayDecimal(entry['quantity'] as String)} ${entry['unit']} · ${object(entry['calculation'])['quantityEvidence'] == 'measured' ? context.l10n.measuredShort : context.l10n.estimatedShort}
${context.displayTimestamp(entry['occurredAt'] as String)}''',
            onTap: () => detail(entry),
          ),
        if (controller.cursor != null)
          OutlinedButton(
            onPressed: controller.moreBusy
                ? null
                : () => controller.more(false),
            child: Text(
              controller.moreBusy
                  ? context.l10n.loading
                  : context.l10n.moreRecords,
            ),
          ),
        if (controller.summary != null)
          NutritionTotalsCard(totals: controller.summary!),
      ],
    ),
  );

  Widget ownFoodList() => RefreshIndicator(
    onRefresh: controller.searchOwn,
    child: ListView(
      key: const PageStorageKey('nutrition-own-foods'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading(context.l10n.privateFoodsUpper),
        FilledButton.icon(
          onPressed: createFood,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.createOwnFood),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.privateFoodsHint),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(labelText: context.l10n.searchMyFoods),
          onChanged: controller.queryChanged,
          onSubmitted: controller.submitQuery,
        ),
        const SizedBox(height: 12),
        if (controller.ownLoading)
          AppLoading(label: context.l10n.loadingPrivateFoods),
        if (controller.ownError != null)
          FlowStatus(
            title: context.l10n.queryUnavailable,
            message: localizedNutritionFeedback(context, controller.ownError!),
            actionLabel: context.l10n.retry,
            onAction: controller.searchOwn,
          ),
        if (!controller.ownLoading &&
            controller.ownError == null &&
            controller.foods.isEmpty)
          FlowStatus(
            title: context.l10n.noPrivateResults,
            message: context.l10n.noPrivateHint,
          ),
        for (final food in controller.foods)
          FlowRecord(
            title: asFood(food).displayName,
            subtitle:
                '${asFood(food).localizedBasis(context)}\n${context.l10n.privatePortionHint}',
            onTap: () => record(asFood(food)),
          ),
        if (controller.ownCursor != null)
          OutlinedButton(
            onPressed: controller.ownMoreBusy
                ? null
                : () => controller.more(true),
            child: Text(
              controller.ownMoreBusy
                  ? context.l10n.loading
                  : context.l10n.morePrivateFoods,
            ),
          ),
      ],
    ),
  );

  Widget _error() => FlowStatus(
    title: context.l10n.queryUnavailable,
    message: localizedNutritionFeedback(context, controller.error!),
    actionLabel: context.l10n.retry,
    onAction: controller.load,
  );
}
