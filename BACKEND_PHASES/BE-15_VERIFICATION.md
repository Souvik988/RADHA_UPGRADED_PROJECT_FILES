# BE-15 Verification Pack — EAN List Import & Validation

> Run after `pnpm install && pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (tenant invariants), D (security gates), E (full lifecycle).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...        # tenant owner with products:write
MANAGER_TOKEN=...      # tenant manager
STAFF_TOKEN=...        # tenant staff (read only on lists)
FREE_TOKEN=...         # free_consumer
A_TOKEN=...            # tenant A owner
B_TOKEN=...            # tenant B owner

STORE_ID=...           # any store under tenant A
```

Prep two CSV fixtures and one XLSX fixture:

```bash
# fixtures/sample-good.csv
cat > /tmp/sample-good.csv <<'EOF'
ean,name,brand,notes
8901030789885,Maggi 2-Min Noodles,Nestle,Family pack
8901491100049,Britannia Bourbon,Britannia,Original
3017620422003,Nutella,Ferrero,250 g jar
EOF

# fixtures/sample-with-errors.csv
cat > /tmp/sample-errors.csv <<'EOF'
ean,name,brand
,Missing EAN row,FooBrand
abc,Letters in EAN,FooBrand
8901030789880,Wrong check digit,FooBrand
8901030789885,First valid,Nestle
8901030789885,Duplicate of row 5,Nestle
EOF
```

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/ean-lists/__tests__
```
**Expect**:
- `file-detector.utils.spec.ts` — 10 cases.
- `row-mapper.utils.spec.ts` — 6 cases.
- `import-processor.service.spec.ts` — 5 cases.
- `ean-matcher.service.spec.ts` — 11 cases.

**Total**: 32 new cases. Cumulative project total ≈ 335.

## Suite B — HTTP integration

### B1 — Create draft list

```bash
LIST=$(curl -s -X POST "$HOST/api/v1/ean-lists" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Q3 2026 Approved\",\"storeId\":\"$STORE_ID\"}")
LIST_ID=$(echo "$LIST" | jq -r '.data.id')
echo "Created list $LIST_ID"
```
**Expect**: HTTP 201, status `draft`, version 1, totalItems 0.

### B2 — Inline CSV import

```bash
B64=$(base64 -w0 /tmp/sample-good.csv)
curl -s -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"csv\",\"fileName\":\"good.csv\",\"fileBase64\":\"$B64\"}" | jq
```
**Expect**: HTTP 202, response includes `batchId`. After ~500 ms the batch is `completed`:
```bash
curl -s "$HOST/api/v1/ean-lists/imports/$BATCH_ID" -H "Authorization: Bearer $OWNER_TOKEN" | jq
# status: "completed", validRows: 3, invalidRows: 0
```

Confirm in psql:
```sql
SELECT count(*) FROM ean_list_items WHERE list_id = '<LIST_ID>';
-- 3
SELECT product_id IS NOT NULL FROM ean_list_items WHERE list_id = '<LIST_ID>' AND ean = '3017620422003';
-- t (Nutella was already in the global catalog from BE-11)
```

### B3 — Inline CSV with errors

```bash
B64=$(base64 -w0 /tmp/sample-errors.csv)
curl -s -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"csv\",\"fileName\":\"errors.csv\",\"fileBase64\":\"$B64\"}" | jq
```
**Expect**: status `completed`, `validRows: 1`, `invalidRows: 4` (missing EAN, letters, wrong check digit, duplicate of row 5).

### B4 — Errors detail endpoint

```bash
BATCH_ID=...   # from B3 response
curl -s "$HOST/api/v1/ean-lists/imports/$BATCH_ID/errors" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data | length'
```
**Expect**: 4. Each entry has `rowNumber`, `errors` array, `rawData` JSONB.

### B5 — Errors CSV download

```bash
curl -s "$HOST/api/v1/ean-lists/imports/$BATCH_ID/errors/csv" \
  -H "Authorization: Bearer $OWNER_TOKEN" -o /tmp/errors.csv
