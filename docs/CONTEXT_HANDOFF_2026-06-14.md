# RADHA — Context Handoff (2026-06-14)

Paste this into a fresh context to continue. It is self-contained. Prior sessions did the
mobile subscription/payment/catalog/product convergence + located/hardened the dashboard +
built the master function matrix. **The backend can now be brought up live (Docker is up).**

---

## 0. TL;DR — do this next
1. Wait for the background `pnpm install` (started in the converged worktree) to finish.
2. Bring up the backend (§5) → `GET http://localhost:3000/api/v1/health` returns ok.
3. Live-verify domains against the running backend using the **master matrix** (§6) — every
   row is currently `BLOCKED_EXTERNAL` (static only); flip them to WORKING/PARTIAL/etc.
4. Then mobile **L1 l10n** (subscription/catalog strings × 6 ARB), dashboard **D3/D4**.
Keep each change green; commit per the convention in §7.

---

## 1. Repo & branch map (CRITICAL — read first)
Repo root: `C:/Users/sayan/Downloads/RADHA_UPGRADED_PROJECT_FILES new/RADHA_UPGRADED_PROJECT_FILES`
(the outer `…new/` folder is a non-git wrapper). Remote `origin` =
`github.com/Souvik988/RADHA_UPGRADED_PROJECT_FILES`. **Nothing pushed (CASE C)** — work is on
local branches + bundles.

Two git worktrees, two content lines:
| Worktree path | Branch | Content |
|---|---|---|
| `…/RADHA_UPGRADED_PROJECT_FILES/` | `codex/radha-production-convergence` | **export** tree: `radha_app/` (old Flutter), `radha_backend/`, **`radha_dashboard/`** (the dashboard) |
| `…/radha-production-converged/` | `codex/radha-production-converged` | **canonical monorepo** (= `origin/main` `bd4710b` + sprint work): `apps/mobile/` (Flutter, pkg `radha_mobile`), `server/`, `packages/` |

- **Mobile work + all convergence docs live on the CONVERGED branch** (`apps/mobile`, `server`).
- **The dashboard lives ONLY on the EXPORT branch** (`radha_dashboard/`). Dashboard fixes were
  committed there. (Bringing the dashboard into the monorepo `apps/` is a pending port.)
- `origin/main`'s `apps/owner-dashboard` is an empty placeholder — **not** the dashboard.

## 2. Canonical roots & conventions
- **Mobile:** `radha-production-converged/apps/mobile`, package **`radha_mobile`** (imports
  `package:radha_mobile/...`). Flutter at `C:/src/flutter/bin/flutter.bat` (3.44.0 / Dart 3.12).
- **Backend:** `radha-production-converged/server` (NestJS, feature-complete; 2059 jest per CLAUDE.md).
- **Dashboard:** `RADHA_UPGRADED_PROJECT_FILES/radha_dashboard` (Next.js 15.3 + React 19, npm,
  vitest; `node_modules` present). Wired to `NEXT_PUBLIC_API_BASE_URL → /api/v1`.

## 3. Environment (verified this session)
- Docker UP & healthy: **`radha-postgres` → localhost:5433** (db `radha_dev`), **`radha-redis`
  → localhost:6380**. (Also unrelated `roomance-*` on 5432/6379 — ignore.)
- node v24.15.0, pnpm 8.15.0. **`pnpm install` is RUNNING in the background** in
  `radha-production-converged/` (check its task output before assuming deps are ready).
- No emulator/device; mobile-mcp + playwright MCP servers are disconnected.

## 4. What's DONE & green (do not redo)
**Mobile (converged branch, 227 Flutter tests pass, `analyze --fatal-infos` clean):**
- Catalog browse honest source states (live/offline/unavailable) + retry + telemetry.
- Product detail classified lookup failures (notFound/offline/unauthorized/serverFailure).
- **Payment engine** `apps/mobile/lib/features/subscription/payment/` (CheckoutEngine + sealed
  CheckoutResult + RazorpayAdapter) — 14 tests.
- **Subscription contract**: plural `/subscriptions/*` ApiClient + DTOs (`subscription_status_dto.dart`);
  entitlement_provider derives from `/subscriptions/status` (no hardcoded map).
- **Subscription page**: backend plans (UUID checkout), engine-driven, structured result
  handling, false "GST/cancel anytime" promise removed. 3 widget tests.
- Shared UI: `RadhaBottomNavigation`, `RadhaStatusChip`.
Commits: `9d9814e 8640a51 6a99a8e 86cb725 a1f3b0a 1c9ca8c e7d445e d0530f5 1de9404 7ef5991 9aab91c`.

**Dashboard (export branch, 155 vitest pass, prod-source typecheck clean):**
- D1 fixed: tenant-settings read `session.user.tenantId` (was `/tenants/undefined`).
- D2 fixed: removed dead lead `'converted'` comparison.
- **Demo mode hardened**: `isDemoRequest` returns false in production; `DEMO_MODE` gated by
  `NODE_ENV!=='production'` → **no mock metrics can ship**. Billing already uses canonical
  plural `/subscriptions/*` + `/payments/*` (no mismatch).
Commits: `45a671a` (D1/D2), `a2b48a6` (demo guard).

