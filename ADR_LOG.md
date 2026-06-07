# RADHA Mobile — Architecture Decision Log

> **Purpose.** This is the canonical log of foundational technical decisions for the RADHA Flutter app (`apps/mobile/`). Every ADR represents a choice that, once made, locks several phases. ADRs are immutable: when an entry is wrong, write a superseding ADR rather than editing history.
>
> **Format.** Michael Nygard style, expanded with reversal difficulty and validation criteria. Each ADR is owned by the role that signs the corresponding phase Sign-off Gate.
>
> **Cross-references.** Every FE-NN phase doc lists `Affected ADRs:` in its prerequisites. `FRONTEND_DESIGN_SYSTEM.md` and `FRONTEND_VERIFICATION_SYSTEM.md` both reference the ADRs that constrain them.

---

## Index

| ADR | Title | Status | Reversal |
|---|---|---|---|
| ADR-001 | 40 phases, not 38 (deviation from system-prompt template) | Accepted | High |
| ADR-002 | Riverpod 2.5 + `riverpod_generator` for state | Accepted | High |
| ADR-003 | GoRouter 14 for routing and deep links | Accepted | Medium |
| ADR-004 | Drift 2.18 for local persistence | Accepted | Medium |
| ADR-005 | Dio 5 for HTTP transport with interceptor chain | Accepted | Low |
| ADR-006 | `flex_color_scheme` 7.3 for Material 3 theming | Accepted | Low |
| ADR-007 | `envied` for compile-time environment injection | Accepted | Low |
| ADR-008 | Sentry (`sentry_flutter`) for crash and trace observability | Accepted | Medium |
| ADR-009 | Patrol for E2E on device, `golden_toolkit` for visual regression | Accepted | Low |
| ADR-010 | Feature-first folder layout under `lib/features/` | Accepted | High |
| ADR-011 | `apps/mobile/` inside the existing pnpm monorepo | Accepted | High |
| ADR-012 | Three Android flavors + xcconfig iOS configurations | Accepted | Medium |

---

## ADR-001: 40 phases, not 38

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Engineering Manager, Product Owner
**Affected phases**: FE-01..FE-40 (the entire roadmap)

### Context
The system-prompt scaffolding template that seeded the planning effort prescribed a 38-phase frontend execution plan. The master roadmap (`FRONTEND_PHASES/00_MASTER_FRONTEND_ROADMAP.md`) was already authored with 40 phases organised into five eight-phase layers (Foundation, Onboarding+Auth, Consumer Core, Business+Owner, Polish+Cross-cutting). The 40-phase shape mirrors the backend roadmap (BE-01..BE-57 in eight-phase waves) and gives wave maps a clean even split for parallel team execution. Renumbering forty inbound cross-references — from `MASTER_ARCHITECTURE.md`, `BUILD_ORDER_INDEX.md`, `EXECUTION_ROADMAP.md`, `CONNECTION_MAP.md`, every `FE-NN_PHASE.md`, and the wave map — would have introduced dozens of avoidable defects.

The 38-prompt also lacked dedicated phases for four topics that the team considered non-negotiable: security hardening, runtime permissions, deep linking, and animation library hardening. Folding those into a 38-phase plan would have produced overloaded phases that violated the SOP rule of fifteen-test-procedures-per-phase staying actionable in a single sprint.

### Decision
Keep the 40-phase roadmap. Fold the missing 38-prompt topics into existing phases:

- **Security hardening** → distributed across FE-06 (TLS pinning, idempotency), FE-07 (JWT refresh, secure storage), FE-40 (R8/ProGuard, integrity, privacy manifest).
- **Permissions** → owned by FE-17 (camera, photos via `permission_handler`) with a per-screen pattern adopted in FE-09 (notifications), FE-29 (storage for photo capture).
- **Deep linking** → owned by FE-05 (GoRouter universal/app links, redirect guards) and reused in FE-21 (recall deep link), FE-31 (task deep link).
- **Animation hardening** → FE-33 (Lottie pack, reduced-motion paths, asset budget) plus FE-04 motion system foundation.

