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
  const NutritionPage({
    super.key,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    this.repository,
  });
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver {
  late final NutritionRepository repository;
  DateTime date = DateTime.now();
  bool loading = true, moreBusy = false, ownMoreBusy = false;
  String? error, cursor, ownCursor;
  List<Json> entries = [], foods = [];
  Json? summary;
  int generation = 0;
  final search = TextEditingController();
  Timer? debounce;
  bool get active => mounted && widget.currentAccountId() == widget.accountId;
  @override
  void initState() {
    super.initState();
    repository =
        widget.repository ??
        GoNutritionRepository(
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
        );
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  void accountChanged() {
    if (widget.currentAccountId() != widget.accountId) {
      generation++;
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
      if (active) load();
    }
  }

  @override
  void dispose() {
    generation++;
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
      ownMoreBusy = false;
      error = null;
      entries = [];
      summary = null;
      foods = [];
      cursor = null;
      ownCursor = null;
    });
    try {
      final values = await Future.wait<Object>([
        repository.entries(localDay(date), offsetZone(date)),
        repository.summary(localDay(date), offsetZone(date)),
        repository.foods(q: search.text.trim()),
      ]);
      if (!active || g != generation) return;
      final records = values[0] as NutritionPageData,
          own = values[2] as NutritionPageData;
      setState(() {
        entries = records.items;
        cursor = records.cursor;
        summary = values[1] as Json;
        foods = own.items;
        ownCursor = own.cursor;
      });
    } catch (e) {
      if (active && g == generation) setState(() => error = nutritionError(e));
    } finally {
      if (active && g == generation) setState(() => loading = false);
    }
  }

  Future<void> more(bool own) async {
    if (!active || loading || (own ? ownMoreBusy : moreBusy)) return;
    final token = own ? ownCursor : cursor;
    if (token == null) return;
    final g = generation;
    setState(() {
      if (own) {
        ownMoreBusy = true;
      } else {
        moreBusy = true;
      }
      error = null;
    });
    try {
      final result = own
          ? await repository.foods(q: search.text.trim(), cursor: token)
          : await repository.entries(
              localDay(date),
              offsetZone(date),
              cursor: token,
            );
      if (active && g == generation) {
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
      if (active && g == generation) setState(() => error = nutritionError(e));
    } finally {
      if (active && g == generation) {
        setState(() {
          ownMoreBusy = false;
          moreBusy = false;
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
    await load();
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
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Minha alimentação'),
        actions: [
          IconButton(
            onPressed: loading ? null : load,
            tooltip: 'Atualizar alimentação',
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Consumo'),
            Tab(text: 'Meus alimentos'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: chooseDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${localDay(date)} · ${offsetZone(date)}'),
                ),
                FilledButton.icon(
                  onPressed: chooseReference,
                  icon: const Icon(Icons.search),
                  label: const Text('Pesquisar alimento e registrar consumo'),
                ),
                const Text(
                  'Registros confirmados por você. Nenhuma dieta, meta ou compensação por exercício é criada.',
                ),
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Consultando alimentação',
                    ),
                  ),
                if (error != null) _error(),
                if (!loading && error == null && entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhum consumo registrado neste dia.'),
                  ),
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      title: Text(
                        object(
                              object(entry['calculation'])['food'],
                            )['nameOriginal']
                            as String,
                      ),
                      subtitle: Text(
                        '${entry['quantity']} ${entry['unit']} · ${object(entry['calculation'])['quantityEvidence'] == 'measured' ? 'medida' : 'estimativa'}\n${localTimestamp(entry['occurredAt'] as String)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => detail(entry),
                    ),
                  ),
                if (cursor != null)
                  OutlinedButton(
                    onPressed: moreBusy ? null : () => more(false),
                    child: Text(
                      moreBusy ? 'Carregando…' : 'Carregar mais registros',
                    ),
                  ),
                if (summary != null)
                  ExpansionTile(
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
                      for (final n in objects(summary!['nutrients']))
                        ListTile(
                          title: Text(displayLabel(n['nameOriginal'])),
                          subtitle: Text(
                            '${n['value'] ?? 'Desconhecido'} ${n['unit'] ?? ''}\n${n['includedEntries']} incluídos · ${n['unknownEntries']} sem valor calculável\nColuna: ${n['sourceColumnKey']}',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: createFood,
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar alimento próprio'),
                ),
                const Text(
                  'Somente seus alimentos particulares. Criar um alimento não registra consumo nem o publica no catálogo.',
                ),
                TextField(
                  controller: search,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Buscar nos meus alimentos',
                  ),
                  onChanged: (_) {
                    debounce?.cancel();
                    debounce = Timer(const Duration(milliseconds: 400), load);
                  },
                  onSubmitted: (_) {
                    debounce?.cancel();
                    load();
                  },
                ),
                if (loading)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Consultando alimentos particulares',
                    ),
                  ),
                if (error != null) _error(),
                if (!loading && error == null && foods.isEmpty)
                  const Text('Nenhum alimento próprio corresponde à busca.'),
                for (final food in foods)
                  Card(
                    child: ListTile(
                      title: Text(food['nameOriginal'] as String),
                      subtitle: Text(asFood(food).basisLabel),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => record(asFood(food)),
                    ),
                  ),
                if (ownCursor != null)
                  OutlinedButton(
                    onPressed: ownMoreBusy ? null : () => more(true),
                    child: Text(
                      ownMoreBusy
                          ? 'Carregando…'
                          : 'Carregar mais alimentos próprios',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  Widget _error() => Column(
    children: [
      Semantics(liveRegion: true, child: Text(error!)),
      OutlinedButton(onPressed: load, child: const Text('Tentar novamente')),
    ],
  );
}
