import 'package:trainforge/features/food_reference/presentation/food_labels.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/shared/widgets/draft_guard.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';
import 'nutrition_feedback.dart';

bool _rejected(Object e) =>
    e is DioException &&
    {400, 401, 404, 409, 413, 415, 429}.contains(e.response?.statusCode);

bool validateNutritionForm(GlobalKey<FormState> form, BuildContext context) {
  final invalid = form.currentState!.validateGranularly();
  if (invalid.isEmpty) return true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final field = invalid.first;
    if (context.mounted && field.mounted) {
      Scrollable.ensureVisible(
        field.context,
        alignment: .15,
        duration: AppMotion.reduced(context)
            ? Duration.zero
            : AppMotion.duration,
      );
    }
  });
  return false;
}

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
  final guard = GlobalKey<DraftGuardState>();
  final quantity = TextEditingController(),
      preparation = TextEditingController();
  late DateTime when;
  late String unit;
  late String initialDraft;
  String get draft => [
    quantity.text,
    preparation.text,
    unit,
    evidence,
    when.toIso8601String(),
  ].join("\u0000");
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
    initialDraft = draft;
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
      if (!validateNutritionForm(form, context) ||
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      if (mounted) guard.currentState!.complete(result);
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
    return DraftGuard(
      key: guard,
      dirty: draft != initialDraft,
      busy: busy,
      uncertain: pending != null,
      child: FigmaRouteFrame(
        body: Form(
          key: form,
          onChanged: () => setState(() {}),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FigmaPageHeading(
                  title: widget.entry == null
                      ? context.l10n.portionYours
                      : context.l10n.correctIntake,
                  subtitle: widget.food.localizedName(context),
                ),
                FigmaSection(
                  color: context.tf.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.quantity,
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
                          labelText: context.l10n.consumedQuantity,
                          hintText: context.l10n.enterQuantity,
                        ),
                        validator: (v) =>
                            validDecimal(decimal(v ?? ''), positive: true)
                            ? null
                            : context.l10n.positiveQuantity,
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: InputDecoration(
                          labelText: context.l10n.quantityUnit,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'g',
                            child: Text(context.l10n.grams),
                          ),
                          DropdownMenuItem(
                            value: 'ml',
                            child: Text(context.l10n.milliliters),
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
                FormField<String>(
                  initialValue: evidence,
                  enabled: !locked,
                  validator: (value) =>
                      value == null ? context.l10n.chooseEvidence : null,
                  builder: (field) => InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.quantityHow,
                      errorText: field.errorText,
                      enabled: !locked,
                    ),
                    child: RadioGroup<String>(
                      groupValue: field.value,
                      onChanged: (value) {
                        if (locked) return;
                        field.didChange(value);
                        setState(() => evidence = value);
                      },
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'measured',
                            enabled: !locked,
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.l10n.measuredChoice),
                          ),
                          RadioListTile<String>(
                            value: 'estimated',
                            enabled: !locked,
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.l10n.estimatedChoice),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                FigmaSection(
                  color: context.tf.nutrition,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.portionComposition,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.l10n.calculationOnSave,
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
                        context.l10n.originPreparation,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (widget.food.reviewedName?.locale ==
                          foodContentLocale(context))
                        Text(
                          '${context.l10n.originalFoodName}: ${widget.food.displayName}',
                        ),
                      Text(
                        widget.food.localizedBasis(context),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: context.tf.muted,
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(context.l10n.sourceVersion),
                        children: [
                          SelectableText(
                            '${context.l10n.origin}: ${widget.food.sourceId}\n${context.l10n.version}: ${widget.food.versionId}\n${widget.food.sourceVersion}\n${widget.food.source.attribution}\n${widget.food.source.license}',
                          ),
                        ],
                      ),
                      TextFormField(
                        key: Key('entry-preparation'),
                        controller: preparation,
                        enabled: !locked,
                        maxLength: 180,
                        decoration: InputDecoration(
                          labelText: context.l10n.observedPreparation,
                        ),
                      ),
                      Text(
                        context.l10n.preparationNote,
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
                    '${context.displayDate(when)} · ${context.displayTime(when)} · ${offsetZone(when)}',
                  ),
                ),
                Text(
                  context.l10n.deviceDateConfirmed,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.tf.muted,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  context.l10n.intakeConfirmationNotice,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.tf.muted,
                  ),
                ),
                SizedBox(height: 12),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(localizedNutritionFeedback(context, error!)),
                  ),
                if (pending != null && !busy)
                  Text(context.l10n.intakeUncertain),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(
                    busy
                        ? context.l10n.confirming
                        : pending != null
                        ? context.l10n.retryConfirmation
                        : widget.entry == null
                        ? context.l10n.confirmIntake
                        : context.l10n.confirmCorrection,
                  ),
                ),
              ],
            ),
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
  final guard = GlobalKey<DraftGuardState>();
  final name = TextEditingController(),
      preparation = TextEditingController(),
      basis = TextEditingController();
  final nutrients = <_NutrientDraft>[];
  String unit = 'g', keyValue = mutationKey();
  String? error;
  Json? pending;
  bool busy = false;
  bool get dirty =>
      name.text.isNotEmpty ||
      preparation.text.isNotEmpty ||
      basis.text.isNotEmpty ||
      nutrients.isNotEmpty ||
      unit != "g";
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
      if (!validateNutritionForm(form, context)) return;
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
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.repository.createFood(pending!, keyValue);
      if (mounted) guard.currentState!.complete(result);
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
    return DraftGuard(
      key: guard,
      dirty: dirty,
      busy: busy,
      uncertain: pending != null,
      child: FigmaRouteFrame(
        body: SafeArea(
          child: Form(
            key: form,
            onChanged: () => setState(() {}),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FigmaPageHeading(
                    title: context.l10n.createOwnFood,
                    subtitle: context.l10n.ownDataUpper,
                  ),
                  FlowSectionTitle(context.l10n.foodIdentity),
                  Text(context.l10n.ownFoodNotice),
                  TextFormField(
                    key: Key('own-food-name'),
                    controller: name,
                    enabled: !locked,
                    maxLength: 180,
                    decoration: InputDecoration(
                      labelText: context.l10n.foodName,
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? context.l10n.enterName
                        : null,
                  ),
                  TextFormField(
                    controller: preparation,
                    enabled: !locked,
                    maxLength: 180,
                    decoration: InputDecoration(
                      labelText: context.l10n.declaredPreparation,
                    ),
                  ),
                  FlowSectionTitle(context.l10n.compositionBasis),
                  Text(context.l10n.basisNotice),
                  TextFormField(
                    controller: basis,
                    enabled: !locked,
                    maxLength: 14,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.optionalBasisQuantity,
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ||
                            validDecimal(decimal(v!), positive: true)
                        ? null
                        : context.l10n.positiveBasis,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    isExpanded: true,
                    itemHeight: null,
                    decoration: InputDecoration(
                      labelText: context.l10n.basisUnit,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'g',
                        child: Text(context.l10n.grams),
                      ),
                      DropdownMenuItem(
                        value: 'ml',
                        child: Text(context.l10n.milliliters),
                      ),
                    ],
                    onChanged: locked ? null : (v) => setState(() => unit = v!),
                  ),
                  FlowSectionTitle(context.l10n.declaredNutrients),
                  Text(context.l10n.noAssumedNutrients),
                  const SizedBox(height: 12),
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
                                labelText: context.l10n.nutrientName,
                              ),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? context.l10n.enterNutrientName
                                  : null,
                            ),
                            TextFormField(
                              controller: nutrients[i].value,
                              enabled: !locked,
                              maxLength: 14,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: context.l10n.optionalBasisValue,
                              ),
                              validator: (v) =>
                                  (v ?? '').trim().isEmpty ||
                                      validDecimal(decimal(v!))
                                  ? null
                                  : context.l10n.decimalOrUnknown,
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: nutrients[i].unit,
                              isExpanded: true,
                              itemHeight: null,
                              decoration: InputDecoration(
                                labelText: context.l10n.nutrientUnit,
                              ),
                              items: ['g', 'mg', 'µg', 'kcal', 'kJ']
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: locked
                                  ? null
                                  : (v) =>
                                        setState(() => nutrients[i].unit = v!),
                            ),
                            TextButton(
                              onPressed: locked
                                  ? null
                                  : () {
                                      setState(() {
                                        nutrients.removeAt(i).dispose();
                                      });
                                    },
                              child: Text(context.l10n.removeField),
                            ),
                          ],
                        ),
                      ),
                    ),
                  OutlinedButton(
                    onPressed: locked || nutrients.length >= 32
                        ? null
                        : () => setState(() => nutrients.add(_NutrientDraft())),
                    child: Text(context.l10n.addNutrient),
                  ),
                  if (error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(localizedNutritionFeedback(context, error!)),
                    ),
                  if (pending != null && !busy)
                    Text(context.l10n.ownFoodUncertain),
                  FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(
                      busy
                          ? context.l10n.confirming
                          : pending != null
                          ? context.l10n.retryConfirmation
                          : context.l10n.saveFoodOnly,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
