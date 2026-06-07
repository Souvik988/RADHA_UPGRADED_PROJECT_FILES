# RADHA Mobile — Technical Debt Register

> **Version**: `v1.0.0`
> **Last updated**: 2026-05-17
> **Owner**: Frontend Tech Lead (register custodian) · Engineering Manager (escalation)
> **Status**: **Live document.** Every accepted shortcut, every deferred refactor, every "we'll fix this later" lives here. Nothing else.

This is the canonical record of technical debt accepted by the RADHA Flutter app (`apps/mobile/`). Debt is a deliberate trade — speed today against cleanup later. Untracked debt compounds silently; tracked debt has a clock and an owner. This file is the clock.

Constrained by:
- **ADR-001** — 40-phase roadmap; cleanup phases are anchored to phase IDs.
- **ADR-002** — Riverpod state shape (DEBT-005, DEBT-014 reference it).
- **ADR-008** — Sentry observability (DEBT-009 invalidation strategy).
- `FRONTEND_QA_SYSTEM.md` — coverage gates referenced from DEBT-002.
- `FRONTEND_VERIFICATION_SYSTEM.md` — CI checks that surface debt automatically.
- `FRONTEND_DESIGN_SYSTEM.md` — token versioning that DEBT-007 affects.

---

## How to read this file

Every entry has:
- A stable **DEBT-NNN** id that never re-numbers (resolved entries stay in place).
- A severity, priority, and status that the quarterly review keeps current.
- An **introduced phase** (when it became debt) and a **cleanup phase** (when it must be gone).
- Concrete **future risk** — the failure mode if cleanup never happens.
- A **cleanup approach** that the cleanup-phase owner can pick up cold.

Resolved entries keep their full body and add a **Date resolved** line plus a link to the resolving PR. They are not deleted — the register is also a memory of "why did we do it this way?"

---

## Index

| ID | Title | Severity | Priority | Status | Phase in → out |
|---|---|---|---|---|---|
| DEBT-001 | Drift schema lacks composite indexes for offline product cache | Medium | Backlog | Open | FE-08 → FE-08 perf pass |
| DEBT-002 | Coverage gate is 80% during foundation, raised to 85% from FE-06 | Low | Next Sprint | Open | FE-01 → FE-06 |
| DEBT-003 | Hardcoded Razorpay test key in `dev.env` | Medium | Next Sprint | Open | FE-01 → FE-13 |
| DEBT-004 | `cached_network_image` default LRU eviction unaware of device class | Medium | Backlog | Open | FE-06 → FE-39 |
| DEBT-005 | GoRouter `redirect` runs sync `ref.read` on auth providers | High | Next Sprint | Open | FE-05 → FE-07 polish |
| DEBT-006 | `intl_utils` watcher and CI build_runner can drift silently | Low | Backlog | Open | FE-35 → FE-35 polish |
| DEBT-007 | Bundled fonts ship full glyph sets for Tamil/Telugu/Bengali | Medium | Backlog | Open | FE-02 → FE-39 |
| DEBT-008 | `flutter_secure_storage` falls back to encrypted SharedPrefs on Android <23 | Medium | Backlog | Open | FE-07 → FE-40 |
| DEBT-009 | Recall alerts list re-fetches on every foreground | Medium | Next Sprint | Open | FE-21 → FE-36 |
| DEBT-010 | Onboarding segment selection is local-only across cold restart | Low | Backlog | Open | FE-10 → FE-10 polish |
| DEBT-011 | Lottie JSON parsed at cold start, ~80 ms cost | Medium | Backlog | Open | FE-09 → FE-39 |
| DEBT-012 | ARB pluralization missing `=2/few/many` for hi/mr | Low | Backlog | Open | FE-35 → FE-35 polish |
| DEBT-013 | S3 presigned upload does not resume on network drop | Medium | Backlog | Open | FE-29 → FE-36 |
| DEBT-014 | Providers expose `AsyncValue<T>` directly instead of typed `Result<T>` | Low | Backlog | Open | FE-07 → post-v1 |
| DEBT-015 | `tool/contracts/diff_dtos.dart` runs `quicktype` per PR with no cache | Low | Backlog | Open | FE-06 → FE-06 polish |

Severity counts: **Critical 0** · **High 1** · **Medium 8** · **Low 6**.
Open: **15** · In Progress: **0** · Resolved: **0**.

