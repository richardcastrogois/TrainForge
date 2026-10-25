# Telas e fluxos

> Gerado de código e registros versionados por `tools/gerar_documentacao.py`. Não editar este arquivo à mão. Revisão das entradas: `1268d3cacb87300c`.

## Atual: referências entre widgets

Construtor referenciado é evidência estática. Condições, botão voltar, clique e transição real não foram executados pelo gerador.

```mermaid
flowchart LR
    node0["AppearancePage"]
    node1["AuthPage"]
    node2["CatalogDetailPage"]
    node3["CatalogPage"]
    node4["FoodDetailPage"]
    node5["FoodPage"]
    node6["HomePage"]
    node7["TodayPage"]
    node8["EntryDetailPage"]
    node9["EntryFormPage"]
    node10["OwnFoodFormPage"]
    node11["NutritionPage"]
    node12["AiOnboardingPage"]
    node13["ManualOnboardingPage"]
    node14["OnboardingEntryPage"]
    node15["PrivacyPage"]
    node16["ProfilePage"]
    node17["StatsPage"]
    node18["WorkoutDayPage"]
    node19["WorkoutPlanPage"]
    node20["WorkoutsPage"]
    node21["AccountPage"]
    node22["AppShell"]
    node23["AuthGate"]
    node24["EvaluationGuidePage"]
    node25["ProductShell"]
    node26["StartupPage"]
    node1 -->|"referencia widget"| node0
    node1 -->|"referencia widget"| node3
    node1 -->|"referencia widget"| node5
    node1 -->|"referencia widget"| node15
    node1 -->|"referencia widget"| node23
    node3 -->|"referencia widget"| node2
    node5 -->|"referencia widget"| node4
    node6 -->|"referencia widget"| node1
    node6 -->|"referencia widget"| node18
    node8 -->|"referencia widget"| node9
    node9 -->|"referencia widget"| node10
    node10 -->|"referencia widget"| node9
    node11 -->|"referencia widget"| node5
    node11 -->|"referencia widget"| node8
    node11 -->|"referencia widget"| node9
    node11 -->|"referencia widget"| node10
    node12 -->|"referencia widget"| node1
    node12 -->|"referencia widget"| node23
    node13 -->|"referencia widget"| node1
    node13 -->|"referencia widget"| node23
    node14 -->|"referencia widget"| node1
    node14 -->|"referencia widget"| node12
    node14 -->|"referencia widget"| node13
    node16 -->|"referencia widget"| node1
    node17 -->|"referencia widget"| node1
    node17 -->|"referencia widget"| node14
    node18 -->|"referencia widget"| node1
    node19 -->|"referencia widget"| node1
    node19 -->|"referencia widget"| node18
    node20 -->|"referencia widget"| node1
    node20 -->|"referencia widget"| node14
    node20 -->|"referencia widget"| node19
    node21 -->|"referencia widget"| node0
    node21 -->|"referencia widget"| node15
    node22 -->|"referencia widget"| node6
    node22 -->|"referencia widget"| node16
    node22 -->|"referencia widget"| node17
    node22 -->|"referencia widget"| node20
    node23 -->|"referencia widget"| node1
    node23 -->|"referencia widget"| node25
    node23 -->|"referencia widget"| node26
    node24 -->|"referencia widget"| node3
    node24 -->|"referencia widget"| node5
    node25 -->|"referencia widget"| node3
    node25 -->|"referencia widget"| node11
    node25 -->|"referencia widget"| node21
```

