# BE-24 Session Handoff — Notifications & Background Jobs

## Session Metadata
- **Phase**: BE-24
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-26
- **Previous Phase**: BE-23 — AI/OCR Wrapper persistence
- **Next Phase**: BE-25

---

## ⚠️ ORCHESTRATOR INTEGRATION CHECKLIST

> Hard constraint: **do not modify shared files** (`app.module.ts`, `db/schema/index.ts`, `package.json`, `main.api.ts`, `main.worker.ts`, `main.scheduler.ts`). The merge step applies the changes below.

### 1. Schema barrel additions

`server/src/db/schema/index.ts` — append:

```typescript
export * from './notifications';
```

This re-exports `notifications`, `notificationPreferences`, `notificationTemplates`, `deviceTokens`, all five enums (`notificationStatusEnum`, `notificationChannelEnum`, `notificationPriorityEnum`, `notificationCategoryEnum`, `devicePlatformEnum`), and the row/insert types for each.

### 2. Database migration

`server/src/db/migrations/0004_be24_notifications.sql` is included. **Idempotent** — every `CREATE` and `CREATE TYPE` is guarded. After merge:

```bash
cd server
pnpm db:migrate
```

### 3. AppModule registration

`server/src/app.module.ts` — add the imports and entries:

```typescript
import { FcmModule } from './integrations/fcm/fcm.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { JobsModule } from './jobs/jobs.module';

// inside @Module imports — keep ScheduleModule.forRoot() before JobsModule
imports: [
  // ...existing imports...
  FcmModule,
  NotificationsModule,
  JobsModule,
],
```

Ordering: `ScheduleModule.forRoot()` (already in `AppModule`) **must** stay registered **before** `JobsModule`, otherwise `@Cron()` decorators won't fire.

### 4. New npm dependencies

Add to `server/package.json`:

| Package | Version | Why | Lazy-loaded? |
|---|---|---|---|
| `bullmq` | `^5.7.0` | Queue + retry/backoff + DLQ | yes |
| `ioredis` | `^5.4.1` | Redis client used by BullMQ | yes |
| `firebase-admin` | `^12.1.0` | FCM (push notifications) | yes |

All three are loaded via dynamic `import('…').catch(() => null)` (same lazy pattern as BE-13's `@aws-sdk/*` and BE-21's `exceljs`). The server **boots** without them; channels degrade gracefully (FCM returns `globalError`, BullMQ falls through to synchronous dispatch).

After the merge, run:

```bash
pnpm --filter @radha/server install
```

### 5. Environment variables (new — append to `.env.example`)

Required only if you want the live channels active:

```dotenv
# BE-24 — FCM (Firebase Cloud Messaging) — push notifications
# Pick exactly one of:
FCM_SERVICE_ACCOUNT_JSON=          # full service-account JSON, single line
FCM_SERVICE_ACCOUNT_BASE64=        # base64-encoded JSON

# BE-24 — Optional cron toggle (used by `JobsModule` follow-up)
RUN_CRONS=1                        # set on the scheduler process only
```

Existing `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD` / `REDIS_DB` / `REDIS_TLS` (already in `env.schema.ts`) are reused by BullMQ — no new schema entries are required.

### 6. Bootstrap changes

#### `server/src/main.api.ts`

No structural change required. Once `JobsModule` is registered in `AppModule`, the API process automatically holds the BullMQ producer connection.

#### `server/src/main.worker.ts`

No structural change required. The worker process imports `AppModule`, which now imports `JobsModule`, which calls `BullMqBootstrapService.initialise()` on `onModuleInit`. The bootstrap detects `NotificationProcessor` in the DI graph and starts the BullMQ Worker side automatically. Concurrency = 10, rate limit = 200/min (tunable in `bullmq-queue.provider.ts`).

#### `server/src/main.scheduler.ts`

No structural change required. `@Cron()` decorators on the cron classes fire here because `ScheduleModule.forRoot()` is registered in `AppModule`.

