import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import '../../food_reference/domain/food_reference.dart';
import '../../food_reference/presentation/food_labels.dart';
import '../../food_reference/presentation/food_page.dart';
import '../domain/nutrition.dart';
import 'nutrition_controller.dart';
import 'nutrition_feedback.dart';

/// A selection only. Reuses private read/pagination state and never records intake.
class OwnFoodPickerPage extends StatefulWidget {
  final NutritionRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final Future<FoodReference?> Function(BuildContext)? chooseReference;
  const OwnFoodPickerPage({
    super.key,
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    this.chooseReference,
  });
  @override
  State<OwnFoodPickerPage> createState() => _OwnFoodPickerPageState();
}

class _OwnFoodPickerPageState extends State<OwnFoodPickerPage> {
  late final NutritionController controller;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller = NutritionController(
      repository: widget.repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
    );
    widget.sessionChanges.addListener(accountChanged);
    controller.searchOwn();
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active && mounted) {
      search.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  void dispose() {
    widget.sessionChanges.removeListener(accountChanged);
    controller.dispose();
    search.dispose();
    super.dispose();
  }

  void choose(FoodReference food) {
    if (!controller.active || !mounted) return;
    Navigator.pop(context, food);
  }

  Future<void> library() async {
    if (!mounted || !controller.active) return;
    final FoodReference? food;
    if (widget.chooseReference != null) {
      food = await widget.chooseReference!(context);
    } else {
      food = await Navigator.push<FoodReference>(
        context,
        MaterialPageRoute(
          builder: (_) => const FoodPage(selectForConsumption: true),
        ),
      );
    }
    if (mounted && controller.active && food != null) choose(food);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => FigmaRouteFrame(
      body: RefreshIndicator(
        onRefresh: controller.searchOwn,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            FigmaPageHeading(
              title: context.l10n.mealOwnFoods,
              subtitle: context.l10n.mealOwnFoodsHint,
            ),
            OutlinedButton.icon(
              onPressed: library,
              icon: const Icon(Icons.search),
              label: Text(context.l10n.mealLibraryFood),
            ),
            TextField(
              controller: search,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: context.l10n.searchMyFoods,
              ),
              onChanged: controller.queryChanged,
              onSubmitted: controller.submitQuery,
            ),
            if (controller.ownLoading)
              AppLoading(label: context.l10n.loadingPrivateFoods),
            if (controller.ownError != null)
              FlowStatus(
                title: context.l10n.queryUnavailable,
                message: localizedNutritionFeedback(
                  context,
                  controller.ownError!,
                ),
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
            for (final raw in controller.foods)
              FlowRecord(
                title: asFood(raw).displayName,
                subtitle: asFood(raw).localizedBasis(context),
                onTap: () => choose(asFood(raw)),
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
      ),
    ),
  );
}
