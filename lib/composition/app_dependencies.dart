import '../features/auth/domain/auth_profile.dart';
import '../features/catalog/domain/catalog_entry.dart';
import '../features/food_reference/domain/food_reference.dart';
import '../features/nutrition/domain/nutrition.dart';
import '../features/privacy/domain/privacy.dart';

typedef NutritionRepositoryFactory =
    NutritionRepository Function({
      required String accountId,
      required String? Function() currentAccountId,
    });

/// Lazy factories composed at the app boundary, never in a feature's widgets.
class AppDependencies {
  final SessionRepository Function() createSessionRepository;
  final CatalogRepository Function() createCatalogRepository;
  final FoodRepository Function() createFoodRepository;
  final PrivacyRepository Function() createPrivacyRepository;
  final NutritionRepositoryFactory createNutritionRepository;

  const AppDependencies({
    required this.createSessionRepository,
    required this.createCatalogRepository,
    required this.createFoodRepository,
    required this.createPrivacyRepository,
    required this.createNutritionRepository,
  });
}
