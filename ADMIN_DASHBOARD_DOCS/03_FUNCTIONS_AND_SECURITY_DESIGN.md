# RADHA Admin Dashboard — Master Doc 3/3

## Function Design & Security Design (Next.js)

> **Scope.** The functional spec (what every feature module *does* and the
> backend functions it composes), the **proposed new enterprise functions**, and
> the full **security design** for the **RADHA Admin/Owner Dashboard** Next.js app.
> Reads alongside Doc 1 (APIs) and Doc 2 (UI).
>
> **Honest-data rule.** Existing functions cite real Doc 1 endpoints. New
> capabilities are tagged **🆕 PROPOSED** and require the backend endpoint to be
> built first (see Doc 1 §8). Never ship UI that fabricates data for an endpoint
> that doesn't exist.

---

## PART A — FUNCTION DESIGN

### A.1 Functional architecture (frontend)

```
Next.js App Router
  ├─ middleware.ts          → route guard (session + role/permission)
  ├─ lib/api/*              → typed API client per domain (Doc 1)
  ├─ lib/auth/*             → session, token refresh, RBAC helpers
  ├─ lib/permissions.ts     → mirror of backend permission catalog
  ├─ features/<domain>/     → page + hooks + components + schemas
  │     ├─ *.queries.ts     → TanStack Query / RSC fetchers
  │     ├─ *.actions.ts     → server actions (mutations)
  │     ├─ *.schema.ts      → Zod (mirrors backend DTOs)
  │     └─ components/*
  └─ components/ui/*        → shared design-system primitives (Doc 2 §4)
```

**Layering (mirror of backend discipline):**
- **Page/Component** = presentation only.
- **Hook/Query** = data orchestration (fetch, cache, optimistic update).
- **API client** = the only place that talks HTTP. Typed, versioned (`/api/v1`),
  injects auth, handles 401-refresh, normalizes errors.
- **Schema** = Zod validation at the boundary (request + response shape).

### A.2 Cross-cutting functions

| Function | Behaviour | Backend |
|---|---|---|
| `apiFetch<T>()` | Adds `Authorization`, `x-request-id`; on 401 → silent refresh + retry once; maps errors to typed result | all |
| `useSession()` | Returns `{user, role, permissions, storeIds}` | `/auth/me` |
| `can(permission)` / `hasRole(role)` | Client RBAC gate for UI affordances (server re-checks) | `permission.types` |
| `useStoreScope()` | Current `storeId` (from switcher) injected into queries | `/stores` |
| `useDateRange()` | Global `from`/`to` for dashboard/analytics | dashboard/analytics |
| `exportJob()` | Kicks an export, polls artefact list, returns presigned URL | `/reports/*` |
| `toastResult()` | Success/error/undo toasts, `aria-live` | n/a |

### A.3 Module-by-module function spec (existing)

#### A.3.1 Auth & session
- **Login** (`/auth/admin/login`) → set httpOnly session cookie, hydrate
  `/auth/me`, redirect by role.
- **Refresh** (`/auth/refresh`) → rotate on 401, silent.
- **Logout** (`/auth/logout`) → revoke session, clear cookie.
- **Password reset** (`/auth/password/reset/request|complete`), **email verify**
  (`/auth/email/verify`), **accept invite** (`/auth/admin/invitations/accept`).

#### A.3.2 Overview / dashboard
- Compose KPIs, alerts, quick-actions, trends, team, activity, health-score from
  `/dashboard/*`. Multi-store rollup (owner) from `/dashboard/multi-store`.
- Functions: `loadOverview(storeId, range)`, `loadMultiStore()`,
  `resolveAlertAction(alert)`, `kpiTrend(kpi)`.

#### A.3.3 Expiry
- `listExpiry(filters)`, `expiryStats()`, `expiryByCategory()`, `calendarHeat()`,
  `acknowledgeAlert(id)`, `resolveAlert(id)`, `getThresholds()/saveThresholds()`,
  `ocrValidate(image)`. → `/expiry-records/*`, `/expiry-thresholds`,
  `/expiry-alerts/*`, `/expiry/ocr/validate`.

