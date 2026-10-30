import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/draft_guard.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import '../../food_reference/presentation/food_labels.dart';
import '../domain/meals.dart';
import '../domain/nutrition.dart';
import 'entry_detail_page.dart';
import 'nutrition_feedback.dart';
import 'nutrition_messages.dart';
import 'meal_metadata_page.dart';

class MealDetailPage extends StatefulWidget {
  final bool evidenceMode;
  final String id, accountId;
  final MealRepository repository;
  final NutritionRepository nutrition;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  const MealDetailPage({
    super.key,
    required this.id,
    required this.accountId,
    required this.repository,
    required this.nutrition,
    required this.currentAccountId,
    required this.sessionChanges,
    this.evidenceMode = false,
  });
  @override
  State<MealDetailPage> createState() => _MealDetailPageState();
}

class _MealDetailPageState extends State<MealDetailPage> {
  ConfirmedMeal? value;
  bool loading = true, busy = false, invalidated = false, conflict = false;
  int generation = 0;
  int? pendingRevision;
  String keyValue = mutationKey();
  String? error, locale;
  bool get active =>
      mounted && !invalidated && widget.currentAccountId() == widget.accountId;
  @override
  void initState() {
    super.initState();
    widget.sessionChanges.addListener(accountChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = foodContentLocale(context);
    if (next != locale) {
      locale = next;
      load();
    }
  }

  void accountChanged() {
    if (widget.currentAccountId() == widget.accountId || !mounted) return;
    invalidated = true;
    generation++;
    setState(() {
      value = null;
      pendingRevision = null;
      error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    });
  }

  @override
  void dispose() {
    generation++;
    widget.sessionChanges.removeListener(accountChanged);
    value = null;
    super.dispose();
  }

  Future<void> load({bool reconcile = false}) async {
    if (!active || busy) return;
    final g = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.repository.meal(widget.id, locale: locale!);
      if (!active || g != generation) return;
      setState(() {
        value = result;
        if (reconcile) {
          pendingRevision = null;
          conflict = false;
          keyValue = mutationKey();
        }
      });
    } catch (e) {
      if (active && g == generation) setState(() => error = nutritionError(e));
    } finally {
      if (active && g == generation) setState(() => loading = false);
    }
  }

  Future<void> askDelete() async {
    final revision = value?.meal.revision;
    if (revision == null ||
        busy ||
        pendingRevision != null ||
        value?.deletedAt != null) {
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.l10n.deleteMeal),
        content: Text(context.l10n.deleteMealConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.deleteMeal),
          ),
        ],
      ),
    );
    if (!active || yes != true) return;
    setState(() => pendingRevision = revision);
    await remove();
  }

  Future<void> remove() async {
    if (!active || busy || conflict || pendingRevision == null) return;
    generation++;
    setState(() {
      busy = true;
      loading = false;
      error = null;
    });
    try {
      final result = await widget.repository.deleteMeal(
        widget.id,
        pendingRevision!,
        keyValue,
      );
      if (!active) return;
      setState(() {
        value = result;
        pendingRevision = null;
      });
    } catch (e) {
      if (!active) return;
      setState(() {
        error = nutritionError(e);
        if (e is DioException && e.response?.statusCode == 409) conflict = true;
      });
    } finally {
      if (active) setState(() => busy = false);
    }
  }

  Future<void> entry(Json item) async {
    if (!active || busy || pendingRevision != null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailPage(
          entry: item,
          repository: widget.nutrition,
          evidenceMode: widget.evidenceMode,
        ),
      ),
    );
    if (active) await load();
  }

  Future<void> edit() async {
    final saved = value;
    if (!active ||
        busy ||
        loading ||
        pendingRevision != null ||
        saved == null ||
        saved.deletedAt != null) {
      return;
    }
    await Navigator.push<ConfirmedMeal>(
      context,
      MaterialPageRoute(
        builder: (_) => MealMetadataPage(
          repository: widget.repository,
          meal: saved.meal,
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
          sessionChanges: widget.sessionChanges,
        ),
      ),
    );
    if (active) await load();
  }

  @override
  Widget build(BuildContext context) => DraftGuard(
    dirty: false,
    busy: busy,
    uncertain: pendingRevision != null,
    uncertainMessage: conflict ? context.l10n.mealConflictNotice : null,
    child: FigmaRouteFrame(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          FigmaPageHeading(
            title: value?.meal.title.isNotEmpty == true
                ? value!.meal.title
                : context.l10n.mealUnnamed,
            subtitle: context.l10n.mealMetadataOnly,
          ),
          if (loading) AppLoading(label: context.l10n.loadingNutrition),
          if (error != null)
            FlowStatus(
              title: context.l10n.queryUnavailable,
              message: conflict
                  ? context.l10n.mealConflictNotice
                  : localizedNutritionFeedback(context, error!),
              actionLabel: pendingRevision == null || conflict
                  ? context.l10n.retry
                  : null,
              onAction: pendingRevision == null || conflict
                  ? () => load(reconcile: conflict)
                  : null,
            ),
          if (value != null) ...[
            Text(
              '${context.displayTimestamp(value!.meal.occurredAt)} · ${value!.meal.timezone}',
            ),
            if (value!.deletedAt != null)
              Text(context.l10n.mealDeleted)
            else ...[
              if (pendingRevision == null)
                OutlinedButton(
                  onPressed: busy || loading ? null : edit,
                  child: Text(context.l10n.correctMeal),
                ),
              if (value!.meal.totalActiveItems == 0)
                Text(context.l10n.mealEmptyGroup),
              for (final item in value!.entries.where(
                (e) => e['deletedAt'] == null,
              ))
                FlowRecord(
                  title: entryDisplayName(item, foodContentLocale(context)),
                  subtitle:
                      '${context.displayDecimal(item['quantity'] as String)} ${item['unit']} · ${context.displayTimestamp(item['occurredAt'] as String)}',
                  onTap: busy || pendingRevision != null
                      ? null
                      : () => entry(item),
                ),
              if (pendingRevision == null)
                OutlinedButton(
                  onPressed: busy || loading ? null : askDelete,
                  child: Text(context.l10n.deleteMeal),
                )
              else if (!conflict)
                FilledButton(
                  onPressed: busy ? null : remove,
                  child: Text(
                    busy
                        ? context.l10n.confirming
                        : context.l10n.retryConfirmation,
                  ),
                ),
            ],
          ],
        ],
      ),
    ),
  );
}
