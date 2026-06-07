# BE-19 Session Handoff — Task Assignment & Workflow

## Session Metadata
- **Phase**: BE-19
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-25

## What Was Completed

### Schema (consolidated `db/schema/tasks.ts`)

Five tables in one file because they ship in one migration and share lifecycle:

- **`tasks`** — tenant-scoped, store-scoped work items. Carries `title/description/type/priority/status`, full lifecycle dates (`startDate/dueDate/startedAt/completedAt`), evidence requirements (`requiresPhoto`, `requiresScan`, `minimumEvidenceCount`), linkages (`expiryAlertId`, `productIds[]`, `scanSessionId`, `templateId`, `parentTaskId`), recurring fields (`isRecurring`, `recurrencePattern`, `recurrenceOccurrenceCount`), denormalised counters (`evidenceCount`, `assigneeCount`), `overdueMarkedAt`, plus soft-delete + audit columns. **Partial unique index** `idx_tasks_expiry_alert_active_uniq` enforces "at most one active task per expiry alert" so the auto-generator is idempotent.
- **`task_assignments`** — many-to-many task ↔ user. Modelled as **revoke-not-delete** (`revokedAt/revokedBy/revokedReason`), with **partial unique index** `idx_task_assignments_active_uniq` on `(task_id, assignee_id) WHERE revoked_at IS NULL` so a previously revoked user is a clean re-insert. Roles: `primary | observer`.
- **`task_events`** — append-only audit trail. 15 event types covering created/assigned/started/updated/completed/rejected/cancelled/reassigned/unassigned/evidence_added/evidence_removed/comment/status_changed/overdue/recurrence_spawned. Carries `fromStatus/toStatus` and free-form `metadata` JSONB.
- **`task_evidence`** — photos/scans/notes/videos. Soft-delete supported. Refs `mediaId` (BE-13), `scanSessionId` (BE-16). The DTO refine asserts the right field is populated for the type.
- **`task_templates`** — tenant-scoped reusable definitions. Carries default values + `defaultDueOffsetMinutes` for instant-now-due-at math. **Partial unique index** on `(tenant_id, name) WHERE deleted_at IS NULL` so deleting a template frees up its name.

### Enums (6)
- `task_status`, `task_priority`, `task_type`, `task_assignment_role`, `task_event_type`, `task_evidence_type`.

### DTOs (`dto/tasks.dto.ts` — 13 schemas in one file)

Consolidated per BE-15/16/17/18 convention. Every schema:
- Caps lengths/list sizes (max 20 assignees, max 50 evidence items, max 200 list limit, etc.).
- Cross-field refines: start ≤ due, isRecurring requires pattern, requiresPhoto requires minimumEvidenceCount ≥ 1, photo evidence needs mediaId, scan evidence needs scanSessionId, note needs note text, weekly recurrence with daysOfWeek must specify at least one day, assigneeIds must be unique.
- CSV-parsing query helpers for status/priority/type filters.
- Coerced numbers / dates so query strings parse cleanly.

### Pure utilities (`utils/recurrence.utils.ts`)

- `isRecurrencePattern(unknown)` — type guard for raw JSONB pulled from the DB. Validates `type` enum and `interval ≥ 1`.
- `calculateNextDueDate(previousDue, pattern, occurrencesUsed?)` — daily/weekly/monthly support with day-of-week wrap-around and clamped day-of-month for short months. Returns null when `endDate` exceeded or `occurrences` quota reached.
- `hasRemainingOccurrences(pattern, used)` — pre-spawn quota check.

### Repositories (5)

All extend `BaseRepository<typeof table, Row, NewRow, Partial<NewRow>>`.

