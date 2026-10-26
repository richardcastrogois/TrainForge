import 'package:trainforge/core/l10n/read_feedback.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'dart:async';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import '../domain/catalog_entry.dart';
import 'catalog_controller.dart';
import 'catalog_detail_page.dart';

class CatalogPage extends StatefulWidget {
  final CatalogController? controller;
  final CatalogFilters? initialFilters;
  const CatalogPage({super.key, this.controller, this.initialFilters});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with WidgetsBindingObserver {
  late final CatalogController controller;
  final search = TextEditingController();
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller =
        widget.controller ??
        CatalogController(
          AppDependencyScope.read(context).createCatalogRepository(),
        );
    search.text = (widget.initialFilters ?? controller.filters).q;
    controller.load(filters: widget.initialFilters);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debounce?.cancel();
    search.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  Future<void> chooseFilters() async {
    final facets = controller.facets;
    if (facets == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    var selected = controller.filters;
    final result = await showModalBottomSheet<CatalogFilters>(
      context: context,
      sheetAnimationStyle: AppMotion.style(context),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, update) {
              Widget select(
                String title,
                String current,
                List<String> values,
                void Function(String) apply, {
                String? hint,
              }) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: current,
                  itemHeight: null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: title,
                    helperText: hint,
                    helperMaxLines: 3,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(context.l10n.allKnownValues),
                    ),
                    ...values.map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, softWrap: true),
                      ),
                    ),
                  ],
                  onChanged: (value) => update(() => apply(value ?? '')),
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.sourceFilters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.unknownNotAssumed),
                  const SizedBox(height: 20),
                  select(
                    context.l10n.category,
                    selected.category,
                    facets.categories,
                    (v) => selected = selected.copyWith(category: v),
                  ),
                  select(
                    context.l10n.equipment,
                    selected.equipment,
                    facets.equipment,
                    (v) => selected = selected.copyWith(equipment: v),
                  ),
                  select(
                    context.l10n.environment,
                    selected.environment,
                    facets.environments,
                    (v) => selected = selected.copyWith(environment: v),
                    hint: context.l10n.unknownEnvironment(
                      facets.unknownEnvironmentCount,
                    ),
                  ),
                  select(
                    context.l10n.audience,
                    selected.population,
                    facets.populations,
                    (v) => selected = selected.copyWith(population: v),
                    hint: context.l10n.unknownAudience(
                      facets.unknownPopulationCount,
                    ),
                  ),
                  select(
                    context.l10n.modality,
                    selected.modality,
                    facets.modalities,
                    (v) => selected = selected.copyWith(modality: v),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: Text(context.l10n.applyFilters),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (result != null && mounted) controller.load(filters: result);
  }

  void submit(String value) {
    debounce?.cancel();
    controller.load(filters: controller.filters.copyWith(q: value.trim()));
  }

  void clearFilters() {
    debounce?.cancel();
    search.clear();
    controller.load(filters: CatalogFilters(kind: controller.filters.kind));
  }

  Widget _header(BuildContext context, CatalogFacets? facets) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FigmaPageHeading(
          title: context.l10n.libraryTitle,
          subtitle: context.l10n.librarySubtitle,
        ),
        Text(context.l10n.metadataOnly),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: context.l10n.searchOriginal,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: context.l10n.search,
              onPressed: controller.busy
                  ? null
                  : () => controller.load(
                      filters: controller.filters.copyWith(
                        q: search.text.trim(),
                      ),
                    ),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
          onSubmitted: submit,
          onChanged: (value) {
            debounce?.cancel();
            debounce = Timer(
              const Duration(milliseconds: 400),
              () => submit(value),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: Text(
                '${context.l10n.movements}${facets == null ? '' : ' (${facets.movementCount})'}',
              ),
              selected: controller.filters.kind == 'movements',
              onSelected: controller.busy
                  ? null
                  : (_) => controller.load(
                      filters: controller.filters.copyWith(kind: 'movements'),
                    ),
            ),
            ChoiceChip(
              label: Text(
                '${context.l10n.programs}${facets == null ? '' : ' (${facets.programCount})'}',
              ),
              selected: controller.filters.kind == 'programs',
              onSelected: controller.busy
                  ? null
                  : (_) => controller.load(
                      filters: controller.filters.copyWith(kind: 'programs'),
                    ),
            ),
            TextButton.icon(
              onPressed: controller.busy || facets == null
                  ? null
                  : chooseFilters,
              icon: const Icon(Icons.filter_list),
              label: Text(context.l10n.filters),
            ),
            TextButton(
              onPressed: controller.busy ? null : clearFilters,
              child: Text(context.l10n.clear),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _notice(String text, {bool retry = false}) => Padding(
    padding: const EdgeInsets.all(24),
    child: FlowStatus(
      title: retry ? context.l10n.queryUnavailable : context.l10n.noResults,
      message: text,
      actionLabel: retry ? context.l10n.retry : context.l10n.clearFilters,
      onAction: retry ? () => controller.load() : clearFilters,
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      return FigmaRouteFrame(
        body: RefreshIndicator(
          onRefresh: () => controller.load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header(context, controller.facets)),
              if (controller.busy)
                SliverToBoxAdapter(
                  child: Center(
                    child: AppLoading(label: context.l10n.loadingLibrary),
                  ),
                )
              else if (controller.error != null)
                SliverToBoxAdapter(
                  child: _notice(
                    localizedReadFeedback(context, controller.error!),
                    retry: true,
                  ),
                )
              else if (controller.items.isEmpty)
                SliverToBoxAdapter(
                  child: _notice(
                    '${controller.filters.kind == 'programs' ? context.l10n.noProgramsBatch : context.l10n.noMetadataFilters}\n\n${context.l10n.audienceScope}',
                  ),
                )
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
                              Text(
                                localizedReadFeedback(
                                  context,
                                  controller.moreError!,
                                ),
                              ),
                            if (controller.nextCursor != null)
                              OutlinedButton(
                                onPressed: controller.loadingMore
                                    ? null
                                    : controller.more,
                                child: Text(
                                  controller.loadingMore
                                      ? context.l10n.loading
                                      : context.l10n.loadMore,
                                ),
                              ),
                          ],
                        );
                      }
                      final item = controller.items[index];
                      return FlowRecord(
                        title: item.title ?? context.l10n.titleNotProvided,
                        subtitle:
                            '${item.kind == 'movement'
                                ? context.l10n.movement
                                : item.kind == 'collection'
                                ? context.l10n.collection
                                : context.l10n.program} · ${item.sourceName} · ${item.locale ?? context.l10n.languageNotProvided}\n${context.l10n.credits}: ${(item.nameCreators.isNotEmpty ? item.nameCreators : item.creators).join(', ')}\n${item.licenseLabel ?? context.l10n.licenseNotProvided}\n${context.l10n.sourceInDetail}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CatalogDetailPage(
                              entry: item,
                              repository: controller.repository,
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
}
