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
  // Author-selected Grafite e lima. Neutral surfaces carry hierarchy; lime marks actions.
  // 70/20/10 is a visual direction, not a measured pixel quota.
  static const dark = TrainForgeColors({
    'background': Color(0xff111211),
    'surface': Color(0xff242823),
    'ink': Color(0xfff4f6ef),
    'muted': Color(0xffbfc7ba),
    'cardMuted': Color(0xffbfc7ba),
    'primary': Color(0xffd8eb90),
    'onPrimary': Color(0xff263015),
    'accent': Color(0xff303a23),
    'nutrition': Color(0xff242823),
    'soft': Color(0xff2b3028),
    'blue': Color(0xff242823),
    'yellow': Color(0xff242823),
    'pink': Color(0xff242823),
    'outline': Color(0xff869173),
    'navSurface': Color(0xff242823),
    'navBorder': Color(0xff687260),
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