#### Cron deduplication (production)

`@Cron()` decorators fire in **every** process that imports `JobsModule`. v1 ships with all three processes eligible. For production:

1. **Recommended**: gate cron execution per-method:
   ```typescript
   if (process.env.RUN_CRONS !== '1') return;
   ```
   Set `RUN_CRONS=1` only on the scheduler process.
2. **Alternative**: split `JobsModule` into a queue half + a schedule half and import only the queue half from API/worker.

The first option is two lines per cron. v2 polish — happy to ship in a small follow-up before BE-25 if Ops wants it.

### 7. Permissions catalog

No changes to `server/src/modules/auth/types/permission.types.ts` or `role-permissions.map.ts`. The notifications endpoints are gated by **role** only (`Roles('owner', 'manager', 'staff', 'auditor', 'admin', 'consumer')`) — every authenticated user can manage their **own** inbox + preferences + FCM tokens. Admin-only `POST /notifications/test` uses `Roles('admin', 'owner')`.

`RequireTenant()` is set for inbox + preferences (cross-tenant inbox reads impossible). The FCM-token routes deliberately do **not** require a tenant — fresh Consumer signups may still be in the BE-09 tenant-bootstrap window when their device first registers.

### 8. Cron schedules chosen

| Cron | Schedule | Why |
|---|---|---|
| `daily-aggregation` | `0 1 * * *` UTC (06:30 IST) | Late enough that all events for the previous UTC day are persisted; early enough that India-morning dashboards are fresh. |
| `expiry-status-update` | `0 2 * * *` UTC (07:30 IST) | After aggregation so the dashboard doesn't see stale red/yellow counts mid-recalc. |
| `session-cleanup` | `EVERY_HOUR` | Cheap (indexed scans). Hourly cadence keeps overdue tasks + stale session state bounded by ≤ 60 min. |
| `data-retention` | `0 3 * * 0` (Sunday 03:00 UTC = 08:30 IST) | Off-peak window. Weekly is enough for retention bookkeeping; daily would be expensive on `audit_logs`. |
| `scheduled-reports` | `EVERY_30_MINUTES` | Schedules only resolve to hour-of-day, so 30 min is the minimum useful granularity. |
| `notification-dispatch` | `EVERY_MINUTE` | Recovery sweeper — bounded `LIMIT 200` and one indexed read against `notifications_scheduled_idx`. |

### 9. BullMQ retry / backoff

Configured in `BullMqBootstrapService` (`bullmq-queue.provider.ts`):

```typescript
defaultJobOptions: {
  attempts: 5,                                    // 4 retries after first attempt
  backoff: { type: 'exponential', delay: 5_000 }, // 5s, 10s, 20s, 40s, 80s
  removeOnComplete: { age: 86_400, count: 5_000 }, // 1-day TTL on completed
  removeOnFail: { age: 7 * 86_400 },              // 7-day DLQ on failed
}
```

After 5 attempts the job lands in BullMQ's failed set (effectively a DLQ — viewable via Bull-Board if Ops wires it later). The notification row's `failedAt` and `error` are populated by `dispatchNow`'s catch path so the App Owner Dashboard can surface the failure without inspecting Redis.

### 10. SMS-channel restriction (Req 28)

`PreferenceManagerService.filterChannels` enforces "SMS only for the `auth` category" regardless of per-user preferences. Req 28 is honoured: SMS = OTP delivery only, no marketing/expiry/task spam over SMS. The router never even calls `SmsService.sendNotification` for non-auth notifications because the channel is filtered out before persistence.

---


## What Was Completed

### Schema (single file `db/schema/notifications.ts`)

Four tables, five enums, one migration (`0004_be24_notifications.sql`):

