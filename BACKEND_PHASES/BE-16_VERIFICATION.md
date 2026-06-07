# BE-16 Verification Pack — Scan Session Management

> Run after `pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (tenant + cross-user), D (security gates), E (full lifecycle + audit trail).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...    # tenant owner
MANAGER_TOKEN=...  # tenant manager
STAFF_TOKEN=...    # tenant staff
AUDITOR_TOKEN=...  # auditor (read+export, no write)
FREE_TOKEN=...     # free_consumer (no scans:* perms)
A_TOKEN=...        # tenant A staff
B_TOKEN=...        # tenant B staff

STORE_ID=...       # store under tenant A
LIST_ID=...        # active EAN list with at least one EAN '8901030789885'
EAN_IN=8901030789885    # in the active list
EAN_OUT=8901491100049   # NOT in the active list
```

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/scans/__tests__
```
**Expect**:
- `scan-stats.utils.spec.ts` — 9 cases.
- `duplicate-detector.service.spec.ts` — 3 cases.
- `scan-item.service.spec.ts` — 9 cases.
- `scan-session.service.spec.ts` — 7 cases.

**Total**: 28 new cases. Cumulative project total ≈ 363.

## Suite B — HTTP integration

### B1 — Create session

```bash
SESSION=$(curl -s -X POST "$HOST/api/v1/scan-sessions" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"storeId\":\"$STORE_ID\",\"type\":\"audit\",\"eanListId\":\"$LIST_ID\"}")
SESSION_ID=$(echo "$SESSION" | jq -r '.data.id')
echo "Created session $SESSION_ID"
```
**Expect**: HTTP 201, status `active`, totalScans 0, eanListId set.

### B2 — Cannot create a duplicate active session

```bash
curl -i -s -X POST "$HOST/api/v1/scan-sessions" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"storeId\":\"$STORE_ID\",\"type\":\"audit\"}"
```
**Expect**: HTTP 409 with `error.code = "E6000"` and `metadata.activeSessionId` set.

### B3 — Resume active session

```bash
curl -s "$HOST/api/v1/scan-sessions/active?storeId=$STORE_ID" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '.data.id'
```
**Expect**: matches `$SESSION_ID`.

### B4 — Record a matched scan

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T10:00:00Z\",\"quantity\":1}" | jq
```
**Expect**: `eanMatchStatus = "matched"`, no `unmatched_ean` warning, `isDuplicate: false`. Session counter `matchedEans` increments.

### B5 — Record an unmatched scan

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_OUT\",\"scannedAt\":\"2026-05-22T10:01:00Z\"}" \
  -H "Content-Type: application/json" | jq '.data.eanValidation.reason'
```
**Expect**: `"not_in_list"`. Response includes `unmatched_ean` warning with `severity: "error"`.

### B6 — Record a near-expiry scan

```bash
EXPIRY=$(date -u -d '+15 days' +%Y-%m-%dT%H:%M:%SZ)
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T10:02:00Z\",\"expiryDate\":\"$EXPIRY\",\"batchNumber\":\"B-100\"}" \
  -H "Content-Type: application/json" | jq '.data.expiryStatus, .data.warnings[].type'
```
**Expect**: `"yellow"` and `"near_expiry"`.

### B7 — Duplicate detection

Re-run B4 (same EAN, same `batchNumber=null` since B4 didn't include one):
```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T10:03:00Z\"}" \
  -H "Content-Type: application/json" | jq '.data.isDuplicate, .data.duplicateOf.id'
```
**Expect**: `true` and the id of the first scan from B4.

### B8 — Different batch ≠ duplicate

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T10:04:00Z\",\"batchNumber\":\"B-200\"}" \
  -H "Content-Type: application/json" | jq '.data.isDuplicate'
```
**Expect**: `false` — different batch number is a legitimate re-scan.

### B9 — Session summary

```bash
curl -s "$HOST/api/v1/scan-sessions/$SESSION_ID/summary" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```
**Expect**: `totalScans` matches the actual count from `scan_items`. `scanRate` is a positive number. `warningsCount = unmatched + expired + nearExpiry`.

### B10 — Batch scan

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items/batch" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d '{"items":[{"ean":"8901030789885","scannedAt":"2026-05-22T10:10:00Z"},{"ean":"abc","scannedAt":"2026-05-22T10:10:01Z"}]}' \
  -H "Content-Type: application/json" | jq '.data | { resultsCount: .results | length, failuresCount: .failures | length }'
```
**Expect**: Two results returned (the second has `eanMatchStatus = "invalid"`). `failures` is empty because the bad EAN is recorded with `invalid` status, not thrown.

### B11 — End session

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/end" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d '{"notes":"Audit complete"}' \
  -H "Content-Type: application/json" | jq '.data.status, .data.durationSeconds, .data.totalScans'
```
**Expect**: `"completed"`, positive integer durationSeconds, totalScans matches the items count.

### B12 — Cannot scan into a closed session

