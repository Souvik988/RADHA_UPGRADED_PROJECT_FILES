# Worktree And Commit Recovery Report

Date: 2026-06-14
Final branch: `codex/radha-final-convergence`
Remote main audited: `bd4710b66cf836d7d84ac54a867d56f04d6c7b5a`
Current recovered baseline: `554b87ccb7aa4d6eff94272a3443cfcc7714e045`

## Executive Finding

The missing subscription/payment work was not present on `origin/main` or on the published
`origin/codex/radha-production-convergence` branch. It was recovered from the local canonical
monorepo worktree branch `codex/radha-production-converged`.

The recovered branch descends from `origin/main`, so the work is port-safe:

- Merge base with `origin/main`: `bd4710b66cf836d7d84ac54a867d56f04d6c7b5a`
- Recovery branch before final branch creation: `codex/radha-production-converged`
- Final execution branch created from that recovered branch: `codex/radha-final-convergence`

## Safety Artifacts

Created before new recovery/gate edits:

- Full bundle: `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-full-recovery.bundle`
- Bundle verification: passed; bundle records complete history
- Working tree patch: `C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\radha-working-tree.patch`
- Patch size: 0 bytes because the only pre-existing dirty files are Windows Flutter generated files
  reported by Git as line-ending normalization noise

Pre-existing dirty files intentionally not staged:

- `apps/mobile/windows/flutter/generated_plugin_registrant.cc`
- `apps/mobile/windows/flutter/generated_plugin_registrant.h`
- `apps/mobile/windows/flutter/generated_plugins.cmake`

## Worktrees Found

| Worktree | Branch | Head | Role | Decision |
|---|---|---:|---|---|
| `RADHA_UPGRADED_PROJECT_FILES` | `codex/radha-production-convergence` | `a622bc3` | Export/dashboard worktree and published branch | Preserve separately; dashboard is not yet ported into canonical monorepo |
| `radha-production-converged` | `codex/radha-production-converged` | `554b87c` | Canonical monorepo with recovered mobile/server/shared work | Use as recovery source |
| `radha-production-converged` | `codex/radha-final-convergence` | `554b87c` | Final convergence branch created from recovered canonical branch | Continue here |

## Reported Recovery Files

| File | Found in final branch | Source |
|---|---|---|
| `checkout_engine.dart` | yes | `apps/mobile/lib/features/subscription/payment/checkout_engine.dart` |
| `checkout_models.dart` | yes | `apps/mobile/lib/features/subscription/payment/checkout_models.dart` |
| `razorpay_adapter.dart` | yes | `apps/mobile/lib/features/subscription/payment/razorpay_adapter.dart` |
| `subscription_status_dto.dart` | yes | `apps/mobile/lib/core/network/dto/subscription_status_dto.dart` |
| `RADHA_MASTER_FUNCTION_MATRIX.md` | yes | `docs/RADHA_MASTER_FUNCTION_MATRIX.md` |
| `PRODUCT_DETAIL_REPAIR_REPORT.md` | no | Not found in either current worktree; product detail repair exists as code/test commits |
| `PAYMENT_STATE_MACHINE.md` | yes | `docs/PAYMENT_STATE_MACHINE.md` |
| `PHASE_3_VALIDATION_REPORT.md` | yes | `docs/PHASE_3_VALIDATION_REPORT.md` |

## Local Commit Recovery Table

All commits below descend from `origin/main`.