---

## DEBT-001: Initial Drift schema lacks composite indexes for offline product cache lookups

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-08
**Cleanup phase**: FE-08 perf pass (target — fold into FE-39 if not done by then)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
The first cut of the Drift schema in FE-08 indexes `products(ean)` and `products(tenant_id)` as separate single-column indexes. Hot queries on the offline scan path filter by `(ean, tenant_id)` simultaneously and need a composite index for the SQLite query planner to avoid table scans on caches with > 5,000 rows.

### Why introduced
FE-08 prioritises shipping a working offline scan loop end-to-end (scan → cache hit → render). Indexing strategy was deferred so the schema would not bake in assumptions before the real query patterns were observable. The single-column indexes are correct for early adopters and become a problem only once a tenant's local cache grows.

### Future risk if unresolved
Once the cache crosses ~5,000 products (typical mid-size store after 2–3 weeks of business use), offline scan p50 climbs from ~80 ms to 200–400 ms and crosses the FE-39 budget of `< 800 ms`. On older Android devices (Android 8 / 2 GB RAM) the regression is sharper because `sqlite3` falls back to disk I/O.

### Cleanup approach
- Add `CREATE INDEX idx_products_ean_tenant ON products (tenant_id, ean)`.
- Add `CREATE INDEX idx_products_tenant_updated ON products (tenant_id, updated_at DESC)` for sync delta queries.
- Drop the single-column `products(ean)` index — composite covers it.
- Bump Drift schema version, add migration in `drift/migrations/`.
- Re-run benchmark `tool/bench/offline_scan_bench.dart` and confirm p50 ≤ 100 ms at 10,000 rows.

### Related
- ADR-004 (Drift)
- `FE-08_PHASE.md` — Schema definition
- `FE-39_PHASE.md` — Performance pass owner
- BE-44 sync — feeds the table this index protects

---

## DEBT-002: Test coverage gate is 80% during FE-01..FE-05 foundation

**Severity**: Low
**Priority**: Next Sprint
**Status**: Open
**Owner**: QA Lead
**Introduced in phase**: FE-01
**Cleanup phase**: FE-06 (gate raises automatically)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
`mobile-ci.yml` enforces a coverage gate of **80% on `lib/app/**`** during foundation phases, then raises to **85% on `lib/features/**` and 80% on `lib/core/**`** from FE-06 onward. The lower bar during FE-01..FE-05 means foundation modules ship with thinner test coverage than the rest of the app.

### Why introduced
Foundation code (theme tokens, motion primitives, navigation shell) is hard to unit-test in isolation because most behaviour shows up only when consumed by feature code. Forcing 85% on a near-empty `lib/app/` would have produced shallow tests that exercise the test, not the code. The 80% bar buys honest tests during scaffolding.

### Future risk if unresolved
None — the gate raises mechanically when `coverage_gate.dart` reads `phase >= 6`. The risk is forgetting to backfill coverage on FE-01..FE-05 modules once the gate flips, leaving the foundation permanently under-tested.

### Cleanup approach
- During FE-06, run `flutter test --coverage` and review the lcov delta on `lib/app/**`.
- Add tests until 85% on each module.
- Update `coverage_gate.dart` to remove the phase exemption.
- Reference this DEBT id in the FE-06 sign-off PR.

### Related
- `FRONTEND_QA_SYSTEM.md` — Rung 2 (unit tests)
- `FRONTEND_VERIFICATION_SYSTEM.md` — coverage report job
- `FE-06_PHASE.md` — gate raise

---

## DEBT-003: Hardcoded Razorpay test key in dev flavor's `dev.env`

**Severity**: Medium
**Priority**: Next Sprint
**Status**: Open
**Owner**: Backend Tech Lead (key custody) · Frontend Tech Lead (rotation in app)
**Introduced in phase**: FE-01
**Cleanup phase**: FE-13 (paywall) — must rotate before public beta
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
`apps/mobile/env/dev.env` contains a Razorpay **test-mode** API key (`rzp_test_*`) hardcoded for local development. The key is committed because dev flavor builds run on every contributor's machine and needs to work offline of any secrets manager.

### Why introduced
Razorpay test keys are designed to be public and only accept test cards. Setting up a per-developer secret store at FE-01 time would have blocked anyone running `flutter run --flavor dev` until they got credentials. The trade was: ship dev convenience, accept a clearly-test key in source.