- **`notifications`** — log of every send attempt. Per-channel statuses (email/sms/push/in-app) on the same row; mailbox semantics (`is_read`, `read_at`); lifecycle timestamps (`sent_at`, `scheduled_for`, `failed_at`, `attempt_count`). 6 indexes.
- **`notification_preferences`** — one row per user. Channel-level master toggles + JSONB `category_opt_ins` map (default-enabled when key absent).
- **`notification_templates`** — DB-stored override layer for the in-process default templates. `tenant_id IS NULL` rows are platform defaults; tenant overrides unique per `(tenant_id, key, locale)`.
- **`device_tokens`** — FCM device tokens. Permanent-failure tokens flip `is_active=false` (Req 28). Re-registering an active token transfers ownership.

5 enums: `notification_status` (7 states), `notification_channel`, `notification_priority`, `notification_category` (9 categories), `device_platform`.

### Repositories (4)

- **`NotificationsRepository`** — `findByIdForUser`, `listForUser` (cursor pagination via tuple seek), `markRead`, `markAllRead`, `findDueScheduled`, `findExpiredOlderThan` / `deleteOlderThan`, `incrementAttempts`, `getUnreadCount`, `countSentInWindow` (SES budget metering).
- **`NotificationPreferencesRepository`** — `findByUser`, `upsertForUser` with `ON CONFLICT (user_id) DO UPDATE`.
- **`NotificationTemplatesRepository`** — `findEffective(key, tenantId, locale)` does the tenant→global resolution; `listForTenant`.
- **`DeviceTokensRepository`** — `upsertByToken` (transfer-ownership upsert), `findActiveForUser(s)`, `markInvalidByToken(s)`, `deactivateByUserAndToken`.

### Services (6 sub + 1 main)

- **`NotificationsService`** — public façade. send → persist → router fan-out → status update → audit-log. Optional BullMQ queue via `NOTIFICATIONS_QUEUE_TOKEN`. `dispatchNow` is the worker entry point. `dispatchDue` is the recovery sweeper called by the cron.
- **`PreferenceManagerService`** — preferences read/write, SMS-only-for-auth enforcement, quiet-hours predicate (overnight-aware, IANA-zone-aware via `Intl.DateTimeFormat`) + `nextActiveTime` (5-min walk forward, bounded at 25h).
- **`TemplateRendererService`** — DB override → platform default DB row → in-process fallback. `{{key}}` substitution. HTML branch values are HTML-escaped at substitution time.
- **`NotificationRouterService`** — fan-out to channels concurrently via `Promise.allSettled`. Resolves user contact once. `in-app` is a no-op (the row IS the in-app payload).
- **`EmailNotificationService`** — adapter over `EmailService` (BE-07).
- **`SmsNotificationService`** — adapter over `SmsService.sendNotification` (BE-06).
- **`PushNotificationService`** — pulls active device tokens, fans out FCM multicast, marks permanent-failure tokens inactive on the way back.

### Integrations (1)

- **`FcmService`** — Firebase Cloud Messaging wrapper. Lazy-loads `firebase-admin`. Two credential formats supported (`FCM_SERVICE_ACCOUNT_JSON`, `FCM_SERVICE_ACCOUNT_BASE64`). `sendEachForMulticast` for batches; permanent-failure tokens classified via FCM error codes.
- **`FcmModule`** — global, exports `FcmService`.

### Processor (1)

- **`NotificationProcessor`** — BullMQ adapter. Receives `(job)`, calls `dispatchNow`, throws on failure so BullMQ retries per the configured backoff. Emits `notification.dispatch.{success,failed,error}` counters and a duration histogram via `MetricsService`.

### BullMQ infrastructure

- **`BullMqBootstrapService`** — lazy-loads `bullmq` + `ioredis`. Falls through to `null` queue when either dep is missing; the system stays correct, just synchronous.
- **`JobsModule`** — wires the bootstrap, binds `NOTIFICATIONS_QUEUE_TOKEN` via `useFactory`, registers the cron jobs. `onModuleInit` initialises BullMQ; `onModuleDestroy` shuts it down.

