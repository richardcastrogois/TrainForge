# Graph Report - api  (2026-09-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 193 nodes · 495 edges · 7 communities
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 43 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `523f6d96`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Servidor e rotas
- Rotas de treino mobile
- Geracao de planos
- Erros de dominio
- Autenticacao mobile
- Criacao transacional de planos
- Conexao ao banco

## God Nodes (most connected - your core abstractions)
1. `getMobileUserFromAuthorizationHeader()` - 16 edges
2. `prisma` - 14 edges
3. `NotFoundError` - 13 edges
4. `buildManualWorkoutPlan()` - 11 edges
5. `ErrorSchema` - 10 edges
6. `mobileWorkoutPlanRoutes()` - 9 edges
7. `InvalidDateRangeError` - 8 edges
8. `mobileAuthRoutes()` - 8 edges
9. `workoutPlanRoutes()` - 8 edges
10. `auth` - 8 edges

## Surprising Connections (you probably didn't know these)
- `mobileBootstrapRoutes()` --calls--> `getMobileUserFromAuthorizationHeader()`  [EXTRACTED]
  routes/mobile-bootstrap.ts → lib/get-mobile-user.ts
- `mobileStatsRoutes()` --calls--> `getMobileUserFromAuthorizationHeader()`  [EXTRACTED]
  routes/mobile-stats.ts → lib/get-mobile-user.ts
- `mobileOnboardingRoutes()` --calls--> `buildManualWorkoutPlan()`  [EXTRACTED]
  routes/mobile-onboarding.ts → lib/manual-plan-builder.ts
- `mobileOnboardingRoutes()` --calls--> `getMobileUserFromAuthorizationHeader()`  [EXTRACTED]
  routes/mobile-onboarding.ts → lib/get-mobile-user.ts
- `mobileProfileRoutes()` --calls--> `getMobileUserFromAuthorizationHeader()`  [EXTRACTED]
  routes/mobile-profile.ts → lib/get-mobile-user.ts

## Import Cycles
- None detected.

## Communities (7 total, 0 thin omitted)

### Community 0 - "Servidor e rotas"
Cohesion: 0.10
Nodes (28): InvalidDateRangeError, NotFoundError, allowedOrigins, app, envToLogger, auth, trustedOrigins, calculateWorkoutStreak() (+20 more)

### Community 1 - "Rotas de treino mobile"
Cohesion: 0.09
Nodes (30): InvalidWorkoutPlanError, InvalidWorkoutSessionCompletionError, SessionAlreadyStartedError, WorkoutDayIsRestError, WorkoutPlanNotActiveError, WorkoutSessionAlreadyCompletedError, BodyFatPercentageSchema, BootstrapSchema (+22 more)

### Community 2 - "Geracao de planos"
Cohesion: 0.10
Nodes (26): ALL_WEEK_DAYS, buildManualWorkoutPlan(), getCoverImageUrl(), getMaxExercises(), getPlanName(), getReps(), getRestTime(), getSets() (+18 more)

### Community 3 - "Erros de dominio"
Cohesion: 0.14
Nodes (15): InvalidMobileAuthTokenError, InvalidUserTrainDataError, meRoutes(), mobileOnboardingRoutes(), mobileProfileRoutes(), UpsertUserTrainDataBodySchema, UpsertUserTrainDataSchema, UserTrainDataSchema (+7 more)

### Community 4 - "Autenticacao mobile"
Cohesion: 0.15
Nodes (19): env, envSchema, parsedEnv, trustedOriginsList, getMobileUserFromAuthorizationHeader(), allowedAudiences, generateMobileRefreshToken(), googleClient (+11 more)

### Community 5 - "Criacao transacional de planos"
Cohesion: 0.16
Nodes (13): aiRoutes(), mobileWorkoutPlanRoutes(), workoutPlanRoutes(), areWorkoutPlansEquivalent(), assertValidWorkoutPlan(), CreateWorkoutPlan, InputDto, normalizeWorkoutDays() (+5 more)

### Community 6 - "Conexao ao banco"
Cohesion: 0.22
Nodes (7): adapter, globalForPrisma, prisma, InputDto, OutputDto, InputDto, OutputDto

## Knowledge Gaps
- **60 isolated node(s):** `CalculateWorkoutStreakInput`, `WorkoutDayForStreak`, `InputDto`, `OutputDto`, `InputDto` (+55 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `getMobileUserFromAuthorizationHeader()` connect `getMobileUserFromAuthorizationHeader` to `index.ts`, `mobile-workout-plans.ts`, `mobile-onboarding.ts`, `errors/index.ts`, `CreateWorkoutPlan.ts`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `buildManualWorkoutPlan()` connect `mobile-onboarding.ts` to `errors/index.ts`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Why does `prisma` connect `db.ts` to `index.ts`, `mobile-workout-plans.ts`, `errors/index.ts`, `getMobileUserFromAuthorizationHeader`, `CreateWorkoutPlan.ts`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **What connects `CalculateWorkoutStreakInput`, `WorkoutDayForStreak`, `InputDto` to the rest of the system?**
  _60 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `index.ts` be split into smaller, more focused modules?**
  _Cohesion score 0.09523809523809523 - nodes in this community are weakly interconnected._
- **Should `mobile-workout-plans.ts` be split into smaller, more focused modules?**
  _Cohesion score 0.08710801393728224 - nodes in this community are weakly interconnected._
- **Should `mobile-onboarding.ts` be split into smaller, more focused modules?**
  _Cohesion score 0.10052910052910052 - nodes in this community are weakly interconnected._