### Future risk if unresolved
Two failure modes:
1. **Test key mistakenly used in staging/prod** if env merging is misconfigured. Mitigated today by `envied` compile-time validation that requires a non-empty `RAZORPAY_KEY` per flavor.
2. **Test key gets confused with a prod key** in code review. Mitigated by enforcing the `rzp_test_` prefix in `dev.env` via lint.

The real risk is **forgetting to rotate** if Razorpay revokes test keys or the project's test account rotates.

### Cleanup approach
- Move `dev.env` Razorpay key out of git and into the dev secrets bundle distributed via 1Password.
- Add a CI check that `dev.env` does not contain any value matching `rzp_(live|test)_*`.
- Provide a one-line fallback (`RAZORPAY_KEY=rzp_test_PUBLIC_DEMO`) that connects to a shared sandbox account.
- Document key rotation in the FE-13 handoff.

### Related
- ADR-007 (envied)
- `ENVIRONMENT_CONFIG.md` — env file management
- `FE-13_PHASE.md` — paywall

---

## DEBT-004: `cached_network_image` cache uses default LRU eviction

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-06
**Cleanup phase**: FE-39 (performance pass)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
`cached_network_image` is configured with the package defaults (max 200 entries, 7-day stale window, system-default disk cache directory). The cache is not aware of the device class (low-end Android with 2 GB RAM vs flagship iPhone). On Pixel 4a and Galaxy J series the cache fills the available scratch space within a week of business use and starts thrashing when scanned product photos rotate.

### Why introduced
The package defaults work for ~80% of devices and the perf cost only shows up after sustained use. Tuning per device class needs a profile run on a representative device matrix that does not exist until FE-39.

### Future risk if unresolved
On low-end Android devices the cache evicts hot photos more often than necessary (because LRU does not know that the OHS hero image is reopened daily), producing sub-second flashes of placeholder on the dashboard. Cumulative jank over a session is 2–3% of frames, breaching the FE-39 < 1% budget.

### Cleanup approach
- Compute device class at boot via `device_info_plus` (RAM tier, CPU class). Map to `low | mid | high`.
- Set per-tier cache config:
  - low: 80 entries, 256 MB disk cap, 3-day stale window
  - mid: 200 entries, 512 MB, 7-day
  - high: 400 entries, 1 GB, 14-day
- Add a custom `CacheManager` subclass keyed by device class.
- Add jank trace for the dashboard hero image carousel and confirm < 1% jank.

### Related
- `FE-06_PHASE.md` — image cache wiring
- `FE-39_PHASE.md` — perf pass
- `FRONTEND_DESIGN_SYSTEM.md` — image budget section

---

## DEBT-005: GoRouter `redirect` runs synchronous `ref.read` on auth providers

**Severity**: High
**Priority**: Next Sprint
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-05
**Cleanup phase**: FE-07 polish (after auth flow stabilises)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
The GoRouter `redirect` callback in `lib/app/router.dart` reads `authStateProvider` and `onboardingProgressProvider` synchronously via `ref.read`. The providers happen to be hydrated before the first navigation today because `bootstrap()` `await`s them. If hydration becomes async (e.g. when secure-storage read takes 200 ms on a slow Android device), the redirect callback will fire with a stale state and route the user to splash → home → login, producing a visible flash.

### Why introduced
Async redirects in GoRouter 14 require `redirect: (ctx, state) async => ...` and a router rebuild dance with `ChangeNotifier` re-emission. The synchronous form is simpler and correct **today**. The team chose readability for FE-05 and accepted that any future auth-hydration latency above ~50 ms would force the refactor.

### Future risk if unresolved
First-launch UX flicker on slow devices. More importantly, if the team adds remote-config gates (BE-47) into the redirect chain, the synchronous read will not have the latest flags and could route users into screens disabled for their account.

### Cleanup approach
- Convert `redirect` to async: return `Future<String?>` that awaits a `routerHydrationProvider`.
- Make `routerHydrationProvider` resolve when both auth and onboarding providers are non-`AsyncLoading`.
- Wrap router with `RouterReady` widget that shows splash while hydrating.
- Add a widget test that simulates 500 ms storage latency and verifies no double-navigation.