### Alternatives considered
- **Option A — Renumber to 38 phases.** Aligns with the prompt template. Rejected because every `FE-NN` reference in `FRONTEND_PHASES/`, `BACKEND_PHASES/`, `MASTER_ARCHITECTURE.md`, `EXECUTION_ROADMAP.md`, the wave map, and the backend endpoint coverage table would need a coordinated edit, and any miss creates silent drift between docs.
- **Option B — Add two phases on top of the prompt's 38, producing 40 differently structured phases.** Cleanest in a vacuum but the result would not match the master roadmap that engineering already drafted. Rejected because two parallel 40-phase plans is worse than one.
- **Option C (chosen) — Keep 40 as authored, fold prompt-only topics into existing phases, document the deviation here.** Preserves cross-doc integrity, preserves the wave map, and gives security/permissions/deep-link owners a clear home.

### Tradeoffs accepted
- Anyone reading the system-prompt-derived template will see "38" and have to consult this ADR to reconcile.
- Security and permissions are cross-cutting rather than a single phase — discipline is needed in code review to ensure they are not skipped per screen. `FRONTEND_QA_SYSTEM.md` adds explicit checklist items in the per-phase QA artifacts.

### Long-term impact
The 40-phase shape becomes the project's permanent identity. Wave map (Waves A–E) stays valid. New cross-cutting topics in v2 (e.g. AI co-pilot, Wear OS) get appended as FE-41+ rather than reshuffling.

### Reversal difficulty
**High.** Forty phase docs, three roadmap docs, the wave map, the backend coverage table, and CI badges all reference `FE-NN`. A reversal would touch ~80 files.

### Validation
- Every prompt-only topic resolves to a concrete owning phase (table above). Verified at this ADR's acceptance.
- No phase doc has more than 15 test procedures or 8 Q&A items at sign-off.
- Every BE endpoint listed in `00_MASTER_FRONTEND_ROADMAP.md` resolves to exactly one consuming phase.

---

## ADR-002: Riverpod 2.5 + `riverpod_generator` for state management

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, two senior Flutter engineers
**Affected phases**: FE-07 (primary), FE-08, FE-13, FE-15, FE-17, FE-18, FE-25, FE-31

### Context
RADHA mobile is a multi-surface app (consumer + business) with offline-first state, JWT refresh, real-time recall pushes, paginated lists, optimistic mutations on outbox, and feature-flag gating. State management is the spine. The wrong choice now will leak across forty phases.

### Decision
Adopt **Riverpod 2.5** with **`riverpod_generator`** and **`riverpod_lint`**. All providers are code-generated. Async state uses `AsyncNotifier` and `AsyncValue`. Family providers are typed via generated records. No global singletons; all dependencies are scoped through `ProviderContainer` and `ProviderScope` overrides for testing.

### Alternatives considered
- **Option A — Bloc 8 (`flutter_bloc`).** Strong opinions, mature ecosystem, good tooling. Rejected for boilerplate (event class + state class + bloc class per feature) and the stream-of-events model that does not map cleanly to async data fetches; `AsyncValue` is a better fit for paginated/cached HTTP responses.
- **Option B — `provider` (legacy).** Lightweight, official "ChangeNotifier era" tool. Rejected: the Flutter team has effectively superseded `provider` with Riverpod for greenfield apps; no compile-time safety; difficult to scope/override for tests.
- **Option C — GetX.** Single-package solution covering state + routing + DI. Rejected on three grounds: (1) global service-locator anti-pattern that hides dependencies; (2) custom router replaces the platform `Navigator`/`GoRouter` ecosystem; (3) community fragmentation and ad-hoc plugin quality are documented risks.
- **Option D — Vanilla `ValueNotifier` + `InheritedWidget`.** Rejected: each feature would reinvent caching, cancellation, and error mapping.
- **Option E (chosen) — Riverpod 2.5 + generator.** Compile-time provider safety (`riverpod_lint`), `AsyncNotifier` matches BE async semantics, override-based testing, no global state, DevTools provider inspector, and first-class `freezed` interop.

### Tradeoffs accepted
- Engineers must learn the `riverpod_generator` mental model (annotate, run `build_runner`).
- `build_runner` adds 20–40 s to local incremental builds; mitigated by `dart run build_runner watch --delete-conflicting-outputs`.
- Provider files are generated; reading a stack trace through generated code requires familiarity.

### Long-term impact
Every phase from FE-07 onward writes providers in the same shape. Tests use `ProviderContainer` overrides and never reach for `mockito` against globals. The pattern is teachable to new hires in <2 days.

### Reversal difficulty
**High.** Riverpod is intertwined with feature controllers, repositories, and route guards. A migration would rewrite roughly 70% of `lib/features/`.

