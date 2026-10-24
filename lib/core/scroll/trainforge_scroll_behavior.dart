import 'package:flutter/material.dart';

/// Remove Android's stretch decoration without changing platform physics,
/// scroll notifications, refresh gestures, scrollbars, or iOS bouncing.
class TrainForgeScrollBehavior extends MaterialScrollBehavior {
  const TrainForgeScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => getPlatform(context) == TargetPlatform.android
      ? child
      : super.buildOverscrollIndicator(context, child, details);
}
