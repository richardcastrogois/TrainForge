import 'shell_labels.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The four pages of the app. The "+" in the middle of the bar is an action,
/// not a page.
enum TrainForgeDestination {
  today('Hoje', 'home'),
  workouts('Treinos', 'plans'),
  food('Alimentação', 'food'),
  evolution('Evolução', 'evolution');

  final String label, asset;
  const TrainForgeDestination(this.label, this.asset);
  String localizedLabel(BuildContext context) => shellLabel(context, name);
}

/// Floating frosted-glass bar: Hoje · Treinos · (+) · Alimentação · Evolução,
/// icons only (names stay for screen readers and long-press tooltips).
///
/// * The "+" is bigger and stays raised in the middle.
/// * The bar itself is Liquid Glass (refraction, rim light), not a plain
///   blur: it bends what scrolls behind it.
/// * The open page rises as a green circle over the bar. Moving between
///   pages (tap or drag) it glides; near the "+" it sinks into the bar and
///   comes back up on the other side, so it never crosses over the "+".
/// * Pressing and dragging along the bar carries the lens under the finger;
///   releasing opens that page. Reduced motion removes the glide.
class FigmaBottomNav extends StatefulWidget {
  final TrainForgeDestination selected;
  final ValueChanged<TrainForgeDestination> onSelected;
  final VoidCallback? onAdd;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onAdd,
  });

  /// Bar height plus the part of the circles above it.
  static const height = 96.0;

  @override
  State<FigmaBottomNav> createState() => _FigmaBottomNavState();
}

/// Slot order on screen; null is the "+".
const _slots = <TrainForgeDestination?>[
  TrainForgeDestination.today,
  TrainForgeDestination.workouts,
  null,
  TrainForgeDestination.food,
  TrainForgeDestination.evolution,
];

// Geometry (logical pixels). The bar starts at [_barTop].
const _count = 5, _barTop = 30.0, _pad = 6.0;
const _lens = 25.0, _lensY = 30.0;
const _add = 31.0, _addY = 26.0;

/// 1 away from the "+", 0 right over it: the lens sinks there.
double _visibility(double position) =>
    (((position - 2).abs() - .3) / .5).clamp(0.0, 1.0);

class _FigmaBottomNavState extends State<FigmaBottomNav> {
  /// Continuous position (0..4) while dragging; null when at rest.
  double? _drag;
  int? _lastHaptic;

  int get _rest => _slots.indexOf(widget.selected);

  /// Nearest page to [position], never the "+".
  int _pageNear(double position) {
    final index = position.round().clamp(0, 4);
    if (_slots[index] != null) return index;
    return position < 2 ? 1 : 3;
  }

  double _positionFor(double dx, double slot) =>
      ((dx - _pad - slot / 2) / slot).clamp(0.0, (_count - 1).toDouble());

  void _move(double dx, double slot) {
    final next = _positionFor(dx, slot);
    final index = _pageNear(next);
    if (index != _lastHaptic) {
      _lastHaptic = index;
      HapticFeedback.selectionClick();
    }
    setState(() => _drag = next);
  }

  void _end() {
    final index = _pageNear(_drag ?? _rest.toDouble());
    setState(() {
      _drag = null;
      _lastHaptic = null;
    });
    if (index != _rest) widget.onSelected(_slots[index]!);
  }

