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
import '../domain/meals.dart';
import 'nutrition_messages.dart';
import 'nutrition_feedback.dart';
import '../data/offline_nutrition_repository.dart';
import 'food_contribution_page.dart';
import 'food_offline_labels.dart';
import '../domain/portion_quantity.dart';
import '../../food_reference/data/local_food_repository.dart';
import 'own_food_portions_editor.dart';

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
  final bool prepareForMeal;
  final DateTime? initialWhen;
  const EntryFormPage({
    super.key,
    required this.food,
    required this.repository,
    this.entry,
    this.prepareForMeal = false,
    this.initialWhen,
  }) : assert(!prepareForMeal || entry == null);
  @override
  State<EntryFormPage> createState() => _EntryFormPageState();
}

class _EntryFormPageState extends State<EntryFormPage> {
  final form = GlobalKey<FormState>();
  final guard = GlobalKey<DraftGuardState>();
  final quantity = TextEditingController(),
      preparation = TextEditingController(),
      portionCount = TextEditingController(text: '1');
  FoodPortion? selectedPortion;
  Json? get portionInput {
    final portion = selectedPortion;
    return portion == null
        ? null
        : {
            'id': portion.id,
            'label': portion.label,
            'quantity': portion.quantity,
            'unit': portion.unit,
            'condition': portion.condition,
            'sourceId': portion.sourceId,
            'count': decimal(portionCount.text),
          };
  }

  bool validQuantity(String value) => validFoodIntakeQuantity(widget.food, {
    'foodId': widget.food.id,
    'foodVersion': widget.food.versionId,
    'quantity': value,
    'unit': unit,
    if (selectedPortion != null) 'portion': portionInput,
  });

  late DateTime when;
  late String unit;
  late String initialDraft;
  String get draft => [
    quantity.text,
    preparation.text,
    unit,
    evidence,
    when.toIso8601String(),
    selectedPortion?.id,
    portionCount.text,
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
        ? widget.initialWhen ?? DateTime.now()
        : DateTime.parse(e['occurredAt'] as String).toLocal();
    unit = e?['unit'] as String? ?? widget.food.basisUnit ?? 'g';
    quantity.text = e?['quantity'] as String? ?? '';
    preparation.text = e == null
        ? ''
        : object(e['calculation'])['preparation'] as String;
    evidence = e == null
        ? null
        : object(e['calculation'])['quantityEvidence'] as String;
    if (e != null && object(e['calculation'])['portion'] is Map) {
      final portion = object(object(e['calculation'])['portion']);
      final matches = widget.food.portions.where((p) => p.id == portion['id']);
      if (matches.length == 1) {
        selectedPortion = matches.single;
        portionCount.text = portion['count'] as String;
      }
    }
    initialDraft = draft;
  }

