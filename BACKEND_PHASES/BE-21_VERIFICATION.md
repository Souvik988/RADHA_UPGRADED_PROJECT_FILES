# BE-21 Verification Pack — Report Export & S3 Storage

> Run after the orchestrator merge (see `BE-21_HANDOFF.md` §
> "ORCHESTRATOR INTEGRATION CHECKLIST"). Five suites: A unit, B
> HTTP integration, C tenant invariants, D security gates, E full
> lifecycle.

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...        # tenant A owner
MANAGER_TOKEN=...      # tenant A manager
STAFF_TOKEN=...        # tenant A staff
B_TOKEN=...            # tenant B owner (for cross-tenant tests)

# Optional: pre-existing BE-20 report id (only needed for B5 + E1).
# If BE-20 is not yet shipped, B5 and E1 must be skipped.
EXISTING_REPORT_ID=...
```

The `BE-21_HANDOFF.md` orchestrator checklist must be applied
first (schema barrel + AppModule + npm deps). Validate by running:

```bash
pnpm --filter @radha/server build
```

A clean build proves the module is registered, the schema barrel
re-exports `reports`, and `exceljs`/`pdfkit` are installed.

---

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/reports/__tests__
```

**Expect**:

| Spec file | Cases |
|---|---|
| `format.utils.spec.ts` | 19 |
| `storage-keys.utils.spec.ts` | 13 |
| `csv-exporter.service.spec.ts` | 13 |
| `excel-exporter.service.spec.ts` | 11 |
| `pdf-exporter.service.spec.ts` | 11 |
| `export.service.spec.ts` | 11 |
| `report-download.service.spec.ts` | 10 |
| `report-storage.service.spec.ts` | 5 |
| `reports.dto.spec.ts` | 16 |
| `export-pipeline.integration.spec.ts` | 2 |
| **TOTAL** | **~111** |

**Pass criteria**: zero failures, no skipped tests, full module
coverage > 85%.

---

## Suite B — HTTP integration

### B1 — Ad-hoc export to all four formats

```bash
curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "B1 — All Formats Smoke Test",
    "tenantName": "Acme Foods",
    "formats": ["xlsx", "pdf", "csv", "json"],
    "rows": [
      { "ean": "8901030789885", "name": "Maggi", "status": "green" },
      { "ean": "8901030789892", "name": "Bru", "status": "yellow" }
    ],
    "summary": { "totalRows": 2, "yellowCount": 1, "greenCount": 1 }
  }' | jq
```

**Expect**:
- HTTP 201.
- `result.files.length === 4`.
- Each file has `format`, `s3Key`, `fileName`, `sizeBytes > 0`,
  `checksum` matching `^[0-9a-f]{64}$`, and `expiresAt` ~ 90 days
  from now.
- `result.totalSizeBytes` equals the sum of per-file sizes.
- `result.durationMs` < 2 000 for a 2-row dataset.

### B2 — List artefacts for the report

```bash
REPORT_ID=$(jq -r '.reportId' <<< "$B1_RESPONSE")
curl -s "$HOST/api/v1/reports/$REPORT_ID/files" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq 'length'
```

**Expect**: `4`.

### B3 — Presigned download URL by format

```bash
curl -s "$HOST/api/v1/reports/$REPORT_ID/download/csv?expirySeconds=300" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```

**Expect**:
```json
{ "url": "https://...s3...", "expiresAt": "...", "fileName": "...csv" }
```
- `url` starts with `https://`.
- `expiresAt` is ~ 5 minutes from now.

Then download the URL and verify content:

```bash
DOWNLOAD_URL=$(jq -r '.url' <<< "$B3_RESPONSE")
curl -s -o /tmp/be21-b3.csv "$DOWNLOAD_URL"
head /tmp/be21-b3.csv
```

**Expect**: BOM + `ean,name,status` + 2 data rows.

### B4 — Presigned download URL by file id

```bash
FILE_ID=$(curl -s "$HOST/api/v1/reports/$REPORT_ID/files" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  | jq -r '.[] | select(.format == "pdf") | .id')

curl -s "$HOST/api/v1/report-files/$FILE_ID/download" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```

**Expect**: same shape as B3, default 24 h TTL.

### B5 — Re-export an existing BE-20 report (skip if BE-20 not shipped)

```bash
curl -s -X POST "$HOST/api/v1/reports/$EXISTING_REPORT_ID/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "formats": ["xlsx"] }' | jq
```

**Expect**:
- If BE-20 + `REPORT_DATA_LOADER` provider registered: HTTP 201 +
  `result.files[0].format === "xlsx"`.
- Otherwise: HTTP 500 with body
  `"ReportDataLoader is not registered..."`. This is the
  expected pre-BE-20 behaviour and is documented.

### B6 — Empty data export still produces metadata-only artefacts

```bash
curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "B6 — Empty Data",
    "tenantName": "Acme Foods",
    "formats": ["pdf", "xlsx"],
    "rows": []
  }' | jq '.files[].sizeBytes'
```

**Expect**: Both `> 0` (header / metadata sheets always present).

