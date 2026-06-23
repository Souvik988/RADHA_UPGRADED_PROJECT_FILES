# PHASE 08 — Tasks module

## Goal
Build the Tasks screen: a Kanban board (To-do / In-progress / Done) + table toggle, task create
(blank or from template), the full workflow transitions, evidence drawer, and auto-from-alert.

## Depends on
Phases 02, 04, 05. (06 alerts and 07 expiry feed "auto-from-alert".)

## Doc references
- Doc 1 §6.9 (`/tasks/*`, `/task-templates/*`).
- Doc 2 §5.4 (Tasks spec), §4.7 (side panel), §4.8 (modal/confirm).
- Doc 3 §A.3.4 (task functions), §A.5 (optimistic updates), §B.7 (destructive confirm).

## Scope (in)
- `app/(dash)/tasks/page.tsx` — board/table toggle + stats strip + create CTA.
- `features/tasks/tasks.queries.ts` / `.actions.ts` — list, stats, create, update, delete, workflow
  (start/complete/reject/cancel/reassign), templates CRUD + instantiate, auto-from-alert, evidence
  add/remove.
- `features/tasks/tasks.schema.ts` — Zod for task, template, evidence, stats.
- `features/tasks/components/`:
  - `task-board.tsx` — Kanban columns; drag-or-button transitions (optimistic + rollback).
  - `task-table.tsx` — `<DataTable>` alternative view (status chip, assignee, due date mono).
  - `task-stats.tsx` — `/tasks/stats` strip.
  - `task-create-panel.tsx` — side panel: blank (`POST /tasks`) or from template
    (`/task-templates`, `/:id/instantiate`).
  - `task-detail-panel.tsx` — workflow rail (start/complete/reject/cancel/reassign), evidence list
    (`/tasks/:id/evidence`, delete `/tasks/evidence/:id`).
  - `templates-manager.tsx` — templates CRUD (manager+).
  - `auto-from-alert.tsx` — entry used by Overview/Expiry: `POST /tasks/auto-from-alert`.

## Out of scope
Bulk task assign with undo (🆕 batch endpoint, Phase 18 — here only per-item). Cross-store task views
beyond store scope.

## Step-by-step
1. Page: toggle board/table; stats strip; one orange "New task" CTA → create panel.
2. Board: columns from task status; transition via buttons (and optional drag) calling the workflow
   endpoints with optimistic update + rollback on error; reassign opens an assignee picker.
3. Table view: sortable columns (`aria-sort`), mono due dates, status chips.
4. Create panel: RHF+Zod; choose template (instantiate) or blank; assignee + store scoped.
5. Detail panel: workflow rail (permission-gated transitions), evidence upload/list/delete; cancel
   = destructive confirm.
6. Templates manager (manager+): list/create/edit/delete templates.
7. Auto-from-alert hook callable from alert rows (Phase 06/07). States: skeleton columns, empty
   ("No tasks yet — assign your first from an alert or template"), error retry. Verify.

## API wiring
- `GET /tasks`, `/tasks/my`, `/tasks/stats`. `POST /tasks`, `GET/PATCH/DELETE /tasks/:id`.
- `POST /tasks/:id/start|complete|reject|cancel|reassign`. `POST /tasks/auto-from-alert`.
- `POST/GET /task-templates`, `GET/PATCH/DELETE /task-templates/:id`, `POST /task-templates/:id/instantiate`.
- `POST /tasks/:id/evidence`, `DELETE /tasks/evidence/:evidenceId`. Store-scoped.

## Design spec
- Doc 2 §5.4. Status chips per column; mono dates; one orange CTA. Side panels `xl` left radius,
  confirm-on-dismiss-if-dirty. Optimistic transitions feel instant; reduced-motion safe.

## Security checks
- Workflow transitions + templates permission-gated (`tasks:write|assign|delete`); API re-enforces.
- Cancel/delete = confirm dialog (type-to-confirm not needed per-item; reserved for bulk in P18).
- Evidence uploads via presigned/short-TTL where backend provides; no credentials embedded (§B.7).
- Store scope on all calls.

## Acceptance criteria
- [ ] Board + table both render `/tasks`; toggle works; stats strip from `/tasks/stats`.
- [ ] Create (blank + template/instantiate) works; assignee + store scoped.
- [ ] All workflow transitions function with optimistic update + rollback; reassign picker works.
- [ ] Evidence add/remove works; cancel/delete confirm.
- [ ] auto-from-alert callable from alerts. All states designed; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: create a task from a template, move it across columns (confirm persistence), reject/cancel
  with confirm, add then delete evidence, trigger auto-from-alert from an Overview alert.

## Rollback note
Additive under `features/tasks/` + the page. No shared-layer/backend changes.
