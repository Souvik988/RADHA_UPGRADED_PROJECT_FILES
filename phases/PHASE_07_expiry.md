# PHASE 07 — Expiry module

## Goal
Build the Expiry screen: KPIs (near-expiry / expired / forecast loss), a calendar heat grid,
the records table with status chips, a thresholds editor, and alert acknowledge/resolve — with
add-record + OCR validate.

## Depends on
Phases 02, 04, 05. (06 establishes alert-drill targets.)

## Doc references
- Doc 1 §6.8 (`/expiry-records/*`, `/expiry-thresholds`, `/expiry-alerts/*`, `/expiry/ocr/validate`), §7.2.
- Doc 2 §5.3 (Expiry spec), §4.2/4.5 (table, status chip), §6 (by-category bar).
- Doc 3 §A.3.3 (expiry functions), §B.7 (destructive confirm).

## Scope (in)
- `app/(dash)/expiry/page.tsx` — filter bar (store, status near/expired, category, date-range) +
  zones.
- `features/expiry/expiry.queries.ts` / `.actions.ts` — list, stats, by-category, calendar heat,
  acknowledge/resolve, thresholds get/save, create record, OCR validate.
- `features/expiry/expiry.schema.ts` — Zod for records, stats, thresholds, alerts, OCR.
- `features/expiry/components/`:
  - `expiry-kpis.tsx` — near-expiry, expired, forecast loss (`/stats`, `/stats/by-category`).
  - `expiry-calendar.tsx` — `<CalendarHeat>` day cells dot-coded by density; click → day list.
  - `expiry-table.tsx` — `<DataTable>` of records (`/expiry-records`, `/near-expiry`, `/expired`);
    mono EAN + expiry date + `<StatusChip>`; row → acknowledge/resolve alert.
  - `by-category-bar.tsx` — horizontal bar from `/stats/by-category`.
  - `thresholds-editor.tsx` — manager+ side panel: `GET/PUT /expiry-thresholds`.
  - `add-record-panel.tsx` — `POST /expiry-records`; OCR-assisted MFG/EXP via `/expiry/ocr/validate`.

## Out of scope
Creating tasks from expiry (Tasks phase, via auto-from-alert). Forecast modeling beyond what
`/forecast` returns. Alert-rule thresholds (🆕, Phase 18) — only the existing category thresholds here.

## Step-by-step
1. Filter bar (sticky) wired to query params + store scope + date range.
2. KPI row from stats endpoints (mono, count-up); forecast loss from `/forecast`.
3. Calendar heat grid: fetch density per day; click selects a day → filtered table.
4. Records table: columns EAN (mono), product/token, expiry date (mono), status chip, store; row
   actions acknowledge/resolve → `/expiry-alerts/:id/acknowledge|resolve` with optimistic update.
5. Thresholds editor (manager+ only, permission-gated) in a side panel; save with confirm.
6. Add-record panel: form (RHF+Zod), optional image → `/expiry/ocr/validate` to prefill MFG/EXP;
   submit `POST /expiry-records`. One orange CTA ("Add expiry record").
7. States: skeleton table/calendar, empty ("Nothing expiring in this window — nice and fresh"),
   error retry. Verify.

## API wiring
- `GET /expiry-records`, `/near-expiry`, `/expired`, `/forecast`, `/stats`, `/stats/by-category`,
  `GET /expiry-records/:id`. `POST /expiry-records` (201). `POST /expiry-records/recalculate`.
- `GET/PUT /expiry-thresholds`. `GET /expiry-alerts`, `POST /expiry-alerts/:id/acknowledge|resolve`.
- `POST /expiry/ocr/validate`. All store-scoped.

## Design spec
- Doc 2 §5.3. Status chips: expired→danger, expiring→warn, fresh→success (icon+text, never color
  alone). Calendar dots: orange = this week, warn = next. Mono dates/EANs. One orange CTA.

## Security checks
- Store scope on every call. Thresholds editor + add/recalculate permission-gated (manager+);
  client gate cosmetic, API enforces.
- Acknowledge/resolve write actions audited server-side; show confirm for resolve.
- Honest data: show EAN/token if no product name; never fabricate names.

## Acceptance criteria
- [ ] Filters drive the table/calendar; store scope + date range honored.
- [ ] KPIs + by-category bar + forecast render from real endpoints (mono, count-up).
- [ ] Calendar heat → day list; table acknowledge/resolve works with optimistic update + rollback.
- [ ] Thresholds editor gated to manager+; add-record + OCR prefill works.
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean; anti-slop passes.

## Verification
- `npm run typecheck && npm run build`.
- User: open `/expiry`, filter near/expired, click a calendar day, acknowledge an alert (confirm
  feed/KPI reflects), open thresholds as manager vs staff (gated), add a record with an image.

## Rollback note
Additive under `features/expiry/` + the page (replaces placeholder). No shared-layer/backend changes.
