# BE-20 Verification Pack — Report Generation Engine

> Run after `pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (tenant invariants), D (security gates), E (full lifecycle: generate → status → dashboard → cancel → schedule → aggregate).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...        # tenant owner
MANAGER_TOKEN=...      # tenant manager
STAFF_TOKEN=...        # tenant staff
AUDITOR_TOKEN=...      # tenant auditor
B_TOKEN=...            # tenant B
STORE_ID=...           # store under tenant A
B_STORE_ID=...         # store under tenant B
USER_ID=...            # owner's id (for filter checks)
```

Confirm the schema migration ran:

```bash
$PSQL -c "\d reports"
$PSQL -c "\d report_files"
$PSQL -c "\d report_schedules"
$PSQL -c "\d daily_store_metrics"
```

Each of the four tables must exist with the indexes listed in the handoff.

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/reports/__tests__
```

**Expect**:
- `reports-generation.dto.spec.ts` — 13 cases.
- `reports.dto.spec.ts` (BE-21 schemas) — 12 cases.
- `schedule.utils.spec.ts` — 9 cases.
- `report-generator.service.spec.ts` — 5 cases.
- `report-schedule.service.spec.ts` — 9 cases.
- `report-queue.service.spec.ts` — 6 cases.
- `reports.service.spec.ts` — 12 cases.
- `generators.spec.ts` — 17 cases.

**Total**: 60 BE-20 cases (plus the existing BE-21 spec files which should also stay green).

## Suite B — HTTP integration

### B1 — Generate report (queued → completed)

```bash
curl -s -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\":\"expiry-summary\",
    \"formats\":[\"json\",\"csv\"],
    \"storeIds\":[\"$STORE_ID\"],
    \"dateRange\":{\"from\":\"2026-01-01T00:00:00Z\",\"to\":\"2026-04-30T00:00:00Z\"}
  }" | jq
```
**Expect**: HTTP 202, `{ reportId, status: "completed" | "failed", estimatedDurationSeconds, formats }`.

```bash
REPORT_ID=...   # from response

curl -s "$HOST/api/v1/reports/$REPORT_ID" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq
```
**Expect**: `status: "completed"`, `summary.total`, `summary.green/yellow/red/expired`, `files: [{format:'json',...}, {format:'csv',...}]` (BE-21 export ran successfully).

### B2 — List reports

```bash
curl -s "$HOST/api/v1/reports?status=completed&limit=10" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq
```
**Expect**: array of `ReportSummary` rows, newest first.

### B3 — Dashboard summary (live)

```bash
curl -s "$HOST/api/v1/dashboard/summary?storeId=$STORE_ID&daysAhead=30" \
  -H "Authorization: Bearer $STAFF_TOKEN" | jq
```
**Expect**: `{ storeId, dateRange, totals, expiry, scanHealth, trends, topProducts, topUsers, generatedAt }`. Wall-clock under 500 ms on a populated DB.

### B4 — Generate every report type

For each of `expiry-summary`, `ean-mismatch`, `scan-history`, `task-completion`, `inventory-summary`, `grn-history`, `health-distribution`, `audit-trail`:

```bash
curl -s -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\":\"<TYPE>\",
    \"formats\":[\"json\"],
    \"dateRange\":{\"from\":\"2026-01-01T00:00:00Z\",\"to\":\"2026-04-30T00:00:00Z\"}
  }" | jq
```
**Expect**: every type returns a reportId; `status` settles to `completed`. For `inventory-summary` / `grn-history` while the upstream tables are absent, `summary.notes` says "BE-26 dependency" / "BE-27 dependency" and `meta.deferred` is set. `task-completion` returns real data once BE-19's tasks barrel re-export lands; otherwise its summary carries `notes: "BE-19 dependency"`.

`dashboard` should be **rejected** when generated through this endpoint:

```bash
curl -i -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\":\"dashboard\",
    \"formats\":[\"json\"],
    \"dateRange\":{\"from\":\"2026-01-01T00:00:00Z\",\"to\":\"2026-04-30T00:00:00Z\"}
  }"
