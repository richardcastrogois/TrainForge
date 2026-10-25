import '../features/auth/data/auth_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/food_reference/data/food_repository.dart';
import '../features/nutrition/data/nutrition_repository.dart';
import '../features/privacy/data/privacy_repository.dart';
import 'app_dependencies.dart';

AppDependencies productionDependencies() => AppDependencies(
  createSessionRepository: () => AuthRepository(),
  createCatalogRepository: () => GoCatalogRepository(),
  createFoodRepository: () => GoFoodRepository(),
  createPrivacyRepository: () => GoPrivacyRepository(),
  createNutritionRepository:
      ({required accountId, required currentAccountId}) =>
          GoNutritionRepository(
            accountId: accountId,
            currentAccountId: currentAccountId,
          ),
);
