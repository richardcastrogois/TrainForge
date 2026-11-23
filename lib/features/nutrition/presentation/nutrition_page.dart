import 'nutrition_totals_card.dart';
import 'meal_diary_page.dart';
import '../domain/meals.dart';
import 'package:trainforge/features/food_reference/presentation/food_labels.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'nutrition_controller.dart';
import 'nutrition_feedback.dart';
import '../domain/nutrition.dart';
import 'nutrition_forms.dart';
import 'entry_detail_page.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../food_reference/data/food_photo_classifier.dart';
import '../../food_reference/data/food_voice_matcher.dart';
import 'voice_meal_page.dart';
import '../data/offline_nutrition_repository.dart';
import '../../food_reference/presentation/barcode_scanner_page.dart';
import '../../food_reference/data/local_food_repository.dart';
import 'food_offline_labels.dart';
import 'food_contribution_page.dart';
import 'offline_sync_panel.dart';

class NutritionPage extends StatefulWidget {
  final bool evidenceMode;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final NutritionRepository? repository;
  final DateTime? initialDate;

  /// Photo recognition; injectable for tests. Defaults to the bundled model.
  final FoodPhotoClassifier? photoClassifier;

  /// Returns the path of a photo the app may read and delete, or null when cancelled.
  final Future<String?> Function(ImageSource source)? pickPhoto;

  /// Returns the spoken sentence, or null; injectable for tests.
  final Future<String?> Function(BuildContext context, List<String> vocabulary)?
  listenVoice;
  const NutritionPage({
    super.key,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    this.repository,
    this.initialDate,
    this.evidenceMode = false,
    this.photoClassifier,
    this.pickPhoto,
    this.listenVoice,
  });
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with WidgetsBindingObserver {
  late final NutritionRepository repository;
  late final NutritionController controller;
  final search = TextEditingController();
  late final FoodPhotoClassifier photoClassifier;
  bool photoAvailable = false, photoBusy = false, voiceBusy = false;
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
    controller.searchOwn();
    photoClassifier = widget.photoClassifier ?? FoodPhotoClassifier();
    final offline = repository;
    if (offline is OfflineNutritionRepository) {
      unawaited(
        photoClassifier.available().then((ok) {
          if (mounted && ok) setState(() => photoAvailable = true);
        }),
      );
      offline.addListener(offlineChanged);
      unawaited(
        offline.synchronize().then((_) async {
          if (active) {
            await controller.load();
            await controller.searchOwn();
          }
        }),
      );
    }
  }

