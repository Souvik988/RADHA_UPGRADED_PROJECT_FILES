# PHASE 18 — 🆕 PROPOSED enterprise features (gated "needs backend")

## Goal
Design and build the UI shells for the proposed enterprise capabilities — clearly gated behind a
"needs backend" / locked state — so the product story is complete without ever wiring a screen to a
non-existent endpoint or fabricating data.

## Depends on
Phases 02, 04, 05 (the 🆕 client stubs throw `NotImplementedBackendError`). Each proposed feature's
"home" surface (e.g. Settings team tab, Admin tenants) was stubbed in its earlier phase.

## Doc references
- Doc 1 §8 (all PROPOSED endpoints, §8.1–§8.6).
- Doc 3 §A.4 (PROPOSED enterprise functions 1–10), §B.7 (bulk/broadcast controls when they land).
- Doc 2 §4.12 (locked overlay), §9 (no fabricated data).

## Scope (in)
For each item below: a real, token-correct **layout** behind a `<NeedsBackend>` banner / `<LockedOverlay>`
(value behind glass), with the typed `@proposed` client fn present but throwing until the backend ships.
- **Team & access mgmt** (§8.1 `/users/*`) — `app/(dash)/settings/team/` shell: invite/list/role/deactivate UI, gated.
- **Audit-log viewer** (§8.1 `/audit-logs`) — `app/(dash)/admin/audit-logs/` filterable table shell, gated.
- **Saved views & alert rules** (§8.2) — saved-view save/apply control + alert-rule builder, gated.
- **Scheduled & emailed reports** (§8 / A.4.4) — schedule form on top of Reports, gated.
- **Cross-store compare & cohorts** (§8.3) — `app/(dash)/analytics/compare/` grouped-bar shell, gated.
- **Platform-admin console** (§8.4 `/admin/tenants`, `/admin/metrics`, flag mgmt, platform settings) —
  `app/(dash)/admin/tenants/`, `/admin/metrics/`, flag-management, settings shells, gated, admin-only.
- **Broadcast comms** (§8.5 `/notifications/broadcast`) — segment picker + message composer shell, gated.
- **Billing back-office** (§8.6 `/billing/invoices`, `/transactions`) — invoice/transaction tables, gated.
- **Bulk operations + undo** (A.4.9) — multi-select + bulk action bar + undo-toast UX wired to a
  feature flag (uses per-item endpoints short-term; batch endpoint is the upgrade), gated where batch needed.
- **Global search ⌘K** (A.4.10 `/search/global`) — either client-side fan-out (short-term, real) OR
  gated single endpoint; ship the real fan-out where it composes existing endpoints.
- `components/system/needs-backend.tsx` — standard banner explaining the feature needs a backend
  endpoint (lists the proposed route), with a docs link. No fake data, ever.

## Out of scope
Implementing the backend endpoints (backend-first; out of dashboard scope). Shipping any 🆕 surface as
if live. Bulk/broadcast without confirm + audit once real.

## Step-by-step
1. Build `<NeedsBackend route="POST /api/v1/users/invite">` banner component (reuses `<LockedOverlay>`).
2. For each item, create the route + a faithful layout using real components, wrapped so it renders the
   value/shape **behind glass** with the NeedsBackend banner; the `@proposed` client fn throws.
3. Where a capability composes existing endpoints today (global search fan-out, per-item "bulk"), ship
   the **real** version and mark only the batch/endpoint upgrade as 🆕.
4. Gate platform-admin shells to `role==='admin'`.
5. Add a short `phases/PROPOSED_BACKEND.md` note listing each 🆕 endpoint the backend must add (mirrors
   Doc 1 §8) so backend work is unambiguous. Verify.

## API wiring
- All §8 endpoints as `@proposed` stubs that throw `NotImplementedBackendError` (no network call).
- Real, allowed compositions: global-search fan-out across existing `/products`, `/suppliers`,
  `/tasks`, `/grn`, `/stores`; bulk-as-loop over existing per-item endpoints (with undo + confirm).

## Design spec
- Doc 2 §4.12 locked overlay: real layout + tasteful blur/scrim + lock glyph + one orange CTA
  (e.g. "Request this feature" / docs). NeedsBackend banner is calm, informative, on-brand. No
  fabricated rows/numbers anywhere.

## Security checks
- 🆕 fns never issue a real request (honest-data rule, Doc 3 §A.4 / Doc 2 §9).
- Bulk/broadcast (when real) require preview count + explicit confirm + undo + audit + rate-limit (§B.7).
- Platform-admin shells admin-only + code-split. Global-search fan-out respects scope + 429 backoff.

## Acceptance criteria
- [ ] Every 🆕 feature has a token-correct shell behind a clear NeedsBackend/locked state.
- [ ] No 🆕 surface fetches a non-existent endpoint or shows fabricated data.
- [ ] Real compositions (global search fan-out, per-item bulk w/ undo) work and are scope-safe.
- [ ] `phases/PROPOSED_BACKEND.md` lists each required backend endpoint.
- [ ] `build`+`typecheck` clean; anti-slop passes.

## Verification
- `npm run typecheck && npm run build`.
- User: visit each 🆕 surface → sees the locked/needs-backend state (no fake data); try global search
  (real results); try a per-item bulk action with undo.

## Rollback note
Additive shells + a docs note. Remove the 🆕 routes/components to revert. When a backend endpoint
ships, replace the stub + NeedsBackend wrapper with the live wiring in a follow-up.
