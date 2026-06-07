# BE-25 Verification — Suppliers Module

This document is the local-verification playbook for the BE-25 phase. It is organised into five suites (A–E) matching the canonical RADHA verification rhythm (validation gate, schema, REST surface, business rules, integration). Each suite has a clear pass criterion. Run them top-to-bottom; the next suite assumes the previous suites passed.

> ⚠ **Pre-requisites**
> 1. The three single-line appends from `BE-25_HANDOFF.md → INTEGRATION CHECKLIST` must already be in place: `app.module.ts`, `db/schema/index.ts`, optionally `permission.types.ts`.
> 2. PostgreSQL is running and reachable per `.env.development`.
> 3. `pnpm install` has been run at the repo root.

---

## Suite A — Static Validation Gate

The "no-runtime" pass: typecheck, lint, schema-generation, unit tests, build. Must pass clean (`--max-warnings 0`) before any runtime check.

### A1. Type-check

```bash
cd server
pnpm exec tsc --noEmit -p tsconfig.json
```

**Pass**: zero diagnostics, exit 0.

### A2. Lint

```bash
pnpm lint
```

**Pass**: zero warnings, zero errors. ESLint runs with `--max-warnings 0`.

### A3. Generate Drizzle migrations diff (optional)

```bash
pnpm db:generate -- --name be25_suppliers_diff
```

**Pass**: drizzle-kit reports no schema drift between `0005_be25_suppliers.sql` and the live `db/schema/`. (Re-running `db:generate` after the manual SQL is a sanity check; if drizzle-kit emits a fresh file, diff it against `0005` and reconcile.)

### A4. Run migrations against an empty database

```bash
pnpm db:migrate
```

**Pass**: every migration up to and including `0005_be25_suppliers.sql` runs without errors. The migration is idempotent — re-running it on a fresh database after a successful first run is a no-op.

Verify in `psql`:

```sql
\dt suppliers
\dt supplier_contacts
\dt supplier_performance
\dT supplier_status
```

All four objects must exist.

### A5. Unit tests

```bash
pnpm test --testPathPattern suppliers
```

**Pass**:
- `suppliers.dto.spec.ts` — all DTO cases pass.
- `suppliers.service.spec.ts` — all service cases pass.
- `supplier-performance.service.spec.ts` — all performance cases pass.
- `supplier-import.service.spec.ts` — all import cases pass.

Total: ~40 cases passing, 0 failing.

### A6. Production build

```bash
pnpm build
```

**Pass**: nest builds the `dist/` output without errors. `dist/modules/suppliers/` exists.

---

## Suite B — Schema & Migration

DB-level checks that confirm the tables, indexes, and constraints behave as designed.

### B1. Tables exist with the expected columns

In `psql`:

```sql
\d suppliers
\d supplier_contacts
\d supplier_performance
```

**Pass criteria**:

- `suppliers` has all columns including `id`, `tenant_id`, `code`, `gst_number`, `pan_number`, `status`, `total_grns`, `total_amount_delivered`, `metadata`, audit + soft-delete columns.
- `supplier_contacts` has soft-delete + `is_primary` + cascade FK to `suppliers`.
- `supplier_performance` has `grn_id`, `delivery_days`, `expiry_remaining_days`, `short_shelf_life`, `amount`, `recorded_at`.

### B2. Tenant + status indexes

```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'suppliers';
```

**Pass**: at minimum the following indexes are present:

- `idx_suppliers_tenant`
- `idx_suppliers_tenant_status`
- `idx_suppliers_name`
- `idx_suppliers_city`
- `idx_suppliers_gst`
- `idx_suppliers_tenant_code_uniq` (partial, `WHERE deleted_at IS NULL`)
- `idx_suppliers_tenant_gst_uniq` (partial, `WHERE gst_number IS NOT NULL AND deleted_at IS NULL`)

### B3. Partial uniques behave as expected

