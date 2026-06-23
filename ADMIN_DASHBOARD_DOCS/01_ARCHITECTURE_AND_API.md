# RADHA Admin Dashboard — Master Doc 1/3

## Full Architecture, Workflow & API Use-Case Reference

> **Scope.** This document is the single source of truth for the **RADHA Admin /
> Owner Dashboard** (a private **Next.js** web app). It maps the *actual* NestJS
> backend (`radha_backend/`) API surface that the dashboard consumes, the auth +
> multi-tenancy model, the role/permission matrix, end-to-end workflows, and a
> clearly-marked set of **proposed enterprise-grade endpoints** that do not exist
> yet but fit the product.
>
> **Honest-data rule.** Everything in §1–§7 is verified against the codebase.
> Everything in §8 is labelled **🆕 PROPOSED** — it is a design recommendation,
> not a shipped feature. Do not render proposed data as if it were live.

---

## 1. What RADHA is (context for the dashboard)

**RADHA** — *Retail Assistant for Data, Health & Audits* — is a mobile-first retail
audit platform for Indian retail teams. The mobile app (Flutter) is for staff on
the floor; the **Admin/Owner Dashboard** (this Next.js project) is the back-office
command centre for **Owners, Tenant Admins, Managers**, and the **RADHA platform
Admin** (support/operations).

Core domains the dashboard surfaces: store operations, expiry tracking, tasks,
inventory + GRN, EAN/approved-list audits, scanning analytics, subscriptions &
billing, leads/marketing funnel, operational health scoring, and platform
administration (tenants, impersonation, feature flags).

---

## 2. System architecture

### 2.1 Runtime topology

```
                          ┌─────────────────────────────────────────────┐
   Next.js Admin Dashboard│  (this project — SSR/CSR, server actions)    │
   Flutter Mobile App     │                                              │
            │             └─────────────────────────────────────────────┘
            │ HTTPS  (Bearer JWT)   base path:  /api/v1
            ▼
   ┌───────────────────────────────────────────────────────────────────┐
   │                       NestJS modular monolith                       │
   │                                                                     │
   │  main.api.ts        REST API process  (controllers → services →     │
   │                     repositories)                                   │
   │  main.worker.ts     BullMQ workers (imports, OCR, reports, AI,      │
   │                     notifications)                                  │
   │  main.scheduler.ts  cron (reminders, rollups, cleanup)              │
   └───────────────────────────────────────────────────────────────────┘
        │                     │                      │
        ▼                     ▼                      ▼
   PostgreSQL            Redis (BullMQ +        External providers:
   (Drizzle ORM)         ioredis cache)         2Factor.in (OTP), Razorpay,
                                                S3/CloudFront/Rekognition,
                                                Google Vision/Gemini, OFF, FCM
```

### 2.2 Backend layering rules (enforced)

- **Controllers** = transport only (validation + delegation). No business logic.
- **Services** own business logic + transactions.
- **Repositories** own all DB access (Drizzle). No business logic.
- **Integrations** wrap every third-party SDK (2Factor, Razorpay, AWS, Gemini,
  OFF, FCM). Services never call SDKs directly.
- Every state-changing write also writes an **audit log**.
- Every multi-tenant query carries `tenant_id` (and `store_id` where applicable).

### 2.3 Tech stack (backend)

NestJS 10 · Drizzle ORM over PostgreSQL · BullMQ + ioredis · `class-validator` +
`zod` for validation · `@nestjs/jwt` + `bcrypt` for auth · `nestjs-pino` logging ·
`helmet` + `compression` · Sentry · S3/CloudFront · Razorpay · FCM.

### 2.4 API conventions

| Aspect | Value |
|---|---|
| Global prefix | `api` (`API_PREFIX`, default `api`) |
| Versioning | URI-based, default version `1` |
| **Effective base path** | **`/api/v1`** |
| Auth header | `Authorization: Bearer <accessToken>` |
| Validation | Zod (`ZodValidationPipe`) + `class-validator` DTOs |
| IDs | UUID v4 (`ParseUuidPipe` on path params) |
| Pagination | Cursor on `(created_at desc, id desc)` or domain sort |
| Request id | `x-request-id` header (correlated in logs) |

