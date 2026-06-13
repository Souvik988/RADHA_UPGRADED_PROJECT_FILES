# PHASE 17 — Settings + profile + language

## Goal
Build the Settings screen: profile, language preference, security (password change), and tenant info.

## Depends on
Phases 02, 03 (session), 05.

## Doc references
- Doc 2 §5.14 (Settings spec).
- Doc 1 §4 (`/auth/me`, password reset), §6.4 (`/tenants/me`).
- Doc 3 §B.2 (re-auth for sensitive change), §A.4.1 (team mgmt is 🆕).

## Scope (in)
- `app/(dash)/settings/page.tsx` — tabbed: Profile / Language / Security / Tenant.
- `features/settings/settings.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components: `profile-card.tsx` (`/auth/me`), `language-select.tsx` (`PUT /users/me/language` — the
  shipped locales en/hi/ta/te/bn/mr; `gu` noted not-shipped), `security-card.tsx` (password change
  via reset flow / dedicated endpoint, step-up), `tenant-info.tsx` (`/tenants/me`).
- Team management tab placeholder → 🆕 (Phase 18) locked state.

## Out of scope
Team/user management (🆕, Phase 18). Editing tenant billing (Phase 14). Notification prefs (Phase 15).

## Step-by-step
1. Profile card from `/auth/me` (name, role, mobile masked, stores). Edit where backend allows.
2. Language select (shipped locales); persist via `PUT /users/me/language`; note `gu` recommended-but-not-shipped.
3. Security: password change with step-up confirm + min-12 + strength meter.
4. Tenant info from `/tenants/me` (read).
5. Team tab = 🆕 locked-state pointer to Phase 18. States: skeleton, error retry. Verify.

## API wiring
- `GET /auth/me`, `PUT /users/me/language`, `GET /tenants/me`, password change (`/auth/password/*`
  or dedicated endpoint). 🆕 `/users/*` deferred.

## Design spec
- Doc 2 §5.14. Tabbed settings, clean form fields (orange focus ring, visible labels), mono for IDs.
  One orange CTA per tab. Masked PII (mobile).

## Security checks
- Password change = step-up re-auth + min-12 (§B.2); never store password client-side.
- Mask partial PII (mobile) per §B.9. Tenant scope on calls. Team mgmt stays 🆕-gated (no fake data).

## Acceptance criteria
- [ ] Profile, language, tenant info render from real endpoints; language persists.
- [ ] Password change works with step-up + min-12 validation.
- [ ] Team tab shows a 🆕 locked state (no fabricated users).
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: view profile, change language (persists on reload), change password (step-up), view tenant info.

## Rollback note
Additive under `features/settings/` + the page. No shared-layer/backend changes.
