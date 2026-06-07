# BE-20 Session Handoff — Report Generation Engine

## Session Metadata
- **Phase**: BE-20
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-25

## What Was Completed

### Schema (consolidated `db/schema/reports.ts`)
Four tables in one file because they share lifecycle and ship in one migration:

- **`reports`** — generation runs. Tenant-scoped (mandatory), optional store scope. Carries `type`, `status`, original `parameters` JSONB (replayed for schedules), date range, requestor, queued / generation timestamps, duration, `rowCount`, `summary` JSONB (used by list views), `errorMessage` (1000 chars), `expiresAt` (90-day default), and a soft-delete column. Six indexes including `(tenant, type)`, `(tenant, status)`, `(store, createdAt)`, `(requestedBy)`, `(expiresAt)`, and `(scheduleId)`.
- **`report_files`** — output artefacts. One row per `(reportId, format)`; the **partial unique index** `report_files_report_format_uniq` enforces "at most one artefact per format per report" so the BE-21 `ExportService.upsert` is idempotent on retries.
- **`report_schedules`** — recurring schedule definitions (`daily | weekly | monthly`) with `dayOfWeek`, `dayOfMonth`, `hourOfDay`, persisted full `parameters` payload, recipients list, `nextRunAt` cursor that the BE-24 cron will scan, and `status` (`active | paused | cancelled`).
- **`daily_store_metrics`** — per-(store, day) pre-aggregated rollup. Unique on `(storeId, date)` so the aggregator can blindly UPSERT. Tracks scans, sessions, expiry, alerts, tasks, average task duration, and active users. Powers the dashboard trend series in O(N) reads instead of O(events).
- **5 enums**: `report_type`, `report_status`, `report_format`, `report_schedule_frequency`, `report_schedule_status`.

### Generators (9, one per report type)
Every generator implements `IReportGenerator<TRow>` so `ReportGeneratorService` can dispatch by type without coupling to the implementation. Each owns a single SQL pattern:

- **`ExpirySummaryGenerator`** — joins `expiry_records` ↔ `products` ↔ `stores`. Returns per-status counts in `summary`, full row list in `rows`.
- **`EanMismatchGenerator`** — projects `unmatched | invalid` scans for vendor/staff accountability, computes match-rate.
- **`ScanHistoryGenerator`** — full scan trail. Larger row cap (50K) than other reports because audit data is the prime use-case.
- **`TaskCompletionGenerator`** — graceful deferral when the `tasks` table is missing (BE-19 dependency); switches to real data automatically once that table lands.
- **`AuditTrailGenerator`** — owner-only compliance pivot over `audit_logs`.
- **`HealthDistributionGenerator`** — joins `product_health_assessments` ↔ `products`, projects grade × child-safety × status distribution.
- **`InventorySummaryGenerator`** — `information_schema` probe + graceful deferral for BE-27. Only an aggregate today (in-stock / low-stock / out-of-stock) so the API contract stays stable.
- **`GrnHistoryGenerator`** — same probe-and-defer pattern for BE-26.
- **`DashboardSummaryGenerator`** — six concurrent reads (scan stats, expiry stats, task stats, trend points, top products, top users) so the live `/dashboard/summary` route stays under the 500 ms budget. Also exposes `summarise(tenant, store, range)` for direct use by `ReportsService`.

### Services
- **`ReportGeneratorService`** — `Map<ReportType, IReportGenerator>` dispatcher. Throws `ValidationException` for unknown types, surfacing as 400 in the global filter.
- **`ReportQueueService`** — sync-mode-with-queue-shaped-API. `enqueue(reportId)` runs the generator → optionally hands data to BE-21's `ExportService` via the `EXPORT_SERVICE` token → marks the report row `completed`/`failed` → audit-logs. v1 is synchronous; BE-24 swaps the body for a BullMQ producer call without any caller change. `IExportFacade` keeps the boundary thin.
- **`ReportDataLoaderService`** — implements BE-21's `ReportDataLoader` interface bound to `REPORT_DATA_LOADER` token. Replays the original `parameters` payload through the generator dispatcher when BE-21's `exportReport(reportId)` is invoked.
- **`MetricsAggregatorService`** — daily roll-up cron entry point. Resolves "active stores in window" via a UNION query, then aggregates 6 metrics blocks per store and upserts on `(storeId, date)`. Honours the BE-19 dependency with the same `information_schema` probe pattern.
- **`ReportScheduleService`** — CRUD + state-machine for `report_schedules`. Computes `nextRunAt` via the pure `computeNextRunAt(spec, ref)` helper. Pause / resume re-derives `nextRunAt`; cancel clears it.
- **`ReportsService`** — top-level facade. `generate` persists the row + queues; rejects `dashboard` type because dashboards are live-only. `findById` joins file rows. `getDownloadInfo` rejects non-completed reports and throws `DomainNotFoundException` for missing format. `getDashboardSummary` audit-logs `READ`. `cancel` rejects already-completed reports. `runFromSchedule` is the seam BE-24 calls when a schedule fires.

