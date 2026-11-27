import 'dart:ui';

import 'shell_labels.dart';
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
/// The open page rises as a circle above the bar, sitting in a notch cut
/// into the glass. Pressing and dragging along the bar carries the circle and
/// the notch under the finger with a liquid stretch; releasing opens that
/// page (the "+" slot is skipped). Reduced motion keeps the gesture without
/// the glide and the stretch.
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

  /// Bar height plus the part of the circle above it.
  static const height = 92.0;

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

// Geometry: the bar starts at [_barTop]; the circle centre sits on its top
// edge and the notch is a slightly larger circle cut from the glass.
const _count = 5, _barTop = 30.0, _pad = 8.0;
const _circle = 28.0, _notch = 35.0, _centerY = 30.0;

class _FigmaBottomNavState extends State<FigmaBottomNav> {
  /// Continuous position (0..4) while dragging; null when at rest.
  double? _drag;
  int? _lastHaptic;

  /// Last finger movement, used for the liquid stretch.
  double _speed = 0;

  int get _rest => _slots.indexOf(widget.selected);
  int get _highlight => (_drag ?? _rest.toDouble()).round().clamp(0, 4);

  double _positionFor(double dx, double slot) =>
      ((dx - _pad - slot / 2) / slot).clamp(0.0, (_count - 1).toDouble());

  void _move(double dx, double slot, [double velocity = 0]) {
    final next = _positionFor(dx, slot);
    final index = next.round();
    if (index != _lastHaptic) {
      _lastHaptic = index;
      HapticFeedback.selectionClick();
    }
    setState(() {
      _drag = next;
      _speed = velocity;
    });
  }

  void _end() {
    final index = _highlight;
    setState(() {
      _drag = null;
      _lastHaptic = null;
      _speed = 0;
    });
    final target = _slots[index];
    if (target != null && index != _rest) widget.onSelected(target);
  }

  void _cancel() => setState(() {
    _drag = null;
    _lastHaptic = null;
    _speed = 0;
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highContrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final tint = highContrast
        ? context.tf.surface
        : context.tf.surface.withValues(alpha: dark ? .72 : .78);
    final dragging = _drag != null;
    final target = _drag ?? _rest.toDouble();
    return SizedBox(
      height: FigmaBottomNav.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = (constraints.maxWidth - _pad * 2) / _count;
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (d) => _move(d.localPosition.dx, slot),
            onLongPressMoveUpdate: (d) => _move(d.localPosition.dx, slot),
            onLongPressEnd: (_) => _end(),
            onLongPressCancel: _cancel,
            onHorizontalDragStart: (d) => _move(d.localPosition.dx, slot),
            onHorizontalDragUpdate: (d) =>
                _move(d.localPosition.dx, slot, d.delta.dx),
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: _cancel,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: target),
              // Follows the finger 1:1; glides with a soft overshoot at rest.
              duration: dragging || reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, position, _) {
                final cx = _pad + (position + .5) * slot;
                final stretch = reduced || !dragging
                    ? 0.0
                    : (.06 + _speed.abs() / 40).clamp(0.0, .22);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: _barTop,
                      child: _GlassNotchBar(cx: cx, tint: tint),
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
                                  ? _addButton(context)
                                  : _item(
                                      context,
                                      _slots[i]!,
                                      // The open page shows in the circle.
                                      hidden: i == _highlight,
                                    ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: cx - _circle,
                      top: _centerY - _circle,
                      child: IgnorePointer(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            1 + stretch,
                            1 - stretch * .6,
                            1,
                          ),
                          // Over the "+" the circle keeps the open page.
                          child: _circleFor(
                            context,
                            _slots[_highlight] ?? widget.selected,
                            dragging: dragging,
                          ),
                        ),
                      ),
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

  Widget _circleFor(
    BuildContext context,
    TrainForgeDestination destination, {
    required bool dragging,
  }) {
    final color = context.tf.primary;
    return AnimatedScale(
      scale: dragging ? 1.08 : 1,
      duration: AppMotion.reduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      child: Container(
        width: _circle * 2,
        height: _circle * 2,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: dragging ? .5 : .35),
              blurRadius: dragging ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(child: _icon(destination, Colors.white, 28)),
      ),
    );
  }

  Widget _icon(TrainForgeDestination destination, Color color, double size) =>
      SizedBox.square(
        dimension: size,
        child: SvgPicture.asset(
          'assets/figma/${destination.asset}-inactive.svg',
          excludeFromSemantics: true,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      );

  /// The "+" lives in the middle of the bar, always visible.
  Widget _addButton(BuildContext context) => Semantics(
    label: shellLabel(context, 'add'),
    button: true,
    excludeSemantics: true,
    child: Tooltip(
      message: shellLabel(context, 'add'),
      triggerMode: TooltipTriggerMode.manual,
      child: Center(
        child: Material(
          color: TrainForgeTheme.highlight,
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('nav-add'),
            customBorder: const CircleBorder(),
            onTap: widget.onAdd == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onAdd!();
                  },
            child: const SizedBox.square(
              dimension: 50,
              child: Icon(Icons.add, size: 30, color: TrainForgeTheme.ink),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _item(
    BuildContext context,
    TrainForgeDestination destination, {
    required bool hidden,
  }) => Semantics(
    label: destination.localizedLabel(context),
    button: true,
    selected: destination == widget.selected,
    excludeSemantics: true,
    child: Tooltip(
      message: destination.localizedLabel(context),
      // Long press belongs to the drag-to-switch gesture, not the tooltip.
      triggerMode: TooltipTriggerMode.manual,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('nav-${destination.name}'),
          customBorder: const CircleBorder(),
          onTap: () => widget.onSelected(destination),
          child: Center(
            child: AnimatedOpacity(
              opacity: hidden ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: _icon(destination, context.tf.ink, 26),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Rounded glass bar with a circular notch at [cx].
class _GlassNotchBar extends StatelessWidget {
  final double cx;
  final Color tint;
  const _GlassNotchBar({required this.cx, required this.tint});

  @override
  Widget build(BuildContext context) {
    final clipper = _NotchClipper(cx);
    return CustomPaint(
      painter: _ShadowPainter(clipper),
      child: ClipPath(
        clipper: clipper,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: CustomPaint(
            painter: _GlassPainter(clipper, tint),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _NotchClipper extends CustomClipper<Path> {
  final double cx;
  _NotchClipper(this.cx);

  @override
  Path getClip(Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(30)),
      );
    final notch = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(cx, _centerY - _barTop), radius: _notch),
      );
    return Path.combine(PathOperation.difference, bar, notch);
  }

  @override
  bool shouldReclip(_NotchClipper oldClipper) => oldClipper.cx != cx;
}

class _ShadowPainter extends CustomPainter {
  final _NotchClipper clipper;
  _ShadowPainter(this.clipper);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawShadow(
    clipper.getClip(size),
    const Color(0xff183e32),
    8,
    false,
  );
  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) =>
      oldDelegate.clipper.cx != clipper.cx;
}

class _GlassPainter extends CustomPainter {
  final _NotchClipper clipper;
  final Color tint;
  _GlassPainter(this.clipper, this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(Colors.white.withValues(alpha: .2), tint),
            tint,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) =>
      oldDelegate.clipper.cx != clipper.cx || oldDelegate.tint != tint;
}
