import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import '../domain/nutrition.dart';
import '../data/nutrition_repository.dart';

bool _rejected(Object e) =>
    e is DioException &&
    {400, 401, 404, 409, 413, 415, 429}.contains(e.response?.statusCode);

class EntryFormPage extends StatefulWidget {
  final FoodReference food;
  final NutritionRepository repository;
  final Json? entry;
  const EntryFormPage({
    super.key,
    required this.food,
    required this.repository,
    this.entry,
  });
  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final form = GlobalKey<FormState>();
  final quantity = TextEditingController(),
      preparation = TextEditingController();
  late DateTime when;
  late String unit;
  String? evidence, error;
  bool busy = false;
  Json? pending;
  String keyValue = mutationKey();
  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    when = e == null
        ? DateTime.now()
        : DateTime.parse(e['occurredAt'] as String).toLocal();
    unit = e?['unit'] as String? ?? widget.food.basisUnit ?? 'g';
    quantity.text = e?['quantity'] as String? ?? '';
    preparation.text = e == null
        ? ''
        : object(e['calculation'])['preparation'] as String;
    evidence = e == null
        ? null
        : object(e['calculation'])['quantityEvidence'] as String;
  }

  @override
  void dispose() {
    quantity.dispose();
    preparation.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: when,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
    );
    if (t != null && mounted) {
      setState(() => when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }
  }

  Future<void> save() async {
    if (busy) return;
    if (pending == null) {
      if (!form.currentState!.validate() ||
          !validDecimal(decimal(quantity.text), positive: true) ||
          evidence == null) {
        setState(
          () =>
              error = 'Informe quantidade e escolha se foi medida ou estimada.',
        );
        return;
      }
      pending = {
        'foodId': widget.food.id,
        'foodVersion': widget.food.versionId,
        'quantity': decimal(quantity.text),
        'unit': unit,
        'preparation': preparation.text.trim(),
        'occurredAt': when.toUtc().toIso8601String(),
        'timezone': offsetZone(when),
        'quantityEvidence': evidence,
        'revision': widget.entry == null
            ? 0
            : object(widget.entry!['calculation'])['revision'],
      };
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.saveEntry(
        pending!,
        keyValue,
        id: widget.entry?['id'] as String?,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = nutritionError(e);
        if (_rejected(e)) {
          pending = null;
          keyValue = mutationKey();
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = busy || pending != null;
    return FigmaRouteFrame(
      body: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FigmaPageHeading(
                title: widget.entry == null
                    ? 'A porção é tua.'
                    : 'Corrigir consumo',
                subtitle: widget.food.displayName,
              ),
              FigmaSection(
                color: context.tf.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Quantidade',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      key: Key('entry-quantity'),
                      controller: quantity,
                      enabled: !locked,
                      maxLength: 14,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Quantidade consumida',
                        hintText: 'Informe a quantidade',
                      ),
                      validator: (v) =>
                          validDecimal(decimal(v ?? ''), positive: true)
                          ? null
                          : 'Informe uma quantidade maior que zero, até 6 casas decimais.',
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: unit,
                      isExpanded: true,
                      itemHeight: null,
                      decoration: InputDecoration(
                        labelText: 'Unidade da quantidade',
                      ),
                      items: [
                        DropdownMenuItem(value: 'g', child: Text('Gramas (g)')),
                        DropdownMenuItem(
                          value: 'ml',
                          child: Text('Mililitros (ml)'),
                        ),
                      ],
                      onChanged: locked
                          ? null
                          : (v) => setState(() => unit = v!),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: evidence,
                isExpanded: true,
                itemHeight: null,
                decoration: InputDecoration(
                  labelText: 'Como obteve a quantidade?',
                ),
                items: [
                  DropdownMenuItem(
                    value: 'measured',
                    child: Text('Medi com balança ou recipiente'),
                  ),
                  DropdownMenuItem(
                    value: 'estimated',
                    child: Text('Fiz uma estimativa'),
                  ),
                ],
                validator: (v) =>
                    v == null ? 'Escolha medida ou estimativa.' : null,
                onChanged: locked ? null : (v) => setState(() => evidence = v),
              ),
              SizedBox(height: 12),
              FigmaSection(
                color: context.tf.nutrition,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composição da porção',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'O cálculo é confirmado pela API ao salvar. Valores desconhecidos não viram zero; métodos e unidades diferentes não são somados.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: context.tf.cardMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              FigmaSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Origem e preparação',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.food.basisLabel,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: context.tf.muted,
                      ),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text('Fonte e versão'),
                      children: [
                        SelectableText(
                          'Origem: ${widget.food.sourceId}\nVersão: ${widget.food.versionId}\n${widget.food.sourceVersion}\n${widget.food.source.attribution}\n${widget.food.source.license}',
                        ),
                      ],
                    ),
                    TextFormField(
                      key: Key('entry-preparation'),
                      controller: preparation,
                      enabled: !locked,
                      maxLength: 180,
                      decoration: InputDecoration(
                        labelText: 'Preparo observado (opcional)',
                      ),
                    ),
                    Text(
                      'O preparo é uma anotação sua e não altera a composição da fonte. Não convertemos gramas em mililitros sem densidade comprovada.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: context.tf.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: locked ? null : pickDate,
                child: Text(
                  '${localDay(when)} · ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')} · ${offsetZone(when)}',
                ),
              ),
              Text(
                'Data e hora do aparelho, confirmadas por você.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: context.tf.muted,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Confirme somente o que você consumiu. Não há dieta prescrita nem compensação por exercícios. Quantidades estimadas serão identificadas como estimadas.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: context.tf.muted,
                ),
              ),
              SizedBox(height: 12),
              if (error != null)
                Semantics(liveRegion: true, child: Text(error!)),
              if (pending != null && !busy)
                Text(
                  'A resposta ainda não foi confirmada. Tente novamente com os mesmos dados ou volte para conferir o histórico.',
                ),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Confirmando…'
                      : pending != null
                      ? 'Tentar confirmar novamente'
                      : widget.entry == null
                      ? 'Confirmar consumo'
                      : 'Confirmar correção',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientDraft {
  final name = TextEditingController(), value = TextEditingController();
  String unit = 'g';
  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class OwnFoodFormPage extends StatefulWidget {
  final NutritionRepository repository;
  const OwnFoodFormPage({super.key, required this.repository});
  @override
  State<OwnFoodFormPage> createState() => _OwnFoodFormPageState();
}

class _OwnFoodFormPageState extends State<OwnFoodFormPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      preparation = TextEditingController(),
      basis = TextEditingController();
  final nutrients = <_NutrientDraft>[];
  String unit = 'g', keyValue = mutationKey();
  String? error;
  Json? pending;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    preparation.dispose();
    basis.dispose();
    for (final n in nutrients) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (pending == null) {
      if (!form.currentState!.validate()) return;
      final b = decimal(basis.text);
      pending = {
        'name': name.text.trim(),
        'preparation': preparation.text.trim(),
        'basis': {
          'quantity': b.isEmpty ? null : b,
          'unit': b.isEmpty ? null : unit,
        },
        'nutrients': nutrients
            .map(
              (n) => {
                'name': n.name.text.trim(),
                'unit': n.unit,
                'value': n.value.text.trim().isEmpty
                    ? null
                    : decimal(n.value.text),
              },
            )
            .toList(),
      };
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.createFood(pending!, keyValue);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = nutritionError(e);
          if (_rejected(e)) {
            pending = null;
            keyValue = mutationKey();
          }
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = busy || pending != null;
    return Scaffold(
      appBar: AppBar(title: Text('Cadastrar alimento próprio')),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Cadastro particular, separado do catálogo público. Criar este alimento não registra consumo e não significa revisão editorial ou clínica.',
              ),
              TextFormField(
                key: Key('own-food-name'),
                controller: name,
                enabled: !locked,
                maxLength: 180,
                decoration: InputDecoration(labelText: 'Nome do alimento'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
              ),
              TextFormField(
                controller: preparation,
                enabled: !locked,
                maxLength: 180,
                decoration: InputDecoration(
                  labelText: 'Preparo declarado (opcional)',
                ),
              ),
              Text(
                'Se souber, informe a base a que os nutrientes se referem. Deixe em branco o que não conhece. Ausência não significa zero.',
              ),
              TextFormField(
                controller: basis,
                enabled: !locked,
                maxLength: 14,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantidade da base (opcional)',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ||
                        validDecimal(decimal(v!), positive: true)
                    ? null
                    : 'Base deve ser maior que zero.',
              ),
              DropdownButtonFormField<String>(
                initialValue: unit,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'Unidade da base'),
                items: [
                  DropdownMenuItem(value: 'g', child: Text('Gramas (g)')),
                  DropdownMenuItem(value: 'ml', child: Text('Mililitros (ml)')),
                ],
                onChanged: locked ? null : (v) => setState(() => unit = v!),
              ),
              for (var i = 0; i < nutrients.length; i++)
                Card(
                  key: ObjectKey(nutrients[i]),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nutrients[i].name,
                          enabled: !locked,
                          maxLength: 100,
                          decoration: InputDecoration(
                            labelText: 'Nome do nutriente',
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Informe o nome do nutriente.'
                              : null,
                        ),
                        TextFormField(
                          controller: nutrients[i].value,
                          enabled: !locked,
                          maxLength: 14,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Valor na base (opcional)',
                          ),
                          validator: (v) =>
                              (v ?? '').trim().isEmpty ||
                                  validDecimal(decimal(v!))
                              ? null
                              : 'Informe um decimal ou deixe desconhecido.',
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: nutrients[i].unit,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Unidade do nutriente',
                          ),
                          items: ['g', 'mg', 'µg', 'kcal', 'kJ']
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: locked
                              ? null
                              : (v) => setState(() => nutrients[i].unit = v!),
                        ),
                        TextButton(
                          onPressed: locked
                              ? null
                              : () {
                                  setState(() {
                                    nutrients.removeAt(i).dispose();
                                  });
                                },
                          child: Text('Remover este campo'),
                        ),
                      ],
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: locked || nutrients.length >= 32
                    ? null
                    : () => setState(() => nutrients.add(_NutrientDraft())),
                child: Text('Adicionar nutriente conhecido ou desconhecido'),
              ),
              if (error != null)
                Semantics(liveRegion: true, child: Text(error!)),
              if (pending != null && !busy)
                Text(
                  'Resposta não confirmada. Repita com os mesmos dados para evitar duplicação.',
                ),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Confirmando…'
                      : pending != null
                      ? 'Tentar confirmar novamente'
                      : 'Salvar somente o alimento',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