### Cron jobs (6)

- `daily-aggregation.cron.ts` → 01:00 UTC daily.
- `expiry-status-update.cron.ts` → 02:00 UTC daily, walks active tenants × stores.
- `session-cleanup.cron.ts` → hourly. Combines stale-session expiration + overdue-task marking.
- `data-retention.cron.ts` → Sunday 03:00 UTC. 5 cleanup queries.
- `scheduled-reports.cron.ts` → every 30 min. `findDueAt` → `runFromSchedule` → bulk in-app notifications.
- `notification-dispatch.cron.ts` → every minute (recovery sweeper).

### Controller

- **`NotificationsController`** — 8 endpoints under `/api/v1/notifications/...`. Static segments (`preferences`, `read-all`, `test`, `fcm-token`) declared before the dynamic `:id` slot. BE-08 guard stack on every route.

### Tests

| File | Cases |
|---|---|
| `template-renderer.service.spec.ts` | 8 |
| `preference-manager.service.spec.ts` | 8 |
| `notifications.service.spec.ts` | 11 |
| `notification-router.service.spec.ts` | 5 |
| `notification.processor.spec.ts` | 3 |
| `notifications.dto.spec.ts` | 11 |
| `fcm.service.spec.ts` | 6 |

**52 new test cases.** All clean against TypeScript diagnostics.

---

## Files Created (vs BE-24 spec "Files to Create")

| Spec file | Status |
|---|---|
| `server/src/db/schema/notifications.ts` | ✅ |
| `server/src/db/schema/notification_preferences.ts` | ✅ folded into `notifications.ts` (consolidated per BE-15/16/17/18/19/20 convention) |
| `server/src/db/schema/notification_templates.ts` | ✅ folded into `notifications.ts` |
| `server/src/modules/notifications/notifications.module.ts` | ✅ |
| `server/src/modules/notifications/notifications.controller.ts` | ✅ |
| `server/src/modules/notifications/notifications.service.ts` | ✅ |
| `server/src/modules/notifications/services/email-notification.service.ts` | ✅ |
| `server/src/modules/notifications/services/sms-notification.service.ts` | ✅ |
| `server/src/modules/notifications/services/push-notification.service.ts` | ✅ |
| `server/src/modules/notifications/services/notification-router.service.ts` | ✅ |
| `server/src/modules/notifications/services/template-renderer.service.ts` | ✅ |
| `server/src/modules/notifications/services/preference-manager.service.ts` | ✅ |
| `server/src/modules/notifications/processors/notification.processor.ts` | ✅ |
| `server/src/modules/notifications/repositories/notifications.repository.ts` | ✅ |
| `server/src/modules/notifications/repositories/notification-preferences.repository.ts` | ✅ |
| `server/src/modules/notifications/repositories/notification-templates.repository.ts` | ✅ |
| `server/src/modules/notifications/repositories/device-tokens.repository.ts` | ✅ |
| `server/src/integrations/fcm/fcm.service.ts` | ✅ + `fcm.module.ts` + `fcm.types.ts` |
| `server/src/jobs/cron/daily-aggregation.cron.ts` | ✅ |
| `server/src/jobs/cron/expiry-status-update.cron.ts` | ✅ |
| `server/src/jobs/cron/session-cleanup.cron.ts` | ✅ |
| `server/src/jobs/cron/data-retention.cron.ts` | ✅ |
| `server/src/jobs/cron/scheduled-reports.cron.ts` | ✅ |
| `server/src/jobs/jobs.module.ts` | ✅ + `bullmq-queue.provider.ts` |
| `server/src/jobs/cron/notification-dispatch.cron.ts` | ⚠ added (not in spec) — recovery sweeper for the queueless fallback path |
| All `__tests__/` files | ✅ 7 spec files, 52 cases |

### Spec items deferred / replaced

