# BE-19 Verification Pack — Task Assignment & Workflow

> Run after `pnpm db:migrate`. Five suites: A (unit), B (HTTP integration), C (tenant + DB invariants), D (security gates), E (recurring + auto-task end-to-end).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...        # tenant owner
MANAGER_TOKEN=...      # tenant manager
STAFF1_TOKEN=...       # tenant staff #1 (will be primary assignee)
STAFF2_TOKEN=...       # tenant staff #2 (will be reassigned to)
B_TOKEN=...            # tenant B (cross-tenant tests)
STORE_ID=...           # store under tenant A
PRODUCT_ID=...         # product visible to tenant A
ALERT_ID=...           # an active expiry_alert under tenant A
STAFF1_ID=...          # user id corresponding to STAFF1_TOKEN
STAFF2_ID=...          # user id corresponding to STAFF2_TOKEN
```

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/tasks/__tests__
```

**Expect**:
- `task-workflow.service.spec.ts` — 13 cases.
- `recurrence.utils.spec.ts` — 14 cases.
- `tasks.dto.spec.ts` — 24 cases.
- `task-evidence.service.spec.ts` — 11 cases.
- `task-assignment.service.spec.ts` — 7 cases.
- `recurring-tasks.service.spec.ts` — 5 cases.
- `auto-task-generator.service.spec.ts` — 4 cases.
- `task-templates.service.spec.ts` — 7 cases.
- `tasks.service.spec.ts` — 14 cases.

**Total**: 99 new cases. Cumulative project total ≈ 530.

## Suite B — HTTP integration

### B1 — Create task (manager assigns staff)

```bash
DUE=$(date -u -d '+2 days' +%Y-%m-%dT%H:%M:%SZ)
curl -s -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Check Aisle 3 expiries\",
    \"type\": \"expiry-check\",
    \"priority\": \"high\",
    \"storeId\": \"$STORE_ID\",
    \"assigneeIds\": [\"$STAFF1_ID\"],
    \"dueDate\": \"$DUE\",
    \"requiresPhoto\": true,
    \"minimumEvidenceCount\": 1
  }" | jq
```
**Expect**: HTTP 201, `status: "pending"`, `assigneeCount: 1`. Task event row inserted:
```sql
SELECT type, to_status FROM task_events WHERE task_id = '<TASK_ID>' ORDER BY created_at;
-- ('created', 'pending')
-- ('assigned', NULL)  -- one per assignee
```

### B2 — Start task (assignee)

```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/start" \
  -H "Authorization: Bearer $STAFF1_TOKEN" | jq
```
**Expect**: HTTP 200, `status: "in_progress"`, `startedAt` populated. New `task_events` row with `type='started'`, `from_status='pending'`, `to_status='in_progress'`.

### B3 — Complete fails when minimum evidence not met

```bash
curl -i -X POST "$HOST/api/v1/tasks/$TASK_ID/complete" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expect**: HTTP 422, `code: "E7000"`, message mentions minimum evidence required.

### B4 — Add evidence

```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/evidence" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"photo\", \"mediaId\": \"$MEDIA_ID\"}" | jq
```
**Expect**: HTTP 201, evidence row created. Task `evidenceCount` increments to 1.

### B5 — Complete with evidence inline

```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/complete" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notes": "Discounted 12 items"}' | jq
```
**Expect**: HTTP 200, `status: "completed"`, `completedAt` set, `actualDurationMinutes >= 0`. New `task_events` row with `type='completed'`, `metadata.actualDurationMinutes` recorded.

### B6 — List my tasks

```bash
curl -s "$HOST/api/v1/tasks/my?status=pending,in_progress" \
  -H "Authorization: Bearer $STAFF1_TOKEN" | jq '. | length'