### Validation
- After FE-08 closes, no `BlocProvider`, `Provider.of`, or `Get.put` exists anywhere under `lib/`.
- `riverpod_lint` runs in `mobile-ci.yml` with zero warnings.
- DevTools provider tree shows ≤ 50 providers in steady state on the Business dashboard (FE-25).

---

## ADR-003: GoRouter 14 for routing and deep links

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Mobile Architect
**Affected phases**: FE-05 (primary), FE-09, FE-12, FE-16, FE-21, FE-25, FE-31

### Context
RADHA needs deep links from FCM pushes (recall alerts, task assignments), universal/app links from the marketing site, and authentication redirect guards (anonymous → login → onboarding → segment). Twelve top-level routes and two shells (consumer, business) must coexist behind a single navigator.

### Decision
Adopt **GoRouter 14** with the typed routes builder (`go_router_builder`). Route trees live in `lib/app/router/`. Redirect guards consume Riverpod providers via `ref` exposed through `GoRouterRefreshStream`. Push payloads are mapped to `GoRoute.path` strings in a single `DeepLinkResolver`.

### Alternatives considered
- **Option A — `auto_route`.** Strong code-gen, type-safe routes, nested routing. Rejected because the Flutter Material team now ships GoRouter as the recommended router; using `auto_route` means tracking a community-led API divergence with each Flutter SDK upgrade.
- **Option B — Hand-rolled `Navigator 2.0`.** Maximum flexibility. Rejected because every team in the industry that has tried this has rebuilt 80% of GoRouter at higher cost.
- **Option C — `beamer`.** Reasonable mid-ground. Rejected: smaller ecosystem, less momentum, no compelling differentiator over GoRouter.
- **Option D (chosen) — GoRouter 14 + typed routes.** Official Material team direction, deep-link-first, declarative redirect guards, web-friendly history API for the supplementary Flutter Web build.

### Tradeoffs accepted
- Typed routes require a `build_runner` step (already running for Riverpod/freezed/Drift).
- Nested ShellRoute API surface is large; team must converge on one pattern (documented in FE-05).

### Long-term impact
Every deep link in production is a `go_router` path. Push payloads in BE-24 emit `path` and optional `params`, both stable for a year. Reversibility is medium because route call sites are hundreds in number but mechanically swappable.

### Reversal difficulty
**Medium.** A migration to `auto_route` would rewrite call sites and route definitions but not feature code.

### Validation
- All deep-link smoke tests in FE-05, FE-21, FE-31 pass.
- `flutter analyze` reports zero `Navigator.push(...)` outside of `Cupertino` back gestures.
- `go_router_builder` outputs compile clean in CI.

---

## ADR-004: Drift 2.18 for local persistence

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Backend Tech Lead (schema alignment)
**Affected phases**: FE-08 (primary), FE-17, FE-18, FE-20, FE-27, FE-28, FE-30, FE-36

### Context
RADHA is offline-first. Scans, expiry entries, GRN drafts, and outbox writes must persist between sessions and survive airplane-mode restarts. The local schema mirrors a meaningful subset of the server schema (products, scans, expiry items, sync queue) and needs reactive streams to drive UI without manual subscription plumbing.

### Decision
Adopt **Drift 2.18** (sqlite under the hood via `sqlite3_flutter_libs`). Tables are declared in Dart with `@DriftDatabase`, query results are `Stream`s, migrations are versioned in code, and DAOs live per feature.

### Alternatives considered
- **Option A — Hive.** Box-based, fast, simple. Rejected: opaque box semantics make multi-table joins awkward, no first-class reactive streams across boxes, and migrations are open-coded. Acceptable for key-value caches; insufficient as an offline DB.
- **Option B — Isar.** Modern NoSQL, fast, reactive. Rejected on environment risk: Apple Silicon native-build issues have repeatedly bitten teams (the `libisar.dylib` toolchain). RADHA cannot afford a "won't build on a new MacBook" hazard during a release.
- **Option C — `sqflite` raw.** Maximum control. Rejected for query maintenance burden: every join is hand-written, every column rename is a SQL migration plus a Dart mapper, and there are no reactive streams.
- **Option D (chosen) — Drift 2.18.** Type-safe queries, generated DAOs, reactive `Stream` results, mature migration story, mirrors backend schema, runs cleanly on Linux/macOS/Windows/Android/iOS.