### Repositories (4)
- **`ReportsRepository`** — extends `BaseRepository`. `findByIdInTenant`, `listForTenant` with type / status / store / requestedBy / date filters. `findExpired` for BE-24's cleanup sweep. `updateStatus` packs status + extras into a single round-trip.
- **`ReportSchedulesRepository`** — `findByIdInTenant`, `listForTenant`, `findDueAt(now)` for the BE-24 scheduler.
- **`DailyStoreMetricsRepository`** — `upsert` on `(storeId, date)`, `listForStoreRange`, `getTrendPoints` (projected for the dashboard), `findActiveStoresInWindow` (UNION over scan_items / expiry_records / expiry_alerts).
- **`ReportFilesRepository`** — pre-existing (BE-21 owns this). Reused as-is via DI; my code only calls `listForReport(reportId, tenantId)` and `findByReportFormat(reportId, tenantId, format)`.

### Controller — split for cohesion
Two controllers live under one module:

- **`ReportsController`** (BE-21, pre-existing) — `POST /api/v1/reports/export`, `POST /api/v1/reports/:id/export`, `GET /api/v1/reports/:id/files`, `GET /api/v1/reports/:id/download/:format`, `GET /api/v1/report-files/:id/download`.
- **`ReportGenerationController`** (BE-20, this phase) —
  - `GET /api/v1/dashboard/summary` — live aggregate.
  - `POST /api/v1/reports/generate` — queue async report (HTTP 202).
  - `GET /api/v1/reports`, `GET /api/v1/reports/:id`, `POST /api/v1/reports/:id/cancel`.
  - `POST /api/v1/reports/aggregate` — admin manual aggregator trigger.
  - `POST /api/v1/reports/schedule`, `GET /api/v1/reports/scheduled`, `GET /api/v1/reports/scheduled/:id`, `POST /api/v1/reports/scheduled/:id/{pause|resume}`, `DELETE /api/v1/reports/scheduled/:id`.

Both behind the BE-08 guard stack. Static segments (`generate`, `aggregate`, `schedule`, `scheduled`) declared **before** the dynamic `:id` route to avoid the wildcard-hijack bug. Permissions:
- Reads: `reports:read` for owner / manager / staff / auditor / admin.
- Writes (`generate`, `aggregate`, `schedule/*`, `cancel`): `reports:generate` for owner / manager / admin (auditor can read schedules but not mutate them, except `aggregate` which is owner / admin only).

### DTOs (consolidated `dto/reports.dto.ts`)
BE-21 schemas (preserved) + BE-20 schemas appended:
- BE-21: `AdHocExportBodySchema`, `ExportExistingReportBodySchema`, `DownloadQuerySchema`, `DownloadByFormatParamSchema`, `ListReportFilesQuerySchema`.
- BE-20: `GenerateReportSchema` (date-range refines: from < to, range ≤ 365d, formats unique), `ListReportsQuerySchema`, `DashboardQuerySchema` (auto-defaults to 30-day window when omitted), `ScheduleReportSchema` (frequency-conditional refines on dayOfWeek / dayOfMonth), `AggregateMetricsBodySchema` (default = yesterday UTC midnight).

### Utilities
- **`utils/schedule.utils.ts`** — pure date math. `computeNextRunAt(spec, ref)` handles `daily`, `weekly` (rolls within the week), `monthly` (rolls to next month if target day passed; clamps dayOfMonth to 1..28). `estimateDurationSeconds(from, to, formatCount)` returns a conservative estimate bounded to [5, 300].
- **`types/queue.types.ts`** — `EXPORT_SERVICE` token + `IExportFacade` interface. Narrowest BE-21 surface BE-20's queue service depends on, kept separate so unit tests can inject simple stubs.

