import 'package:trainforge/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import '../domain/nutrition.dart';
import '../data/nutrition_repository.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Consumo confirmado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              food['nameOriginal'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${entry['quantity']} ${entry['unit']} · ${c['quantityEvidence'] == 'measured' ? 'quantidade medida' : 'quantidade estimada'}',
            ),
            Text(
              'Horário neste aparelho: ${localTimestamp(entry['occurredAt'] as String)} · fuso informado no registro: ${entry['timezone']}',
            ),
            Text(
              'Preparo anotado: ${(c['preparation'] as String).isEmpty ? 'não informado' : c['preparation']}',
            ),
            Text(source['attribution'] as String),
            ExpansionTile(
              title: const Text('Origem e cálculo preservados'),
              children: [
                SelectableText(
                  'Origem: ${c['origin']} · ${food['sourceId']}\nVersão: ${entry['foodVersion']}\nMétodo: ${c['algorithm']}\n${source['licenseLabel']}\n${source['sourceUrl']}\n${source['licenseUrl']}',
                ),
                const Text(
                  'Fração exata preservada. Exibição arredondada a 6 casas. Traço, limite, unidade incompatível e base ausente não se tornam zero. Preparo não altera a composição.',
                ),
              ],
            ),
            if (error != null) Semantics(liveRegion: true, child: Text(error!)),
            OutlinedButton(
              onPressed: busy ? null : edit,
              child: const Text('Corrigir quantidade, preparo ou horário'),
            ),
            OutlinedButton(
              onPressed: busy ? null : remove,
              child: Text(busy ? 'Confirmando…' : 'Excluir este consumo'),
            ),
            for (final n in objects(c['nutrients']))
              Card(
                child: ListTile(
                  title: Text(displayLabel(n['nameOriginal'])),
                  subtitle: Text(
                    '${n['value'] ?? 'Desconhecido'} ${n['unit'] ?? ''}\nEstado original: ${n['sourceState']} · célula: ${n['rawText'] ?? ''} · limite: ${n['sourceUpperBound'] ?? 'não informado'}\nBase: ${object(n['basis'])['quantity'] ?? '?'} ${object(n['basis'])['unit'] ?? ''}\nFator: ${n['factor'] ?? 'não calculável'}\nFração exata: ${n['exactFraction'] ?? 'desconhecida'}${n['reason'] == '' ? '' : '\nMotivo: ${n['reason']}'}',
                  ),
                ),
              ),
            ExpansionTile(
              title: Text(
                'Correções anteriores (${(c['changes'] as List).length})',
              ),
              children: [
                for (final change in objects(c['changes']))
                  ListTile(
                    title: Text(
                      'Revisão ${change['revision']} · ${change['quantity']} ${change['unit']}',
                    ),
                    subtitle: Text(
                      '${change['occurredAt']} · ${change['timezone']}\n${change['quantityEvidence']}\nPreparo: ${change['preparation']}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
