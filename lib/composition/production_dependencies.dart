import '../features/auth/data/auth_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/food_reference/data/local_food_repository.dart';
import '../features/food_reference/data/catalog_installer.dart';
import '../features/nutrition/data/offline_nutrition_repository.dart';
import '../features/nutrition/data/nutrition_local_store.dart';
import '../features/privacy/data/privacy_repository.dart';
import 'app_dependencies.dart';
import '../features/training_configuration/data/training_configuration_repository.dart';
import '../features/activity/data/activity_repository.dart';

AppDependencies productionDependencies() {
  final installer = CatalogInstaller();
  final catalog = LocalFoodRepository(installer.open, installer: installer);
  return AppDependencies(
    createActivityRepository:
        ({required accountId, required currentAccountId}) =>
            GoActivityRepository(
              accountId: accountId,
              currentAccountId: currentAccountId,
            ),
    createTrainingConfigurationRepository:
        ({required accountId, required currentAccountId}) =>
            GoTrainingConfigurationRepository(
              accountId: accountId,
              currentAccountId: currentAccountId,
            ),
    createSessionRepository: () => AuthRepository(),
    createCatalogRepository: () => GoCatalogRepository(),
    createFoodRepository: () => catalog,
    createPrivacyRepository: () => GoPrivacyRepository(),
    createNutritionRepository:
        ({required accountId, required currentAccountId}) =>
            OfflineNutritionRepository(
              catalog: catalog,
              store: NutritionLocalStore(
                accountId: accountId,
                currentAccountId: currentAccountId,
              ),
            ),
  );
}