#### A.3.4 Tasks
- `listTasks/createTask/updateTask/deleteTask`, workflow
  `start|complete|reject|cancel|reassign`, `taskStats()`,
  templates CRUD + `instantiate`, `autoFromAlert()`, evidence add/remove.
  → `/tasks/*`, `/task-templates/*`.

#### A.3.5 Inventory & GRN
- Inventory: `summary/categoryBreakdown/counts/movements/lowStock`,
  `stockIn/stockOut/adjust` (permission-gated). → `/inventory/*`.
- GRN: `listGrn/createGrn/getGrn/updateGrn`, items CRUD, workflow
  `validate|post|cancel|reverse`, `grnStats()`. → `/grn/*`.

#### A.3.6 Suppliers
- CRUD + `search/import/export`, contacts CRUD, status
  `activate/deactivate/blacklist`, `performance()`. → `/suppliers/*`.

#### A.3.7 Audit / EAN
- Lists CRUD + `activate/deactivate`, `import(file)`, import monitoring
  (`imports/:batchId`, `/errors`, `/errors/csv`), `validate/validateBatch`,
  items list, scan-session review. → `/ean-lists/*`, `/scan-sessions/*`.

#### A.3.8 Reports
- `buildExport(spec)`, `reExport(id)`, `listFiles(id)`, `downloadUrl(...)`.
  → `/reports/*`, `/report-files/*`.

#### A.3.9 Analytics & leads
- `websiteStats/websiteFunnel/fullFunnel`, `tenantActivity`, lead pipeline
  `list/get/updateStatus/convert`. → `/analytics/*`, `/marketing/leads/*`.

#### A.3.10 Billing
- `getStatus/getUsage/getPlans`, `upgrade/cancel/reactivate`,
  `checkout/verify/refund`. → `/subscriptions/*`, `/payments/*`.

#### A.3.11 Notifications
- `inbox/markRead/markAllRead/preferences/testSend`, FCM token (web push).
  → `/notifications/*`.

#### A.3.12 Platform admin
- `impersonateStart/End`, `impersonationAudit`, feature flags (`/feature-flags/me`),
  webhooks CRUD + deliveries + replay (`/webhooks/*`). → `/admin/*`.

### A.4 🆕 PROPOSED enterprise functions (need backend first — Doc 1 §8)

> Useful for an enterprise back-office; **not in the codebase today.** Build the
> backend endpoint, add the permission, enforce tenant/store scope + audit, then
> wire these.

1. **Team & access management** — `listUsers/inviteUser/updateRole/deactivate/
   userActivity`. (Doc 1 §8.1 `/users/*`). Today only invite-accept exists.
2. **Unified audit-log viewer** — `searchAuditLogs(filters)`. Data is already
   written on every mutation; expose a read API (`/audit-logs`).
3. **Saved views & alert rules** — `saveView/listViews`, `createAlertRule` so
   owners define low-stock %/expiry windows (`/dashboard/saved-views`, `/alert-rules`).
4. **Scheduled & emailed reports** — `scheduleReport(cron, recipients)` on top of
   the export engine.
5. **Cross-store compare & cohorts** — `compareStores`, `cohorts`
   (`/analytics/stores/compare`, `/analytics/cohorts`).
6. **Platform-admin console** — `listTenants/inspect/suspend`, `platformMetrics`
   (MRR/active/churn), `manageFeatureFlags`, `platformSettings` (`/admin/*`).
7. **Broadcast comms** — `broadcast(segment, message)` (`/notifications/broadcast`).
8. **Billing back-office** — `invoices/transactions/invoicePdf` (`/billing/*`).
9. **Bulk operations** — multi-select bulk task assign / expiry resolve / supplier
   status, with **undo** + audit. (Composes existing per-item endpoints; a batch
   endpoint is the enterprise upgrade.)
10. **Global search (⌘K)** — `globalSearch(q)` spanning products/suppliers/tasks/
    GRN/stores (`/search/global` 🆕, or client-side fan-out short-term).

### A.5 State, caching & error model
- **Caching:** TanStack Query — `staleTime` 30–60s for KPIs/lists; invalidate on
  mutation (e.g. posting a GRN invalidates inventory + dashboard caches, mirroring
  backend `IDashboardCacheInvalidator`).