```sql
-- 1. Insert two suppliers with the same code in different tenants → both succeed
INSERT INTO suppliers (tenant_id, name, code) VALUES ('00000000-0000-0000-0000-000000000001', 'A', 'SUP-X');
INSERT INTO suppliers (tenant_id, name, code) VALUES ('00000000-0000-0000-0000-000000000002', 'B', 'SUP-X');

-- 2. Insert a duplicate code in the same tenant → fails with a unique-violation
INSERT INTO suppliers (tenant_id, name, code) VALUES ('00000000-0000-0000-0000-000000000001', 'C', 'SUP-X');

-- 3. Soft-delete the first; re-inserting the same code in the same tenant → succeeds
UPDATE suppliers SET deleted_at = now() WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND code = 'SUP-X';
INSERT INTO suppliers (tenant_id, name, code) VALUES ('00000000-0000-0000-0000-000000000001', 'D', 'SUP-X');
```

**Pass**: steps 1 and 3 succeed; step 2 fails with `unique_violation` on `idx_suppliers_tenant_code_uniq`.

### B4. Primary-contact uniqueness

```sql
-- One supplier
INSERT INTO suppliers (id, tenant_id, name, code)
  VALUES ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000001', 'A', 'SUP-A');

-- First primary contact: succeeds
INSERT INTO supplier_contacts (supplier_id, tenant_id, name, is_primary)
  VALUES ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000001', 'Boss', true);

-- Second primary contact: fails with unique-violation
INSERT INTO supplier_contacts (supplier_id, tenant_id, name, is_primary)
  VALUES ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000001', 'Boss2', true);
```

**Pass**: second insert fails on `idx_supplier_contacts_primary_uniq`.

### B5. Cascade-delete

```sql
-- Add a contact + a performance row, then hard-delete the supplier
INSERT INTO supplier_contacts (supplier_id, tenant_id, name)
  VALUES ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000001', 'Random');
INSERT INTO supplier_performance (supplier_id, tenant_id, delivery_days)
  VALUES ('00000000-0000-0000-0000-00000000a001', '00000000-0000-0000-0000-000000000001', 4);
DELETE FROM suppliers WHERE id = '00000000-0000-0000-0000-00000000a001';

SELECT count(*) FROM supplier_contacts WHERE supplier_id = '00000000-0000-0000-0000-00000000a001';
SELECT count(*) FROM supplier_performance WHERE supplier_id = '00000000-0000-0000-0000-00000000a001';
```

**Pass**: both counts are `0` (cascade worked).

---

## Suite C — REST Surface

End-to-end smoke against a running API. Assumes a tenant + an `owner` user have been onboarded (BE-09 onboarding flow). Replace `$TOKEN` with a valid bearer token issued via the BE-06 OTP flow.

```bash
pnpm start:dev
```

### C1. Create supplier (happy path)

```bash
curl -s -X POST http://localhost:3000/api/v1/suppliers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Acme Distributors",
    "category": "dairy",
    "gstNumber": "27AAPFU0939F1ZV",
    "panNumber": "AAPFU0939F",
    "phone": "9876543210",
    "city": "Mumbai",
    "state": "Maharashtra",
    "pincode": "400001"
  }'
```

**Pass**: returns 201 with a JSON body containing an auto-generated `code` matching `^SUP-`, `status: "active"`, all submitted fields stored.

### C2. GST/PAN validation (negative)

```bash
curl -s -i -X POST http://localhost:3000/api/v1/suppliers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Bad GST", "gstNumber": "NOT-VALID" }'
```

**Pass**: returns 400 with `code: "VALIDATION_ERROR"` and a `details` entry pointing at `gstNumber`.

### C3. Code uniqueness within tenant

Repeat C1 with the same explicit `"code": "SUP-ACME-001"` twice:

**Pass**: second call returns 409 `DUPLICATE_RESOURCE` with `field: "code"`.

### C4. Cross-tenant isolation

Issue a token for tenant B, attempt `GET /api/v1/suppliers/<tenant-A-supplier-id>`:

**Pass**: returns 404 `NOT_FOUND` (supplier not visible).

### C5. List with cursor pagination

```bash
curl -s "http://localhost:3000/api/v1/suppliers?limit=2" -H "Authorization: Bearer $TOKEN"
```