head -n 5 /tmp/errors.csv
```
**Expect**: header `rowNumber,errors,rawData` followed by the 4 error rows. Verify it parses cleanly (no broken quoting):
```bash
python3 -c "import csv; print(list(csv.reader(open('/tmp/errors.csv'))))"
```

### B6 — Activate list

```bash
curl -s -X POST "$HOST/api/v1/ean-lists/$LIST_ID/activate" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.status'
# "active"
```
Confirm only one active list per scope:
```sql
SELECT count(*) FROM ean_lists WHERE store_id = '<STORE_ID>' AND status = 'active' AND deleted_at IS NULL;
-- 1
```

### B7 — Validate single EAN against active list

```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"ean\":\"8901030789885\",\"storeId\":\"$STORE_ID\"}" | jq
```
**Expect**:
```json
{ "valid": true, "matched": true, "ean": "8901030789885", "listItem": {...} }
```

EAN not in list:
```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"ean\":\"9999999999994\",\"storeId\":\"$STORE_ID\"}" | jq '.data.reason'
# "not_in_list"
```

### B8 — Batch validation

```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate/batch" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"eans\":[\"8901030789885\",\"9999999999994\",\"abc\"],\"storeId\":\"$STORE_ID\"}" | jq
```
**Expect**: 3-keyed object — first matched, second `not_in_list`, third `invalid_format`. Single round-trip to DB.

### B9 — XLSX import (requires `xlsx` package + a fixture)

Create a tiny XLSX with the same headers and 3 EANs:
```bash
python3 - <<'EOF'
import openpyxl
wb = openpyxl.Workbook()
ws = wb.active
ws.append(['EAN','Name','Brand'])
ws.append(['8901030789885','Maggi','Nestle'])
ws.append(['8901491100049','Bourbon','Britannia'])
wb.save('/tmp/sample.xlsx')
EOF

B64=$(base64 -w0 /tmp/sample.xlsx)
curl -s -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"xlsx\",\"fileName\":\"sample.xlsx\",\"fileBase64\":\"$B64\"}" | jq
```
**Expect**: `validRows: 2` (idempotent — these EANs are already in the list, so onConflictDoNothing skips silently).

### B10 — List items

```bash
curl -s "$HOST/api/v1/ean-lists/$LIST_ID/items?limit=10" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq '.data | length'
```
**Expect**: 4 (3 from B2 + 1 valid row from B3 — duplicate of row 5 was rejected).

### B11 — Cancel a queued import

Spam-create another import (uses sync v1, so by the time we read it'll be `completed`; with BE-24 async this'll meaningfully test cancellation):
```bash
B64=$(base64 -w0 /tmp/sample-good.csv)
RESP=$(curl -s -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"csv\",\"fileName\":\"x.csv\",\"fileBase64\":\"$B64\"}")
BATCH_ID=$(echo "$RESP" | jq -r '.data.batchId')

curl -i -X POST "$HOST/api/v1/ean-lists/imports/$BATCH_ID/cancel" \
  -H "Authorization: Bearer $OWNER_TOKEN"
```
**Expect (v1 sync)**: HTTP 422 (`E7000` — "Cannot cancel batch in status completed"). The contract is enforced; cancellation only succeeds for `queued` / `processing`.

## Suite C — Tenant invariants

### C1 — Cross-tenant access blocked

Tenant B tries to read Tenant A's list:
```bash
curl -i "$HOST/api/v1/ean-lists/$A_LIST_ID" -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 404, `error.code = "E5000"`.

Tenant B tries to validate against Tenant A's store:
```bash
curl -i -X POST "$HOST/api/v1/ean-lists/validate" \
  -H "Authorization: Bearer $B_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"ean\":\"8901030789885\",\"storeId\":\"$A_STORE_ID\"}"
```
**Expect**: HTTP 403 (TenantScopeGuard rejects the cross-tenant store reference).

### C2 — Tenant-wide list as fallback when no store-specific list

Tenant A has only a tenant-wide list (no `storeId`). Validate with a store under tenant A:
```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate" \
  -H "Authorization: Bearer $A_TOKEN" \
  -d "{\"ean\":\"8901030789885\",\"storeId\":\"$ANY_A_STORE\"}" | jq
```
**Expect**: matched (the tenant-wide list applies to all stores in the tenant).

### C3 — Store-specific list overrides tenant-wide