```
**Expect**: ≥ 0; should not include the just-completed task.

### B7 — Reassign

Create a new task, then:
```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/reassign" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"assigneeIds\": [\"$STAFF2_ID\"], \"role\": \"primary\", \"reason\": \"Staff1 on leave\"}" | jq
```
**Expect**: HTTP 200. Old assignment now has `revokedAt` set, new assignment is active:
```sql
SELECT assignee_id, revoked_at, revoked_reason FROM task_assignments WHERE task_id = '<TASK_ID>';
-- (staff1, <timestamp>, 'Staff1 on leave')
-- (staff2, NULL, NULL)
```
A `task_events` row with `type='reassigned'` is added.

### B8 — Reject by assignee

Create a fresh task assigned to STAFF1, start it, then:
```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/reject" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Wrong store assigned"}' | jq
```
**Expect**: HTTP 200, `status: "rejected"`. Re-opening:
```bash
curl -s -X PATCH "$HOST/api/v1/tasks/$TASK_ID" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description": "still need to check"}' | jq
```
**Expect**: HTTP 422 — cannot update terminal status. (Reopen via `PATCH status` is not exposed; if needed, BE-19 only allows `rejected → pending` through a state-machine path that we haven't surfaced as an endpoint. Documented as a deferral.)

### B9 — Cancel

```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/cancel" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "duplicate"}' | jq
```
**Expect**: HTTP 200, `status: "cancelled"`. `task_events` row with `type='cancelled', notes='duplicate'`.

### B10 — Stats

```bash
curl -s "$HOST/api/v1/tasks/stats?storeId=$STORE_ID" \
  -H "Authorization: Bearer $MANAGER_TOKEN" | jq
```
**Expect**:
```json
{
  "storeId": "...",
  "total": <N>,
  "byStatus": { "pending": ..., "in_progress": ..., "completed": ..., ... },
  "byPriority": { ... },
  "byType": { ... },
  "byAssignee": [ { "userId": "...", "total": ..., "completed": ... }, ... ],
  "averageCompletionMinutes": ...,
  "onTimeRate": 0.0..1.0
}
```

### B11 — Auto-task from expiry alert

```bash
curl -s -X POST "$HOST/api/v1/tasks/auto-from-alert" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"alertId\": \"$ALERT_ID\",
    \"storeId\": \"$STORE_ID\",
    \"assigneeIds\": [\"$STAFF1_ID\"],
    \"dueOffsetMinutes\": 1440
  }" | jq
```
**Expect**: HTTP 201, task with `expiryAlertId` set, `priority='urgent'` (red alert) or `'high'` (yellow). Re-running the same call returns the same task id (idempotent).

### B12 — Templates

```bash
TEMPLATE=$(curl -s -X POST "$HOST/api/v1/task-templates" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Daily shelf check",
    "type": "shelf-audit",
    "titleTemplate": "Daily shelf check",
    "priority": "medium",
    "defaultDueOffsetMinutes": 1440,
    "requiresPhoto": false,
    "requiresScan": false,
    "minimumEvidenceCount": 0,
    "isRecurring": true,
    "recurrencePattern": {"type": "daily", "interval": 1}
  }' | jq -r '.id')

curl -s -X POST "$HOST/api/v1/task-templates/$TEMPLATE/instantiate" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"storeId\": \"$STORE_ID\", \"assigneeIds\": [\"$STAFF1_ID\"]}" | jq
```
**Expect**: HTTP 201, real task with `templateId` set, `dueDate ≈ now + 24h`, `isRecurring: true`.

## Suite C — Tenant + DB invariants

### C1 — Cross-tenant task access blocked

```bash
curl -i "$HOST/api/v1/tasks/$A_TASK_ID" -H "Authorization: Bearer $B_TOKEN"
```
**Expect**: HTTP 404 (tenant filter blocks the read).

### C2 — Active assignment uniqueness

Force a duplicate via raw SQL:
```sql
INSERT INTO task_assignments (task_id, assignee_id, tenant_id, role, assigned_by)
VALUES ('<TASK>', '<USER>', '<TENANT>', 'primary', '<MANAGER>');
INSERT INTO task_assignments (task_id, assignee_id, tenant_id, role, assigned_by)
VALUES ('<TASK>', '<USER>', '<TENANT>', 'primary', '<MANAGER>');
```
**Expect**: second INSERT fails with `duplicate key value violates unique constraint "idx_task_assignments_active_uniq"`.

After revoking the first row (`UPDATE task_assignments SET revoked_at = now() WHERE id = ...`), inserting the same `(task, user)` again succeeds — partial index excludes revoked rows.

### C3 — Active task per expiry alert uniqueness

```sql
INSERT INTO tasks (tenant_id, store_id, title, type, expiry_alert_id, status)
VALUES ('<T>', '<S>', 'a', 'expiry-check', '<ALERT>', 'pending');
INSERT INTO tasks (tenant_id, store_id, title, type, expiry_alert_id, status)
VALUES ('<T>', '<S>', 'b', 'expiry-check', '<ALERT>', 'pending');
```
**Expect**: second INSERT fails with `duplicate key value violates unique constraint "idx_tasks_expiry_alert_active_uniq"`.

After soft-deleting the first (`UPDATE tasks SET deleted_at = now() WHERE ...`), inserting the second succeeds.

### C4 — Template name uniqueness per tenant

```sql
INSERT INTO task_templates (tenant_id, name, type, title_template) VALUES ('<T>', 'X', 'cleaning', 'X');
INSERT INTO task_templates (tenant_id, name, type, title_template) VALUES ('<T>', 'X', 'cleaning', 'X');
```
**Expect**: second INSERT fails. After soft-deleting the first row, re-inserting succeeds.

### C5 — Cascade on task delete

```sql
DELETE FROM tasks WHERE id = '<TASK_ID>';
SELECT count(*) FROM task_assignments WHERE task_id = '<TASK_ID>';
SELECT count(*) FROM task_events WHERE task_id = '<TASK_ID>';
SELECT count(*) FROM task_evidence WHERE task_id = '<TASK_ID>';
```
**Expect**: all three counts = 0 (FK cascades). In production we use soft-delete; this hard-DELETE path is for ops cleanup only.

## Suite D — Security gates

### D1 — Free Consumer cannot create tasks

```bash
curl -i -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $FREE_CONSUMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"x\",\"type\":\"cleaning\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"]}"
```
**Expect**: HTTP 403 (`tasks:write` and `tasks:assign` both missing).

### D2 — Staff cannot create tasks (tasks:assign required)

```bash
curl -i -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"x\",\"type\":\"cleaning\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"]}"
```
**Expect**: HTTP 403 (staff has `tasks:write` but not `tasks:assign`).

### D3 — Non-assignee cannot start task

Task created and assigned to STAFF1; STAFF2 tries to start:
```bash
curl -i -X POST "$HOST/api/v1/tasks/$TASK_ID/start" \
  -H "Authorization: Bearer $STAFF2_TOKEN"
