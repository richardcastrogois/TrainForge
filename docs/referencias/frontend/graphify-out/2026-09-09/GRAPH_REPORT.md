# Graph Report - frontend  (2026-09-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 298 nodes · 424 edges · 19 communities (14 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `11407b3c`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- dependencies
- [dayId]/page.tsx
- compilerOptions
- getProtectedBootstrap
- cn
- devDependencies
- components.json
- form.tsx
- stats/page.tsx
- bottom-nav.tsx
- skeleton.tsx
- app/layout.tsx
- package.json
- fetch.ts
- chrome-devtools
- eslint.config.mjs
- next.config.ts
- postcss.config.mjs

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
- `Button()` --calls--> `cn()`  [EXTRACTED]
  components/ui/button.tsx → lib/utils.ts
- `Spinner()` --calls--> `cn()`  [EXTRACTED]
  components/ui/spinner.tsx → lib/utils.ts
- `Skeleton()` --calls--> `cn()`  [EXTRACTED]
  components/ui/skeleton.tsx → lib/utils.ts
- `AvatarBadge()` --calls--> `cn()`  [EXTRACTED]
  components/ui/avatar.tsx → lib/utils.ts
- `AvatarGroup()` --calls--> `cn()`  [EXTRACTED]
  components/ui/avatar.tsx → lib/utils.ts

## Import Cycles
- None detected.

## Communities (19 total, 5 thin omitted)

### Community 0 - "dependencies"
Cohesion: 0.05
Nodes (41): ai, @ai-sdk/react, better-auth, class-variance-authority, clsx, dayjs, dotenv, @hookform/resolvers (+33 more)

### Community 1 - "[dayId]/page.tsx"
Cohesion: 0.13
Nodes (17): SignInWithGoogle(), authClient, completeWorkoutAction(), startWorkoutAction(), BackButton(), CompleteWorkoutButton(), CompleteWorkoutButtonProps, ExerciseCard() (+9 more)

### Community 2 - "compilerOptions"
Cohesion: 0.07
Nodes (28): dom, dom.iterable, esnext, **/*.mts, .next/dev/types/**/*.ts, next-env.d.ts, .next/types/**/*.ts, node_modules (+20 more)

### Community 3 - "getProtectedBootstrap"
Cohesion: 0.11
Nodes (21): ConsistencySquare(), ConsistencySquareProps, ConsistencyTracker(), ConsistencyTrackerProps, getWeekDates(), WEEKDAY_SHORT, WEEKDAY_LABELS, WorkoutDayCard() (+13 more)

### Community 4 - "cn"
Cohesion: 0.14
Nodes (20): LogoutButton(), ProfilePage(), Avatar(), AvatarBadge(), AvatarFallback(), AvatarGroup(), AvatarGroupCount(), AvatarImage() (+12 more)

### Community 5 - "devDependencies"
Cohesion: 0.08
Nodes (25): eslint, eslint-config-next, orval, devDependencies, eslint, eslint-config-next, orval, prettier (+17 more)

### Community 6 - "components.json"
Cohesion: 0.10
Nodes (19): aliases, components, hooks, lib, ui, utils, iconLibrary, registries (+11 more)

### Community 7 - "form.tsx"
Cohesion: 0.16
Nodes (16): Chat(), chatFormSchema, ChatFormValues, ChatProps, SUGGESTED_MESSAGES, FormControl(), FormDescription(), FormField() (+8 more)

### Community 8 - "stats/page.tsx"
Cohesion: 0.17
Nodes (12): StatCard(), StatCardProps, buildMonthGroups(), getMonday(), MonthGroup, StatsHeatmap(), StatsHeatmapProps, WeekData (+4 more)

### Community 9 - "bottom-nav.tsx"
Cohesion: 0.20
Nodes (11): ActivePage, BottomNav(), getActivePage(), NavItem, ChatOpenButton(), ProtectedAppContext, ProtectedAppContextValue, ProtectedAppProvider() (+3 more)

### Community 11 - "app/layout.tsx"
Cohesion: 0.25
Nodes (6): anton, geistMono, geistSans, interTight, metadata, Toaster()

### Community 12 - "package.json"
Cohesion: 0.22
Nodes (8): name, private, scripts, build, dev, lint, start, version

### Community 13 - "fetch.ts"
Cohesion: 0.47
Nodes (4): customFetch(), ExtractResponseData, getHeaders(), getUrl()

## Knowledge Gaps
- **125 isolated node(s):** `CompleteWorkoutButtonProps`, `ExerciseCardProps`, `StartWorkoutButtonProps`, `SpinnerProps`, `SkeletonProps` (+120 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `cn()` connect `cn` to `bottom-nav.tsx`, `skeleton.tsx`, `[dayId]/page.tsx`, `form.tsx`?**
  _High betweenness centrality (0.094) - this node is a cross-community bridge._
- **Why does `getProtectedBootstrap` connect `getProtectedBootstrap` to `stats/page.tsx`, `bottom-nav.tsx`, `cn`, `[dayId]/page.tsx`?**
  _High betweenness centrality (0.055) - this node is a cross-community bridge._
- **Why does `dependencies` connect `dependencies` to `package.json`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **What connects `CompleteWorkoutButtonProps`, `ExerciseCardProps`, `StartWorkoutButtonProps` to the rest of the system?**
  _125 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `dependencies` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._
- **Should `[dayId]/page.tsx` be split into smaller, more focused modules?**
  _Cohesion score 0.12903225806451613 - nodes in this community are weakly interconnected._
- **Should `compilerOptions` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._