```bash
curl -i -s -X POST "$HOST/api/v1/scan-sessions/$SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T11:00:00Z\"}" \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 422, `error.code = "E7001"` (`SCAN_SESSION_CLOSED`).

### B13 — List sessions

```bash
curl -s "$HOST/api/v1/scan-sessions?storeId=$STORE_ID" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq '.data | length'
```
**Expect**: ≥ 1.

## Suite C — Tenant + cross-user invariants

### C1 — Cross-tenant access blocked

```bash
curl -i "$HOST/api/v1/scan-sessions/$SESSION_ID" -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 403 (TenantScopeGuard) or 404 (tenant-scoped repository) — both acceptable.

### C2 — Cross-user end blocked

Create a session as Staff A; try to end it as Staff B (same tenant):
```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$STAFF_A_SESSION/end" \
  -H "Authorization: Bearer $STAFF_B_TOKEN" \
  -d '{}' -H "Content-Type: application/json"
```
**Expect**: HTTP 403 (`E4000`) — "Cannot end a session belonging to another user".

### C3 — Cross-user scan into other user's session blocked

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$STAFF_A_SESSION/items" \
  -H "Authorization: Bearer $STAFF_B_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T11:00:00Z\"}" \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 403.

### C4 — DB-level partial unique index

Even with two HTTP requests racing, only one active session per (user, store) survives:
```sql
SELECT count(*) FROM scan_sessions
 WHERE user_id = '<USER>' AND store_id = '<STORE>' AND status = 'active' AND deleted_at IS NULL;
-- 1
```

## Suite D — Security gates

### D1 — Free Consumer cannot create sessions

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions" \
  -H "Authorization: Bearer $FREE_TOKEN" \
  -d "{\"storeId\":\"$STORE_ID\",\"type\":\"audit\"}" \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 403 — `scans:write` missing.

### D2 — Auditor can read but not write

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions" \
  -H "Authorization: Bearer $AUDITOR_TOKEN" \
  -d "{\"storeId\":\"$STORE_ID\",\"type\":\"audit\"}" \
  -H "Content-Type: application/json"
# 403 — auditor has scans:read + scans:export, not scans:write

curl -i "$HOST/api/v1/scan-sessions/$SESSION_ID" \
  -H "Authorization: Bearer $AUDITOR_TOKEN"
# 200 — read works
```

### D3 — Invalid EAN format → recorded with invalid status

```bash
curl -s -X POST "$HOST/api/v1/scan-sessions/$NEW_SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d '{"ean":"abc","scannedAt":"2026-05-22T10:00:00Z"}' \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 400 (Zod regex rejects letters in EAN). Even if the regex were bypassed, `validateEan` would catch it and the path would persist with `eanMatchStatus = 'invalid'` (no SQL injection vector).

### D4 — SQL-injection-style EAN treated as data

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$NEW_SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"' OR 1=1 --\",\"scannedAt\":\"2026-05-22T10:00:00Z\"}" \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 400 (Zod regex). Drizzle parameterises every other path.

### D5 — Quantity cap

```bash
curl -i -X POST "$HOST/api/v1/scan-sessions/$NEW_SESSION_ID/items" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"$EAN_IN\",\"scannedAt\":\"2026-05-22T10:00:00Z\",\"quantity\":1000000}" \
  -H "Content-Type: application/json"
```
**Expect**: HTTP 400 (Zod max(100_000)).

### D6 — Soft-delete preserves audit trail

After `DELETE /scan-sessions/$ID/items/$ITEM_ID`:
```sql
SELECT id, ean, deleted_at FROM scan_items WHERE id = '<itemId>';
-- one row, deleted_at is set
```

## Suite E — Full lifecycle + audit trail

End-to-end test on a fresh session:
1. `POST /scan-sessions` (audit type, with eanListId).
2. Record 5 scans: 3 matched, 1 unmatched, 1 expired.
3. `GET /scan-sessions/:id` — verify counters are in sync.
4. `GET /scan-sessions/:id/summary` — verify summary matches counters.
5. `DELETE /scan-sessions/:id/items/:itemId` — remove the unmatched scan.
6. `GET /scan-sessions/:id/summary` — verify counters dropped (drift-free recompute).
7. `POST /scan-sessions/:id/end` — verify status is `completed` and counters refreshed once more.
8. `POST /scan-sessions/:id/items` again — verify HTTP 422 `SCAN_SESSION_CLOSED`.
9. Audit log:
   ```sql
   SELECT action, metadata FROM audit_logs
    WHERE resource_type = 'ScanSession' AND resource_id = '<SESSION>'
    ORDER BY created_at;
   ```
   Expected sequence: `CREATE` → `UPDATE(transition=complete)`.

## Final sign-off

- [ ] Suite A: 28 unit cases pass
- [ ] Suite B: 13 HTTP integration scenarios on a real DB
- [ ] Suite C: 4 tenant + cross-user invariants
- [ ] Suite D: 6 security gates
- [ ] Suite E: full lifecycle + audit trail verified

**Verified by**: ___________________________
**Date**: ___________________________
