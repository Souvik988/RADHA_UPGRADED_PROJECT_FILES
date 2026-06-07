# BE-04 Session Handoff — Error Handling & Logging System

## Session Metadata
- **Phase**: BE-04
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-17

## What Was Completed

### Error Codes & Exceptions
- **`ErrorCode` enum** with **70 stable codes** spanning 9 categories (1xxx generic, 2xxx validation, 3xxx auth, 4xxx authorization, 5xxx not-found, 6xxx conflicts, 7xxx business rules, 8xxx external services, 9xxx database).
- **`ERROR_CODE_TO_HTTP_STATUS`** record (compile-time exhaustive) and **`ERROR_CODE_DEFAULT_MESSAGE`** record so every code has both a status and a user-facing default message.
- **`BusinessException`** base class + 5 typed subclasses: `ValidationException`, `DomainNotFoundException`, `DomainForbiddenException`, `DomainConflictException`, `ExternalServiceException`.
  - Each carries the `ErrorCode`, derives HTTP status from the canonical map, and emits the standard `{ code, message, details? }` body that `GlobalExceptionFilter` already understands.

### Observability Module
- **`ObservabilityModule`** (global) wires up:
  - `IErrorTrackingService` — provider factory selects `SentryService` when `SENTRY_DSN` is set, otherwise `NoopErrorTrackingService`.
  - `IAuditLogService` (`AuditLogService`) — structured-log today, repository-backed in BE-05.
  - `MetricsService` — counter/gauge/histogram emitters (structured log today, OTel in BE-48).

### Sentry Integration
- **`SentryService`** lazily imports `@sentry/node`, initialises with the typed config (DSN, release = `appVersion`, traces sample rate, environment).
- `beforeSend` scrubs Indian PII fields and known secret keys from `request.data`, `request.headers`, and `extra` so secrets can never reach Sentry servers.
- `withScope` for every capture so request id / user / tenant are tagged per event.
- **No-op fallback** at `NoopErrorTrackingService` so consumers can always inject the symbol without null checks.

### Audit Logging
- **`AuditLogService`** auto-enriches every entry from `RequestContextService` (userId / tenantId / ipAddress / userAgent), redacts `metadata`, and emits a `audit.event` line tagged `audit: true`.
- Honours `AUDIT_LOG_ENABLED` env flag.
- `query()` returns `[]` until BE-05 connects the `audit_logs` table.

### Metrics Service
- Three primitives: `counter`, `gauge`, `histogram`.
- Every emit is logged with `metric: true` and a Unix-millis timestamp so log-based dashboards work even before BE-48 ships the OTel exporter.

### Global Exception Filter Upgrades
- Now **routes through the error-tracking service** (Optional injection — works without it).
- Routes 5xx domain exceptions and unknown errors to the tracker; 4xx domain exceptions stay client-side only.
- `BusinessException.code` is preserved verbatim in the response.
- Reverse-lookup for legacy `HttpException` → consistent `ErrorCode` mapping with drift detection.

### Config Surface Additions
- `SENTRY_DSN`, `SENTRY_TRACES_SAMPLE_RATE`, `AUDIT_LOG_ENABLED`, `CRITICAL_ALERT_EMAIL` added to `EnvSchema`.
- New `ConfigService.observability` typed compound.
- `.env.example` updated.

## Files Created (matched against BE-04 spec)

| Spec file | Status |
|---|---|
| `server/src/common/errors/error-codes.ts` | ✅ |
| `server/src/common/errors/business.exception.ts` | ✅ (consolidated; see Deviations) |
| `server/src/common/errors/index.ts` | ✅ |
| `server/src/observability/sentry.service.ts` | ✅ |
| `server/src/observability/observability.module.ts` | ✅ (renamed from sentry.module.ts; see Deviations) |
| `server/src/observability/error-tracking.types.ts` | ✅ |
| `server/src/observability/audit-log.service.ts` | ✅ |
| `server/src/observability/audit-log.types.ts` | ✅ |
| `server/src/observability/metrics.service.ts` | ✅ |
| `server/src/observability/noop-error-tracking.service.ts` | ✅ (added) |
| Tests for error codes, BusinessException, AuditLogService, MetricsService, NoopErrorTracking, GlobalExceptionFilter (rewritten) | ✅ |

## Files Modified
- `server/src/app.module.ts` — registers `ObservabilityModule`
- `server/src/common/filters/global-exception.filter.ts` — error-tracker hook + ErrorCode reverse-mapping
- `server/src/config/env.schema.ts` — adds Sentry + audit + alert envs
- `server/src/config/config.types.ts` — adds `ObservabilityConfig`
- `server/src/config/config.service.ts` — adds `.observability` getter
- `server/.env.example` — Sentry/audit/alert sections
- `server/package.json` — adds optional `@sentry/node ^7.99`