  void _cancel() => setState(() {
    _drag = null;
    _lastHaptic = null;
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final tint = context.tf.surface.withValues(alpha: dark ? .3 : .38);
    final dragging = _drag != null;
    return SizedBox(
      height: FigmaBottomNav.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = (constraints.maxWidth - _pad * 2) / _count;
          double xOf(double position) => _pad + (position + .5) * slot;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (d) => _move(d.localPosition.dx, slot),
            onLongPressMoveUpdate: (d) => _move(d.localPosition.dx, slot),
            onLongPressEnd: (_) => _end(),
            onLongPressCancel: _cancel,
            onHorizontalDragStart: (d) => _move(d.localPosition.dx, slot),
            onHorizontalDragUpdate: (d) => _move(d.localPosition.dx, slot),
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: _cancel,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _drag ?? _rest.toDouble()),
              duration: dragging || reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              builder: (context, position, _) {
                final visible = reduced ? 1.0 : _visibility(position);
                final shown = _slots[_pageNear(position)]!;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: _barTop,
                      child: _LiquidBar(tint: tint, plain: highContrast),
                    ),
                    Positioned(
                      left: _pad,
                      right: _pad,
                      top: _barTop,
                      bottom: 0,
                      child: Row(
                        children: [
                          for (var i = 0; i < _count; i++)
                            SizedBox(
                              width: slot,
                              child: _slots[i] == null
                                  ? const SizedBox.shrink()
                                  : _item(
                                      context,
                                      _slots[i]!,
                                      // The page under the lens shows in it.
                                      opacity:
                                          ((position - i).abs() * 1.6 +
                                                  (1 - visible))
                                              .clamp(0.0, 1.0),
                                    ),
                            ),
                        ],
                      ),
                    ),
                    // Lens of the open page; sinks near the "+".
                    Positioned(
                      left: xOf(position) - _lens,
                      top: _lensY - _lens + (1 - visible) * 30,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: visible,
                          child: Transform.scale(
                            scale: (.6 + .4 * visible) * (dragging ? 1.06 : 1),
                            child: _Lens(destination: shown),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: xOf(2) - _add,
                      top: _addY - _add,
                      child: _addButton(context),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Bigger raised "+" in the middle, always above the bar.
  Widget _addButton(BuildContext context) => Semantics(
    label: shellLabel(context, 'add'),
    button: true,
    excludeSemantics: true,
    child: Tooltip(
      message: shellLabel(context, 'add'),
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        key: const ValueKey('nav-add'),
        onTap: widget.onAdd == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onAdd!();
              },
        child: Container(
          width: _add * 2,
          height: _add * 2,
          decoration: BoxDecoration(
            color: TrainForgeTheme.highlight,
            shape: BoxShape.circle,
            border: Border.all(color: context.tf.background, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40183e32),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 32, color: TrainForgeTheme.ink),
        ),
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    TrainForgeDestination destination, {
    required double opacity,
  }) => Semantics(
    label: destination.localizedLabel(context),
    button: true,
    selected: destination == widget.selected,
    excludeSemantics: true,
    child: Tooltip(
      message: destination.localizedLabel(context),
      // Long press belongs to the drag-to-switch gesture, not the tooltip.
      triggerMode: TooltipTriggerMode.manual,
      // No ripple: the lens is the only feedback.
      child: GestureDetector(
        key: ValueKey('nav-${destination.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(destination),
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: navIcon(destination, context.tf.ink, 26),
          ),
        ),
      ),
    ),
  );
}

Widget navIcon(TrainForgeDestination destination, Color color, double size) {
  Widget svg(double side) => SizedBox.square(
    dimension: side,
    child: SvgPicture.asset(
      'assets/figma/${destination.asset}-inactive.svg',
      excludeFromSemantics: true,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
  if (destination != TrainForgeDestination.food) return svg(size);
  // Food and drinks share the tab: a fork and a glass.
  return SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      'assets/figma/food-drink.svg',
      excludeFromSemantics: true,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
}

/// The open page: solid brand-green circle with its icon in white.
class _Lens extends StatelessWidget {
  final TrainForgeDestination destination;
  const _Lens({required this.destination});
  @override
  Widget build(BuildContext context) => Container(
    width: _lens * 2,
    height: _lens * 2,
    decoration: BoxDecoration(
      color: context.tf.primary,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: context.tf.primary.withValues(alpha: .35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Center(child: navIcon(destination, Colors.white, 26)),
  );
}

/// Liquid Glass capsule (refraction, light rim). With high contrast it is
/// an opaque surface instead.
class _LiquidBar extends StatelessWidget {
  final Color tint;
  final bool plain;
  const _LiquidBar({required this.tint, required this.plain});
  @override
  Widget build(BuildContext context) {
    const radius = 34.0;
    final shadow = BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2b183e32),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    );
    if (plain) {
      return DecoratedBox(
        decoration: shadow.copyWith(color: context.tf.surface),
      );
    }
    return DecoratedBox(
      decoration: shadow,
      child: GlassContainer(
        shape: const LiquidRoundedSuperellipse(borderRadius: radius),
        useOwnLayer: true,
        quality: GlassQuality.premium,
        settings: LiquidGlassSettings(
          glassColor: tint,
          thickness: 26,
          blur: 2.5,
          refractiveIndex: 1.28,
          lightIntensity: .9,
          saturation: 1.4,
          chromaticAberration: .02,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
