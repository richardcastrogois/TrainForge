# Graph Report - trainforge  (2026-09-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 470 nodes · 607 edges · 21 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Cliente HTTP e modelos
- Detalhe do plano
- Onboarding manual
- Interface e widgets
- Perfil do utilizador
- Estatisticas do utilizador
- Onboarding com IA
- Dados de perfil
- Modelo do plano
- Repositorio de autenticacao
- Entrada autenticada
- Tipos e valores opcionais
- Lista de planos
- API de treinos
- Modelo do dia
- Execucao do treino
- Resumo do plano
- Armazenamento de sessao
- Resposta de sessao
- Configuracao do Dio
- Configuracao de ambiente

## God Nodes (most connected - your core abstractions)
1. `AuthRepository` - 9 edges
2. `TrainData` - 5 edges
3. `WorkoutsRepository` - 4 edges
4. `AuthPage` - 3 edges
5. `_AuthPageState` - 3 edges
6. `HomePage` - 3 edges
7. `_HomePageState` - 3 edges
8. `ManualOnboardingPage` - 3 edges
9. `_ManualOnboardingPageState` - 3 edges
10. `WorkoutPlanPage` - 3 edges

## Surprising Connections (you probably didn't know these)
- `_AiOnboardingPageState` --inherits--> `State`  [EXTRACTED]
  features/onboarding/presentation/pages/ai_onboarding_page.dart → None  _Bridges community 1 → community 6_
- `_ProfilePageState` --inherits--> `State`  [EXTRACTED]
  features/profile/presentation/pages/profile_page.dart → None  _Bridges community 1 → community 4_
- `_StatsPageState` --inherits--> `State`  [EXTRACTED]
  features/stats/presentation/pages/stats_page.dart → None  _Bridges community 1 → community 5_
- `_WorkoutDayPageState` --inherits--> `State`  [EXTRACTED]
  features/workouts/presentation/pages/workout_day_page.dart → None  _Bridges community 1 → community 15_
- `_WorkoutsPageState` --inherits--> `State`  [EXTRACTED]
  features/workouts/presentation/pages/workouts_page.dart → None  _Bridges community 1 → community 12_

## Import Cycles
- None detected.

## Communities (21 total, 0 thin omitted)

### Community 0 - "Cliente HTTP e modelos"
Cohesion: 0.06
Nodes (33): Dio, ../domain/auth_user.dart, ../domain/home_summary.dart, AuthApi, dio, getMe, loginWithGoogleIdToken, dio (+25 more)

### Community 1 - "Detalhe do plano"
Cohesion: 0.07
Nodes (33): AuthPage, _AuthPageState, authRepository, build, createState, errorMessage, HomePage, _HomePageState (+25 more)

### Community 2 - "Onboarding manual"
Cohesion: 0.06
Nodes (30): OnboardingApi, api, createAiPlan, createManualPlan, OnboardingRepository, ageController, authRepository, bodyFatController (+22 more)

### Community 3 - "Interface e widgets"
Cohesion: 0.07
Nodes (26): build, app.dart, TrainForgeApp, core/log/app_logger.dart, build, createState, errorMessage, handleLogin (+18 more)

### Community 4 - "Perfil do utilizador"
Cohesion: 0.07
Nodes (28): api, getProfile, ProfileRepository, upsertTrainData, ageController, authRepository, bodyFatController, build (+20 more)

### Community 5 - "Estatisticas do utilizador"
Cohesion: 0.07
Nodes (27): completedWorkoutsCount, conclusionRate, consistency, DailyConsistency, date, fromJson, StatsData, totalTimeInSeconds (+19 more)

### Community 6 - "Onboarding com IA"
Cohesion: 0.07
Nodes (27): ageController, AiOnboardingPage, _AiOnboardingPageState, authRepository, bodyFatController, build, _buildNumberField, _buildSavingOverlay (+19 more)

### Community 7 - "Dados de perfil"
Cohesion: 0.08
Nodes (25): double get, BootstrapData, fromJson, hasActivePlan, homeData, needsOnboarding, trainData, user (+17 more)