**Pass**: response shape `{ data: [...], nextCursor: "<base64>", hasMore: true|false }`. Following the cursor returns the next page; the union of pages contains every supplier exactly once.

### C6. Search

```bash
curl -s "http://localhost:3000/api/v1/suppliers/search?q=Acme&limit=10" -H "Authorization: Bearer $TOKEN"
```

**Pass**: returns suppliers whose name / code / legal name / GST contains "Acme" (case-insensitive).

### C7. Status transitions

```bash
# active → inactive
curl -s -X POST .../suppliers/<id>/deactivate -H "Authorization: Bearer $TOKEN"
# inactive → active
curl -s -X POST .../suppliers/<id>/activate -H "Authorization: Bearer $TOKEN"
# active → blacklisted with reason
curl -s -X POST .../suppliers/<id>/blacklist \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "reason": "fraud" }'
```

**Pass**: each call returns 200 with the updated supplier; `blacklistReason` and `blacklistedAt` set on the third call. Attempting `POST /:id/deactivate` while `status='blacklisted'` returns 422 `BUSINESS_RULE_VIOLATION`.

### C8. Multi-contact

```bash
curl -s -X POST .../suppliers/<id>/contacts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Sales Lead", "isPrimary": true, "phone": "9876543210" }'

# Add a second primary; the first should be demoted server-side
curl -s -X POST .../suppliers/<id>/contacts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Accounts", "isPrimary": true }'
```

**Pass**: both succeed. `GET /:id` shows `contacts` array of length 2, exactly one with `isPrimary: true` (the second contact).

### C9. Soft delete + list invisibility

```bash
curl -s -X DELETE .../suppliers/<id> -H "Authorization: Bearer $TOKEN" -i
curl -s ".../suppliers" -H "Authorization: Bearer $TOKEN"
```

**Pass**: DELETE returns 204; the deleted supplier is absent from the list; the audit log carries a `DELETE` event. In `psql`, `SELECT deleted_at FROM suppliers WHERE id = '...'` returns a non-null timestamp.

### C10. Performance endpoint

```bash
curl -s .../suppliers/<id>/performance -H "Authorization: Bearer $TOKEN"
```

**Pass**: returns the SupplierPerformance shape; `qualityScore = 75`, `reliabilityScore = 50` for a brand-new supplier (no GRNs yet).

---

## Suite D — Business Rules

Edge-case checks driven by Jest specs and reproducible via the API.

### D1. Status transition matrix

Run the `suppliers.service.spec.ts > status transitions` block:

```bash
pnpm test --testPathPattern suppliers.service.spec
```

**Pass**: 6+ cases green covering blacklist with reason, pending → inactive (allowed), blacklisted → inactive (rejected), blacklisted → active clears blacklist fields, idempotent activate, illegal-transition error.

### D2. Bulk import — happy path

Generate a small XLSX in Node REPL or any spreadsheet tool with header row `name,code,gst,phone` and 10 rows. Base64-encode it and POST:

```bash
curl -s -X POST .../suppliers/import \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"fileType\": \"xlsx\",
    \"fileName\": \"suppliers.xlsx\",
    \"fileBase64\": \"$(base64 -w 0 suppliers.xlsx)\"
  }"
```

**Pass**: returns `{ totalRows: 10, imported: 10, skipped: 0, failed: 0, errors: [] }`. `GET /api/v1/suppliers` lists the 10 new rows.

### D3. Bulk import — error reporting

Edit the same sheet to introduce a row with no name, a row with invalid GST, and a duplicate code. Re-import.

**Pass**:
- `failed >= 2` (empty name + invalid GST).
- `errors[]` contains row numbers (`row: 4`, `row: 5`, …) and the offending field names (`field: "name"`, `field: "gstNumber"`, `field: "code"`).
- Valid rows still imported (`imported >= the valid count`).
- The audit log carries an `IMPORT` event with the totals.

### D4. Bulk import — duplicate code in same tenant is skipped

Re-run the same import file twice. The second run should `skip` every row that's already present (all of them) and produce zero failures and zero new rows.

### D5. Export

