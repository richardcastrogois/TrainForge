import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';
import 'nutrition_forms.dart';

class EntryDetailPage extends StatefulWidget {
  final Json entry;
  final NutritionRepository repository;
  const EntryDetailPage({
    super.key,
    required this.entry,
    required this.repository,
  });
  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  late Json entry;
  bool busy = false;
  String? error;
  final deleteKey = mutationKey();
  @override
  void initState() {
    super.initState();
    entry = widget.entry;
  }

  Future<void> edit() async {
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(
          food: asFood(object(object(entry['calculation'])['food'])),
          repository: widget.repository,
          entry: entry,
        ),
      ),
    );
    if (mounted && result != null) setState(() => entry = result);
  }

  Future<void> remove() async {
    if (busy) return;
    final yes = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        title: const Text('Excluir este consumo?'),
        content: const Text(
          'Ele sairá dos subtotais e do histórico ativo. O registro e suas correções continuam particulares na exportação até a exclusão da conta. O alimento cadastrado permanece.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir consumo'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.deleteEntry(
        entry['id'] as String,
        object(entry['calculation'])['revision'] as int,
        deleteKey,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = nutritionError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = object(entry['calculation']),
        food = object(c['food']),
        source = object(food['source']);
    return PopScope(
      canPop: !busy,
      child: FigmaRouteFrame(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const FigmaPageHeading(
              title: 'Consumo confirmado',
              subtitle: 'DIÁRIO · REGISTRO PARTICULAR',
            ),
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    displayLabel(food['nameOriginal']),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${entry['quantity']} ${entry['unit']}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    c['quantityEvidence'] == 'measured'
                        ? 'Quantidade medida'
                        : 'Quantidade estimada',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Horário neste aparelho: ${localTimestamp(entry['occurredAt'] as String)}',
                  ),
                  Text('Fuso informado no registro: ${entry['timezone']}'),
                  const SizedBox(height: 8),
                  Text(
                    'Preparo anotado: ${(c['preparation'] as String).isEmpty ? 'não informado' : c['preparation']}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FlowSectionTitle('Origem da composição'),
                  Text(source['attribution'] as String),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Origem e cálculo preservados'),
                    children: [
                      SelectableText(
                        '''Origem: ${c['origin']} · ${food['sourceId']}
Versão: ${entry['foodVersion']}
Método: ${c['algorithm']}
${source['licenseLabel']}
${source['sourceUrl']}
${source['licenseUrl']}''',
                      ),
                      const Text(
                        'Fração exata preservada. Exibição arredondada a 6 casas. Traço, limite, unidade incompatível e base ausente não se tornam zero. Preparo não altera a composição.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              FlowStatus(title: 'Solicitação não confirmada', message: error!),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: busy ? null : edit,
              child: const Text('Corrigir quantidade, preparo ou horário'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : remove,
              child: Text(busy ? 'Confirmando…' : 'Excluir este consumo'),
            ),
            const FlowSectionTitle('Composição desta porção'),
            const Text(
              'Os valores abaixo pertencem à versão e ao método da fonte. Desconhecido não significa zero.',
            ),
            const SizedBox(height: 12),
            for (final n in objects(c['nutrients']))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FigmaSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        displayLabel(n['nameOriginal']),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${n['value'] ?? 'Desconhecido'} ${n['unit'] ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (n['reason'] != null && n['reason'] != '')
                        Text('Motivo: ${n['reason']}'),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Base, valor original e cálculo'),
                        children: [
                          Text(
                            '''Estado original: ${n['sourceState']} · célula: ${n['rawText'] ?? ''} · limite: ${n['sourceUpperBound'] ?? 'não informado'}
Base: ${object(n['basis'])['quantity'] ?? '?'} ${object(n['basis'])['unit'] ?? ''}
Fator: ${n['factor'] ?? 'não calculável'}
Fração exata: ${n['exactFraction'] ?? 'desconhecida'}''',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            FigmaSection(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Correções anteriores (${(c['changes'] as List).length})',
                ),
                children: [
                  for (final change in objects(c['changes']))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Revisão ${change['revision']} · ${change['quantity']} ${change['unit']}',
                          ),
                          Text(
                            '${localTimestamp(change['occurredAt'] as String)} · fuso informado: ${change['timezone']}',
                          ),
                          Text(
                            change['quantityEvidence'] == 'measured'
                                ? 'Quantidade medida'
                                : 'Quantidade estimada',
                          ),
                          Text('Preparo: ${change['preparation']}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
