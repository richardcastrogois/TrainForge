import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import '../data/nutrition_repository.dart';
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
  DateTime date = DateTime.now();
  bool loading = true, moreBusy = false, ownMoreBusy = false, ownLoading = true;
  String? error, ownError, cursor, ownCursor;
  List<Json> entries = [], foods = [];
  Json? summary;
  int generation = 0, ownGeneration = 0;
  final search = TextEditingController();
  String ownQuery = '';
  Timer? debounce;
  bool get active => mounted && widget.currentAccountId() == widget.accountId;
  @override
  void initState() {
    super.initState();
    date = widget.initialDate ?? DateTime.now();
    repository =
        widget.repository ??
        GoNutritionRepository(
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
        );
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    load();
    searchOwn();
  }

  void accountChanged() {
    if (widget.currentAccountId() != widget.accountId) {
      generation++;
      ownGeneration++;
      entries = [];
      foods = [];
      summary = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      accountChanged();
      if (active) {
        load();
        searchOwn();
      }
    }
  }

  @override
  void dispose() {
    generation++;
    ownGeneration++;
    debounce?.cancel();
    search.dispose();
    widget.sessionChanges.removeListener(accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    if (!active) return;
    final g = ++generation;
    setState(() {
      loading = true;
      moreBusy = false;
      error = null;
      entries = [];
      summary = null;
      cursor = null;
    });
    try {
      final values = await Future.wait<Object>([
        repository.entries(localDay(date), offsetZone(date)),
        repository.summary(localDay(date), offsetZone(date)),
      ]);
      if (!active || g != generation) return;
      final records = values[0] as NutritionPageData;
      setState(() {
        entries = records.items;
        cursor = records.cursor;
        summary = values[1] as Json;
      });
    } catch (e) {
      if (active && g == generation) setState(() => error = nutritionError(e));
    } finally {
      if (active && g == generation) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> searchOwn() async {
    if (!active) return;
    final g = ++ownGeneration;
    final query = search.text.trim();
    ownQuery = query;
    setState(() {
      ownLoading = true;
      ownMoreBusy = false;
      ownError = null;
      foods = [];
      ownCursor = null;
    });
    try {
      final page = await repository.foods(q: query);
      if (active && g == ownGeneration) {
        setState(() {
          foods = page.items;
          ownCursor = page.cursor;
        });
      }
    } catch (e) {
      if (active && g == ownGeneration) {
        setState(() => ownError = nutritionError(e));
      }
    } finally {
      if (active && g == ownGeneration) setState(() => ownLoading = false);
    }
  }

  Future<void> more(bool own) async {
    if (!active || (own ? ownLoading || ownMoreBusy : loading || moreBusy)) {
      return;
    }
    final token = own ? ownCursor : cursor;
    if (token == null) return;
    final g = own ? ownGeneration : generation;
    bool current() => active && g == (own ? ownGeneration : generation);
    setState(() {
      if (own) {
        ownMoreBusy = true;
      } else {
        moreBusy = true;
      }
      if (own) {
        ownError = null;
      } else {
        error = null;
      }
    });
    try {
      final result = own
          ? await repository.foods(q: ownQuery, cursor: token)
          : await repository.entries(
              localDay(date),
              offsetZone(date),
              cursor: token,
            );
      if (current()) {
        setState(() {
          if (own) {
            foods = [...foods, ...result.items];
            ownCursor = result.cursor;
          } else {
            entries = [...entries, ...result.items];
            cursor = result.cursor;
          }
        });
      }
    } catch (e) {
      if (current()) {
        setState(() {
          if (own) {
            ownError = nutritionError(e);
          } else {
            error = nutritionError(e);
          }
        });
      }
    } finally {
      if (current()) {
        setState(() {
          if (own) {
            ownMoreBusy = false;
          } else {
            moreBusy = false;
          }
        });
      }
    }
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
    await load();
    if (active && result != null) await detail(result);
  }

  Future<void> detail(Json entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(entry: entry, repository: repository),
      ),
    );
    if (active) await load();
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

  Future<void> createFood() async {
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => OwnFoodFormPage(repository: repository),
      ),
    );
    if (!active) return;
    await searchOwn();
    if (mounted && active && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alimento particular salvo. Nenhum consumo foi registrado.',
          ),
        ),
      );
    }
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (chosen != null && active) {
      date = chosen;
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: FigmaRouteFrame(
      body: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Consumo'),
              Tab(text: 'Meus alimentos'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [consumptionList(), ownFoodList()]),
          ),
        ],
      ),
    ),
  );

  Widget heading(String subtitle) =>
      FigmaPageHeading(title: 'Minha alimentação', subtitle: subtitle);

  Widget consumptionList() => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      key: const PageStorageKey('nutrition-consumption'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading('DIÁRIO · REGISTROS CONFIRMADOS POR VOCÊ'),
        OutlinedButton.icon(
          onPressed: chooseDate,
          icon: const Icon(Icons.calendar_today),
          label: Text('${localDay(date)} · ${offsetZone(date)}'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: chooseReference,
          icon: const Icon(Icons.search),
          label: const Text('Pesquisar alimento e registrar consumo'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Registros confirmados por você. Nenhuma dieta, meta ou compensação por exercício é criada.',
        ),
        const SizedBox(height: 16),
        if (loading) const AppLoading(label: 'Consultando alimentação'),
        if (error != null) _error(),
        if (!loading && error == null && entries.isEmpty)
          const FlowStatus(
            title: 'Nenhum consumo registrado neste dia.',
            message:
                'Escolha outra data ou pesquise um alimento para registrar o que consumiu. Ausência de registro não significa consumo zero.',
          ),
        for (final entry in entries)
          FlowRecord(
            title: displayLabel(
              object(object(entry['calculation'])['food'])['nameOriginal'],
            ),
            subtitle:
                '''${entry['quantity']} ${entry['unit']} · ${object(entry['calculation'])['quantityEvidence'] == 'measured' ? 'medida' : 'estimativa'}
${localTimestamp(entry['occurredAt'] as String)}''',
            onTap: () => detail(entry),
          ),
        if (cursor != null)
          OutlinedButton(
            onPressed: moreBusy ? null : () => more(false),
            child: Text(moreBusy ? 'Carregando…' : 'Carregar mais registros'),
          ),
        if (summary != null)
          FigmaSection(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                summary!['complete'] == true
                    ? 'Subtotais do dia · ${summary!['entries']} registros'
                    : 'Limite de subtotal excedido',
              ),
              children: [
                Text(summary!['notice'] as String),
                if (summary!['complete'] == true)
                  Text(
                    '${summary!['measuredEntries']} quantidades medidas · ${summary!['estimatedEntries']} estimadas',
                  ),
                const SizedBox(height: 12),
                for (final n in objects(summary!['nutrients']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          displayLabel(n['nameOriginal']),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${n['value'] ?? 'Desconhecido'} ${n['unit'] ?? ''}',
                        ),
                        Text(
                          '${n['includedEntries']} incluídos · ${n['unknownEntries']} sem valor calculável',
                        ),
                        Text('Coluna: ${n['sourceColumnKey']}'),
                        const Divider(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget ownFoodList() => RefreshIndicator(
    onRefresh: searchOwn,
    child: ListView(
      key: const PageStorageKey('nutrition-own-foods'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading('ALIMENTOS PARTICULARES · NÃO PUBLICADOS'),
        FilledButton.icon(
          onPressed: createFood,
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar alimento próprio'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Somente seus alimentos particulares. Criar um alimento não registra consumo nem o publica no catálogo.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            labelText: 'Buscar nos meus alimentos',
          ),
          onChanged: (_) {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 400), searchOwn);
          },
          onSubmitted: (_) {
            debounce?.cancel();
            searchOwn();
          },
        ),
        const SizedBox(height: 12),
        if (ownLoading)
          const AppLoading(label: 'Consultando alimentos particulares'),
        if (ownError != null)
          FlowStatus(
            title: 'Consulta indisponível',
            message: ownError!,
            actionLabel: 'Tentar novamente',
            onAction: searchOwn,
          ),
        if (!ownLoading && ownError == null && foods.isEmpty)
          const FlowStatus(
            title: 'Nenhum alimento próprio corresponde à busca.',
            message:
                'Pesquise outro nome ou cadastre um alimento particular. Informe somente os dados conhecidos; não preencha nutrientes por suposição.',
          ),
        for (final food in foods)
          FlowRecord(
            title: asFood(food).displayName,
            subtitle: '''${asFood(food).basisLabel}
Particular · tocar para informar uma porção''',
            onTap: () => record(asFood(food)),
          ),
        if (ownCursor != null)
          OutlinedButton(
            onPressed: ownMoreBusy ? null : () => more(true),
            child: Text(
              ownMoreBusy ? 'Carregando…' : 'Carregar mais alimentos próprios',
            ),
          ),
      ],
    ),
  );

  Widget _error() => FlowStatus(
    title: 'Consulta indisponível',
    message: error!,
    actionLabel: 'Tentar novamente',
    onAction: load,
  );
}