```bash
curl -s ".../suppliers/export?format=xlsx" -H "Authorization: Bearer $TOKEN" -o suppliers.xlsx
file suppliers.xlsx
```

**Pass**: file is a valid xlsx (`Microsoft Excel 2007+` per `file`); opening it in Excel/LibreOffice shows the same headers as `listAllForExport` and one row per supplier in the tenant.

### D6. Audit log coverage

After running C1–C9 + D2–D5, query `audit_logs`:

```sql
SELECT action, resource_type, count(*)
FROM audit_logs
WHERE tenant_id = '<your tenant>' AND resource_type LIKE 'Supplier%'
GROUP BY action, resource_type;
```

**Pass**: at minimum CREATE, UPDATE, DELETE, IMPORT, EXPORT events present for resource type `Supplier`; CREATE + DELETE for `SupplierContact`.

---

## Suite E — Integration

Confirms the module wires correctly into the rest of the system after the INTEGRATION CHECKLIST has been applied.

### E1. App boots with SuppliersModule registered

`pnpm start:dev` produces a clean Nest log including:

```
[InstanceLoader] SuppliersModule dependencies initialized
[RoutesResolver] SuppliersController { /suppliers }: …
```

If you see `Nest cannot resolve dependencies of the SuppliersController`, an INTEGRATION CHECKLIST step is missing.

### E2. Drizzle schema barrel includes suppliers

```bash
node -e "console.log(Object.keys(require('./server/dist/db/schema')).filter(k => k.startsWith('supplier')))"
```

**Pass**: prints `[ 'suppliers', 'supplierContacts', 'supplierPerformance', 'supplierStatusEnum', ... ]` (TypeScript types + runtime objects).

### E3. RBAC permission roundtrip (only after step 3 of INTEGRATION CHECKLIST is applied)

```bash
# Owner token: succeeds
curl -i .../suppliers -H "Authorization: Bearer $OWNER_TOKEN"   # 200

# Staff token (read only): list works, create fails
curl -i .../suppliers -H "Authorization: Bearer $STAFF_TOKEN"   # 200
curl -i -X POST .../suppliers ...                                # 403 INSUFFICIENT_PERMISSIONS
```

If the INTEGRATION CHECKLIST step 3 has NOT yet been applied, the controller falls back to role-only enforcement; the same probe still confirms staff read works and staff create returns 403 `ROLE_REQUIRED`.

### E4. Performance hook is callable from a sibling module

Sanity-check that BE-26 will be able to import the service:

```ts
// pseudo-test inside server/test/be25-integration.spec.ts (optional)
import { SuppliersModule } from '@/modules/suppliers/suppliers.module';
import { SupplierPerformanceService } from '@/modules/suppliers/services/supplier-performance.service';

await Test.createTestingModule({ imports: [SuppliersModule] }).compile();
// resolution succeeds → service is exported correctly
```

**Pass**: the test module compiles and `module.get(SupplierPerformanceService)` returns a non-null instance.

### E5. Sentry-grade tags

Trigger any non-2xx response (e.g. `POST /suppliers` with `gstNumber: "BAD"`). In Sentry / log output, confirm the breadcrumb carries:

- `code: "VALIDATION_ERROR"`
- `tenantId: <uuid>`
- `userId: <uuid>`
- `route: "POST /api/v1/suppliers"`

**Pass**: every error envelope is tagged with the BE-04 catalog code and BE-08 context. No raw 500 leaks past the global filter.

---

## Sign-off

- [ ] Suite A — static validation gate green
- [ ] Suite B — schema + partial uniques + cascade verified
- [ ] Suite C — every REST endpoint hit with positive + negative cases
- [ ] Suite D — status transitions, bulk import error reporting, export, audit log coverage verified
- [ ] Suite E — module wired in (after INTEGRATION CHECKLIST), permission round-trip OK, sibling-module import resolves
- [ ] Coverage > 85% on `src/modules/suppliers/**`

**Verifier**: ___________________________  **Date**: ___________

**☐ APPROVED — Proceed to BE-26**
**☐ CHANGES REQUESTED**

---

**End of BE-25 Verification.**
