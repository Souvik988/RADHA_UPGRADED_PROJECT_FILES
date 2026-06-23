# PHASE 05 — API client layer

## Goal
Build the typed `lib/api/*` HTTP layer that is the **only** place the app talks to the backend:
`apiFetch<T>()` (auth injection, `x-request-id`, 401 silent-refresh-and-retry-once, normalized typed
errors), Zod schemas mirroring backend DTOs, per-domain typed clients, and TanStack Query setup.
Refactor Phase 03/04 ad-hoc fetches onto this layer.

## Depends on
Phase 03 (session/refresh), Phase 04 (store scope). Foundations for all of 06–18.

## Doc references
- Doc 1 §2.4 (conventions: base path, Bearer, `x-request-id`, cursor pagination), §6 (endpoint catalog).
- Doc 3 §A.1 (functional architecture), §A.2 (`apiFetch`), §A.5 (caching/error model), §B.4 (validate at edge), §B.9 (`x-request-id` propagation).

## Scope (in)
- `lib/api/core/api-fetch.ts` — `apiFetch<T>(path, {method, body, query, schema, signal})`:
  - Runs server-side (server components/actions/route handlers) so the Bearer is attached from the
    httpOnly cookie; client callers go through server actions or `/api/*` proxies.
  - Adds `Authorization: Bearer`, `x-request-id` (uuid), `Content-Type`.
  - On 401 → call refresh once → retry; on second 401 → throw `UnauthorizedError` (triggers logout).
  - Normalizes backend `ErrorCode`/`BusinessException` → typed `ApiError {code,message,fields?,status}`.
  - Validates the response with the passed Zod `schema` (Doc 3 §B.4) — reject malformed payloads.
- `lib/api/core/errors.ts` — typed error classes + `toUiError()` mapping (field/inline/toast).
- `lib/api/core/pagination.ts` — cursor helpers `(created_at desc, id desc)`; `Paginated<T>` type.
- `lib/api/core/query-client.tsx` — TanStack `QueryClientProvider` (staleTime 30–60s defaults,
  retry/backoff, 429 handling), mounted in `(dash)/layout`.
- `lib/api/schemas/` — shared Zod primitives (UUID, ISO date, money, EAN) + `UserMe`, `TokenPair`,
  `Store`, `DashboardKpis`, `AlertItem`, `HealthScore`, etc. (mirror Doc 1 shapes).
- Per-domain typed clients (functions only; no React) — one file each, matching Doc 1 §6:
  `auth.ts, dashboard.ts, stores.ts, tenants.ts, products.ts, ean-lists.ts, scan-sessions.ts,
  expiry.ts, tasks.ts, inventory.ts, grn.ts, suppliers.ts, reports.ts, subscriptions.ts,
  payments.ts, analytics.ts, marketing.ts, admin.ts, notifications.ts, feature-flags.ts,
  webhooks.ts, recall.ts, referrals.ts`. Each exports typed fns (e.g. `getKpis(storeId)`,
  `listExpiry(filters)`) returning Zod-validated data.
- `lib/api/index.ts` — barrel.
- Refactor: replace Phase 03/04 direct fetches with `apiFetch` (server-side).
- A throttle/debounce util `lib/api/core/rate.ts` (search debounce, poll throttle, 429 backoff).

## Out of scope
Screen UI (later phases). 🆕 PROPOSED endpoints (Doc 1 §8) get **typed stubs that throw
`NotImplementedBackendError`** so callers can render a "needs backend" state — never a fake request.

## Step-by-step
1. Implement `apiFetch` server-side; read base URL from `NEXT_PUBLIC_API_BASE_URL`; pull Bearer from
   `getSession()`. Generate `x-request-id` per call and log/propagate it.
2. Implement the 401 → refresh-once → retry loop using the Phase 03 refresh handler; on failure throw
   `UnauthorizedError`.
3. Build error normalization mapping backend error codes to `ApiError`; `toUiError` decides
   field/inline/toast placement.
4. Author shared Zod schemas first, then per-domain clients. Keep each fn small: build query string
   (scoped `storeId` from caller), call `apiFetch` with the response schema.
5. Mark 🆕 PROPOSED fns clearly (JSDoc `@proposed`) and have them throw `NotImplementedBackendError`.
6. Set up TanStack Query provider with sensible defaults + 429 backoff; expose query-key factories
   per domain for cache invalidation (Doc 3 §A.5 — posting GRN invalidates inventory + dashboard).
7. Refactor Phase 03/04 fetches onto the new client. Verify.

## API wiring
All of Doc 1 §6 endpoints get a typed function. Conventions enforced centrally: `/api/v1` base,
Bearer, `x-request-id`, cursor pagination, strict Zod query objects (e.g. dashboard requires
`storeId` UUID except `multi-store`; `limit` 1–100 on activity).

## Design spec
No visual surface beyond the query provider. Provides the loading/empty/error data states that
Phase 02 components render (Doc 3 §A.5).

## Security checks
- API client is the **sole** HTTP layer; components never call `fetch` directly (Doc 2 §8, Doc 3 §A.1).
- Bearer attached server-side only; never exposed to client JS (§B.5).
- Response Zod-validation at the boundary (§B.4); reject malformed/oversized payloads.
- Propagate `x-request-id` for traceability (§B.9). No tokens/PII in query strings or logs.
- 429 backoff + debounce/throttle (§B.8). 🆕 endpoints never issue a real request.

## Acceptance criteria
- [ ] `apiFetch` injects auth + `x-request-id`, validates with Zod, and silent-refreshes once on 401.
- [ ] Every Doc 1 §6 endpoint has a typed client fn returning validated data.
- [ ] 🆕 PROPOSED fns throw `NotImplementedBackendError` (no network call).
- [ ] TanStack Query provider mounted; query-key factories + invalidation helpers exist.
- [ ] Phase 03/04 fetches refactored onto the client. `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- Unit-spot-check (optional Vitest): mock a 401 → assert one refresh + one retry; mock a malformed
  payload → assert Zod rejection; call a 🆕 fn → assert it throws `NotImplementedBackendError`.
- User: confirm Overview placeholder can load `/dashboard/kpis` through the client (dev backend up).

## Rollback note
Additive `lib/api/*` + provider. Revert by restoring Phase 03/04 direct fetches and removing
`lib/api/`. No backend changes.
