/// Weight over time and the body mass index (BMI).
///
/// Sources and rules (also shown in Fontes e transparência):
/// * BMI = weight (kg) / height (m)², with the adult bands of the World
///   Health Organization: under 18.5 underweight, 18.5–24.9 normal weight,
///   25–29.9 overweight (pre-obesity), 30 or more obesity (WHO Technical
///   Report Series 894, 2000). Not meant for people under 18, pregnancy or
///   very muscular bodies, as the page says.
/// * App rules, not from a source: the trend uses the average of each week
///   (Monday to Sunday), since weight changes from one day to the next;
///   after 7 days without a weigh-in the app suggests a new one.
library;

/// One weigh-in: the day and the weight with one decimal.
class WeighIn {
  final DateTime day;
  final double kg;
  const WeighIn(this.day, this.kg);

  static const minKg = 25.0, maxKg = 250.0;

  Map<String, Object> toJson() => {'d': _date(day), 'w': (kg * 10).round()};

  /// Null when the stored value is invalid or out of range.
  static WeighIn? fromJson(Object? j) {
    if (j is! Map) return null;
    final day = DateTime.tryParse('${j['d']}');
    final tenths = j['w'];
    if (day == null || tenths is! int) return null;
    final kg = tenths / 10;
    if (kg < minKg || kg > maxKg) return null;
    return WeighIn(DateTime(day.year, day.month, day.day), kg);
  }
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Keeps one weigh-in per day (the new one wins), oldest first, at most
/// [limit] (about ten years of weekly weigh-ins).
List<WeighIn> addWeighIn(List<WeighIn> all, WeighIn entry, {int limit = 520}) {
  final day = DateTime(entry.day.year, entry.day.month, entry.day.day);
  final list = [
    for (final w in all)
      if (_date(w.day) != _date(day)) w,
    WeighIn(day, entry.kg),
  ]..sort((a, b) => a.day.compareTo(b.day));
  return list.length > limit ? list.sublist(list.length - limit) : list;
}

/// Average of one week, from Monday.
class WeekAverage {
  final DateTime monday;
  final double kg;
  final int count;
  const WeekAverage(this.monday, this.kg, this.count);
}

DateTime mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// The average of each week with weigh-ins, oldest first.
List<WeekAverage> weeklyAverages(List<WeighIn> all) {
  final weeks = <String, List<double>>{};
  final mondays = <String, DateTime>{};
  for (final w in all) {
    final m = mondayOf(w.day);
    final key = _date(m);
    mondays[key] = m;
    (weeks[key] ??= []).add(w.kg);
  }
  final keys = weeks.keys.toList()..sort();
  return [
    for (final k in keys)
      WeekAverage(
        mondays[k]!,
        weeks[k]!.reduce((a, b) => a + b) / weeks[k]!.length,
        weeks[k]!.length,
      ),
  ];
}

/// BMI with one decimal, or null without a height.
double? bmi(double kg, int? heightCm) {
  if (heightCm == null || heightCm <= 0) return null;
  final m = heightCm / 100;
  return double.parse((kg / (m * m)).toStringAsFixed(1));
}

/// WHO adult bands.
enum BmiBand {
  under(0, 18.5),
  normal(18.5, 25),
  over(25, 30),
  obese(30, double.infinity);

  final double from, to;
  const BmiBand(this.from, this.to);

  static BmiBand of(double value) =>
      values.firstWhere((b) => value >= b.from && value < b.to);
}

/// True when the last weigh-in is 7 or more days old (or there is none).
bool weighInDue(List<WeighIn> all, DateTime now) {
  if (all.isEmpty) return true;
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(all.last.day).inDays >= 7;
}