### Tradeoffs accepted
- `build_runner` step required for table changes.
- App download size grows by ~1.4 MB for `sqlite3_flutter_libs`. Within FE-39 size budget (< 35 MB release APK).
- Drift's query language is Dart-shaped, not SQL — engineers used to raw SQL must adapt.

### Long-term impact
The local DB is the single source of truth for offline reads. Sync (FE-08, FE-36) writes through Drift transactions. Conflict resolution is centralised in the Drift layer.

### Reversal difficulty
**Medium.** Schema is portable to `sqflite` but DAOs and reactive call sites would need rework.

### Validation
- After FE-08, all reads from product cache, scans, and outbox flow through Drift `Stream`s.
- Schema fingerprint (`apps/mobile/.contracts.lock.json`) matches BE Drizzle schema for the offline subset.
- Cold-DB-open time on Pixel 4a < 80 ms (measured in FE-39).

---

## ADR-005: Dio 5 for HTTP transport with interceptor chain

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Backend Tech Lead (idempotency contract)
**Affected phases**: FE-06 (primary), FE-07, FE-08, FE-17, FE-29

### Context
The frontend must enforce idempotency on every state-changing call (BE-44 sync), retry with backoff on 5xx and network errors, attach a JWT and refresh on 401, log redacted payloads in dev, route correlation IDs end-to-end, send multipart photos to BE-22 OCR, and PUT large files to S3 presigned URLs with progress events. A single, composable interceptor chain is mandatory.

### Decision
Adopt **Dio 5** with a four-stage interceptor chain: `AuthInterceptor` → `IdempotencyInterceptor` → `RetryInterceptor` → `LoggingInterceptor`. Errors are mapped to a sealed `ApiFailure` union (freezed). Multipart and S3 PUT use Dio's built-in progress streams.

### Alternatives considered
- **Option A — `package:http` (official).** Lightweight, minimal. Rejected for being too low-level: every retry, every idempotency key, every refresh cycle would be hand-rolled in service layer code, duplicated across features.
- **Option B — `chopper`.** Retrofit-style declarative, code-generated. Rejected because the declarative annotation style is less ergonomic than Dio interceptors when the same interceptor must read auth state, write headers, and observe upload progress; for RADHA's use case interceptors win.
- **Option C — `dart_frog_http_client` or other niche options.** Rejected on community size and stability.
- **Option D (chosen) — Dio 5 with explicit interceptor stack.** Mature, battle-tested, transparent control of the request lifecycle, first-class multipart and progress, large community.

### Tradeoffs accepted
- Dio's API has historically had breaking changes; we pin to `^5.4.0` and lift only with an ADR amendment.
- Logging interceptor must redact PII (phone, email, OTP) — enforced by tests in FE-06.

### Long-term impact
Every backend call in the app passes through one chain. Adding a new cross-cutting concern (e.g. a feature-flag header) is one file edit, not 60.

### Reversal difficulty
**Low.** Service layer is thin and typed; swapping Dio for `http` would touch one file per service.

### Validation
- FE-06 contract tests prove: idempotency key present on POST/PUT/PATCH; refresh flow on 401; retry budget honoured; logging redacts.
- No service file imports `package:http` or `dart:io HttpClient` directly. Enforced by the custom-lint pack.

---

## ADR-006: `flex_color_scheme` 7.3 for Material 3 theming

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Design Lead, Frontend Tech Lead
**Affected phases**: FE-02 (primary), FE-03, FE-33, FE-37, FE-38

### Context
RADHA needs light + dark + dynamic-color (Material You on Android 12+), comprehensive M3 sub-themes, and a single seed-color pipeline with deterministic tonal palettes. Hand-rolling `ThemeData` for every component (buttons, chips, sheets, snackbars, navigation bars, dialogs) means hundreds of lines of repetitive code that drifts as Flutter ships M3 updates.

### Decision
Adopt **`flex_color_scheme` 7.3** as the single theme source. The seed color is RADHA emerald (`#10B981`). Light and dark schemes are derived from `FlexScheme.custom`. M3 sub-themes are configured via `FlexSubThemesData` and mapped to design tokens defined in `FRONTEND_DESIGN_SYSTEM.md`. Custom tokens (motion, haptics, custom radii, custom spacing) live in `ThemeExtension`s registered with `ThemeData.extensions`.