### Community 8 - "Modelo do plano"
Cohesion: 0.08
Nodes (23): coverImageUrl, estimatedDurationInSeconds, exercisesCount, fromJson, id, isRest, name, weekDay (+15 more)

### Community 9 - "Repositorio de autenticacao"
Cohesion: 0.09
Nodes (20): auth_api.dart, auth_storage.dart, AppLogger, error, info, warning, dart:developer, _api (+12 more)

### Community 10 - "Entrada autenticada"
Cohesion: 0.10
Nodes (20): BootstrapApi, api, BootstrapRepository, getBootstrap, package:trainforge/features/bootstrap/data/bootstrap_api.dart, package:trainforge/features/bootstrap/data/bootstrap_repository.dart, package:trainforge/features/bootstrap/domain/bootstrap_data.dart, package:trainforge/shared/widgets/app_shell.dart (+12 more)

### Community 11 - "Tipos e valores opcionais"
Cohesion: 0.10
Nodes (19): AuthUser, email, fromJson, id, image, name, token, activeWorkoutPlanId (+11 more)

### Community 12 - "Lista de planos"
Cohesion: 0.10
Nodes (20): openTodayWorkout, build, _openOnboarding, build, authRepository, build, createState, errorMessage (+12 more)

### Community 13 - "API de treinos"
Cohesion: 0.11
Nodes (19): dio, fetchWorkoutDayDetail, fetchWorkoutPlanDetail, fetchWorkoutPlans, finishWorkoutSession, startWorkoutSession, WorkoutsApi, api (+11 more)

### Community 14 - "Modelo do dia"
Cohesion: 0.10
Nodes (19): completedAt, coverImageUrl, estimatedDurationInSeconds, exercises, fromJson, id, isRest, name (+11 more)

### Community 15 - "Execucao do treino"
Cohesion: 0.11
Nodes (18): actionLoading, authRepository, build, buildActionSection, createState, errorMessage, formatDuration, handleFinishWorkout (+10 more)

### Community 16 - "Resumo do plano"
Cohesion: 0.11
Nodes (17): coverImageUrl, estimatedDurationInSeconds, exercises, fromJson, id, isActive, isRest, name (+9 more)

### Community 17 - "Armazenamento de sessao"
Cohesion: 0.22
Nodes (8): AuthStorage, clearToken, getToken, saveToken, _storage, _tokenKey, package:flutter_secure_storage/flutter_secure_storage.dart, static const

### Community 18 - "Resposta de sessao"
Cohesion: 0.25
Nodes (7): completedAt, FinishWorkoutSessionResult, fromJson, id, startedAt, StartWorkoutSessionResult, userWorkoutSessionId

### Community 19 - "Configuracao do Dio"
Cohesion: 0.29
Nodes (6): AppDio, instance, package:trainforge/core/config/app_config.dart, package:trainforge/core/log/app_logger.dart, package:trainforge/features/auth/data/auth_storage.dart, static final Dio

### Community 20 - "Configuracao de ambiente"
Cohesion: 0.50
Nodes (3): apiBaseUrl, AppConfig, static const String

## Knowledge Gaps
- **315 isolated node(s):** `AuthApi`, `dio`, `getMe`, `loginWithGoogleIdToken`, `dio` (+310 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AuthRepository` connect `auth_repository.dart` to `workout_plan_page.dart`, `manual_onboarding_page.dart`, `profile_page.dart`, `stats_page.dart`, `ai_onboarding_page.dart`, `auth_gate.dart`, `workouts_page.dart`, `workout_day_page.dart`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Why does `TrainData` connect `profile_data.dart` to `manual_onboarding_page.dart`, `package:flutter/material.dart`, `ai_onboarding_page.dart`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `OnboardingRepository` connect `manual_onboarding_page.dart` to `ai_onboarding_page.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `AuthApi`, `dio`, `getMe` to the rest of the system?**
  _315 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `package:dio/dio.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06219512195121951 - nodes in this community are weakly interconnected._
- **Should `workout_plan_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06722689075630252 - nodes in this community are weakly interconnected._
- **Should `manual_onboarding_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0625 - nodes in this community are weakly interconnected._