# BE-18 Verification Pack — Expiry Tracking & Alerts

> Run after `pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (tenant invariants), D (security gates), E (recalc + cron simulation).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...        # tenant owner
MANAGER_TOKEN=...      # tenant manager
STAFF_TOKEN=...        # tenant staff
B_TOKEN=...            # tenant B
STORE_ID=...           # store under tenant A
PRODUCT_ID=...         # product visible to tenant A (set sub_category='dairy' to test category-aware paths)
```

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/expiry/__tests__
```
**Expect**:
- `expiry-rules.utils.spec.ts` — 11 cases.
- `default-thresholds.spec.ts` — 5 cases.
- `expiry-calculator.service.spec.ts` — 4 cases.
- `ocr-date-validator.service.spec.ts` — 13 cases.
- `expiry-threshold.service.spec.ts` — 5 cases.
- `expiry-alert.service.spec.ts` — 12 cases.

**Total**: 50 new cases. Cumulative project total ≈ 430.

## Suite B — HTTP integration

### B1 — Create expiry record (green)

```bash
EXPIRY=$(date -u -d '+90 days' +%Y-%m-%dT%H:%M:%SZ)
curl -s -X POST "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PRODUCT_ID\",\"storeId\":\"$STORE_ID\",\"expiryDate\":\"$EXPIRY\",\"quantity\":50,\"source\":\"manual\"}" | jq
```
**Expect**: HTTP 201, `status: "green"`, `daysRemaining: ~90`. No alert generated:
```sql
SELECT count(*) FROM expiry_alerts WHERE expiry_record_id = '<RECORD_ID>';
-- 0
```

### B2 — Create expiry record near expiry (yellow → auto-alert)

```bash
EXPIRY=$(date -u -d '+15 days' +%Y-%m-%dT%H:%M:%SZ)
curl -s -X POST "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PRODUCT_ID\",\"storeId\":\"$STORE_ID\",\"expiryDate\":\"$EXPIRY\",\"quantity\":12}" | jq
```
**Expect**: `status: "yellow"`. Alert auto-created:
```sql
SELECT id, status, is_resolved FROM expiry_alerts WHERE expiry_record_id = '<RECORD_ID>';
-- 1 row, status='yellow', is_resolved=false
```

### B3 — Create record near red threshold

```bash
EXPIRY=$(date -u -d '+3 days' +%Y-%m-%dT%H:%M:%SZ)
curl -s -X POST "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$DAIRY_PRODUCT_ID\",\"storeId\":\"$STORE_ID\",\"expiryDate\":\"$EXPIRY\",\"quantity\":5}" | jq
```
**Expect**: For a dairy-categorised product (yellow=7, red=2), `status: "yellow"` (3 > 2). Then re-run with `+1 days` → `status: "red"`.

### B4 — Near-expiry list

```bash
curl -s "$HOST/api/v1/expiry-records/near-expiry?storeId=$STORE_ID&daysAhead=30" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '. | length'
```
**Expect**: ≥ 2 (the yellow + red records from B2/B3).

### B5 — Stats by category

```bash
curl -s "$HOST/api/v1/expiry-records/stats?storeId=$STORE_ID" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```
**Expect**:
```json
{ "storeId": "...", "total": 3, "green": 1, "yellow": 2, "red": 0, "expired": 0, "unknown": 0 }
```
And:
```bash
curl -s "$HOST/api/v1/expiry-records/stats/by-category?storeId=$STORE_ID" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```
**Expect**: per-category breakdown.

### B6 — Forecast

```bash
curl -s "$HOST/api/v1/expiry-records/forecast?storeId=$STORE_ID&daysAhead=30" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '.days | length'
```
**Expect**: at least 1 day with non-zero `expiringCount`.

### B7 — Tenant threshold override

```bash
curl -s -X PUT "$HOST/api/v1/expiry-thresholds" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"dairy","yellowDays":14,"redDays":4}' | jq
```
**Expect**: row created/updated. Verify:
```sql
SELECT yellow_days, red_days FROM expiry_thresholds WHERE tenant_id = '<TENANT>' AND category = 'dairy';
-- 14, 4
```

### B8 — Acknowledge alert

```bash
ALERT_ID=$(curl -s "$HOST/api/v1/expiry-alerts?storeId=$STORE_ID" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq -r '.[0].id')

curl -s -X POST "$HOST/api/v1/expiry-alerts/$ALERT_ID/acknowledge" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notes":"Will discount by EOD"}' | jq
```
**Expect**: `isAcknowledged: true`, `acknowledgedBy` set, `acknowledgedNotes` matches.

### B9 — Resolve alert

```bash
curl -s -X POST "$HOST/api/v1/expiry-alerts/$ALERT_ID/resolve" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resolution":"discounted","notes":"50% off applied"}' | jq
```
**Expect**: `isResolved: true`, `resolution: "discounted"`. The `(expiry_record_id, 'yellow')` partial unique slot is now free for a fresh alert if the record changes status again.

### B10 — Recalculate after threshold change

```bash
curl -s -X POST "$HOST/api/v1/expiry-records/recalculate" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"storeId\":\"$STORE_ID\"}" | jq
```
**Expect**: `{ scanned: <N>, updated: <M>, alertsCreated: <K> }`. Records that flip status now reflect the new tenant thresholds.

### B11 — OCR validation

```bash
curl -s -X POST "$HOST/api/v1/expiry/ocr/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"EXP: 31/12/2030","confidence":0.92}' | jq
```
**Expect**: `valid: true`, `format: "DD-MM-YYYY"`, `date: "2030-12-31T00:00:00.000Z"`, no warning.

```bash
curl -s -X POST "$HOST/api/v1/expiry/ocr/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"EXP: 31/12/2099","confidence":0.92}' | jq
```
**Expect**: `valid: false`, warning mentions "future".

## Suite C — Tenant invariants

### C1 — Cross-tenant record access blocked

```bash
curl -i "$HOST/api/v1/expiry-records/$A_RECORD_ID" -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 404.