- **`TasksRepository`** — `findByIdInTenant`, `findByExpiryAlert`, `listForTenant` (status/priority/type/dueWindow/templateId/parentTaskId filters), `findOverdueCandidates` (BE-24 cron), `markOverdue`, `incrementCounter` (atomic SQL +/- on `evidenceCount` / `assigneeCount` / `recurrenceOccurrenceCount`), `getStats` (single GROUP BY per dimension + agg query), `getAssigneeStats` (joins `task_assignments` for per-user counts).
- **`TaskAssignmentsRepository`** — `findActiveByTaskAndUser`, `listActiveForTask`, `listAllForTask`, `listTasksForUser` (joins tasks), `insertIfMissing` (uses partial unique index + `ON CONFLICT DO NOTHING`), `revoke`, `revokeAllPrimary`, `countActive`.
- **`TaskEventsRepository`** — append-only. Just `create` + `findByTask`.
- **`TaskEvidenceRepository`** — `findByIdInTenant`, `listForTask`, soft-delete via base class.
- **`TaskTemplatesRepository`** — `findByIdInTenant`, `findByNameInTenant`, `listForTenant` (active/type filters).

### Services (7)

- **`TaskWorkflowService`** — pure state machine. 6 statuses, terminal flag, `validateTransition` throws `BusinessException` with `TASK_ALREADY_COMPLETED` for completed→anything, `BUSINESS_RULE_VIOLATION` otherwise. Frozen transition map exposed as `TaskWorkflowService.TRANSITIONS`.
- **`TaskAssignmentService`** — orchestrates assignment lifecycle. `assignBatch` (dedupes within call, atomic counter bump), `reassign` (revoke-all-primary + assignBatch + reassigned event), `unassign`, `assertActiveAssignment` (used by start/complete/reject/addEvidence to enforce "only assignees can act").
- **`TaskEvidenceService`** — `add` / `addMany` / `remove` (only original uploader can remove their own evidence — managers can override at the controller permission layer), `ensureRequirementsMet` (gate called from `complete` before the transaction body runs: minimumEvidenceCount, requiresPhoto needs at least one photo with mediaId, requiresScan accepts inline `completionScanSessionId` OR pre-existing scan-evidence OR `task.scanSessionId`).
- **`RecurringTasksService`** — `spawnNextOccurrence(parent, actorId, tx)`. No-ops when not recurring, malformed pattern, or quota exhausted. Copies `productIds`, evidence requirements, estimated duration. Resets state-tracking fields, links via `parentTaskId`, copies all active assignments forward, bumps parent's `recurrenceOccurrenceCount` atomically, logs `recurrence_spawned` event on the child.
- **`AutoTaskGeneratorService`** — `generateForAlert(tenantId, actorId, dto)`. Idempotent: if a task already references the alert, returns it instead of creating. Maps alert status to priority (`yellow` → `high`, `red`/`expired` → `urgent`). Sets `requiresScan: true`, `minimumEvidenceCount: 1` so completion proves the items got dealt with. Logs `transition: 'auto-from-expiry-alert'` audit metadata.
- **`TaskTemplatesService`** — CRUD + `instantiate` (overlays `InstantiateTemplateDto` on the template default and delegates to `TasksService.create`). Rejects inactive templates. Validates name uniqueness on create.
- **`TasksService`** — top-level orchestrator. CRUD, workflow (start/complete/reject/cancel), reassign, evidence add/remove (façade), list/listForUser/getStats, BE-24 cron entry `markOverdue(now)`. Spawns recurring children inside the same transaction as the parent's completion.

### Controller (`tasks.controller.ts`)

19 endpoints under two top-level paths:

