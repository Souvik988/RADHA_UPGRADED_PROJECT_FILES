# BE-26 Verification Pack — GRN (Goods Receipt Note) Module

Five suites cover BE-26: A (unit tests), B (HTTP integration), C (DB invariants), D (security gates), E (atomic posting + reversal + concurrent post).

Run before declaring BE-26 complete. Suites A and B run during local dev; C–E require a fresh dev DB plus the orchestrator integration steps from `BE-26_HANDOFF.md` (schema barrel + AppModule).

## Prerequisites

```bash
cd server
pnpm install
# Apply BE-26_HANDOFF integration checklist first:
#   1. export * from './grn' added to db/schema/index.ts
#   2. GrnModule registered in app.module.ts
pnpm db:migrate         # applies 0006_be26_grn.sql
```

A test tenant + store + (active) supplier + a manager / owner JWT are assumed for HTTP suites. The handoff doc explains how the orchestrator overrides `INVENTORY_SERVICE_TOKEN`, `SUPPLIER_LOOKUP_TOKEN`, `SUPPLIER_PERFORMANCE_TOKEN` once BE-25 / BE-27 ship; until then the in-process stubs are sufficient for the verification suites.

---

## Suite A — Unit tests

Run the GRN-only test slice:

```bash
cd server
pnpm test --testPathPattern=grn
```

Expected: **6 spec files, 94 cases, all passing.**

| Spec file | Cases | What it locks down |
|---|---|---|
| `grn.dto.spec.ts` | 26 | Every Zod schema refine + cap. EAN format, positive-integer quantity, expiry > manufacture, AddItems max=200 cap, status CSV parser, list limit cap, reverse reason required + capped |
| `grn-number-generator.utils.spec.ts` | 7 | Pure helpers + peek-next-sequence under empty bucket / normal seq / 5-digit overflow / unparseable suffix |
| `grn-validation.service.spec.ts` | 11 | Errors block, warnings allow. Negative qty, expiry ≤ mfg, missing fields → invalid. Past-expiry, short-shelf-life, duplicate-batch, unknown-product → warnings only |
| `grn-posting.service.spec.ts` | 17 | Preflight reject paths + atomic transaction. **Inventory throw rolls everything back. Concurrent post returns GRN_ALREADY_POSTED via the optimistic state guard.** Short-shelf-life count, supplier metrics post-commit, audit log on success |
| `grn-reversal.service.spec.ts` | 10 | Already-reversed reject, non-posted reject, outbound per posted line, skip never-posted lines, **concurrent reverse rejection via guard-null**, reversed event with reason, audit log transition=reverse, supplier reversal post-commit |
| `grn.service.spec.ts` | 23 | Full orchestrator surface — supplier validation (missing / cross-tenant / blacklisted / inactive), duplicate invoice → 409, draft state machine (post / cancel / reverse rejections), counter refresh on add / remove items, delegation to posting / reversal services, findById 404 + happy paths |

**Pass criteria**: all 94 cases green, no failures, no skipped.

---

## Suite B — HTTP integration

Spin up the API:

```bash
pnpm start:dev
```

In a separate terminal, exercise the full lifecycle. Replace `$JWT`, `$STORE`, `$SUPPLIER` with values from your test tenant.

### B1 — Create draft GRN

```bash
curl -X POST http://localhost:3000/api/v1/grn \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "supplierId": "'$SUPPLIER'",
    "storeId": "'$STORE'",
    "invoiceNumber": "INV-T1-001",
    "invoiceDate": "2026-06-01",
    "inwardDate": "2026-06-05",
    "totalAmount": 5000,
    "items": [
      { "ean": "8901234567890", "quantity": 50, "unit": "pcs",
        "batchNumber": "B01", "expiryDate": "2027-06-30",
        "unitPrice": 100 }
    ]
  }'
```

**Expected**: 201 with body containing `id`, `grnNumber: "GRN-<store6>-202606-0001"`, `status: "draft"`, `totalItems: 1`, `totalQuantity: 50`. Save the returned `id` as `$GRN_ID`.

### B2 — Add more items

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/items \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      { "ean": "8901111111111", "quantity": 20,
        "batchNumber": "B02", "expiryDate": "2026-07-15" }
    ]
  }'
```

**Expected**: 201, returns array of created items. `GET /grn/$GRN_ID` now reports `totalItems: 2, totalQuantity: 70`.

### B3 — Validate

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/validate \
  -H "Authorization: Bearer $JWT"
```

**Expected**: 200 with `{ valid: true, errors: [], warnings: [...] }`. The second item (expiry 2026-07-15, ≤ 30 days from inward 2026-06-05) should generate a `short_shelf_life` warning.

