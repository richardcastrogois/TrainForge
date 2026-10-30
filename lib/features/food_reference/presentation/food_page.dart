import 'food_labels.dart';
import 'package:trainforge/core/l10n/read_feedback.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'food_controller.dart';
import '../domain/food_reference.dart';
import 'food_detail_page.dart';

class FoodPage extends StatefulWidget {
  final FoodController? controller;
  final bool selectForConsumption;
  final bool evidenceMode;
  const FoodPage({
    super.key,
    this.controller,
    this.selectForConsumption = false,
    this.evidenceMode = false,
  });
  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> with WidgetsBindingObserver {
  late final FoodController controller;
  final search = TextEditingController();
  Timer? debounce;
  String? contentLocale;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller =
        widget.controller ??
        FoodController(AppDependencyScope.read(context).createFoodRepository());
    search.text = controller.q;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = foodContentLocale(context);
    if (contentLocale == locale) return;
    contentLocale = locale;
    debounce?.cancel();
    controller.load(locale: locale, q: search.text.trim());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.load();
  }

  void submit(String value) {
    debounce?.cancel();
    controller.load(q: value.trim());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debounce?.cancel();
    search.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  Future<void> openFood(FoodReference food) async {
    final selected = await Navigator.push<FoodReference>(
      context,
      MaterialPageRoute<FoodReference>(
        builder: (_) => FoodDetailPage(
          food: food,
          repository: controller.repository,
          selectForConsumption: widget.selectForConsumption,
          evidenceMode: widget.evidenceMode,
        ),
      ),
    );
    if (!mounted) return;
    if (selected != null && widget.selectForConsumption) {
      Navigator.pop(context, selected);
      return;
    }
    controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final facets = controller.facets;
      return FigmaRouteFrame(
        body: RefreshIndicator(
          onRefresh: () => controller.load(),
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FigmaPageHeading(
                        title: context.l10n.searchResults,
                        subtitle: controller.q.isEmpty
                            ? context.l10n.foodReferences
                            : context.l10n.searchFor(controller.q),
                      ),
                      TextField(
                        controller: search,
                        textInputAction: TextInputAction.search,
                        maxLength: 100,
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: controller.localizedNames
                              ? context.l10n.searchFoodNames
                              : context.l10n.searchOriginal,
                          hintText: context.l10n.foodPreparation,
                          helperText: !widget.evidenceMode
                              ? null
                              : controller.localizedNames
                              ? context.l10n.reviewedNamesHint
                              : context.l10n.originalNamesHint,
                          helperMaxLines: 3,
                          suffixIcon: TextButton(
                            onPressed: () => submit(search.text),
                            child: Text(context.l10n.search),
                          ),
                        ),
                        onSubmitted: submit,
                        onChanged: (value) {
                          debounce?.cancel();
                          debounce = Timer(
                            Duration(milliseconds: 400),
                            () => submit(value),
                          );
                        },
                      ),
                      if (!widget.evidenceMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final choice in [
                                context.l10n.commonRice,
                                context.l10n.commonBrownRice,
                                context.l10n.commonRedBeans,
                              ])
                                ActionChip(
                                  label: Text(choice),
                                  onPressed: () {
                                    search.text = choice;
                                    submit(choice);
                                  },
                                ),
                            ],
                          ),
                        ),
                      if (controller.catalogChanged)
                        Semantics(
                          liveRegion: true,
                          child: Text(context.l10n.nameCatalogChanged),
                        ),
                      if (widget.evidenceMode && facets != null) ...[
                        SizedBox(height: 12),
                        Text(
                          context.l10n.foodCoverage(
                            facets.total,
                            facets.unknownBasis,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: context.tf.muted,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            sourceChip(context.l10n.allSources, ''),
                            for (final source in facets.sources)
                              sourceChip(
                                '${source.name} (${source.count})',
                                source.id,
                              ),
                          ],
                        ),
                      ],
                      SizedBox(height: 12),
                      if (widget.evidenceMode)
                        Text(
                          context.l10n.originalFoodNotice,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: context.tf.muted,
                          ),
                        ),
                      if (widget.evidenceMode && !widget.selectForConsumption)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            context.l10n.readOnlyFood,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: context.tf.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (controller.busy)
                SliverToBoxAdapter(
                  child: Center(
                    child: AppLoading(label: context.l10n.loadingFood),
                  ),
                )
              else if (controller.error != null)
                SliverToBoxAdapter(
                  child: _message(
                    localizedReadFeedback(context, controller.error!),
                    retry: true,
                  ),
                )
              else if (controller.items.isEmpty)
                SliverToBoxAdapter(child: _message(context.l10n.noFoodResults))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  sliver: SliverList.builder(
                    itemCount: controller.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == controller.items.length) {
                        return Column(
                          children: [
                            if (controller.moreError != null)
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  localizedReadFeedback(
                                    context,
                                    controller.moreError!,
                                  ),
                                ),
                              ),
                            if (controller.cursor != null)
                              OutlinedButton(
                                onPressed: controller.loadingMore
                                    ? null
                                    : controller.more,
                                child: Text(
                                  controller.loadingMore
                                      ? context.l10n.loading
                                      : context.l10n.moreFood,
                                ),
                              ),
                          ],
                        );
                      }
                      final food = controller.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: context.tf.nutrition,
                          borderRadius: BorderRadius.circular(22),
                          child: InkWell(
                            onTap: () => openFood(food),
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    food.localizedName(context),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.evidenceMode
                                        ? '${food.source.name} · ${food.localizedLanguage(context)}\n${food.localizedBasis(context)}\n${food.source.license} · ${food.sourceVersion}'
                                        : food.localizedBasis(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.35,
                                      color: context.tf.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  Widget sourceChip(String label, String id) => ChoiceChip(
    label: Text(label),
    selected: controller.sourceId == id,
    backgroundColor: context.tf.surface,
    selectedColor: context.tf.primary,
    labelStyle: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: controller.sourceId == id
          ? context.tf.onPrimary
          : context.tf.primary,
    ),
    shape: StadiumBorder(),
    side: BorderSide.none,
    showCheckmark: false,
    onSelected: controller.busy ? null : (_) => controller.load(sourceId: id),
  );
  Widget _message(String text, {bool retry = false}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(text, textAlign: TextAlign.center),
          ),
          SizedBox(height: 16),
          if (retry)
            FilledButton(
              onPressed: () => controller.load(),
              child: Text(context.l10n.retry),
            )
          else
            TextButton(
              onPressed: () {
                search.clear();
                controller.load(q: '', sourceId: '');
              },
              child: Text(context.l10n.clearSearch),
            ),
        ],
      ),
    ),
  );
}