- **Optimistic updates** for task/GRN workflow with rollback on error.
- **Error normalization:** map backend `ErrorCode`/`BusinessException` to typed UI
  errors → field-level (form), inline (panel), or toast. Always offer retry.
- **Loading:** skeletons (Doc 2 §4.11), never blocking spinners >300ms.

---

## PART B — SECURITY DESIGN

> The backend already enforces auth, RBAC, tenant scope, validation, audit, and
> rate-limiting. The dashboard must **never weaken** these and must add
> **web-specific** protections (session storage, CSRF, headers, CSP).

### B.1 Threat model (top risks)
1. Token theft (XSS / insecure storage) → account/tenant takeover.
2. Cross-tenant data access (broken object-level authorization).
3. Privilege escalation (calling owner/admin endpoints as manager/staff).
4. CSRF on state-changing requests.
5. Leakage of secrets/PII in logs, URLs, or client bundles.
6. Abuse of impersonation, refunds, broadcasts, exports.
7. Supply-chain (malicious npm dependency).

### B.2 Authentication & session (web)
- **Login** via `/auth/admin/login`. Store the JWT pair in **httpOnly, Secure,
  SameSite=Lax** cookies set by a Next.js Route Handler / server action — **not**
  in `localStorage` (XSS-exfiltration risk).
- **Access token** short-lived (`expiresIn`, ~15m); **refresh** rotating,
  server-tracked, revocable. Silent refresh on 401 via `/auth/refresh`; on refresh
  failure → hard logout.
- **Logout** calls `/auth/logout` (server revokes session) and clears cookies.
- **Idle + absolute timeouts**; re-auth for sensitive actions (refund,
  impersonation start, plan change) — step-up confirm.
- Password policy enforced by backend (min 12). Surface a strength meter; never
  store passwords client-side.

### B.3 Authorization (defense in depth)
- **Server-side first.** The backend guard stack (`JwtAuthGuard → RolesGuard →
  PermissionsGuard → TenantScopeGuard → StoreScopeGuard`) is the real boundary.
- **Next.js `middleware.ts`** gates routes by role/permission for UX, and **server
  components / server actions re-check** before rendering admin data (never trust
  the client toggle).
- **Client `can()`/`hasRole()`** only hides/disables affordances — assume it can be
  bypassed; the API still rejects.
- **Tenant/store scope:** always send the scoped `storeId`; never let a user pick a
  store outside `session.storeIds`. Treat any cross-scope 403 as a security event.
- **Least privilege:** Admin (platform) section bundle is code-split and only
  loaded for `role === 'admin'`.

### B.4 Input / output safety
- **Validate at the edge:** mirror backend Zod schemas (Doc 1) with React Hook
  Form + Zod; reject before sending.
- **Output encoding:** React escapes by default — **never** `dangerouslySet
  InnerHTML` with server/user content. Sanitize any rich text (DOMPurify) if ever
  needed.
- **No secrets in the bundle:** only `NEXT_PUBLIC_*` are public. API base URL is
  public; keys/secrets stay server-side (Route Handlers / server actions).
- **No sensitive data in URLs** (tokens, PII) — they leak via logs/referrer.

### B.5 CSRF & request integrity
- Cookie-based auth → enable **CSRF protection** for state-changing requests:
  `SameSite=Lax` + double-submit token (or origin/referer check) on POST/PATCH/
  DELETE issued from the browser.
- Prefer **server actions / Route Handlers** as the mutation surface so the bearer
  token is attached server-side and never exposed to client JS.
- Razorpay checkout: verify on server (`/payments/verify`); the webhook
  (`/payments/webhooks/razorpay`) is the billing source of truth and is
  signature-verified by the backend — the dashboard never trusts client-side
  payment success alone.

### B.6 HTTP security headers / CSP (Next.js)
Set via `next.config` headers / middleware:
- `Content-Security-Policy`: `default-src 'self'`; allow only the API origin in
  `connect-src`, self + needed CDNs in `script-src`/`style-src`, `img-src` for S3/
  CloudFront product images; **no `unsafe-inline` scripts**.
