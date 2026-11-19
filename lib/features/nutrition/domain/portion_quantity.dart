import '../../food_reference/domain/food_reference.dart';
import 'exact_nutrition.dart';
import 'nutrition.dart';

/// Source quantities retain their original precision; manual inputs use
/// [validDecimal] and are never widened by this validation.
bool validSourceQuantity(Object? value) =>
    value is String &&
    value.length <= 80 &&
    RegExp(r'^[0-9]+(?:\.[0-9]+)?$').hasMatch(value) &&
    RegExp('[1-9]').hasMatch(value);

String? derivedPortionQuantity(FoodPortion portion, String count) {
  if (!validSourceQuantity(portion.quantity) ||
      !validDecimal(count, positive: true)) {
    return null;
  }
  try {
    return (ExactAmount.parse(portion.quantity) * ExactAmount.parse(count))
        .exactDecimal();
  } on FormatException {
    return null;
  }
}

/// Precision beyond manual input is accepted only with an exact, documented
/// portion of this food version and a matching quantity * count.
bool validFoodIntakeQuantity(FoodReference food, Json input) {
  final quantity = input['quantity'];
  if (input['foodId'] != food.id ||
      input['foodVersion'] != food.versionId ||
      !const {'g', 'ml'}.contains(input['unit']) ||
      !validSourceQuantity(quantity)) {
    return false;
  }
  final rawPortion = input['portion'];
  if (rawPortion == null) {
    return validDecimal(quantity as String, positive: true);
  }
  if (rawPortion is! Map) return false;
  final count = rawPortion['count'];
  if (count is! String ||
      !validDecimal(count, positive: true) ||
      rawPortion['unit'] != input['unit']) {
    return false;
  }
  final matches = food.portions.where((p) => p.id == rawPortion['id']);
  if (matches.length != 1) return false;
  final portion = matches.single;
  if (rawPortion['label'] != portion.label ||
      rawPortion['quantity'] != portion.quantity ||
      rawPortion['unit'] != portion.unit ||
      rawPortion['condition'] != portion.condition ||
      rawPortion['sourceId'] != portion.sourceId) {
    return false;
  }
  final derived = derivedPortionQuantity(portion, count);
  if (derived == null) return false;
  return ExactAmount.parse(derived).fraction ==
      ExactAmount.parse(quantity as String).fraction;
}
