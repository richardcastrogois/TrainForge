import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

/// Same fixed brand background as the native launch window, no artificial delay.
class StartupPage extends StatelessWidget {
  final String label;
  const StartupPage({super.key, required this.label});
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: TrainForgeTheme.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: TrainForgeTheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) => constraints.maxHeight < 400
            ? SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TrainForgeMark(size: 64),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SafeArea(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(child: TrainForgeMark(size: 124)),
                    Positioned(
                      top: constraints.maxHeight / 2 + 70,
                      left: 24,
                      right: 24,
                      child: const Text(
                        'trainforge',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: TrainForgeTheme.accent,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 32,
                      left: 24,
                      right: 24,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