### B4 — Post (atomic)

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/post \
  -H "Authorization: Bearer $JWT"
```

**Expected**: 200 with `{ grn: { status: "posted", postedAt, postedBy }, inventoryUpdates: [...], expiryRecordsCreated: 2 }`.

Verify side effects:
- `SELECT status, posted_at, posted_by, short_shelf_life_count FROM grn_headers WHERE id='$GRN_ID'` → posted, stamped, count > 0.
- `SELECT * FROM expiry_records WHERE source='grn' AND source_id IN (SELECT id FROM grn_items WHERE grn_id='$GRN_ID')` → 2 rows.
- `SELECT type, actor_id FROM grn_events WHERE grn_id='$GRN_ID' ORDER BY created_at` → at least `created`, `item_added`, `posted`.
- `SELECT action, resource_type, metadata FROM audit_logs WHERE resource_id='$GRN_ID'` → CREATE for the GRN, CREATE for the GrnPosting (with `transition: 'post'`).

### B5 — Cannot post twice

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/post \
  -H "Authorization: Bearer $JWT" -i
```

**Expected**: 422 with `{"code": "E7003", "message": "GRN has already been posted"}` (`GRN_ALREADY_POSTED`).

### B6 — Cannot edit posted GRN

```bash
curl -X PATCH http://localhost:3000/api/v1/grn/$GRN_ID \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"notes":"trying to edit"}' -i
```

**Expected**: 422 `GRN_ALREADY_POSTED`.

### B7 — Cannot cancel posted GRN

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/cancel \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"trying to cancel"}' -i
```

**Expected**: 422 `GRN_ALREADY_POSTED` with hint to use reverse instead.

### B8 — Reverse posted GRN

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/reverse \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"damage in transit"}'
```

**Expected**: 200 with `{ grn: { status: "reversed", reversedAt, reversedBy, reversalReason }, inventoryReverted: 2, expiryRecordsReverted: 2 }`.

Verify:
- `SELECT status, reversed_at, reversed_by, reversal_reason FROM grn_headers WHERE id='$GRN_ID'` → all set.
- `grn_events` now contains a `reversed` event with the reason in `notes`.
- Calling reverse again returns 422 (already reversed).

### B9 — Duplicate invoice rejected

Try creating a second GRN for the same supplier with the same invoice number:

```bash
curl -X POST http://localhost:3000/api/v1/grn \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{...same supplierId, same invoiceNumber...}' -i
```

**Expected**: 409 with `{"code": "E6001", "message": "Invoice ... already recorded for this supplier"}` (`DUPLICATE_RESOURCE`).

### B10 — Stats

```bash
curl "http://localhost:3000/api/v1/grn/stats?storeId=$STORE" \
  -H "Authorization: Bearer $JWT"
```

**Expected**: 200 with `{ total, byStatus: { draft, pending_review, posted, cancelled, reversed }, totalAmount, totalItems, totalQuantity, shortShelfLifeCount }`.

### B11 — List with cursor pagination

```bash
curl "http://localhost:3000/api/v1/grn?storeId=$STORE&limit=2" \
  -H "Authorization: Bearer $JWT"
```

**Expected**: 200 with `{ data: [...], nextCursor, hasMore }`. Pass the cursor on the next request and confirm no duplicates and `hasMore` eventually flips to false.

### B12 — Cancel a draft

Create a fresh draft (with a new invoice number) then:

```bash
curl -X POST http://localhost:3000/api/v1/grn/$DRAFT_ID/cancel \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"wrong supplier"}'
```

**Expected**: 200 with `status: "cancelled"`, `cancelledAt`, `cancelledBy`, `cancellationReason: "wrong supplier"`.

---

## Suite C — DB invariants

Run these queries directly against the Postgres dev DB.

### C1 — Duplicate invoice impossible at the storage layer

```sql
-- Manually attempt the duplicate insert (bypassing the service layer):
INSERT INTO grn_headers (
  id, tenant_id, store_id, grn_number, supplier_id,
  invoice_number, invoice_date, inward_date
) VALUES (
  gen_random_uuid(), '<tenant>', '<store>', 'GRN-X-Y-9999',
  '<supplier>', 'INV-DUP-001', '2026-06-01', '2026-06-02'
);
INSERT INTO grn_headers (
  id, tenant_id, store_id, grn_number, supplier_id,
  invoice_number, invoice_date, inward_date
) VALUES (
  gen_random_uuid(), '<tenant>', '<store>', 'GRN-X-Y-9998',
  '<supplier>', 'INV-DUP-001', '2026-06-03', '2026-06-04'
);
```