### C2 — Threshold isolation

Tenant A sets dairy yellow=14. Tenant B's resolution should still see platform default 7:
```bash
curl -s "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $B_TOKEN" \
  -G --data-urlencode "storeId=$B_STORE" | jq
# Tenant B's records use 7-day yellow threshold for dairy
```

### C3 — Active-alert uniqueness per record per status

Try to manually insert a duplicate active alert:
```sql
INSERT INTO expiry_alerts (tenant_id, store_id, expiry_record_id, product_id, status, days_remaining, quantity)
VALUES ('<TENANT>','<STORE>','<RECORD>','<PRODUCT>','red',2,5);
INSERT INTO expiry_alerts (tenant_id, store_id, expiry_record_id, product_id, status, days_remaining, quantity)
VALUES ('<TENANT>','<STORE>','<RECORD>','<PRODUCT>','red',2,5);
```
**Expect**: second INSERT fails with `duplicate key value violates unique constraint "expiry_alerts_active_per_record_uniq"`.

After resolving the first alert (`is_resolved=true`), inserting another `(record, 'red')` succeeds — because the partial index excludes resolved rows.

## Suite D — Security gates

### D1 — Free Consumer cannot create

```bash
curl -i -X POST "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $FREE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PRODUCT_ID\",\"storeId\":\"$STORE_ID\",\"expiryDate\":\"2027-01-01T00:00:00Z\",\"quantity\":1}"
```
**Expect**: HTTP 403 (`inventory:write` missing).

### D2 — Staff cannot upsert thresholds

```bash
curl -i -X PUT "$HOST/api/v1/expiry-thresholds" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"dairy","yellowDays":7,"redDays":2}'
```
**Expect**: HTTP 403 (Owner/Admin only).

### D3 — Staff cannot recalculate

```bash
curl -i -X POST "$HOST/api/v1/expiry-records/recalculate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"storeId\":\"$STORE_ID\"}"
```
**Expect**: HTTP 403 (Manager+).

### D4 — Invalid threshold rejected (yellow ≤ red)

```bash
curl -i -X PUT "$HOST/api/v1/expiry-thresholds" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category":"dairy","yellowDays":3,"redDays":7}'
```
**Expect**: HTTP 400 (Zod refine: `yellowDays must be greater than redDays`).

### D5 — Manufacture date after expiry rejected

```bash
curl -i -X POST "$HOST/api/v1/expiry-records" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productId\":\"$PRODUCT_ID\",\"storeId\":\"$STORE_ID\",\"expiryDate\":\"2026-01-01T00:00:00Z\",\"manufactureDate\":\"2026-06-01T00:00:00Z\",\"quantity\":1}"
```
**Expect**: HTTP 400 (Zod refine).

### D6 — OCR sanity bounds

```bash
curl -s -X POST "$HOST/api/v1/expiry/ocr/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"EXP: 30/02/2027","confidence":0.92}' | jq '.valid'
# false (Feb 30 invalid)
```

## Suite E — Recalc + cron simulation

1. Create 5 records at various distances (3, 6, 15, 31, 90 days out).
2. Snapshot status: `SELECT id, status FROM expiry_records WHERE store_id = '<STORE>';` → expect a mix of red/yellow/green.
3. Update tenant threshold to a stricter version (e.g. yellow=10, red=3).
4. Call `POST /expiry-records/recalculate`.
5. Re-query: rows that previously qualified as yellow at distance 15 should now be green; the 6-day record may flip from red to yellow depending on category.
6. Audit log:
   ```sql
   SELECT action, metadata FROM audit_logs WHERE resource_type = 'ExpiryRecord' ORDER BY created_at DESC LIMIT 5;
   ```
   **Expect**: `UPDATE` with `metadata.transition = 'recalculate'` and counters for scanned/updated/alertsCreated.
7. Simulate "next day": manually update `lastStatusUpdate` to yesterday and run recalc again. Status drift gets caught and persisted.

## Final sign-off

- [ ] Suite A: 50 unit cases pass
- [ ] Suite B: 11 HTTP integration scenarios pass on a real DB
- [ ] Suite C: 3 tenant + DB-level invariants verified in psql
- [ ] Suite D: 6 security gates fire correctly
- [ ] Suite E: recalc end-to-end with audit trail

**Verified by**: ___________________________
**Date**: ___________________________