## 5. Backend bringup (the live unblock) — exact, de-risked steps
**`pnpm install` is DONE (exit 0).** Verified container creds + env var names this session, so
this is turnkey. From `radha-production-converged/`:
```
# 1. Create server/.env from the dev template, then set the DB/Redis block to the
#    ACTUAL radha-postgres container (verified: user=radha pw=radha_dev_password db=radha_dev):
#      (PowerShell)  Copy-Item server\.env.development.example server\.env
#    Then ensure these EXACT values (the backend reads DB_*; migrate.ts also accepts DATABASE_URL):
#      DB_HOST=localhost
#      DB_PORT=5433
#      DB_NAME=radha_dev
#      DB_USER=radha
#      DB_PASSWORD=radha_dev_password
#      DB_SSL=false
#      REDIS_HOST=localhost
#      REDIS_PORT=6380
#      (keep the template's JWT_ACCESS_SECRET/JWT_REFRESH_SECRET dev values)
#      add Razorpay TEST keys: RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET (owner's env)
#    NOTE: the loader in migrate.ts is "first value wins / don't clobber existing" — so if a key
#    appears twice, the FIRST wins. Edit the existing lines in place; don't just append overrides.
#    The config is zod-validated (server/src/config/env.schema.ts) — a missing REQUIRED key fails
#    boot with a clear message; add whatever it names.
# 2. migrate + seed plans (subscriptions need plan rows w/ UUIDs):
cd server
pnpm db:migrate
npx tsx src/db/seeds/subscription-plans.seed.ts     # seed file confirmed present; no db:seed script
# 3. start API in BACKGROUND (start:dev = nest --watch; run detached, never blocking):
#      run_in_background:  pnpm --filter @radha/server start:dev      # PORT=3000
# 4. health:  curl http://localhost:3000/api/v1/health   (+ /health/ready)
```
Gotchas: `@/` path alias via tsconfig-paths; worker/scheduler are separate entry points
(`server:worker`/`server:scheduler`); if a `tsx`/Nest DI metadata error appears, use
`ts-node -r tsconfig-paths/register` (known prior issue). Container `radha-postgres` is on
**5433** (5432 is an unrelated `roomance-postgres` — don't use it).

## 6. Live verification plan (drive from the master matrix)
`docs/RADHA_MASTER_FUNCTION_MATRIX.md` maps 39 mobile routes + 82 ApiClient eps, 33 dashboard
pages + 84 BFF proxies, 52 backend controllers across 8 domains + auth/RBAC. With the backend
up, verify per domain (Phase-6 order): **A Catalog (mobile done) → B Scanner → C Expiry/Tasks →
D Inventory/GRN → E Consumer Safety → F Subscription/Payments (mobile done; do test-mode
Razorpay) → G Reports/OHS → H Profile/Settings/Platform.** For each: hit the endpoint, confirm
mobile + dashboard render real data + loading/empty/error/offline, classify every control, check
role/tenant/entitlement gating, then flip the matrix row + commit.
- **Dashboard live login** uses real backend now (set `DEMO_MODE=false` in dashboard `.env.local`
  or unset, restart `npm run dev`). Create a tenant/user via backend seed/OTP to log in.
- **Test-mode payment**: with Razorpay test keys in `server/.env`, run the subscription upgrade
  on a device/emulator end-to-end → verify `/payments/verify` activates the plan + entitlement
  refresh. (No device this session — needs an emulator.)

## 7. Conventions / gotchas (save debugging time)
- **Flutter tests that build the theme** must `setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false)`
  AND be `testWidgets` (pure `test()` throws on the unbundled font). Tapping below the fold needs
  `await tester.ensureVisible(finder)` first.
- **build_runner** regenerates many `.g.dart`; commit only the semantically-changed ones — the
  rest are **LF/CRLF-only churn**, `git checkout --` them (repo is CRLF; tooling writes LF).
- **Fake ApiClient in tests**: `class _FakeApi implements ApiClient { … noSuchMethod … }` +
  override the few methods; override `apiClientProvider`/`checkoutEngineProvider` in ProviderScope.
- **⚠️ GIT HAZARD**: an external auto-commit/reset tool resets the EXPORT branch to `ba818fd`
  ("add" commits). The converged branch + bundles are unaffected. **After any commit, verify with
  `git cat-file -e HEAD:<file>`**; if orphaned, re-commit.
- Validation gates: mobile `flutter analyze --fatal-infos` + `flutter test --no-pub` (from
  apps/mobile); dashboard `npm run typecheck` + `npm run test` (from radha_dashboard); backend
  `pnpm --filter @radha/server test`.

## 8. Open work (priority)
- **P1 Live verification** of every domain + cross-client sync + test-mode payment (needs backend
  up [§5] + an emulator). Flip master-matrix rows from BLOCKED_EXTERNAL.
- **L1** mobile l10n: subscription_screen + catalog strings are English-only → move to ARB across
  en/hi/ta/te/bn/mr + add an ARB-completeness test. (Achievable without backend.)
- **D3** `radha_dashboard/features/expiry/scope-change.test.tsx` — `scope` type drift (test-only;
  decide if `scope` is an intended field).
- **D4** `npm i -D @playwright/test && npx playwright install` in radha_dashboard → dashboard E2E.
- **Port** `radha_dashboard` into the monorepo `apps/` for one-tree convergence (big, optional).

## 9. Safety artifacts (recovery)
- `../radha-functional-convergence.bundle` (--all) + `../radha-functional-convergence.patch`
- `../radha-codex-local-safety.bundle`, `../radha-codex-format-patches/`
- Restore: `git clone <bundle> <dir>`.

## 10. Doc index (in `radha-production-converged/docs/`)
RADHA_MASTER_FUNCTION_MATRIX · DASHBOARD_DISCOVERY_REPORT · DASHBOARD_INTEGRATION_REPORT ·
FUNCTIONAL_CONVERGENCE_{RECOVERY,BASELINE} · REPOSITORY_CONVERGENCE_REPORT ·
SUBSCRIPTION_PAYMENT_CONTRACT · PAYMENT_STATE_MACHINE · PHASE_3_VALIDATION_REPORT ·
PRODUCT_DETAIL/UI_V2_* (mobile). Memory: `…/.claude/.../memory/ui_migration_v2.md` is the
running ledger.
