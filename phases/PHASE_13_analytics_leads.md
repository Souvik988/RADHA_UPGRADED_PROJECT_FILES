# PHASE 13 — Analytics + Leads

## Goal
Build Analytics (website stats + funnel + tenant app activity) and Leads (pipeline table/Kanban,
detail, status update, convert-to-tenant).

## Depends on
Phases 02, 04, 05.

## Doc references
- Doc 1 §6.15 (`/analytics/*`, `/marketing/leads/*`), §7.6 (admin converts leads).
- Doc 2 §5.10 (Analytics & Leads spec), §6 (funnel/line/KPI charts).
- Doc 3 §A.3.9 (analytics/leads functions).

## Scope (in)
- `app/(dash)/analytics/page.tsx` — website stats + funnel + conversion KPIs + tenant activity.
- `app/(dash)/leads/page.tsx` — leads pipeline (table + Kanban-by-status) + detail panel.
- `features/analytics/*` and `features/leads/*` (queries/actions/schema/components).
- Components: `funnel-chart.tsx` (`/analytics/funnel`), `traffic-line.tsx` + `conversion-kpis.tsx`
  (`/analytics/website/stats`, `/website/funnel`), `tenant-activity.tsx` (`/analytics/app/tenant`),
  `leads-table.tsx` / `leads-kanban.tsx` (`/marketing/leads`), `lead-detail-panel.tsx` (`/leads/:id`,
  `PATCH` status/notes), `convert-lead.tsx` (`/leads/:id/convert`).

## Out of scope
Cross-store compare + cohorts (🆕, Phase 18). Per-user app activity (`/analytics/app/me`) beyond a
link. Editing website analytics source.

## Step-by-step
1. Analytics page (owner/admin): funnel chart, traffic line, conversion KPI tiles (mono), tenant app
   activity panel. Date-range driven.
2. Leads page (owner/admin): pipeline table + Kanban toggle grouped by status; row → detail panel.
3. Detail panel: lead info, status update (`PATCH`), notes; convert → tenant with confirm (audited).
4. States: skeleton charts/table, empty ("No leads in this range"), error retry. Verify.

## API wiring
- `GET /analytics/website/stats`, `/website/funnel`, `/funnel` (owner, admin), `/analytics/app/tenant`.
- `POST /analytics/app/events`, `/events/batch` (for the dashboard's own usage telemetry, optional).
- `GET /marketing/leads`, `/leads/:id`, `PATCH /marketing/leads/:id`, `POST /leads/:id/convert`.

## Design spec
- Doc 2 §5.10 + §6. Funnel chart, smooth traffic line (area ≤10%), mono conversion numbers. Lead
  status chips. One orange CTA (Convert lead) on detail. Charts: legend toggle, keyboard tooltips,
  data-table fallback, empty/error.

## Security checks
- Analytics + leads gated to owner/admin (server + client); API re-enforces.
- Convert-lead is a sensitive mutation → confirm + audited server-side.
- Honest data: render only returned funnel/lead numbers; no fabricated metrics. Mask partial PII in
  lead contact columns where appropriate (§B.9).

## Acceptance criteria
- [ ] Analytics renders funnel + traffic + conversion KPIs + tenant activity (owner/admin only).
- [ ] Leads table + Kanban render; detail panel updates status/notes; convert works with confirm.
- [ ] All states designed; one orange CTA per region; charts have data fallback.
- [ ] `build`+`typecheck` clean; anti-slop passes.

## Verification
- `npm run typecheck && npm run build`.
- User (owner/admin): view analytics for a range, open a lead, change its status, add a note, convert
  it (confirm). Confirm a manager cannot reach these pages.

## Rollback note
Additive under `features/analytics/` + `features/leads/` + pages. No shared-layer/backend changes.
