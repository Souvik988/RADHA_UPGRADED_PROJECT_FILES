# RADHA — Dashboard Discovery Report

**The completed dashboard exists.** Located by exhaustive workspace search (Phase 1).

## Location & identity
- **Path:** `RADHA_UPGRADED_PROJECT_FILES/radha_dashboard/` (in the export working tree on
  branch `codex/radha-production-convergence`; **not** on `origin/main` — origin/main's
  `apps/owner-dashboard` is the empty "planned" placeholder).
- **Framework:** Next.js **15.3.9** (App Router) + React **19.1.0**, TypeScript, Tailwind +
  shadcn/ui (`components.json`), package manager **npm** (`package-lock.json`).
- **Name:** `radha-dashboard`.
- **`node_modules` present** → it builds/tests locally without an install.
- Specs/docs: `.kiro/specs/dashboard-production-ready`, `.kiro/specs/radha-dashboard-redesign`,
  `ADMIN_DASHBOARD_DOCS/`.

## Scripts
`dev` (next dev) · `build` (next build) · `start` · `lint` (next lint) · `typecheck`
(`tsc --noEmit`) · `test` (`vitest run`). E2E perf specs under `tests/perf/` use
`@playwright/test` (**not installed**).

## Backend wiring — already the canonical backend
- API base URL: **`NEXT_PUBLIC_API_BASE_URL`** (default `http://localhost:3000`) + `/api/v1`
  — the **same backend + prefix as mobile** (`lib/api/core/api-fetch.ts`).
- Auth: JWT with refresh (`lib/auth/refresh-session.ts`, `use-session.ts`,
  `refresh-lock.test.ts`) + `middleware.ts` route protection.
- RBAC: `lib/permissions.ts` (+ `permissions.test.ts`), role-based nav `lib/nav-config.ts`.
- **`NEXT_PUBLIC_DEMO_MODE`** flag (+ `lib/demo/`) — a demo/mock path that must be audited
  so no fake metrics ship in production mode.

## Pages (App Router, `(auth)` + `(dash)` route groups)
`(auth)/login`; `(dash)/` overview + admin/audit-logs, admin/tenants, analytics/compare,
billing/invoices, notifications/broadcast, reports/schedule, expiry, … (full enumeration is
a Phase-3 matrix task). Many pages call `/api/v1/*` directly.

## State / design
shadcn/ui components, Tailwind theme (`tailwind.config.ts`), feature folders under
`features/*` (admin, analytics, expiry, …), charts in `lib/charts`.

## Verdict
**Usable — do NOT recreate.** It is a real, tested Next.js app already pointed at the
canonical `/api/v1` backend with JWT+RBAC. Remaining convergence work = connect to a running
backend, audit pages/actions, fix the recorded typecheck defects, retire `DEMO_MODE` mock
data in production, and bring it into the monorepo (`apps/`) for one-ecosystem layout.

See [FUNCTIONAL_CONVERGENCE_BASELINE.md](./FUNCTIONAL_CONVERGENCE_BASELINE.md) for build/test
results and [RADHA_MASTER_FUNCTION_MATRIX.md](./RADHA_MASTER_FUNCTION_MATRIX.md) (to be built).
