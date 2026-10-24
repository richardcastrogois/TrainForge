import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const duration = Duration(milliseconds: 220);
  static bool reduced(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media != null) {
      return media.disableAnimations || media.accessibleNavigation;
    }
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.accessibleNavigation;
  }

  static AnimationStyle style(BuildContext context) => reduced(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: duration,
          reverseDuration: Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
        );
}

/// Applies only to the incoming subtree: private outgoing content is never kept alive.
class AppAppear extends StatefulWidget {
  final Widget child;
  const AppAppear({super.key, required this.child});
  @override
  State<AppAppear> createState() => _AppAppearState();
}

class _AppAppearState extends State<AppAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: AppMotion.duration,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      controller.value = 1;
    } else if (!controller.isAnimating && controller.value == 0) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: FadeTransition(
      opacity: controller.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: widget.child,
    ),
  );
}

class TrainForgePageTransitions extends PageTransitionsBuilder {
  const TrainForgePageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: const Offset(.035, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

class TrainForgeCupertinoTransitions extends PageTransitionsBuilder {
  const TrainForgeCupertinoTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    return const CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
