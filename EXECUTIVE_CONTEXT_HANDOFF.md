# RADHA — Executive Context Handoff
> **For the incoming executive developer.** Paste this whole file into your new IDE/agent as the
> first message. It is self-contained: read it top-to-bottom once, then start at §10 (Roadmap).
> Author: outgoing executive developer. Date: **2026-06-14**. Branch HEAD at handoff: **`0742d93`**.

---

## 0. Who you are, and the bar you hold

You are the **executive director AND lead developer** of RADHA. You do not wait to be told what to
build — you make decisions, you verify with evidence, and you ship best-in-class work. The owner
(non-technical, communicates fast/voice-to-text, infer intent) wants **decisions made, not menus**,
and **best-in-class output, not the safe/cheap option**. When something fails, you fix it and report
back — you don't surface a list of options.

**The five non-negotiables (this is the "quality of working" you must match or exceed):**

1. **Live-verify everything. Never trust "it looks wired."** The single biggest lesson of this
   project: a static audit (code is present, imports look right, contracts match) marked five whole
   features "WIRED" that were **completely broken at runtime**. They were only caught by *actually
   running the backend and hitting the endpoints*. Static green ≠ working. Build it, run it, hit it,
   look at the real output. (See §6 for the methodology and the re-runnable verification tool.)
2. **No fabricated data, ever.** No invented nutrition numbers, no guessed EANs, no placeholder
   metrics shipped as if real, no health claim on unrated items. If the data isn't there, show an
   honest empty/locked state. The owner cares about this deeply — a misleading number is worse than
   a clear "we don't have this yet."
3. **Function before decoration. But then make it beautiful.** Get the structure working and proven
   first; visuals on top of broken functions are meaningless. Once it works, every screen gets tuned
   motion/haptics + designed empty/error/loading/offline states. No generic Material defaults.
4. **Don't churn polished, tested code to force-fit something.** If an asset/feature needs a new
   surface, build the surface deliberately — don't jam it into a screen that already works well and
   has passing tests. Minimal, surgical, correct.
5. **Keep every change green and commit it.** Each unit: make the change → run the gate (§7) → commit
   with a conventional message. Never leave a half-localized screen or a broken build. Small,
   reviewable, green commits.

---

## 1. What RADHA is (one paragraph)

**RADHA = Retail Assistant for Data, Health & Audits** — a mobile-first retail-audit platform for
Indian retail teams + a consumer "know what you eat" browse/scan experience. Capabilities: barcode/EAN
scan + product lookup (Open Food Facts fallback), rule-based health indicators, expiry tracking,
approved-EAN verification, bulk audit scan sessions, manager→staff tasks, Excel/PDF reports +
dashboards, lightweight inventory + GRN, subscriptions (3-month trial; ₹49/99/199), free-first
AI/OCR. **Out of scope (V1):** GST invoicing, POS cart, payment collection, sales ledger, full
accounting. Surfaces: **Flutter app** (`apps/mobile`) · marketing site (not started) · private owner
dashboard (`radha_dashboard`, lives on the export branch) · **NestJS API+Worker+Scheduler** (`server/`).

---

## 2. Where everything lives (READ FIRST — there are two git worktrees)

- **Outer folder** `…/RADHA_UPGRADED_PROJECT_FILES new/` is a **non-git wrapper** (just the CWD).
- **Canonical monorepo (do all current work here):**
  `…/RADHA_UPGRADED_PROJECT_FILES new/radha-production-converged/`
  branch **`codex/radha-production-converged`**. Contains `apps/mobile/` (Flutter, package
  `radha_mobile`), `server/` (NestJS), `packages/shared-types/`.
- **Export worktree** `…/RADHA_UPGRADED_PROJECT_FILES new/RADHA_UPGRADED_PROJECT_FILES/`
  branch `codex/radha-production-convergence`. Contains **`radha_dashboard/`** (Next.js 15.3 owner
  dashboard) — **the dashboard lives ONLY here**, not in the monorepo yet.
- Remote `origin` = `github.com/Souvik988/RADHA_UPGRADED_PROJECT_FILES`. **Nothing is pushed** — all
  work is local commits on the two branches. (Pushing is the owner's call; don't push unless asked.)
