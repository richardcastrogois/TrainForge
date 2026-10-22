import 'dart:async';
import 'package:flutter/material.dart';
import '../data/food_repository.dart';
import 'food_controller.dart';
import 'food_detail_page.dart';

class FoodPage extends StatefulWidget {
  final FoodController? controller;
  const FoodPage({super.key, this.controller});
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
    controller = widget.controller ?? FoodController(GoFoodRepository());
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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final facets = controller.facets;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Alimentos de referência',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              onPressed: controller.busy ? null : () => controller.load(),
              tooltip: 'Atualizar alimentos',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => controller.load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Composição das fontes Ciqual e CoFID. Consulta sem prescrição de dieta ou registro de consumo.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: search,
                          textInputAction: TextInputAction.search,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Buscar pelo nome original',
                            helperText:
                                'Nomes em francês ou inglês, conforme a fonte.',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              tooltip: 'Pesquisar alimentos',
                              onPressed: () => submit(search.text),
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
                        if (facets != null) ...[
                          Text(
                            '${facets.total} referências · ${facets.unknownBasis} sem base confirmada.',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Todas as fontes'),
                                selected: controller.sourceId.isEmpty,
                                onSelected: controller.busy
                                    ? null
                                    : (_) => controller.load(sourceId: ''),
                              ),
                              ...facets.sources.map(
                                (s) => ChoiceChip(
                                  label: Text('${s.name} (${s.count})'),
                                  selected: controller.sourceId == s.id,
                                  onSelected: controller.busy
                                      ? null
                                      : (_) => controller.load(sourceId: s.id),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Text(
                          'Preparo e idioma permanecem no nome original. Ausência, traço e limite não são zero. Fonte e licença em cada detalhe.',
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.busy)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Consultando alimentos',
                      ),
                    ),
                  )
                else if (controller.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _message(controller.error!, retry: true),
                  )
                else if (controller.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _message(
                      'Nenhum alimento corresponde à busca. Tente um termo no idioma original ou outra fonte.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                        return Card(
                          child: ListTile(
                            title: Text(food.displayName),
                            subtitle: Text(
                              '${food.source.name} · ${food.languageLabel}\n${food.basisLabel}\n${food.source.license} · ${food.sourceVersion}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => FoodDetailPage(
                                    food: food,
                                    repository: controller.repository,
                                  ),
                                ),
                              );
                              if (mounted) controller.load();
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
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
          const SizedBox(height: 16),
          if (retry)
            FilledButton(
              onPressed: () => controller.load(),
              child: const Text('Tentar novamente'),
            )
          else
            TextButton(
              onPressed: () {
                search.clear();
                controller.load(q: '', sourceId: '');
              },
              child: const Text('Limpar busca e fonte'),
            ),
        ],
      ),
    ),
  );
}