| SHA | Branch discovered on | Parent | Already on remote | Files changed | Decision |
|---|---|---|---|---|---|
| `9d9814e` | `codex/radha-production-converged` | `bd4710b` | no | catalog source-state handling, UI v2 foundation | Preserve in final branch |
| `8640a51` | `codex/radha-production-converged` | `9d9814e` | no | `REPOSITORY_CONVERGENCE_REPORT.md`, `SUBSCRIPTION_PAYMENT_CONTRACT.md` | Preserve as recovery evidence |
| `6a99a8e` | `codex/radha-production-converged` | `8640a51` | no | product lookup failure states | Preserve; supports later Product Detail work |
| `86cb725` | `codex/radha-production-converged` | `6a99a8e` | no | `CheckoutEngine`, checkout models, injectable Razorpay adapter, engine tests | Recover/port; subscription-payment core |
| `a1f3b0a` | `codex/radha-production-converged` | `86cb725` | no | plural `/subscriptions/*` ApiClient, server-driven entitlements, `SubscriptionStatusDto`, tests | Recover/port; subscription contract fix |
| `1c9ca8c` | `codex/radha-production-converged` | `a1f3b0a` | no | subscription page plan fetching, checkout engine integration, widget tests | Recover/port; subscription UI fix |
| `e7d445e` | `codex/radha-production-converged` | `1c9ca8c` | no | `PAYMENT_STATE_MACHINE.md` | Preserve as subscription/payment design record |
| `d0530f5` | `codex/radha-production-converged` | `e7d445e` | no | sprint validation report | Preserve |
| `1de9404` | `codex/radha-production-converged` | `d0530f5` | no | dashboard discovery/baseline docs | Preserve for later dashboard convergence |
| `7ef5991` | `codex/radha-production-converged` | `1de9404` | no | `RADHA_MASTER_FUNCTION_MATRIX.md` | Preserve; superseded by generated matrix gate where possible |
| `9aab91c` | `codex/radha-production-converged` | `7ef5991` | no | dashboard integration report | Preserve |
| `1016dc1` | `codex/radha-production-converged` | `9aab91c` | no | backend bring-up handoff | Preserve |
| `d1826c4` | `codex/radha-production-converged` | `1016dc1` | no | backend module wiring, permissions, KPI query fixes | Preserve; live-verification repair |
| `52ce51c` | `codex/radha-production-converged` | `d1826c4` | no | localized subscription screen and ARB completeness test | Preserve; later than subscription recovery |
| `27fee0f` | `codex/radha-production-converged` | `52ce51c` | no | mobile visual asset wiring | Preserve but not part of first recovery gate |
| `38c5675` | `codex/radha-production-converged` | `27fee0f` | no | tenant onboarding starts trial subscriptions | Preserve; subscription backend correctness |
| `27ade54` | `codex/radha-production-converged` | `38c5675` | no | catalog search localization | Preserve; later localization phase |
| `4c26498` | `codex/radha-production-converged` | `27ade54` | no | product browse localization | Preserve; later localization phase |
| `0742d93` | `codex/radha-production-converged` | `4c26498` | no | featured rail localization | Preserve; later localization phase |
| `83e9a8e` | `codex/radha-production-converged` | `0742d93` | no | prior handoff | Superseded by updated recovery docs, keep in history |
| `9a5a7ec` | `codex/radha-production-converged` | `83e9a8e` | no | product detail localization | Preserve; correct order is after recovery commits |
| `e536a51` | `codex/radha-production-converged` | `9a5a7ec` | no | profile localization | Preserve; later localization phase |
| `0422cc8` | `codex/radha-production-converged` | `e536a51` | no | select-store localization | Preserve; later localization phase |
| `554b87c` | `codex/radha-production-converged` | `0422cc8` | no | application context handoff | Preserve; superseded in part by this report |

## Subscription/Payment Recovery Decision

Decision: recover and preserve the local implementation rather than rebuilding it.

Recovered capabilities:

- sealed checkout result model
- testable `CheckoutEngine`
- injectable `RazorpayAdapter`
- external-wallet handling as a non-terminal event
- duplicate callback protection
- pending confirmation state
- backend-driven plan/status/usage DTOs
- plural `/subscriptions/*` mobile client paths
- `SubscriptionStatusDto`
- server-driven entitlement feature/limit/usage mapping
- subscription page plan fetching from backend
- monthly/yearly selection
- entitlement refresh after payment verification path
- unit/widget test coverage for checkout engine, entitlement mapping, and subscription screen

The final branch now preserves the recovered subscription/payment code before the Product Detail
localization commit in history. The next required green commit should focus on the generated contract
gate and recovery evidence, then targeted subscription/payment verification should be rerun before
moving back to Product Detail work.

## Remote Status

Remote branches visible during recovery:

- `origin/main` at `bd4710b66cf836d7d84ac54a867d56f04d6c7b5a`
- `origin/codex/radha-production-convergence` at `a622bc3691ced3dca52ddfa031caa6c5cc17eed2`

The recovered subscription/payment commits are not on either remote branch at the time of this
report. They are local-only until `codex/radha-final-convergence` is pushed.

