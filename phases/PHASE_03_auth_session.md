# PHASE 03 — Auth & session

## Goal
Implement a secure, httpOnly-cookie session backed by the backend JWT pair: login, password
reset, invite-accept, silent refresh, logout, a middleware route-guard, and RBAC helpers
(`useSession`, `can()`, `hasRole()`). Client gating is cosmetic; the API stays the real boundary.

## Depends on
Phase 01 (shell, headers), Phase 02 (form-field, button, states).

## Doc references
- Doc 1 §4 (token model, admin login flow, supporting endpoints), §4.1 (JWT payload), §5 (roles/perms).
- Doc 3 §A.3.1 (auth functions), §B.2 (web session), §B.3 (authorization defense-in-depth), §A.2 (`useSession`, `can`, `hasRole`).
- Doc 2 §5.14 (settings/profile hooks consume `/auth/me`).

## Scope (in)
- `lib/auth/session.ts` — server-only: read/write the session cookie (httpOnly, Secure,
  SameSite=Lax), store `{accessToken, refreshToken, expiresAt}`; helpers `getSession()`,
  `setSession()`, `clearSession()`. Cookie name from env.
- `app/api/auth/login/route.ts` — Route Handler: POST email/password → calls
  `POST /api/v1/auth/admin/login` server-side → sets cookies → returns minimal user. (Bearer never
  reaches client JS.)
- `app/api/auth/refresh/route.ts` — POST → `POST /api/v1/auth/refresh` with stored refresh token →
  rotate cookies. On failure → clear + 401.
- `app/api/auth/logout/route.ts` — POST → `POST /api/v1/auth/logout` (Bearer) → clear cookies → 204.
- `app/api/auth/me/route.ts` — GET → proxies `GET /api/v1/auth/me` with server-side bearer (used by
  `useSession` so token stays server-side); returns `UserMeResponse`.
- `lib/auth/rbac.ts` — `hasRole(session, role)`, `can(session, permission)`; permission constants in
  `lib/permissions.ts` mirroring Doc 1 §5.2 catalog.
- `lib/auth/use-session.ts` — client hook: fetches `/api/auth/me` (TanStack Query), returns
  `{user, role, permissions, storeIds, isLoading}`.
- `middleware.ts` — route-guard: unauthenticated → `/login`; role-gated route prefixes (`/admin/*`
  requires `admin`) → redirect/403 page; attaches nothing sensitive to the client.
- `app/(auth)/login/page.tsx` — login form (RHF + Zod, min-12 password meter), error states, redirect-by-role.
- `app/(auth)/reset/page.tsx` — request + complete reset (`/auth/password/reset/request|complete`).
- `app/(auth)/invite/page.tsx` — accept admin invite (`/auth/admin/invitations/accept`).
- `app/(auth)/verify/page.tsx` — email verify (`/auth/email/verify`).
- `features/auth/auth.schema.ts` — Zod schemas (login, reset, invite) mirroring backend DTOs.
- `components/auth/role-gate.tsx`, `permission-gate.tsx` — cosmetic UI gates (hide/disable only).

## Out of scope
The full app shell/nav (Phase 04), the generic `apiFetch` client (Phase 05 — this phase calls the
backend directly inside Route Handlers using a small server-only fetch helper; refactor onto
`apiFetch` in Phase 05).

## Step-by-step
1. Create `lib/auth/session.ts` using `next/headers` `cookies()`; set cookies with
   `{ httpOnly:true, secure:true, sameSite:'lax', path:'/' }`. Compute `expiresAt = now + expiresIn`.
2. Build the four Route Handlers. They are the **only** place the refresh token is read; they attach
   the Bearer server-side. Add a double-submit CSRF token (set a readable `csrf` cookie + require a
   matching header on POST) — finalize CSRF in Phase 05 too.
3. `lib/permissions.ts`: enumerate the §5.2 catalog as string literals + a `PERMISSIONS` const.
   `lib/auth/rbac.ts`: pure functions over the session user.
4. `middleware.ts`: read session cookie presence; for protected matchers redirect to `/login` with
   `?next=`; for `/admin` check role via a lightweight signed claim (or call `/api/auth/me` in a
   server component layout — middleware only checks cookie presence, the **server layout re-checks
   role** per §B.3). Add `config.matcher` for `(dash)` + `/admin`.
5. Login page: RHF + Zod, submit to `/api/auth/login`; on success `router.replace` by role
   (admin→`/admin`, others→`/`). Show typed errors (invalid creds, locked) via `<ErrorState>`/inline.
6. Reset/invite/verify pages mirror their DTOs; min-12 password rule + strength meter; success states.
7. Wire `useSession` + gates; add a `/403` page with explanation (not a silent hide for paid).
8. Verify.

## API wiring
- `POST /api/v1/auth/admin/login` `{email,password,deviceId?}` → `{accessToken,refreshToken,expiresIn,user}`.
- `GET /api/v1/auth/me` → `{id,mobile,name,role,tenantId,storeIds[],permissions[],isVerified,bypassOnboarding,createdAt}`.
- `POST /api/v1/auth/refresh` `{refreshToken}` → new `TokenPair`.
- `POST /api/v1/auth/logout` (Bearer) → 204.
- `POST /api/v1/auth/password/reset/request` `{email}` → `{status:'queued'}`.
- `POST /api/v1/auth/password/reset/complete` `{token,newPassword}` (min 12).
- `POST /api/v1/auth/email/verify` `{token}`.
- `POST /api/v1/auth/admin/invitations/accept` `{token,name,password}` (min 12).

## Design spec
- Auth pages: warm cream canvas, centered card (raised, `lg`, hairline, `--shadow-card`), RADHA
  mark + eyebrow, single orange CTA, mono for any codes. Reduced-motion-safe entrance.
- All states designed: loading button, inline field errors (`role="alert"`), error retry, success.

## Security checks (Doc 3 §B.2–B.3)
- Tokens **only** in httpOnly + Secure + SameSite=Lax cookies — never localStorage, never in URL.
- Access token short-lived; refresh rotating/revocable; silent refresh on 401, hard logout on
  refresh failure; logout revokes server session + clears cookies.
- Middleware gate is UX; **server components/actions re-check role/permission** before admin data.
- Client `can()/hasRole()` only hide/disable — assume bypassable.
- Step-up confirm scaffold for sensitive actions (used later by refund/impersonation).
- Password min 12; strength meter; never persist password client-side.
- CSRF: SameSite=Lax + double-submit token on browser POST/PATCH/DELETE.

## Acceptance criteria
- [ ] Login sets httpOnly cookies; no token visible in `localStorage`/`document.cookie` JS read of the session token.
- [ ] `GET /auth/me` hydration works via the server proxy; `useSession` returns role/permissions/storeIds.
- [ ] 401 triggers a silent refresh once; refresh failure forces logout to `/login`.
- [ ] Middleware redirects unauthenticated users; `/admin` blocked for non-admin (server re-check too).
- [ ] Reset, invite, verify flows complete against their endpoints; min-12 enforced.
- [ ] Logout revokes session and clears cookies. `build` + `typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: log in with a seeded admin; confirm redirect + `/auth/me` data; inspect cookies are
  httpOnly (DevTools → Application → Cookies); trigger a 401 (e.g. expire token) and confirm silent
  refresh; visit `/admin` as a manager → blocked; log out → cookies cleared.

## Rollback note
Additive auth files + `middleware.ts`. To revert, delete the `(auth)` route group, `app/api/auth/*`,
`lib/auth/*`, `lib/permissions.ts`, and `middleware.ts` (removing the guard restores open routing).
No backend changes.