### Related
- ADR-003 (GoRouter)
- `FE-05_PHASE.md` — router setup
- `FE-07_PHASE.md` — auth state

---

## DEBT-006: `intl_utils` runs in dev watcher mode and CI build_runner mode separately

**Severity**: Low
**Priority**: Backlog
**Status**: Open
**Owner**: i18n owner (rotation)
**Introduced in phase**: FE-35
**Cleanup phase**: FE-35 polish (same phase, follow-up PR)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
Generated localizations are produced via `flutter pub run intl_utils:generate` locally (dev watcher) and via `dart run build_runner build` in CI. The two paths have slightly different behaviour for plural forms and message merging. Today they happen to agree because the ARB files are simple, but no automated check guarantees they stay in sync.

### Why introduced
The Flutter ecosystem has not converged on a single canonical generator. Picking one path forces every contributor onto either the watcher or the build_runner workflow, both of which have ergonomic warts. Running both keeps options open.

### Future risk if unresolved
A contributor adds a plural form that compiles via watcher but breaks build_runner — or vice versa — and ships before CI catches it. Realistically caught by `mobile-i18n.yml`'s ARB key check, but not by a true generator-equivalence check.

### Cleanup approach
- Add `tool/i18n/check_generators_match.sh` that runs both paths into temp directories and `diff`s the generated `app_localizations*.dart` files.
- Wire it into `mobile-i18n.yml`.
- Decide a canonical path post-FE-35 (likely build_runner) and remove the other from contributor docs.