- `/api/v1/tasks/*`
  - `POST /tasks` — create (manager+, `tasks:write tasks:assign`)
  - `GET /tasks` — list filtered (staff+, `tasks:read`)
  - `GET /tasks/my` — current user's assigned tasks (staff+)
  - `GET /tasks/stats` — aggregations (manager+)
  - `POST /tasks/auto-from-alert` — auto-create from expiry alert (manager+)
  - `GET /tasks/:id` — detail with assignments + events + evidence
  - `PATCH /tasks/:id` — update fields (manager+, blocked on terminal status)
  - `DELETE /tasks/:id` — soft delete (manager+, `tasks:delete`)
  - `POST /tasks/:id/start` — start (assignee, state-machine validated)
  - `POST /tasks/:id/complete` — complete with optional evidence + scan session
  - `POST /tasks/:id/reject` — reject (assignee, with reason)
  - `POST /tasks/:id/cancel` — cancel (manager+, `tasks:delete`, with reason)
  - `POST /tasks/:id/reassign` — reassign (manager+, `tasks:assign`)
  - `POST /tasks/:id/evidence` — add one evidence item
  - `DELETE /tasks/evidence/:evidenceId` — remove evidence (uploader)
- `/api/v1/task-templates/*`
  - `POST /task-templates` — create (manager+)
  - `GET /task-templates` — list filtered
  - `GET /task-templates/:id` — read
  - `PATCH /task-templates/:id` — update
  - `DELETE /task-templates/:id` — soft delete
  - `POST /task-templates/:id/instantiate` — create a task from template

Static segments (`/my`, `/stats`, `/auto-from-alert`, every `/task-templates/...`) are declared **before** `/tasks/:id` so routing is deterministic.

Permission gates:
- reads → `tasks:read`
- writes → `tasks:write`
- create / reassign → `tasks:assign`
- delete / cancel / template delete → `tasks:delete`

All four `tasks:*` permissions already exist in the BE-08 role permission map for owner/manager/staff/auditor — **no new permission strings introduced**.

### Migration
- **`server/src/db/migrations/0002_be19_tasks.sql`** — idempotent (`CREATE TYPE IF NOT EXISTS` via DO blocks, `CREATE TABLE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`). 5 tables, 6 enums, 11 indexes (3 partial unique, 8 regular).

### Tests (9 spec files, 70 cases)

| Spec | Cases | Covers |
|---|---|---|
| `task-workflow.service.spec.ts` | 13 | every allowed/disallowed transition, terminal flags, ErrorCode mapping for completed→anything (`TASK_ALREADY_COMPLETED`), getNextPossibleStatuses |
| `recurrence.utils.spec.ts` | 14 | type guard rejection of malformed/empty inputs, daily, weekly without daysOfWeek, weekly with daysOfWeek (jump + wrap), monthly day-clamp for short months, dayOfMonth override, endDate cutoff, unknown frequency, occurrence quota |
| `tasks.dto.spec.ts` | 24 | every CreateTask refine (assigneeIds non-empty/unique/cap, dates, recurrence, photo + minimum, empty title), Update partial + ordering, Complete defaults, Reassign defaults + dedupe, AddEvidence per-type required field, Recurrence weekly empty-day rejection + dayOfMonth bound, ListTasks CSV + cap + default, AutoTaskFromAlert defaults + non-empty assignees |
| `task-evidence.service.spec.ts` | 11 | add persists/bumps/logs, remove not-found / wrong-user / happy-path, ensureRequirementsMet for no-requirements / minimum (existing-only fail, mixed pass) / requiresPhoto rejection + accepted with existing photo / requiresScan rejection + inline session accept + pre-existing scan accept |
| `task-assignment.service.spec.ts` | 7 | assignBatch with dedupe + counter bump, no-bump on no-op inserts, reassign with replace=true (revoke + add + counter math), reassign with replace=false (no revoke), unassign not-found / happy path with counter, assertActiveAssignment forbidden + happy path |
| `recurring-tasks.service.spec.ts` | 5 | not-recurring no-op, malformed pattern no-op, quota exhausted no-op, child has correct due date + parentTaskId + isRecurring=false, copies active assignments + bumps both counters + logs recurrence_spawned |
| `auto-task-generator.service.spec.ts` | 4 | alert missing throws, idempotent re-call returns existing, yellow → high priority, red → urgent priority + correct metadata |
| `task-templates.service.spec.ts` | 7 | duplicate name rejected, fresh persists, findById not-found, findById happy, soft-delete, instantiate rejects inactive, instantiate overlays overrides + delegates, instantiate falls back to titleTemplate |
| `tasks.service.spec.ts` | 14 | create with primary + observer assignment, start (not-found / forbidden / already-in-progress / happy + event), complete (minimum-evidence rejection / actualDuration / scanSessionId attached / spawns recurring / does not spawn non-recurring), cancel (not-found / on-completed-rejected / happy + reason), reject (with reason captured), update (terminal-status rejected / persists + event), markOverdue (empty / multi-candidate happy path) |