> Example absolute URL (local): `http://localhost:3000/api/v1/dashboard/kpis`
> Android emulator reaches host backend at `http://10.0.2.2:3000/api/v1`.

---

## 3. Multi-tenancy model

- Every business table is scoped by `tenant_id`; operational tables also by
  `store_id`.
- Enforced at the **guard + service/repository** layer:
  - `TenantScopeGuard` — derives `tenantId` from the JWT, blocks cross-tenant access.
  - `StoreScopeGuard` — verifies the user can access the requested `:storeId`
    (only active when `@RequireStore()` is present).
  - `@RequireTenant()` — asserts a tenant context exists (consumer signups may not
    have one yet).
- **Owner** sees all stores in their tenant. **Manager/Staff/Auditor** see only
  their assigned stores (`storeIds` on the JWT). **Admin** (RADHA platform) can
  cross tenants only via the explicit **impersonation** flow (§7.6).

---

## 4. Authentication & session workflow

RADHA has **two** auth front doors. The Admin Dashboard primarily uses the
**email/password admin door**; the mobile app uses **OTP**.

### 4.1 Token model

`POST` auth endpoints return a `TokenPair` (+ user on verify/login):

```jsonc
{
  "accessToken": "<JWT>",
  "refreshToken": "<JWT>",
  "expiresIn": 900,           // seconds (access token TTL)
  "user": { /* UserMeResponse */ }
}
```

Access-token JWT payload (`AccessTokenPayload`): `sub` (userId), `tenantId`,
`role`, `sessionId`, `iat/exp/iss/aud`. Refresh tokens are rotating (`jti`,
server-tracked sessions, revocable).

### 4.2 Admin Dashboard login flow (email/password)

```
1. POST /api/v1/auth/admin/login        { email, password, deviceId? }
      → 200 { accessToken, refreshToken, expiresIn, user }
2. Store tokens (httpOnly cookie recommended — see Doc 3 §Security).
3. Call GET /api/v1/auth/me to hydrate role/permissions/storeIds.
4. On 401, POST /api/v1/auth/refresh    { refreshToken }  → new TokenPair.
5. POST /api/v1/auth/logout (Bearer)    → 204, revokes the session.
```

Supporting admin-identity endpoints:

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/v1/auth/admin/login` | Email/password login (200) |
| POST | `/api/v1/auth/password/reset/request` | Begin reset → `{status:'queued'}` |
| POST | `/api/v1/auth/password/reset/complete` | Finish reset `{token,newPassword}` |
| POST | `/api/v1/auth/email/verify` | Verify email `{token}` |
| POST | `/api/v1/auth/admin/invitations/accept` | Accept admin invite `{token,name,password}` |

> Password policy (from DTOs): reset/invite passwords **min 12, max 128 chars**;
> new password must differ from current.

### 4.3 Mobile OTP flow (for reference / shared accounts)

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/v1/auth/otp/request` | Issue OTP via SMS → `{requestId, expiresIn, attemptsRemaining}` |
| POST | `/api/v1/auth/otp/verify` | Verify OTP → `TokenPair` + user |
| POST | `/api/v1/auth/token/refresh` | Rotate (legacy alias of `/refresh`) |
| POST | `/api/v1/auth/refresh` | Canonical refresh |
| POST | `/api/v1/auth/logout` | Revoke current session (204) |
| GET | `/api/v1/auth/me` | Current user bootstrap |

`GET /api/v1/auth/me` → `UserMeResponse`: `{ id, mobile, name, role, tenantId,
storeIds[], permissions[], isVerified, bypassOnboarding, createdAt }`.

---

## 5. Roles & permissions matrix

### 5.1 Roles (`UserRole`)

`admin` (RADHA platform/support) · `owner` (tenant owner) · `manager` ·
`staff` · `auditor` · `consumer` (mobile end-user, not a dashboard role).

