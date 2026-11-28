/// What the person wants from food, and the starting point the app suggests
/// for it. Every number comes from a public reference named below; the
/// person can change the goal at any time. Not a prescription: pregnancy,
/// people under 18 and anyone with a health condition are told to agree
/// their targets with a professional.
///
/// Sources:
/// * Protein, g/kg/day: International Society of Sports Nutrition position
///   stand "Protein and exercise" (Jäger et al., 2017,
///   doi:10.1186/s12970-017-0177-8): 1.4–2.0 for people who exercise;
///   higher during an energy deficit to keep lean mass. General adults:
///   0.8 (Recommended Dietary Allowance, US Institute of Medicine, 2005).
/// * Meals a day: ISSN "Nutrient timing" (Kerksick et al., 2017,
///   doi:10.1186/s12970-017-0189-4): protein spread evenly every 3–4 h
///   (4 meals in a waking day); more meals mainly help appetite, so the
///   goals that need more food get 5.
/// * Water to drink: EFSA dietary reference values for water (2010,
///   doi:10.2903/j.efsa.2010.1459): total water 2.0 L/day women, 2.5 L/day
///   men, about 20% of it from food, so 1.6 L and 2.0 L to drink. Other or
///   undisclosed gender: the midpoint, 1.8 L.
enum FoodGoal {
  /// Lose fat while keeping muscle.
  loseFat('perder', meals: 4, proteinPerKg: 2.0, tipSource: 'source_protein'),

  /// Keep the current weight.
  maintain('manter', meals: 4, proteinPerKg: 1.4, tipSource: 'source_timing'),

  /// Gain muscle mass.
  gainMuscle('ganhar', meals: 5, proteinPerKg: 1.6, tipSource: 'source_timing'),

  /// Lose fat and gain muscle at the same time.
  recomposition(
    'recompor',
    meals: 4,
    proteinPerKg: 2.0,
    tipSource: 'source_protein',
  ),

  /// Train or play sport better.
  performance(
    'desempenho',
    meals: 5,
    proteinPerKg: 1.6,
    tipSource: 'source_timing',
  ),

  /// Eat better, no body change in mind.
  eatBetter('saude', meals: 4, proteinPerKg: 0.8, tipSource: 'source_rda');

  final String id;
  final int meals;
  final double proteinPerKg;

  /// The reference behind the goal's tip on the picker (`goalTip_<id>`):
  /// the `use` key of one of [foodGoalSources].
  final String tipSource;
  const FoodGoal(
    this.id, {
    required this.meals,
    required this.proteinPerKg,
    required this.tipSource,
  });

  static FoodGoal? fromId(String? id) {
    for (final goal in values) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  /// Daily protein in grams, or null without a weight.
  int? proteinGrams(int? weightKg) =>
      weightKg == null ? null : (weightKg * proteinPerKg).round();

  /// Water to drink a day, in ml (see EFSA above).
  static int waterMl(String? gender) => switch (gender) {
    'woman' => 1600,
    'man' => 2000,
    _ => 1800,
  };
}

/// A published reference behind a number the food page suggests. Shown in
/// "Fontes e transparência" so every value can be traced to its source.
class FoodReferenceSource {
  /// Citation as published (kept in its original language).
  final String citation;
  final String doi;

  /// Key of the label that says what the app takes from it.
  final String use;

  /// Address when the reference has no DOI.
  final String? link;
  const FoodReferenceSource(this.citation, this.doi, this.use, {this.link});
  String get url => link ?? 'https://doi.org/$doi';
  String get shown => doi.isEmpty ? url : 'DOI $doi';
}

const foodGoalSources = [
  FoodReferenceSource(
    'Jäger R, Kerksick CM, Campbell BI, et al. International Society of '
        'Sports Nutrition Position Stand: protein and exercise. Journal of '
        'the International Society of Sports Nutrition. 2017;14:20.',
    '10.1186/s12970-017-0177-8',
    'source_protein',
  ),
  FoodReferenceSource(
    'Institute of Medicine. Dietary Reference Intakes for Energy, '
        'Carbohydrate, Fiber, Fat, Fatty Acids, Cholesterol, Protein, and '
        'Amino Acids. Washington, DC: The National Academies Press; 2005.',
    '10.17226/10490',
    'source_rda',
  ),
  FoodReferenceSource(
    'Kerksick CM, Arent S, Schoenfeld BJ, et al. International Society of '
        'Sports Nutrition position stand: nutrient timing. Journal of the '
        'International Society of Sports Nutrition. 2017;14:33.',
    '10.1186/s12970-017-0189-4',
    'source_timing',
  ),
  FoodReferenceSource(
    'EFSA Panel on Dietetic Products, Nutrition, and Allergies (NDA). '
        'Scientific Opinion on Dietary Reference Values for water. EFSA '
        'Journal. 2010;8(3):1459.',
    '10.2903/j.efsa.2010.1459',
    'source_water',
  ),
];

/// Behind the BMI bands on the body page.
const bodySources = [
  FoodReferenceSource(
    'World Health Organization. Obesity: preventing and managing the global '
        'epidemic. Report of a WHO consultation. WHO Technical Report Series '
        '894. Geneva: World Health Organization; 2000.',
    '',
    'source_bmi',
    link: 'https://iris.who.int/handle/10665/42330',
  ),
];