```
**Expect**: HTTP 422 with `BUSINESS_RULE_VIOLATION` and message about the live `/dashboard/summary` endpoint.

### B5 — Date range validation

Invalid range (to before from):
```bash
curl -i -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","formats":["csv"],"dateRange":{"from":"2026-04-01T00:00:00Z","to":"2026-01-01T00:00:00Z"}}'
```
**Expect**: HTTP 400 with `VALIDATION_ERROR`, `details[0].field == "dateRange.to"`.

Range > 365 days:
```bash
curl -i -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","formats":["csv"],"dateRange":{"from":"2024-01-01T00:00:00Z","to":"2026-01-01T00:00:00Z"}}'
```
**Expect**: HTTP 400 with the 365-day message.

### B6 — Schedule a recurring report

```bash
curl -s -X POST "$HOST/api/v1/reports/schedule" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\":\"expiry-summary\",
    \"title\":\"Weekly expiry digest\",
    \"frequency\":\"weekly\",
    \"dayOfWeek\":1,
    \"hourOfDay\":8,
    \"parameters\":{
      \"type\":\"expiry-summary\",
      \"formats\":[\"xlsx\"],
      \"storeIds\":[\"$STORE_ID\"],
      \"dateRange\":{\"from\":\"2026-01-01T00:00:00Z\",\"to\":\"2026-12-31T00:00:00Z\"}
    }
  }" | jq
```
**Expect**: HTTP 201, `{ id, frequency:"weekly", nextRunAt:"…Monday 08:00…", status:"active" }`.

```bash
SCHED_ID=...

curl -s "$HOST/api/v1/reports/scheduled" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq
```
**Expect**: array including the new schedule.

```bash
curl -s -X POST "$HOST/api/v1/reports/scheduled/$SCHED_ID/pause" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.status'
# "paused"

curl -s -X POST "$HOST/api/v1/reports/scheduled/$SCHED_ID/resume" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.status'
# "active"

curl -i -X DELETE "$HOST/api/v1/reports/scheduled/$SCHED_ID" \
  -H "Authorization: Bearer $OWNER_TOKEN"
# HTTP 200, status="cancelled", nextRunAt=null
```

### B7 — Manual aggregation

```bash
curl -s -X POST "$HOST/api/v1/reports/aggregate" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"date\":\"$(date -u -d '-1 day' +%Y-%m-%dT00:00:00Z)\"}" | jq
```
**Expect**: `{ date, storesProcessed, rowsUpserted }`. Verify the rollup row landed:

```sql
SELECT store_id, total_scans, expiry_records_added, sessions_completed
FROM daily_store_metrics
WHERE date = (current_date - 1)::timestamptz;
```

### B8 — Cancel a pending report

```bash
RID=$(curl -s -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\":\"scan-history\",\"formats\":[\"json\"],\"dateRange\":{\"from\":\"2026-04-01T00:00:00Z\",\"to\":\"2026-04-30T00:00:00Z\"}}" \
  | jq -r '.reportId')

# In sync v1 the row is already completed by the time the response returns,
# so cancel must be exercised when running under BE-24's queue worker. The
# corresponding business-rule guard is asserted at the unit-test layer
# (`reports.service.spec.ts ▸ rejects cancelling a completed report`).
curl -i -X POST "$HOST/api/v1/reports/$RID/cancel" \
  -H "Authorization: Bearer $MANAGER_TOKEN"
```
**Expect**: HTTP 422 with `BUSINESS_RULE_VIOLATION` if the row is already `completed`.

## Suite C — Tenant invariants

### C1 — Cross-tenant report read blocked

```bash
A_REPORT_ID=...   # generated under tenant A

curl -i "$HOST/api/v1/reports/$A_REPORT_ID" \
  -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 404.

### C2 — Cross-tenant dashboard blocked

```bash
curl -i "$HOST/api/v1/dashboard/summary?storeId=$STORE_ID" \
  -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 403 (TenantScopeGuard rejects accessing a store outside the JWT's tenant).

### C3 — Schedule isolation

Tenant A creates a schedule. Tenant B's `GET /api/v1/reports/scheduled` must not return it:

```bash
curl -s "$HOST/api/v1/reports/scheduled" -H "Authorization: Bearer $B_TOKEN" \
  | jq '.[] | select(.id == "<A_SCHED_ID>")'
# (empty)
```

### C4 — Aggregator tenant scoping

The aggregator query in `MetricsAggregatorService.collectForStore` always pins
`tenant_id = ${tenantId}`. Verify:

```sql
SELECT DISTINCT tenant_id FROM daily_store_metrics WHERE store_id = '<STORE_A>';
-- exactly one row, the tenant A id
```

## Suite D — Security gates

### D1 — Staff cannot generate reports

```bash
curl -i -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","formats":["csv"],"dateRange":{"from":"2026-04-01T00:00:00Z","to":"2026-04-30T00:00:00Z"}}'
```
**Expect**: HTTP 403 (`reports:generate` missing).

### D2 — Staff cannot list reports

```bash
curl -i "$HOST/api/v1/reports" -H "Authorization: Bearer $STAFF_TOKEN"
```
**Expect**: HTTP 403 (`reports:read` not in staff role grant).

### D3 — Auditor can read but cannot mutate schedules

```bash
curl -i "$HOST/api/v1/reports/scheduled" -H "Authorization: Bearer $AUDITOR_TOKEN"
# HTTP 200