### 5.2 Permission catalog (namespaced `domain:action`)

Users / identity: `users:read|write|delete|invite` · Products:
`products:read|write|delete|bulk-import` · Scans: `scans:read|write|delete|export`
· Tasks: `tasks:read|write|assign|delete` · Reports:
`reports:read|generate|export` · Inventory: `inventory:read|write|adjust` · GRN:
`grn:read|write|post|cancel` · Subscriptions: `subscriptions:read|manage` ·
Owner-tier: `owner:dashboard|analytics|billing` · Platform admin:
`admin:tenants:read|write`, `admin:platform:settings`, `admin:invite`,
`admin:revoke`.

### 5.3 Role → capability (dashboard view)

| Capability | admin | owner | manager | staff | auditor |
|---|:---:|:---:|:---:|:---:|:---:|
| Owner dashboard (`/dashboard`) | ✅ | ✅ | partial | partial | partial |
| Multi-store summary | ✅ | ✅ | — | — | — |
| Trends / team / health-score | ✅ | ✅ | ✅ | — | — |
| Products write/delete | ✅ | ✅ | write | — | — |
| EAN lists write | ✅ | ✅ | ✅ | — | — |
| Inventory adjust | ✅ | ✅ | ✅ | stock in/out | — |
| GRN post/cancel | ✅ | ✅ | post | write | — |
| Reports export | ✅ | ✅ | ✅ | view | view |
| Subscriptions manage | ✅ | ✅ | — | — | — |
| Website analytics / funnel | ✅ | ✅ | — | — | — |
| Marketing leads | ✅ | ✅ | — | — | — |
| Tenants admin / impersonation | ✅ | — | — | — | — |
| Refunds | ✅ | ✅ | — | — | — |

> Effective permissions = role-set (`ROLE_PERMISSIONS_MAP`) **∪** per-user grants
> on `AuthenticatedUser.permissions`. The guard stack is
> `JwtAuthGuard → RolesGuard → PermissionsGuard → TenantScopeGuard → StoreScopeGuard`.

---

## 6. Complete API catalog (dashboard-relevant)

All paths are prefixed with `/api/v1`. "Roles" lists who may call. Tenant/Store
scoping is noted where it applies.

### 6.1 Client Dashboard — `/dashboard/*` (read-only, tenant+store scoped)

| Method | Path | Roles | Notes |
|---|---|---|---|
| GET | `/dashboard` | owner, manager, staff, auditor | Full payload for `?storeId` (+ `from`/`to`) |
| GET | `/dashboard/kpis` | owner, manager, staff, auditor | KPI tiles for store |
| GET | `/dashboard/alerts` | owner, manager, staff, auditor | Critical/warning/info alerts |
| GET | `/dashboard/quick-actions` | owner, manager, staff, auditor | Context actions for current user |
| GET | `/dashboard/trends` | owner, manager | Time-series (scans/expiry/tasks/inventory) |
| GET | `/dashboard/team` | owner, manager | Top scanners, task leaders |
| GET | `/dashboard/activity` | owner, manager, staff, auditor | Recent activity feed (`?limit`) |
| GET | `/dashboard/health-score` | owner, manager | OHS latest + 30d trend |
| GET | `/dashboard/multi-store` | **owner only** | Aggregated cross-store summary |

**KPI shape (`DashboardKpis`):** `scansToday/Week/Month`, `expiringNextWeek`,
`expiredItems`, `pendingTasks`, `overdueTasks`, `completedToday`, `totalProducts`,
`lowStockItems`, `eanMatchRate` (0–100), `trends{scans,expiry,tasks,inventory}`.

**Alerts:** `{ total, critical[], warning[], info[] }`; each `AlertItem` has
`type` (`expiry_red|expiry_yellow|low_stock|task_overdue|ean_mismatch_spike|system`),
`title`, `description`, `count`, `actionUrl?`.

**Operational Health Score (OHS):** weighted 0–100 from six components —
`compliance, expiryManagement, inventoryAccuracy, taskCompletion, teamActivity,
vendorQuality` — with per-component breakdown, raw inputs, and algorithm version.

