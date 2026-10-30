import 'food_labels.dart';
import '../../nutrition/presentation/nutrition_facts.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import '../domain/food_reference.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodReference food;
  final FoodRepository repository;
  final bool selectForConsumption;
  final bool evidenceMode;
  const FoodDetailPage({
    super.key,
    required this.food,
    required this.repository,
    this.selectForConsumption = false,
    this.evidenceMode = false,
  });
  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with WidgetsBindingObserver {
  late Future<FoodDetailData> result;
  String? contentLocale;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = foodContentLocale(context);
    if (contentLocale == locale) return;
    contentLocale = locale;
    reload();
  }

  void reload() {
    final repository = widget.repository;
    result = repository is LocalizedFoodRepository
        ? (repository as LocalizedFoodRepository).localizedDetail(
            widget.food,
            locale: contentLocale!,
          )
        : repository.detail(widget.food);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(reload);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FigmaRouteFrame(
    body: SafeArea(
      child: FutureBuilder<FoodDetailData>(
        future: result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: FigmaBack(),
                ),
                AppLoading(label: context.l10n.loadingComposition),
              ],
            );
          }
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                FigmaPageHeading(
                  title: context.l10n.sourceComposition,
                  subtitle: context.l10n.referenceFood,
                ),
                FlowStatus(
                  title: context.l10n.compositionUnavailable,
                  message: context.l10n.foodVersionUnavailable,
                  actionLabel: context.l10n.retry,
                  onAction: () => setState(reload),
                ),
              ],
            );
          }
          final data = snapshot.data!, food = data.food, source = food.source;
          if (!widget.evidenceMode) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                FigmaPageHeading(
                  title: food.localizedName(context),
                  subtitle: food.localizedBasis(context),
                ),
                if (widget.selectForConsumption) ...[
                  FilledButton(
                    onPressed: () => Navigator.pop(context, food),
                    child: Text(context.l10n.useFoodVersion),
                  ),
                  const SizedBox(height: 12),
                ],
                NutritionFacts(
                  values: [
                    for (final n in data.nutrients)
                      (
                        name: n.displayName,
                        value: n.localizedMagnitude(context),
                        unit: n.unit ?? '',
                      ),
                  ],
                ),
              ],
            );
          }
          final reviewed = food.reviewedName;
          final usesReviewed =
              reviewed != null && reviewed.locale == foodContentLocale(context);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: data.nutrients.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FigmaPageHeading(
                      title: context.l10n.sourceComposition,
                      subtitle: context.l10n.originalFoodVersion,
                    ),
                    Text(
                      food.localizedName(context),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    if (!usesReviewed &&
                        food.localizedName(context) != food.displayName) ...[
                      Text(context.l10n.translationsExplanation),
                      Text(
                        '${context.l10n.originalFoodName}: ${food.displayName}',
                      ),
                    ],
                    if (usesReviewed) ...[
                      const SizedBox(height: 8),
                      Text(context.l10n.reviewedFoodName),
                      Text(
                        '${context.l10n.originalFoodName}: ${food.displayName}',
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(context.l10n.nameReviewSource),
                        children: [
                          SelectableText(reviewed.attribution),
                          Text(reviewed.license),
                          SelectableText(reviewed.licenseUrl),
                          SelectableText(
                            '${context.l10n.version}: ${reviewed.versionId}',
                          ),
                        ],
                      ),
                    ] else if (food.sourceId != 'personal') ...[
                      const SizedBox(height: 8),
                      Text(context.l10n.foodNameFallback),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${food.localizedLanguage(context)} · ${food.localizedBasis(context)}',
                    ),
                    const SizedBox(height: 8),
                    Text(context.l10n.foodQueryNotice),
                    TextButton(
                      onPressed: () => setState(reload),
                      child: Text(context.l10n.refreshComposition),
                    ),
                    if (widget.selectForConsumption)
                      FilledButton(
                        onPressed: () => Navigator.pop(context, food),
                        child: Text(context.l10n.useFoodVersion),
                      ),
                    const SizedBox(height: 16),
                    FigmaSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.sourceLicense,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(source.attribution),
                          Text(
                            '${source.license} · ${food.sourceVersion}\n${context.l10n.publication}: ${source.publishedAt}',
                          ),
                          SelectableText(source.url),
                          SelectableText(source.licenseUrl),
                          Text(source.warranty),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(context.l10n.provenanceConditions),
                            children: [
                              SelectableText(
                                '${source.publisher}\n${context.l10n.code}: ${food.sourceFoodId}\n${context.l10n.version}: ${food.versionId}\n${source.changes}\n${source.conditions.join('\n')}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.originalNutrients,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(context.l10n.nutrientMethodsNotice),
                    const SizedBox(height: 8),
                  ],
                );
              }
              final n = data.nutrients[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FigmaSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        n.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.localizedValue(context),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(n.localizedBasis(context)),
                      if (n.raw.isNotEmpty)
                        Text('${context.l10n.originalCell}: ${n.raw}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