### Alternatives considered
- **Option A — Hand-rolled `ThemeData`.** Maximum control. Rejected for maintenance cost: every M3 component update from the Flutter team requires re-mapping; `flex_color_scheme` does this for the team.
- **Option B — `material_color_utilities` directly.** Mid-ground. Rejected because it solves only the palette generation, not the sub-theme wiring.
- **Option C (chosen) — `flex_color_scheme` 7.3.** One-liner produces a complete M3 light/dark theme; sub-themes are declarative; tone overrides supported; brand emerald stays at full saturation in both modes via `surfaceMode`.

### Tradeoffs accepted
- The package is one developer-led — bus-factor risk. Mitigated because the surface area we use is small (scheme + sub-themes) and replicable by hand if the package stalls.
- Some advanced `flex_color_scheme` features (key colors, fixedDim) are not used to keep the surface predictable.

### Long-term impact
Designers map tokens once; engineers consume `Theme.of(context).colorScheme.primary` everywhere. Brand updates cost one PR.

### Reversal difficulty
**Low.** A migration to vanilla `ThemeData` would mechanically replace one builder call.

### Validation
- The token-lint pass (`tool/design/lint_tokens.dart`) finds zero hardcoded color literals outside theme files.
- Light/dark golden snapshots match the design Figma export within 2 ΔE on swatch chips.

---

## ADR-007: `envied` for compile-time environment injection

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Security Lead
**Affected phases**: FE-01 (primary), FE-06, FE-13, FE-40

### Context
The app reads several environment-scoped values at build time: API base URL per flavor, Sentry DSN, Razorpay key, build channel, feature-flag bootstrap URL. These must be (a) statically baked into the binary so a runtime override cannot redirect traffic, (b) typed so a typo at the call site is a compile error, and (c) absent from the prod APK as plaintext where they are sensitive.

### Decision
Adopt **`envied`** with one `.env` file per flavor (`.env.dev`, `.env.staging`, `.env.prod`) and a generated `Env` class per flavor. Sensitive values (e.g. Razorpay live key) use `obfuscate: true` to avoid plaintext in the APK. The `.env.*` files are gitignored; a `.env.dev.template` is committed.

### Alternatives considered
- **Option A — `flutter_dotenv`.** Reads the env file at runtime from assets. Rejected for two reasons: (1) the values are visible as plaintext inside the APK assets; (2) a misconfigured asset path produces a runtime crash, not a compile error.
- **Option B — `--dart-define` only.** Native to the Flutter toolchain, no extra package. Rejected because values are string-typed at the call site (`String.fromEnvironment('API_URL', defaultValue: '')`), prone to silent default fallbacks, and scattered across the code.
- **Option C — A custom code-gen pass.** Rejected: rebuilds `envied` poorly.
- **Option D (chosen) — `envied`.** Compile-time injection, typed accessors, optional obfuscation for sensitive keys, one `.env.<flavor>` file per environment, zero runtime cost.

### Tradeoffs accepted
- `build_runner` step required for env regeneration. Same pipeline as Riverpod/Drift/freezed.
- Obfuscation is best-effort, not encryption. Real secrets stay server-side; the mobile app holds public-facing keys (Razorpay key, Sentry DSN) only.

### Long-term impact
A new env var is one PR: add to `.env.<flavor>`, add to `Env` class, regenerate. CI fails on missing keys.

### Reversal difficulty
**Low.** Typed env class is replaceable with `--dart-define` over a single sprint.

### Validation
- `flutter build apk --flavor prod --release` followed by `apkanalyzer` finds no plaintext for keys marked `obfuscate: true`.
- CI rejects PRs that change `.env.template` without updating `ENVIRONMENT_CONFIG.md`.

---

## ADR-008: Sentry (`sentry_flutter`) for crash and trace observability

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Backend Tech Lead, SRE
**Affected phases**: FE-01 (DSN slot), FE-06 (network breadcrumbs), FE-40 (release gate)

### Context
The backend already runs on Sentry (BE-48). End-to-end correlation of a mobile error to a server log is faster when both ends emit to the same vendor: a single trace ID joins the mobile breadcrumbs to the backend span. The team prefers one observability vendor over two unless there is a strong reason to split.