> ⚠️ Query params are **strict** Zod objects: `storeId` (UUID, required on all
> except `multi-store`), `from`/`to` (ISO date), `limit` (1–100, activity only).

### 6.2 Operational Health Scoring — mixed prefixes

| Method | Path | Roles | Notes |
|---|---|---|---|
| GET | `/products/:productId/health` | (products:read) | Product health score |
| POST | `/products/:productId/health/recompute` | (products:read) | Recompute one |
| POST | `/products/health/bulk-recompute` | (products:read) | Recompute many |
| GET | `/products/health/filter` | (products:read) | Filter by health flags |
| GET | `/health-scoring/rules` | (products:read) | Active scoring rules |
| GET | `/health-scoring/stats` | admin, owner | Scoring stats |

### 6.3 Stores — `/stores/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/stores` | owner, admin |
| GET | `/stores` | owner, manager, staff, auditor, admin |
| GET | `/stores/:storeId` | (store-scoped) |
| POST | `/stores/:storeId/access` | (store-scoped) — grant user access |
| DELETE | `/stores/:storeId/access/:userId` | (store-scoped) — revoke |

### 6.4 Tenants — `/tenants/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/tenants/onboard` | **Public** — self-serve tenant creation |
| GET | `/tenants/me` | owner, manager, staff, auditor, admin |

### 6.5 Products & Catalog — `/products/*`, `/catalog/*`

| Method | Path | Roles / perm |
|---|---|---|
| GET | `/products/lookup/:ean` | all + consumer (`products:read`) |
| POST | `/products/lookup/batch` | owner, manager, staff, auditor, admin |
| GET | `/products` | search (`products:read`) |
| GET | `/products/:id` | (`products:read`) |
| POST | `/products` | owner, manager, admin (`products:write`) |
| PATCH | `/products/:id` | owner, manager, admin (`products:write`) |
| DELETE | `/products/:id` | owner, admin (`products:delete`) |
| GET | `/products/search` `/autocomplete` `/facets` `/popular` `/:id/similar` | (`products:read`) |
| GET | `/catalog/categories` `/catalog/products` | all + consumer |

### 6.6 EAN approved lists & bulk audit — `/ean-lists/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/ean-lists` | owner, manager, admin |
| GET | `/ean-lists` | owner, manager, staff, auditor, admin |
| POST | `/ean-lists/validate` · `/validate/batch` | (auth) — verify scanned EANs |
| GET | `/ean-lists/imports/:batchId` · `/errors` · `/errors/csv` | owner, manager, admin |
| POST | `/ean-lists/imports/:batchId/cancel` | owner, manager, admin |
| GET | `/ean-lists/:id` · `/:id/items` | owner, manager, staff, auditor, admin |
| PATCH/DELETE | `/ean-lists/:id` | owner, manager, admin |
| POST | `/ean-lists/:id/activate` · `/deactivate` · `/import` | owner, manager, admin |

### 6.7 Scans & sessions — `/scan-sessions/*`

| Method | Path | Roles |
|---|---|---|
| GET | `/scan-sessions/sync-batches` · `/:batchId` | owner, manager, staff, auditor, admin |
| POST | `/scan-sessions/sync-batches/:batchId/cancel` | (auth) |
| POST | `/scan-sessions` | create session (201) |
| GET | `/scan-sessions` · `/active` · `/:id` | owner, manager, staff, auditor, admin |
| (items) | `/scan-sessions/:id/items` … | add/remove session items |

### 6.8 Expiry — `/expiry-records/*`, `/expiry-thresholds`, `/expiry-alerts/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/expiry-records` | create (201) |
| GET | `/expiry-records` | owner, manager, staff, auditor, admin |
| GET | `/expiry-records/near-expiry` · `/expired` · `/forecast` | same |
| GET | `/expiry-records/stats` · `/stats/by-category` | same |
| POST | `/expiry-records/recalculate` | recompute |
| GET | `/expiry-records/:id` | same |
| GET/PUT | `/expiry-thresholds` | read / update category thresholds |
| GET | `/expiry-alerts` | same |
| POST | `/expiry-alerts/:id/acknowledge` · `/resolve` | workflow |
| POST | `/expiry/ocr/validate` | OCR MFG/EXP validation |

