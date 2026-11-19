import 'nutrition.dart';

/// Decimal quantities are rational numbers. No double enters saved calculations.
class ExactAmount {
  final BigInt numerator, denominator;
  ExactAmount._(this.numerator, this.denominator);
  factory ExactAmount(BigInt n, BigInt d) {
    if (d == BigInt.zero) throw const FormatException('Zero denominator');
    final divisor = n.gcd(d);
    final sign = d.isNegative ? -BigInt.one : BigInt.one;
    return ExactAmount._(n ~/ divisor * sign, d ~/ divisor * sign);
  }
  factory ExactAmount.parse(String value) {
    if (!RegExp(r'^[+-]?[0-9]+(?:\.[0-9]+)?$').hasMatch(value)) {
      throw const FormatException('Invalid exact decimal');
    }
    final parts = value.split('.');
    return ExactAmount(
      BigInt.parse(value.replaceAll('.', '')),
      BigInt.from(10).pow(parts.length == 2 ? parts[1].length : 0),
    );
  }
  ExactAmount operator +(ExactAmount other) => ExactAmount(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );
  ExactAmount operator *(ExactAmount other) =>
      ExactAmount(numerator * other.numerator, denominator * other.denominator);
  ExactAmount operator /(ExactAmount other) =>
      ExactAmount(numerator * other.denominator, denominator * other.numerator);
  String get fraction => '$numerator/$denominator';

  /// Serialize a finite quantity without rounding or scientific notation.
  /// Nonterminating fractions and oversized wire values fail explicitly.
  String exactDecimal({int maxLength = 80}) {
    final absolute = numerator.abs();
    final result = StringBuffer(
      '${numerator.isNegative ? '-' : ''}${absolute ~/ denominator}',
    );
    var remainder = absolute % denominator;
    if (remainder != BigInt.zero) result.write('.');
    while (remainder != BigInt.zero && result.length <= maxLength) {
      remainder *= BigInt.from(10);
      result.write(remainder ~/ denominator);
      remainder %= denominator;
    }
    if (remainder != BigInt.zero || result.length > maxLength) {
      throw const FormatException('Exact decimal exceeds quantity limit');
    }
    return result.toString();
  }

  String decimal({int places = 6}) {
    final factor = BigInt.from(10).pow(places);
    final scaled =
        (numerator.abs() * factor * BigInt.two + denominator) ~/
        (denominator * BigInt.two);
    final whole = scaled ~/ factor;
    final rest = (scaled % factor)
        .toString()
        .padLeft(places, '0')
        .replaceFirst(RegExp('0+\$'), '');
    return '${numerator.isNegative ? '-' : ''}$whole${rest.isEmpty ? '' : '.$rest'}';
  }
}

const canonicalNames = <String, String>{
  'energy_kcal': 'Energy',
  'protein_g': 'Protein',
  'carbohydrate_g': 'Carbohydrate',
  'fat_g': 'Fat',
  'fiber_g': 'Fiber',
  'sodium_mg': 'Sodium',
  'sugars_g': 'Sugars',
  'saturated_fat_g': 'Saturated fat',
  'cholesterol_mg': 'Cholesterol',
  'calcium_mg': 'Calcium',
  'iron_mg': 'Iron',
  'potassium_mg': 'Potassium',
};

List<Json> scaleCanonical(Json food, String quantity, String unit) {
  final amount = ExactAmount.parse(quantity);
  if (amount.numerator <= BigInt.zero) {
    throw const FormatException('Quantity must be positive');
  }
  final cells = objects(food['canonicalNutrients'] ?? const []);
  final result = <Json>[];
  for (final cell in cells) {
    if (cell['primaryForTotals'] == false) continue;
    final id = cell['nutrientId'] as String;
    final basis = object(food['basis']);
    final basisQuantity =
        cell['basisQuantity'] as String? ?? basis['quantity'] as String?;
    final basisUnit = cell['basisUnit'] as String? ?? basis['unit'] as String?;
    final state = cell['state'] as String? ?? 'missing';
    ExactAmount? factor, value;
    if (basisQuantity != null &&
        basisUnit == unit &&
        ExactAmount.parse(basisQuantity).numerator > BigInt.zero) {
      factor = amount / ExactAmount.parse(basisQuantity);
      if (state == 'numeric' && cell['value'] != null) {
        value = ExactAmount.parse(cell['value'] as String) * factor;
      }
    }
    result.add({
      'nutrientId': id,
      'sourceColumnKey': id,
      'nameOriginal': canonicalNames[id] ?? id,
      'unit': cell['unit'],
      'sourceState': state,
      'rawText': cell['value'] ?? '',
      'sourceReasons': <String>[],
      'sourceValue': cell['value'],
      'sourceUpperBound': cell['upperBound'],
      'basis': {'quantity': basisQuantity, 'unit': basisUnit},
      'factor': factor?.decimal(),
      'value': value?.decimal(),
      'exactFraction': value?.fraction,
      'methodId': cell['methodId'],
      'reason': factor == null
          ? 'food_basis_unresolved'
          : value == null
          ? 'no_exact_numeric_quantity'
          : '',
    });
  }
  return result;
}

Json exactTotals(List<Json> entries, {bool complete = true}) {
  final groups = <String, Json>{};
  final sums = <String, ExactAmount>{};
  var measured = 0, pending = 0;
  for (final entry in entries) {
    final calculation = object(entry['calculation']);
    if (calculation['quantityEvidence'] == 'measured') measured++;
    if (entry['syncState'] != null && entry['syncState'] != 'confirmed') {
      pending++;
    }
    for (final cell in objects(calculation['nutrients'])) {
      final id =
          cell['nutrientId'] as String? ?? cell['sourceColumnKey'] as String;
      final key = '$id|${cell['unit']}';
      final group = groups.putIfAbsent(
        key,
        () => {
          'sourceColumnKey': id,
          'nutrientId': id,
          'nameOriginal': canonicalNames[id] ?? cell['nameOriginal'],
          'unit': cell['unit'],
          'value': null,
          'exactFraction': null,
          'includedEntries': 0,
          'unknownEntries': 0,
        },
      );
      final fraction = cell['exactFraction'] as String?;
      if (fraction == null || cell['value'] == null) {
        group['unknownEntries'] = (group['unknownEntries'] as int) + 1;
      } else {
        final parts = fraction.split('/');
        final value = ExactAmount(
          BigInt.parse(parts.first),
          parts.length == 2 ? BigInt.parse(parts.last) : BigInt.one,
        );
        sums[key] = (sums[key] ?? ExactAmount(BigInt.zero, BigInt.one)) + value;
        group['includedEntries'] = (group['includedEntries'] as int) + 1;
      }
    }
  }
  for (final group in groups.entries) {
    group.value['value'] = sums[group.key]?.decimal();
    group.value['exactFraction'] = sums[group.key]?.fraction;
    // A nutrient absent from another entry is unknown, not a zero.
    group.value['unknownEntries'] =
        entries.length - (group.value['includedEntries'] as int);
  }
  return {
    'entries': entries.length,
    'measuredEntries': measured,
    'estimatedEntries': entries.length - measured,
    'complete': complete,
    'pendingEntries': pending,
    'nutrients': groups.values.toList(),
    'notice': '',
  };
}