| Tela/widget | Localização |
| --- | --- |
| AppearancePage | [lib/core/theme/appearance_page.dart:5](../../../lib/core/theme/appearance_page.dart) |
| AuthPage | [lib/features/auth/presentation/pages/auth_page.dart:13](../../../lib/features/auth/presentation/pages/auth_page.dart) |
| CatalogDetailPage | [lib/features/catalog/presentation/catalog_detail_page.dart:65](../../../lib/features/catalog/presentation/catalog_detail_page.dart) |
| CatalogPage | [lib/features/catalog/presentation/catalog_page.dart:12](../../../lib/features/catalog/presentation/catalog_page.dart) |
| FoodDetailPage | [lib/features/food_reference/presentation/food_detail_page.dart:7](../../../lib/features/food_reference/presentation/food_detail_page.dart) |
| FoodPage | [lib/features/food_reference/presentation/food_page.dart:11](../../../lib/features/food_reference/presentation/food_page.dart) |
| HomePage | [lib/features/home/presentation/pages/home_page.dart:10](../../../lib/features/home/presentation/pages/home_page.dart) |
| TodayPage | [lib/features/home/presentation/pages/today_page.dart:9](../../../lib/features/home/presentation/pages/today_page.dart) |
| EntryDetailPage | [lib/features/nutrition/presentation/entry_detail_page.dart:9](../../../lib/features/nutrition/presentation/entry_detail_page.dart) |
| EntryFormPage | [lib/features/nutrition/presentation/nutrition_forms.dart:34](../../../lib/features/nutrition/presentation/nutrition_forms.dart) |
| OwnFoodFormPage | [lib/features/nutrition/presentation/nutrition_forms.dart:400](../../../lib/features/nutrition/presentation/nutrition_forms.dart) |
| NutritionPage | [lib/features/nutrition/presentation/nutrition_page.dart:13](../../../lib/features/nutrition/presentation/nutrition_page.dart) |
| AiOnboardingPage | [lib/features/onboarding/presentation/pages/ai_onboarding_page.dart:10](../../../lib/features/onboarding/presentation/pages/ai_onboarding_page.dart) |
| ManualOnboardingPage | [lib/features/onboarding/presentation/pages/manual_onboarding_page.dart:10](../../../lib/features/onboarding/presentation/pages/manual_onboarding_page.dart) |
| OnboardingEntryPage | [lib/features/onboarding/presentation/pages/onboarding_entry_page.dart:9](../../../lib/features/onboarding/presentation/pages/onboarding_entry_page.dart) |
| PrivacyPage | [lib/features/privacy/presentation/privacy_page.dart:8](../../../lib/features/privacy/presentation/privacy_page.dart) |
| ProfilePage | [lib/features/profile/presentation/pages/profile_page.dart:9](../../../lib/features/profile/presentation/pages/profile_page.dart) |
| StatsPage | [lib/features/stats/presentation/pages/stats_page.dart:10](../../../lib/features/stats/presentation/pages/stats_page.dart) |
| WorkoutDayPage | [lib/features/workouts/presentation/pages/workout_day_page.dart:9](../../../lib/features/workouts/presentation/pages/workout_day_page.dart) |
| WorkoutPlanPage | [lib/features/workouts/presentation/pages/workout_plan_page.dart:10](../../../lib/features/workouts/presentation/pages/workout_plan_page.dart) |
| WorkoutsPage | [lib/features/workouts/presentation/pages/workouts_page.dart:11](../../../lib/features/workouts/presentation/pages/workouts_page.dart) |
| AccountPage | [lib/shared/widgets/account_page.dart:11](../../../lib/shared/widgets/account_page.dart) |
| AppShell | [lib/shared/widgets/app_shell.dart:9](../../../lib/shared/widgets/app_shell.dart) |
| AuthGate | [lib/shared/widgets/auth_gate.dart:10](../../../lib/shared/widgets/auth_gate.dart) |
| EvaluationGuidePage | [lib/shared/widgets/evaluation_guide_page.dart:10](../../../lib/shared/widgets/evaluation_guide_page.dart) |
| ProductShell | [lib/shared/widgets/product_shell.dart:17](../../../lib/shared/widgets/product_shell.dart) |
| StartupPage | [lib/shared/widgets/startup_page.dart:6](../../../lib/shared/widgets/startup_page.dart) |

## Chamadas usadas por cada feature

