import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';

/// The page's main button: brand green with a small orange disc for the
/// icon, and a soft light that sweeps across it now and then (still when
/// motion is reduced). Green leads the page; orange only marks the detail.
class MainAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  const MainAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 56,
  });

  @override
  State<MainAction> createState() => _MainActionState();
}

class _MainActionState extends State<MainAction>
    with SingleTickerProviderStateMixin {
  late final loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      loop.repeat();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final green = context.tf.primary;
    final on = context.tf.onPrimary;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: Material(
          color: green,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shadowColor: green,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                children: [
                  // The sweep crosses in the first 40% of each loop.
                  AnimatedBuilder(
                    animation: loop,
                    builder: (context, _) {
                      final v = loop.isAnimating ? loop.value / .4 : 2.0;
                      if (v > 1) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment(-2.4 + 4.8 * v, 0),
                        child: FractionallySizedBox(
                          widthFactor: .4,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: .2),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: TrainForgeTheme.highlight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                size: 20,
                                color: TrainForgeTheme.ink,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: on,
                              ),
                            ),
                          ],
                        ),
                      ),
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