### Related
- `FE-35_PHASE.md` — runtime swap
- `LOCALIZATION_STRATEGY.md` — generator choice
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-i18n.yml`

---

## DEBT-007: Bundled fonts include full glyph sets for Tamil/Telugu/Bengali

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Design Lead
**Introduced in phase**: FE-02
**Cleanup phase**: FE-39 (performance pass — APK size budget)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
`assets/fonts/` ships Noto Sans Tamil, Noto Sans Telugu, and Noto Sans Bengali at full glyph coverage (~600 KB each) plus regular and bold weights. The actual app surface uses a subset of glyphs (Indic numerics, conjuncts, business-vocabulary kerning pairs). Subsetting would save approximately **2 MB** off the release APK.

### Why introduced
Subsetting requires knowing the final visible vocabulary — including all microcopy, error messages, and translator-supplied product category names. That vocabulary stabilises only after FE-35 (i18n) ships and translators have completed their review. Subsetting too early will require a re-roll the moment a new screen lands.

### Future risk if unresolved
The release APK exceeds the FE-40 budget of `< 35 MB single-ABI`. Realistic excess is 35–37 MB without subsetting, which fails the FE-39 gate.

### Cleanup approach
- Run `tool/fonts/extract_glyphs.dart` against all ARB files and microcopy fixtures.
- Use `pyftsubset` to produce per-locale subset files.
- Switch `pubspec.yaml` to load locale-specific fonts via `flutter_localizations`.
- Re-run APK size benchmark; confirm new size ≤ 33 MB.

### Related
- ADR-006 (theme)
- `FE-02_PHASE.md` — fonts wired
- `FE-39_PHASE.md` — perf pass
- `FE-40_PHASE.md` — release engineering
- `LOCALIZATION_STRATEGY.md` — locale list

---

## DEBT-008: `flutter_secure_storage` falls back to encrypted SharedPreferences on Android <23

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-07
**Cleanup phase**: FE-40 (release engineering — minSdk decision)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
`flutter_secure_storage` uses Android Keystore on API 23+ (Marshmallow). On API 19–22 (Lollipop and below), the package falls back to SharedPreferences encrypted with an in-app symmetric key derived from a hardware identifier. The fallback is **not** equivalent in security guarantees but is documented and standard for the package.

### Why introduced
The team set Android minSdk to 21 (Lollipop) at FE-01 to maximise device coverage in tier-2 and tier-3 retail (~4% market share on Android < 23 in target geographies as of 2026). Bumping to minSdk 23 would drop those users.

### Future risk if unresolved
A motivated attacker with physical access and root on an Android < 23 device could extract the JWT refresh token from the encrypted SharedPreferences blob. Realistic risk: small (the device population is shrinking) but the threat model is real for high-value retail accounts.

### Cleanup approach
- At FE-40, re-evaluate minSdk against current Play Store device data.
- If Android < 23 share is < 2%, bump minSdk to 23 and remove the fallback path.
- If still > 2%, document the threat in `FRONTEND_VERIFICATION_SYSTEM.md` security section, add an in-app warning when run on API < 23 ("Your device's Android version does not support the strongest secure storage. Update if possible.").
- Either way, log device API at boot to Sentry tags so the population can be tracked.

### Related
- ADR-007 (env injection — feeds into security choices)
- `FE-07_PHASE.md` — auth state
- `FE-40_PHASE.md` — release engineering

---

## DEBT-009: Recall alerts list re-fetches on every app foreground

**Severity**: Medium
**Priority**: Next Sprint
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-21
**Cleanup phase**: FE-36 (sync UI)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
The recall alerts inbox at FE-21 invalidates its provider on every app foreground (`AppLifecycleState.resumed`). This guarantees freshness but produces unnecessary network traffic and a brief skeleton flash every time the user reopens the app, even if no recall has been issued.

### Why introduced
At FE-21 there is no FCM-driven invalidation channel yet (BE-39 publishes recall events, but the client hasn't subscribed). Foreground refresh is the simplest correct strategy and ships in 2 hours instead of 2 days.

### Future risk if unresolved
- Quota cost at scale: if 100,000 users open the app twice per day, that is 200,000 unnecessary `GET /api/v1/recalls` calls daily.
- UX cost: skeleton flash on foreground feels janky.
- Sentry breadcrumbs are noisier than they need to be.

### Cleanup approach
- In FE-36, subscribe to FCM topic `recalls.tenant.<tenantId>`.
- On message receipt, invalidate `recallAlertsProvider` from the FCM background handler.
- Replace the foreground-refresh strategy with a stale-time-based check (refetch only if data older than 15 minutes).
- Verify Sentry breadcrumb volume drops by ≥ 70%.

### Related
- ADR-008 (Sentry)
- `FE-21_PHASE.md` — recall alerts
- `FE-36_PHASE.md` — sync UI
- BE-39 recalls
- BE-44 sync

---

## DEBT-010: Onboarding segment selection uses local-only state for back-navigation

**Severity**: Low
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-10
**Cleanup phase**: FE-10 polish (same phase, follow-up PR before FE-13 ships)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
On the onboarding segment cards screen (FE-10), tapping a card and then backing out preserves the visual selection state in widget memory only. Killing the app and relaunching loses the partial selection — the user must tap again. The selection only commits to the server at "Confirm" tap.

### Why introduced
Persisting partial onboarding state requires schema decisions in BE-34 and Drift schema bumps in FE-08. Neither was scoped into FE-10. The user impact is small (one extra tap) and only affects users who kill the app mid-onboarding.

### Future risk if unresolved
A small but real activation-funnel leak: ~2% of users abandon onboarding mid-segment-selection. Of those, ~30% relaunch within 24 hours and would benefit from resumed state. Total impact: < 1% activation lift.

### Cleanup approach
- Add `onboarding_progress` table to Drift schema (small — { user_id, partial_segment_id, updated_at }).
- Persist selection on tap; clear on confirm.
- Read on splash; if non-null and recent (< 7 days), pre-select the card.
- Add widget test for cold-restart preservation.

### Related
- `FE-10_PHASE.md` — segment cards
- `FE-08_PHASE.md` — Drift schema (would need bump)
- BE-34 onboarding

---

## DEBT-011: Lottie animations parsed at cold start

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-09
**Cleanup phase**: FE-39 (performance pass)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
Lottie JSON files (boot loop, scan-success, paywall-celebrate, recall-attention, etc.) are bundled as raw `.json` and parsed at first use. The boot-loop file is parsed during splash, adding ~80 ms to cold start on a Pixel 4a. Pre-compiling to `dotLottie` (`.lottie`) format or to a Flutter-friendly binary cuts parse time to < 10 ms.

### Why introduced
The `lottie` package's binary format support shifted across versions during the project's lifetime. Sticking with JSON during FE-09 avoided package-version churn and gave Design Lead the freedom to drop in After Effects exports without conversion steps.

### Future risk if unresolved
Cold-start budget creep. FE-39 budget is `< 1.5 s to first frame on Pixel 4a`; current splash parse cost is 80 ms with one Lottie file. Adding three more Lottie files at boot would push the budget over.

### Cleanup approach
- Convert all `assets/lottie/*.json` to `.lottie` (dotLottie) format via `tool/lottie/convert.dart`.
- Update `RadhaLottie.asset()` wrapper to load `.lottie` first, fall back to `.json`.
- Re-run `flutter run --profile --trace-startup` and confirm cold start < 1.4 s.
- Update `ASSET_PIPELINE.md` to reflect the new pipeline.

### Related
- `FE-09_PHASE.md` — splash
- `FE-39_PHASE.md` — perf pass
- `ASSET_PIPELINE.md` — asset pipeline
- `FRONTEND_DESIGN_SYSTEM.md` — animation vocabulary

---

## DEBT-012: ARB pluralization rules use `=0/=1/other` for hi/mr

**Severity**: Low
**Priority**: Backlog
**Status**: Open
**Owner**: i18n owner
**Introduced in phase**: FE-35
**Cleanup phase**: FE-35 polish (after translator confirmation)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
ARB plural messages currently encode three forms: `=0`, `=1`, `other`. Hindi and Marathi grammar permits `=2` ("दो"), `few`, and `many` as distinct plural forms in some constructions. The current ARB ignores those forms because the source-of-truth English ARB only has the three-form skeleton.

### Why introduced
At FE-35 ship time, translators had confirmed the three-form output for Hindi and Marathi as acceptable. Re-skeletoning ARBs across six locales to add `=2/few/many` would require coordinated translator rework that wasn't scoped into FE-35.

### Future risk if unresolved
Minor grammatical roughness in counted strings ("2 आइटम" reads slightly stiff but is understood). No functional risk.

### Cleanup approach
- Open ARB files for `hi.arb` and `mr.arb`.
- For each plural message, ask the translator if `=2/few/many` would improve naturalness.
- Update ARB skeleton to support the new forms (English `other` covers all extras).
- Regenerate localizations.
- Pin the change to a translator-signed PR.

### Related
- `LOCALIZATION_STRATEGY.md` — plural handling
- `FE-35_PHASE.md` — i18n runtime swap

---

## DEBT-013: S3 image upload via presigned URL does not resume on network drop

**Severity**: Medium
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-29
**Cleanup phase**: FE-36 (sync UI — outbox upload retry)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
GRN photo uploads (`apps/mobile/lib/features/grn/data/upload_repository.dart`) hit S3 via presigned POST URL. On network drop mid-upload, the upload restarts from byte 0 on the next retry. There is no resume marker.

### Why introduced
S3 multipart upload with resume requires server coordination (BE-26 GRN was scoped for single-part upload). Single-part is simpler, has no client-side state to manage, and works for the common case (photos on store-grade Wi-Fi).

### Future risk if unresolved
For low-bandwidth users (rural retail on 2G/3G) or users with flaky shop networks, a 4 MB photo upload may never complete because each retry restarts. Realistic impact: 2–5% of GRN flows in tier-3 stores, producing visible failure states and forcing manual retry.

### Cleanup approach
- BE-26 to add multipart presigned endpoint (`POST /api/v1/grn/uploads/initiate`, `PUT /api/v1/grn/uploads/<id>/parts/<partNumber>`, `POST /api/v1/grn/uploads/<id>/complete`).
- Update `upload_repository.dart` to chunk into 1 MB parts.
- Persist part-completion state in Drift (table `upload_parts`).
- On network drop, retry from the last completed part.
- Wire the retry into the offline outbox queue.

### Related
- `FE-29_PHASE.md` — GRN wizard
- `FE-36_PHASE.md` — sync UI
- BE-26 GRN
- BE-44 sync

---

## DEBT-014: Riverpod providers expose `AsyncValue<T>` directly

**Severity**: Low
**Priority**: Backlog
**Status**: Open
**Owner**: Frontend Tech Lead
**Introduced in phase**: FE-07
**Cleanup phase**: post-v1 (not blocking)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
Async providers across the app expose `AsyncValue<T>` as their public surface. Consumers handle three states (`loading`, `data`, `error`) inline at every call site. A typed `Result<T> = Success<T> | Failure<RadhaError>` wrapper would normalise error categorisation (network, server, validation, auth, quota) and make consumer code more readable.

### Why introduced
`AsyncValue` is idiomatic Riverpod. Switching to a custom wrapper now means fighting the library and rewriting `AsyncValue.when`-based widget tests. The team accepts inline state handling for v1 and would consider the wrapper for v2.

### Future risk if unresolved
Code duplication across the app: every async screen reimplements the same `loading → data → error` mapping. Error categorisation is inconsistent (some screens render "Network error", some render the raw exception, some render a localized fallback). Realistic impact: 2–3 days of polish time at FE-37 (empty/error states pass).

### Cleanup approach
- Define `Result<T, E extends RadhaError>` in `lib/core/result.dart`.
- Add an `AsyncValue<T> -> Result<T, RadhaError>` adapter.
- Migrate one feature at a time post-v1, starting with the highest-traffic screens (FE-17 scan, FE-25 dashboard).
- Update widget test helpers to accept `Result<T>` fixtures.

### Related
- ADR-002 (Riverpod)
- `FE-07_PHASE.md` — state management
- `FE-37_PHASE.md` — empty/error states pass

---

## DEBT-015: `tool/contracts/diff_dtos.dart` runs `quicktype` per PR with no cache

**Severity**: Low
**Priority**: Backlog
**Status**: Open
**Owner**: DevEx
**Introduced in phase**: FE-06
**Cleanup phase**: FE-06 polish (CI optimisation pass)
**Date introduced**: 2026-05-17
**Date resolved**: —

### Debt description
The contract diff job in `mobile-ci.yml` runs `quicktype` to generate Dart classes from `packages/shared-types` and diffs against the committed Dart DTOs. `quicktype` is invoked fresh on each PR, taking ~12 s. Caching the `quicktype` output keyed on `packages/shared-types/**` content hash would reduce that to < 1 s on cache hit.

### Why introduced
The contract diff job needs to be **correct first, fast second**. Caching introduces invalidation risk; a stale cache could mask a real contract drift. Initial implementation skipped caching deliberately.

### Future risk if unresolved
12 s per PR × ~50 PRs/week = ~10 minutes of CI time per week. At scale this matters; today it does not.

### Cleanup approach
- Add `actions/cache@v4` keyed on `${{ hashFiles('packages/shared-types/**') }}`.
- Cache `tool/contracts/.cache/`.
- Confirm cache invalidates on shared-types change (test by editing one DTO).
- Add a fallback: if `quicktype` output exists in cache but does not match the input hash, force regenerate.

### Related
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-ci.yml`
- `FE-06_PHASE.md` — API client + DTOs

---

## Process for adding debt

A piece of debt is not real until it is in this register. The process below is a hard rule: PRs that introduce known shortcuts without a debt entry are blocked.

### Step 1 — Detect

Debt enters the register through one of three doors:

1. **A reviewer flags a tradeoff** during PR review. The author either resolves it before merge or opens a debt entry referenced from the PR description.
2. **A phase author flags it during phase doc authoring** — the phase doc lists the debt under "Risk Assessment" and references this register.
3. **A regular audit** (quarterly) finds it via lint sweep, perf trace, or coverage report. The auditor opens the entry.

### Step 2 — Open a tracker ticket

Every debt entry must have a corresponding ticket in the project tracker:
- Ticket title format: `DEBT-NNN: <title from this file>`
- Ticket body links back to this register file.
- Ticket labels: `tech-debt`, severity label, priority label, owning module.
- Ticket assignee: the **Owner** field from this register.

The ticket exists so that sprint planning surfaces debt in the same backlog as features, not in a parallel hidden list.

### Step 3 — Choose severity

| Severity | Definition | Examples |
|---|---|---|
| **Critical** | Production outage risk, data loss risk, or security vulnerability with known exploit path. Must be resolved within the current sprint. | Hardcoded prod credentials. Schema migration that drops user data on rollback. |
| **High** | User-visible degradation under realistic load, or a refactor blocker for an upcoming phase. Must be resolved by next sprint. | DEBT-005 — sync redirect that breaks under hydration latency. Cache invalidation that fails under burst load. |
| **Medium** | Non-blocking but compounds over time. User-visible only at scale. Must be resolved before public beta. | DEBT-001, DEBT-003, DEBT-004, DEBT-007, DEBT-008, DEBT-009, DEBT-011, DEBT-013. |
| **Low** | Code-quality, DX, or polish item. Resolved when convenient. May ship with v1. | DEBT-002, DEBT-006, DEBT-010, DEBT-012, DEBT-014, DEBT-015. |

### Step 4 — Choose priority

| Priority | Definition |
|---|---|
| **Immediate** | Stop-the-line. Resolve in current sprint. Used only for Critical or breached-SLA High. |
| **Next Sprint** | Plan into the next sprint. Reviewed at sprint planning. |
| **Backlog** | Tracked, not scheduled. Pulled into a sprint when its cleanup phase starts. |

Severity informs priority but does not dictate it. A Medium item might be Next Sprint if its cleanup phase is imminent; a High item might be Backlog if its cleanup phase is months away (but the team must accept the SLA breach risk in writing).

### Step 5 — Reference at resolution

When the cleanup PR lands:
1. PR description includes a section `Closes DEBT-NNN` with a one-line summary of the resolution.
2. PR labels include `debt-resolution`.
3. The PR updates this file:
   - Status → `Resolved`
   - Adds `Date resolved: YYYY-MM-DD`
   - Adds `Resolution PR: #<number>`
4. The Index table is updated.
5. The tracker ticket is closed and links the resolution PR.

Resolved entries are **not deleted**. They stay as a record of the trade. Search by status to filter active debt.

### Step 6 — Quarterly review

Every quarter the Frontend Tech Lead and Engineering Manager sit down for a 90-minute debt review:
1. Walk every Open entry. Confirm severity and priority are still accurate.
2. Promote any High whose SLA was breached (entry > 2 sprints old at Next Sprint) to Immediate.
3. Identify any Backlog entry that is "rotting" — owner has changed, original context is fading — and either schedule it or formally accept it as long-term.
4. Identify any pattern of similar debt entries that suggests a systemic gap (e.g. three entries about cache eviction → time to invest in a cache abstraction).
5. Update this file's `Last updated` and `Severity counts` lines.
6. Post review notes to the engineering channel; archive in `docs/debt-reviews/YYYY-Q.md`.

### Step 7 — Hard rules

- A PR that introduces a shortcut **without** a corresponding debt entry is blocked at review.
- A PR that closes a debt entry but does not update this file is blocked at review (CI check `tool/debt/check_register.sh` parses the PR body for `Closes DEBT-NNN` and verifies the file changed).
- The register is a single file. No per-feature debt lists, no scattered TODO comments. TODO comments in code must reference a DEBT id (`// TODO(DEBT-005): ...`).
- The register is read by every new engineer in onboarding. It is part of the "what is the state of this codebase?" answer.

---

## Severity definitions — examples

To keep the severity ladder consistent, here are concrete examples that calibrate the bands:

### Critical examples (none currently in the register — by design)
- A JWT validation bypass in a release build.
- A migration that does not roll back cleanly and could lose a production tenant's data.
- A third-party SDK that exfiltrates PII without consent.

### High examples
- DEBT-005 — fragile router redirect that will break when hydration latency rises.
- (Hypothetical) A dependency on a deprecated Firebase SDK with a known EOL date.

### Medium examples
- DEBT-001, DEBT-003, DEBT-004, DEBT-007, DEBT-008, DEBT-009, DEBT-011, DEBT-013.
- Common shape: **works for users today, breaks for some users at scale or in adversarial conditions, has a known cleanup phase**.

### Low examples
- DEBT-002, DEBT-006, DEBT-010, DEBT-012, DEBT-014, DEBT-015.
- Common shape: **measurable code-quality or DX improvement, no user impact, can ship with v1**.

---

## Anti-patterns this register prevents

- **Silent debt** — TODO comments scattered across the codebase with no owner and no clock.
- **Dead debt** — items entered once and forgotten because no one reviews the register.
- **Misclassified debt** — Critical issues labeled Medium because no one wants to disrupt the sprint.
- **Debt sprawl** — every reviewer's "I would have done this differently" turning into an entry. The register is for **deliberate trades**, not aesthetic preferences.
- **Resolution without record** — code change lands but the entry stays Open because nobody updated the file.

---

## Changelog

| Version | Date | Change |
|---|---|---|
| v1.0.0 | 2026-05-17 | Initial register with 15 entries pre-populated from foundation phase risk assessments. |

---

**END OF FILE — TECHNICAL_DEBT_REGISTER.md**