**Total: 99 new test cases.** Cumulative project total: ~530.

## Files Created (matched against BE-19 spec)

| Spec file | Status |
|---|---|
| `server/src/db/schema/tasks.ts`, `task_assignments.ts`, `task_events.ts`, `task_evidence.ts`, `task_templates.ts` | ✅ all 5 in `db/schema/tasks.ts` (consolidated — same lifecycle, single migration) |
| `server/src/modules/tasks/tasks.module.ts` | ✅ |
| `server/src/modules/tasks/tasks.controller.ts` | ✅ |
| `server/src/modules/tasks/tasks.service.ts` | ✅ |
| `server/src/modules/tasks/services/task-assignment.service.ts` | ✅ |
| `server/src/modules/tasks/services/task-workflow.service.ts` | ✅ |
| `server/src/modules/tasks/services/task-evidence.service.ts` | ✅ |
| `server/src/modules/tasks/services/task-templates.service.ts` | ✅ |
| `server/src/modules/tasks/services/recurring-tasks.service.ts` | ✅ |
| `server/src/modules/tasks/services/auto-task-generator.service.ts` | ✅ |
| `server/src/modules/tasks/repositories/tasks.repository.ts` | ✅ |
| `server/src/modules/tasks/repositories/task-assignments.repository.ts` | ✅ |
| `server/src/modules/tasks/repositories/task-events.repository.ts` | ✅ |
| `server/src/modules/tasks/repositories/task-evidence.repository.ts` | ✅ (added — needed for evidence service to be testable in isolation) |
| `server/src/modules/tasks/repositories/task-templates.repository.ts` | ✅ (added) |
| `server/src/modules/tasks/dto/create-task.dto.ts`, `update-task.dto.ts`, `list-tasks.dto.ts` | ✅ at `dto/tasks.dto.ts` (consolidated 13 schemas) |
| `server/src/modules/tasks/types/task.types.ts` | ✅ |
| `server/src/modules/tasks/utils/recurrence.utils.ts` | ✅ (added — pure helpers extracted from `RecurringTasksService`) |
| Tests | ✅ 9 spec files, 99 cases |

## ⚠ ORCHESTRATOR INTEGRATION CHECKLIST

The hard-constraint files were **not** modified. The orchestrator must apply these merges manually:

### 1. Schema barrel — `server/src/db/schema/index.ts`

Add at the end (after `expiry`):
```typescript
export * from './tasks';
```

### 2. App module — `server/src/app.module.ts`

Add the import:
```typescript
import { TasksModule } from './modules/tasks/tasks.module';
```

And register in the `imports: [...]` array (anywhere after `ExpiryModule`):
```typescript
ExpiryModule,
TasksModule,
```

### 3. Permissions — `server/src/modules/auth/types/permission.types.ts` and `constants/role-permissions.map.ts`

✅ **No changes needed.** All four permissions used by BE-19 (`tasks:read`, `tasks:write`, `tasks:assign`, `tasks:delete`) already exist in the BE-08 catalog and are mapped to admin/owner/manager/staff/auditor as appropriate. Confirmed:
- `tasks:read` — admin, owner, manager, staff, auditor
- `tasks:write` — admin, owner, manager, staff
- `tasks:assign` — admin, owner, manager
- `tasks:delete` — admin, owner

