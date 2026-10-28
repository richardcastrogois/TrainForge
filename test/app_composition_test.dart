import 'package:trainforge/features/training_configuration/presentation/training_configuration_page.dart';
import 'training_configuration_test.dart' show ConfigurationFixture;
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/app.dart';
import 'package:trainforge/composition/app_dependencies.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/shared/widgets/product_shell.dart';

import 'appearance_startup_motion_test.dart' show MemoryAppearance;
import 'auth_controller_test.dart' show SessionFixture, fixtureProfile;
import 'catalog_test.dart' show FixtureCatalog;
import 'food_reference_test.dart' show FixtureFoods;
import 'nutrition_test.dart' show FakeNutrition;
import 'privacy_test.dart' show FixturePrivacy;

// Isolated test services; never supplied to a runtime app or a real account.
class CompositionFixture {
  final session = SessionFixture();
  final catalog = FixtureCatalog();
  final foods = FixtureFoods();
  final privacy = FixturePrivacy();
  final nutrition =
      <
        ({
          String accountId,
          String? Function() currentAccountId,
          ObservedNutrition repository,
        })
      >[];
  final configurations =
      <
        ({
          String accountId,
          String? Function() currentAccountId,
          ConfigurationFixture repository,
        })
      >[];
  int sessions = 0, catalogs = 0, foodLists = 0, policies = 0;

  late final dependencies = AppDependencies(
    createTrainingConfigurationRepository:
        ({required accountId, required currentAccountId}) {
          final repository = ConfigurationFixture();
          configurations.add((
            accountId: accountId,
            currentAccountId: currentAccountId,
            repository: repository,
          ));
          return repository;
        },
    createSessionRepository: () {
      sessions++;
      return session;
    },
    createCatalogRepository: () {
      catalogs++;
      return catalog;
    },
    createFoodRepository: () {
      foodLists++;
      return foods;
    },
    createPrivacyRepository: () {
      policies++;
      return privacy;
    },
    createNutritionRepository:
        ({required accountId, required currentAccountId}) {
          final repository = ObservedNutrition();
          nutrition.add((
            accountId: accountId,
            currentAccountId: currentAccountId,
            repository: repository,
          ));
          return repository;
        },
  );
}

class ObservedNutrition extends FakeNutrition {
  int summaries = 0, entryLists = 0;
  @override
  Future<Json> summary(String day, String zone) {
    summaries++;
    return super.summary(day, zone);
  }