### 6.9 Tasks — `/tasks/*`, `/task-templates/*`

| Method | Path | Roles |
|---|---|---|
| POST/GET | `/task-templates` | templates CRUD |
| GET/PATCH/DELETE | `/task-templates/:id` | templates |
| POST | `/task-templates/:id/instantiate` | spawn task from template |
| GET | `/tasks/my` · `/tasks/stats` | dashboards |
| POST | `/tasks/auto-from-alert` | task from an alert |
| POST/GET | `/tasks` | CRUD |
| GET/PATCH/DELETE | `/tasks/:id` | CRUD |
| POST | `/tasks/:id/start` `/complete` `/reject` `/cancel` `/reassign` | workflow |
| POST | `/tasks/:id/evidence`, DELETE `/tasks/evidence/:evidenceId` | evidence |

### 6.10 Inventory — `/inventory/*`

| Method | Path | Roles |
|---|---|---|
| GET | `/inventory/summary` · `/category-breakdown` · `/counts` | owner, manager, staff, auditor, admin |
| GET | `/inventory/movements` · `/low-stock` | owner, manager, auditor, admin |
| GET | `/inventory/low-stock-rules` | owner, manager, admin |
| POST | `/inventory/stock-in` · `/stock-out` | owner, manager, staff, admin (`inventory:write`) |
| POST | `/inventory/adjust` | owner, manager, admin (`inventory:adjust`) |

### 6.11 GRN (goods receipt) — `/grn/*`

| Method | Path | Roles |
|---|---|---|
| GET | `/grn/stats` | owner, manager, auditor, admin |
| POST/GET | `/grn` | CRUD |
| GET/PATCH | `/grn/:id` | CRUD |
| POST/PATCH/DELETE | `/grn/:id/items[/:itemId]` | line items |
| POST | `/grn/:id/validate` `/post` `/cancel` `/reverse` | workflow |

### 6.12 Suppliers — `/suppliers/*`

| Method | Path | Roles |
|---|---|---|
| POST/GET | `/suppliers` | CRUD |
| GET | `/suppliers/search` · `/export` | search / Excel export |
| POST | `/suppliers/import` | bulk import |
| GET/PATCH/DELETE | `/suppliers/:id` | CRUD (write: owner/manager/admin) |
| POST | `/suppliers/:id/activate` `/deactivate` `/blacklist` | status |
| GET/POST | `/suppliers/:id/contacts`, DELETE `/suppliers/contacts/:contactId` | contacts |
| GET | `/suppliers/:id/performance` | owner, manager, auditor, admin |

### 6.13 Reports & exports — `/reports/*`, `/report-files/*`

| Method | Path | Roles / perm |
|---|---|---|
| POST | `/reports/export` | owner, manager, admin (`reports:export`) — ad-hoc |
| POST | `/reports/:id/export` | re-export existing report |
| GET | `/reports/:id/files` | list artefacts |
| GET | `/reports/:id/download/:format` | presigned URL by format |
| GET | `/report-files/:id/download` | presigned URL by file id |

### 6.14 Subscriptions & billing — `/subscriptions/*`, `/payments/*`

| Method | Path | Roles |
|---|---|---|
| GET | `/subscriptions/plans` | **Public** — plan catalog |
| GET | `/subscriptions/status` · `/usage` | (auth, tenant) |
| POST | `/subscriptions/upgrade` `/cancel` `/reactivate` | manage |
| POST | `/payments/checkout` | create Razorpay order |
| POST | `/payments/verify` | verify payment signature |
| POST | `/payments/refund` | **admin, owner** |
| POST | `/payments/webhooks/razorpay` | **Public** — Razorpay webhook (signature-verified) |