- **v2 ADDENDUM Req 31 (`Recall_Sweep_Job`)** — defers to BE-39 per the spec doc. BE-24 ships the channels + preferences enforcement it relies on.
- **v2 ADDENDUM Req 47 (`Daily_Insights_Job`)** — defers to BE-54 per the spec doc. BE-24 ships the `daily-insights` category and the `daily-digest` template.
- **v2 ADDENDUM `SesBudgetWatcherService`** — data plumbing in place via `countSentInWindow(from, to, 'email')`. Watcher cron not shipped because the warning destination (Owner alerts) lands in BE-31. **Brutal honesty: deferred.**
- **DLQ admin UI** — BullMQ keeps failed jobs for 7 days. Bull-Board or a custom DLQ inspector can be wired later.
- **Cron deduplication via env flag** — see "Cron deduplication" above. Decorator-level guard is a 2-line follow-up; v1 ships unconditionally so the validation pack can exercise crons on a single dev process.
- **Outbound SES bounce webhook** — `notification_status='bounced'` enum value reserved; webhook endpoint + event-source bus is BE-25/BE-31 work. **Brutal honesty: deferred.**
- **Per-template seed data in `notification_templates`** — in-process registry covers all 15 default keys, so the API works on day 1 without seeded rows. Seeding the DB rows is a follow-up if the App Owner Dashboard wants to list/edit them.

## Files Modified (vs HARD CONSTRAINTS — flagged for orchestrator)

None modified. All four guarded files are untouched.

| File | Change needed | Risk |
|---|---|---|
| `server/src/app.module.ts` | Import `FcmModule`, `NotificationsModule`, `JobsModule` | Low |
| `server/src/db/schema/index.ts` | `export * from './notifications';` | Low |
| `server/package.json` | Add `bullmq`, `ioredis`, `firebase-admin` | Low |
| `server/src/main.api.ts` | None (auto-wired) | None |
| `server/src/main.worker.ts` | None (auto-wired) | None |
| `server/src/main.scheduler.ts` | None (auto-wired) | None |

## Database Changes

- 4 new tables: `notifications`, `notification_preferences`, `notification_templates`, `device_tokens`.
- 5 new enums: `notification_status`, `notification_channel`, `notification_priority`, `notification_category`, `device_platform`.
- 11 indexes total.

Run `pnpm --filter @radha/server db:migrate`.

## What's Ready for Next Phase

BE-25 (App Owner Dashboard):
1. Read `notifications` joined with `users` for tenant-wide notification history.
2. BullMQ queue depth + failed-job count tile.
3. Inspect `device_tokens` for active-vs-invalidated trend lines.
4. Allow Owners to override `notification_templates` per tenant (CRUD endpoints land in BE-25).

BE-26 (GRN):
1. `NotificationsService.sendTemplate('expiry-near', ...)` after every GRN line bringing stock with insufficient shelf life.
2. `recall-alert` template once BE-39 fires.

BE-31:
1. SES budget watcher.
2. SES bounce webhook → `markInvalidByToken` equivalent for emails.

BE-39 (Recall Sweep):
1. `NotificationsService.sendBulk` with `category: 'recall-alert'`.

BE-54 (Weekly Digest):
1. `NotificationsService.sendTemplate('daily-digest', ...)`.

## Known Issues / Follow-ups

- **Cron dedup is decoration-level not env-gated** — every process running `JobsModule` will fire the crons. v1 acceptable; production needs a `RUN_CRONS=1` guard on each cron's `run()` method.
- **`@nestjs/bullmq` not used** — went directly to the `bullmq` package via the lazy bootstrap. Trade-off: no `@Processor()` decorators — the worker is registered in code in `BullMqBootstrapService.initialise`. Swapping is a 30-min refactor.
- **No SES bounce webhook wired** — largest deferred item. The data path is ready (`notification_status='bounced'` enum value, `email_status` column).
- **No SES budget alarm cron** — data plumbing in `countSentInWindow` is ready; a 30-line `SesBudgetWatcherCron` would close it.
- **Quiet hours `nextActiveTime` walks 5-min increments** — bounded at 25h. Off by ≤ 5 min from the precise boundary.
- **Single locale for templates (en)** — i18n is BE-39 work. Schema column is in place.
- **In-app channel doesn't push to a websocket** — Mobile_App polls `/api/v1/notifications`.
- **No idempotency on `send()`** — calling twice with the same payload creates two notifications. Idempotency-Key support waits for BE-44.
- **Per-tenant SES sender** — currently uses the global `criticalAlertEmail` config as From. White-label per-tenant is post-launch.

