# PHASE 20 — Final QA + handover

## Goal
End-to-end click-through per role, produce a fix list, update PHASE_INDEX statuses, and write a short
README for running the app — the handover gate.

## Depends on
Phases 01–19.

## Doc references
- Doc 1 §5.3 (role → capability matrix — drives per-role testing).
- Doc 3 Part C (full delivery checklist — Functional + Security + Design).
- Doc 2 §9 (anti-slop final gate).

## Scope (in)
- Per-role end-to-end walkthroughs: `admin`, `owner`, `manager`, `staff`, `auditor` — verify each
  sees exactly the capabilities in Doc 1 §5.3 and nothing more.
- A `phases/QA_FINDINGS.md` fix list (severity-tagged), worked down to zero blockers.
- Update `PHASE_INDEX.md` statuses to `[x]` for completed phases.
- `radha_dashboard/README.md` — prerequisites, env (`.env.local` from `.env.example`), install,
  `dev`/`build`/`start`/`lint`/`typecheck`, backend dependency (API at `/api/v1`), notes on 🆕 gated
  features + how to flip them on when backend lands.
- Final Doc 3 Part C checklist sign-off (Functional + Security + Design).

## Out of scope
New features. Backend work. Deployment/infra (note prereqs only).

## Step-by-step
1. Run each role through every screen; confirm RBAC gating (server-enforced), scope, and all states.
2. Log findings in `QA_FINDINGS.md`; fix blockers; re-verify.
3. Confirm honest-data rule: no 🆕 surface shows fabricated data; all live screens use real endpoints.
4. Tick the full Doc 3 Part C checklist (Functional/Security/Design).
5. Update `PHASE_INDEX.md` statuses. Write `README.md`.
6. Final verify.

## API wiring
No new endpoints. Confirms every wired screen handles loading/empty/error/offline + 401/429.

## Design spec
- Final anti-slop gate (Doc 2 §9) across the whole app; tokens-only; one orange CTA per region; mono
  numbers; dark + light verified.

## Security checks
- Full Doc 3 Part C Security checklist signed off. Re-confirm sensitive-op step-up + audit, CSP/headers,
  cookie security, `npm audit` clean, no secrets in bundle.

## Acceptance criteria
- [ ] All five roles walked end-to-end; capabilities match Doc 1 §5.3; no over-exposure.
- [ ] `QA_FINDINGS.md` exists with zero open blockers.
- [ ] `PHASE_INDEX.md` statuses updated; `README.md` written + accurate.
- [ ] Doc 3 Part C checklist fully ticked (Functional + Security + Design).
- [ ] `build`+`typecheck`+`lint` clean; `npm audit` clean.

## Verification
- `npm run typecheck && npm run lint && npm run build && npm audit`.
- User: follow the README from a clean checkout to a running app; spot-check two roles end-to-end.

## Rollback note
Documentation + fixes only. Individual fixes revert per file via git. No structural removal.
