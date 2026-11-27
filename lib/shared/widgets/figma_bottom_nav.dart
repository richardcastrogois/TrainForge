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

/// Floating Liquid Glass bar in the iOS 26 style: Hoje · Treinos · (+) ·
/// Alimentação · Evolução, icons only (names stay for screen readers).
///
/// * The bar and the selected-page pill are Liquid Glass
///   ([GlassTabBar.bottom] from liquid_glass_widgets): pressing and dragging
///   along the bar lifts a refracting lens that magnifies what is under the
///   finger; releasing opens that page and the lens settles into the pill.
/// * Only the "+" is raised, in the middle; its slot in the bar never becomes
///   a page.
class FigmaBottomNav extends StatelessWidget {
  final TrainForgeDestination selected;
  final ValueChanged<TrainForgeDestination> onSelected;
  final VoidCallback? onAdd;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onAdd,
  });

  /// Bar height plus the part of the "+" above it.
  static const height = 82.0;
  static const _bar = 64.0, _add = 30.0;

  /// Orange that keeps 3:1 against the light glass (non-text contrast).
  static const activeOrange = Color(0xffd95c0b);

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
            child: GlassTabBar.bottom(
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
              // The icon under the lens turns orange, the app's second colour.
              selectedIconColor: dark
                  ? TrainForgeTheme.highlight
                  : FigmaBottomNav.activeOrange,
              unselectedIconColor: context.tf.ink,
              indicatorColor: TrainForgeTheme.highlight.withValues(
                alpha: dark ? .22 : .16,
              ),
              quality: GlassQuality.premium,
              // Liquid glass with a little frost, so the icons stay readable
              // over busy content (as iOS does).
              settings: LiquidGlassSettings(
                glassColor: context.tf.surface.withValues(
                  alpha: dark ? .18 : .26,
                ),
                blur: 9,
                thickness: 24,
                refractiveIndex: 1.25,
                lightIntensity: .8,
                saturation: 1.3,
              ),
            ),
          ),
          Positioned(top: 0, child: _addButton(context)),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context) => Semantics(
    label: shellLabel(context, 'add'),
    button: true,
    excludeSemantics: true,
    child: Tooltip(
      message: shellLabel(context, 'add'),
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        key: const ValueKey('nav-add'),
        onTap: onAdd == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onAdd!();
              },
        // Orange liquid glass, no border.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40183e32),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: GlassContainer(
            width: _add * 2,
            height: _add * 2,
            shape: const LiquidOval(),
            useOwnLayer: true,
            quality: GlassQuality.premium,
            settings: LiquidGlassSettings(
              glassColor: TrainForgeTheme.highlight.withValues(alpha: .88),
              blur: 6,
              thickness: 22,
              refractiveIndex: 1.25,
              lightIntensity: .9,
            ),
            child: const Center(
              child: Icon(Icons.add, size: 32, color: TrainForgeTheme.ink),
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