### B7 — Unicode safety (Hindi + emoji)

```bash
curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "B7 — Unicode",
    "tenantName": "Acme",
    "formats": ["csv"],
    "rows": [{ "name": "दूध 🥛", "count": 2 }]
  }' | jq
```

**Expect**: HTTP 201. Then download the CSV and verify the body
contains `दूध 🥛`.

### B8 — Conditional formatting fires for status columns

```bash
curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "B8 — Status",
    "tenantName": "Acme",
    "formats": ["xlsx"],
    "rows": [
      { "ean": "1", "status": "red" },
      { "ean": "2", "status": "yellow" },
      { "ean": "3", "status": "green" }
    ]
  }'
```

Open the downloaded XLSX in Excel / LibreOffice / Numbers.

**Expect**: status column rendered with red / yellow / green
fills.

---

## Suite C — Tenant invariants

### C1 — Cross-tenant download by id is 404

```bash
# Create artefact in tenant A.
A_RESPONSE=$(curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "C1 — Tenant A artefact",
    "tenantName": "Tenant A",
    "formats": ["csv"],
    "rows": [{ "x": 1 }]
  }')
A_FILE_ID=$(jq -r '.files[0].id' <<< "$A_RESPONSE")

# Tenant B tries to fetch it.
curl -s -o /dev/null -w "%{http_code}\n" \
  "$HOST/api/v1/report-files/$A_FILE_ID/download" \
  -H "Authorization: Bearer $B_TOKEN"
```

**Expect**: `404` (DomainNotFoundException — file is not in tenant
B's scope).

### C2 — Cross-tenant download by (reportId, format) is 404

```bash
A_REPORT_ID=$(jq -r '.reportId' <<< "$A_RESPONSE")
curl -s -o /dev/null -w "%{http_code}\n" \
  "$HOST/api/v1/reports/$A_REPORT_ID/download/csv" \
  -H "Authorization: Bearer $B_TOKEN"
```

**Expect**: `404`.

### C3 — Cross-tenant file listing is empty

```bash
curl -s "$HOST/api/v1/reports/$A_REPORT_ID/files" \
  -H "Authorization: Bearer $B_TOKEN" | jq 'length'
```

**Expect**: `0`.

### C4 — S3 keys are tenant-scoped

```sql
SELECT file_key FROM report_files WHERE id = '<A_FILE_ID>';
```

**Expect**: starts with `tenants/<tenant-A-id>/reports/...`.

---

## Suite D — Security gates

### D1 — Staff cannot trigger ad-hoc export

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "title":"D1","tenantName":"A","formats":["csv"],"rows":[{"x":1}] }'
```

**Expect**: `403` — staff lacks the `manager+` role on
`POST /reports/export`.

### D2 — Anonymous request rejected

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$HOST/api/v1/reports/export" \
  -H "Content-Type: application/json" \
  -d '{ "title":"D2","tenantName":"A","formats":["csv"],"rows":[{"x":1}] }'
```

**Expect**: `401`.

### D3 — Formula injection neutralised in CSV

```bash
RESPONSE=$(curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "D3 — Injection",
    "tenantName": "Acme",
    "formats": ["csv"],
    "rows": [{ "evil": "=cmd|/c calc" }]
  }')

DOWNLOAD_URL=$(curl -s "$HOST/api/v1/report-files/$(jq -r '.files[0].id' <<< $RESPONSE)/download" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq -r '.url')
curl -s "$DOWNLOAD_URL"
```

**Expect**: row body is `'=cmd|/c calc` (apostrophe-prefixed) —
formula will not execute when opened in Excel/Sheets.

### D4 — TTL hard cap at 7 days

```bash
curl -s "$HOST/api/v1/report-files/$FILE_ID/download?expirySeconds=2592000" \
  -H "Authorization: Bearer $STAFF_TOKEN" -i
```

**Expect**: HTTP 400 with `code: "VALIDATION_ERROR"` —
`DownloadQuerySchema` rejects values above 604 800.

### D5 — TTL minimum at 60 seconds

```bash
curl -s "$HOST/api/v1/report-files/$FILE_ID/download?expirySeconds=10" \
  -H "Authorization: Bearer $STAFF_TOKEN" -i
```

**Expect**: HTTP 400 — `expirySeconds` must be ≥ 60.

### D6 — Expired file rejected

```sql
UPDATE report_files SET expires_at = now() - interval '1 day' WHERE id = '<FILE_ID>';
```

```bash
curl -s "$HOST/api/v1/report-files/$FILE_ID/download" \
  -H "Authorization: Bearer $STAFF_TOKEN" -i
```

**Expect**: HTTP 410 (`RESOURCE_GONE`) — `BusinessException`
"Report artefact has expired".

### D7 — Row count above 100 K rejected

```bash
python3 -c "import json; print(json.dumps({
  'title':'D7','tenantName':'A','formats':['csv'],
  'rows':[{'x':i} for i in range(100001)]
}))" | curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" --data @-
```

**Expect**: HTTP 400 with `code: "VALIDATION_ERROR"`.