### Decision
Adopt **`sentry_flutter`** for the mobile crash, performance, and breadcrumb stream. Symbol (debug-info) upload is part of the FE-40 release pipeline. The DSN is per-flavor (empty in dev to silence local noise). Performance traces are sampled at 10% in prod, 100% in staging.

### Alternatives considered
- **Option A — Firebase Crashlytics.** Free, built into the Firebase stack we already use for FCM. Rejected for split-vendor observability: a mobile crash would land in Crashlytics, the corresponding backend error in Sentry, and on-call engineers would correlate by hand.
- **Option B — Both Crashlytics + Sentry.** Rejected for double instrumentation cost (two SDKs, two release pipelines, two privacy reviews) without a compensating gain.
- **Option C — Self-hosted (e.g. self-hosted GlitchTip).** Rejected: ops burden RADHA does not have headcount for in v1.
- **Option D (chosen) — Sentry SaaS.** Same vendor as BE-48, joined trace IDs, native Flutter SDK with Impeller-aware performance, established privacy posture.

### Tradeoffs accepted
- One vendor lock-in. Acceptable because the SDK is open source and the on-prem migration path exists if needed.
- Sentry SDK adds ~600 KB to release APK. Within budget.

### Long-term impact
Observability is one dashboard, one alert routing config, one on-call paging policy.

### Reversal difficulty
**Medium.** Replacing Sentry means swapping the SDK and re-doing the symbol-upload pipeline; call-site impact is low since errors are emitted through a thin wrapper.

### Validation
- A test crash in staging shows up in Sentry within 60 s (FE-40 release smoke).
- Symbol upload integrity check in `mobile-release.yml` rejects builds with missing dSYM/mapping.

---

## ADR-009: Patrol for E2E on device, `golden_toolkit` for visual regression

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: QA Lead, Frontend Tech Lead
**Affected phases**: FE-01 (CI hook), FE-11, FE-12, FE-17, FE-29, FE-40

### Context
RADHA needs E2E coverage on permissioned native flows (camera + ML Kit, push notifications, deep links, biometrics, file pickers). Vanilla `integration_test` cannot reach native permission dialogs or system UI. Visual regression coverage must run in <2 minutes per phase to keep the PR pipeline under 12 minutes.

### Decision
Adopt **Patrol** for E2E (`patrol_cli`, `patrol_finders`, native automation drivers for Android/iOS). Adopt **`golden_toolkit`** for visual regression (font loading, multi-device screen sizes, light/dark/RTL × text-scale). Playwright is restricted to the supplementary Flutter Web build (FE-Web only) and is not used on Android/iOS.

### Alternatives considered
- **Option A — `integration_test` only.** Rejected: cannot tap native permission dialogs.
- **Option B — Appium.** Rejected: heavy server, slow setup, weak Flutter widget tree access.
- **Option C — Maestro.** Lightweight YAML-driven UI runner. Rejected as a primary because the Dart-side Patrol API gives engineers the same authoring environment as widget tests; Maestro would require a parallel test format.
- **Option D — Playwright (Android/iOS via Webview).** Rejected: RADHA is a native Flutter app, not a Webview.
- **Option E (chosen) — Patrol + golden_toolkit.** Patrol for permissioned and platform-channel flows; `golden_toolkit` for fast visual regression. Both author tests in Dart.

### Tradeoffs accepted
- Patrol requires a connected device or a device farm runner; the merge-to-main pipeline gains a ~10-minute Patrol stage.
- Goldens are platform-rendered; macOS goldens diverge from Linux. The `--update-goldens` flow is gated by a reviewer signature in the commit message.

### Long-term impact
Per-phase QA artifacts include a Patrol report and golden diffs. Visual regressions are caught before merge.

### Reversal difficulty
**Low.** Test files are isolated under `integration_test/` and `test/goldens/`.

### Validation
- Each phase that touches a native capability ships at least one Patrol test (FE-11 OTP, FE-17 camera, FE-21 push deep link, FE-31 task push).
- Goldens cover light + dark + RTL × xs/md/xxl text scales for every primitive in `lib/widgets/`.

---

## ADR-010: Feature-first folder layout under `lib/features/`

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, two senior Flutter engineers
**Affected phases**: every FE-NN phase

### Context
A 40-phase build produces hundreds of files. A layered layout (`lib/controllers/`, `lib/services/`, `lib/widgets/`, `lib/screens/` at the top level) creates pseudo-modular code that fights every code-review change set: a single feature's PR touches every top-level folder. The backend already organises by domain module (`server/src/modules/<domain>/`) and the frontend should mirror that discipline.