### 6.15 Analytics, funnel & marketing leads — `/analytics/*`, `/marketing/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/analytics/app/events` · `/events/batch` | all incl. consumer (202) |
| GET | `/analytics/app/me` | per-user activity |
| GET | `/analytics/app/tenant` | owner, manager, admin |
| GET | `/analytics/website/stats` · `/website/funnel` · `/funnel` | **owner, admin** |
| GET | `/marketing/leads` · `/leads/:id` | owner, admin |
| PATCH | `/marketing/leads/:id` | update status/notes |
| POST | `/marketing/leads/:id/convert` | convert lead → tenant |

### 6.16 Platform admin & impersonation — `/admin/*`

| Method | Path | Roles |
|---|---|---|
| POST | `/admin/impersonate` | **admin** — start support session (201) |
| DELETE | `/admin/impersonate` | **admin** — end current session |
| GET | `/admin/impersonations/audit` | **admin** — audit trail (`?staffUserId`, `?impersonatedUserId`, `?limit`) |

### 6.17 Notifications — `/notifications/*`

| Method | Path | Roles |
|---|---|---|
| GET | `/notifications` | all incl. consumer |
| GET/PATCH | `/notifications/preferences` | read/update prefs |
| POST | `/notifications/read-all` · `/:id/read` | mark read |
| POST | `/notifications/test` | **admin, owner** — test send (202) |
| POST/DELETE | `/notifications/fcm-token` | device token register/unregister |

### 6.18 Growth & misc (dashboard-adjacent)

| Method | Path | Roles |
|---|---|---|
| GET | `/feature-flags/me` | (auth) — flag variants for current user |
| GET | `/recall/alerts`, POST `/recall/alerts/:id/acknowledge` | recall mgmt |
| GET | `/referrals/me`, POST `/referrals/apply` | referrals |
| POST/GET | `/webhooks/endpoints`, GET `/webhooks/deliveries`, POST `/webhooks/deliveries/:id/replay` | owner, manager, admin — outbound webhooks |
| GET | `/verify/:tenantSlug` (Public), `/badges/me` | verified badge |
| POST/GET/DELETE | `/family/*`, `/subscriptions/premium-consumer` | consumer growth |

---

## 7. End-to-end dashboard workflows

### 7.1 Owner daily command-centre load
1. `POST /auth/admin/login` → tokens → `GET /auth/me` (role, storeIds).
2. `GET /stores` to populate the store switcher.
3. For selected store: `GET /dashboard?storeId=…` (one call returns KPIs, alerts,
   quick-actions, trends, team, activity, subscription, health-score) **or** call
   the granular endpoints for lazy/independent widgets.
4. Owners also call `GET /dashboard/multi-store` for the all-stores rollup.

### 7.2 Expiry triage → task
1. `GET /dashboard/alerts` surfaces `expiry_red`/`expiry_yellow`.
2. Drill: `GET /expiry-records/near-expiry?storeId=…`.
3. `POST /tasks/auto-from-alert` (or `POST /tasks`) to assign clearance work.
4. Staff completes on mobile → `POST /tasks/:id/complete`; dashboard activity feed
   reflects it; OHS `expiryManagement` component improves on next rollup.

### 7.3 Approved-list (EAN) audit
1. `POST /ean-lists` then `POST /ean-lists/:id/import` (Excel/CSV).
2. Monitor `GET /ean-lists/imports/:batchId` + `/errors/csv`.
3. `POST /ean-lists/:id/activate`.
4. Floor scans validate against it; `eanMatchRate` KPI + `ean_mismatch_spike`
   alert show audit health.

### 7.4 Inventory + GRN inward
1. `POST /grn` → add items (`POST /grn/:id/items`) → `POST /grn/:id/validate` →
   `POST /grn/:id/post` (posts stock).
2. `GET /inventory/summary` / `/low-stock` reflect new stock.
3. `POST /inventory/adjust` for counts/corrections (audited).

### 7.5 Billing lifecycle
1. `GET /subscriptions/status` + `/usage` on the billing page.
2. `POST /subscriptions/upgrade` → `POST /payments/checkout` → Razorpay → `POST
   /payments/verify`.
