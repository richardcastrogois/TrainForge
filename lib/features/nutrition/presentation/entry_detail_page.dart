import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:flutter/material.dart';
import '../domain/nutrition.dart';
import 'nutrition_messages.dart';
import 'nutrition_feedback.dart';
import 'nutrition_forms.dart';
import 'entry_read_controller.dart';
import '../../food_reference/presentation/food_labels.dart';

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

class _EntryDetailPageState extends State<EntryDetailPage>
    with WidgetsBindingObserver {
  late EntryReadController reader;
  Json get entry => reader.entry;
  bool busy = false;
  String? error;
  final deleteKey = mutationKey();
  @override
  void initState() {
    super.initState();
    reader = EntryReadController(
      repository: widget.repository,
      entry: widget.entry,
    )..addListener(readChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void readChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = foodContentLocale(context);
    if (reader.locale != language) reader.load(language);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy && reader.locale != null) {
      reader.load(reader.locale!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    reader.removeListener(readChanged);
    reader.dispose();
    super.dispose();
  }

  Future<void> edit() async {
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(
          food: entryPresentationFood(entry, foodContentLocale(context)),
          repository: widget.repository,
          entry: entry,
        ),
      ),
    );
    if (mounted && result != null) await reader.edited(result);
  }

  Future<void> remove() async {
    if (busy) return;
    final yes = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.style(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.deleteIntakeQuestion),
        content: Text(context.l10n.deleteIntakeNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteIntake),
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
    final reviewed = reader.display?.name;
    final usesReviewed =
        reviewed != null && reviewed.locale == foodContentLocale(context);
    return PopScope(
      canPop: !busy,
      child: FigmaRouteFrame(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            FigmaPageHeading(
              title: context.l10n.intakeConfirmed,
              subtitle: context.l10n.privateDiaryUpper,
            ),
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reader.name(foodContentLocale(context)),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (reader.loading) Text(context.l10n.loading),
                  if (reader.error != null)
                    FlowStatus(
                      title: context.l10n.requestUnconfirmed,
                      message: localizedNutritionFeedback(
                        context,
                        reader.error!,
                      ),
                      actionLabel: context.l10n.retry,
                      onAction: () => reader.load(foodContentLocale(context)),
                    ),
                  if (usesReviewed) ...[
                    Text(context.l10n.reviewedFoodName),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(context.l10n.nameReviewSource),
                      children: [
                        SelectableText(reviewed.attribution),
                        Text(reviewed.license),
                        SelectableText(reviewed.licenseUrl),
                        SelectableText(
                          "${context.l10n.version}: ${reviewed.versionId}",
                        ),
                      ],
                    ),
                  ] else if (reader.localized &&
                      !reader.loading &&
                      reader.error == null &&
                      food["sourceId"] != "personal")
                    Text(context.l10n.foodNameFallback),
                  Text(
                    "${context.l10n.originalFoodName}: ${displayLabel(food['nameOriginal'])} · ${food['nameLocale']}",
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${context.displayDecimal(entry['quantity'] as String)} ${entry['unit']}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    c['quantityEvidence'] == 'measured'
                        ? context.l10n.quantityMeasured
                        : context.l10n.quantityEstimated,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${context.l10n.deviceTime}: ${context.displayTimestamp(entry['occurredAt'] as String)}',
                  ),
                  Text('${context.l10n.recordedZone}: ${entry['timezone']}'),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.notedPreparation}: ${(c['preparation'] as String).isEmpty ? context.l10n.notInformed : c['preparation']}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlowSectionTitle(context.l10n.compositionOrigin),
                  Text(source['attribution'] as String),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(context.l10n.preservedCalculation),
                    children: [
                      SelectableText(
                        '''${context.l10n.origin}: ${c['origin']} · ${food['sourceId']}
${context.l10n.version}: ${entry['foodVersion']}
${context.l10n.method}: ${c['algorithm']}
${source['licenseLabel']}
${source['sourceUrl']}
${source['licenseUrl']}''',
                      ),
                      Text(context.l10n.fractionNotice),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              FlowStatus(
                title: context.l10n.requestUnconfirmed,
                message: localizedNutritionFeedback(context, error!),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed:
                  busy ||
                      reader.loading ||
                      (reader.localized && reader.error != null)
                  ? null
                  : edit,
              child: Text(context.l10n.correctIntakeAction),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed:
                  busy ||
                      reader.loading ||
                      (reader.localized && reader.error != null)
                  ? null
                  : remove,
              child: Text(
                busy ? context.l10n.confirming : context.l10n.deleteThisIntake,
              ),
            ),
            FlowSectionTitle(context.l10n.thisPortionComposition),
            Text(context.l10n.portionSourceNotice),
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
                        '${n['value'] is String ? context.displayDecimal(n['value'] as String) : context.l10n.unknownValue} ${n['unit'] ?? ''}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (n['reason'] != null && n['reason'] != '')
                        Text('${context.l10n.reason}: ${n['reason']}'),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(context.l10n.basisOriginalCalculation),
                        children: [
                          Text(
                            '''${context.l10n.originalState}: ${n['sourceState']} · ${context.l10n.cell}: ${n['rawText'] ?? ''} · ${context.l10n.limit}: ${n['sourceUpperBound'] ?? context.l10n.notInformed}
${context.l10n.basis}: ${object(n['basis'])['quantity'] ?? '?'} ${object(n['basis'])['unit'] ?? ''}
${context.l10n.factor}: ${n['factor'] ?? context.l10n.notCalculable}
${context.l10n.exactFraction}: ${n['exactFraction'] ?? context.l10n.unknownValue}''',
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
                  context.l10n.previousCorrections(
                    (c['changes'] as List).length,
                  ),
                ),
                children: [
                  for (final change in objects(c['changes']))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${context.l10n.revision(change['revision'] as int)} · ${context.displayDecimal(change['quantity'] as String)} ${change['unit']}',
                          ),
                          Text(
                            '${context.displayTimestamp(change['occurredAt'] as String)} · ${context.l10n.recordedZone}: ${change['timezone']}',
                          ),
                          Text(
                            change['quantityEvidence'] == 'measured'
                                ? context.l10n.quantityMeasured
                                : context.l10n.quantityEstimated,
                          ),
                          Text(
                            '${context.l10n.preparation}: ${change['preparation']}',
                          ),
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
