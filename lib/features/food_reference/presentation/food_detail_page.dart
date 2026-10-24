import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import '../domain/food_reference.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodReference food;
  final FoodRepository repository;
  final bool selectForConsumption;
  const FoodDetailPage({
    super.key,
    required this.food,
    required this.repository,
    this.selectForConsumption = false,
  });
  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage>
    with WidgetsBindingObserver {
  late Future<FoodDetailData> result;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  void reload() {
    result = widget.repository.detail(widget.food);
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
                const AppLoading(label: 'Consultando composição'),
              ],
            );
          }
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const FigmaPageHeading(
                  title: 'Composição da fonte',
                  subtitle: 'ALIMENTO DE REFERÊNCIA',
                ),
                FlowStatus(
                  title: 'Composição indisponível',
                  message:
                      'Este alimento está indisponível. Pode haver falha de conexão ou retirada da versão.',
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(reload),
                ),
              ],
            );
          }
          final data = snapshot.data!, food = data.food, source = food.source;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: data.nutrients.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FigmaPageHeading(
                      title: 'Composição da fonte',
                      subtitle: 'ALIMENTO · VERSÃO ORIGINAL',
                    ),
                    Text(
                      food.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${food.languageLabel} · ${food.basisLabel}'),
                    const SizedBox(height: 8),
                    Text(data.notice),
                    TextButton(
                      onPressed: () => setState(reload),
                      child: const Text('Atualizar composição'),
                    ),
                    if (widget.selectForConsumption)
                      FilledButton(
                        onPressed: () => Navigator.pop(context, food),
                        child: const Text(
                          'Usar esta versão para registrar consumo',
                        ),
                      ),
                    const SizedBox(height: 16),
                    FigmaSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Fonte e licença',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(source.attribution),
                          Text(
                            '${source.license} · ${food.sourceVersion}\nPublicação: ${source.publishedAt}',
                          ),
                          SelectableText(source.url),
                          SelectableText(source.licenseUrl),
                          Text(source.warranty),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Proveniência e condições'),
                            children: [
                              SelectableText(
                                '${source.publisher}\nCódigo: ${food.sourceFoodId}\nVersão: ${food.versionId}\n${source.changes}\n${source.conditions.join('\n')}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nutrientes e valores originais',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Métodos e colunas distintos permanecem separados. Cada valor informa sua própria base; nenhuma porção é calculada.',
                    ),
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
                        n.displayValue,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(n.basisLabel),
                      if (n.raw.isNotEmpty) Text('Célula original: ${n.raw}'),
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