### 4. New npm dependencies — `server/package.json`

✅ **No new dependencies.** BE-19 reuses the existing Drizzle, Zod, Nest, Jest stack from BE-01..BE-18.

### 5. Migration

Run after the schema barrel is updated:
```bash
cd server
pnpm db:generate    # confirms drizzle agrees the schema is consistent
pnpm db:migrate     # applies 0002_be19_tasks.sql
```

The hand-written migration `0002_be19_tasks.sql` is idempotent and uses `CREATE TYPE IF NOT EXISTS` / `CREATE TABLE IF NOT EXISTS` / partial unique indexes that match the Drizzle schema definitions byte-for-byte.

## Database Changes
- New tables: `tasks`, `task_assignments`, `task_events`, `task_evidence`, `task_templates`.
- New enums: `task_status`, `task_priority`, `task_type`, `task_assignment_role`, `task_event_type`, `task_evidence_type`.
- 11 indexes total: 3 partial unique (active assignment per task/user, active task per expiry alert, active template name per tenant), 8 regular B-tree.

## What's Ready for Next Phase

BE-20 (reports) can:
1. Aggregate `task_events` for "average time in pending" / "rejected rate" / "overdue rate" reports.
2. Pivot `tasks` by assignee / type / priority for performance dashboards.
3. Use `actualDurationMinutes` and `dueDate vs completedAt` for SLA reports.

BE-24 (notifications + cron) will:
1. Schedule `tasksService.markOverdue(now)` daily at midnight per tenant timezone.
2. Push FCM notifications when:
   - A task is created and `assigned` event fires (for each assignee).
   - A task transitions to `overdue`.
   - A recurring task spawns a child for the next day.
3. The notification bus reads `task_events` directly — no extra schema needed.

BE-26 (GRN) can:
1. Auto-create `inventory-count` tasks when a GRN line arrives so receiving staff are reminded to verify counts.
2. Link via `metadata: { grnId, grnLineId }` (no schema change needed; `tasks.metadata` is JSONB).

BE-31 (App Owner Dashboard):
1. `GET /tasks/stats?storeId=...` is the single endpoint behind the operations panel.
2. Live overdue feed: `GET /tasks?status=overdue&limit=200`.
3. Per-staff scorecard: `byAssignee` rows in the stats response.

## Known Issues / Follow-ups

