# Graph Report - frontend  (2026-09-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 295 nodes · 422 edges · 19 communities (15 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `11407b3c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Dependencias de runtime
- Componentes e estilos
- Compilacao TypeScript
- Bootstrap e contexto
- Ferramentas de desenvolvimento
- Pagina do treino
- Configuracao de componentes
- Controles de formulario
- Pagina de estatisticas
- Navegacao inferior
- Estados de carregamento
- Entrada com Google
- Estrutura da aplicacao
- Scripts do projeto
- Cliente HTTP web
- Regras de lint
- Configuracao do Next
- Pipeline de CSS
- Geracao do cliente HTTP

## God Nodes (most connected - your core abstractions)
1. `cn()` - 35 edges
2. `compilerOptions` - 16 edges
3. `getProtectedBootstrap` - 15 edges
4. `Button()` - 11 edges
5. `Skeleton()` - 7 edges
6. `include` - 7 edges
7. `aliases` - 6 edges
8. `tailwind` - 6 edges
9. `Spinner()` - 5 edges
10. `useFormField()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `AvatarBadge()` --calls--> `cn()`  [EXTRACTED]
  components/ui/avatar.tsx → lib/utils.ts
- `AvatarGroup()` --calls--> `cn()`  [EXTRACTED]
  components/ui/avatar.tsx → lib/utils.ts
- `AvatarGroupCount()` --calls--> `cn()`  [EXTRACTED]
  components/ui/avatar.tsx → lib/utils.ts
- `Card()` --calls--> `cn()`  [EXTRACTED]
  components/ui/card.tsx → lib/utils.ts
- `CardAction()` --calls--> `cn()`  [EXTRACTED]
  components/ui/card.tsx → lib/utils.ts

## Import Cycles
- None detected.

## Communities (19 total, 4 thin omitted)

### Community 0 - "Dependencias de runtime"
Cohesion: 0.05
Nodes (41): ai, @ai-sdk/react, better-auth, class-variance-authority, clsx, dayjs, dotenv, @hookform/resolvers (+33 more)

### Community 1 - "Componentes e estilos"
Cohesion: 0.12
Nodes (22): LogoutButton(), ProfilePage(), Avatar(), AvatarBadge(), AvatarFallback(), AvatarGroup(), AvatarGroupCount(), AvatarImage() (+14 more)

### Community 2 - "Compilacao TypeScript"
Cohesion: 0.07
Nodes (28): dom, dom.iterable, esnext, **/*.mts, .next/dev/types/**/*.ts, next-env.d.ts, .next/types/**/*.ts, node_modules (+20 more)

### Community 3 - "Bootstrap e contexto"
Cohesion: 0.11
Nodes (21): ConsistencySquare(), ConsistencySquareProps, ConsistencyTracker(), ConsistencyTrackerProps, getWeekDates(), WEEKDAY_SHORT, WEEKDAY_LABELS, WorkoutDayCard() (+13 more)

### Community 4 - "Ferramentas de desenvolvimento"
Cohesion: 0.08
Nodes (25): eslint, eslint-config-next, orval, devDependencies, eslint, eslint-config-next, orval, prettier (+17 more)

### Community 5 - "Pagina do treino"
Cohesion: 0.20
Nodes (13): completeWorkoutAction(), startWorkoutAction(), BackButton(), CompleteWorkoutButton(), CompleteWorkoutButtonProps, ExerciseCard(), ExerciseCardProps, StartWorkoutButton() (+5 more)

### Community 6 - "Configuracao de componentes"
Cohesion: 0.10
Nodes (19): aliases, components, hooks, lib, ui, utils, iconLibrary, registries (+11 more)

### Community 7 - "Controles de formulario"
Cohesion: 0.17
Nodes (15): chatFormSchema, ChatFormValues, ChatProps, SUGGESTED_MESSAGES, FormControl(), FormDescription(), FormField(), FormFieldContext (+7 more)

### Community 8 - "Pagina de estatisticas"
Cohesion: 0.17
Nodes (12): StatCard(), StatCardProps, buildMonthGroups(), getMonday(), MonthGroup, StatsHeatmap(), StatsHeatmapProps, WeekData (+4 more)

### Community 9 - "Navegacao inferior"
Cohesion: 0.20
Nodes (11): ActivePage, BottomNav(), getActivePage(), NavItem, ChatOpenButton(), ProtectedAppContext, ProtectedAppContextValue, ProtectedAppProvider() (+3 more)

### Community 11 - "Entrada com Google"
Cohesion: 0.36
Nodes (3): SignInWithGoogle(), Chat(), authClient

### Community 12 - "Estrutura da aplicacao"
Cohesion: 0.25
Nodes (6): anton, geistMono, geistSans, interTight, metadata, Toaster()

### Community 13 - "Scripts do projeto"
Cohesion: 0.22
Nodes (8): name, private, scripts, build, dev, lint, start, version

### Community 14 - "Cliente HTTP web"
Cohesion: 0.47
Nodes (4): customFetch(), ExtractResponseData, getHeaders(), getUrl()

## Knowledge Gaps
- **124 isolated node(s):** `SpinnerProps`, `SkeletonProps`, `ExtractResponseData`, `ConsistencySquareProps`, `ConsistencyTrackerProps` (+119 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `cn()` connect `cn` to `bottom-nav.tsx`, `skeleton.tsx`, `[dayId]/page.tsx`, `form.tsx`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `getProtectedBootstrap` connect `getProtectedBootstrap` to `stats/page.tsx`, `bottom-nav.tsx`, `[dayId]/page.tsx`, `cn`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `dependencies` connect `dependencies` to `package.json`?**
  _High betweenness centrality (0.049) - this node is a cross-community bridge._
- **What connects `SpinnerProps`, `SkeletonProps`, `ExtractResponseData` to the rest of the system?**
  _124 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `dependencies` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._
- **Should `cn` be split into smaller, more focused modules?**
  _Cohesion score 0.12473118279569892 - nodes in this community are weakly interconnected._
- **Should `compilerOptions` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._