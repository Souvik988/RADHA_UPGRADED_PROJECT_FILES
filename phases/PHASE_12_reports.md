# PHASE 12 — Reports + exports

## Goal
Build the Reports screen: a report builder (dataset + range + store), an export job with progress
polling, the artefact list with presigned downloads, and re-export of existing reports.

## Depends on
Phases 02, 04, 05.

## Doc references
- Doc 1 §6.13 (`/reports/*`, `/report-files/*`).
- Doc 2 §5.9 (Reports spec), §4.11 (job-progress loading state).
- Doc 3 §A.3.8 (report functions), §A.2 (`exportJob()`), §B.7 (presigned short-TTL URLs).

## Scope (in)
- `app/(dash)/reports/page.tsx` — builder + artefact list.
- `features/reports/reports.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components:
  - `report-builder.tsx` — pick dataset, range, store, format (XLSX/PDF/CSV) → `POST /reports/export`.
  - `export-job-card.tsx` — `exportJob()`: kick export, poll artefact list, show job-progress, then
    enable download.
  - `artefacts-table.tsx` — `GET /reports/:id/files`; presigned download `/download/:format` or
    `/report-files/:id/download`; re-export `/reports/:id/export`.

## Out of scope
Scheduled / emailed reports (🆕, Phase 18). Analytics-specific exports (Phase 13). Building new
backend report types.

## Step-by-step
1. Builder form (RHF+Zod): dataset select, date-range (defaults from global), store scope, format.
   One orange "Generate report" CTA → `POST /reports/export`.
2. On submit, render an `export-job-card` that polls the artefact list until the file is ready
   (throttled poll, backoff on 429); show progress, never a raw spinner.
3. Artefacts table: list files with size/format/created (mono), download via presigned URL, and a
   re-export action for existing reports.
4. States: builder idle, job running (progress), empty ("No reports generated yet"), error retry,
   download-failed toast. Verify.

## API wiring
- `POST /reports/export` (`reports:export`) — ad-hoc export. `POST /reports/:id/export` — re-export.
- `GET /reports/:id/files` — artefacts. `GET /reports/:id/download/:format`,
  `GET /report-files/:id/download` — presigned URLs. Store/tenant-scoped.

## Design spec
- Doc 2 §5.9. Job-progress card (eyebrow + status + mono elapsed). Mono file sizes/timestamps.
  One orange CTA. Download buttons secondary/ghost.

## Security checks
- Export gated to `reports:export` (owner/manager/admin); API re-enforces.
- Downloads use backend presigned short-TTL URLs; never embed credentials or tokens in URLs (§B.7, §B.4).
- Poll throttled + 429 backoff (§B.8). Store/tenant scope on all calls.

## Acceptance criteria
- [ ] Builder generates an export via `POST /reports/export`; job-progress polls to completion.
- [ ] Artefact list shows files; presigned download works; re-export works.
- [ ] Export gated correctly; downloads are presigned (no credentials in URL).
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: generate an XLSX report (watch progress), download it, re-export, and confirm a non-permitted
  role cannot trigger export.

## Rollback note
Additive under `features/reports/` + the page. No shared-layer/backend changes.