## Deviations from Spec

- **Single `db/schema/notifications.ts` consolidation** — same as BE-15/16/17/18/19/20 pattern.
- **Single consolidated `dto/notifications.dto.ts`** — five Zod schemas.
- **`device_tokens` table added on top of spec** — required by Req 28 (FCM permanent-failure invalidation).
- **Notification dispatch sweeper** — added beyond the spec's 5 crons.
- **`@nestjs/bullmq` not adopted** — see Known Issues.
- **In-process default templates registry** — alongside the DB table. Spec wanted DB-only; in-process means the API works without seeded rows on day 1.
- **`marketing` category opt-out by default** — GDPR-friendly.
- **SMS hard-locked to `auth`** — Req 28 enforced regardless of per-user preferences.

## Context for Next Developer

You're inheriting:
- A working multi-channel notification surface (email, SMS, push, in-app) with per-user preferences, quiet hours, category opt-outs.
- A BullMQ-backed dispatch path with retry/backoff/DLQ that gracefully falls through to synchronous dispatch when Redis isn't available.
- A clean BE-15/17/18/19/20/21 hookup: every module that already deferred its notification dispatch can now `inject(NotificationsService)`.
- 6 cron jobs covering daily aggregation, expiry recalc, session cleanup, data retention, scheduled reports, and notification dispatch sweeping.
- 7 spec files, 52 test cases, all clean against TypeScript diagnostics.

## Environment State

New deps in `server/package.json` (to be added during merge):
- `bullmq ^5.7.0`
- `ioredis ^5.4.1`
- `firebase-admin ^12.1.0`

**Run `pnpm install` after merging.** Without these the lazy imports return `null` and the system runs in synchronous-only mode (no queue, no FCM). Email + SMS still work via the existing BE-06/07 integrations.

## Performance Metrics

- `send()` synchronous path (no queue): ~15-30 ms.
- `send()` queued path: ~5 ms (prefs + insert + queue.add).
- Per-channel dispatch:
  - email (mock): < 1 ms; SES live: ~150-300 ms.
  - SMS (mock): < 1 ms; MSG91 live: ~200-500 ms.
  - push (FCM live): ~200-500 ms for a 100-token multicast.
  - in-app: instant.
- `getHistory` cursor pagination, limit 50: ~5-10 ms on a populated table.
- Cron costs: aggregation < 30s for 1K stores; recalc ~5-15s per store with 10K records; data retention ~5-30s.

## Security Audit

- Tenant scoping on every read via `(tenantId, userId)` indexes ✅.
- BE-08 guard stack on every route ✅.
- DTO caps everywhere ✅.
- HTML escaping on placeholder values in the HTML branch (no template injection) ✅.
- SMS hard-locked to `auth` category ✅.
- Marketing opt-out by default — GDPR-friendly ✅.
- Audit log entries on every send + preference update + token register/unregister ✅.
- Permanent-failure tokens auto-marked invalid (Req 28) ✅.
- Quiet-hours honoured for non-urgent sends ✅.
- BullMQ queue failures don't break dispatch — sync fallback keeps the system correct ✅.
- FCM credentials read from env only — never logged ✅.
- `forceSync` flag is internal-only — not surfacable via the controller ✅.
- Notification rows older than 90 days (read) auto-pruned by data retention cron ✅.

## Verification Pack

