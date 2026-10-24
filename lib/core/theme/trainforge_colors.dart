import 'package:flutter/material.dart';

@immutable
class TrainForgeColors extends ThemeExtension<TrainForgeColors> {
  final Map<String, Color> values;
  const TrainForgeColors(this.values);
  static const light = TrainForgeColors({
    'background': Color(0xfff6f6f1),
    'surface': Colors.white,
    'ink': Color(0xff142f2c),
    'muted': Color(0xff64736e),
    'cardMuted': Color(0xff506258),
    'primary': Color(0xff215e52),
    'onPrimary': Colors.white,
    'accent': Color(0xffd8eb90),
    'nutrition': Color(0xfff5e3d5),
    'soft': Color(0xffe8eee3),
    'blue': Color(0xffc9eaf7),
    'yellow': Color(0xfff8eba5),
    'pink': Color(0xfff8d6e8),
    'outline': Color(0xff9aaba2),
    'navSurface': Color(0xffe8f0e8),
    'navBorder': Color(0xffc5d9cf),
  });
  // Companion palette derived from the existing green identity, not a claimed Figma dark frame.
  static const dark = TrainForgeColors({
    'background': Color(0xff101c18),
    'surface': Color(0xff1c2d25),
    'ink': Color(0xffedf3e9),
    'muted': Color(0xffb5c8bd),
    'cardMuted': Color(0xffb5c8bd),
    'primary': Color(0xffa4dbc1),
    'onPrimary': Color(0xff12382a),
    'accent': Color(0xff344629),
    'nutrition': Color(0xff42332b),
    'soft': Color(0xff263c31),
    'blue': Color(0xff203e48),
    'yellow': Color(0xff443e22),
    'pink': Color(0xff442e3d),
    'outline': Color(0xff6f8c7d),
    'navSurface': Color(0xff1d352a),
    'navBorder': Color(0xff486653),
  });
  Color get background => values['background']!;
  Color get surface => values['surface']!;
  Color get ink => values['ink']!;
  Color get muted => values['muted']!;
  Color get cardMuted => values['cardMuted']!;
  Color get primary => values['primary']!;
  Color get onPrimary => values['onPrimary']!;
  Color get accent => values['accent']!;
  Color get nutrition => values['nutrition']!;
  Color get soft => values['soft']!;
  Color get blue => values['blue']!;
  Color get yellow => values['yellow']!;
  Color get pink => values['pink']!;
  Color get outline => values['outline']!;
  Color get navSurface => values['navSurface']!;
  Color get navBorder => values['navBorder']!;
  @override
  TrainForgeColors copyWith({Map<String, Color>? colors}) =>
      TrainForgeColors({...values, ...?colors});
  @override
  TrainForgeColors lerp(covariant TrainForgeColors? other, double t) =>
      other == null
      ? this
      : TrainForgeColors({
          for (final key in values.keys)
            key: Color.lerp(values[key], other.values[key], t)!,
        });
}

extension TrainForgeContext on BuildContext {
  TrainForgeColors get tf =>
      Theme.of(this).extension<TrainForgeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? TrainForgeColors.dark
          : TrainForgeColors.light);
}