- Canonical agent guide: `radha-production-converged/CLAUDE.md` (full engineering guardrails).
- The master status map you drive repairs from: **`radha-production-converged/docs/RADHA_MASTER_FUNCTION_MATRIX.md`**.

**⚠️ GIT HAZARD:** an external auto-commit/reset tool has been seen resetting the **export** branch.
The converged branch + bundles are unaffected. After any commit, verify it stuck:
`git cat-file -e HEAD:<path/to/file>`. Safety bundles exist at `…/radha-functional-convergence.bundle`.

---

## 3. Environment + bring-up (de-risked recipe — this is turnkey, follow exactly)

- **Host:** Windows 11, shell is **PowerShell** (`;` to chain, `$env:VAR`, `$null`). A Bash tool is
  also available. **Never** run watchers/dev-servers/`--watch` in a blocking foreground tool — run
  them in the background.
- **Toolchain:** Node v24, pnpm 8.15.0 (`corepack`/repo-pinned), Flutter at
  **`C:/src/flutter/bin/flutter.bat`** (3.44 / Dart 3.12).
- **Docker (already up & healthy):** `radha-postgres` → `localhost:5433` (db `radha_dev`, user
  `radha`, pw `radha_dev_password`), `radha-redis` → `localhost:6380`. *(Ignore the unrelated
  `roomance-*` containers on 5432/6379.)*

### Bring the backend up live (the unblock — the handoff that preceded me got this WRONG; do this):
```powershell
cd radha-production-converged
pnpm install                                  # workspaces
pnpm --filter @radha/shared-types build       # ❗ CRITICAL: install does NOT build this; without
                                              #   it tsc fails with 12 "Cannot find module
                                              #   '@radha/shared-types'" errors and the server won't boot
# server/.env — create it with the REAL container creds + the init-only salt:
#   NODE_ENV=development  PORT=3000
#   DB_HOST=localhost DB_PORT=5433 DB_NAME=radha_dev DB_USER=radha DB_PASSWORD=radha_dev_password DB_SSL=false
#   REDIS_HOST=localhost REDIS_PORT=6380
#   SMS_PROVIDER=mock                          # OTP is returned in the API response (devOtp) in dev
#   JWT_ACCESS_SECRET=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
#   JWT_REFRESH_SECRET=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
#   LOG_FORMAT=pretty LOG_LEVEL=debug
#   ANALYTICS_HASH_SALT=radha_dev_analytics_salt_0123456789_abcdef   # ❗ NOT in the zod schema; the
#                                              #   analytics module's onModuleInit hard-requires >=32
#                                              #   chars. Missing it passes env-validation then CRASHES
#                                              #   Nest bootstrap with AnalyticsSaltMissingError.
#   RAZORPAY_KEY_ID=  RAZORPAY_KEY_SECRET=  RAZORPAY_WEBHOOK_SECRET=  # blank => deterministic mock; boots fine
cd server
pnpm db:migrate                               # all 31 migrations already applied; idempotent
npx tsx src/db/seeds/subscription-plans.seed.ts   # seeds 4 plans + 44 entitlements (needed for /subscriptions)
pnpm build                                    # nest build + tsc-alias (rewrites @/ and @radha/shared-types in dist)
# Run the COMPILED dist, NOT `nest start --watch` (watch is ~3 min/compile and flaky on Windows):
#   node dist/main.api      (run in background; boots in seconds)
```
Health checks: `GET http://localhost:3000/api/v1/health` → `{"status":"ok"}`,
`GET /api/v1/health/ready` → `{database:"ok"}`. (A non-fatal `bullmq.init.failed` log line is fine —
Redis queues degrade but the REST API serves. The API wraps every response as `{success,data,meta}`.)

> **Backend is running right now** on `:3000` (HEAD `0742d93`). If you restart it: `pnpm build` then
> `node dist/main.api`. To re-pick-up source changes you must rebuild (dist is compiled, not watched).

---

## 4. How to get an authenticated session for live testing (no UI needed)

Dev mode hands you everything over HTTP. All bodies are `{success,data,meta}` — read `.data`.
1. `POST /api/v1/tenants/onboard` *(public)* with `{businessName, subdomain, ownerName, email,
   mobile, storeName}` (mobile = a **bare 10-digit** Indian number starting 6–9) → creates
   tenant + **owner** user + store + admin store-access. As of D9 it also starts the trial subscription.
