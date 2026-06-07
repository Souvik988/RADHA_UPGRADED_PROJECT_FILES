# BE-17 Verification Pack — Bulk Scan Processing

> Run after `pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (idempotency replay invariants), D (security gates), E (full lifecycle).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

STAFF_TOKEN=...      # tenant staff
B_TOKEN=...          # other tenant
SESSION_ID=...       # active session for the staff user
```

Use UUIDs throughout. Generate with `python3 -c "import uuid; print(uuid.uuid4())"` or any equivalent.

## Suite A — Unit

```bash
pnpm --filter @radha/server test src/modules/scans/__tests__
```
**Expect** the BE-17 specs:
- `idempotency.service.spec.ts` — 4 cases.
- `bulk-scan.service.spec.ts` — 13 cases.

(Plus BE-16's 28 cases continue to pass.)

**Total new**: 17 cases. Cumulative project total ≈ 380.

## Suite B — HTTP integration

### B1 — Small batch (5 items) succeeds

```bash
CID1=$(python3 -c "import uuid; print(uuid.uuid4())")
CID2=$(python3 -c "import uuid; print(uuid.uuid4())")
CID3=$(python3 -c "import uuid; print(uuid.uuid4())")
CID4=$(python3 -c "import uuid; print(uuid.uuid4())")
CID5=$(python3 -c "import uuid; print(uuid.uuid4())")

cat > /tmp/batch5.json <<EOF
{
  "items": [
    {"clientId":"$CID1","ean":"8901030789885","scannedAt":"2026-05-22T10:00:00Z"},
    {"clientId":"$CID2","ean":"8901491100049","scannedAt":"2026-05-22T10:00:01Z"},
    {"clientId":"$CID3","ean":"3017620422003","scannedAt":"2026-05-22T10:00:02Z"},
    {"clientId":"$CID4","ean":"8901030789885","scannedAt":"2026-05-22T10:00:03Z","batchNumber":"B-200"},
    {"clientId":"$CID5","ean":"abc","scannedAt":"2026-05-22T10:00:04Z"}
  ]
}
EOF

curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json | jq
```
**Expect**: HTTP 202, `status: "partial"` (because of the bad-format EAN in item 5), `totalItems: 5`. The bad-format item is recorded with `eanMatchStatus = 'invalid'` not as a failure, so failed=0 — verify with the next call.

### B2 — Status check

```bash
BATCH_ID=$(curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json | jq -r '.data.batchId')

curl -s "$HOST/api/v1/scan-sessions/sync-batches/$BATCH_ID" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```
**Expect**: progress.percentage = 100. processed/succeeded/duplicates/failed counters consistent.

### B3 — Idempotent replay returns duplicates

Re-submit the **exact same payload** (same clientIds):
```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json | jq
```
**Expect**: HTTP 202. Then status:
```bash
curl -s "$HOST/api/v1/scan-sessions/sync-batches/<NEW_BATCH_ID>" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '.data.progress'
```
**Expect**: `duplicates >= 4` (every item with a clientId in the previous batch shows up here). Verify in psql:
```sql
SELECT count(*) FROM scan_items WHERE session_id = '<SESSION>' AND deleted_at IS NULL;
-- 5 (no duplicates persisted)
```

### B4 — Mid-size batch (200 items)

```bash
python3 - <<EOF > /tmp/batch200.json
import json, uuid, datetime
items = []
for i in range(200):
    items.append({
        "clientId": str(uuid.uuid4()),
        "ean": "8901030789885",
        "scannedAt": (datetime.datetime.utcnow() + datetime.timedelta(seconds=i)).isoformat() + "Z",
        "batchNumber": f"B-{i:04d}",
    })
print(json.dumps({"items": items}))
EOF

time curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch200.json | jq '.data | { totalItems, status }'
```
**Expect**: HTTP 202, `status: "completed"`, total wall-clock < 30 s on a dev box (within HTTP budget).

### B5 — Empty batch rejected

```bash
curl -i -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"items":[]}'
```
**Expect**: HTTP 400 (Zod min-length-1).

### B6 — Within-batch duplicate clientIds rejected

```bash
DUPE=$(python3 -c "import uuid; print(uuid.uuid4())")
curl -i -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"items\":[{\"clientId\":\"$DUPE\",\"ean\":\"8901030789885\",\"scannedAt\":\"2026-05-22T10:00:00Z\"},{\"clientId\":\"$DUPE\",\"ean\":\"8901491100049\",\"scannedAt\":\"2026-05-22T10:00:01Z\"}]}"
```
**Expect**: HTTP 400, `error.code = "E2001"` (`INVALID_INPUT`).

### B7 — Oversized batch rejected at DTO level

```bash
python3 -c "import json,uuid; print(json.dumps({'items':[{'clientId':str(uuid.uuid4()),'ean':'8901030789885','scannedAt':'2026-05-22T10:00:00Z'} for _ in range(5001)]}))" > /tmp/huge.json
curl -i -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/huge.json
```
**Expect**: HTTP 400 (Zod max-5000).

### B8 — List sync batches

```bash
curl -s "$HOST/api/v1/scan-sessions/sync-batches?sessionId=$SESSION_ID&limit=10" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '.data | length'
```
**Expect**: ≥ 1 (or however many you've submitted).

## Suite C — Idempotency replay invariants

### C1 — Same clientId across multiple sessions is allowed

If a Mobile_App reuses a clientId across sessions (legitimate — different sessions are different scopes):
```bash
# Session A
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_A/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"items\":[{\"clientId\":\"$REUSED_CID\",\"ean\":\"8901030789885\",\"scannedAt\":\"2026-05-22T10:00:00Z\"}]}" \
  -H "Content-Type: application/json" | jq '.data'

# Session B (same user, different session)
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_B/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"items\":[{\"clientId\":\"$REUSED_CID\",\"ean\":\"8901030789885\",\"scannedAt\":\"2026-05-22T10:00:00Z\"}]}" \
  -H "Content-Type: application/json" | jq '.data'
```
**Expect**: Both batches succeed (different sessions, different idempotency scope). Two rows in `scan_items` — one per session.

### C2 — DB-level partial unique index enforcement

Try to manually insert a duplicate `(session_id, client_id)` via psql:
```sql
INSERT INTO scan_items (
  session_id, tenant_id, store_id, user_id, ean, ean_match_status, expiry_status,
  scanned_at, quantity, client_id
) VALUES (
  '<SESSION>', '<TENANT>', '<STORE>', '<USER>', '8901030789885',
  'matched', 'unknown', now(), 1, '<EXISTING_CLIENT_ID>'
);
```
**Expect**: ERROR `duplicate key value violates unique constraint "scan_items_session_client_uniq"`.

### C3 — NULL clientIds never collide

```sql
INSERT INTO scan_items (
  session_id, tenant_id, store_id, user_id, ean, ean_match_status, expiry_status,
  scanned_at, quantity, client_id
) VALUES
  ('<SESSION>', '<TENANT>', '<STORE>', '<USER>', '8901030789885', 'matched', 'unknown', now(), 1, NULL),
  ('<SESSION>', '<TENANT>', '<STORE>', '<USER>', '8901030789885', 'matched', 'unknown', now(), 1, NULL);
```
**Expect**: Both inserts succeed (partial index excludes NULL).

## Suite D — Security gates

### D1 — Cross-tenant batch access blocked

```bash
curl -i "$HOST/api/v1/scan-sessions/sync-batches/$A_BATCH_ID" -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 404 (tenant-scoped repo returns null).

### D2 — Cross-user submit blocked

User A submits a batch into User B's session:
```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$B_SESSION/bulk-sync" \
  -H "Authorization: Bearer $A_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json
```
**Expect**: HTTP 403 (`E4000`) — "Not your session".

### D3 — Bulk submit into a closed session

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$CLOSED_SESSION/bulk-sync" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json
```
**Expect**: HTTP 422 (`E7001` `SCAN_SESSION_CLOSED`).

### D4 — Free Consumer cannot bulk-sync

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/bulk-sync" \
  -H "Authorization: Bearer $FREE_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/batch5.json
```
**Expect**: HTTP 403 — `scans:write` permission missing.

### D5 — Cross-user cancel blocked

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/sync-batches/$A_BATCH_ID/cancel" \
  -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 403 — "Not your batch".

## Suite E — Full lifecycle

End-to-end sequence on a fresh session:
1. Create session → `POST /scan-sessions`.
2. Submit batch of 50 items → `POST /:id/bulk-sync` → 202, status `completed`.
3. `GET /sync-batches/:batchId` → percentage 100, succeeded=50, duplicates=0, failed=0.
4. `POST /:id/bulk-sync` (same payload, replay) → 202, status `completed`, but `duplicates=50, succeeded=0`.
5. `psql: SELECT count(*) FROM scan_items WHERE session_id = '<SESSION>' AND deleted_at IS NULL;` → 50 (no doubles).
6. `POST /:id/end` (BE-16) → status `completed`, totalScans=50.
7. Try another bulk-sync → HTTP 422 (closed).
8. Audit log:
   ```sql
   SELECT action, metadata FROM audit_logs
    WHERE resource_type = 'ScanSyncBatch'
    ORDER BY created_at;
   -- IMPORT (success=true), IMPORT (success=true / duplicates=50)
   ```

## Final sign-off

- [ ] Suite A: 17 unit cases pass (plus 28 from BE-16 still passing)
- [ ] Suite B: 8 HTTP integration scenarios on a real DB
- [ ] Suite C: 3 idempotency invariants verified in psql
- [ ] Suite D: 5 security gates fire correctly
- [ ] Suite E: full lifecycle + audit trail verified

**Verified by**: ___________________________
**Date**: ___________________________