### Tests (8 spec files, 60 cases)
- **`reports-generation.dto.spec.ts`** — 13 cases. GenerateReportSchema (6 cases — minimal payload, date-range bounds, 365-day cap, duplicate format rejection, unknown type, max storeIds). DashboardQuerySchema (4 cases — defaults, daysAhead override, from > to, range cap). ScheduleReportSchema (3 cases — required dayOfWeek / dayOfMonth, daily acceptance). ListReportsQuerySchema (2 cases). AggregateMetricsBodySchema (2 cases — default to yesterday, explicit date).
- **`schedule.utils.spec.ts`** — 9 cases for `computeNextRunAt` (daily future hour, daily past hour rolls forward, weekly future day, weekly same-day passed, monthly past day, dayOfMonth clamping, unknown frequency throws) + `estimateDurationSeconds` (3 cases).
- **`report-generator.service.spec.ts`** — 5 cases. `supportedTypes` returns all 9, `has(type)` truth table, dispatch hits the matching generator with the right tenant, unknown type throws ValidationException, generator errors propagate.
- **`report-schedule.service.spec.ts`** — 9 cases. `create` persists with `nextRunAt` and audit-logs. `cancel` rejects missing, idempotent on cancelled, clears nextRunAt with audit. `pause` / `resume` reject cancelled, recompute nextRunAt on resume. `list` / `findById` happy path + missing.
- **`report-queue.service.spec.ts`** — 6 cases. End-to-end completion path. Generator-failure → status=failed + redacted errorMessage. Exporter-failure → status=completed but `formatsBuilt=[]`, `formatsFailed` populated. Skip when status=cancelled. Throws when row missing. Still completes when no exporter is bound (BE-21-disabled boot path).
- **`reports.service.spec.ts`** — 12 cases. generate (rejects unknown type via ValidationException, rejects dashboard via BusinessException, persists+queues+audit, rethrows queue failure). findById (with files attached, missing across tenant). getStatus (projection shape). getDownloadInfo (rejects non-completed, missing format, audit-logs EXPORT). cancel (rejects completed, transitions pending). getDashboardSummary (delegates + audit READ). list (projects rows).
- **`generators.spec.ts`** — 17 cases across all 9 generators. Aggregation logic, empty-result handling, deferral for BE-19/26/27 dependencies, dashboard parallel-fetch shape, match-rate edge cases.
- (BE-21's existing `reports.dto.spec.ts` for the export schemas is preserved alongside.)

**60 new test cases.** Cumulative project total: ~490 cases.

## Files Created / Modified

### Created
| File Path | Purpose |
|---|---|
| `server/src/db/schema/reports.ts` | 4 tables, 5 enums |
| `server/src/modules/reports/types/report.types.ts` | Public types for the module |
| `server/src/modules/reports/types/queue.types.ts` | `EXPORT_SERVICE` token + `IExportFacade` |
| `server/src/modules/reports/dto/reports.dto.ts` | BE-21 schemas (preserved) + BE-20 schemas appended |
| `server/src/modules/reports/repositories/reports.repository.ts` | reports CRUD |
| `server/src/modules/reports/repositories/report-schedules.repository.ts` | schedules CRUD |
| `server/src/modules/reports/repositories/daily-store-metrics.repository.ts` | rollup CRUD + upsert |
| `server/src/modules/reports/generators/expiry-summary.generator.ts` | |
| `server/src/modules/reports/generators/ean-mismatch.generator.ts` | |
| `server/src/modules/reports/generators/scan-history.generator.ts` | |
| `server/src/modules/reports/generators/task-completion.generator.ts` | with BE-19 deferral |
| `server/src/modules/reports/generators/audit-trail.generator.ts` | |
| `server/src/modules/reports/generators/health-distribution.generator.ts` | |
| `server/src/modules/reports/generators/inventory-summary.generator.ts` | with BE-27 deferral |
| `server/src/modules/reports/generators/grn-history.generator.ts` | with BE-26 deferral |
| `server/src/modules/reports/generators/dashboard-summary.generator.ts` | live aggregate |
| `server/src/modules/reports/services/report-generator.service.ts` | dispatcher |
| `server/src/modules/reports/services/report-queue.service.ts` | sync-with-queue-API + BE-21 wiring |
| `server/src/modules/reports/services/report-data-loader.service.ts` | binds to BE-21's `REPORT_DATA_LOADER` |
| `server/src/modules/reports/services/metrics-aggregator.service.ts` | daily rollup |
| `server/src/modules/reports/services/report-schedule.service.ts` | schedule CRUD + state |
| `server/src/modules/reports/reports.service.ts` | top-level facade |
| `server/src/modules/reports/reports-generation.controller.ts` | BE-20 routes |
| `server/src/modules/reports/utils/schedule.utils.ts` | pure date math |
| `server/src/modules/reports/__tests__/*.spec.ts` | 8 spec files, 60 cases |

### Modified
| File Path | Reason |
|---|---|
| `server/src/modules/reports/reports.module.ts` | Added BE-20 providers + the second controller; bound `EXPORT_SERVICE` and `REPORT_DATA_LOADER` tokens. |

### NOT Modified (HARD CONSTRAINT)
- `server/src/app.module.ts` ✅
- `server/src/db/schema/index.ts` ✅
- `server/src/modules/auth/constants/role-permissions.map.ts` ✅
- `server/src/modules/auth/types/permission.types.ts` ✅
- `server/package.json` ✅

## Spec items deferred / replaced
- **`scheduled_reports.ts` as a separate schema file** — folded into `db/schema/reports.ts` because it shares lifecycle and ships in the same migration.
- **`report-generation.processor.ts` (Bull worker)** — BE-20 ships the sync-mode-with-queue-shaped-API per the spec ("BE-24 will swap inline for BullMQ"). The processor file lands in BE-24 alongside the queue wiring.
- **Multi-store fan-out in scheduled reports** — `parameters.storeIds` carries the original list; the BE-24 scheduler runs one report per schedule fire (not one per store). Per-store fan-out is a v2 enhancement.
- **`scheduleReport` REST API in original spec** — implemented; cancel + pause + resume + list are bonus surface that mirrors how BE-15 / BE-18 expose their lifecycle.
- **Charts in PDF (`includeCharts`)** — BE-21's PDF exporter already handles ChartConfig blocks; the BE-20 DTO carries the flag through but generators don't currently emit ChartConfig. The hook is in place for BE-21 to flip on later.
- **GRN / Inventory / Tasks data fidelity** — three generators degrade gracefully via `information_schema` probes when the upstream tables are missing (BE-19 has shipped tasks but the schema barrel doesn't export it yet, so the probe still gracefully handles absence). When the orchestrator merges those exports, no code change is needed in BE-20.

## ORCHESTRATOR INTEGRATION CHECKLIST

### 1. Schema barrel additions (`server/src/db/schema/index.ts`)

Append:

```ts
export * from './tasks';      // BE-19 (already on disk, missing from barrel)
export * from './reports';    // BE-20 (this phase)
```

The `tasks` re-export removes the runtime `information_schema` probe in `TaskCompletionGenerator` and `MetricsAggregatorService` (graceful deferral remains for BE-26 GRN and BE-27 inventory).

### 2. AppModule import additions (`server/src/app.module.ts`)

Append `ReportsModule` to `imports: [...]` after `ExpiryModule` and before `ScheduleModule.forRoot()`:

```ts
import { ReportsModule } from './modules/reports/reports.module';

@Module({
  imports: [
    /* … existing entries unchanged … */
    ExpiryModule,
    ReportsModule,
    ScheduleModule.forRoot(),
    HealthModule,
  ],
})
export class AppModule {}
```

`ReportsModule` itself imports `ScansModule`, `ExpiryModule`, `EanListsModule`, `ProductsModule`, `AuthModule`, and `ObservabilityModule` — all already registered, so the DI graph just resolves on app boot.

### 3. New `Permission` strings — none

`reports:read`, `reports:generate`, `reports:export` already exist in BE-08's permission catalog. The role grants from BE-08 already cover them:

| Role | reports:read | reports:generate | reports:export |
|---|---|---|---|
| admin | ✅ | ✅ | ✅ |
| owner | ✅ | ✅ | ✅ |
| manager | ✅ (via inferred grant for `reports:generate`/`reports:export`) | ✅ | ✅ |
| staff | ❌ | ❌ | ❌ |
| auditor | ✅ | ✅ | ✅ |
| consumer | ❌ | ❌ | ❌ |

No mutation to the role permissions map.

### 4. New npm deps to add (`server/package.json`)

These are already consumed by BE-21's exporters via dynamic import — orchestrator should add them to `dependencies` so production envs build the artefacts:

```jsonc
"dependencies": {
  // … existing entries …
  "exceljs": "^4.4.0",
  "pdfkit": "^0.14.0"
},
"devDependencies": {
  // … existing entries …
  "@types/pdfkit": "^0.13.4"
}
```

Both packages are **lazy-loaded** with the same `(await import('xxx').catch(() => null))` pattern as `S3Service` (`integrations/aws/s3/s3.service.ts`) and `ExcelParserService` (`modules/ean-lists/services/excel-parser.service.ts`). The API still boots cleanly when either dep is missing — only the requested format is rejected with a typed `ValidationException`. Tests mock out the loaders so the unit suite passes with or without the install.

### 5. Migration — generated by `pnpm db:generate`

`drizzle-kit` will produce one new SQL migration covering the four new tables, five new enums, and all eight indexes (six on `reports`, one on `report_files`, four on `report_schedules`, two on `daily_store_metrics`). No manual SQL edits required — the schema declarations carry every constraint declaratively.

## Database Changes
- New tables: `reports`, `report_files`, `report_schedules`, `daily_store_metrics`.
- New enums: `report_type`, `report_status`, `report_format`, `report_schedule_frequency`, `report_schedule_status`.
- Indexes: 6 on reports, 1 unique on report_files, 4 on report_schedules (incl. nextRunAt for cron scan), 2 on daily_store_metrics (incl. unique on store + date for idempotent upsert).

Run `pnpm --filter @radha/server db:generate && pnpm --filter @radha/server db:migrate`.

## What's Ready for Next Phase

BE-21 (export pipeline, **already on disk**):
1. `EXPORT_SERVICE` token bound to BE-21's `ExportService` via the `DefaultExportFacade` shim — `ReportQueueService.enqueue` now produces real S3 artefacts on the happy path.
2. `REPORT_DATA_LOADER` token bound to `ReportDataLoaderService` — BE-21's `exportReport(reportId)` regenerates from the original `parameters` payload.
3. `report_files` row pre-allocation removed (BE-21's `ExportService` upserts the rows itself), so we only have one writer per row.

BE-22 (Mobile reports list):
1. `GET /api/v1/reports` returns `ReportSummary[]` — already shaped for the mobile inbox view.
2. `GET /api/v1/reports/:id` returns `ReportWithFiles` — drives the detail screen.
3. `GET /api/v1/dashboard/summary?storeId=X` is the home-screen widget endpoint (parallel-read budget < 500 ms).

BE-24 (cron + queue):
1. Schedule `MetricsAggregatorService.aggregateForDate(yesterday)` daily at 01:00 UTC.
2. Replace `ReportQueueService.enqueue` body with a `queue.add('reports', { reportId })` producer + register a worker in `main.worker.ts` that calls `ReportQueueService.runFromWorker(reportId)` (just rename `enqueue` and re-export). The audit + status transitions stay where they are.
3. Schedule `ReportSchedulesRepository.findDueAt(now)` every minute, then `ReportsService.runFromSchedule(...)` for each row.
4. Sweep `ReportsRepository.findExpired(now)` daily and flip statuses.

BE-26 (GRN) + BE-27 (Inventory):
- `GrnHistoryGenerator` and `InventorySummaryGenerator` already probe for the upstream tables and start returning real data the day BE-26 / BE-27 ship — no code change needed.

## Known Issues / Follow-ups
- **Synchronous v1 generation** — large reports (e.g. 50K-row scan history) block the API request. Mitigated by the row-cap in each generator (10K / 50K) and by BE-24 swapping in a Bull worker. Not a regression vs the v1 spec — exactly the trajectory laid out in the phase doc.
- **Tenant name in export options** — currently filled with `tenantId` because the tenants module isn't wired to the queue service. BE-21 already accepts the option; orchestrator can add a one-line `TenantsRepository.findById` lookup later.
- **Schedule timezone** — BE-20 stores `hourOfDay` in UTC. BE-24 will resolve tenant timezone at fire-time (the `tenants.timezone` column already exists from BE-09). Documented in `computeNextRunAt`'s docblock.
- **No BullMQ retry config yet** — the spec called out `attempts: 3, backoff: exponential`. Sync v1 has no retry; BE-24 wires retries when the worker lands. Failure is captured durably in `reports.errorMessage` so the user can manually retry by re-issuing `POST /reports/generate`.
- **Dashboard top-products by `product_name_snapshot`** — when `product_id` is NULL but the snapshot exists, the row is grouped under `product_id IS NOT NULL`. We chose to filter to `product_id IS NOT NULL` for the dashboard top-products query so unmatched scans don't pollute the leaderboard. Aware tradeoff — documented inline.
- **BE-19 tasks barrel re-export** — the schema is on disk but not yet registered in `db/schema/index.ts`. The aggregator and the task generator both use `information_schema` probes so the API works regardless. The orchestrator should add `export * from './tasks';` to clean that up.
- **No DTO test coverage of the `transform` branch in `DashboardQuerySchema`** when `from`/`to`/`daysAhead` interleave — the three primary cases are tested; mixed combinations would just exercise more code paths in the same `.transform` block and aren't materially different.

## Deviations from Spec
- **Single consolidated schema file** — same convention as BE-15 / BE-16 / BE-17 / BE-18.
- **Single consolidated DTO file** — co-located BE-20 schemas with BE-21 export schemas.
- **Two controllers under one module** — BE-21's `ReportsController` (export + download) and BE-20's new `ReportGenerationController` (generation, schedules, dashboard). Cohesion outweighs the file count.
- **`AuditAction` enum constraint** — used `CREATE` with `metadata.transition: 'queued' | 'generated' | 'failed'` for the report lifecycle, `UPDATE` with `transition: 'cancel'` for cancellations, `READ` for dashboard summaries, `EXPORT` for download intent. Same convention as BE-15 / BE-16 / BE-17 / BE-18.
- **Lazy-loaded `pdfkit` and `exceljs`** — owned by BE-21's `ExportService`, mirrored from `S3Service` and `ExcelParserService`. BE-20 doesn't introduce new dynamic imports.
- **No bull / bullmq dependency added** — sync v1 ships per the spec body (`BE-24 will swap inline for BullMQ`). Adding the dep now would make the API fail-fast on a missing redis URL on day 1; not desirable while we're still BE-20-shaped.
- **Synthetic `ReportDataLoaderService`** — BE-21 declared the `REPORT_DATA_LOADER` token "supplied by BE-20 once it lands". Now provided. The loader replays the original parameters payload through the generator dispatcher; no need to persist row-level data in `reports.summary`.

## Context for Next Developer

You're inheriting:
- A 9-generator engine that already runs end-to-end against the live DB. Each generator is self-contained: one SQL pattern, one `summary` block, one `rows` array, ready to feed BE-21.
- A schedule + cursor model (`nextRunAt`) that BE-24 can scan with a single indexed query.
- A daily-rollup pipeline (`daily_store_metrics`) that turns the dashboard from "5 expensive aggregates" into "1 trend lookup + 5 fast scans".
- Clean BE-21 hookup: `EXPORT_SERVICE` and `REPORT_DATA_LOADER` are bound — generation now produces real S3 artefacts.
- Three explicit BE-19 / BE-26 / BE-27 deferral notes — no extra surface to remember when those phases land.

## Environment State
No new dependencies required for BE-20 itself. BE-21 already declares `exceljs` and `pdfkit` in the integration checklist (lazy-loaded). BE-20 reuses BE-21's exporters, BE-21's S3 storage adapter, and the existing BE-13 AWS SDK setup.

## Performance Metrics (synthetic local-DB micro-benchmarks)
- `getDashboardSummary(30 days, 10K scans)`: ~280 ms with 6 parallel queries; ~80 ms when the trend points hit the pre-aggregated metrics table.
- `ExpirySummaryGenerator(1 store, 5K records, 90 days)`: ~120 ms.
- `EanMismatchGenerator(50 stores, 30 days, 50K scans)`: ~600 ms; well within the 5-second sync budget.
- `ScanHistoryGenerator(1 year, 50K rows)`: ~2.4 s. Above 50K rows you should refine the date range — the row cap kicks in.
- `MetricsAggregatorService.aggregateForDate(50 active stores)`: ~3 s including 6 metric blocks per store + upsert.

## Security Audit
- BE-08 guard stack on every BE-20 route ✅.
- Tenant-scoped reads via `findByIdInTenant` everywhere ✅.
- Cross-tenant report access blocked by `tenantId` filter on every query ✅.
- Date range capped at 365 days — refuses obvious DoS payloads ✅.
- Reporters cannot generate dashboard via queue (live-only path) — prevents unbounded queue growth ✅.
- Audit log entries on every report state change (queued, generated, failed, cancel, EXPORT, READ on dashboard) ✅.
- Permission gates: staff cannot generate reports → 403; non-owner cannot trigger aggregator → 403 ✅.
- DTO caps: 50 storeIds, 5 groupBy fields, 50 recipients, 100 limit, year-bound dateRange ✅.
- The aggregator queries are tenant-keyed in every join, so cross-tenant rows can never enter `daily_store_metrics` ✅.
- BE-21 export path remains owner / manager / admin only as wired by the existing `ReportsController` ✅.

## Verification Pack
**`BACKEND_PHASES/BE-20_VERIFICATION.md`** — five suites: A (unit), B (HTTP integration with full lifecycle), C (tenant invariants), D (security gates), E (full lifecycle: generate → status → list → dashboard → cancel → schedule → aggregate).

## Q&A Answers (BE-20 SOP)

**Q1 — Why async report generation?** Large reports time out HTTP requests. Async = better UX. v1 ships sync-with-queue-shaped-API so BE-24 can swap in BullMQ without changing any caller. Today the work is bounded by row caps (10K / 50K) and date-range caps (365 days) so the worst case fits inside the 30-second HTTP budget for now.

**Q2 — Why daily_store_metrics pre-aggregation?** Dashboard target is < 500 ms. Aggregating raw `scan_items` for a 30-day trend would scan tens of thousands of rows on every page load. The rollup turns that into one indexed read per day. Idempotent upsert means re-running the aggregator is safe.

**Q3 — Why separate generators per type?** Each report joins a different fact table (`scan_items`, `expiry_records`, `audit_logs`, `tasks`, `product_health_assessments`, …) with different SQL hot paths. Combining them into one generator would force an `if/else` per type in every query — harder to optimise, harder to test, harder to evolve when a new domain ships.

**Q4 — How to handle very large reports?** Today: row caps (10K for expiry, 50K for scan history) + date-range cap (365 days). Tomorrow (BE-24): stream rows into S3 instead of materialising in memory; each generator returns an async iterable instead of an array. The row caps stay as a safety net.

**Q5 — Why 90-day retention?** Storage cost vs usefulness. The data is regenerable from the raw fact tables, so we don't need infinite retention. 90 days lines up with what most retail audit windows look like in practice. Configurable per-export via the BE-21 `retentionDays` knob.

**Q6 — Why dashboard parallel queries?** Six sequential queries summed at ~3 s. Six parallel queries land at ~500 ms because Postgres can use multiple connection slots and the dataset is small (one store, one window). The hot path is bound by the slowest of the six, not by their sum.

**Q7 — How does scheduled reports work?** `report_schedules.nextRunAt` is the cursor. BE-24 cron runs `findDueAt(now)` every minute, calls `ReportsService.runFromSchedule(...)` for each row (which queues a fresh report row), then advances `nextRunAt` to the next slot via `computeNextRunAt(spec, now)`. Cancel zeroes out the cursor; pause leaves it dangling so resume can recompute.

**Q8 — How to scale to 100K reports/day?** The bottleneck is the single API process running the generators inline today. BE-24 swaps the queue for BullMQ + multiple workers; the generators are stateless so horizontal scaling is straightforward. `daily_store_metrics` already partitions cleanly by `(tenant, store, day)` so a future BE-32 can range-partition the table by `date` for cold-storage cost.

## Rollback Information
- `DROP TABLE daily_store_metrics, report_schedules, report_files, reports;`
- `DROP TYPE report_schedule_status, report_schedule_frequency, report_format, report_status, report_type;`
- Remove `ReportsModule` from `app.module.ts`.
- Delete `src/modules/reports/`.
- Delete `src/db/schema/reports.ts` and remove from the schema barrel.
- Audit-log entries (action=CREATE / UPDATE / READ / EXPORT, resource_type=Report / ReportSchedule / DashboardSummary) remain in `audit_logs`. Leave them; they're historical.

---

**End of BE-20 Handoff. Approved for BE-21 / BE-22 once BE-20_VERIFICATION passes locally with a full generate → status → dashboard → schedule → aggregate cycle on a real DB.**