### Decision
Adopt a feature-first layout:

```
lib/
  app/                  # bootstrap, router, theme wiring
  core/                 # cross-cutting: dto, errors, logging, env, constants
  data/                 # cross-cutting infra: dio client, drift db, secure storage
  widgets/              # design-system primitives (PrimaryButton, AppTextField, ...)
  features/
    auth/               # FE-11, FE-12: OTP request + verify
    onboarding/         # FE-09, FE-10
    scanner/            # FE-17
    product/            # FE-18, FE-19
    expiry/             # FE-20, FE-28
    recalls/            # FE-21
    explainer/          # FE-22
    alternatives/       # FE-23
    shopping_list/      # FE-24
    business_dashboard/ # FE-25, FE-26
    bulk_scan/          # FE-27
    grn/                # FE-29
    inventory/          # FE-30
    tasks/              # FE-31
    reports/            # FE-32
    settings/           # cross-phase
    sync/               # FE-08, FE-36
  l10n/                 # ARBs (en, hi, ta, te, bn, mr)
```

Each feature folder owns its `presentation/` (widgets, screens), `application/` (Riverpod controllers), `domain/` (entities, value objects), and `data/` (repositories, DTO mappers).

### Alternatives considered
- **Option A — Layered (`controllers/`, `services/`, `widgets/`, `screens/` at top).** Rejected: every feature PR fans out across folders, code review becomes scrolling exercise.
- **Option B — Pure clean architecture with separate packages per layer.** Rejected: package overhead inflates `pubspec.yaml` and slows `pub get`/`build_runner`.
- **Option C (chosen) — Feature-first with internal layering.** Mirrors backend module layout. Each feature is a teachable, reviewable unit.

### Tradeoffs accepted
- Engineers must enforce no cross-feature imports (`features/scanner/` cannot import `features/grn/`). The custom-lint pack adds a rule.
- Cross-feature shared widgets land in `lib/widgets/`. Discipline required to know when a widget graduates.

### Long-term impact
A new feature (e.g. FE-41 Wear OS companion) is a new folder. PRs are bounded. Onboarding new engineers means pointing them at one folder, not five.

### Reversal difficulty
**High.** Hundreds of file paths and import statements would change.

### Validation
- The cross-feature-import lint rule has zero violations after FE-08.
- Every FE-NN phase's "Files to Create" list maps to exactly one `features/<domain>/` folder (or `widgets/`, `core/`).

---

## ADR-011: `apps/mobile/` inside the existing pnpm monorepo

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Engineering Manager, Frontend Tech Lead, Backend Tech Lead
**Affected phases**: FE-01 (primary), FE-06, FE-40

### Context
The repository already houses `server/`, `packages/shared-types/`, future `apps/marketing-web/`, `apps/owner-dashboard/`, and infra config. Adding the Flutter app as a sibling in `apps/mobile/` keeps backend and frontend changes in one PR, lets the mobile team consume `@radha/shared-types` directly, and keeps cross-cutting documentation (`API_CONTRACTS.md`, `CONNECTION_MAP.md`) in one place.

### Decision
Place the Flutter project at `apps/mobile/`. The pnpm workspace root is unchanged (`pnpm-workspace.yaml`: `server`, `packages/*`). The Flutter project is not a pnpm workspace member (Flutter uses `pub`), but lives in the same git repository. CI workflows (`mobile-ci.yml`, `mobile-release.yml`) live at `.github/workflows/` and are scoped by `paths:` filters.

Shared types are bridged: `packages/shared-types/src/*.ts` is the source of truth. A CI step (`tool/contracts/diff_dtos.dart`) generates Dart DTOs via `quicktype`, places them at `apps/mobile/lib/core/dto/`, and fails CI on drift.

### Alternatives considered
- **Option A — Separate `radha-mobile` git repo.** Rejected: API contract drift is invisible across repo boundaries; PRs that change a backend DTO and the corresponding Dart DTO must be coordinated by hand.
- **Option B — Make the Flutter project a pnpm workspace member with a thin `package.json`.** Rejected: pnpm has nothing to manage there, and the indirection adds confusion for new engineers.
- **Option C (chosen) — Flutter as a sibling under `apps/`, no pnpm membership, contract drift caught by CI.** Single repo, single PR, single CI, single doc set.