**Expected**: second insert fails with `duplicate key value violates unique constraint "uniq_grn_invoice_supplier"`.

### C2 — Duplicate batch on same GRN impossible

```sql
INSERT INTO grn_items (id, grn_id, tenant_id, store_id, ean, quantity, batch_number)
VALUES (gen_random_uuid(), '<grn>', '<tenant>', '<store>', '8901234567890', 1, 'B01');
INSERT INTO grn_items (id, grn_id, tenant_id, store_id, ean, quantity, batch_number)
VALUES (gen_random_uuid(), '<grn>', '<tenant>', '<store>', '8901234567890', 1, 'B01');
```

**Expected**: second insert fails on `uniq_grn_item_grn_ean_batch` (partial unique).

### C3 — Same EAN without batch can repeat

```sql
INSERT INTO grn_items (id, grn_id, tenant_id, store_id, ean, quantity)
VALUES (gen_random_uuid(), '<grn>', '<tenant>', '<store>', '8901234567890', 1);
INSERT INTO grn_items (id, grn_id, tenant_id, store_id, ean, quantity)
VALUES (gen_random_uuid(), '<grn>', '<tenant>', '<store>', '8901234567890', 1);
```

**Expected**: both succeed (partial index excludes NULL `batch_number`).

### C4 — Cascade delete

```sql
DELETE FROM grn_headers WHERE id = '<grn>';
SELECT COUNT(*) FROM grn_items WHERE grn_id = '<grn>';
SELECT COUNT(*) FROM grn_events WHERE grn_id = '<grn>';
```

**Expected**: both counts = 0 after the header is gone.

### C5 — Index usage

```sql
EXPLAIN
SELECT * FROM grn_headers
WHERE tenant_id = '<tenant>'
  AND store_id = '<store>'
  AND status = 'posted'
ORDER BY inward_date DESC
LIMIT 50;
```

**Expected**: plan uses `idx_grn_tenant_store_status_date`.

```sql
EXPLAIN
SELECT * FROM grn_headers WHERE supplier_id = '<supplier>' ORDER BY inward_date DESC;
```

**Expected**: plan uses `idx_grn_supplier_date`.

---

## Suite D — Security gates

### D1 — Tenant isolation

Authenticate as a user in tenant A; try to read a GRN owned by tenant B:

```bash
curl http://localhost:3000/api/v1/grn/<tenant-b-grn-id> \
  -H "Authorization: Bearer $JWT_TENANT_A" -i
```

**Expected**: 404 (not 403 — we mirror the products module convention to avoid leaking existence).

### D2 — Cross-tenant supplier reference

Authenticate as tenant A; try to create a GRN with a supplier from tenant B:

```bash
curl -X POST http://localhost:3000/api/v1/grn \
  -H "Authorization: Bearer $JWT_TENANT_A" \
  -H "Content-Type: application/json" \
  -d '{ "supplierId": "<tenant-b-supplier>", ... }' -i
```

**Expected**: 404 `Supplier not found`.

### D3 — Role gates

```bash
# Auditor tries to create a GRN:
curl -X POST http://localhost:3000/api/v1/grn -H "Authorization: Bearer $JWT_AUDITOR" -d '...' -i
```

**Expected**: 403 (auditor lacks `grn:write`).

### D4 — Owner-only reverse

```bash
# Manager attempts reverse:
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/reverse \
  -H "Authorization: Bearer $JWT_MANAGER" -d '{"reason":"x"}' -i
```

**Expected**: 403 (controller restricts to `owner`/`admin` roles).

### D5 — Validation rejection

Send a payload with negative quantity:

```bash
curl -X POST http://localhost:3000/api/v1/grn \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{ ..., "items": [{ "ean": "8901234567890", "quantity": -5 }] }' -i
```

**Expected**: 400 `VALIDATION_ERROR`, details point at the `quantity` field.

### D6 — Audit log surfaces every state change

```sql
SELECT action, resource_type, resource_id, user_id, metadata, occurred_at
FROM audit_logs
WHERE resource_id = '<grn-id>' OR (resource_type = 'GrnPosting' AND resource_id = '<grn-id>')
ORDER BY occurred_at;
```

**Expected** (for a full lifecycle): rows for CREATE Grn, UPDATE Grn (transition=edit), CREATE GrnPosting (transition=post), UPDATE GrnPosting (transition=reverse). Cancel adds a separate UPDATE Grn row with transition=cancel.

---

## Suite E — Transactional integrity (the most important suite)

Three explicit checks that BE-26's serializable posting + optimistic state guard hold up under concurrency and failure.

### E1 — Atomic rollback on inventory failure

If the inventory service throws during posting, no partial state must be observable.

