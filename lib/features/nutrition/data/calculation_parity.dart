import '../domain/exact_nutrition.dart';
import '../domain/nutrition.dart';

ExactAmount? _fraction(Json cell) {
  final raw = cell['exactFraction'] as String?;
  if (raw == null) return null;
  final parts = raw.split('/');
  return ExactAmount(
    BigInt.parse(parts.first),
    parts.length == 2 ? BigInt.parse(parts.last) : BigInt.one,
  );
}

/// Compare mathematical values and unknown states, never formatting or rounded
/// decimals. Source identity is mapped separately during synchronization.
bool sameCalculationSnapshot(
  Json local,
  Json remote, {
  bool meal = false,
  Json? expectedBody,
}) {
  if (meal) {
    final expected = expectedBody ?? object(local['meal']);
    final metadata = object(remote['meal']);
    if (metadata['title'] != expected['title'] ||
        metadata['timezone'] != expected['timezone'] ||
        !_sameInstant(metadata['occurredAt'], expected['occurredAt'])) {
      return false;
    }
    final left = objects(local['entries']), right = objects(remote['entries']);
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!sameCalculationSnapshot(
        left[i],
        right[i],
        expectedBody: expectedBody == null || expectedBody['items'] is! List
            ? null
            : objects(expectedBody['items'])[i],
      )) {
        return false;
      }
    }
    return true;
  }
  final expected = expectedBody ?? local;
  if (remote['foodId'] != expected['foodId'] ||
      remote['foodVersion'] != expected['foodVersion'] ||
      remote['timezone'] != expected['timezone'] ||
      !_sameInstant(remote['occurredAt'], expected['occurredAt'])) {
    return false;
  }
  if (local['quantity'] != remote['quantity'] ||
      local['unit'] != remote['unit']) {
    final l = ExactAmount.parse(local['quantity'] as String),
        r = ExactAmount.parse(remote['quantity'] as String);
    if (l.fraction != r.fraction || local['unit'] != remote['unit']) {
      return false;
    }
  }
  final l = object(local['calculation']), r = object(remote['calculation']);
  final expectedPortion = expectedBody?['portion'] ?? l['portion'];
  if ((expectedPortion == null) != (r['portion'] == null)) return false;
  if (expectedPortion is Map && r['portion'] is Map) {
    final a = object(expectedPortion), b = object(r['portion']);
    for (final key in ['id', 'label', 'unit', 'condition', 'sourceId']) {
      if (a[key] != b[key]) return false;
    }
    if (!_sameDecimal(a['quantity'], b['quantity']) ||
        !_sameDecimal(a['count'], b['count'])) {
      return false;
    }
  }
  if (l['algorithm'] != r['algorithm'] ||
      l['quantityEvidence'] != r['quantityEvidence'] ||
      l['preparation'] != r['preparation']) {
    return false;
  }
  final left = objects(l['nutrients']), right = objects(r['nutrients']);
  String identity(Json cell) =>
      '${cell['nutrientId'] ?? cell['sourceColumnKey']}|${cell['unit']}';
  final remoteCells = {for (final cell in right) identity(cell): cell};
  if (left.length != right.length || remoteCells.length != right.length) {
    return false;
  }
  for (final cell in left) {
    final other = remoteCells[identity(cell)];
    if (other == null || cell['sourceState'] != other['sourceState']) {
      return false;
    }
    if (cell['methodId'] != other['methodId'] ||
        !_sameDecimal(cell['sourceUpperBound'], other['sourceUpperBound']) ||
        object(cell['basis'])['unit'] != object(other['basis'])['unit'] ||
        !_sameDecimal(
          object(cell['basis'])['quantity'],
          object(other['basis'])['quantity'],
        )) {
      return false;
    }
    final a = _fraction(cell), b = _fraction(other);
    if (a?.fraction != b?.fraction) return false;
    if ((cell['value'] == null) != (other['value'] == null)) return false;
  }
  return true;
}

bool _sameDecimal(Object? left, Object? right) {
  if (left == null || right == null) return left == right;
  return ExactAmount.parse(left as String).fraction ==
      ExactAmount.parse(right as String).fraction;
}

bool _sameInstant(Object? left, Object? right) {
  if (left == null || right == null) return left == right;
  final a = DateTime.tryParse(left as String),
      b = DateTime.tryParse(right as String);
  return a != null && b != null && a.isAtSameMomentAs(b);
}