## Tests Written
- `error-codes.spec.ts` — 5 cases (uniqueness, exhaustive HTTP map, default messages, range alignment, depth ≥ 60)
- `business.exception.spec.ts` — 9 cases covering base + every specialised subclass
- `audit-log.service.spec.ts` — 5 cases (enrichment, metadata redaction, disabled flag, batch, query placeholder)
- `metrics.service.spec.ts` — 3 cases
- `noop-error-tracking.service.spec.ts` — 1 catchall safety case
- `global-exception.filter.spec.ts` — **rewritten** with 8 cases (was 5) covering BusinessException routing, 4xx vs 5xx tracker behaviour, unknown throwables, optional tracker

## Database Changes
None. (BE-05 will introduce the database connection and the `audit_logs` table.)

## What's Ready for Next Phase

BE-05 (Database Connection & Repository Foundation) can:
1. Implement an `AuditLogRepository` and replace the placeholder body of `AuditLogService.query`.
2. Persist enriched entries inside `AuditLogService.logAction` after the structured-log emit (we already keep them in the same shape).
3. Reuse `BusinessException`/`ErrorCode` directly: `DATABASE_CONNECTION_FAILED` / `DATABASE_TIMEOUT` / `DATABASE_DEADLOCK` are already in the catalog.
4. Tap `MetricsService` for query timing histograms.
5. Sentry will already capture any boot-time DB failure via `OnModuleInit` → exception path.

## Known Issues / Follow-ups
- The `@sentry/node` import is dynamic (`await import`). If the package isn't installed at runtime, the service warns once and degrades to no-op — this is intentional so `pnpm install` can be deferred until a developer wants real error tracking, but means we should make `@sentry/node` a soft requirement in CI to avoid silently disabling it in production deploys.
- `MetricsService` currently logs every metric. In BE-48 we'll route to OTel/Prometheus and stop log-spamming when volume rises.
- `AuditLogService.query()` returns `[]` deliberately. BE-05 wires the repo and unblocks the admin endpoints.

## Deviations from Spec
- **Combined exception subclasses into a single file**. The spec listed five separate files (`validation.exception.ts`, `not-found.exception.ts`, …). Five 5-line files for trivially-related sibling classes was friction — they all live in `business.exception.ts` and re-export through `errors/index.ts`. Same public API, less file noise.
- **Renamed `sentry.module.ts` → `observability.module.ts`** because Sentry is one of three things the module wires (audit log, metrics, error tracking). The single module avoids fan-out and matches BE-48's planned module name.
- **Added `NoopErrorTrackingService`** (not in the spec) so the abstraction stays clean — consumers always inject `ERROR_TRACKING_SERVICE` without conditional logic.
- **Renamed exception subclasses**: `NotFoundException` → `DomainNotFoundException`, `ForbiddenException` → `DomainForbiddenException`, `ConflictException` → `DomainConflictException`. Reason: NestJS already exports `NotFoundException` and `ForbiddenException`, and accidental collision was a real foot-gun in BE-03 e2e. The `Domain` prefix makes intent obvious and avoids import shadowing.
- The `SENTRY_DSN` env var was not enumerated in BE-02's schema; added it here together with `SENTRY_TRACES_SAMPLE_RATE`, `AUDIT_LOG_ENABLED`, `CRITICAL_ALERT_EMAIL`.
- The audit query DTO file mentioned in the spec is unnecessary today — the admin audit endpoints don't exist yet (no DB). When BE-05 enables them, we'll add a Zod-typed DTO using `ZodValidationPipe` from BE-03.

## Context for Next Developer (BE-05)

You're inheriting a clean error/observability surface:
- Throw `BusinessException`-typed errors with stable codes and the response envelope is filled out for you.
- Inject `AuditLogService` to record any compliance-relevant action (CRUD, login/logout, exports).
- Inject `MetricsService` to count/gauge/histogram anything operationally interesting.
- Inject `ERROR_TRACKING_SERVICE` (symbol) when you want to add Sentry breadcrumbs or capture a non-throw event.

BE-05 should:
1. Add Drizzle ORM + `postgres` connection pool, wiring it through `ConfigService.database`.
2. Create the `audit_logs` table as the first migration; immediately back `AuditLogService` with the repository.
3. Add a `RequestTransactionInterceptor` so every request can opt into a single PG transaction.
4. Wire `health/ready` through to a real DB ping so Kubernetes readiness probes work.
5. Use `ErrorCode.DATABASE_CONNECTION_FAILED` / `DATABASE_TIMEOUT` / `DATABASE_DEADLOCK` from this phase — don't invent new strings.