curl -i -X POST "$HOST/api/v1/reports/schedule" \
  -H "Authorization: Bearer $AUDITOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","title":"x","frequency":"daily","hourOfDay":2,"parameters":{"type":"scan-history","formats":["csv"],"dateRange":{"from":"2026-04-01T00:00:00Z","to":"2026-04-30T00:00:00Z"}}}'
# HTTP 403
```

### D4 — Only owner / admin can trigger aggregator

```bash
curl -i -X POST "$HOST/api/v1/reports/aggregate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" -d '{}'
```
**Expect**: HTTP 403 (manager has `reports:generate` but the route restricts roles to `owner` / `admin`).

### D5 — Duplicate format rejection

```bash
curl -i -X POST "$HOST/api/v1/reports/generate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","formats":["csv","csv"],"dateRange":{"from":"2026-04-01T00:00:00Z","to":"2026-04-30T00:00:00Z"}}'
```
**Expect**: HTTP 400 (`formats must be unique`).

### D6 — Schedule frequency / day-field invariant

```bash
curl -i -X POST "$HOST/api/v1/reports/schedule" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"scan-history","title":"x","frequency":"weekly","hourOfDay":2,"parameters":{"type":"scan-history","formats":["csv"],"dateRange":{"from":"2026-04-01T00:00:00Z","to":"2026-04-30T00:00:00Z"}}}'
```
**Expect**: HTTP 400 (`dayOfWeek is required for weekly schedules`).

### D7 — Audit log entries

```sql
SELECT action, resource_type, success, metadata->>'transition' AS transition
FROM audit_logs
WHERE resource_type IN ('Report','ReportSchedule','DashboardSummary')
ORDER BY occurred_at DESC
LIMIT 20;
```
**Expect**: a mix of `CREATE / Report / queued`, `CREATE / Report / generated`, `READ / DashboardSummary`, `EXPORT / Report` (after BE-21 download), `UPDATE / ReportSchedule / cancel|pause|resume`.

## Suite E — Full lifecycle

### E1 — Generate → status → list → cancel

1. POST `/reports/generate` (B1) → snapshot reportId.
2. GET `/reports/$REPORT_ID` → status `completed`, file rows attached.
3. GET `/reports?storeId=$STORE_ID` → entry visible at the top.
4. POST `/reports/$REPORT_ID/cancel` → 422 (already completed).

### E2 — Schedule → fire (manual) → audit

1. Create schedule (B6) with `frequency:'daily'`, `hourOfDay` set to a near-future minute.
2. Manually call `ReportsService.runFromSchedule` via a one-off script (BE-24 will own the cron):
   ```ts
   await reportsService.runFromSchedule(tenantId, ownerUserId, scheduleId, schedule.parameters);
   ```
3. New report row appears with `scheduleId` populated.
4. Audit row: `action=CREATE, resource_type=Report, metadata.transition='queued', metadata.scheduleId=<id>`.

### E3 — Aggregator → dashboard speedup

1. Run B7 for yesterday → rows materialised.
2. GET `/dashboard/summary?storeId=$STORE_ID&daysAhead=14` → `trends` array populated from `daily_store_metrics` (no fact-table scan needed).
3. Re-run B7 for the same date → response is `rowsUpserted=N` (the same `N`); idempotent.

### E4 — Cleanup behaviour

```sql
-- Report past expires_at
UPDATE reports SET expires_at = now() - interval '1 day' WHERE id = '<R>';

-- BE-24 will sweep these via ReportsRepository.findExpired(now). Call manually:
SELECT id, status FROM reports WHERE id = '<R>';
-- still completed in BE-20 — BE-24 flips to expired. Documented.
```

## Final sign-off

- [ ] Suite A: 60 BE-20 unit cases pass (existing BE-21 spec files still green)
- [ ] Suite B: 8 HTTP integration scenarios pass on a real DB
- [ ] Suite C: 4 tenant invariants verified via psql + cross-tenant tokens
- [ ] Suite D: 7 security gates fire correctly
- [ ] Suite E: 4 lifecycle scenarios end-to-end with audit trail intact

**Verified by**: ___________________________
**Date**: ___________________________
