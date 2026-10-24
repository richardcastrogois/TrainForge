import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/trainforge_theme.dart';
import 'core/theme/appearance_controller.dart';
import 'core/motion/app_motion.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/nutrition/domain/nutrition.dart';
import 'shared/widgets/auth_gate.dart';
import 'shared/widgets/startup_page.dart';

class TrainForgeApp extends StatefulWidget {
  final AppearanceController? appearance;
  final AuthController? authController;
  final NutritionRepository? nutritionRepository;
  const TrainForgeApp({
    super.key,
    this.appearance,
    this.authController,
    this.nutritionRepository,
  });
  @override
  State<TrainForgeApp> createState() => _TrainForgeAppState();
}

class _TrainForgeAppState extends State<TrainForgeApp> {
  late final appearance = widget.appearance ?? AppearanceController();
  bool initialThemeApplied = false;
  @override
  void initState() {
    super.initState();
    appearance.restore();
  }

  @override
  void dispose() {
    if (widget.appearance == null) appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    controller: appearance,
    child: ListenableBuilder(
      listenable: appearance,
      builder: (context, _) {
        final animateTheme = initialThemeApplied;
        if (appearance.loaded) initialThemeApplied = true;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TrainForge',
          theme: TrainForgeTheme.light,
          darkTheme: TrainForgeTheme.dark,
          themeMode: appearance.mode,
          themeAnimationDuration: !animateTheme || AppMotion.reduced(context)
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
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: context.tf.background,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
              ),
              child: child!,
            );
          },
          home: appearance.loaded
              ? AuthGate(
                  controller: widget.authController,
                  nutritionRepository: widget.nutritionRepository,
                )
              : const StartupPage(label: 'Preparando o TrainForge'),
        );
      },
    ),
  );
}