Activate a store-specific list with **different** EANs. Then validate:
```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate" \
  -d "{\"ean\":\"<an EAN only in tenant-wide list>\",\"storeId\":\"$STORE_WITH_OVERRIDE\"}"
```
**Expect**: `not_in_list` (store override hides the tenant-wide list for that store).

## Suite D — Security gates

### D1 — Free Consumer cannot create / import / validate

```bash
curl -i -X POST "$HOST/api/v1/ean-lists" \
  -H "Authorization: Bearer $FREE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"x"}'
```
**Expect**: HTTP 403 — `products:write` permission missing for `free_consumer`.

### D2 — Staff cannot import or activate

```bash
curl -i -X POST "$HOST/api/v1/ean-lists/$LIST_ID/activate" \
  -H "Authorization: Bearer $STAFF_TOKEN"
```
**Expect**: HTTP 403.

### D3 — Mislabelled file rejected

Take the CSV bytes from B1 and submit them with `fileType: "xlsx"`:
```bash
B64=$(base64 -w0 /tmp/sample-good.csv)
curl -i -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"xlsx\",\"fileName\":\"hostile.xlsx\",\"fileBase64\":\"$B64\"}"
```
**Expect**: HTTP 400, validation error mentioning "does not match detected" or unrecognised format.

### D4 — Legacy `.xls` rejected

Save anything in legacy `.xls` format and try:
**Expect**: HTTP 400, "Legacy .xls files are not supported".

### D5 — Oversized file

```bash
# Build ~25 MB random CSV
python3 -c "import random; print('ean,name'); [print(f'89010307898{i:04d},Item {i}') for i in range(1_500_000)]" > /tmp/huge.csv
B64=$(base64 -w0 /tmp/huge.csv)
curl -i -X POST "$HOST/api/v1/ean-lists/$LIST_ID/import" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"fileType\":\"csv\",\"fileName\":\"huge.csv\",\"fileBase64\":\"$B64\"}"
```
**Expect**: HTTP 400 — DTO `fileBase64` capped at 14 MB.

### D6 — Cannot delete an active list

After activation:
```bash
curl -i -X DELETE "$HOST/api/v1/ean-lists/$LIST_ID" -H "Authorization: Bearer $OWNER_TOKEN"
```
**Expect**: HTTP 422 (`E7000`) — must deactivate first.

### D7 — SQL-injection-like EANs are treated as literal text

```bash
curl -s -X POST "$HOST/api/v1/ean-lists/validate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d "{\"ean\":\"' OR 1=1 --\",\"storeId\":\"$STORE_ID\"}"
```
**Expect**: HTTP 400 (Zod regex rejects the input). Even if it bypassed Zod, Drizzle parameterises and the EAN regex normalisation would strip non-digits, leaving an empty string that fails the format check.

## Suite E — Full lifecycle

End-to-end flow on a fresh list:

1. **Create draft** → status `draft`, totalItems 0.
2. **Import CSV** → status `completed`, totalItems > 0.
3. **Read list** → `matchedItems` reflects how many EANs linked to the catalog.
4. **Activate** → status `active`, previous active list (if any) archived.
5. **Validate matched EAN** → `matched: true`.
6. **Validate unmatched EAN** → `reason: not_in_list`.
7. **Activate a different list in same scope** → previous list goes to `archived` automatically.
8. **Deactivate** → status `archived`, no active list for the scope.
9. **Validate now** → `reason: no_active_list`.

```sql
-- verify scope invariant after activation
SELECT id, name, status FROM ean_lists
WHERE tenant_id = '<TENANT>' AND store_id = '<STORE>' AND deleted_at IS NULL
ORDER BY activated_at DESC;
-- exactly one row with status='active', the rest archived
```

```sql
-- verify audit log captures the lifecycle
SELECT action, metadata FROM audit_logs
WHERE resource_id = '<LIST_ID>'
ORDER BY created_at;
-- CREATE → IMPORT → UPDATE(transition=activate) → UPDATE(transition=deactivate)
```

## Final sign-off

- [ ] Suite A: 32 unit cases pass
- [ ] Suite B: 11 HTTP integration scenarios pass on real Excel + CSV
- [ ] Suite C: 3 tenant-isolation invariants verified
- [ ] Suite D: 7 security gates fire correctly
- [ ] Suite E: full lifecycle end-to-end with audit trail

**Verified by**: ___________________________
**Date**: ___________________________