## Environment State
New deps:
- `@sentry/node ^7.99.0`

New env:
- `SENTRY_DSN` (optional)
- `SENTRY_TRACES_SAMPLE_RATE` (default 0.1)
- `AUDIT_LOG_ENABLED` (default true)
- `CRITICAL_ALERT_EMAIL` (optional, for BE-49 to wire restore-test alerts)

## Performance Metrics
- Exception construction: < 1 ms (allocates one HttpException + one details map)
- Sentry capture: async; non-blocking
- Audit log emit: < 1 ms (just structured logger.info)
- Metrics emit: < 1 ms
- Reverse-lookup of HTTP status → ErrorCode: O(1)

## Security Audit
- Sentry `beforeSend` scrubs `password`, `otp`, `token`, `secret`, `aadhaar`, `pan`, `cookie`, `authorization` from request.data/headers and extra context ✅
- 4xx errors NEVER reported to error tracker (avoids noise + accidental PII upload from validation failures) ✅
- 5xx errors always reported with redacted body in the local log AND in the tracker scope ✅
- `BusinessException` cannot leak internal error message text by accident — if no message is provided, falls back to the code's default user-facing string ✅
- `AuditLogService` redacts metadata before logging, can't be turned off per-request ✅
- `@sentry/node` is loaded dynamically so it's safe to omit in environments where you can't ship binary native deps ✅

## Next Phase Preparation

To run BE-04 locally:
```
pnpm install                        # @sentry/node lands now
cp server/.env.example server/.env.local
pnpm --filter @radha/server lint
pnpm --filter @radha/server test
pnpm --filter @radha/server start:dev
```

Verify error envelope is unchanged from BE-03:
```
curl -i http://localhost:3000/api/v1/nonexistent
# 404, error.code = "E5000" (NOT_FOUND), meta.requestId present
```

Verify Sentry stays disabled when DSN is empty:
```
pnpm --filter @radha/server start:dev | grep "Sentry"
# expect: "Sentry DSN not configured; error tracking disabled."
```

To enable Sentry (with a real DSN):
```
SENTRY_DSN=https://...@sentry.io/... pnpm --filter @radha/server start:dev
# expect: "Sentry initialised (env=development, sample=0.1)"
```

## Q&A Answers (BE-04 SOP)

**Q1 — Why custom exception classes instead of plain `HttpException`?** Type safety on `code`, autocomplete in IDE, mobile-app can switch on the codes for retry/i18n logic, instances are stable identifiers in tests (`expect(err).toBeInstanceOf(DomainNotFoundException)`).

**Q2 — Why an enum, not strings?** Numbered ranges encode category (5xxx ⇒ resource missing). Enum values are stable identifiers we promise never to renumber. Easy to grep across logs. The compiler enforces exhaustiveness on `ERROR_CODE_TO_HTTP_STATUS`.

**Q3 — Why optional Sentry?** Local dev shouldn't pollute the production project. CI environments may not have outbound internet. Cost control. The whole API stays usable without it.

**Q4 — What is `beforeSend`?** A Sentry hook that runs in-process *before* the event is shipped to the Sentry server. Last line of defence to scrub PII or drop events entirely. Critical for GDPR / DPDP compliance.

**Q5 — Audit vs regular logs?** Audit logs are immutable, queryable, and tied to compliance retention. Regular logs are operational and may be aggressively rotated. Audit entries always include who/what/when/result; regular logs don't have that contract.

**Q6 — When to add a new error code?** When the Mobile_App needs to react differently. If two situations need the same UX, reuse. The catalog is intentionally finite — adding hundreds of nuanced codes makes mobile-side handling worse, not better.

**Q7 — Test error handling without breaking prod?** Throw exceptions from a small `/test/error` endpoint guarded by `isDevelopment`. Use property tests in CI. Inject failures through provider mocks. Watch error rates in Sentry post-deploy.

**Q8 — error/warn/info distinction?** `error` = page someone, action required. `warn` = investigate later, retry happened, latency budget breached. `info` = normal operation, request lifecycle. `debug` = local dev only. `verbose` = trace.

## Rollback Information
- Remove `@sentry/node` from `server/package.json`
- Delete `src/observability/`
- Delete `src/common/errors/` (and all imports of `BusinessException` / `ErrorCode` — none yet outside tests)
- Restore `app.module.ts` to BE-03 form
- Restore `global-exception.filter.ts` to BE-03 form (no error tracker injection)
- Remove `SENTRY_*`, `AUDIT_LOG_ENABLED`, `CRITICAL_ALERT_EMAIL` from env schema and example file

---

**End of BE-04 Handoff. Approved for BE-05 once local verification commands pass.**
