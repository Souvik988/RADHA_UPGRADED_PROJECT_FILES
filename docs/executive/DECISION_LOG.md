# RADHA — Decision Log

> Architectural / product decisions taken autonomously (ordinary engineering) or flagged for the owner.
> Each: date · decision · rationale · alternatives · reversibility.

| Date | Decision | Rationale | Alternatives considered | Reversible? |
|---|---|---|---|---|
| 2026-06-15 | Work continues on `codex/radha-final-convergence` @ `4bf72ee` (the directive's canonical branch, pushed to origin) | It builds on the prior executive handoff and contains the latest l10n + convergence work | Continue on `codex/radha-production-converged` (now superseded) | Yes (branches preserved + bundle) |
| 2026-06-15 | Created `docs/executive/` control plane (PROGRAM_STATE, EVIDENCE_LEDGER, scorecard, registers, resume prompt) before further feature work | The program needs a single source of truth + evidence discipline; scorecard must be calculated not chosen | Skip and code directly | Yes |
| 2026-06-15 | Completion reported as **~53%** (calculated from weighted scorecard) | Honesty rule: functional/automated core strong, release-readiness half unproven | Report a flattering round number | n/a (recomputed each turn) |
| 2026-06-15 | Leave `apps/mobile/windows/flutter/generated_*` uncommitted | Generated churn from local Flutter runs; §6 says protect unless Windows support is intentionally regenerated+tested | Commit them | Yes |
| 2026-06-15 | Dashboard reads **rollups only**; raw tenant UGC encrypted per-tenant; platform raw access only via audited break-glass (admin-impersonation) | Privacy-by-design + fixes "bulky dashboard" by reading pre-aggregated `owner_daily_metrics`/`operational_health_scores` | Dashboard reads raw tables (rejected: privacy + scale) | Design; not yet implemented |
| 2026-06-15 | Recall 403 for tenant-less consumer accepted as **by design** | Recalls are tenant-scoped; consumer-recall is a separate entitled path | Treat as defect (rejected) | Yes if product disagrees |

## Flagged for owner (do not decide autonomously) — see OWNER_ACTIONS_REQUIRED.md
- Razorpay production credentials; AWS account + financial provisioning; privacy/legal sign-off
  (DPDP Act mapping is `LEGAL_REVIEW`); store data-safety declaration; closed-beta go/no-go.