### Tradeoffs accepted
- The repo grows in checkout size (~150 MB after `pub get`). Acceptable.
- Engineers who want to clone "just the mobile app" cannot. Acceptable because dual-stack ownership is the team norm.
- Git history is interleaved across surfaces. Mitigated by `pathspec`-aware tooling.

### Long-term impact
A backend DTO change and the matching Dart DTO change are atomic. Onboarding for full-stack engineers is one repo to clone.

### Reversal difficulty
**High.** Splitting later means git history surgery and a new CI tenant.

### Validation
- `tool/contracts/diff_dtos.dart` runs in `mobile-ci.yml` and fails on drift.
- `apps/mobile/.contracts.lock.json` matches the latest `packages/shared-types/dist/index.d.ts` schema fingerprint.

---

## ADR-012: Three Android flavors + xcconfig iOS configurations

**Status**: Accepted
**Date**: 2026-05-17
**Deciders**: Frontend Tech Lead, Mobile Architect, Release Manager
**Affected phases**: FE-01 (primary), FE-40

### Context
The single most common production accident on mobile teams is shipping a build that points at the wrong API. Bundle IDs that collide between environments cause the wrong build to overwrite the right one on a developer device. Per-environment Sentry DSNs and FCM senders must be physically isolated.

### Decision
Adopt three flavors for Android (`dev`, `staging`, `prod`) via `productFlavors`, and three xcconfig-based configurations for iOS (`Dev.xcconfig`, `Staging.xcconfig`, `Prod.xcconfig`) wired through `Runner.xcodeproj`. Bundle identifiers are physically distinct:

- `app.radha.mobile.dev`
- `app.radha.mobile.staging`
- `app.radha.mobile`

Each flavor has its own:

- App icon (`ic_launcher_dev.png`, `ic_launcher_staging.png`, `ic_launcher_prod.png`)
- App name (`RADHA Dev`, `RADHA Staging`, `RADHA`)
- API base URL (via `envied` ADR-007)
- FCM project (`google-services.json` per flavor)
- Sentry DSN (per flavor; empty in dev)
- Flavor banner (visible on dev/staging, off on prod)

### Alternatives considered
- **Option A — Single flavor + `--dart-define=ENV=...`.** Rejected: bundle ID is identical, so a developer who installs `dev` then `prod` overwrites the previous install; physical isolation is what prevents the cross-flavor accident.
- **Option B — Two flavors only (debug + release).** Rejected: collapses staging into one of the two; staging must be a third, isolated environment that mirrors prod for QA.
- **Option C — Four+ flavors.** Rejected: the operational cost of an extra flavor (icons, signing keys, store listings) outweighs the marginal benefit.
- **Option D (chosen) — Three flavors / xcconfigs.** Industry-standard, supports side-by-side install, isolates secrets, isolates crash streams.

### Tradeoffs accepted
- Three sets of signing artifacts (one per flavor, except dev which signs with the debug keystore).
- Three Firebase projects to manage.
- Slightly more complex Gradle and xcconfig wiring; one-time cost.

### Long-term impact
QA and release sign-off processes can be reasoned about per flavor. A staging-only crash never appears in the prod Sentry stream.

### Reversal difficulty
**Medium.** Removing a flavor unwinds Gradle, xcconfig, signing, and store listings; not trivial but mechanical.

### Validation
- All three flavors install side-by-side on a single device (FE-01 T8).
- Each flavor's diagnostic dialog (long-press home in FE-01) shows the correct API URL and Sentry DSN.
- Prod build has zero references to dev or staging URLs (verified by `strings | grep` in FE-40 release gate).

---

## How to Add a New ADR

1. Pick the next ADR number (`ADR-013`).
2. Copy the template above.
3. Fill the eight sections completely. No "TBD".
4. Get sign-off from at least one other senior engineer.
5. Append to the index table.
6. Reference the ADR in any phase doc whose decisions it constrains.
7. Open a PR titled `docs(adr): ADR-NNN <title>`.

## How to Supersede an ADR

Never edit an accepted ADR. Add a new ADR with `Status: Accepted (supersedes ADR-NNN)` and update the prior entry's status to `Superseded by ADR-MMM`. The history is the value.

---

**Last Updated**: 2026-05-17
**ADRs**: 12 accepted, 0 superseded, 0 rejected
**Next ADR Number**: ADR-013