The unit test `grn-posting.service.spec.ts → "rolls back the transaction when inventory throws"` already validates this: status remains `draft`, no posted event row, no stamped `posted_at`. To verify against a real DB, swap the `INVENTORY_SERVICE_TOKEN` provider for a stub that throws on the second item:

```typescript
class FailingInventoryStub implements IInventoryService {
  private count = 0;
  async applyInbound(req: InventoryMovementRequest) {
    this.count++;
    if (this.count === 2) throw new Error('forced failure');
    return { inventoryItemId: 'x', stockMovementId: 'y', newQuantity: req.quantity };
  }
  async applyOutbound() {
    throw new Error('not implemented');
  }
}
```

Boot the API with this provider override, attempt to post a 3-item GRN, then run:

```sql
SELECT status, posted_at FROM grn_headers WHERE id = '<grn-id>';
SELECT type FROM grn_events WHERE grn_id = '<grn-id>' AND type = 'posted';
SELECT COUNT(*) FROM expiry_records WHERE source_id IN (SELECT id FROM grn_items WHERE grn_id = '<grn-id>');
```

**Expected**: status = 'draft', posted_at IS NULL, no `posted` event, zero expiry_records (the BE-18 record creation runs inside the same transaction). The error response is `500` (the underlying error bubbles up since "forced failure" isn't a `BusinessException`).

### E2 — Concurrent post safety

Two clients call `POST /grn/$GRN_ID/post` simultaneously. Only one must succeed.

```bash
# In two terminals at the same time:
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/post -H "Authorization: Bearer $JWT" &
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/post -H "Authorization: Bearer $JWT" &
wait
```

**Expected**:
- Exactly one call returns 200 with the posted GRN.
- The other returns 422 `GRN_ALREADY_POSTED`. (Either the read-time guard rejects it, or the optimistic state guard returns null and the service surfaces "GRN was posted by another session".)

Verify side effects:

```sql
SELECT COUNT(*) FROM grn_events WHERE grn_id = '<grn-id>' AND type = 'posted';
SELECT COUNT(*) FROM expiry_records
  WHERE source = 'grn' AND source_id IN (SELECT id FROM grn_items WHERE grn_id = '<grn-id>');
```

**Expected**: exactly 1 `posted` event, exactly N `expiry_records` (where N = items with expiryDate, no doubling).

### E3 — Reversal idempotency

After a successful post + reverse cycle (Suite B8), attempt reverse a second time:

```bash
curl -X POST http://localhost:3000/api/v1/grn/$GRN_ID/reverse \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"reason":"second attempt"}' -i
```

**Expected**: 422 `BUSINESS_RULE_VIOLATION` with message "GRN has already been reversed". `grn_events` contains exactly **one** `reversed` event row (no duplicate from the second attempt). The DB-level reversal stamps (`reversed_at`, `reversed_by`, `reversal_reason`) are unchanged.

Concurrent reverse: same as E2 but with `/reverse` body. Exactly one wins; the other gets a 422 via the optimistic guard returning null.

### E4 — Number generator under contention

Two parallel draft creations for the same store + month:

```bash
curl -X POST http://localhost:3000/api/v1/grn -H "Authorization: Bearer $JWT" -d '{...invoice INV-A...}' &
curl -X POST http://localhost:3000/api/v1/grn -H "Authorization: Bearer $JWT" -d '{...invoice INV-B...}' &
wait
```

**Expected**: two distinct `grn_number` values returned. If the read-then-bump races collide, one of the inserts trips the `uniq_grn_number_tenant` index and the global exception filter returns 500 (we don't auto-retry — flagged as a known issue in the handoff). At the target scale this is exceedingly rare; if telemetry shows it, the recommendation is to graduate the generator to a Postgres sequence.

---

## Sign-off

- [ ] Suite A passes (`pnpm test --testPathPattern=grn` → 6 specs, 94 cases, all green).
- [ ] Suite B all 12 HTTP scenarios verified against a running API.
- [ ] Suite C invariants enforced at the DB layer.
- [ ] Suite D security gates verified.
- [ ] Suite E.1 atomic rollback verified manually with the failing inventory stub.
- [ ] Suite E.2 concurrent post returns exactly one success + one `GRN_ALREADY_POSTED`.
- [ ] Suite E.3 reverse idempotency verified.
- [ ] BE-26_HANDOFF integration checklist applied.
- [ ] `pnpm lint && pnpm test && pnpm build` all green from the server workspace.

**Reviewer Approval**: ☐ APPROVED — Proceed to BE-27   ☐ CHANGES REQUESTED

**Reviewer Signature**: ___________________________