  String? _contentLocale;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final value = foodContentLocale(context);
    if (value == _contentLocale) return;
    final first = _contentLocale == null;
    _contentLocale = value;
    if (value != controller.locale) {
      controller.selectLocale(value);
    } else if (first) {
      controller.load();
    }
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      });
    }
  }

  void offlineChanged() {
    final source = repository;
    if (source is OfflineNutritionRepository && source.store.locked) {
      controller.invalidateAccount();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      accountChanged();
      if (active) {
        final offline = repository;
        if (offline is OfflineNutritionRepository) {
          unawaited(offline.synchronize());
        }
        controller.load();
        controller.searchOwn();
      }
    }
  }

  @override
  void dispose() {
    final source = repository;
    if (source is OfflineNutritionRepository) {
      source.removeListener(offlineChanged);
    }
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
        builder: (_) => EntryDetailPage(
          entry: entry,
          repository: repository,
          evidenceMode: widget.evidenceMode,
        ),
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

  Future<void> scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null || !mounted || !controller.active) return;
    final offline = repository;
    if (offline is! OfflineNutritionRepository) return;
    try {
      final found = await offline.catalog.barcode(code);
      final normalized = LocalFoodRepository.normalizedBarcode(code);
      for (final food in await offline.store.resources('food')) {
        if ((food['barcodes'] as List? ?? []).any(
          (v) =>
              LocalFoodRepository.normalizedBarcode(v as String) == normalized,
        )) {
          found.add(asFood(food));
        }
      }
      if (!mounted || !controller.active) return;
      if (found.isEmpty) {
        final create = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(foodOfflineLabel(context, 'notFound')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(foodOfflineLabel(context, 'manual')),
              ),
            ],
          ),
        );
        if (create == true && mounted && controller.active) {
          await Navigator.push<Json>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OwnFoodFormPage(repository: repository, initialBarcode: code),
            ),
          );
          if (active) await controller.searchOwn();
        }
        return;
      }
      final selected = found.length == 1
          ? found.single
          : await showDialog<FoodReference>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text(foodOfflineLabel(context, 'scan')),
                children: found
                    .map(
                      (f) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, f),
                        child: Text(
                          '${f.localizedName(context)}${f.brand == null ? '' : ' · ${f.brand}'}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
      if (selected != null && active) await record(selected);
    } catch (_) {
      if (mounted && controller.active) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.queryUnavailable)));
      }
    }
  }

  Future<String?> _pick(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 90,
    );
    return image?.path;
  }

  /// Photo → up to 5 catalog foods; the person picks one and confirms the quantity.
  Future<void> photo() async {
    final offline = repository;
    if (!active || photoBusy || offline is! OfflineNutritionRepository) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(foodOfflineLabel(context, 'photoCamera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(foodOfflineLabel(context, 'photoGallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !active) return;
    String? path;
    try {
      path = await (widget.pickPhoto ?? _pick)(source);
    } catch (_) {
      path = null;
      if (mounted) _photoMessage('photoUnavailable');
      return;
    }
    if (path == null || !active) return;
    setState(() => photoBusy = true);
    final foods = <FoodReference>[];
    var failed = false;
    try {
      for (final suggestion in await photoClassifier.suggest(path)) {
        final food = await offline.catalog.photoFood(
          suggestion.food.foodId,
          suggestion.food.versionId,
        );
        if (food != null) foods.add(food);
      }
    } catch (_) {
      failed = true;
    } finally {
      // The photo is never stored: it only feeds this analysis.
      try {
        await File(path).delete();
      } catch (_) {}
      if (mounted) setState(() => photoBusy = false);
    }
    if (!mounted || !active) return;
    if (failed) return _photoMessage('photoUnavailable');
    const searchOther = Object();
    final selected = await showDialog<Object>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          foodOfflineLabel(
            context,
            foods.isEmpty ? 'photoNone' : 'photoSuggestions',
          ),
        ),
        children: [
          if (foods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(foodOfflineLabel(context, 'photoHint')),
            ),
          for (final food in foods)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, food),
              child: Text(food.localizedName(context)),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, searchOther),
            child: Text(foodOfflineLabel(context, 'photoSearch')),
          ),
        ],
      ),
    );
    if (!active) return;
    if (selected is FoodReference) {
      await record(selected);
    } else if (identical(selected, searchOther)) {
      await chooseReference();
    }
  }

  Future<bool> _recordSaved(FoodReference food) async {
    if (!active) return false;
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => EntryFormPage(food: food, repository: repository),
      ),
    );
    if (active) await controller.load();
    return result != null;
  }

  /// Voice → known foods (same 370 as the photo model) or a catalog search per item.
  Future<void> voice() async {
    final offline = repository;
    if (!active || voiceBusy || offline is! OfflineNutritionRepository) return;
    final locale = foodContentLocale(context);
    final List<FoodPhotoClass> known;
    try {
      known = await photoClassifier.classes();
    } catch (_) {
      return _photoMessage('voiceUnavailable');
    }
    if (!mounted) return;
    final listen =
        widget.listenVoice ??
        (context, vocabulary) => listenForMeal(context, vocabulary: vocabulary);
    final sentence = await listen(context, [for (final c in known) c.name]);
    if (sentence == null || !mounted || !active) return;
    setState(() => voiceBusy = true);
    final items = <VoiceMealItem>[];
    try {
      for (final heard in FoodVoiceMatcher(known).match(sentence)) {
        final options = <FoodReference>[];
        for (final c in heard.candidates) {
          final food = await offline.catalog.photoFood(c.foodId, c.versionId);
          if (food != null && !options.any((o) => o.id == food.id)) {
            options.add(food);
          }
        }
        if (options.isEmpty) {
          try {
            final page = await offline.catalog.localizedList(
              locale: locale,
              q: heard.heard,
            );
            options.addAll(page.items.take(3));
          } catch (_) {}
        }
        items.add(VoiceMealItem(heard.heard, options));
      }
    } finally {
      if (mounted) setState(() => voiceBusy = false);
    }
    if (!mounted || !active) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceMealPage(
          sentence: sentence,
          items: items,
          record: _recordSaved,
          searchByName: chooseReference,
        ),
      ),
    );
  }

  void _photoMessage(String key) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(foodOfflineLabel(context, key))));

  Future<void> meals() async {
    final source = repository;
    if (!active || source is! MealRepository) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MealDiaryPage(
          evidenceMode: widget.evidenceMode,
          repository: source as MealRepository,
          nutrition: repository,
          accountId: widget.accountId,
          currentAccountId: widget.currentAccountId,
          sessionChanges: widget.sessionChanges,
          initialDate: controller.date,
        ),
      ),
    );
    if (active) await controller.load();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.ownFoodSaved)));
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
            TabBar(
              tabs: [
                Tab(text: context.l10n.intake),
                Tab(text: context.l10n.myFoods),
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
      FigmaPageHeading(title: context.l10n.myNutrition, subtitle: subtitle);

  Widget consumptionList() => RefreshIndicator(
    onRefresh: controller.load,
    child: ListView(
      key: const PageStorageKey('nutrition-consumption'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        heading(
          repository is OfflineNutritionRepository
              ? foodOfflineLabel(context, 'offlineDiary')
              : context.l10n.confirmedDiaryUpper,
        ),
        if (repository is OfflineNutritionRepository)
          OfflineSyncPanel(
            repository: repository as OfflineNutritionRepository,
            reload: controller.load,
          ),
        if (repository is MealRepository)
          OutlinedButton.icon(
            onPressed: meals,
            icon: const Icon(Icons.restaurant),
            label: Text(context.l10n.viewMeals),
          ),
        OutlinedButton.icon(
          onPressed: chooseDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(
            '${context.displayDate(controller.date)} · ${offsetZone(controller.date)}',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: chooseReference,
          icon: const Icon(Icons.search),
          label: Text(context.l10n.searchRecordFood),
        ),
        if (repository is OfflineNutritionRepository)
          OutlinedButton.icon(
            onPressed: scan,
            icon: const Icon(Icons.barcode_reader),
            label: Text(foodOfflineLabel(context, 'scan')),
          ),
        if (repository is OfflineNutritionRepository)
          OutlinedButton.icon(
            onPressed: voiceBusy ? null : voice,
            icon: const Icon(Icons.mic),
            label: Text(foodOfflineLabel(context, 'voice')),
          ),
        if (repository is OfflineNutritionRepository && photoAvailable)
          OutlinedButton.icon(
            onPressed: photoBusy ? null : photo,
            icon: const Icon(Icons.photo_camera),
            label: Text(
              foodOfflineLabel(
                context,
                photoBusy ? 'photoBusy' : 'photoRecognize',
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(context.l10n.diaryNoPrescription),
        const SizedBox(height: 16),
        if (controller.loading)
          AppLoading(label: context.l10n.loadingNutrition),
        if (controller.error != null) _error(),
        if (!controller.loading &&
            controller.error == null &&
            controller.entries.isEmpty)
          FlowStatus(
            title: context.l10n.noIntakeDay,
            message: context.l10n.noIntakeHint,
          ),
        for (final entry in controller.entries)
          FlowRecord(
            title: entryDisplayName(entry, foodContentLocale(context)),
            subtitle:
                '''${context.displayDecimal(entry['quantity'] as String)} ${entry['unit']} · ${object(entry['calculation'])['quantityEvidence'] == 'measured' ? context.l10n.measuredShort : context.l10n.estimatedShort}
${context.displayTimestamp(entry['occurredAt'] as String)}${entry['syncState'] == null ? '' : ' · ${foodOfflineLabel(context, entry['syncState'] == 'confirmed' ? 'confirmed' : 'pending')}'}''',
            onTap: () => detail(entry),
          ),
        if (controller.cursor != null)
          OutlinedButton(
            onPressed: controller.moreBusy
                ? null
                : () => controller.more(false),
            child: Text(
              controller.moreBusy
                  ? context.l10n.loading
                  : context.l10n.moreRecords,
            ),
          ),
        if (controller.summary != null)
          NutritionTotalsCard(totals: controller.summary!),
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
        heading(context.l10n.privateFoodsUpper),
        if (repository is OfflineNutritionRepository)
          TextButton.icon(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => FoodContributionsPage(
                  repository: repository as OfflineNutritionRepository,
                ),
              ),
            ),
            icon: const Icon(Icons.volunteer_activism),
            label: Text(foodOfflineLabel(context, 'contributions')),
          ),
        FilledButton.icon(
          onPressed: createFood,
          icon: const Icon(Icons.add),
          label: Text(context.l10n.createOwnFood),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.privateFoodsHint),
        const SizedBox(height: 16),
        TextField(
          controller: search,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(labelText: context.l10n.searchMyFoods),
          onChanged: controller.queryChanged,
          onSubmitted: controller.submitQuery,
        ),
        const SizedBox(height: 12),
        if (controller.ownLoading)
          AppLoading(label: context.l10n.loadingPrivateFoods),
        if (controller.ownError != null)
          FlowStatus(
            title: context.l10n.queryUnavailable,
            message: localizedNutritionFeedback(context, controller.ownError!),
            actionLabel: context.l10n.retry,
            onAction: controller.searchOwn,
          ),
        if (!controller.ownLoading &&
            controller.ownError == null &&
            controller.foods.isEmpty)
          FlowStatus(
            title: context.l10n.noPrivateResults,
            message: context.l10n.noPrivateHint,
          ),
        for (final food in controller.foods)
          FlowRecord(
            title: asFood(food).displayName,
            subtitle:
                '${asFood(food).localizedBasis(context)}\n${context.l10n.privatePortionHint}',
            onTap: () => record(asFood(food)),
          ),
        if (controller.ownCursor != null)
          OutlinedButton(
            onPressed: controller.ownMoreBusy
                ? null
                : () => controller.more(true),
            child: Text(
              controller.ownMoreBusy
                  ? context.l10n.loading
                  : context.l10n.morePrivateFoods,
            ),
          ),
      ],
    ),
  );

  Widget _error() => FlowStatus(
    title: context.l10n.queryUnavailable,
    message: localizedNutritionFeedback(context, controller.error!),
    actionLabel: context.l10n.retry,
    onAction: controller.load,
  );
}