```
**Expect**: HTTP 403, `code: "E4000"`, message "You are not assigned to this task".

### D4 — Staff cannot cancel (tasks:delete required)

```bash
curl -i -X POST "$HOST/api/v1/tasks/$TASK_ID/cancel" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason":"x"}'
```
**Expect**: HTTP 403.

### D5 — Cannot complete task in pending status

```bash
# Task in 'pending', skip start, try to complete
curl -i -X POST "$HOST/api/v1/tasks/$PENDING_TASK_ID/complete" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```
**Expect**: HTTP 422, error mentions cannot transition pending → completed.

### D6 — Cannot update completed task

```bash
curl -i -X PATCH "$HOST/api/v1/tasks/$COMPLETED_TASK_ID" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "new title"}'
```
**Expect**: HTTP 422, error mentions terminal status.

### D7 — DTO validation rejects malformed evidence

```bash
# Photo evidence without mediaId
curl -i -X POST "$HOST/api/v1/tasks/$TASK_ID/evidence" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type": "photo"}'
```
**Expect**: HTTP 400, validation details mention `mediaId`.

```bash
# Recurring without pattern
curl -i -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"x\",\"type\":\"cleaning\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"],\"isRecurring\":true}"
```
**Expect**: HTTP 400, mentions `recurrencePattern is required`.

```bash
# requiresPhoto without minimumEvidenceCount >= 1
curl -i -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"x\",\"type\":\"cleaning\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"],\"requiresPhoto\":true}"
```
**Expect**: HTTP 400.

### D8 — Auto-task generator requires tasks:write + tasks:assign

```bash
curl -i -X POST "$HOST/api/v1/tasks/auto-from-alert" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"alertId\":\"$ALERT_ID\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"]}"
```
**Expect**: HTTP 403.

## Suite E — Recurring + auto-task end-to-end

### E1 — Daily recurring task spawns child on completion

1. Create a recurring daily task due tomorrow:
```bash
DUE=$(date -u -d '+1 day' +%Y-%m-%dT%H:%M:%SZ)
TASK_ID=$(curl -s -X POST "$HOST/api/v1/tasks" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Daily shelf check\",
    \"type\": \"shelf-audit\",
    \"storeId\": \"$STORE_ID\",
    \"assigneeIds\": [\"$STAFF1_ID\"],
    \"dueDate\": \"$DUE\",
    \"isRecurring\": true,
    \"recurrencePattern\": {\"type\": \"daily\", \"interval\": 1}
  }" | jq -r '.id')