  @override
  void dispose() {
    quantity.dispose();
    preparation.dispose();
    portionCount.dispose();
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
          !validQuantity(decimal(quantity.text)) ||
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
        if (selectedPortion != null) 'portion': portionInput,
        'revision': widget.entry == null
            ? 0
            : object(widget.entry!['calculation'])['revision'],
      };
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.prepareForMeal) {
      guard.currentState!.complete(copyMealJson(pending!));
      return;
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
                  title: widget.prepareForMeal
                      ? context.l10n.prepareMealItem
                      : widget.entry == null
                      ? context.l10n.portionYours
                      : context.l10n.correctIntake,
                  subtitle: widget.food.localizedName(context),
                ),
                FigmaSection(
                  color: context.tf.accent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.food.portions.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          key: const Key('entry-portion'),
                          initialValue: selectedPortion?.id ?? '',
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: foodOfflineLabel(context, 'portion'),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(
                                foodOfflineLabel(context, 'manualQuantity'),
                              ),
                            ),
                            ...widget.food.portions.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.label} · ${p.quantity} ${p.unit}',
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ],
                          onChanged: locked
                              ? null
                              : (id) {
                                  if (id == null || id.isEmpty) {
                                    setState(() => selectedPortion = null);
                                    return;
                                  }
                                  final p = widget.food.portions.firstWhere(
                                    (p) => p.id == id,
                                  );
                                  setState(() {
                                    selectedPortion = p;
                                    portionCount.text = '1';
                                    quantity.text = p.quantity;
                                    unit = p.unit;
                                  });
                                },
                        ),
                        if (selectedPortion != null)
                          TextFormField(
                            key: const Key('entry-portion-count'),
                            controller: portionCount,
                            enabled: !locked,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: foodOfflineLabel(
                                context,
                                'portionCount',
                              ),
                            ),
                            validator: (v) =>
                                validDecimal(decimal(v ?? ''), positive: true)
                                ? null
                                : context.l10n.nutritionCheckFields,
                            onChanged: (value) {
                              final count = decimal(value);
                              if (validDecimal(count, positive: true)) {
                                setState(
                                  () => quantity.text =
                                      derivedPortionQuantity(
                                        selectedPortion!,
                                        count,
                                      ) ??
                                      '',
                                );
                              }
                            },
                          ),
                        Text(foodOfflineLabel(context, 'portionNotice')),
                        const SizedBox(height: 12),
                      ],
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
                        readOnly: selectedPortion != null,
                        maxLength: selectedPortion == null ? 14 : 80,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: context.l10n.consumedQuantity,
                          hintText: context.l10n.enterQuantity,
                        ),
                        validator: (v) => validQuantity(decimal(v ?? ''))
                            ? null
                            : context.l10n.positiveQuantity,
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: InputDecoration(
                          counterText: '',
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
                        onChanged: locked || selectedPortion != null
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
                      counterText: '',
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
                        context.l10n.observedPreparation,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.food.localizedBasis(context),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: context.tf.muted,
                        ),
                      ),
                      TextFormField(
                        key: Key('entry-preparation'),
                        controller: preparation,
                        enabled: !locked,
                        maxLength: 180,
                        decoration: InputDecoration(
                          counterText: '',
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
                  widget.prepareForMeal
                      ? context.l10n.mealDraftNotice
                      : context.l10n.intakeConfirmationNotice,
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
                        : widget.prepareForMeal
                        ? context.l10n.addMealItem
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
  final String? initialBarcode;
  const OwnFoodFormPage({
    super.key,
    required this.repository,
    this.initialBarcode,
  });
  @override
  State<OwnFoodFormPage> createState() => _OwnFoodFormPageState();
}

class _OwnFoodFormPageState extends State<OwnFoodFormPage> {
  final form = GlobalKey<FormState>();
  final guard = GlobalKey<DraftGuardState>();
  final name = TextEditingController(),
      preparation = TextEditingController(),
      basis = TextEditingController(),
      brand = TextEditingController(),
      barcode = TextEditingController();
  final nutrients = <_NutrientDraft>[];
  final portions = <FoodPortionDraft>[];
  String unit = 'g', keyValue = mutationKey();
  String? error;
  Json? pending;
  bool busy = false;
  bool get dirty =>
      name.text.isNotEmpty ||
      preparation.text.isNotEmpty ||
      basis.text.isNotEmpty ||
      nutrients.isNotEmpty ||
      portions.isNotEmpty ||
      brand.text.isNotEmpty ||
      barcode.text.isNotEmpty ||
      unit != "g";
  @override
  void initState() {
    super.initState();
    barcode.text = widget.initialBarcode ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    preparation.dispose();
    basis.dispose();
    brand.dispose();
    barcode.dispose();
    for (final portion in portions) {
      portion.dispose();
    }
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
        if (brand.text.trim().isNotEmpty) 'brand': brand.text.trim(),
        if (barcode.text.trim().isNotEmpty) 'barcodes': [barcode.text.trim()],
        if (portions.isNotEmpty)
          'portions': portions.map((p) => p.toJson()).toList(),
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
      final offline = widget.repository;
      if (mounted && offline is OfflineNutritionRepository) {
        await inviteFoodContribution(context, offline, copyMealJson(pending!));
      }
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
                    controller: brand,
                    enabled: !locked,
                    maxLength: 180,
                    decoration: InputDecoration(
                      labelText: foodOfflineLabel(context, 'brand'),
                    ),
                  ),
                  TextFormField(
                    controller: barcode,
                    enabled: !locked,
                    maxLength: 14,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: foodOfflineLabel(context, 'barcode'),
                    ),
                    validator: (value) =>
                        value == null ||
                            value.trim().isEmpty ||
                            LocalFoodRepository.validBarcode(value.trim())
                        ? null
                        : context.l10n.nutritionCheckFields,
                  ),
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
                  OwnFoodPortionsEditor(
                    portions: portions,
                    locked: locked,
                    changed: () => setState(() {}),
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
