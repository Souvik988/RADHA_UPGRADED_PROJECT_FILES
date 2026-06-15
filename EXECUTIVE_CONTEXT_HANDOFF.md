# RADHA Application Context Handoff

Copy-paste this whole file into the next IDE/agent as the first message.
It is self-contained and focused on the application work in this repository.

Author: outgoing executive developer
Date: 2026-06-14
Application code baseline covered here: `0422cc8 feat(mobile): localize select store screen`
Branch: `codex/radha-production-converged`
Canonical worktree for the work described here:
`C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged`

This handoff intentionally covers the application implementation state, recent app changes,
verification gates, and next engineering steps. It excludes unrelated production-history notes.

---

## 0. Executive Role And Quality Bar

You are the executive director and lead developer for RADHA. The owner expects decisive,
production-minded execution, not a menu of options. Make the best reasonable decision, implement it,
verify it with evidence, and report clearly.

Non-negotiables:

1. Live-verify important behavior. Static wiring is not proof that a feature works.
2. Never fabricate product, health, nutrition, pricing, tenant, or dashboard data.
3. Function first, then polish. A beautiful broken screen is still broken.
4. Keep changes scoped. Do not churn stable, tested code to force-fit unrelated work.
5. Leave each logical unit green and committed unless the owner explicitly asks otherwise.

RADHA must be treated as a production system that can grow to 10 million users: tenant-safe,
privacy-first, indexed, observable, and fast.

---

## 1. What RADHA Is

RADHA is a mobile-first retail audit platform for Indian retail teams, plus a consumer product
browse/scan experience. Core capabilities include barcode/EAN scan, product lookup, rule-based
health indicators, expiry tracking, approved-EAN verification, bulk audit sessions, manager-to-staff
tasks, reports, lightweight inventory, GRN, subscriptions, and offline-aware mobile flows.

Out of scope for V1: GST invoicing, POS cart, payment collection, sales ledger, and full accounting.

Primary surfaces:

- Flutter mobile app: `apps/mobile`
- NestJS API/worker/scheduler: `server`
- Shared contracts: `packages/shared-types`
- Owner dashboard exists in the export worktree, not yet converged into the monorepo

---

## 2. Worktree And Git Reality

There are multiple folders under:
`C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new`

Use this worktree for the application work described in this handoff:
`C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged`

Current branch:
`codex/radha-production-converged`

Remote tracking state before this handoff document was updated:
`ahead 23` from `origin/main`

Important: do not push unless the owner asks.

Known dirty files before this handoff update:

- `EXECUTIVE_CONTEXT_HANDOFF.md` - intentionally being updated now
- `apps/mobile/windows/flutter/generated_plugin_registrant.cc` - pre-existing generated change
- `apps/mobile/windows/flutter/generated_plugin_registrant.h` - pre-existing generated change
- `apps/mobile/windows/flutter/generated_plugins.cmake` - pre-existing generated change

Do not stage or revert the Windows generated plugin files unless you intentionally regenerate and
validate the Windows Flutter embedding. They were not part of the localization units.

After every commit, verify important committed files still exist at HEAD with:

```powershell
git cat-file -e HEAD:apps/mobile/lib/features/select_store/select_store_screen.dart
```

This protects against earlier reset/auto-commit hazards seen in the project history.

---

## 3. Environment Notes

Host shell is Windows PowerShell. Use Windows-safe commands.

Mobile work:

```powershell
cd "C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged\apps\mobile"
flutter gen-l10n
flutter analyze --fatal-infos
flutter test
```

Backend work:

```powershell
cd "C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged"
pnpm install
pnpm --filter @radha/shared-types build
cd server
pnpm build
```

Do not run long-lived watchers in foreground agent tools. If a server is needed, run a compiled
server or background process and verify it with HTTP.

---

## 4. Recent Application Work Completed

The last three application units completed in the current continuation were all mobile L1
localization work. They are already committed. Do not redo them.

### 4.1 Product Detail Localization

Commit:
`9a5a7ec localize catalog product detail`

Files changed:

