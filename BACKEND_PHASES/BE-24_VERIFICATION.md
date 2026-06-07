# BE-24 Verification Pack — Notifications & Background Jobs

> Owner: Kiro · Phase: BE-24 · Last updated: 2026-05-26
>
> Run order: A → B → C → D → E. Suites A and C run without Redis; suites B, D, E benefit from a live Redis (the system still works without it, just synchronous).

## Pre-flight

```bash
cd server
pnpm install                  # picks up bullmq, ioredis, firebase-admin
pnpm db:migrate               # applies 0004_be24_notifications.sql
pnpm lint                     # --max-warnings 0 must pass
pnpm test                     # full unit suite
pnpm build                    # nest build must succeed
```

Optional Redis for suites B + E:

```bash
docker run --rm -p 6379:6379 --name radha-redis redis:7-alpine
```

Optional FCM (suites only check disabled paths in CI; live paths require a project):

```bash
export FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

---

## Suite A — Unit (Jest, no DB / no Redis)

Runs on the in-process default templates and stub repositories. Validates that the notification service is correct on its own, before any I/O.

### A1. Template renderer (`template-renderer.service.spec.ts`, 8 cases)
- Default template substitution (`task-assigned` with placeholders).
- HTML escaping on the html branch.
- Generic template via `subject` + `body` placeholders.
- DB override row wins over the default.
- Repo error falls back to defaults (no throw).
- `defaultChannelsFor` returns the registered channels.
- `defaultCategoryFor` returns the registered category.
- `renderString` direct mode + html-escape toggle.

### A2. Preference manager (`preference-manager.service.spec.ts`, 8 cases)
- Defaults when no row exists (marketing opt-out by default).
- DB row's `categoryOptIns` JSONB merges over defaults.
- `filterChannels` excludes user-disabled channels.
- `filterChannels` forces SMS to auth-only.
- `filterChannels` returns empty for opted-out categories.
- `filterChannels` allows SMS for `auth`.
- `isQuietHours` overnight-aware (22:00 → 07:00 UTC).
- `isQuietHours` urgent priority bypasses.

### A3. Notifications service (`notifications.service.spec.ts`, 11 cases)
- Synchronous dispatch persists row + per-channel statuses.
- Category opt-out emits a `skipped` row (audit-visible).
- Quiet-hours non-urgent reschedule with `delay > 0` queue option.
- SMS dropped for non-auth categories.
- All-channel failure marks `failedAt` + `error`.
- Queue wired + non-forced enqueues instead of dispatching.
- `markAsRead` delegates to repo.
- `markAllAsRead` returns updated count.
- `dispatchDue` zero when nothing due.
- `dispatchDue` queues each row when queue is wired.
- `dispatchDue` falls back to sync when queue absent.
- `sendBulk` counts successes + collects per-user errors.

### A4. Notification router (`notification-router.service.spec.ts`, 5 cases)
- Empty channels returns empty.
- Email + push + in-app dispatched concurrently with per-channel result.
- Channel-level rejection caught (no throw).
- Partial failure mixed with success.
- User-lookup failure falls back to empty contact (channels still called).

### A5. Notification processor (`notification.processor.spec.ts`, 3 cases)
- Success returns `sent` + delivered count + emits success counter.
- Failure throws so BullMQ retries; emits failed counter.
- Underlying error rethrows; emits error counter.

### A6. DTO validation (`notifications.dto.spec.ts`, 11 cases)
- List query defaults + range coercion.
- UpdatePreferences rejects empty body.
- UpdatePreferences accepts partial channel toggles.
- UpdatePreferences rejects malformed quiet hours (24:00).
- UpdatePreferences accepts well-formed quiet hours.
- UpdatePreferences rejects unknown digest frequency.
- TestNotification rejects non-uuid userId.
- TestNotification rejects empty channel array.
- RegisterDeviceToken token length boundary.
- RegisterDeviceToken accepts valid platform.
- RegisterDeviceToken rejects unknown platform.

### A7. FCM service (`fcm.service.spec.ts`, 6 cases)
- Reports unavailable without credentials.
- Returns `globalError` when no creds + tokens supplied.
- Returns no-tokens-provided on empty input.
- Rejects malformed JSON in env var.
- Accepts valid service-account JSON (defers init to dynamic import).
- Deduplicates tokens before dispatch.

**Pass criteria**: `pnpm test src/modules/notifications src/integrations/fcm` exits 0 with all 52 cases green.

---

## Suite B — Integration (mock channels, sync dispatch)

Runs against a real Postgres but uses mock email/SMS/FCM providers. No Redis needed.

```bash
NODE_ENV=test pnpm test:e2e --testPathPattern=notifications
```

### B1. End-to-end send (mock email, in-app)
- POST `/api/v1/notifications/test` with category=`task`, channels=`['email','in-app']`.
- Expect 202 with `notificationId`.
- Inspect `mockEmailProvider.getOutbox()` — exactly one entry with the rendered subject + body.
- Query `SELECT * FROM notifications WHERE id = $1` — `email_status='sent'`, `in_app_status='delivered'`, `sent_at IS NOT NULL`.

### B2. Inbox listing
- POST 3 notifications via the test endpoint.
- GET `/api/v1/notifications?limit=2`.
- Expect 2 rows + `nextCursor`.
- GET `/api/v1/notifications?limit=2&cursor=<nextCursor>`.
- Expect the 3rd row + `nextCursor: null`.

### B3. Mark-as-read
- POST `/api/v1/notifications/<id>/read`.
- Expect 200.
- Re-list with `unreadOnly=true` — the marked row is excluded.

### B4. Mark all as read
- POST 5 unread notifications.
- POST `/api/v1/notifications/read-all`.
- Expect `{ updated: 5 }`.
- Re-list with `unreadOnly=true` — empty.

### B5. Preferences round-trip
- GET `/api/v1/notifications/preferences` — defaults returned.
- PATCH `{ channels: { email: false }, categories: { marketing: true } }`.
- GET again — merged values returned.

### B6. Device token register + unregister
- POST `/api/v1/notifications/fcm-token` with a 120-char token + platform=android.
- Expect 201 + `{ id: <uuid> }`.
- DELETE `/api/v1/notifications/fcm-token` with the same token.
- Expect 200 + `{ success: true }`.
- Verify `device_tokens.is_active=false`, `invalidation_reason='user_logout'`.

### B7. Token transfer (Req 28)
- User A registers token T.
- User B registers same token T.
- Verify the row's `user_id` is now B and `is_active=true`.
- User A's `findActiveForUser` no longer returns T.

**Pass criteria**: every assertion green; mock email outbox shows the exact rendered subject; DB rows reflect the per-channel statuses.

---

## Suite C — Preferences + quiet-hours invariants

Runs against the in-process service (no DB needed for the predicate checks).

### C1. Marketing opt-out by default
- New user → `getPreferences` → `categories.marketing === false`.
- `filterChannels(prefs, ['email'], 'marketing')` → `[]`.
- The notification row is created with `email_status='skipped'`.

### C2. SMS lock (Req 28)
For every category in `['expiry-alert', 'task', 'report', 'system', 'recall-alert', 'daily-insights']`:
- `filterChannels(prefs, ['sms'], category)` → `[]`.
- `filterChannels(prefs, ['sms'], 'auth')` → `['sms']`.

### C3. Quiet hours overnight
- `quietHours = { enabled: true, start: '22:00', end: '07:00', timezone: 'UTC' }`.
- 23:30 UTC → `isQuietHours(prefs, 'normal', t)` returns true.
- 12:00 UTC → returns false.
- 06:30 UTC → returns true.
- 07:30 UTC → returns false.

### C4. Quiet hours bypass
- Same prefs, priority='urgent' → `isQuietHours` returns false at every hour.
- `send()` with `priority: 'urgent'` does **not** schedule, dispatches immediately.

### C5. nextActiveTime walk
- Quiet hours 22:00 → 07:00 UTC, `now = 23:00 UTC`.
- `nextActiveTime(prefs, now)` returns a Date within `[now+1m, now+9h+5m]` (07:00 UTC roughly).

### C6. Timezone handling
- Same prefs but `timezone='Asia/Kolkata'`, `now = 17:00 UTC` (= 22:30 IST).
- `isQuietHours` returns true.
- `now = 02:00 UTC` (= 07:30 IST) → returns false.

**Pass criteria**: all 6 invariants hold; covered by tests in suite A2 and verifiable via REST in suite B.

---

## Suite D — Security gates

### D1. JWT required
- GET `/api/v1/notifications` without bearer → 401.

### D2. Cross-tenant inbox impossible
- User U1 in tenant T1, user U2 in tenant T2.
- Login as U1, GET `/api/v1/notifications` — only U1's rows in T1 returned (no rows for U2 even though we share an endpoint).
- Force a query parameter `?tenantId=T2` → ignored (the controller reads tenant from the JWT-issued `CurrentTenant`).

### D3. Test endpoint admin-only
- Login as a `consumer` user, POST `/api/v1/notifications/test`.
- Expect 403 (`ROLE_REQUIRED` envelope).
- Login as `admin`, retry — 202.

### D4. SMS-non-auth blocked
- POST `/api/v1/notifications/test` with `category='task'`, `channels=['sms','in-app']`.
- Inspect created row — `channels=['in-app']` (sms filtered out).
- `mockSmsProvider.getMockBox()` — empty.

### D5. HTML escape
- POST `/api/v1/notifications/test` with `subject='<script>alert(1)</script>'`, `body='ok'`.
- Inspect rendered html via the mock email provider — `&lt;script&gt;` substituted, never raw `<script>`.

### D6. Rate-limit on send
- 100 rapid calls to `POST /notifications/test` from a single user.
- After the global rate limit (BE-46), expect 429.
- Notifications already enqueued continue to dispatch.

### D7. Permanent-token invalidation
- Stub `FcmService.send` to return `permanentFailure: true` for token X.
- Send a push notification with token X attached to a user.
- Verify `device_tokens.is_active=false WHERE token=X` after dispatch.

**Pass criteria**: every gate enforced; no admin-only or cross-tenant leak.

---

## Suite E — Cron simulation + BullMQ retry

### E1. Notification dispatch sweeper
- Insert a row with `scheduled_for = now() - INTERVAL '1 minute'`, `sent_at IS NULL`.
- Manually call `notificationDispatchCron.run()`.
- Expect the row's `sent_at` populated and `email_status='sent'` (synchronous fallback) OR a BullMQ job present (queue mode).

### E2. Daily aggregation cron
- Seed `scan_items` for store S1 with 50 rows on yesterday's UTC date.
- Manually call `dailyAggregationCron.run()`.
- Verify `daily_store_metrics` has a row keyed `(S1, yesterday)` with `total_scans=50`.

### E3. Expiry status cron
- Seed an `expiry_records` row with `expiry_date = now() + INTERVAL '2 days'`, status='green'.
- Manually call `expiryStatusUpdateCron.run()`.
- Expect the row's status promoted to `red` if the threshold has it ≤ 3 days.

### E4. Session cleanup cron
- Insert a scan session with `last_activity_at = now() - INTERVAL '5 hours'`, `status='active'`.
- Manually call `sessionCleanupCron.run()`.
- Expect status='expired'.
- Insert a task with `due_date = now() - INTERVAL '1 hour'`, `status='pending'`.
- Same cron call expected to flip it to `overdue`.

### E5. Data retention cron
- Insert a notification with `created_at = now() - INTERVAL '100 days'`, `is_read=true`.
- Manually call `dataRetentionCron.run()`.
- Verify the row is deleted.
- Insert an audit_log with `occurred_at = now() - INTERVAL '400 days'` — also deleted.

### E6. Scheduled reports cron
- Insert a `report_schedule` with `next_run_at = now() - INTERVAL '1 minute'`, `status='active'`, `recipients=[u1, u2]`.
- Manually call `scheduledReportsCron.run()`.
- Verify a `reports` row was created.
- Verify two `notifications` rows (one per recipient) with `category='report'`.

### E7. BullMQ retry path (requires Redis)
- Stub `EmailService.send` to throw on the first 3 calls, succeed on the 4th.
- POST `/api/v1/notifications/test` (forceSync=false).
- Wait for the job to settle.
- Verify the notification row's final `email_status='sent'`, `attempt_count=4`.

### E8. BullMQ DLQ path (requires Redis)
- Stub `EmailService.send` to always throw.
- POST `/api/v1/notifications/test`.
- Wait 5 minutes (full backoff schedule).
- Verify the notification row's `email_status='failed'`, `failed_at IS NOT NULL`, `error='boom'`.
- Inspect Redis: the job is in the failed set.

### E9. Sync fallback (no Redis)
- Stop Redis.
- POST `/api/v1/notifications/test`.
- Verify the response status is `'sent'` (sync mode), the row has `email_status='sent'`.
- Restart Redis. Subsequent sends return `status='queued'` again.

**Pass criteria**: every cron returns measurable side effects; BullMQ retries up to 5x with exponential backoff; sync fallback is correct when Redis is offline.

---

## Sign-off Checklist

- [ ] Suite A: 52/52 unit cases pass.
- [ ] Suite B: full inbox + preferences + token register/unregister round-trip.
- [ ] Suite C: 6 invariants verified (marketing opt-out, SMS lock, quiet-hours overnight + bypass, nextActiveTime, timezone).
- [ ] Suite D: 7 security gates enforced.
- [ ] Suite E: 9 cron + queue scenarios behave correctly.
- [ ] `pnpm lint --max-warnings 0` passes.
- [ ] `pnpm build` passes.
- [ ] Coverage > 85% on notifications module.
- [ ] No new `console.log` calls in production code.
- [ ] Audit log entries verified for: send (CREATE), preferences update (UPDATE), token register (CREATE), token unregister (DELETE).

**Reviewer Approval**: ☐ APPROVED ☐ CHANGES REQUESTED
**Reviewer Signature**: ___________________________

---

**End of BE-24 Verification Pack.**
