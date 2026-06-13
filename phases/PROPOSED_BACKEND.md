# RADHA — 🆕 Proposed Backend Endpoints

> **Source:** Doc 1 §8 / Doc 3 §A.4
> **Status:** Not yet implemented in `radha_backend/`. Build the respective NestJS modules
> before wiring these dashboard shells to real data.
>
> All gated shell pages in Phase 18 use `components/system/needs-backend.tsx` to display
> an info banner and blur the layout preview. Once a module is built and deployed, remove
> the `NeedsBackend` wrapper and wire the component to the real endpoint.

---

## Module: User & Team Management

These endpoints enable the Team Management UI (`/settings/team`).

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/v1/users/invite` | Invite a new user to the tenant by email. Sends invite email, creates pending user record. |
| `GET` | `/api/v1/users` | List all users for the tenant with role, store assignments, and status. Paginated, filterable. |
| `GET` | `/api/v1/users/:id` | Get a single user's details (role, stores, last active, permissions). |
| `PATCH` | `/api/v1/users/:id` | Update user role or store assignments. |
| `DELETE` | `/api/v1/users/:id` | Deactivate or remove a user from the tenant. Soft-delete. |
| `PATCH` | `/api/v1/users/me` | Update the current user's own profile (name). |
| `PUT` | `/api/v1/users/me/language` | Save the current user's UI language preference. |

**NestJS module to create:** `radha_backend/src/modules/users/`

---

## Module: Audit Logs

Enables the Audit Log Viewer (`/admin/audit-logs`).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/admin/audit-logs` | Platform-wide audit trail. Every state-changing action with actor, resource, severity, and timestamp. Filterable by actor, action, date range, severity. Paginated with cursor. |

**NestJS module to create:** `radha_backend/src/modules/audit-logs/`

**Notes:**
- Every state-changing write in all other modules should already write an audit log entry (per existing backend rules). This endpoint *reads* the audit_logs table.
- Admin/owner role required.
- Returns: `{ items: AuditLogEntry[], nextCursor: string | null }`

---

## Module: Platform Admin — Tenant List

Enables the Platform Tenants page (`/admin/tenants`).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/admin/tenants` | List all tenants for RADHA platform admin. Includes name, plan, store count, user count, status. Distinct from the existing `/tenants/:id` endpoint (which serves Tenant Admin role). |

**Notes:**
- Requires platform-admin role (a new role above `admin`), OR a separate RADHA internal auth token.
- Existing `/tenants/:id` serves per-tenant detail for Tenant Admin — this is a cross-tenant list, scoped only for the RADHA platform owner.
- Returns: `{ tenants: PlatformTenantSummary[], total: number, nextCursor: string | null }`

---

## Module: Analytics — Cross-Store Compare

Enables the Cross-Store Compare page (`/analytics/compare`).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/analytics/compare` | Aggregated metrics for multiple stores in a single query. Supports grouping by store for grouped bar chart visualisation. |

**Query params:** `storeIds[]`, `metric` (expiry | tasks | grn | health_score), `from`, `to`

**Returns:** `{ stores: { storeId, storeName, value }[], metric: string, period: { from, to } }`

**Notes:**
- The existing dashboard KPI endpoints are per-store. This endpoint accepts multiple storeIds and returns a grouped response.
- Owner/manager roles with multi-store access.

---

## Module: Reports — Scheduled Reports

Enables the Scheduled Reports page (`/reports/schedule`).

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/v1/reports/schedule` | Create a new scheduled report job with type, format, frequency, and recipient list. |
| `GET` | `/api/v1/reports/schedule` | List all scheduled reports for the tenant. |
| `PATCH` | `/api/v1/reports/schedule/:id` | Update a schedule (change frequency, recipients, pause/resume). |
| `DELETE` | `/api/v1/reports/schedule/:id` | Remove a scheduled report. |

**Body (POST/PATCH):**
```json
{
  "reportType": "expiry | inventory | tasks | grn",
  "format": "pdf | excel",
  "frequency": "daily | weekly | monthly",
  "cronExpression": "0 8 * * 1",
  "recipients": ["email1@example.com"],
  "storeId": "uuid",
  "filters": {}
}
```

**Notes:**
- Uses BullMQ repeatable jobs. The existing report generation code (Phase 12) can be reused.
- Cron jobs should be registered on `main.scheduler.ts`.

---

## Module: Notifications — Broadcast

Enables the Broadcast page (`/notifications/broadcast`).

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/v1/notifications/broadcast` | Send a notification to all tenants or a segment (trial, pro, past_due, inactive). |
| `GET` | `/api/v1/notifications/broadcast` | List past broadcasts with delivery stats. |

**Body:**
```json
{
  "segment": "all | trial | pro | past_due | inactive",
  "channels": ["in_app", "email", "push"],
  "title": "string",
  "body": "string",
  "metadata": {}
}
```

**Notes:**
- Admin/owner role only (platform-level).
- Uses existing `firebase-admin` push infrastructure and the notifications queue.

---

## Module: Billing — Invoices & Transactions

Enables the Invoice History page (`/billing/invoices`).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/billing/invoices` | Paginated invoice history for the tenant. Includes plan, amount, status, and presigned download URL for each PDF. |
| `GET` | `/api/v1/billing/invoices/:id` | Single invoice detail with line items. |
| `GET` | `/api/v1/billing/transactions` | Paginated transaction log (payments, refunds, adjustments). |

**Notes:**
- Razorpay generates the payment records; these endpoints read them from the local DB copy.
- PDF invoices: generated with `pdfkit`, stored in S3, returned as presigned URL.
- The existing `subscriptions` module handles plan state; this module handles invoice records.

---

## Other proposed endpoints (from Doc 1 §8)

| Method | Path | Purpose | Dashboard page |
|---|---|---|---|
| `GET` | `/api/v1/search/global` | Global search across products, tasks, expiry, GRN, suppliers by keyword. | Command palette (⌘K) |
| `POST` | `/api/v1/saved-views` | Save a filter/sort state for a list view (e.g. "Expiring this week, Store A"). | List pages |
| `GET` | `/api/v1/saved-views` | Retrieve saved views for the user. | List pages |
| `POST` | `/api/v1/alert-rules` | Create custom alert rules (e.g. "notify when health score < 70"). | Alerts / settings |
| `GET` | `/api/v1/alert-rules` | List the tenant's alert rules. | Alerts / settings |

---

## Build order recommendation

Build in this sequence to unlock the most user value per sprint:

1. **`/users/me` + `/users/me/language`** — unblocks profile editing and language preference (Phase 17 actions already proxy these)
2. **`/users/invite` + `/users` CRUD** — unblocks Team management tab
3. **`/billing/invoices` + `/billing/transactions`** — high visibility for billing admin
4. **`/admin/audit-logs`** — compliance and security visibility
5. **`/reports/schedule`** — high value for recurring ops teams
6. **`/analytics/compare`** — unlocks cross-store insight for multi-store owners
7. **`/notifications/broadcast`** — platform-admin communications
8. **`/admin/tenants`** — platform-level oversight (last, needs platform-admin role design)
9. **`/search/global`**, **`/saved-views`**, **`/alert-rules`** — progressive UX enhancements

---

*This document is maintained alongside `phases/PHASE_INDEX.md`. Mark each row as `[built]`
when the backend module ships and the dashboard shell is wired to the real endpoint.*