  @override
  Future<NutritionPageData> entries(String day, String zone, {String? cursor}) {
    entryLists++;
    return super.entries(day, zone, cursor: cursor);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          NativeLocaleStore.channel,
          (call) async => call.method == 'read' ? 'pt-BR' : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeLocaleStore.channel, null);
  });
  testWidgets(
    'public routes use injected services lazily and theme changes retain session',
    (tester) async {
      final services = CompositionFixture();
      final appearance = AppearanceController(store: MemoryAppearance());
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        TrainForgeApp(
          dependencies: services.dependencies,
          appearance: appearance,
        ),
      );
      await tester.pumpAndSettle();
      expect(services.sessions, 1);
      expect(services.session.restores, 1);
      expect(services.catalogs, 0);
      expect(services.foodLists, 0);
      expect(services.policies, 0);
      expect(services.nutrition, isEmpty);

      await tester.ensureVisible(find.text('Consultar biblioteca sem entrar'));
      await tester.tap(find.text('Consultar biblioteca sem entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPage), findsOneWidget);
      expect(services.catalogs, 1);
      expect(services.catalog.pageCalls, greaterThan(0));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final foodLink = find.text('Consultar alimentos sem registrar consumo');
      await tester.ensureVisible(foodLink);
      await tester.tap(foodLink);
      await tester.pumpAndSettle();
      expect(find.byType(FoodPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Isolated food first'),
        250,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('Isolated food first'), findsOneWidget);
      expect(services.foodLists, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Privacidade e dados'));
      await tester.tap(find.text('Privacidade e dados'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(services.policies, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await appearance.select(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(services.sessions, 1);
      expect(services.session.restores, 1);
      expect(services.nutrition, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nutrition routes reuse the account service and account change removes old routes',
    (tester) async {
      final services = CompositionFixture()..session.profile = fixtureProfile;
      final appearance = AppearanceController(store: MemoryAppearance());
      addTearDown(appearance.dispose);
      await tester.pumpWidget(
        TrainForgeApp(
          dependencies: services.dependencies,
          appearance: appearance,
        ),
      );
      await tester.pumpAndSettle();
      final accountA = services.nutrition.single;
      expect(accountA.accountId, fixtureProfile.id);
      expect(accountA.currentAccountId(), fixtureProfile.id);
      expect(accountA.repository.summaries, 1);

      await tester.scrollUntilVisible(
        find.text('Minha alimentação'),
        250,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.tap(find.text('Minha alimentação'));
      await tester.pumpAndSettle();
      final page = tester.widget<NutritionPage>(find.byType(NutritionPage));
      expect(identical(page.repository, accountA.repository), isTrue);
      expect(accountA.repository.entryLists, 1);
      expect(accountA.repository.summaries, 2);
      expect(services.nutrition, hasLength(1));

      const other = AuthProfile(
        id: 'other-isolated-account',
        name: 'Other fixture',
        email: 'other@example.invalid',
      );
      final auth = tester
          .widget<ProductShell>(find.byType(ProductShell, skipOffstage: false))
          .controller;
      services.session.profile = other;
      await auth.restore();
      await tester.pumpAndSettle();
      expect(find.byType(NutritionPage), findsNothing);
      expect(services.nutrition, hasLength(2));
      expect(services.nutrition.last.accountId, other.id);
      expect(services.nutrition.last.currentAccountId(), other.id);
      expect(accountA.currentAccountId(), other.id);
      expect(
        identical(services.nutrition.last.repository, accountA.repository),
        isFalse,
      );
      expect(services.sessions, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'training setup route uses the composed account service and clears on account change',
    (t) async {
      final services = CompositionFixture()..session.profile = fixtureProfile;
      final appearance = AppearanceController(store: MemoryAppearance());
      addTearDown(appearance.dispose);
      await t.pumpWidget(
        TrainForgeApp(
          dependencies: services.dependencies,
          appearance: appearance,
        ),
      );
      await t.pumpAndSettle();
      final account = services.configurations.single;
      expect(account.accountId, fixtureProfile.id);
      expect(account.repository.reads, 0);
      await t.tap(find.byTooltip('Abrir perfil'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Configuração de treino'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await t.tap(find.text('Configuração de treino'));
      await t.pumpAndSettle();
      expect(
        identical(
          t
              .widget<TrainingConfigurationPage>(
                find.byType(TrainingConfigurationPage),
              )
              .repository,
          account.repository,
        ),
        true,
      );
      expect(account.repository.reads, 1);
      expect(account.repository.bodies, isEmpty);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Planos'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Criar o meu plano'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await t.tap(find.text('Criar o meu plano'));
      await t.pumpAndSettle();
      expect(find.byType(TrainingConfigurationPage), findsOneWidget);
      expect(account.repository.reads, 2);
      expect(services.configurations.length, 1);
      final auth = t
          .widget<ProductShell>(find.byType(ProductShell, skipOffstage: false))
          .controller;
      services.session.profile = const AuthProfile(
        id: 'new-owner',
        name: 'New owner',
        email: 'new@example.invalid',
      );
      await auth.restore();
      await t.pumpAndSettle();
      expect(find.byType(TrainingConfigurationPage), findsNothing);
      expect(account.currentAccountId(), 'new-owner');
      expect(services.configurations.length, 2);
      expect(t.takeException(), isNull);
    },
  );
}
