import 'package:flutter/material.dart';

/// Tokens read from the current Figma v0.5: node 23:735 (entry).
/// Platform font retained until a distributable Inter font asset is supplied.
abstract final class TrainForgeTheme {
  static const background = Color(0xfff6f6f1), surface = Colors.white;
  static const ink = Color(0xff142f2c), muted = Color(0xff64736e);
  static const primary = Color(0xff215e52), accent = Color(0xffd8eb90);
  static const nutrition = Color(0xfff5e3d5), soft = Color(0xffe8eee3);
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: ink,
        secondary: accent,
        onSecondary: ink,
        outline: muted,
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            headlineLarge: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: ink,
            ),
            headlineSmall: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: ink,
            ),
            titleLarge: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: ink,
            ),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.4, color: ink),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide.none,
          shape: shape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      dividerColor: soft,
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: muted,
        indicatorColor: primary,
      ),
    );
  }
}

class TrainForgeBrand extends StatelessWidget {
  const TrainForgeBrand({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'TrainForge',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TrainForgeTheme.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Text(
            'TF',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TrainForgeTheme.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'trainforge',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: TrainForgeTheme.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
