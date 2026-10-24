import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TrainForgeDestination {
  today('Hoje', 'home'),
  plans('Planos', 'plans'),
  activity('Atividade', 'activity'),
  food('Diário', 'food'),
  evolution('Evolução', 'evolution');

  final String label, asset;
  const TrainForgeDestination(this.label, this.asset);
}

/// Current Figma v0.5 navigation, with original SVG root geometry.
/// At narrow widths the gap shrinks to preserve at least 48px touch targets.
class FigmaBottomNav extends StatelessWidget {
  final TrainForgeDestination selected;
  final ValueChanged<TrainForgeDestination> onSelected;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final destination in TrainForgeDestination.values)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      label: destination.label,
                      button: true,
                      selected: destination == selected,
                      child: Tooltip(
                        message: destination.label,
                        child: Material(
                          color: destination == selected
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? context.tf.primary
                                    : const Color(0xff246859))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            onTap: () => onSelected(destination),
                            borderRadius: BorderRadius.circular(28),
                            child: Center(
                              child: SizedBox.square(
                                dimension: destination == selected ? 28 : 22,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/figma/${destination.asset}-${destination == selected ? 'active' : 'inactive'}.svg',
                                    excludeFromSemantics: true,
                                    colorFilter:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? ColorFilter.mode(
                                            destination == selected
                                                ? context.tf.onPrimary
                                                : context.tf.primary,
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
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
