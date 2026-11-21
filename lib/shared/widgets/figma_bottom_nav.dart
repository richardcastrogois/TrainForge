import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TrainForgeDestination {
  today('Hoje', 'home'),
  plans('Planos', 'plans'),
  activity('Atividade', 'activity'),
  food('Diário', 'food'),
  evolution('Evolução', 'evolution');

  final String label, asset;
  const TrainForgeDestination(this.label, this.asset);
  String localizedLabel(BuildContext context) => switch (this) {
    today => context.l10n.today,
    plans => context.l10n.plans,
    activity => context.l10n.activity,
    food => context.l10n.diary,
    evolution => context.l10n.evolution,
  };
}

/// Current Figma v0.5 navigation, with original SVG root geometry.
/// At narrow widths the gap shrinks to preserve at least 48px touch targets.
///
/// Tapping selects a destination. Pressing and dragging along the bar moves
/// the highlight under the finger (the icon under it lights up) and releasing
/// opens that destination, like the iOS 26 tab bar. Reduced motion keeps the
/// gesture but drops the glide animation.
class FigmaBottomNav extends StatefulWidget {
  final TrainForgeDestination selected;
  final ValueChanged<TrainForgeDestination> onSelected;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<FigmaBottomNav> createState() => _FigmaBottomNavState();
}

class _FigmaBottomNavState extends State<FigmaBottomNav> {
  static const _count = 5;

  /// Continuous pill position (0..4) while dragging; null when at rest.
  double? _drag;
  int? _lastHaptic;

  int get _rest => widget.selected.index;
  int get _highlight => (_drag ?? _rest.toDouble()).round().clamp(0, 4);

  double _positionFor(double dx, double slot, double gap) =>
      ((dx - slot / 2) / (slot + gap)).clamp(0.0, (_count - 1).toDouble());

  void _start(double dx, double slot, double gap) => _move(dx, slot, gap);

  void _move(double dx, double slot, double gap) {
    final next = _positionFor(dx, slot, gap);
    final index = next.round();
    if (index != _lastHaptic) {
      _lastHaptic = index;
      HapticFeedback.selectionClick();
    }
    setState(() => _drag = next);
  }

  void _end() {
    final index = _highlight;
    setState(() {
      _drag = null;
      _lastHaptic = null;
    });
    if (index != _rest) widget.onSelected(TrainForgeDestination.values[index]);
  }

  void _cancel() => setState(() {
    _drag = null;
    _lastHaptic = null;
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = dark ? context.tf.primary : const Color(0xff246859);
    final reduced = AppMotion.reduced(context);
    return SizedBox(
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.tf.navSurface,
          border: Border.all(color: context.tf.navBorder),
          borderRadius: BorderRadius.circular(33),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1a183e32),
              offset: Offset(0, 3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gap = constraints.maxWidth >= 300 ? 8.0 : 0.0;
              final width = (constraints.maxWidth - gap * 4) / 5;
              final position = _drag ?? _rest.toDouble();
              final dragging = _drag != null;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (d) => _start(d.localPosition.dx, width, gap),
                onLongPressMoveUpdate: (d) =>
                    _move(d.localPosition.dx, width, gap),
                onLongPressEnd: (_) => _end(),
                onLongPressCancel: _cancel,
                onHorizontalDragStart: (d) =>
                    _start(d.localPosition.dx, width, gap),
                onHorizontalDragUpdate: (d) =>
                    _move(d.localPosition.dx, width, gap),
                onHorizontalDragEnd: (_) => _end(),
                onHorizontalDragCancel: _cancel,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      // Follows the finger 1:1 while dragging; glides at rest.
                      duration: dragging || reduced
                          ? Duration.zero
                          : AppMotion.duration,
                      curve: Curves.easeOutCubic,
                      left: position * (width + gap),
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          scale: dragging ? 1.08 : 1,
                          duration: reduced
                              ? Duration.zero
                              : const Duration(milliseconds: 160),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: pillColor.withValues(
                                alpha: dragging ? .88 : 1,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: dragging
                                  ? [
                                      BoxShadow(
                                        color: pillColor.withValues(alpha: .35),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final destination in TrainForgeDestination.values)
                          SizedBox(
                            width: width,
                            child: _item(
                              context,
                              destination,
                              lit: destination.index == _highlight,
                              dark: dark,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    TrainForgeDestination destination, {
    required bool lit,
    required bool dark,
  }) => Semantics(
    label: destination.localizedLabel(context),
    button: true,
    selected: destination == widget.selected,
    child: Tooltip(
      message: destination.localizedLabel(context),
      // Long press belongs to the drag-to-switch gesture, not the tooltip.
      triggerMode: TooltipTriggerMode.manual,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => widget.onSelected(destination),
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.reduced(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              width: lit ? 28 : 22,
              height: lit ? 28 : 22,
              child: Center(
                child: SvgPicture.asset(
                  'assets/figma/${destination.asset}-${lit ? 'active' : 'inactive'}.svg',
                  excludeFromSemantics: true,
                  colorFilter: dark
                      ? ColorFilter.mode(
                          lit ? context.tf.onPrimary : context.tf.primary,
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