```
2. Start + complete:
```bash
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/start" -H "Authorization: Bearer $STAFF1_TOKEN"
curl -s -X POST "$HOST/api/v1/tasks/$TASK_ID/complete" \
  -H "Authorization: Bearer $STAFF1_TOKEN" \
  -H "Content-Type: application/json" -d '{}'
```
3. Verify child:
```sql
SELECT id, due_date, parent_task_id, is_recurring, recurrence_pattern
FROM tasks WHERE parent_task_id = '<TASK_ID>';
-- one row, due_date = parent due + 1 day, parent_task_id = <TASK_ID>, is_recurring = false
```
4. Verify counter:
```sql
SELECT recurrence_occurrence_count FROM tasks WHERE id = '<TASK_ID>';
-- 1
```
5. Verify spawn event:
```sql
SELECT type FROM task_events WHERE task_id = '<CHILD_ID>' AND type = 'recurrence_spawned';
-- one row
```
6. Verify assignment forwarded:
```sql
SELECT assignee_id FROM task_assignments WHERE task_id = '<CHILD_ID>' AND revoked_at IS NULL;
-- $STAFF1_ID
```

### E2 — Auto-task from expiry alert end-to-end

1. Pick an active red alert from BE-18:
```sql
SELECT id, status, days_remaining, quantity
FROM expiry_alerts
WHERE tenant_id = '<TENANT>' AND status = 'red' AND is_resolved = false
LIMIT 1;
```
2. Generate task:
```bash
TASK_ID=$(curl -s -X POST "$HOST/api/v1/tasks/auto-from-alert" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"alertId\":\"$ALERT_ID\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"]}" | jq -r '.id')
```
3. Verify task fields:
```sql
SELECT priority, requires_scan, minimum_evidence_count, expiry_alert_id, metadata
FROM tasks WHERE id = '<TASK_ID>';
-- priority='urgent' (red), requires_scan=true, minimum_evidence_count=1, expiry_alert_id=<ALERT_ID>,
-- metadata = { generator: 'expiry-alert', alertStatus: 'red', ... }
```
4. Idempotency check — re-call with same alertId:
```bash
TASK_ID2=$(curl -s -X POST "$HOST/api/v1/tasks/auto-from-alert" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"alertId\":\"$ALERT_ID\",\"storeId\":\"$STORE_ID\",\"assigneeIds\":[\"$STAFF1_ID\"]}" | jq -r '.id')
test "$TASK_ID" = "$TASK_ID2" && echo "idempotent ✓"
```

### E3 — Overdue cron simulation

1. Manually backdate a pending task to yesterday:
```sql
UPDATE tasks SET due_date = now() - interval '1 day' WHERE id = '<TASK_ID>' AND status = 'pending';
```
2. Invoke the sweep from a Nest test runner or via the BE-24 scheduler harness:
```typescript
// in a test or a one-off script
await tasksService.markOverdue(new Date());
```
3. Verify:
```sql
SELECT status, overdue_marked_at FROM tasks WHERE id = '<TASK_ID>';
-- status='overdue', overdue_marked_at=<now>

SELECT type, from_status, to_status FROM task_events WHERE task_id = '<TASK_ID>' AND type = 'overdue';
-- ('overdue', 'pending', 'overdue')
```
4. Verify the cron is idempotent — re-invoke and the row stays at one `overdue` event (because `markOverdue` only matches `status IN ('pending','in_progress')`, the second call is a no-op).

### E4 — Audit trail end-to-end

For a task that went pending → in_progress → completed with one piece of evidence and was reassigned once before completion:
```sql
SELECT type, actor_id, from_status, to_status, notes, metadata
FROM task_events
WHERE task_id = '<TASK_ID>'
ORDER BY created_at;
```
**Expect** rows in order:
1. `created` (manager)
2. `assigned` (manager) — once per assignee
3. `reassigned` (manager) with `metadata.revokedCount`/`addedCount`
4. `assigned` for the new assignee
5. `started` (assignee)
6. `evidence_added`
7. `completed` (assignee) with `metadata.actualDurationMinutes`

## Final sign-off

- [ ] Suite A: 99 unit cases pass
- [ ] Suite B: 12 HTTP integration scenarios pass on a real DB
- [ ] Suite C: 5 tenant + DB invariants verified in psql
- [ ] Suite D: 8 security gates fire correctly
- [ ] Suite E: 4 end-to-end scenarios pass (recurring spawn, auto-task idempotency, overdue cron, audit trail)

**Verified by**: ___________________________
**Date**: ___________________________
