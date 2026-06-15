# RADHA Worktree And Commit Recovery Report

Date: 2026-06-15

## Executive Decision

Canonical continuation target: `codex/radha-final-convergence` in
`C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged`.

Starting canonical HEAD for this recovery pass:
`cc7834d docs(executive): full server-side Razorpay flow live-verified (I 65->80%)`.

Reason: this branch already contains the newer convergence, control-plane, product-detail
localization, subscription/payment, Razorpay verification, catalog browse, low-stock, and recall
work. The older `codex/radha-production-convergence` worktree was preserved and inspected, but its
seven-screen localization work was ported into the canonical branch instead of blindly merging the
older branch.

## Worktrees Inspected

| Worktree | Branch | HEAD | Role |
|---|---:|---:|---|
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-converged` | `codex/radha-final-convergence` | `cc7834d` | Canonical target for this pass |
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES` | `codex/radha-production-convergence` | `a622bc3` | Legacy/alternate worktree holding uncommitted seven-screen localization |

## Safety Artifacts Created

| Artifact | Purpose |
|---|---|
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-pre-mobile-qa-safety.bundle` | Canonical branch recovery bundle before edits |
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-pre-mobile-qa-working.patch` | Canonical dirty-worktree patch before edits |
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-convergence-localization-working.patch` | Alternate worktree localization patch |
| `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-production-convergence-D10_LOCALIZATION_HANDOFF.md` | Copied alternate handoff; contains exposed secret material and must not be committed as-is |

## Branch Divergence Summary

`codex/radha-final-convergence` contains newer required work, including:

- `6489455 fix(subscription): converge mobile plans entitlements and payments`
- `86cb725 feat(payments): testable Razorpay checkout engine (state machine + adapter)`
- `a1f3b0a fix(subscription): align client to plural /subscriptions/* + server-driven entitlements`
- `1c9ca8c feat(subscription-ui): backend-driven plans + engine checkout on the page`
- `4bf72ee feat(mobile): complete localized product detail states`
- `4419e80 feat(mobile): localize low stock alerts screen across 6 locales (D10 sweep)`
- `d355e2d feat(mobile): localize recall alerts screen across 6 locales (D10 sweep)`
- `dd9673d` and `cc7834d` Razorpay verification/control-plane documentation commits

`codex/radha-production-convergence` has older unique commits plus uncommitted localization work.
That uncommitted localization was preserved as a patch and ported manually where the canonical
branch had drifted.

## Localization Recovery Completed

Recovered and ported seven-screen localization from the alternate worktree into canonical
`apps/mobile`:

- `apps/mobile/lib/features/allergen/allergen_profile_screen.dart`
- `apps/mobile/lib/features/expiry/expiry_list_screen.dart`
- `apps/mobile/lib/features/home/home_screen.dart`
- `apps/mobile/lib/features/inventory/inventory_list_screen.dart`
- `apps/mobile/lib/features/onboarding/onboarding_screen.dart`
- `apps/mobile/lib/features/scan/scan_screen.dart`
- `apps/mobile/lib/features/tasks/tasks_list_screen.dart`

Locale source and generated output updated across:

- `apps/mobile/lib/l10n/app_en.arb`
- `apps/mobile/lib/l10n/app_hi.arb`
- `apps/mobile/lib/l10n/app_ta.arb`
- `apps/mobile/lib/l10n/app_te.arb`
- `apps/mobile/lib/l10n/app_bn.arb`
- `apps/mobile/lib/l10n/app_mr.arb`
- `apps/mobile/lib/l10n/generated/app_localizations*.dart`

Test harnesses were updated only where localization delegates were required.

## Contract Matrix Status

Contract matrix deliverable path:
`docs/GENERATED_API_CONTRACT_MATRIX.md`.

Gate run:
`pnpm.cmd contracts:check`

Result:
`API contract drift gate passed.`

## Credential And Secret Handling

Security finding: the alternate untracked `radha_app/docs/D10_LOCALIZATION_HANDOFF.md` contains
exposed Razorpay test secret material. No secret values were copied into this report, staged, or
committed.

Canonical tracked-file check:

- Only env example files are tracked.
- `server/.env`, `server/.env.development`, `apps/mobile/.env`, and
  `apps/mobile/.env.development` are ignored by `.gitignore`.
- Safe local credential-status check in the canonical worktree returned:
  - `server/.env.development`: `MISSING`
  - `RAZORPAY_KEY_ID`: `MISSING`
  - `RAZORPAY_KEY_MODE`: `MISSING`
  - `RAZORPAY_KEY_SECRET`: `MISSING`
  - `RAZORPAY_WEBHOOK_SECRET`: `MISSING`
  - known Gemini API key names: `MISSING`

Owner action required: rotate/regenerate the exposed Razorpay test key pair and configure a
dedicated webhook secret before any further payment live verification. Treat any previously pasted
Gemini/Razorpay credentials as exposed.

## Validation Evidence

Automated gates run after the port:

- `flutter gen-l10n` in `apps/mobile`: passed.
- `dart format --set-exit-if-changed` on touched Dart files: passed after formatting.
- `flutter analyze --fatal-infos` in `apps/mobile`: passed with no issues.
- `flutter test --reporter compact --file-reporter json:localization_full_test_results.jsonl`
  in `apps/mobile`: passed, 243 tests.
- `pnpm.cmd contracts:check` in repo root: passed.

Temporary test artifact `apps/mobile/localization_full_test_results.jsonl` was removed after the
green run.

## Out Of Scope For This Commit

The following pre-existing/local generated changes were intentionally not staged:

- `apps/mobile/windows/flutter/generated_plugin_registrant.cc`
- `apps/mobile/windows/flutter/generated_plugin_registrant.h`
- `apps/mobile/windows/flutter/generated_plugins.cmake`
- `server/.tmp/curated-eans.json`

Mobile MCP installation, Android device/manual verification, and native camera/payment checkout
journeys remain next steps after this recovery/localization/contract gate.
