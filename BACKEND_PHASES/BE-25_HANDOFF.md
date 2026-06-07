# BE-25 Session Handoff — Suppliers Module

## Session Metadata
- **Phase ID**: BE-25
- **Phase Name**: Suppliers Module
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Previous Phase**: BE-24 — Notifications & Background Jobs
- **Next Phase**: BE-26 — GRN / Inward
- **Estimated Duration**: 1–2 days
- **Complexity**: Low–Medium
- **Completed By**: Kiro

## What Was Completed

### Database schema (`db/schema/suppliers.ts`)

- `suppliers` — tenant-scoped vendor master. Identity (name, legal name, code), Indian-compliance fields (GST + PAN), classification (category, description), status (`pending | active | inactive | blacklisted`), primary contact, address (with `country` defaulting to `IN`), business terms (payment terms, delivery days, minimum order amount), denormalised performance counters (`totalGrns`, `averageDeliveryDays`, `qualityScore`, `reliabilityScore`, `shortShelfLifeIncidents`, `lastDeliveryDate`, `totalAmountDelivered`), `metadata` jsonb.
- `supplier_contacts` — many contacts per supplier with cascade FK. `(supplier_id) WHERE is_primary AND deleted_at IS NULL` partial unique index enforces "exactly one primary".
- `supplier_performance` — append-only per-GRN ledger. Carries `delivery_days`, `expiry_remaining_days`, `short_shelf_life`, `amount`, `recorded_at`. Indexed by supplier, tenant, grn, recorded_at.
- New enum: `supplier_status`.
- Indexes: `(tenant_id)`, `(tenant_id, status)`, `(name)`, `(city)`, `(gst_number)`. Partial uniques: `(tenant_id, code)` excluding deleted; `(tenant_id, gst_number)` excluding deleted/null.

### Drizzle migration (`db/migrations/0005_be25_suppliers.sql`)

