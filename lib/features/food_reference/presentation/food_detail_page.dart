import 'package:flutter/material.dart';
import '../domain/food_reference.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodReference food;
  final FoodRepository repository;
  const FoodDetailPage({
    super.key,
    required this.food,
    required this.repository,
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Composição da fonte'),
      actions: [
        IconButton(
          onPressed: () => setState(reload),
          tooltip: 'Atualizar composição',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<FoodDetailData>(
        future: result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Consultando composição',
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Este alimento está indisponível. Pode haver falha de conexão ou retirada da versão.',
                    ),
                    FilledButton(
                      onPressed: () => setState(reload),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!, food = data.food, source = food.source;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.nutrients.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      food.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('${food.languageLabel} · ${food.basisLabel}'),
                    const SizedBox(height: 8),
                    Text(data.notice),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