- `apps/mobile/lib/features/catalog/product_detail_screen.dart`
- `apps/mobile/test/features/product/product_detail_screen_test.dart`
- `apps/mobile/lib/l10n/app_en.arb`
- `apps/mobile/lib/l10n/app_hi.arb`
- `apps/mobile/lib/l10n/app_ta.arb`
- `apps/mobile/lib/l10n/app_te.arb`
- `apps/mobile/lib/l10n/app_bn.arb`
- `apps/mobile/lib/l10n/app_mr.arb`
- generated l10n files under `apps/mobile/lib/l10n/generated`

What changed:

- Moved product-detail user-facing copy into `AppLocalizations`.
- Localized product detail section headings, nutrient labels, insight labels, gated-feature copy,
  lookup failure states, save/share snackbars, and appbar copy.
- Refactored copy that had been embedded in constants/tuples so it resolves through `l10n` at build
  time.
- Updated the product detail widget test harness for localization delegates and supported locales.

Verification used for that unit:

- `flutter gen-l10n`
- focused product detail tests
- `flutter analyze --fatal-infos`

### 4.2 Profile Screen Localization

Commit:
`e536a51 feat(mobile): localize profile screen`

Files changed:

- `apps/mobile/lib/features/profile/profile_screen.dart`
- `apps/mobile/test/features/profile/profile_screen_test.dart`
- six ARB source files
- generated l10n files

What changed:

- Moved profile screen account, preferences, about, guest/user names, version text, sign-out dialog,
  and role labels into `AppLocalizations`.
- Reused existing l10n keys where suitable instead of duplicating copy.
- Added role mapping for known backend/user roles.
- Added focused profile widget tests covering localized actions/account state and sign-out
  confirmation.

Verification used for that unit:

- `flutter gen-l10n`
- `flutter test test/l10n/arb_completeness_test.dart test/features/profile/profile_screen_test.dart`
- `flutter analyze --fatal-infos`
- full `flutter test` passed with 236 tests at that point

### 4.3 Select Store Localization

Commit:
`0422cc8 feat(mobile): localize select store screen`

Files changed:

- `apps/mobile/lib/features/select_store/select_store_screen.dart`
- `apps/mobile/test/features/select_store/select_store_screen_test.dart`
- six ARB source files
- generated l10n files

What changed:

- Localized select-store title, heading, helper body, empty state title/body, CTA, snackbar, and
  known role badges.
- Role badge behavior now maps known roles to existing localized profile role labels.
- Unknown role values still fall back to a humanized raw role string so backend drift is not hidden.
- Added focused widget tests for both populated and empty store states.

Verification used for that unit:

```powershell
dart format apps/mobile/lib/features/select_store/select_store_screen.dart apps/mobile/test/features/select_store/select_store_screen_test.dart
flutter gen-l10n
flutter test test/l10n/arb_completeness_test.dart test/features/select_store/select_store_screen_test.dart
flutter analyze --fatal-infos
flutter test
git diff --check -- apps/mobile/lib/features/select_store/select_store_screen.dart apps/mobile/lib/l10n apps/mobile/test/features/select_store/select_store_screen_test.dart
```

Final full mobile gate after this unit:

- `flutter analyze --fatal-infos`: passed
- `flutter test`: 238 tests passed
- `git diff --check`: passed for the scoped select-store diff
- post-commit `git cat-file -e HEAD:<path>` checks: passed

---

## 5. Current Mobile Localization State

The established l10n system:

- Config: `apps/mobile/l10n.yaml`
- ARB source files: `apps/mobile/lib/l10n/app_*.arb`
- Template locale: `apps/mobile/lib/l10n/app_en.arb`
- Generated files: `apps/mobile/lib/l10n/generated`
- Runtime import:
  `package:radha_mobile/l10n/generated/app_localizations.dart`

Pattern to follow inside widgets:

```dart
final l10n = AppLocalizations.of(context);
```

Then use `l10n.keyName` for all user-facing copy.

Already localized in recent work:

- subscription screen and ARB completeness infrastructure
- catalog search screen
- product browse screen
- featured products rail
- catalog product detail screen
- profile screen
- select-store screen

The mobile app now has six supported locales wired through generated l10n:

- English
- Hindi
- Tamil
- Telugu
- Bengali
- Marathi

