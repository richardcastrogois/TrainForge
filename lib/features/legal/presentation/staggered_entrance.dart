import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';

/// Children enter one after another (fade + short rise) and leave together
/// (fade + short drop) when [leaving] becomes true. Reduced motion shows the
/// final state immediately.
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final bool leaving;
  final VoidCallback? onLeft;
  final Duration step;
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.leaving = false,
    this.onLeft,
    this.step = const Duration(milliseconds: 45),
  });
  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with TickerProviderStateMixin {
  late final AnimationController enter = AnimationController(
    vsync: this,
    duration: AppMotion.duration + widget.step * (widget.children.length - 1),
  );
  late final AnimationController exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    if (AppMotion.reduced(context)) {
      enter.value = 1;
    } else {
      enter.forward();
    }
  }

  @override
  void didUpdateWidget(StaggeredEntrance old) {
    super.didUpdateWidget(old);
    if (widget.leaving && !old.leaving) {
      if (AppMotion.reduced(context)) {
        exit.value = 1;
        widget.onLeft?.call();
      } else {
        exit.forward().whenComplete(() => widget.onLeft?.call());
      }
    }
  }

  @override
  void dispose() {
    enter.dispose();
    exit.dispose();
    super.dispose();
  }

  double _slot(int index) {
    final total = enter.duration!.inMilliseconds;
    final start = ((widget.step.inMilliseconds * index) / total).clamp(
      0.0,
      1.0,
    );
    final end = (start + AppMotion.duration.inMilliseconds / total).clamp(
      start,
      1.0,
    );
    return Interval(
      start,
      end,
      curve: Curves.easeOutCubic,
    ).transform(enter.value);
  }

  Widget _item(double inValue, double outValue, Widget child) => Opacity(
    opacity: (inValue * (1 - outValue)).clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(0, 14 * (1 - inValue) + 10 * outValue),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            _item(
              _slot(i),
              Curves.easeInCubic.transform(exit.value),
              widget.children[i],
            ),
        ],
      ),
    );
  }
}