- `Strict-Transport-Security` (HSTS), `X-Content-Type-Options: nosniff`,
  `X-Frame-Options: DENY` (or `frame-ancestors 'none'`), `Referrer-Policy:
  strict-origin-when-cross-origin`, `Permissions-Policy` (disable camera/mic/geo
  unless used).
- Backend already uses `helmet` + `compression`; keep both layers.

### B.7 Sensitive operations (extra controls)
| Operation | Control |
|---|---|
| **Impersonation** (`/admin/impersonate`) | admin-only; step-up confirm; time-boxed; persistent "impersonating {user}" banner; every session audited (`/admin/impersonations/audit`); auto-end on logout |
| **Refund** (`/payments/refund`) | admin/owner only; confirm dialog with amount + reason; audit |
| **Destructive deletes** (products, EAN lists, suppliers, tasks) | confirm dialog (type-to-confirm for bulk); undo where reversible; audit |
| **Bulk actions** (🆕) | preview affected count; explicit confirm; undo toast; rate-limited |
| **Broadcast** (🆕) | segment preview + confirm; rate-limited; audited |
| **Exports/downloads** | presigned, short-TTL URLs (backend `expirySeconds`); never embed credentials |

### B.8 Rate limiting & abuse
- Backend enforces per-route + per-tier rate limits (`rate-limiting` module, public
  rate-limit guard on public analytics). Dashboard should **debounce** search/
  autocomplete, **throttle** polling (feature flags ~5min, activity feed sensible
  intervals), and back off on 429 with a clear message.

### B.9 Logging, monitoring & privacy
- Backend redacts PII in logs and tags requests with `x-request-id` — propagate it
  from the dashboard for traceability.
- Client-side: send errors to Sentry **without** PII/tokens; scrub before capture.
- Show only data the backend returns (honest-data rule); mask partial PII in tables
  where appropriate (e.g. phone `+91 ••• ••12 34`).
- Respect data-retention + consent flows already modelled in the product
  (onboarding consent).

### B.10 Supply chain & build hygiene
- Pin dependency versions; prefer well-maintained packages; watch for typosquats.
- `npm audit` / Dependabot in CI; lockfile committed.
- No secrets in the repo or client env; use a secrets manager for server env.
- SRI for any third-party scripts; minimize third-party JS (CSP `connect-src`
  allowlist).

### B.11 Network-exposed surface note
> The dashboard is an **authenticated** web app. Do **not** deploy any dashboard
> route or proxy that forwards to the backend without auth. If a BFF/proxy layer is
> added in Next.js, it MUST attach the session-derived bearer token server-side and
> re-enforce role/permission — an unauthenticated proxy would bypass the entire
> backend guard stack.

---

## PART C — DELIVERY CHECKLIST

**Functional**
- [ ] Every page wires only to real Doc 1 endpoints; 🆕 features gated until backend ships.
- [ ] API client is the sole HTTP layer; 401 silent-refresh works; errors typed.
- [ ] Tenant/store scope sent on every scoped call; date-range honored.
- [ ] Optimistic updates + cache invalidation on workflow mutations.
- [ ] All states designed: loading / empty / error / locked / offline.

**Security**
- [ ] Tokens in httpOnly Secure SameSite cookies; no token in localStorage/URL.
- [ ] Middleware + server-side re-check for role/permission; client gate is cosmetic.
- [ ] CSRF protection on browser-issued mutations; mutations via server actions.
- [ ] CSP + HSTS + nosniff + frame-deny + referrer-policy headers set.
- [ ] Step-up confirm + audit on impersonation, refund, destructive, bulk, broadcast.
- [ ] Sentry scrubs PII/tokens; `x-request-id` propagated.
- [ ] `npm audit` clean; deps pinned; no secrets in bundle.

**Design (cross-ref Doc 2)**
- [ ] Tokens-only styling; one orange CTA per region; mono numbers.
- [ ] a11y: 4.5:1 contrast, focus rings, keyboard nav, aria-sort/live, reduced-motion.
- [ ] Anti-slop gate passed.

*End of Doc 3. See `01_ARCHITECTURE_AND_API.md` and `02_DASHBOARD_UI_DESIGN.md`.*