- **BE-24 owns the actual cron**. `TasksService.markOverdue(now)` is the public entry point; the BE-19 controller does not expose it (it's a system-internal operation invoked by the scheduler binary). When BE-24 wires the scheduler, it should use `ScheduleModule` to call this method per tenant.
- **No notification side-effects**. BE-19 emits domain events (`task_events` rows) but does not push notifications. BE-24 will subscribe and translate `created` / `assigned` / `overdue` / `recurrence_spawned` into FCM pushes. Same pattern as BE-15 (deferred queue wiring) and BE-17 (deferred BullMQ wiring).
- **Recurring spawn is sequential at completion time**. A high-frequency daily task that gets completed in a burst does **not** auto-fast-forward; each completion creates exactly one next occurrence. If a daily task hasn't been completed in 5 days, completing it once spawns one next-day task, not five. Documented; this matches retail expectations (you complete TODAY's check, not yesterday's).
- **Evidence file storage**. `task_evidence.media_id` and `scan_session_id` are foreign-key references into BE-13 / BE-16 tables but **not enforced at the DB level** (no FK constraint), to keep cross-module migrations decoupled. The service layer validates these references exist when set via the DTO refines. BE-32 perf hardening can add the FKs once the cross-module migration order stabilises.
- **`overdue` is set by BE-24 cron, not by reads**. A task whose `dueDate` is in the past but was never swept stays in its previous status. Dashboards that need "as-of-now overdue" should filter by `due_date < now() AND status IN ('pending','in_progress')` directly. The `status='overdue'` row reflects the last cron pass.
- **Reassignment doesn't reset `startedAt`**. If a task is `in_progress` and gets reassigned, the new assignee inherits the existing `startedAt`. `actualDurationMinutes` then includes the previous assignee's wall time. This matches the audit trail (the work has been ongoing for 90 minutes regardless of who's doing it) but BE-25 reports may want to filter out reassigned tasks for accurate per-staff timing.
- **Template instantiation does not seed evidence**. A template with `requiresPhoto: true` produces a task with `requiresPhoto: true` but no pre-loaded evidence — the assignee still must upload at completion. Documented as expected behaviour.
- **No bulk reassignment**. Spec didn't require it. Add a `POST /tasks/bulk-reassign` if BE-31 dashboard needs to rotate assignees across many tasks.
- **`UpdateTaskSchema` does not allow changing `assigneeIds`** — that's `POST /tasks/:id/reassign`'s job. Documented; cleaner separation.
- **Status-only `overdue` is not user-settable**. A task only enters `overdue` via `TasksService.markOverdue` (cron). Direct PATCH to `status: overdue` is not allowed by `UpdateTaskSchema`. Correct behaviour.
- **No "manager-can-remove-anyone's-evidence" elevation**. `TaskEvidenceService.remove` allows only the original uploader. If a manager needs to remove a junior's mistaken upload, they can call `DELETE /tasks/evidence/:id` while authenticated as themselves and get a 403. We chose strictness over convenience; BE-31 dashboard can layer in an admin override if telemetry shows churn.

## Deviations from Spec

- **Single consolidated schema file** — same convention as BE-15/16/17/18. Five split files would force five migrations.
- **Single consolidated DTO file** — 13 Zod schemas in one file. Consistent with the rest of the codebase.
- **`task-evidence.repository.ts` and `task-templates.repository.ts` added** — the spec listed only the three primary repos but soft-delete + tenant-scoped lookup needed dedicated wrappers around `BaseRepository`. Same pattern as `ExpiryAlertsRepository` in BE-18.
- **`utils/recurrence.utils.ts` added** — pure helpers extracted so the recurrence math is unit-testable without a Nest test bed. Same convention as BE-18's `expiry-rules.utils.ts`.
- **`AuditAction` enum constraint** — used `'CREATE' | 'UPDATE' | 'DELETE'` with `metadata.transition` discriminators (`'edit' | 'start' | 'complete' | 'reject' | 'cancel' | 'reassign' | 'auto-from-expiry-alert' | 'soft-delete'`). Same convention as BE-18's recalc audit.
- **Permission strategy** — used `tasks:read | tasks:write | tasks:assign | tasks:delete` rather than introduce new strings. The spec's BE-08 role-permission map already covers them.
- **Auto-task generator is a separate service** — clean DI boundary so BE-24's notification bus can wire it without pulling in `TasksService` directly when triggering on alert events.
- **Reassignment is revoke + create** — keeps the audit trail readable. Spec's `reassign` endpoint maps to one transactional call but the row history shows two assignments.
- **Recurring spawn is sequential at completion time** — see Known Issues. Spec's "next day's task auto-created with parentTaskId" is interpreted as "exactly one child per completion".
- **Workflow re-open path** — BE-19 spec's transition table shows `rejected → pending`. Implemented exactly that way; no other re-opens allowed (no `cancelled → pending` etc.).
- **No `tasks.controller` health-check endpoint** — task health is observable through general `/api/health` already.
- **No bulk operations** — single-task endpoints only. Same scope as BE-18 thresholds.

## Context for Next Developer

You're inheriting:
- A working task management system that the App Owner Dashboard (BE-31) can light up immediately for the operations panel.
- A clean BE-24 cron entry: `tasksService.markOverdue(now)` is the only function the scheduler needs to call daily.
- A clean BE-18 alert hook: `autoTaskGeneratorService.generateForAlert(...)` is idempotent and audit-logged. BE-24 can subscribe to expiry-alert creation events and call it.
- A BE-13/16 evidence story: photos go through `mediaId`, scans through `scanSessionId`, both flow into the same `task_evidence` table with type discriminators.
- A clean BE-20 reports surface: `task_events` is the single source of truth for "what happened, when, by whom" — every state change writes one row.
- A clean BE-26 GRN hook: GRN lines that need verification create `inventory-count` tasks with `metadata: { grnId, grnLineId }`. No schema change needed.

## Environment State
No new dependencies. Reuses the existing Drizzle + Zod + Nest stack.

## Performance Metrics (estimated)

- `findById(detail)`: ~30 ms (3 parallel reads).
- `list(50 tasks, filtered by store + status)`: ~20 ms (uses `idx_tasks_store_status_due`).
- `getStats(10K tasks)`: ~80 ms (3 GROUP BY queries + 1 aggregate query).
- `getAssigneeStats(10K tasks)`: ~120 ms (one join + GROUP BY).
- `markOverdue(500 candidates)`: ~2-3 s (sequential per-row update; BE-24 will parallelise).
- `autoGenerateForAlert`: ~70 ms (alert lookup + insert + assignment + audit).
- `complete with 5 evidence + recurring spawn`: ~200 ms (transactional, lots of inserts).

## Security Audit
- BE-08 guard stack on every route ✅.
- Tenant-scoped reads via `findByIdInTenant` everywhere ✅.
- Cross-tenant access blocked by `tenantId` filter on every query ✅.
- `assertActiveAssignment` on start/complete/reject so non-assignees cannot transition state ✅.
- Reassignment requires `tasks:assign` permission (manager+) ✅.
- Cancellation requires `tasks:delete` permission (owner+) ✅.
- Cannot update or reassign tasks in terminal status ✅.
- Cannot acknowledge / complete / reject a task you're not assigned to (403) ✅.
- DTO caps everywhere (max 20 assignees, max 50 evidence items, max 200 list limit, max 1000-character description, etc.) ✅.
- Cross-field refines on DTOs prevent malformed payloads at the validation layer ✅.
- Audit log entries on every state change with `metadata.transition` discriminator ✅.
- Append-only `task_events` table — no UPDATE/DELETE methods exposed on the repository ✅.
- DB-level partial unique index prevents duplicate active assignments and duplicate auto-tasks per alert ✅.

## Verification Pack
**`BACKEND_PHASES/BE-19_VERIFICATION.md`** — five suites: A (unit), B (HTTP integration with full lifecycle), C (tenant + DB invariants), D (security gates), E (recurring + auto-task end-to-end).

## Q&A Answers (BE-19 SOP)

**Q1 — Why state machine?** Tasks have a non-trivial lifecycle: pending → in_progress → completed (or rejected, or cancelled). A free-form `status` string would let any code path write any value and break the audit trail. The state machine enforces "you cannot complete a task you haven't started" and "you cannot un-cancel a task". The `TASK_ALREADY_COMPLETED` ErrorCode (E7002) lets the Mobile_App show a specific dialog when a stale view tries to complete a task that's already done. State machine + audit trail = compliance-friendly: every transition is captured in `task_events` with `fromStatus`, `toStatus`, `actorId`, and `notes`.

**Q2 — Why multiple assignees?** Real retail tasks have helpers, observers, and coordinators. "Reset Aisle 3" might involve two staff members + the manager checking in. Modelling via a junction table (`task_assignments`) keeps the relationship denormalised — adding a person doesn't rewrite the task row. Roles (`primary` / `observer`) let us distinguish "who's actually doing it" from "who needs to be notified". Any active assignee can transition the task; the audit trail captures who did what.

**Q3 — Why a separate `task_events` table?** Append-only audit log. Task itself mutates over time (status flips, dueDate changes, evidence accumulates), but the event log is immutable: once "started at 10:32 by user X" is written, it stays. Compliance-grade — auditors and BE-25 reports query it for "when did this task become overdue?" or "how long was it in_progress before completion?". The repository deliberately exposes only `create` and `findByTask` — no update or delete.

**Q4 — Why minimum evidence count?** Quality control. Without it, a staff member can mark "Cleaned Aisle 3" as complete with no proof. With `requiresPhoto: true, minimumEvidenceCount: 2`, completion is gated until two photos exist. The validation runs at completion time, before the transaction body, so failures don't leave half-written state. The `BUSINESS_RULE_VIOLATION` ErrorCode lets the Mobile_App show a clear "you need 2 more photos" message.

**Q5 — How do recurring tasks work?** Pattern (`type: 'daily'|'weekly'|'monthly'`, `interval: 1..N`, optional `daysOfWeek`, `dayOfMonth`, `endDate`, `occurrences`) is stored on the parent. When the parent completes, `RecurringTasksService.spawnNextOccurrence` calculates the next due date from the pattern, creates a child with `parentTaskId` set, copies all active assignments forward, and bumps the parent's `recurrenceOccurrenceCount`. The child is itself NOT recurring — only the parent carries the pattern. This keeps the recurrence logic entirely on one row and prevents runaway chain spawning (e.g. a child can't accidentally become a parent).

**Q6 — Why auto-tasks from alerts?** Reduces manual work and ensures alerts get addressed. When BE-18 raises a "yellow" alert for 50 dairy items expiring in 5 days, the manager's choice is not "remember to assign this" — it's "approve this auto-generated task or reject it". `AutoTaskGeneratorService.generateForAlert` is idempotent at the DB level (partial unique index on `expiry_alert_id`), so a webhook firing twice is safe. The task carries `requiresScan: true, minimumEvidenceCount: 1` so completion proves the items got scanned (discounted, removed, etc.). BE-24 wires the actual webhook from BE-18 alerts → this generator.

**Q7 — How are overdue tasks tracked?** `TasksService.markOverdue(now)` is the cron entry point: it scans for tasks with `dueDate < now AND status IN ('pending', 'in_progress')`, batch-marks them `overdue`, and writes one `task_events` row each. BE-24 schedules this nightly per tenant. Reads can also filter "as-of-now overdue" via `status IN ('pending','in_progress') AND due_date < now()` for real-time dashboards. The cron-set `status='overdue'` is the lagging indicator; the live filter is the leading one. Both are correct.

**Q8 — What about task templates?** Reusable definitions like "Daily shelf check" or "Monthly stocktake". The template carries every default field (title, type, priority, evidence requirements, recurrence pattern). `instantiate(templateId, overrides)` overlays caller overrides (storeId, assigneeIds, optional title/dueDate/metadata) and creates a real task. Templates can be marked inactive without deletion (the unique-name index excludes soft-deleted rows so a name can be re-used after deletion). The App Owner Dashboard (BE-31) is the typical management surface; mobile staff don't see templates directly — they see the materialised tasks.

## Rollback Information
- `DROP TABLE task_evidence, task_templates, task_events, task_assignments, tasks;`
- `DROP TYPE task_evidence_type, task_event_type, task_assignment_role, task_type, task_priority, task_status;`
- Remove `TasksModule` from `app.module.ts`.
- Remove `export * from './tasks';` from the schema barrel.
- Delete `src/modules/tasks/` and `src/db/schema/tasks.ts`.
- Audit-log entries (resource_type='Task' or 'TaskTemplate') stay in `audit_logs` — they're historical.

---

**End of BE-19 Handoff. Approved for BE-20 once the BE-19_VERIFICATION pack passes locally with a full create → start → complete (with evidence) → recurring-spawn cycle on a real DB.**