2. `POST /api/v1/auth/otp/request {mobile, platform:"mobile"}` → response `.data.devOtp` + `.data.requestId`.
3. `POST /api/v1/auth/otp/verify {mobile, otp, requestId}` → `.data.accessToken` (role=owner, real tenant+store).
   - OTP-login with a *fresh* mobile (never onboarded) instead → a **consumer** token (no tenant).
4. Send `Authorization: Bearer <token>`. Owner token unlocks all tenant-scoped domains; consumer
   token is for the consumer/catalog surface.

---

## 5. What I shipped this session (7 commits — do NOT redo) + prior state

**Backend — brought live + 5 real defects fixed, live-verified 38/38:**
- `d1826c4` **D5–D8**: `InventoryModule` & `ClientDashboardModule` were defined but **never imported**
  in `app.module.ts` → all `/inventory/*` and `/dashboard` KPI routes 404'd. Wired both. · `consumer`
  role lacked `products:read` → consumer catalog browse + `/products/lookup/:ean` returned 403
  (mobile's fake-ApiClient tests never hit the real guard) → granted it in `role-permissions.map.ts`.
  · `client-dashboard kpi.service` counted `products.is_active` (a column that doesn't exist; also not
  store-scoped) → `/dashboard` + `/dashboard/kpis` **500** → rewrote to store-scoped
  `inventory_items.is_low_stock`.
- `38c5675` **D9**: public `tenants/onboard` never called `startTrial` → `/subscriptions/status` 404
  for self-service tenants → now calls `SubscriptionsService.startTrial` post-commit (TenantsModule
  imports SubscriptionsModule), mirroring `business-activation`. Verified live (returns `trial`).

**Mobile L1 localization (each: 6 ARB locales en/hi/ta/te/bn/mr + AppLocalizations wiring, green):**
- `52ce51c` subscription_screen + a reusable **JSON ARB-completeness test**
  (`apps/mobile/test/l10n/arb_completeness_test.dart`) that fails CI if any locale drifts.
- `27ade54` catalog_search_screen · `4c26498` product_browse_screen · `0742d93` featured_rail
  → **the entire catalog *browse* cluster is now localized.**

**Assets:** `27fee0f` wired 3 previously-unused v3 assets (2 product-detail health badges driven by
**real** nutrition fields `transFat`/`containsAllergens`; the consumer-home "RADHA Plus" promo banner).

**Verification gates passing at handoff:** backend live **38/38**; tenant spec 12/12; mobile
**`flutter test` 234/234**; `flutter analyze --fatal-infos` clean.

**Prior work (already built before this session — trust the filesystem + a fresh build over any stale
status table):** backend is feature-complete (~43 modules, 31 migrations, 2059 jest); mobile is a
substantial Flutter app (~25 feature folders, 6 locales, scanner/OCR/browse/subscription/payment all
built); the owner dashboard exists on the export branch (Next.js, ~155 vitest). The owner generated a
v3 art set (Mor mascot scenes, state illos, banners, onboarding, health badges, category cutouts) —
all 40 files are present under `apps/mobile/assets/v2/` and bundled.

---

## 6. THE methodology (internalize this — it's how you find what's actually broken)

The `docs/RADHA_MASTER_FUNCTION_MATRIX.md` cross-maps 39 mobile routes + 82 ApiClient endpoints, 33
dashboard pages + 84 BFF proxies, 52 backend controllers across 8 domains + auth/RBAC. The static
audit marked things "WIRED" that were broken. **Your job is to flip every row from static-WIRED to
LIVE-VERIFIED** by running the real stack.

**The re-runnable live sweep:** there is a Node script (Node 24 has global `fetch`) that onboards a
tenant, OTP-logs-in a consumer + owner, and probes a representative endpoint per domain, printing a
PASS/FAIL table. It lived at `C:\Users\sayan\AppData\Local\Temp\radha-verify.mjs` (a temp file — it
may be cleared; **if so, recreate it** from the recipe in §4: onboard → login → loop GETs with the
token, unwrap `.data`, print status). Run with `node <path>` while the backend is up. Current result:
**38/38**. Use it (or rebuild it) after any backend change.

For a domain to be "done": hit the endpoint with the right role, confirm the mobile screen AND
dashboard page render real data + all four states (loading/empty/error/offline), classify every
control (button/filter/export), check role/tenant/entitlement gating, then update the matrix row +
commit.

---

## 7. Validation gates (run before declaring anything done)

- **Backend:** from `server/` → `pnpm build` (tsc clean) + targeted `npx jest <path> --runInBand`
  (full `pnpm test` = 2059 tests, slow; run targeted unless finishing a phase). Then restart
  `node dist/main.api` and re-run the live sweep (§6).
  - *Test note:* the machine is loaded (backend + Docker), so bcrypt-heavy jest suites can hit the 5s
    timeout under parallel load — that's a CONTENTION flake, not a real failure. Re-run the suite
    `--runInBand` to confirm; it passes alone.
- **Mobile:** from `apps/mobile/` →
  `C:/src/flutter/bin/flutter.bat analyze --fatal-infos` (must be "No issues found!") **and**
  `C:/src/flutter/bin/flutter.bat test` (234/234 at handoff; keep it ≥ that).

---

## 8. Conventions you MUST follow (so your work is consistent with mine)

**Localization (the ARB pattern I established — follow it exactly):**
- l10n is `flutter gen-l10n` driven; config in `apps/mobile/l10n.yaml`; ARBs in `apps/mobile/lib/l10n/`
  (`app_en.arb` is the template). Idiom in screens: `final l10n = AppLocalizations.of(context);` then
  `l10n.keyName` (import `package:radha_mobile/l10n/generated/app_localizations.dart`).
- To add strings: add `"key": "value"` to **all 6** ARB files (insert before the `"appName"` line is the
  uniform anchor I used). Put `@key` metadata (`description` + `placeholders`) **only in `app_en.arb`**.
  Params: `"{name}"` with `placeholders: { name: { type: "String"|"int" } }`. Plurals (used by the
  app): `"{n, plural, =1{...} other{{n} ...}}"`. Keep brand marks (RADHA, Razorpay, OTP) untranslated.
  Then run `C:/src/flutter/bin/flutter.bat gen-l10n`.
- **Translate properly** into hi/ta/te/bn/mr — natural, formal-imperative register matching the
  existing ~285 keys; don't leave English in non-en locales. The `arb_completeness_test.dart` will
  FAIL the build if a locale is missing a key — that's your safety net; keep it green.
- **Test infra:** any widget test that pumps a now-localized screen must add
  `localizationsDelegates: AppLocalizations.localizationsDelegates` + `supportedLocales:
  AppLocalizations.supportedLocales` to its `MaterialApp` (I did this for subscription/catalog/home
  tests — do it for any new one).

**Backend layering (from CLAUDE.md, always-on):** Controller (transport-only, DTO-validated,
guarded) → Service (logic + transaction + audit-log) → Repository (tenant/store-scoped,
cursor-paginated, no `SELECT *`, indexes lead with `tenant_id`). External providers only via
`integrations/*`. Migrations are immutable — add new numbered SQL files. No hardcoded secrets, never
log PII. BullMQ consumers idempotent + DLQ + retry.

**Commits:** conventional (`feat(mobile): …`, `fix(server): …`), one logical unit each, body explains
the *why*, end with `Co-Authored-By: …`. After committing, `git cat-file -e HEAD:<file>` to defeat the
reset hazard. Note: build_runner/gen-l10n regenerate files — commit the semantically-changed ones;
the repo is CRLF and tooling writes LF, so expect harmless line-ending warnings.

**Flutter gotchas:** tests that build the theme need
`setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false)` and must be `testWidgets`. Tapping
below the fold needs `await tester.ensureVisible(finder)` first. `ButtonSegment`/widget lists that
were `const` can't hold `l10n.x` — drop the `const` (keep `const` on the inner Icons).

---

## 9. The owner's v3 assets — status

All 40 files are present under `apps/mobile/assets/v2/` and declared in `pubspec.yaml`; `RadhaAssets`
(`lib/design/app_assets.dart`) already maps them. **~34 are integrated** (referenced + now rendering;
3 newly wired this session). **6 remain UNUSED because they need new surfaces** (don't force-fit them):
- `morSceneOffline` + `stateOffline` → a **dedicated full-screen offline state** (today there's only a
  32px connectivity banner, whose own comment says the full Mor-offline hero "belongs on a dedicated
  offline surface"). Build that surface.
- `onboardHealth` / `onboardAudit` / `onboardGrowth` → **illustrated onboarding capability pages**
  (today page 2 is plain Material-icon rows; restructure into illustrated value pages — design pass).
- `splashLockup` → an alternate splash lockup (the current splash is already polished + animated +
  tested; only swap if you intentionally redesign it). The 4 Mor *sheets*
  (turnaround/expressions/glyph/parts) are design references — correctly NOT bundled.

---

## 10. ROADMAP — what to do next, in priority order (start here)

**P0 — Finish L1 localization (the thread I was on; do this first, it's bounded & high-value):**
- `apps/mobile/lib/features/catalog/product_detail_screen.dart` — the **last** catalog screen, ~49
  hardcoded strings across 1830 lines: section headers (Key nutrients / All nutrients / For you /
  What should concern you), the **nutrient-label tuples** (Energy/Total Fat/Carbohydrates/Protein/
  Fibre/Sodium/Total Sugars — these are in `const`/tuple lists, refactor to resolve `l10n` in build),
  insight labels, gated-feature copy (Ingredient deep-dive), lookup-failure states (notFound/offline/
  unauthorized/serverFailure), save/share snackbars, appbar. Follow the §8 ARB pattern. It's large —
  do it as one focused unit; add the localizationsDelegates to its test (`product_detail_screen_test`).
- Then sweep any remaining English in mobile (scan/expiry/inventory/grn/reports/profile screens) the
  same way until every user-facing string is in ARB and the completeness test still passes.

**P1 — Live-verify + repair every domain against the running backend (the core mandate):**
- Re-run / rebuild the live sweep (§6). Then go domain-by-domain (matrix order A→H): for each, drive
  the **mobile app** (needs an emulator — `flutter run`; the package is `com.radha.radha_mobile`,
  adb at `$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`) AND the **dashboard** against the
  live backend, confirm real data + all 4 states + control classification + role/tenant/entitlement
  gating, fix what's broken, flip the matrix row, commit. Cross-client sync (mobile write →
  dashboard reflects) is part of "done."
- **Test-mode payment** (still BLOCKED): add the owner's Razorpay TEST keys to `server/.env`, run the
  subscription upgrade end-to-end on a device → verify `/payments/verify` activates the plan +
  entitlement refresh.

**P2 — Build the 6 unused-asset surfaces (§9)** — dedicated offline screen, illustrated onboarding,
(optionally) splash lockup. Designed, not force-fit. Every new screen gets the 4 states + tuned motion.

**P3 — Dashboard (export worktree `radha_dashboard/`):** D3 (`expiry/scope-change.test.tsx` scope
type drift — decide if `scope` is an intended field), D4 (`npm i -D @playwright/test && npx playwright
install` → wire dashboard E2E). Set `DEMO_MODE=false` and verify live login against the backend.

**P4 (big, optional):** port `radha_dashboard` into the monorepo `apps/owner-dashboard` for one-tree
convergence; then marketing site; then AWS prod deploy (RDS/ElastiCache/S3/CloudFront — a
`DEPLOY_AWS.md` runbook + Dockerfiles already exist) + RDS backups.

---

## 11. How to think (executive direction)

- **The backend is the source of truth.** Mobile + dashboard must derive everything from it (plans,
  entitlements, health, prices) — never hardcode a plan→feature map or a fabricated number.
- **Move in green, committed units.** A change that isn't verified + committed didn't happen. Prefer
  many small proven commits over one big unverified one.
- **When you find a defect, fix the class of it, not just the instance.** (Example: the consumer
  `products:read` fix unblocked browse, lookup, AND alternatives — one permission, whole flow.)
- **Be honest in docs and reports.** If a test was skipped, say so. If something needs an emulator you
  don't have, say so and do the parts you can. Update `docs/RADHA_MASTER_FUNCTION_MATRIX.md` as you go.
- **Match the craft:** premium feel, 60fps, designed states everywhere, tuned motion/haptics, no
  generic defaults, accurate localization in all 6 languages. This app is meant to be best-in-class
  Indian retail software. Build like it.

> Start now: confirm the gate is green (§7), bring the backend up if it isn't (§3), then take P0
> (`product_detail_screen` localization) to completion as your first committed unit. Go hard.
