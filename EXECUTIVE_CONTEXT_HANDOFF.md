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

The owner wants the application engineered for 10 million users and privacy by design.

Core architecture principles:

- Tenant data isolation is mandatory.
- Raw subscriber/user generated data must not be exposed to the platform dashboard by default.
- Dashboard and reports should read derived rollups/aggregates, not raw tenant content.
- High-volume tables need tenant-leading indexes and cursor/keyset pagination.
- Heavy work belongs in worker/scheduler queues, not synchronous mobile-facing requests.
- No fabricated metrics, mock plans, or placeholder product claims in production paths.

Backend layering rule:

- Controller: transport only, guarded, DTO-validated
- Service: business logic, transactions, audit logging
- Repository: tenant/store-scoped data access, cursor pagination, no layer skipping

Migration rule:

- Existing migrations are immutable.
- Add new numbered SQL migrations.
- Keep schema, migrations, and docs in sync.

Privacy/scaling roadmap to preserve:

- Generalize existing AES-256-GCM style encryption into a proper tenant crypto/KMS abstraction.
- Store sensitive raw UGC encrypted per tenant.
- Keep non-sensitive derived rollups queryable for the owner dashboard.
- Gate any platform raw-data access behind explicit audited break-glass/admin impersonation.
- Add or verify tenant-leading composite/partial indexes for scans, inventory, expiry, tasks, GRN,
  audit logs, usage events, media metadata, and products.

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
