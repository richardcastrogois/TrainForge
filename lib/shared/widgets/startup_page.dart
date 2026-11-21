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
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: TrainForgeTheme.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) => constraints.maxHeight < 400
            ? SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TrainForgeMark(
                          size: 64,
                          background: TrainForgeTheme.deep,
                        ),
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
            : Stack(
                children: [
                  // Same position and tile as the native splash and the first
                  // frame of the entry sequence, so the hand-off is seamless.
                  const Center(
                    child: TrainForgeMark(
                      size: 124,
                      background: TrainForgeTheme.deep,
                    ),
                  ),
                  Positioned(
                    bottom: 32 + MediaQuery.paddingOf(context).bottom,
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
  );
}
