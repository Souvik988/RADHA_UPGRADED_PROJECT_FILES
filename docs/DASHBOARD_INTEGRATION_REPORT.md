# RADHA — Dashboard Integration Report

Static integration audit of `radha_dashboard` against the canonical backend
(`/api/v1`). No backend running here → live calls are `BLOCKED_EXTERNAL`; this covers
**code-level connection, demo-mode safety, and contract correctness**.

## 1. Backend connection — already canonical ✅
- All BFF proxies (`app/api/**`, 84 routes) target `NEXT_PUBLIC_API_BASE_URL` (default
  `http://localhost:3000`) + `/api/v1` — the **same backend + prefix as mobile**.
- Auth: httpOnly+Secure+SameSite session cookie, JWT refresh (`lib/auth/*`), `middleware.ts`
  route protection. Tokens never in localStorage/URL (server-only `session.ts`).
- RBAC: `lib/permissions.ts` + role-based `lib/nav-config.ts`.

## 2. DEMO_MODE mock-data audit ✅ (hardened this pass)
**Architecture (sound):** a deliberate, server-only demo provider — `lib/demo/*` with one
dataset per feature area, scope-filtered (`filterByScope`), `import 'server-only'` so it
**never bundles to the browser**. Every proxy resolves via
`resolveToResponse({ isDemo, fetchReal, selectDemo })` → real mode calls the backend.

**Safety findings:**
- `DEMO_MODE = process.env.DEMO_MODE === 'true'` → **fail-safe default OFF** (unset ⇒ off).
- `.env.example` (prod template) **does not set DEMO_MODE**; `.env.local` (sets it true) is
  **gitignored** (not tracked) — won't ship.
- Residual risk (pre-fix): `isDemoRequest` also returned demo for a session carrying `_demo`,
  independent of env — a stray/forged demo cookie could surface mock data.

**Hardening applied (defense-in-depth — `45a671a`+ on export branch):**
- `lib/api/core/proxy.ts` `isDemoRequest`: **`if (NODE_ENV === 'production') return false;`**
  at the top → demo data is **impossible** in a production build regardless of env or cookie.
- `lib/demo/demo-session.ts` `DEMO_MODE`: `… && NODE_ENV !== 'production'` → demo **login**
  also force-disabled in production (so no `_demo` session can even be minted).
- Result: **no fabricated dashboard metrics can ship.** Demo remains available in
  dev/test for backend-free exploration. Dashboard typecheck clean (prod source);
  **155 vitest tests still pass.**

## 3. Subscription/payment contract — matches the backend ✅
Dashboard billing maps to the **canonical plural** surface (no singular `/subscription`):
| Dashboard proxy | Backend client/path |
|---|---|
| `app/api/billing/plans` | `lib/api/clients/subscriptions.listPlans` → `/subscriptions/plans` |
| `app/api/billing/subscription` | `subscriptions.getSubscription` → `/subscriptions` |
| `app/api/billing/usage` | `subscriptions.getUsage` → `/subscriptions` |
| `app/api/billing/verify` | `/payments/verify`, `/payments/webhooks/razorpay`, `/subscriptions` |

Matches the mobile client (also corrected to plural this sprint) and the backend
controllers. **Matrix watch-item resolved — no contract mismatch.**

## 4. Remaining (this report's scope)
- **Live verification BLOCKED_EXTERNAL** — needs a running backend + (for E2E)
  `npm i -D @playwright/test`. Live login, real metrics, role/tenant isolation, and
  test-mode payment are unverified here.
- Open defects: **D3** (`features/expiry/scope-change.test.tsx` `scope` type drift — test
  only), **D4** (`@playwright/test` not installed). D1/D2 fixed earlier.
- Per-page/per-control audit + the deeper domain repairs remain (Phase 6) and are gated on
  a running backend.
