import 'package:trainforge/features/training_configuration/domain/training_configuration.dart';
import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:flutter/material.dart';
import 'figma_components.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/daily_summary_controller.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'account_page.dart';
import 'package:trainforge/features/training_configuration/presentation/training_configuration_page.dart';
import 'figma_bottom_nav.dart';
import 'plans_overview.dart';
import 'product_overviews.dart';

class ProductShell extends StatefulWidget {
  final AuthController controller;
  final NutritionRepository? nutritionRepository;
  final CatalogController? plansController;
  final Widget Function(TrainForgeDestination)? pageBuilder;
  const ProductShell({
    super.key,
    required this.controller,
    this.nutritionRepository,
    this.plansController,
    this.pageBuilder,
  });
  @override
  State<ProductShell> createState() => _ProductShellState();
}

class _ProductShellState extends State<ProductShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  TrainForgeDestination selected = TrainForgeDestination.today;
  final visited = {TrainForgeDestination.today};
  late final String accountId;
  late final NutritionRepository nutrition;
  late final TrainingConfigurationRepository? configuration;
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

  Future<void> openNutrition({DateTime? day}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NutritionPage(
          accountId: accountId,
          initialDate: day,
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
        openActivity: () => select(TrainForgeDestination.activity),
      ),
      TrainForgeDestination.plans => PlansOverview(
        controller: widget.plansController,
        configure: configuration == null
            ? null
            : () => openTrainingConfiguration(
                context,
                widget.controller,
                configuration!,
              ),
      ),
      TrainForgeDestination.activity => const ActivityOverview(),
      TrainForgeDestination.food => DailyOverview(
        controller: daily,
        name: widget.controller.profile!.name,
        food: true,
        openNutrition: openNutrition,
        openCatalog: openCatalog,
        openActivity: () => select(TrainForgeDestination.activity),
      ),
      TrainForgeDestination.evolution => EvolutionOverview(
        openNutrition: openNutrition,
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
      canPop: selected == TrainForgeDestination.today,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) select(TrainForgeDestination.today);
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
                    onProfile: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountPage(
                          controller: widget.controller,
                          configure: configuration == null
                              ? null
                              : () => openTrainingConfiguration(
                                  context,
                                  widget.controller,
                                  configuration!,
                                ),
                        ),
                      ),
                    ),
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
                    child: FadeTransition(
                      opacity: tabMotion.drive(
                        CurveTween(curve: Curves.easeOutCubic),
                      ),
                      child: IndexedStack(
                        index: selected.index,
                        children: [
                          for (final value in TrainForgeDestination.values)
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: FigmaBottomNav(
                      selected: selected,
                      onSelected: select,
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