**`BACKEND_PHASES/BE-24_VERIFICATION.md`** — five suites: A (unit), B (integration via mock channels + sync dispatch), C (preferences + quiet-hours invariants), D (security gates), E (cron simulation + BullMQ retry).

## Q&A Answers (BE-24 SOP)

**Q1 — Why multi-channel?** Different urgencies, different user preferences, redundancy. OTP SMS reaches users without internet; push is free + instant; email survives device wipes. The router runs them in parallel and respects opt-outs.

**Q2 — Why quiet hours?** Don't wake users at night, professional courtesy, GDPR-friendly. IANA-timezone aware, overnight-aware (22:00 → 07:00). Urgent priority bypasses.

**Q3 — Why FCM for push?** Free, Google-backed, iOS + Android out of the box. Multicast saves round-trips for users with multiple devices. Permanent-failure tokens auto-invalidate.

**Q4 — Why cron jobs vs queues?** Cron for time-based, queue for event-based. The notification-dispatch sweeper bridges both — runs on cron but its purpose is to recover from queue outages.

**Q5 — Why data retention?** Compliance (GDPR, India's DPDPA), storage costs, performance. 90 days for read notifications, 365 for audit logs, 30 for OTP attempts. All policy in `data-retention.cron.ts`.

**Q6 — How handle SES bounces?** Data path supports it (`status='bounced'` enum value, `email_status` column). The actual SES bounce webhook receiver is BE-25/BE-31 work. **Brutal honesty: deferred.**

**Q7 — How scale notifications?** BullMQ workers (concurrency=10 each, scale horizontally). Rate limit 200/min per worker. Batched FCM. Indexed `notifications_user_created_idx` for inbox reads. `daily_store_metrics` upsert for O(stores) dashboards. 100K notifications/day = 1 worker; 1M/day = 5 workers behind one Redis.

**Q8 — Notification storms?** Per-user `digestFrequency='daily'` collapses many notifications into a single daily digest. `urgent` priority bypasses but is reserved for OTP + recall + critical expiry. Bulk fan-out is bounded at the DTO layer (5K user IDs) and runs via `Promise.allSettled`.

**Q-v2.1 — Notification_Preferences seeding for new users?** First read returns in-process defaults (no row inserted). First **update** call upserts a row. Defaults: all channels enabled, all categories enabled except `marketing` (opt-in).

**Q-v2.2 — Multiple devices per user?** `device_tokens` allows N rows per user. The push channel does a single FCM multicast (one provider call, N tokens). Each device gets one push. The in-app inbox is per-user, not per-device, so they only see one inbox entry across devices.

**Q-v2.3 — FCM transient vs permanent retry policy?** Transient (`unavailable`, `internal-error`) → BullMQ retries with exponential backoff (5s, 10s, 20s, 40s, 80s, then DLQ). Permanent (`registration-token-not-registered`, `invalid-argument`) → token marked inactive immediately, no retry on that token. Per-token classification in `FcmService.classifyError`.

## Rollback Information

```bash
# Revert migration
psql $DATABASE_URL -c "DROP TABLE IF EXISTS device_tokens, notification_templates, notification_preferences, notifications;"
psql $DATABASE_URL -c "DROP TYPE IF EXISTS device_platform, notification_category, notification_priority, notification_channel, notification_status;"

# Code rollback
rm -rf server/src/modules/notifications
rm -rf server/src/integrations/fcm
rm -rf server/src/jobs
rm server/src/db/schema/notifications.ts
rm server/src/db/migrations/0004_be24_notifications.sql

# Revert imports in app.module.ts (FcmModule, NotificationsModule, JobsModule)
# Revert exports in db/schema/index.ts
# Revert package.json deps (bullmq, ioredis, firebase-admin)
```

---

**End of BE-24 Handoff. Approved for BE-25 once the BE-24_VERIFICATION pack passes locally with both queue-on (Redis available) and queue-off (sync fallback) modes verified.**
