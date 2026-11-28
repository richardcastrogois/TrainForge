import 'dart:math' as math;
import 'glass_surface.dart';
import 'shell_labels.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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

/// One action of the "+" fan ([NavFan]).
class NavAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const NavAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Floating Liquid Glass bar in the iOS 26 style: Hoje · Treinos · (+) ·
/// Alimentação · Evolução, icons only (names stay for screen readers).
///
/// * The bar and the selected-page pill are Liquid Glass
///   ([GlassTabBar.bottom] from liquid_glass_widgets): pressing and dragging
///   along the bar lifts a refracting lens that magnifies what is under the
///   finger; releasing opens that page and the lens settles into the pill.
/// * Only the "+" is raised, in the middle; its slot in the bar never becomes
///   a page.
/// * While [open], the "+" turns into "x" and [NavFan] shows the actions.
class FigmaBottomNav extends StatelessWidget {
  final TrainForgeDestination selected;
  final ValueChanged<TrainForgeDestination> onSelected;
  final VoidCallback? onAdd;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onAdd,
    this.open = false,
  });

  /// Whether the "+" fan is open.
  final bool open;

  /// Height of the "+" centre above the bottom of the bar area.
  static const addCentre = height - _add;

  /// Bar height plus the part of the "+" above it.
  static const height = 82.0;
  static const _bar = 64.0, _add = 30.0;

  /// Slot order on screen; null is the "+".
  static const slots = <TrainForgeDestination?>[
    TrainForgeDestination.today,
    TrainForgeDestination.workouts,
    null,
    TrainForgeDestination.food,
    TrainForgeDestination.evolution,
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _bar,
            child: _tabs(context, dark),
          ),
          Positioned(top: 0, child: _addButton(context)),
        ],
      ),
    );
  }

  static Duration _motion(BuildContext context) => Duration(
    milliseconds: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? 0
        : 380,
  );

  /// Real liquid glass (as iOS): clear, the content behind stays sharp and
  /// bends at the edges, with a light rim. Only a hint of frost and tint so
  /// the icons stay readable.
  static LiquidGlassSettings _glass(BuildContext context, bool dark) =>
      LiquidGlassSettings(
        glassColor: context.tf.surface.withValues(alpha: dark ? .18 : .24),
        blur: 3.2, // a touch of frost so text behind does not fight the icons
        thickness: 32,
        refractiveIndex: 1.38,
        lightIntensity: 1,
        saturation: 1.2,
        chromaticAberration: .012,
      );

  Widget _tabs(BuildContext context, bool dark) => GlassTabBar.bottom(
    key: const ValueKey('nav-tabs'),
    tabs: [
      for (final slot in slots)
        slot == null
            // Room for the raised "+" drawn above the bar.
            ? const GlassTab(icon: SizedBox.square(dimension: 26))
            : GlassTab(
                icon: _TabIcon(slot),
                semanticLabel: slot.localizedLabel(context),
              ),
    ],
    selectedIndex: slots.indexOf(selected),
    onTabSelected: (index) {
      final target = slots[index];
      if (target == null) {
        onAdd?.call();
        return;
      }
      HapticFeedback.selectionClick();
      // The open page itself is not a change.
      if (target != selected) onSelected(target);
    },
    barHeight: _bar,
    horizontalPadding: 0,
    verticalPadding: 0,
    iconSize: 26,
    // Only the icon of the open page changes colour, to the same
    // orange as the "+" (green and orange are the app's pair).
    selectedIconColor: TrainForgeTheme.highlight,
    unselectedIconColor: context.tf.ink,
    // No coloured pill at rest; the clear glass lens shows up only
    // while the finger presses or drags along the bar.
    indicatorColor: Colors.transparent,
    quality: GlassQuality.premium,
    settings: _glass(context, dark),
  );

  Widget _addButton(BuildContext context) => Semantics(
    label: shellLabel(context, open ? 'close' : 'add'),
    button: true,
    excludeSemantics: true,
    child: Tooltip(
      message: shellLabel(context, 'add'),
      triggerMode: TooltipTriggerMode.manual,
      child: TapRegion(
        groupId: NavFan.group,
        child: GestureDetector(
          key: const ValueKey('nav-add'),
          onTap: onAdd == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onAdd!();
                },
          // Solid orange under a glass rim, no border: the same orange as the
          // other main buttons.
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: TrainForgeTheme.highlight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1a183e32),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: GlassContainer(
              width: _add * 2,
              height: _add * 2,
              shape: const LiquidOval(),
              useOwnLayer: true,
              quality: GlassQuality.premium,
              settings: colouredGlass,
              // The "+" turns into "x" while open.
              child: Center(
                child: AnimatedRotation(
                  turns: open ? .125 : 0,
                  duration: _motion(context),
                  curve: Curves.easeInOutCubic,
                  child: const Icon(
                    Icons.add,
                    size: 32,
                    color: TrainForgeTheme.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Tab icon that follows the bar's selected/unselected colour.
class _TabIcon extends StatelessWidget {
  final TrainForgeDestination destination;
  const _TabIcon(this.destination);
  @override
  Widget build(BuildContext context) => Tooltip(
    key: ValueKey('nav-${destination.name}'),
    message: destination.localizedLabel(context),
    // Long press belongs to the drag-to-switch gesture.
    triggerMode: TooltipTriggerMode.manual,
    child: navIcon(
      destination,
      IconTheme.of(context).color ?? context.tf.ink,
      IconTheme.of(context).size ?? 26,
    ),
  );
}

Widget navIcon(TrainForgeDestination destination, Color color, double size) =>
    SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        destination == TrainForgeDestination.food
            // Food and drinks share the tab: a fork and a glass.
            ? 'assets/figma/food-drink.svg'
            : 'assets/figma/${destination.asset}-inactive.svg',
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );

/// The "+" menu as a fan of round glass buttons that glide out of the "+"
/// along a short arc above it and glide back into it. Place it over the page
/// with its bottom on the bottom of [FigmaBottomNav]. A tap anywhere else
/// calls [onClose] and still reaches what is under the finger.
class NavFan extends StatefulWidget {
  final bool open;
  final List<NavAction> actions;
  final VoidCallback onClose;
  const NavFan({
    super.key,
    required this.open,
    required this.actions,
    required this.onClose,
  });

  /// Tap region shared by the fan and the "+".
  static const group = #navFan;

  /// Room the fan needs above the bottom of the bar.
  static const height = FigmaBottomNav.height + 110;

  @override
  State<NavFan> createState() => _NavFanState();
}

class _NavFanState extends State<NavFan> with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    reverseDuration: const Duration(milliseconds: 380),
    value: widget.open ? 1 : 0,
  );

  @override
  void didUpdateWidget(NavFan old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      motion.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      motion.forward();
    } else {
      motion.reverse();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.actions.length;
    // Close together on a short arc: 2 actions at 120/60 degrees, 3 at
    // 145/90/35.
    final spread = n <= 1
        ? 0.0
        : (n == 2
              ? 60.0
              : n == 3
              ? 110.0
              : 150.0);
    const radius = 96.0, side = 58.0;
    return SizedBox(
      height: NavFan.height,
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, _) => IgnorePointer(
          ignoring: !widget.open,
          child: LayoutBuilder(
            builder: (context, box) {
              final cx = box.maxWidth / 2;
              final cy = box.maxHeight - FigmaBottomNav.addCentre;
              final opening = motion.status != AnimationStatus.reverse;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, action) in widget.actions.indexed)
                    Builder(
                      builder: (context) {
                        final angle =
                            (90 +
                                spread / 2 -
                                (n <= 1 ? 0 : spread * i / (n - 1))) *
                            math.pi /
                            180;
                        // One after the other on the way out, the last one
                        // first on the way back.
                        final delay = i * .1;
                        final local = ((motion.value - delay) / (1 - delay))
                            .clamp(0.0, 1.0);
                        final t =
                            (opening
                                    ? Curves.easeOutCubic
                                    : Curves.easeInOutCubic)
                                .transform(local);
                        final x = cx + math.cos(angle) * radius * t;
                        final y = cy - math.sin(angle) * radius * t;
                        return Positioned(
                          left: x - side / 2,
                          top: y - side / 2,
                          width: side,
                          height: side,
                          child: Opacity(
                            opacity: t,
                            child: Transform.scale(
                              scale: .55 + .45 * t,
                              child: TapRegion(
                                groupId: NavFan.group,
                                onTapOutside: (_) {
                                  if (widget.open) widget.onClose();
                                },
                                child: _FanButton(action, side: side),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Round button of solid colour under a glass rim, like the "+" itself. Its
/// name is for screen readers and the long-press tooltip.
class _FanButton extends StatelessWidget {
  final NavAction action;
  final double side;
  const _FanButton(this.action, {required this.side});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: action.label,
    excludeSemantics: true,
    child: Tooltip(
      message: action.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          action.onTap();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: action.color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: GlassContainer(
            width: side,
            height: side,
            shape: const LiquidOval(),
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: colouredGlass,
            child: Center(
              child: Icon(action.icon, size: 26, color: TrainForgeTheme.ink),
            ),
          ),
        ),
      ),
    ),
  );
}
