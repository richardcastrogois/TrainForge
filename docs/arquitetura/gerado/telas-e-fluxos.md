# Telas e fluxos

> Gerado de código e registros versionados por `tools/gerar_documentacao.py`. Não editar este arquivo à mão. Revisão das entradas: `c4ffb705d2d21912`.

## Atual: referências entre widgets

Construtor referenciado é evidência estática. Condições, botão voltar, clique e transição real não foram executados pelo gerador.

```mermaid
flowchart LR
    node0["AuthPage"]
    node1["CatalogDetailPage"]
    node2["CatalogPage"]
    node3["HomePage"]
    node4["AiOnboardingPage"]
    node5["ManualOnboardingPage"]
    node6["OnboardingEntryPage"]
    node7["ProfilePage"]
    node8["StatsPage"]
    node9["WorkoutDayPage"]
    node10["WorkoutPlanPage"]
    node11["WorkoutsPage"]
    node12["AppShell"]
    node13["AuthGate"]
    node0 -->|"referencia widget"| node2
    node0 -->|"referencia widget"| node13
    node2 -->|"referencia widget"| node1
    node3 -->|"referencia widget"| node0
    node3 -->|"referencia widget"| node9
    node4 -->|"referencia widget"| node0
    node4 -->|"referencia widget"| node13
    node5 -->|"referencia widget"| node0
    node5 -->|"referencia widget"| node13
    node6 -->|"referencia widget"| node0
    node6 -->|"referencia widget"| node4
    node6 -->|"referencia widget"| node5
    node7 -->|"referencia widget"| node0
    node8 -->|"referencia widget"| node0
    node8 -->|"referencia widget"| node6
    node9 -->|"referencia widget"| node0
    node10 -->|"referencia widget"| node0
    node10 -->|"referencia widget"| node9
    node11 -->|"referencia widget"| node0
    node11 -->|"referencia widget"| node6
    node11 -->|"referencia widget"| node10
    node12 -->|"referencia widget"| node3
    node12 -->|"referencia widget"| node7
    node12 -->|"referencia widget"| node8
    node12 -->|"referencia widget"| node11
    node13 -->|"referencia widget"| node0
    node13 -->|"referencia widget"| node2
```

| Tela/widget | Localização |
| --- | --- |
| AuthPage | [lib/features/auth/presentation/pages/auth_page.dart:6](../../../lib/features/auth/presentation/pages/auth_page.dart) |
| CatalogDetailPage | [lib/features/catalog/presentation/catalog_detail_page.dart:62](../../../lib/features/catalog/presentation/catalog_detail_page.dart) |
| CatalogPage | [lib/features/catalog/presentation/catalog_page.dart:7](../../../lib/features/catalog/presentation/catalog_page.dart) |
| HomePage | [lib/features/home/presentation/pages/home_page.dart:10](../../../lib/features/home/presentation/pages/home_page.dart) |
| AiOnboardingPage | [lib/features/onboarding/presentation/pages/ai_onboarding_page.dart:10](../../../lib/features/onboarding/presentation/pages/ai_onboarding_page.dart) |
| ManualOnboardingPage | [lib/features/onboarding/presentation/pages/manual_onboarding_page.dart:10](../../../lib/features/onboarding/presentation/pages/manual_onboarding_page.dart) |
| OnboardingEntryPage | [lib/features/onboarding/presentation/pages/onboarding_entry_page.dart:9](../../../lib/features/onboarding/presentation/pages/onboarding_entry_page.dart) |
| ProfilePage | [lib/features/profile/presentation/pages/profile_page.dart:9](../../../lib/features/profile/presentation/pages/profile_page.dart) |
| StatsPage | [lib/features/stats/presentation/pages/stats_page.dart:10](../../../lib/features/stats/presentation/pages/stats_page.dart) |
| WorkoutDayPage | [lib/features/workouts/presentation/pages/workout_day_page.dart:9](../../../lib/features/workouts/presentation/pages/workout_day_page.dart) |
| WorkoutPlanPage | [lib/features/workouts/presentation/pages/workout_plan_page.dart:10](../../../lib/features/workouts/presentation/pages/workout_plan_page.dart) |
| WorkoutsPage | [lib/features/workouts/presentation/pages/workouts_page.dart:11](../../../lib/features/workouts/presentation/pages/workouts_page.dart) |
| AppShell | [lib/shared/widgets/app_shell.dart:9](../../../lib/shared/widgets/app_shell.dart) |
| AuthGate | [lib/shared/widgets/auth_gate.dart:7](../../../lib/shared/widgets/auth_gate.dart) |

## Chamadas usadas por cada feature

| Feature | Literais HTTP |
| --- | --- |
| auth | `POST /api/v1/auth/google`; `GET /api/v1/me`; `POST /api/v1/auth/logout` |
| bootstrap | `GET /mobile/bootstrap` |
| catalog | `GET /api/v1/catalog/${filters.kind}`; `GET /api/v1/catalog/filters`; `GET /api/v1/catalog/$kind/${Uri.encodeComponent(entry.id)}` |
| home | `GET /mobile/home/$date` |
| onboarding | `POST /mobile/onboarding/manual-plan`; `POST /mobile/onboarding/ai-plan` |
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
