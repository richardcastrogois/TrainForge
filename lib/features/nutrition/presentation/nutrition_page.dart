import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'nutrition_controller.dart';
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
  late final NutritionController controller;
  final search = TextEditingController();
  bool get active => mounted && controller.active;

  @override
  void initState() {
    super.initState();
    repository =
        widget.repository ??
        AppDependencyScope.read(context).createNutritionRepository(
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
        );
    controller = NutritionController(
      repository: repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
      initialDate: widget.initialDate,
    );
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    controller.load();
    controller.searchOwn();
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      accountChanged();
      if (active) {
        controller.load();
        controller.searchOwn();
      }
    }
  }

  @override
  void dispose() {
    search.dispose();
    widget.sessionChanges.removeListener(accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
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
    await controller.load();
    if (active && result != null) await detail(result);
  }

  Future<void> detail(Json entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(entry: entry, repository: repository),
      ),
    );
    if (active) await controller.load();
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
    await controller.searchOwn();
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
      initialDate: controller.date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (chosen != null && active) {
      await controller.selectDate(chosen);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => DefaultTabController(
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
    ),
  );

  Widget heading(String subtitle) =>
      FigmaPageHeading(title: 'Minha alimentação', subtitle: subtitle);

  Widget consumptionList() => RefreshIndicator(
    onRefresh: controller.load,
    child: ListView(
      key: const PageStorageKey('nutrition-consumption'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading('DIÁRIO · REGISTROS CONFIRMADOS POR VOCÊ'),
        OutlinedButton.icon(
          onPressed: chooseDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            '${localDay(controller.date)} · ${offsetZone(controller.date)}',
          ),
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
        if (controller.loading)
          const AppLoading(label: 'Consultando alimentação'),
        if (controller.error != null) _error(),
        if (!controller.loading &&
            controller.error == null &&
            controller.entries.isEmpty)
          const FlowStatus(
            title: 'Nenhum consumo registrado neste dia.',
            message:
                'Escolha outra data ou pesquise um alimento para registrar o que consumiu. Ausência de registro não significa consumo zero.',
          ),
        for (final entry in controller.entries)
          FlowRecord(
            title: displayLabel(
              object(object(entry['calculation'])['food'])['nameOriginal'],
            ),
            subtitle:
                '''${entry['quantity']} ${entry['unit']} · ${object(entry['calculation'])['quantityEvidence'] == 'measured' ? 'medida' : 'estimativa'}
${localTimestamp(entry['occurredAt'] as String)}''',
            onTap: () => detail(entry),
          ),
        if (controller.cursor != null)
          OutlinedButton(
            onPressed: controller.moreBusy
                ? null
                : () => controller.more(false),
            child: Text(
              controller.moreBusy ? 'Carregando…' : 'Carregar mais registros',
            ),
          ),
        if (controller.summary != null)
          FigmaSection(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                controller.summary!['complete'] == true
                    ? 'Subtotais do dia · ${controller.summary!['entries']} registros'
                    : 'Limite de subtotal excedido',
              ),
              children: [
                Text(controller.summary!['notice'] as String),
                if (controller.summary!['complete'] == true)
                  Text(
                    '${controller.summary!['measuredEntries']} quantidades medidas · ${controller.summary!['estimatedEntries']} estimadas',
                  ),
                const SizedBox(height: 12),
                for (final n in objects(controller.summary!['nutrients']))
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
    onRefresh: controller.searchOwn,
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
          onChanged: controller.queryChanged,
          onSubmitted: controller.submitQuery,
        ),
        const SizedBox(height: 12),
        if (controller.ownLoading)
          const AppLoading(label: 'Consultando alimentos particulares'),
        if (controller.ownError != null)
          FlowStatus(
            title: 'Consulta indisponível',
            message: controller.ownError!,
            actionLabel: 'Tentar novamente',
            onAction: controller.searchOwn,
          ),
        if (!controller.ownLoading &&
            controller.ownError == null &&
            controller.foods.isEmpty)
          const FlowStatus(
            title: 'Nenhum alimento próprio corresponde à busca.',
            message:
                'Pesquise outro nome ou cadastre um alimento particular. Informe somente os dados conhecidos; não preencha nutrientes por suposição.',
          ),
        for (final food in controller.foods)
          FlowRecord(
            title: asFood(food).displayName,
            subtitle: '''${asFood(food).basisLabel}
Particular · tocar para informar uma porção''',
            onTap: () => record(asFood(food)),
          ),
        if (controller.ownCursor != null)
          OutlinedButton(
            onPressed: controller.ownMoreBusy
                ? null
                : () => controller.more(true),
            child: Text(
              controller.ownMoreBusy
                  ? 'Carregando…'
                  : 'Carregar mais alimentos próprios',
            ),
          ),
      ],
    ),
  );

  Widget _error() => FlowStatus(
    title: 'Consulta indisponível',
    message: controller.error!,
    actionLabel: 'Tentar novamente',
    onAction: controller.load,
  );
}