| Feature | Literais HTTP |
| --- | --- |
| auth | `POST /api/v1/auth/google`; `GET /api/v1/me`; `POST /api/v1/auth/logout` |
| bootstrap | `GET /mobile/bootstrap` |
| catalog | `GET /api/v1/catalog/${filters.kind}`; `GET /api/v1/catalog/filters`; `GET /api/v1/catalog/$kind/${Uri.encodeComponent(entry.id)}` |
| food_reference | `GET /api/v1/foods`; `GET /api/v1/foods/filters`; `GET /api/v1/foods/${Uri.encodeComponent(food.id)}` |
| home | `GET /mobile/home/$date` |
| onboarding | `POST /mobile/onboarding/manual-plan`; `POST /mobile/onboarding/ai-plan` |
| privacy | `GET /api/v1/privacy`; `GET /api/v1/me/export`; `POST /api/v1/me/deletion-intent`; `DELETE /api/v1/me` |
| profile | `GET /mobile/profile`; `PUT /mobile/profile/train-data` |
| stats | `GET /mobile/stats` |
| workouts | `GET /mobile/workout-plans`; `GET /mobile/workout-plans/$workoutPlanId`; `GET /mobile/workout-plans/$workoutPlanId/days/$workoutDayId`; `POST /mobile/workout-plans/$workoutPlanId/days/$workoutDayId/sessions`; `PATCH /mobile/workout-plans/$workoutPlanId/days/$workoutDayId/sessions/$sessionId` |

## Planejado: jornadas da V1

### Lote alimentar importado — V1-019

```mermaid
flowchart LR
    node0["Snapshots/recibos existentes"]
    node1["Preflight e proveniência por célula"]
    node2["Revisão específica de direitos/base/identidade"]
    node3["6369registros versionados /2excluídos"]
    node4["ImportaçãoGo idempotente noDBisolado"]
    node5["Backupnovo restaurado e tabelas iguais"]
    node6["Gate pendente: autorização/API/Flutteralimentar"]
    node0 -->|"implementado e validado"| node1
    node1 -->|"implementado e validado"| node2
    node2 -->|"implementado e validado"| node3
    node3 -->|"implementado e validado"| node4
    node4 -->|"implementado e validado"| node5
    node5 -->|"implementado e validado"| node6
```
### Consulta real entregue — V1-014

```mermaid
flowchart LR
    node0["Entrada sem login ou conta conectada"]
    node1["Biblioteca:73movimentos /0programas"]
    node2["Busca e filtros da fonte"]
    node3["GET paginado: direitos/revisão/retirada"]
    node4["Detalhe da versão: autoria e licença"]
    node5["Requisitos desconhecidos e prática indisponível"]
    node6["Voltar / recarregar sem gerar treino"]
    node0 -->|"implementado e validado"| node1
    node1 -->|"implementado e validado"| node2
    node2 -->|"implementado e validado"| node3
    node3 -->|"implementado e validado"| node4
    node4 -->|"implementado e validado"| node5
    node5 -->|"implementado e validado"| node6
```
### Jornada principal planejada

```mermaid
flowchart LR
    node0["Entrar"]
    node1["Contexto mínimo"]
    node2["Biblioteca humana"]
    node3["Detalhe + origem + requisitos"]
    node4["Selecionar versão"]
    node5["Sessão / consulta permitida"]
    node6["Registrar realizado"]
    node7["Hoje / histórico"]
    node0 -->|"próximo estado proposto"| node1
    node1 -->|"próximo estado proposto"| node2
    node2 -->|"próximo estado proposto"| node3
    node3 -->|"próximo estado proposto"| node4
    node4 -->|"próximo estado proposto"| node5
    node5 -->|"próximo estado proposto"| node6
    node6 -->|"próximo estado proposto"| node7
```
### Alimentação planejada

```mermaid
flowchart LR
    node0["Hoje"]
    node1["Alimentação"]
    node2["Buscar fonte real"]
    node3["Confirmar preparo e quantidade"]
    node4["Registrar consumo"]
    node5["Consultar / editar histórico"]
    node0 -->|"próximo estado proposto"| node1
    node1 -->|"próximo estado proposto"| node2
    node2 -->|"próximo estado proposto"| node3
    node3 -->|"próximo estado proposto"| node4
    node4 -->|"próximo estado proposto"| node5
```
### Conteúdo sem cobertura

```mermaid
flowchart LR
    node0["Detalhe"]
    node1["Requisito ou licença pendente"]
    node2["Motivo explícito"]
    node3["Consultar referência quando permitido / voltar"]
    node0 -->|"próximo estado proposto"| node1
    node1 -->|"próximo estado proposto"| node2
    node2 -->|"próximo estado proposto"| node3
```

[Voltar ao mapa](../README.md) · [Responsabilidade de cada tela](../fluxos.md)
