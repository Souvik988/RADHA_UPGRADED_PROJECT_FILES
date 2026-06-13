# PHASE 11 — Audit / EAN lists + scan sessions

## Goal
Build the Audit/EAN screen: approved-list management with activate/deactivate, an import wizard with
progress + error report, the items table, an EAN match-rate KPI, and scan-session review.

## Depends on
Phases 02, 04, 05.

## Doc references
- Doc 1 §6.6 (`/ean-lists/*`), §6.7 (`/scan-sessions/*`), §7.3 (approved-list audit workflow).
- Doc 2 §5.8 (Audit/EAN spec), §4.2 (table), §4.11 (wizard states).
- Doc 3 §A.3.7 (audit/EAN functions), §B.7 (destructive confirm).

## Scope (in)
- `app/(dash)/audit/page.tsx` — lists table + match-rate KPI + scan sessions tab.
- `features/audit/audit.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components:
  - `ean-lists-table.tsx` (`/ean-lists`) with active toggle (`/:id/activate|deactivate`).
  - `import-wizard.tsx` — create list → `POST /ean-lists/:id/import` (Excel/CSV); progress from
    `/imports/:batchId`; error report `/errors`, download `/errors/csv`; cancel `/imports/:batchId/cancel`.
  - `ean-items-table.tsx` (`/:id/items`).
  - `match-rate-kpi.tsx` — EAN match-rate (from dashboard KPI `eanMatchRate`) + `ean_mismatch_spike`
    alert tie-in.
  - `scan-sessions.tsx` — review `/scan-sessions`, `/active`, `/:id`, sync batches `/sync-batches`,
    `/sync-batches/:batchId`, cancel `/sync-batches/:batchId/cancel`.
  - `list-create-edit.tsx` — create/patch/delete list.

## Out of scope
On-device scanning (mobile app). Editing scan-session items from the dashboard (read/review only,
plus batch cancel). Cross-store audit rollups (store scope only).

## Step-by-step
1. Lists table with active toggle (confirm on deactivate), mono counts; create/edit/delete (gated).
2. Import wizard: stepper (create → upload → processing → results); poll `/imports/:batchId`;
   surface error count + "Download error CSV"; allow cancel.
3. Items table for a selected active list (`/:id/items`), mono EAN.
4. Match-rate KPI + alert tie-in (links to Overview `ean_mismatch_spike`).
5. Scan sessions tab: list/active/detail + sync-batch monitoring + cancel.
6. States: skeletons, empty ("No approved lists yet — import your first"), error retry, wizard
   error report. Verify.

## API wiring
- `POST/GET /ean-lists`, `GET /ean-lists/:id`, `/:id/items`, `PATCH/DELETE /ean-lists/:id`,
  `POST /ean-lists/:id/activate|deactivate|import`, `POST /ean-lists/validate|validate/batch`,
  `GET /ean-lists/imports/:batchId`, `/errors`, `/errors/csv`, `POST /imports/:batchId/cancel`.
- `GET /scan-sessions`, `/active`, `/:id`, `/sync-batches`, `/sync-batches/:batchId`,
  `POST /scan-sessions`, `/sync-batches/:batchId/cancel`. Store-scoped.

## Design spec
- Doc 2 §5.8. Active list = success chip; import progress card (job-progress, not raw spinner).
  Mono EANs/counts. One orange CTA (Import list). Error report table with download.

## Security checks
- List write/activate + import permission-gated (owner/manager/admin); API re-enforces.
- Import: client validates file type/size; backend validates; error CSV is presigned short-TTL.
- Deactivate/delete = confirm + audit. Store scope on all calls.

## Acceptance criteria
- [ ] Lists table + active toggle work; create/edit/delete gated.
- [ ] Import wizard uploads, shows progress + error report, supports cancel + error-CSV download.
- [ ] Items table + match-rate KPI render; scan-session review + batch cancel work.
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean; anti-slop passes.

## Verification
- `npm run typecheck && npm run build`.
- User: create a list, import a CSV (watch progress, download error CSV if errors), activate it,
  view items + match-rate, then review a scan session and cancel a sync batch.

## Rollback note
Additive under `features/audit/` + the page. No shared-layer/backend changes.