ARB rule:

- Add every new key to all six ARB files.
- Put `@key` metadata only in `app_en.arb`.
- Keep brand names such as RADHA, OTP, Razorpay, and plan/product names untranslated unless the
  existing copy already localizes them.
- After editing ARBs, run `flutter gen-l10n`.
- Keep `test/l10n/arb_completeness_test.dart` green.

Widget test rule:

Any widget test that pumps a localized screen must include:

```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

---

## 6. Current Validation Evidence

Latest evidence from the current worktree:

- Branch: `codex/radha-production-converged`
- Latest application commit covered: `0422cc8`
- Full mobile test suite: `238` tests passed
- Analyzer: `flutter analyze --fatal-infos` passed
- Select-store scoped diff check: passed
- No app-localization files are left unstaged after the select-store commit

The current remaining dirty files before this handoff update were unrelated to the localization
work except for the handoff file itself.

Use tests as evidence only when they cover the requirement. For backend/API behavior, a green mobile
widget test is not enough; hit the real backend.

---

## 7. Backend And Live Verification Context

Backend is expected to be feature-complete enough for live domain verification, but do not assume a
feature works until it is run.

Important backend facts from the prior context:

- NestJS API lives in `server`
- Shared contracts live in `packages/shared-types`
- The API response envelope is generally `{ success, data, meta }`
- Docker services, if running, use:
  - Postgres on `localhost:5433`
  - Redis on `localhost:6380`
- The compiled backend should be run from `server` with `node dist/main.api` after `pnpm build`
- For live testing, create a tenant with `/api/v1/tenants/onboard`, then OTP-login with dev OTP

Do not use static inspection as final proof for backend domains. For a domain to be called done:

- Hit the endpoint with the correct role/token
- Confirm tenant/store scoping
- Confirm the mobile screen renders real data
- Confirm loading, empty, error, and offline states where applicable
- Confirm entitlement/role gating
- Update the function matrix if the verification status changes

Master matrix:
`docs/RADHA_MASTER_FUNCTION_MATRIX.md`

---

## 8. Production Architecture Direction

The owner's explicit mandate: engineer RADHA to handle **10 million users**, store scanned/inventory/
photo data **with proper indexing**, and keep each subscriber's raw data **private** — the owner
dashboard reads only derived aggregates, never raw user content, because that content is **encrypted
per tenant**; the data owner sees their own data; the platform reaches raw data only through an
audited break-glass door. The codebase already has most seeds — generalize them, do not reinvent.

Backend layering (always on): Controller (transport only, guarded, DTO-validated) → Service (logic,
transactions, audit log) → Repository (tenant/store-scoped, cursor pagination, no layer skipping).
Migrations are immutable — add new numbered SQL files; keep schema↔migration↔docs in sync.

### 8A. Privacy / per-tenant encryption flow (the owner's #1 requirement)

**Flow:** a subscriber uses the app — scans products, uploads photos, manages inventory. That raw
data lands on the server + DB **encrypted**. The owner dashboard CANNOT read the raw user data (it is
ciphertext); it shows only non-sensitive **rollups/aggregates**. The business owner (data owner)
decrypts their own data in-app. The RADHA platform owner reaches raw data only via an explicit,
audited break-glass flow.

**Build as envelope encryption, per tenant — grounded in what exists:**
- A working AES-256-GCM envelope service already exists: `server/src/modules/allergen/services/
  encryption.service.ts` (its comment says "in production this would delegate to AWS KMS or a vault").
  **Generalize it** into `integrations/crypto/` (or `kms/`) `TenantCryptoService` behind a typed
  interface + fake-for-tests (integrations-wrapper rule). See directive §20 (versioned keys, rotation,
  re-encryption jobs, authenticated tenant/resource context, audit logging).
- **Key hierarchy (envelope):** one master KEK in **AWS KMS** (never leaves KMS). On tenant creation,
  generate a per-tenant **DEK**; store it **KEK-wrapped** as a new `tenants.encrypted_dek` column (new
  numbered migration). Unwrap the DEK via KMS only inside a tenant-scoped authenticated request;
  AES-256-GCM with a fresh 96-bit IV per record; store `iv|authTag|ciphertext`; never persist the
  plaintext DEK.
- **Encrypt the sensitive UGC, NOT the derived metrics.** Encrypt at rest: photo/scan **images**
  (store in **S3 with SSE-KMS** under a per-tenant key context; the `media_assets` row keeps only the
  S3 key + encrypted metadata), OCR transcripts, sensitive inventory notes/free text, PII. Do NOT
  encrypt the rollups (counts, KPIs, health distributions, low-stock counts, scan volumes) — the
  worker/scheduler computes them into the **already-existing** rollup tables (`operational_health_
  scores`, `owner_daily_metrics`, `consumer_weekly_digests`), which carry no raw user content. Do not
  encrypt fields required for indexed filtering unless a deliberate search-token design exists.
- **Dashboard reads ONLY rollups.** This both keeps raw subscriber data private from the platform and
  **fixes the "bulky dashboard"** problem — it reads small pre-aggregated rows, not millions of raw
  inventory/scan records. Make it a hard rule: dashboard BFF/proxies hit rollup/aggregate endpoints,
  never endpoints returning decrypted UGC.
- **Data-owner access:** the mobile app authenticates as the tenant; the backend unwraps that tenant's
  DEK and decrypts on their behalf for their own tenant-scoped requests → full fidelity for them.
- **Platform break-glass:** reuse the existing **`admin-impersonation`** module (guards + middleware +
  audit). Raw-data access requires elevated admin auth → explicit time-limited grant → mandatory audit
  entry (who/when/which tenant/why). **Default: platform cannot read raw tenant content.**

### 8B. Database & indexing strategy (store scanned/inventory data the right way)

The tenant-scoped index convention is already heavily in place (~296 index declarations). Hold/extend:
- **Every index leads with `tenant_id`** (then `store_id` where store-scoped), then the hot filter/sort
  column. Hot tables: `scan_items`, `scan_sessions`, `stock_movements`, `inventory_items`,
  `expiry_records`, `tasks`, `task_assignments`, `grn`, `audit_logs`, `app_usage_events`,
  `website_events`, `media_assets`, `notifications`, `products`. Composite shapes:
  `(tenant_id, store_id, scanned_at DESC)`, `(tenant_id, store_id, status)`,
  `(tenant_id, store_id, is_low_stock)`, `(tenant_id, ean)`.
- **Partial indexes** for hot predicates: `WHERE deleted_at IS NULL`, `WHERE resolved_at IS NULL`
  (already on `low_stock_alerts`), `WHERE status='active'`. **FK indexes** on every foreign key.
- **Search:** `products.search_tsv` (tsvector) already has GIN + a trigram name index — use them; never
  `LIKE '%x%'` scans. **Keyset/cursor pagination everywhere** — never `OFFSET` on large tables.
- **Partition the append-only giants** by time when volume warrants: declarative RANGE partitioning on
  `created_at`/`scanned_at` for `scan_items`, `audit_logs`, `stock_movements`, `*_usage_events`
  (monthly partitions + per-partition indexes → cheap pruning + retention drops).
- **Process:** run `EXPLAIN ANALYZE` before/after each index migration (evidence, not guesswork); add a
  new numbered file `00NN_scale_indexes.sql`; create indexes `CONCURRENTLY` in prod; keep
  `DATABASE_ARCHITECTURE.md` in sync.

### 8C. Write path & 10M-user topology

- **Stateless API** behind a load balancer, horizontally scaled. The `worker` + `scheduler` processes
  already exist (`main.worker.ts`/`main.scheduler.ts`, gated by `RADHA_PROCESS`) — scale independently.
  All heavy work (image processing, OCR, report generation, **rollups**, notifications) is async on
  **BullMQ** (idempotent consumers + DLQ + retry).
- **Writes:** batch/`COPY` for bulk imports, multi-row inserts, write-behind via BullMQ for non-critical
  writes, **idempotency** on all create endpoints (`idempotency_records` table + module exist). No N+1.
- **Postgres:** managed **RDS** + **PgBouncer** (transaction pooling) + **read replicas** (dashboard/
  report reads → replicas, writes → primary; replica-lag fallback). Size `DB_MAX_CONNECTIONS` for
  PgBouncer. **Redis/ElastiCache:** short-TTL caches (entitlements, plans, rollups, product lookups —
  `off_cache` exists), tenant-namespaced keys, stampede prevention; correctness must never depend on
  cache availability. **Media:** S3 presigned direct upload + CloudFront; DB stores S3 keys only.
- **Budgets:** indexed API reads p95 < 200ms; mobile 60fps; cold start < 1.5s. Targets are not
  achievements until measured (directive §23) — record p50/p95/p99 from staging load tests.

### 8D. Dashboard ↔ backend connection (must be proper + best)

Both clients hit `/api/v1`. Mobile = `apps/mobile` ApiClient; dashboard = `radha_dashboard` BFF proxy
routes (`app/api/**`). Keep shapes in `@radha/shared-types` + `API_CONTRACTS.md` (the `contracts:check`
gate enforces zero unexplained drift). Dashboard reads **rollups only** (8A) → fast + privacy-safe.
`DEMO_MODE` must be **off** in prod. Verify the dashboard live the same way as mobile.

---

## 9. Recommended Next Work

Start with bounded, green application units.

### P0: Continue Mobile L1 Localization Sweep

The product detail, profile, and select-store screens are done. Continue with the remaining screens
that still have user-facing English outside ARB.

Suggested discovery commands:

```powershell
cd "C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged\apps\mobile"
rg '"[A-Z][^"]{2,}"' lib/features
rg "Text\\(|SnackBar|Dialog|AppBar|label:|hintText:|helperText:" lib/features
```

Pick one screen or feature cluster at a time. For each unit:

1. Inspect the screen and its tests.
2. Add all new keys to six ARB files.
3. Add English metadata only in `app_en.arb`.
4. Run `flutter gen-l10n`.
5. Update widget tests with localization delegates where needed.
6. Run focused tests plus `test/l10n/arb_completeness_test.dart`.
7. Run `flutter analyze --fatal-infos`.
8. Run full `flutter test` for broad safety when the change touches shared l10n/generated code.
9. Commit the logical unit.

Likely next feature areas to inspect:

- scan flows
- expiry flows
- inventory and GRN flows
- reports
- tasks
- settings/support
- remaining dialogs/snackbars/empty states

### P1: Live-Verify Functional Domains

After L1 localization is no longer the active thread, move domain-by-domain through the master
function matrix:

`docs/RADHA_MASTER_FUNCTION_MATRIX.md`

For each domain, verify against the live backend and, where applicable, mobile UI. Commit fixes in
small units.

### P2: Production Hardening

Once core functional behavior is live-verified:

- tenant encryption/KMS abstraction
- rollups-only dashboard data access
- high-volume index migration review
- queue idempotency and DLQ review
- observability and launch gates

### P3: Owner Dashboard Convergence

The dashboard lives in the export worktree today. Do not assume it is in this monorepo until it has
been intentionally ported. When owner-dashboard work resumes, verify real backend login and data
reads with demo mode off.

---

## 10. Commit And Verification Discipline

Use conventional commits:

```text
feat(mobile): localize <screen name>
fix(server): <specific runtime defect>
docs: refresh application context handoff
```

Commit body should explain why the change exists, not just what files changed.

End commits with:

```text
Co-Authored-By: Codex <codex@openai.com>
```

Before finalizing any unit:

```powershell
git status --short --branch
git diff --check -- <scoped paths>
```

After committing:

```powershell
git status --short --branch
git show --stat --oneline --name-only HEAD
git cat-file -e HEAD:<important-file>
```

Do not stage unrelated dirty files. Current unrelated dirty files are the Windows Flutter generated
plugin files listed in section 2.

---

## 11. How To Think While Continuing

RADHA is not a prototype anymore. Treat it like a serious Indian retail product:

- Keep the backend as the source of truth.
- Keep mobile and dashboard clients honest to backend contracts.
- Prefer evidence over confidence.
- Prefer one green committed unit over a large unverified batch.
- Keep localization natural in all six locales.
- Build all states: loading, empty, error, offline, success.
- Never hide missing data behind confident-looking placeholder copy.
- Preserve user trust and tenant privacy.

Immediate next action for the next developer:

1. Confirm the worktree status.
2. Do not touch the unrelated Windows generated plugin files.
3. Start the next mobile L1 localization screen with the ARB pattern above, or continue live-domain
   verification if localization is paused by the owner.

---

## 12. Definition of Done — "100% production-grade" (the owner's bar)

The owner's standard: the app is complete only when **every page, every function, every button, every
front-end and UI is production-grade with no mistakes**. Do not declare a screen, feature, or the
product "done" until all of the following hold for it. Quality is never compromised to move faster.

**Per screen / feature (all must hold):**
- Every control classified and working: navigation, button, form, search, filter, sort, pagination,
  save, share, retry, delete, export, payment, permission action. **No dead buttons. No blank screens.**
- Every state designed and correct: loading, refreshing-with-prior-data, success, empty, no-results,
  offline, timeout, unauthorized, forbidden, validation error, conflict, rate-limited, server error,
  retry, partial failure. Never render blank UI for a meaningful failure; never hide missing data behind
  confident placeholder copy.
- **No fabricated data** — no invented health/nutrition, no guessed EAN, no mock plan, no placeholder
  metric in a production path.
- Every mutation prevents duplicate submission (idempotent); every failure offers the correct recovery.
- Fully localized in all six locales (en/hi/ta/te/bn/mr), natural translations, no visible raw wire
  values, text scales 1.0/1.3/2.0 hold.
- Accessibility: semantics/labels, focus, target size, contrast, no colour-only meaning, TalkBack pass.
- Tuned motion/haptics, 60fps-preserving transitions, reduced-motion honored, consistent RADHA visual
  language. No generic Material defaults.
- Backend contract correct (`contracts:check` green); tenant/store/role/entitlement gating correct.
- Regression test for every repaired behaviour; the relevant suites stay green.
- **Live-verified** on the running backend (and on an Android device once available) — not just mocked
  widget tests.

**The product is "100% complete against agreed scope and release gates" only when the §28 gate of the
master directive is met** (zero unexplained contract drift, zero dead controls, zero P0/P1, critical
suites pass, Android critical journeys pass, dashboard Playwright passes, cross-client sync passes,
Razorpay test-mode passes, six-locale coverage passes, critical a11y zero, security blockers zero,
observability operational, privacy controls implemented, performance evidence exists, AWS staging
passes, backup-restore passes, rollback passes, release artifacts build, work pushed). Track the
**calculated** score in `docs/executive/RADHA_COMPLETION_SCORECARD.md` — never a flattering round
number. Report the real percentage and the blocker until every gate is genuinely met.

---

## 13. Session-End Handoff Discipline (STANDING RULE — do this every time)

**Whenever a working session or daily limit is about to end, ALWAYS produce a best-quality handoff
before stopping.** This is a permanent rule, not a one-off. A future session (in any IDE) must be able
to resume at full context and the same quality bar without re-auditing finished work.

On every session wind-down:
1. Finish or cleanly checkpoint the current unit — never leave a knowingly broken tree.
2. Update the program control plane in `docs/executive/`: `PROGRAM_STATE.json` (branch, commit,
   active/completed waves, test counts, defect counts, blockers, **calculated completion score**,
   timestamp), `EVIDENCE_LEDGER.md` (verified vs assumed vs external-blocked — never upgrade without
   evidence), `DEFECT_REGISTER.md`, `DECISION_LOG.md`, `OWNER_ACTIONS_REQUIRED.md`, and
   **`NEXT_RESUME_PROMPT.md`** (the exact, paste-ready prompt that lets a fresh session continue
   without re-auditing).
3. Refresh this file (`EXECUTIVE_CONTEXT_HANDOFF.md`) if architecture/direction changed.
4. State plainly **what is done (with evidence)** and **what remains** (prioritized, next concrete unit
   named).
5. Commit the handoff as its own unit and **push** (`Co-Authored-By: Codex <codex@openai.com>`), then
   verify with `git cat-file -e HEAD:<file>`.

The handoff is itself held to the production-grade bar (§12): accurate, evidence-backed, honest about
gaps, and immediately actionable. Quality is never compromised — including the quality of the handoff.
