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
  const FoodPage({
    super.key,
    this.controller,
    this.selectForConsumption = false,
  });
  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> with WidgetsBindingObserver {
  late final FoodController controller;
  final search = TextEditingController();
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller =
        widget.controller ??
        FoodController(AppDependencyScope.read(context).createFoodRepository());
    search.text = controller.q;
    controller.load();
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
                        title: 'Resultados da pesquisa',
                        subtitle: controller.q.isEmpty
                            ? 'ALIMENTOS DE REFERÊNCIA'
                            : 'PESQUISA · ${controller.q}',
                      ),
                      TextField(
                        controller: search,
                        textInputAction: TextInputAction.search,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: 'Buscar pelo nome original',
                          hintText: 'Alimento ou preparo',
                          helperText:
                              'Nomes em francês ou inglês, conforme a fonte.',
                          helperMaxLines: 3,
                          suffixIcon: TextButton(
                            onPressed: () => submit(search.text),
                            child: Text('Pesquisar'),
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
                      if (facets != null) ...[
                        SizedBox(height: 12),
                        Text(
                          '${facets.total} referências · ${facets.unknownBasis} sem base confirmada.',
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
                            sourceChip('Todas as fontes', ''),
                            for (final source in facets.sources)
                              sourceChip(
                                '${source.name} (${source.count})',
                                source.id,
                              ),
                          ],
                        ),
                      ],
                      SizedBox(height: 12),
                      Text(
                        'Preparo e idioma permanecem no nome original. Ausência, traço e limite não são zero. Fonte e licença em cada detalhe.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: context.tf.muted,
                        ),
                      ),
                      if (!widget.selectForConsumption)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Consulta sem prescrição de dieta ou registro de consumo.',
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
                    child: AppLoading(label: 'Consultando alimentos'),
                  ),
                )
              else if (controller.error != null)
                SliverToBoxAdapter(
                  child: _message(controller.error!, retry: true),
                )
              else if (controller.items.isEmpty)
                SliverToBoxAdapter(
                  child: _message(
                    'Nenhum alimento corresponde à busca. Tente um termo no idioma original ou outra fonte.',
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
                              Semantics(
                                liveRegion: true,
                                child: Text(controller.moreError!),
                              ),
                            if (controller.cursor != null)
                              OutlinedButton(
                                onPressed: controller.loadingMore
                                    ? null
                                    : controller.more,
                                child: Text(
                                  controller.loadingMore
                                      ? 'Carregando…'
                                      : 'Carregar mais alimentos',
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
                                    food.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${food.source.name} · ${food.languageLabel}\n${food.basisLabel}\n${food.source.license} · ${food.sourceVersion}',
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
              child: Text('Tentar novamente'),
            )
          else
            TextButton(
              onPressed: () {
                search.clear();
                controller.load(q: '', sourceId: '');
              },
              child: Text('Limpar busca e fonte'),
            ),
        ],
      ),
    ),
  );
}
