# PHASE 16 — Admin console (admin role)

## Goal
Build the platform-admin console (admin role only): impersonation (start/stop with step-up,
persistent banner, audit trail), feature-flag variants (read), and outbound webhooks
(endpoints CRUD + deliveries + replay).

## Depends on
Phases 02, 03 (role gate), 04 (admin nav code-split), 05.

## Doc references
- Doc 1 §6.16 (`/admin/*` impersonation), §6.18 (webhooks, feature-flags read), §7.6 (support flow).
- Doc 2 §5.13 (Admin console spec).
- Doc 3 §A.3.12 (platform-admin functions), §B.3 (least privilege/code-split), §B.7 (impersonation controls).

## Scope (in)
- `app/(dash)/admin/layout.tsx` — re-checks `role==='admin'` server-side; code-split bundle.
- `app/(dash)/admin/impersonation/page.tsx`, `/admin/flags/page.tsx`, `/admin/webhooks/page.tsx`.
- `features/admin/*` (queries/actions/schema/components).
- Components:
  - `impersonation-start.tsx` — step-up confirm → `POST /admin/impersonate` (201); time-boxed.
  - `impersonation-banner.tsx` — global persistent "You are impersonating {user}" banner while active;
    end via `DELETE /admin/impersonate`; auto-end on logout.
  - `impersonation-audit.tsx` — `GET /admin/impersonations/audit` (filter `staffUserId`,
    `impersonatedUserId`, `limit`).
  - `feature-flags.tsx` — `GET /feature-flags/me` (read variants). Management UI is 🆕 (Phase 18).
  - `webhooks.tsx` — endpoints CRUD (`POST/GET /webhooks/endpoints`), deliveries
    (`GET /webhooks/deliveries`), replay (`POST /webhooks/deliveries/:id/replay`).

## Out of scope
Tenant management / suspend / platform metrics / flag management / platform settings — all 🆕
(Doc 1 §8.4, Phase 18). Here: only the endpoints that exist today.

## Step-by-step
1. Admin layout server-re-checks role; non-admin → `/403`.
2. Impersonation: start with a step-up re-auth confirm (target user, reason, time box) →
   `POST /admin/impersonate`; mount the persistent banner app-wide while active; end action; auto-end
   on logout.
3. Impersonation audit table with filters + mono timestamps.
4. Feature flags: read-only variant list (clearly "read-only — management coming with backend").
5. Webhooks: endpoints table + create/edit; deliveries table with status; replay action (confirm).
6. States: skeletons, empty, error retry. Verify.

## API wiring
- `POST /admin/impersonate` (201), `DELETE /admin/impersonate`, `GET /admin/impersonations/audit`.
- `GET /feature-flags/me`.
- `POST/GET /webhooks/endpoints`, `GET /webhooks/deliveries`, `POST /webhooks/deliveries/:id/replay`.

## Design spec
- Doc 2 §5.13. Impersonation banner = high-visibility warm danger/accent band, always on top while
  active. Audit + deliveries tables mono timestamps/ids. One orange CTA per region. Webhook status chips.

## Security checks (Doc 3 §B.3, §B.7)
- Entire admin section gated to `role==='admin'` (server re-check + code-split bundle).
- Impersonation: step-up confirm, time-boxed, persistent banner, every session audited, auto-end on
  logout. Treat as the most sensitive surface.
- Webhook replay = confirm + audited. No secrets shown (webhook signing secrets masked).

## Acceptance criteria
- [ ] Admin section only loads for admin; non-admin gets 403 (server-enforced).
- [ ] Impersonation start (step-up) → banner shows → end works → audit trail lists sessions.
- [ ] Feature-flag variants read-only; webhooks CRUD + deliveries + replay work.
- [ ] All states designed; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User (admin): start an impersonation (confirm banner + audit entry), end it; view flags; create a
  webhook endpoint, replay a delivery. Confirm a non-admin cannot reach `/admin/*`.

## Rollback note
Additive under `features/admin/` + `app/(dash)/admin/*`. Remove the admin route group + banner mount
to revert. No backend changes.