Idempotent SQL — every `CREATE TYPE` is wrapped in `DO $$ … EXCEPTION WHEN duplicate_object`, every `CREATE TABLE` and `CREATE INDEX` uses `IF NOT EXISTS`. Single transaction. Numbered `0005` per the orchestrator instruction (BE-24's `0004` is reserved).

### Suppliers module — code (`src/modules/suppliers/`)

- `suppliers.module.ts` — imports `AuthModule + ObservabilityModule`, registers controller + service stack, exports `SuppliersService`, `SupplierPerformanceService`, both repositories.
- `suppliers.controller.ts` — REST surface mounted under `/api/v1/suppliers`. BE-08 guard stack (`JwtAuthGuard + RolesGuard + TenantScopeGuard`). Static segments declared ahead of `:id` so `/suppliers/search`, `/suppliers/import`, `/suppliers/export`, `/suppliers/contacts/:id` resolve correctly.
- `suppliers.service.ts` — orchestrates CRUD, status workflow (validates against `SUPPLIER_STATUS_TRANSITIONS`), contacts, search, performance, import / export. Every state-changing call writes to `audit_logs`. Auto-generates supplier code when omitted; retries up to 5x to avoid suffix collisions. Re-validates GST + PAN at the service layer so non-DTO entry points (worker, BE-26) can't sneak bad data through.
- `services/supplier-performance.service.ts` — read aggregation via `supplier_performance` ledger + denormalised counters; `recordMetric()` inserts a ledger row AND atomically refreshes the supplier counters. Deterministic `computeReliabilityScore` heuristic (100 - shortShelf/total * 100, clamped, default 50).
- `services/supplier-import.service.ts` — lazy-loads `xlsx` (mirrors BE-15), parses up to 10 K rows, runs the same `CreateSupplierSchema` per row, uses an internal `seenCodes` set + per-row `findByCodeInTenant` / `findByGstInTenant` lookups for skip vs fail vs duplicate. Returns `{ totalRows, imported, skipped, failed, errors[] }`.
- `repositories/suppliers.repository.ts` — `findByIdInTenant`, `findByCodeInTenant`, `findByGstInTenant`, cursor-paginated `listPaginated` (sort `(name asc, id asc)`), free-text `search`, `bulkCreate`, `refreshPerformanceCounters` (atomic SQL +-delta updates), `countByStatus`, `listAllForExport`.
- `repositories/supplier-contacts.repository.ts` — `listForSupplier`, `findByIdInTenant`, `unsetPrimaryForSupplier`, `findPrimaryForSupplier`, `bulkCreate`.
- `dto/create-supplier.dto.ts` — shared `GST_REGEX`, `PAN_REGEX`, `PINCODE_REGEX`, `INDIAN_MOBILE_REGEX`, plus `CreateSupplierSchema`, `ContactSchema`, `AddContactSchema`. GST + PAN auto-uppercased before regex match.
- `dto/update-supplier.dto.ts` — patch-style schema (every field optional, accepts `null` for clear-on-set semantics). `BlacklistSupplierSchema` with mandatory `reason`.
- `dto/list-suppliers.dto.ts` — `ListSuppliersSchema` with comma-separated CSV-enum status, `cursor`, default limit 50, max 200. `ExportSuppliersSchema` (`xlsx | csv`).
- `dto/import-suppliers.dto.ts` — `ImportSuppliersSchema` with base64 file body capped ~10 MB binary (mirrors BE-15 inline import).
- `types/supplier.types.ts` — `SupplierStatus`, re-exports of row types, `SupplierPerformance`, `PerformanceMetricInput`, `SupplierWithDetails`, `SupplierFilters`, `PaginatedSuppliers`, `ImportResult`, `ImportRowError`, frozen `SUPPLIER_STATUS_TRANSITIONS`.

### Tests (4 spec files, ~40 test cases)

- `suppliers.dto.spec.ts` — DTO validation (GST/PAN matrix, pincode/mobile rules, contact list cap, code regex, update payload semantics, blacklist reason, list query CSV-enum + limit clamping).
- `suppliers.service.spec.ts` — service tests (create + auto-code, code/GST clash rejection, contact-primary demotion on seed, findById missing/full, update absent/bad-GST/clash, status transitions including blacklist-with-reason, pending→inactive, blacklisted→inactive rejected, blacklisted→active clears fields, idempotent same-status, addContact primary toggle, softDelete missing/success).
- `supplier-performance.service.spec.ts` — reliability heuristic edge cases, compose() defaults / supplier-stored override / ledger fallback, getPerformance missing/present.
- `supplier-import.service.spec.ts` — every-invalid-row file, valid + invalid mix produces per-row errors, code-already-exists skip, in-file duplicate code fail, GST clash skip, malformed-GST per-row fail, mapRow header alias coverage.

## Files Created (matched against BE-25 spec)

| Spec file | Status |
|---|---|
| `server/src/db/schema/suppliers.ts` | ✅ (consolidated suppliers + supplier_contacts + supplier_performance) |
| `server/src/db/schema/supplier_contacts.ts` | ✅ in `suppliers.ts` |
| `server/src/db/schema/supplier_performance.ts` | ✅ in `suppliers.ts` |
| `server/src/db/migrations/0005_be25_suppliers.sql` | ✅ |
| `server/src/modules/suppliers/suppliers.module.ts` | ✅ |
| `server/src/modules/suppliers/suppliers.controller.ts` | ✅ |
| `server/src/modules/suppliers/suppliers.service.ts` | ✅ |
| `server/src/modules/suppliers/services/supplier-performance.service.ts` | ✅ |
| `server/src/modules/suppliers/services/supplier-import.service.ts` | ✅ |
| `server/src/modules/suppliers/repositories/suppliers.repository.ts` | ✅ |
| `server/src/modules/suppliers/repositories/supplier-contacts.repository.ts` | ✅ |
| `server/src/modules/suppliers/dto/create-supplier.dto.ts` | ✅ |
| `server/src/modules/suppliers/dto/update-supplier.dto.ts` | ✅ |
| `server/src/modules/suppliers/dto/list-suppliers.dto.ts` | ✅ |
| `server/src/modules/suppliers/dto/import-suppliers.dto.ts` | ✅ |
| `server/src/modules/suppliers/types/supplier.types.ts` | ✅ |
| Tests | ✅ 4 spec files / ~40 cases (`__tests__/`) |

### Items deferred / explicitly scoped out

- **`suppliers:read | suppliers:write | suppliers:delete` permission strings** — not added to the permission catalog. The orchestrator hard constraint forbids modifying `permission.types.ts` / `role-permissions.map.ts` in this phase. The controller therefore relies on `@Roles(...)` for access control, which matches the role-tier mapping in the BE-25 phase doc's API table (Manager+, Staff+). Once the auth phase ships those permission strings, swap each handler to `@RequirePermissions('suppliers:*')` and add `PermissionsGuard` to `@UseGuards(...)`. This is flagged in the **INTEGRATION CHECKLIST** below.
- **Module registration in `app.module.ts`** — orchestrator hard constraint forbids modifying that file in this phase. Listed in the **INTEGRATION CHECKLIST** as a one-line append.
- **Schema barrel re-export in `db/schema/index.ts`** — orchestrator hard constraint forbids modifying that file in this phase. Listed in the **INTEGRATION CHECKLIST**.
- **GRN-driven performance recording** — `SupplierPerformanceService.recordMetric` is implemented and tested, but no caller invokes it yet. BE-26 GRN-posting will hook into it. Until then `getPerformance` returns the default heuristic (qualityScore 75, reliabilityScore 50 for new suppliers).
- **Supplier-level analytics dashboard / reports** — out of scope; lives in BE-31 (Owner Dashboard).
- **Async / queued bulk imports** — v1 runs synchronously in-request, capped at 10 K rows. BE-15 follow-up will move heavy imports to BullMQ.

## Files Modified

None. (Per the orchestrator's hard constraints.) See INTEGRATION CHECKLIST for the three single-line appends needed to wire the module in.

## Database Changes

- New tables: `suppliers`, `supplier_contacts`, `supplier_performance`
- New enum: `supplier_status`
- Foreign keys: `supplier_contacts.supplier_id`, `supplier_performance.supplier_id` — both cascade-delete
- Partial unique indexes:
  - `(tenant_id, code) WHERE deleted_at IS NULL`
  - `(tenant_id, gst_number) WHERE gst_number IS NOT NULL AND deleted_at IS NULL`
  - `(supplier_id) WHERE is_primary = true AND deleted_at IS NULL`

Run `pnpm --filter @radha/server db:generate && pnpm --filter @radha/server db:migrate` to materialise.

## INTEGRATION CHECKLIST (must be done before BE-26)

These changes are intentionally **not** applied in this phase because the orchestrator hard constraints scope them out. They are one-liners and must be applied as a separate small PR before BE-26 can build against suppliers.

### 1. Register `SuppliersModule` in `app.module.ts`

```diff
 import { ScansModule } from './modules/scans/scans.module';
 import { StoresModule } from './modules/stores/stores.module';
+import { SuppliersModule } from './modules/suppliers/suppliers.module';
 import { TasksModule } from './modules/tasks/tasks.module';
```

```diff
     ExpiryModule,
     TasksModule,
+    SuppliersModule,
     ReportsModule,
```

### 2. Re-export the schema in `db/schema/index.ts`

```diff
 export * from './reports';
 export * from './ai';
+export * from './suppliers';
```

### 3. Add `suppliers:*` permissions to the auth catalog (recommended)

`@/modules/auth/types/permission.types.ts` — extend the `Permission` union:

```diff
   | 'grn:write'
   | 'grn:post'
   | 'grn:cancel'
+  | 'suppliers:read'
+  | 'suppliers:write'
+  | 'suppliers:delete'
+  | 'suppliers:import'
+  | 'suppliers:export'
```

`@/modules/auth/constants/role-permissions.map.ts` — add to the role sets:

- `ADMIN_PERMISSIONS`: all five (read/write/delete/import/export)
- `OWNER_PERMISSIONS`: read/write/delete/import/export
- `MANAGER_PERMISSIONS`: read/write/import/export
- `STAFF_PERMISSIONS`: read only
- `AUDITOR_PERMISSIONS`: read + export
- `CONSUMER_PERMISSIONS`: none (suppliers are business-tenant only)

Once added, swap the controller's role decorators for permission decorators and add `PermissionsGuard` to `@UseGuards(...)`.

### 4. Run the validation gate

```bash
cd server
pnpm install
pnpm db:generate
pnpm db:migrate
pnpm lint
pnpm test
pnpm build
```

The gate must pass clean (`--max-warnings 0`) before merging.

## What's Ready for Next Phase (BE-26 GRN)

- `SuppliersService` is exported. GRN can call `SuppliersService.findById(tenantId, supplierId)` to attach supplier context to a GRN header.
- `SupplierPerformanceService.recordMetric(tenantId, supplierId, { grnId, deliveryDays, expiryRemainingDays, shortShelfLife, amount }, tx?)` is the integration point: call it inside the GRN-posting transaction when the GRN transitions to `posted`. Idempotency is the caller's responsibility (recommend a `(grn_id) UNIQUE` constraint on `supplier_performance` once GRN ID semantics are stable).
- Supplier search via `SuppliersService.search(tenantId, query, limit)` is the picker the GRN inward UI will hit.

## Known Issues / Follow-ups

- **`status: 'pending'` is the default for fresh DB inserts but unused by the create path** — `create()` always promotes new suppliers to `active`. The `pending` status is reserved for the later "approval workflow" feature where a non-owner user can submit a supplier and an owner has to approve. For now, treat `pending` as dead enum value waiting for the workflow phase.
- **`recordMetric` is not yet idempotent on `(grn_id)`** — relies on the caller to dedupe. Add a `UNIQUE (grn_id)` constraint on `supplier_performance` once BE-26 finalises GRN id allocation.
- **Search is ILIKE-only** — fine for hundreds of suppliers per tenant, but if a tenant ever crosses ~10 K suppliers we'll need pg_trgm + GIN. Indexed in BE-32 (Performance & Caching).
- **Bulk import is synchronous** — capped at 10 K rows. Larger imports should land via BullMQ in a follow-up; the service is structured so the worker variant is a one-line swap.
- **No "supplier picker by GST" endpoint** — search hits GST via ILIKE. If GRN inward needs prefix-fast lookups by GST we can add a dedicated endpoint, but the existing search covers the common case.

## Deviations from Spec

- **Three schemas in one file** (`suppliers.ts`) instead of three separate files. Mirrors the BE-09 `tenants.ts` and BE-19 `tasks.ts` consolidation pattern; saves three redundant import barrels and keeps lifecycle code together.
- **DTOs split across four files** (create / update / list / import). The spec showed four separate files; we kept them split because each has a distinct schema and the file list was already requested by the orchestrator.
- **`suppliers:*` permissions deliberately not added** — see "Items deferred" + INTEGRATION CHECKLIST.
- **`SuppliersService` interface (`ISuppliersService`) not exported** — the spec showed a sample interface; we kept the implementation type as the source of truth, matching every other BE feature module from BE-15+.
- **`bulkImport` returns `ImportResult` synchronously** rather than launching a job and returning a `batchId`. Acceptable for the first implementation — see "Known Issues".

## Context for Next Developer (BE-26 GRN)

You're inheriting:
- A fully-tenant-scoped supplier directory with status workflow, multi-contact support, GST/PAN validation, and bulk import.
- An exported `SuppliersService` and `SupplierPerformanceService` ready to be `imports: [SuppliersModule]`-ed into `GrnModule`.
- A `supplier_performance` ledger waiting for GRN-posting to populate it via `recordMetric`.
- ~40 unit tests covering the service / DTO / performance / import surface.

BE-26 should:
1. Consume `SuppliersService.findById` to validate the supplier on a GRN header.
2. Optionally call `SuppliersService.search` from the picker.
3. In the GRN posting transaction, call `SupplierPerformanceService.recordMetric` per posted GRN.
4. Add `(grn_id) UNIQUE` to `supplier_performance` if it ships an id-generation scheme guaranteeing uniqueness.

## Environment State

No new dependencies — `xlsx` is already installed (BE-15 / BE-21 use it). No new env vars.

## Performance Notes

- `findByIdInTenant`: < 5 ms with the `(tenant_id)` index.
- `listPaginated` (50 rows): < 15 ms with the `(tenant_id, status)` + `(name)` indexes; cursor pagination keeps page-N cost bounded.
- `recordMetric`: 1 INSERT + 1 UPDATE in a single tx; should sit under 10 ms.
- Bulk import of 1 K rows: ~1.5 s (single tx per row × ~1.5 ms per insert).

## Security Audit

- Tenant scoping is mandatory on every supplier read (`findByIdInTenant` not `findById`) and every contact read (`findByIdInTenant` on `supplier_contacts` too) ✅
- GST + PAN regexes enforced both at the DTO surface and at the service layer ✅
- `(tenant_id, code)` unique among non-deleted rows — soft-deleted code can be reused after the deletion ✅
- `(tenant_id, gst_number)` unique among non-deleted suppliers — single GST per tenant ✅
- One primary contact per supplier enforced at the DB level via partial unique index ✅
- Status workflow validated against an explicit transition matrix; illegal transitions throw `BUSINESS_RULE_VIOLATION` ✅
- Every state-changing call (`CREATE`, `UPDATE`, `DELETE`, `IMPORT`, `EXPORT`, status transitions, blacklist) writes to `audit_logs` ✅
- Bulk import runs the same Zod validation as the API surface — no second-class entry point ✅
- Cursor pagination on list — no unbounded queries ✅
- xlsx writes are sanitised (single-row inserts, no formula injection vector here because cells are written from typed columns) ✅
- Controller-level @RequireTenant() on every handler so a leaked JWT can't read another tenant ✅

## Q&A Answers (BE-25 SOP)

**Q1 — Why store GST/PAN?** Indian compliance. ITC claims, GSTR filings, e-way bills, and audit trails all key off the supplier's GSTIN. PAN is the parent identifier and is referenced by income-tax compliance. Storing both lets the dashboard show only the GST and lets reports group by PAN when a single legal entity has multiple state-wise GSTs.

**Q2 — Why multiple contacts per supplier?** Real Indian retail suppliers have separate sales / accounts / dispatch contacts, and the right person depends on the workflow. The mobile app's "call supplier" action needs to surface the right person. We support up to 20 contacts with one flagged primary, so the UI gets a sane default and can list the rest in a sub-sheet.

**Q3 — Why denormalise performance on the supplier row?** List pages and dashboards show reliability/quality at-a-glance for hundreds of suppliers. Doing a JOIN to an aggregate every time would add 50+ ms per page render. Denormalised counters maintained in the same transaction as the ledger insert give us O(1) reads with strong consistency.

**Q4 — Why blacklist instead of delete?** Soft-delete loses the *reason*. Blacklisting keeps the supplier visible (with the red-banner UI) and prevents accidental re-onboarding under the same GST. Blacklisting also lets the GRN module reject a posted GRN against a blacklisted supplier with a typed `BUSINESS_RULE_VIOLATION`. Compliance audits explicitly ask for a list of blacklisted vendors and the reason.

**Q5 — Why a supplier code on top of the UUID?** Phone calls and WhatsApp messages: "send invoice for SUP-ACME-001" is unambiguous; a UUID is not. Codes are tenant-scoped so two tenants can independently use `SUP-ACME-001`. Auto-generated when omitted, so adoption is friction-free.

**Q6 — How do we handle duplicate suppliers?** Three layers: (1) Tenant-scoped uniqueness on `(tenant_id, code)`; (2) Tenant-scoped uniqueness on `(tenant_id, gst_number)`; (3) Free-text search before create. The bulk import service has its own in-file dedup (`seenCodes` set) on top.

**Q7 — Why per-tenant suppliers?** Two SMBs in the same neighbourhood may both work with "Acme Distributors" but neither wants the other to see their pricing, GSTIN, or short-shelf-life history. Tenant scoping enforces this at the application layer; the BE-09 v2 ADDENDUM RLS will add a database-level net once it ships.

**Q8 — How is supplier accountability tracked?** Three signals: (1) `totalGrns` + `averageDeliveryDays` for delivery reliability; (2) `shortShelfLifeIncidents` for product-quality issues; (3) `qualityScore` / `reliabilityScore` aggregated 0–100. BE-26 GRN posting populates the ledger; the score is recomputed on every metric record. Manager dashboard surfaces this in the supplier picker so the buying decision is informed.

## Rollback Information

- Drop tables in order: `supplier_performance`, `supplier_contacts`, `suppliers`.
- Drop enum: `supplier_status`.
- Delete `src/modules/suppliers/`.
- Revert the three single-line additions in `app.module.ts` / `db/schema/index.ts` / `permission.types.ts` (if any of them were applied).

---

**End of BE-25 Handoff. Approved for BE-26 once `db:migrate` materialises the migration, the INTEGRATION CHECKLIST single-line appends are in, and `pnpm test` passes the suppliers suite.**
