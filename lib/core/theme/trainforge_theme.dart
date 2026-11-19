import 'package:flutter/material.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'brand_mark.dart';
import 'trainforge_colors.dart';
export 'trainforge_colors.dart';

abstract final class TrainForgeTheme {
  static const background = Color(0xfff6f6f1), surface = Colors.white;
  static const ink = Color(0xff142f2c), muted = Color(0xff64736e);
  static const primary = Color(0xff215e52), accent = Color(0xffd8eb90);
  static const nutrition = Color(0xfff5e3d5), soft = Color(0xffe8eee3);

  /// Deep green used for the mark tile on the brand-green canvas.
  static const deep = Color(0xff174639);

  /// Softer green canvas of the splash and the signed-out entry; native
  /// launch screens use the same value (tf_canvas_green / LaunchScreen).
  static const canvas = Color(0xff2b6b5e);
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);
  static ThemeData build(Brightness brightness) {
    final p = brightness == Brightness.dark
        ? TrainForgeColors.dark
        : TrainForgeColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: brightness == Brightness.dark ? p.accent : null,
          onPrimaryContainer: brightness == Brightness.dark ? p.ink : null,
          secondaryContainer: brightness == Brightness.dark ? p.accent : null,
          onSecondaryContainer: brightness == Brightness.dark ? p.ink : null,
          secondary: p.accent,
          onSecondary: p.ink,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          outline: p.outline,
          surfaceContainer: p.soft,
          surfaceContainerLow: p.background,
          surfaceContainerHigh: p.soft,
          surfaceContainerHighest: Color.alphaBlend(
            p.outline.withValues(alpha: .2),
            p.surface,
          ),
        );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: brightness,
      colorScheme: scheme,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    const buttonText = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return base.copyWith(
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: TrainForgePageTransitions(),
          TargetPlatform.iOS: TrainForgeCupertinoTransitions(),
          TargetPlatform.macOS: TrainForgeCupertinoTransitions(),
          TargetPlatform.windows: TrainForgePageTransitions(),
          TargetPlatform.linux: TrainForgePageTransitions(),
          TargetPlatform.fuchsia: TrainForgePageTransitions(),
        },
      ),
      textTheme: base.textTheme
          .apply(bodyColor: p.ink, displayColor: p.ink, fontFamily: 'Inter')
          .copyWith(
            headlineLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: p.ink,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: p.ink,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Inter',
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: p.ink,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.4,
              color: p.ink,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.35,
              color: p.muted,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide.none,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        errorMaxLines: 4,
        hintStyle: TextStyle(color: p.muted),
        labelStyle: TextStyle(color: p.muted),
        helperMaxLines: 4,
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
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
      ),
      dividerColor: p.outline.withValues(alpha: .35),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.muted,
        indicatorColor: p.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.soft,
        circularTrackColor: p.soft,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        modalBackgroundColor: p.background,
        showDragHandle: true,
        dragHandleColor: p.muted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.background),
        actionTextColor: p.background,
        behavior: SnackBarBehavior.floating,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        headerBackgroundColor: p.soft,
        headerForegroundColor: p.ink,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        dialBackgroundColor: p.soft,
      ),
      popupMenuTheme: PopupMenuThemeData(color: p.surface),
    );
  }
}

class TrainForgeMark extends StatelessWidget {
  final double size;

  /// Tile colour; the deep variant sits on the brand-green canvas.
  final Color background;
  const TrainForgeMark({
    super.key,
    this.size = 34,
    this.background = TrainForgeTheme.primary,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'TF',
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 11 / 34),
      ),
      child: CustomPaint(painter: TrainForgeMarkPainter()),
    ),
  );
}

class TrainForgeMarkPainter extends CustomPainter {
  final double progress;
  TrainForgeMarkPainter({this.progress = 1});
  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * .1;
    HeartbeatGlyph.paint(
      canvas,
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      TrainForgeTheme.accent,
      progress: progress,
    );
  }

  @override
  bool shouldRepaint(TrainForgeMarkPainter old) => old.progress != progress;
}

class TrainForgeBrand extends StatelessWidget {
  /// Lime wordmark and deep tile for the brand-green canvas.
  final bool onBrand;
  const TrainForgeBrand({super.key, this.onBrand = false});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'TrainForge',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrainForgeMark(
          background: onBrand ? TrainForgeTheme.deep : TrainForgeTheme.primary,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'TrainForge',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: onBrand ? TrainForgeTheme.accent : context.tf.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
