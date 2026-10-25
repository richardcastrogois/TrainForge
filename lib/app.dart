import 'core/l10n/locale_controller.dart';
import 'core/l10n/localized_context.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'composition/app_dependencies.dart';
import 'composition/app_dependency_scope.dart';
import 'composition/production_dependencies.dart';
import 'package:flutter/services.dart';
import 'core/theme/trainforge_theme.dart';
import 'core/theme/appearance_controller.dart';
import 'core/motion/app_motion.dart';
import 'core/scroll/trainforge_scroll_behavior.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/nutrition/domain/nutrition.dart';
import 'shared/widgets/auth_gate.dart';
import 'shared/widgets/startup_page.dart';

class TrainForgeApp extends StatefulWidget {
  final AppDependencies? dependencies;
  final LocaleController? language;
  final AppearanceController? appearance;
  final AuthController? authController;
  final NutritionRepository? nutritionRepository;
  const TrainForgeApp({
    super.key,
    this.dependencies,
    this.language,
    this.appearance,
    this.authController,
    this.nutritionRepository,
  });
  @override
  State<TrainForgeApp> createState() => _TrainForgeAppState();
}

class _TrainForgeAppState extends State<TrainForgeApp> {
  late final dependencies = widget.dependencies ?? productionDependencies();
  late final appearance = widget.appearance ?? AppearanceController();
  late final language = widget.language ?? LocaleController();
  late final preferences = Listenable.merge([appearance, language]);
  bool initialThemeApplied = false;
  @override
  void initState() {
    super.initState();
    appearance.restore();
    language.restore();
  }

  @override
  void dispose() {
    if (widget.appearance == null) appearance.dispose();
    if (widget.language == null) language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppDependencyScope(
    dependencies: dependencies,
    child: LocaleScope(
      controller: language,
      child: AppearanceScope(
        controller: appearance,
        child: ListenableBuilder(
          listenable: preferences,
          builder: (context, _) {
            final animateTheme = initialThemeApplied;
            if (appearance.loaded) initialThemeApplied = true;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'TrainForge',
              locale: language.choice.locale,
              localeListResolutionCallback: resolveAppLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: supportedAppLocales,
              scrollBehavior: const TrainForgeScrollBehavior(),
              theme: TrainForgeTheme.light,
              darkTheme: TrainForgeTheme.dark,
              themeMode: appearance.mode,
              themeAnimationDuration:
                  !animateTheme || AppMotion.reduced(context)
                  ? Duration.zero
                  : AppMotion.duration,
              builder: (context, child) {
                final dark = Theme.of(context).brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: dark
                        ? Brightness.light
                        : Brightness.dark,
                    statusBarBrightness: dark
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarColor: context.tf.background,
                    systemNavigationBarIconBrightness: dark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                  child: child!,
                );
              },
              home: appearance.loaded && language.loaded
                  ? AuthGate(
                      controller: widget.authController,
                      nutritionRepository: widget.nutritionRepository,
                    )
                  : Builder(
                      builder: (context) =>
                          StartupPage(label: context.l10n.preparing),
                    ),
            );
          },
        ),
      ),
    ),
  );
}