### D8 — Audit trail recorded

```sql
SELECT action, resource_type, metadata->>'transition' AS transition,
       metadata->>'format' AS format
  FROM audit_logs
 WHERE resource_type IN ('Report', 'ReportFile')
 ORDER BY occurred_at DESC LIMIT 10;
```

**Expect**:
- `EXPORT, Report, generated, csv` (one per format generated).
- `READ, ReportFile, download-url, csv` (one per download URL
  issued).

---

## Suite E — Full lifecycle

End-to-end: ad-hoc export → list → download → checksum verify.

```bash
# 1. Create.
RESPONSE=$(curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"E1 — Full Lifecycle",
    "tenantName":"Acme",
    "formats":["xlsx","pdf","csv"],
    "rows":[{"ean":"1","name":"A"},{"ean":"2","name":"B"}],
    "summary":{"total":2}
  }')
REPORT_ID=$(jq -r '.reportId' <<< "$RESPONSE")
EXPECTED_CHECKSUMS=$(jq -r '.files[] | "\(.format) \(.checksum)"' <<< "$RESPONSE")

# 2. List.
curl -s "$HOST/api/v1/reports/$REPORT_ID/files" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq 'length'   # → 3

# 3. Download each format.
for FORMAT in xlsx pdf csv; do
  URL=$(curl -s "$HOST/api/v1/reports/$REPORT_ID/download/$FORMAT" \
    -H "Authorization: Bearer $STAFF_TOKEN" | jq -r '.url')
  curl -sL -o "/tmp/e1-$FORMAT" "$URL"
done

# 4. Verify checksums.
for FORMAT in xlsx pdf csv; do
  ACTUAL=$(sha256sum "/tmp/e1-$FORMAT" | cut -d' ' -f1)
  EXPECTED=$(echo "$EXPECTED_CHECKSUMS" | grep "^$FORMAT" | cut -d' ' -f2)
  if [ "$ACTUAL" = "$EXPECTED" ]; then
    echo "$FORMAT  OK  ($ACTUAL)"
  else
    echo "$FORMAT  MISMATCH  expected=$EXPECTED actual=$ACTUAL"
    exit 1
  fi
done
```

**Pass criteria**:
- Step 2 returns `3`.
- Step 3 downloads all three files without error.
- Step 4 prints `OK` for every format.

### E2 — Dedupe of repeated formats

```bash
curl -s -X POST "$HOST/api/v1/reports/export" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"E2 — Dedupe",
    "tenantName":"Acme",
    "formats":["csv","csv","csv"],
    "rows":[{"x":1}]
  }' | jq '.files | length'
```

**Expect**: `1` — duplicates collapsed at the orchestrator.

### E3 — Atomic download counter

```bash
FILE_ID=$(curl -s "$HOST/api/v1/reports/$REPORT_ID/files" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  | jq -r '.[0].id')

# Issue 5 concurrent download URLs.
for i in {1..5}; do
  curl -s "$HOST/api/v1/report-files/$FILE_ID/download" \
    -H "Authorization: Bearer $STAFF_TOKEN" > /dev/null &
done
wait

# Verify count is exactly 5 (atomic increment, no lost updates).
psql $DATABASE_URL -t -c \
  "SELECT (metadata->>'downloadCount')::int FROM report_files WHERE id = '$FILE_ID';"
```

**Expect**: `5`. (If lost-updates exist, you would see < 5.)

### E4 — JSON format is self-describing

```bash
URL=$(curl -s "$HOST/api/v1/reports/$REPORT_ID/download/json?expirySeconds=300" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq -r '.url')
curl -sL "$URL" | jq '.title'
```

**Expect**: `"E1 — Full Lifecycle"`.

---

## Sign-off

- [ ] Suite A — all 111 unit tests pass
- [ ] Suite B — every route returns the expected status + body
- [ ] Suite C — cross-tenant access is uniformly 404
- [ ] Suite D — security gates trigger as designed
- [ ] Suite E — full lifecycle round-trips with checksum match

**Reviewer Sign-off**:

```
☐ APPROVED — Proceed to BE-22.
☐ CHANGES REQUESTED.
```

---

## Honest Deferral Notes

The following items are intentionally **not** verified in this
pack — they belong to later phases:

- **Bull queue worker for very large XLSX exports** — BE-24's job.
- **Email delivery of generated reports** — BE-24's job.
- **Chart embedding in PDFs** — BE-31's job (Premium feature).
- **`POST /api/v1/reports/:id/export` against a real BE-20
  report** — only verifiable once BE-20 ships its
  `ReportDataLoader` provider.
- **S3 lifecycle deletion at 90 days** — infra concern (BE-49 IaC
  phase). Not a backend test.
- **Multipart streaming upload** — deferred with the queue worker.
- **Concurrent export load test (10 simultaneous)** — k6 / load
  test exists in `TESTING_AND_LAUNCH_PHASES.md` Suite F. Not
  part of the per-phase verification pack.

These are tracked in `BE-21_HANDOFF.md` § "Known Issues /
Follow-ups" with the phase that owns each item.
