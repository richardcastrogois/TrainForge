import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/data/profile_photos.dart';
import 'package:trainforge/features/training_configuration/domain/training_configuration.dart';
import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:flutter/material.dart';
import 'figma_components.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'account_page.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/features/training_configuration/presentation/training_configuration_page.dart';
import 'figma_bottom_nav.dart';
import 'glass_sheet.dart';
import 'product_overviews.dart';
import 'shell_labels.dart';
import 'workouts_overview.dart';
import 'package:trainforge/features/nutrition/data/offline_nutrition_repository.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';

class ProductShell extends StatefulWidget {
  final AuthController controller;
  final NutritionRepository? nutritionRepository;
  final CatalogController? plansController;
  final Widget Function(TrainForgeDestination)? pageBuilder;
  final ActivityRepository? activityRepository;
  const ProductShell({
    super.key,
    required this.controller,
    this.nutritionRepository,
    this.plansController,
    this.pageBuilder,
    this.activityRepository,
  });
  @override
  State<ProductShell> createState() => _ProductShellState();
}

class _ProductShellState extends State<ProductShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Floating bar height plus its margins.
  static const _navSpace = FigmaBottomNav.height + 16;

  TrainForgeDestination selected = TrainForgeDestination.today;
  final visited = {TrainForgeDestination.today};
  late final String accountId;
  late final NutritionRepository nutrition;
  late final TrainingConfigurationRepository? configuration;
  ActivityRepository? _activity;
  ActivityRepository? get activity {
    if (_activity != null) return _activity;
    _activity = widget.activityRepository;
    final factory = context
        .getInheritedWidgetOfExactType<AppDependencyScope>()
        ?.dependencies
        .createActivityRepository;
    return _activity ??= factory?.call(
      accountId: accountId,
      currentAccountId: () => widget.controller.profile?.id,
    );
  }

  late final DailySummaryController daily;
  late final AnimationController tabMotion = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
    value: 1,
  );
  @override
  void initState() {
    super.initState();
    accountId = widget.controller.profile!.id;
    nutrition =
        widget.nutritionRepository ??
        AppDependencyScope.read(context).createNutritionRepository(
          accountId: accountId,
          currentAccountId: () => widget.controller.profile?.id,
        );
    final configurationFactory = context
        .getInheritedWidgetOfExactType<AppDependencyScope>()
        ?.dependencies
        .createTrainingConfigurationRepository;
    configuration = configurationFactory?.call(
      accountId: accountId,
      currentAccountId: () => widget.controller.profile?.id,
    );
    daily = DailySummaryController(
      repository: nutrition,
      accountId: accountId,
      currentAccountId: () => widget.controller.profile?.id,
    );
    WidgetsBinding.instance.addObserver(this);
    if (widget.pageBuilder == null) daily.load();
    _googlePhoto();
  }

  /// Accounts that signed in before pictures were kept get the Google one
  /// once, silently; nothing happens when it is not available.
  Future<void> _googlePhoto() async {
    final repository = widget.controller.repository;
    if (repository is! AuthRepository) return;
    final photos = ProfilePhotos.instance;
    await photos.load(accountId);
    if (photos.googleUrl(accountId) != null) return;
    final url = await repository.googlePhotoUrl();
    if (mounted) await photos.setGoogle(accountId, url);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.pageBuilder == null) {
      daily.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabMotion.dispose();
    daily.dispose();
    super.dispose();
  }

  Future<void> openNutrition({DateTime? day, NutritionStart? start}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionPage(
          accountId: accountId,
          initialDate: day,
          start: start,
          currentAccountId: () => widget.controller.profile?.id,
          sessionChanges: widget.controller,
          repository: nutrition,
        ),
      ),
    );
    if (mounted && widget.controller.profile?.id == accountId) {
      await daily.load();
    }
  }

  /// The gate shows the questions again once the answers are forgotten.
  VoidCallback? redoFirstQuestions(BuildContext context) {
    final scope = OnboardingScope.maybeOf(context);
    if (scope == null) return null;
    return () {
      Navigator.of(context).popUntil((route) => route.isFirst);
      scope.notifier!.reset(scope.accountId);
    };
  }

  void openCatalog() => Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => const CatalogPage()),
  );
  void select(TrainForgeDestination value) {
    if (value == selected) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (AppMotion.reduced(context)) {
      tabMotion.value = 1;
    } else {
      tabMotion.forward(from: 0);
    }
    setState(() {
      selected = value;
      visited.add(value);
    });
  }

  VoidCallback? get configure => configuration == null
      ? null
      : () => openTrainingConfiguration(
          context,
          widget.controller,
          configuration!,
        );

  /// Whether the bar shows the "+" actions instead of the pages.
  bool adding = false;

  void closeAdd() {
    if (adding) setState(() => adding = false);
  }

  /// "+": a fan of round glass buttons opens above it (tap again, outside or back to
  /// close). The same choices for everyone; each one opens its page, which
  /// asks for whatever is still missing. Voice and photo live on the food
  /// page, next to "Registrar refeição".
  void openAdd() => setState(() => adding = !adding);

  List<NavAction> addActions(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final offline = nutrition is OfflineNutritionRepository;
    void then(TrainForgeDestination target) {
      closeAdd();
      select(target);
    }

    return [
      NavAction(
        icon: Icons.fitness_center,
        label: l('addWorkout'),
        color: context.tf.accent,
        onTap: () => then(TrainForgeDestination.workouts),
      ),
      NavAction(
        icon: Icons.restaurant,
        label: l('addMeal'),
        color: context.tf.nutrition,
        onTap: () => then(TrainForgeDestination.food),
      ),
      if (offline)
        NavAction(
          icon: Icons.water_drop_outlined,
          label: l('addWater'),
          color: context.tf.blue,
          onTap: () => then(TrainForgeDestination.food),
        ),
    ];
  }

  AccountPage account(BuildContext context) => AccountPage(
    controller: widget.controller,
    redoFirstQuestions: redoFirstQuestions(context),
    configure: configure,
  );

  /// Small card under the round picture: who is signed in and where to go.
  void openProfile() {
    String l(String k) => shellLabel(context, k);
    final profile = widget.controller.profile!;
    void openAccount() => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (route) => account(route)),
    );
    showTopMenu(
      context,
      header: InkWell(
        onTap: () {
          Navigator.pop(context);
          openAccount();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              ProfileAvatar(
                name: profile.name,
                image: profile.image,
                accountId: profile.id,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: context.tf.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      items: [
        TopMenuItem(Icons.tune, l('profileSettings'), openAccount),
        TopMenuItem(Icons.logout, l('signOut'), widget.controller.logout),
      ],
    );
  }

  Widget page(TrainForgeDestination value) {
    if (!visited.contains(value)) return const SizedBox.shrink();
    if (widget.pageBuilder != null) return widget.pageBuilder!(value);
    return switch (value) {
      TrainForgeDestination.today => DailyOverview(
        controller: daily,
        name: widget.controller.profile!.name,
        food: false,
        openDay: (day) => openNutrition(day: day),
        openNutrition: openNutrition,
        openCatalog: openCatalog,
        openActivity: () => select(TrainForgeDestination.evolution),
      ),
      TrainForgeDestination.workouts => WorkoutsOverview(
        openCatalog: openCatalog,
        configure: configure,
      ),
      TrainForgeDestination.food => DailyOverview(
        controller: daily,
        name: widget.controller.profile!.name,
        food: true,
        openVoice: nutrition is OfflineNutritionRepository
            ? () => openNutrition(start: NutritionStart.voice)
            : null,
        openPhoto: nutrition is OfflineNutritionRepository
            ? () => openNutrition(start: NutritionStart.photo)
            : null,
        diary: nutrition is OfflineNutritionRepository ? nutrition : null,
        openNutrition: openNutrition,
        openCatalog: openCatalog,
        openActivity: () => select(TrainForgeDestination.evolution),
      ),
      TrainForgeDestination.evolution => EvolutionPage(
        activity: activity,
        nutrition: nutrition,
        accountId: accountId,
        currentAccountId: () => widget.controller.profile?.id,
        sessionChanges: widget.controller,
        openNutrition: openNutrition,
        openWorkouts: () => select(TrainForgeDestination.workouts),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    if (profile == null || profile.id != accountId) {
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: selected == TrainForgeDestination.today && !adding,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (adding) {
          closeAdd();
        } else {
          select(TrainForgeDestination.today);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  FigmaHeader(
                    name: profile.name,
                    image: profile.image,
                    accountId: profile.id,
                    onProfile: openProfile,
                  ),
                  if (widget.controller.busy)
                    AppProgress(label: context.l10n.confirmingSession),
                  if (widget.controller.message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextButton(
                        onPressed: widget.controller.busy
                            ? null
                            : widget.controller.retry,
                        child: Text(
                          widget.controller.feedback!.localized(context),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          // Pages leave room at the end for the floating bar.
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              padding: MediaQuery.paddingOf(
                                context,
                              ).copyWith(bottom: _navSpace),
                            ),
                            child: FadeTransition(
                              opacity: tabMotion.drive(
                                CurveTween(curve: Curves.easeOutCubic),
                              ),
                              child: IndexedStack(
                                index: selected.index,
                                children: [
                                  for (final value
                                      in TrainForgeDestination.values)
                                    TickerMode(
                                      enabled: value == selected,
                                      child: ExcludeFocus(
                                        excluding: value != selected,
                                        child: page(value),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 8,
                          child: FigmaBottomNav(
                            selected: selected,
                            onSelected: select,
                            onAdd: openAdd,
                            open: adding,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 8,
                          // A tap anywhere else closes the fan and still
                          // reaches the page.
                          child: NavFan(
                            open: adding,
                            actions: addActions(context),
                            onClose: closeAdd,
                          ),
                        ),
                      ],
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
