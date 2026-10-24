import 'dart:async';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import '../data/catalog_repository.dart';
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
    controller = widget.controller ?? CatalogController(GoCatalogRepository());
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
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos os valores informados'),
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
                    'Filtros da fonte',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Valores não informados não são adaptados nem classificados por suposição.',
                  ),
                  const SizedBox(height: 20),
                  select(
                    'Categoria',
                    selected.category,
                    facets.categories,
                    (v) => selected = selected.copyWith(category: v),
                  ),
                  select(
                    'Equipamento',
                    selected.equipment,
                    facets.equipment,
                    (v) => selected = selected.copyWith(equipment: v),
                  ),
                  select(
                    'Ambiente',
                    selected.environment,
                    facets.environments,
                    (v) => selected = selected.copyWith(environment: v),
                    hint:
                        '${facets.unknownEnvironmentCount} registros sem ambiente informado.',
                  ),
                  select(
                    'Público',
                    selected.population,
                    facets.populations,
                    (v) => selected = selected.copyWith(population: v),
                    hint:
                        '${facets.unknownPopulationCount} registros sem público informado.',
                  ),
                  select(
                    'Modalidade',
                    selected.modality,
                    facets.modalities,
                    (v) => selected = selected.copyWith(modality: v),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Aplicar filtros'),
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
        const FigmaPageHeading(
          title: 'Biblioteca de referência',
          subtitle: 'MOVIMENTO · ORIGEM · DISPONIBILIDADE',
        ),
        const Text(
          'Somente consulta. Estes registros não são instruções nem programas liberados para prática.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar pelo nome original',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Pesquisar',
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
                'Movimentos${facets == null ? '' : ' (${facets.movementCount})'}',
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
                'Programas${facets == null ? '' : ' (${facets.programCount})'}',
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
              label: const Text('Filtros'),
            ),
            TextButton(
              onPressed: controller.busy ? null : clearFilters,
              child: const Text('Limpar'),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _notice(String text, {bool retry = false}) => Padding(
    padding: const EdgeInsets.all(24),
    child: FlowStatus(
      title: retry ? 'Consulta indisponível' : 'Sem resultados',
      message: text,
      actionLabel: retry ? 'Tentar novamente' : 'Limpar filtros',
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
                const SliverToBoxAdapter(
                  child: Center(
                    child: AppLoading(label: 'Consultando biblioteca'),
                  ),
                )
              else if (controller.error != null)
                SliverToBoxAdapter(
                  child: _notice(controller.error!, retry: true),
                )
              else if (controller.items.isEmpty)
                SliverToBoxAdapter(
                  child: _notice(
                    '${controller.filters.kind == 'programs' ? 'Nenhum programa autorizado neste lote.' : 'Nenhum metadado corresponde aos filtros.'}\n\nIdosos, cuidadores, casa, praça e academia continuam no escopo. A fonte precisa informar requisitos e permissão para cada uso.',
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
                              Text(controller.moreError!),
                            if (controller.nextCursor != null)
                              OutlinedButton(
                                onPressed: controller.loadingMore
                                    ? null
                                    : controller.more,
                                child: Text(
                                  controller.loadingMore
                                      ? 'Carregando…'
                                      : 'Carregar mais',
                                ),
                              ),
                          ],
                        );
                      }
                      final item = controller.items[index];
                      return FlowRecord(
                        title: item.title ?? 'Título não informado pela fonte',
                        subtitle:
                            '${item.kind == 'movement'
                                ? 'Movimento'
                                : item.kind == 'collection'
                                ? 'Coleção modular'
                                : 'Programa'} · ${item.sourceName} · ${item.locale ?? 'Idioma não informado'}\nCréditos: ${(item.nameCreators.isNotEmpty ? item.nameCreators : item.creators).join(', ')}\n${item.licenseLabel ?? 'Licença não informada'}\nFonte e licença no detalhe · Somente consulta',
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