3. Razorpay calls `POST /payments/webhooks/razorpay` (source of truth).
4. Disputes: `POST /payments/refund` (admin/owner).

### 7.6 Platform admin / support
1. Admin reviews `GET /marketing/leads`, converts via `/leads/:id/convert`.
2. Support reproduces a tenant issue with `POST /admin/impersonate`
   (time-boxed, fully audited), ends with `DELETE /admin/impersonate`.
3. All sessions reviewable via `GET /admin/impersonations/audit`.

---

## 8. 🆕 PROPOSED enterprise endpoints (NOT yet implemented)

These are recommendations that fit RADHA's domain and an enterprise back-office.
**They do not exist in the backend today** — implement backend-first, then wire
the dashboard. Suggested ownership module noted in brackets.

### 8.1 User & access management `[auth/users]`
- `GET /api/v1/users` — paginated tenant users (filter by role/store/status).
- `POST /api/v1/users/invite` — invite teammate (`users:invite`).
- `PATCH /api/v1/users/:id` — change role/status; `DELETE /api/v1/users/:id`.
- `GET /api/v1/users/:id/activity` — per-user audit/activity timeline.
- `GET /api/v1/audit-logs` — unified, filterable audit trail (the data is already
  written per the "every write is audited" rule; expose a read API).

### 8.2 Saved views, alerts & exports `[client-dashboard]`
- `POST /api/v1/dashboard/saved-views` — persist filter/date/store presets.
- `POST /api/v1/dashboard/export` — schedule/stream a dashboard snapshot (PDF/XLSX).
- `POST /api/v1/alert-rules` — owner-defined thresholds (e.g. low-stock %, expiry
  window) that drive `alerts` + notifications.

### 8.3 Cross-store & cohort analytics `[analytics]`
- `GET /api/v1/analytics/stores/compare?storeIds=` — side-by-side store KPIs.
- `GET /api/v1/analytics/cohorts` — retention/usage cohorts for owner growth.
- `GET /api/v1/analytics/export` — analytics data export.

### 8.4 Platform-admin console `[admin]`
- `GET /api/v1/admin/tenants` + `/:id` — list/inspect tenants (`admin:tenants:read`).
- `PATCH /api/v1/admin/tenants/:id` — suspend/activate/limits (`admin:tenants:write`).
- `GET /api/v1/admin/metrics` — platform KPIs (MRR, active tenants, churn).
- `GET/PUT /api/v1/admin/feature-flags` — manage flags (today only `/feature-flags/me` read).
- `GET/PUT /api/v1/admin/platform-settings` — global settings (`admin:platform:settings`).

### 8.5 Notifications & comms `[notifications]`
- `POST /api/v1/notifications/broadcast` — targeted in-app/push broadcast to a
  tenant/store/role segment (audited, rate-limited).

### 8.6 Billing back-office `[subscriptions/payments]`
- `GET /api/v1/billing/invoices` + `/:id/pdf` — invoice history & download.
- `GET /api/v1/billing/transactions` — payment ledger with filters.

> For each proposed endpoint, follow the layering rules (§2.2), add the matching
> permission to the catalog (§5.2), enforce tenant/store scope, and write an audit
> log on every mutation. See Doc 3 for the function + security designs.

---

## 9. Quick reference — endpoint count by domain

Auth (11) · Dashboard (9) · Health-scoring (6) · Stores (5) · Tenants (2) ·
Products/Catalog (12) · EAN lists (14) · Scans (7+) · Expiry (15) · Tasks (18) ·
Inventory (9) · GRN (12) · Suppliers (13) · Reports (5) · Subscriptions/Payments
(10) · Analytics/Leads (11) · Admin/Impersonation (3) · Notifications (8) · Growth
(misc). **Base path for all: `/api/v1`.**

*End of Doc 1. See `02_DASHBOARD_UI_DESIGN.md` and `03_FUNCTIONS_AND_SECURITY_DESIGN.md`.*
