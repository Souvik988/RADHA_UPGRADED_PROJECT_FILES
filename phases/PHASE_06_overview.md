# PHASE 06 — Overview / Command Centre

## Goal
Build the Overview home screen: KPI bento, OHS gauge + trends, alerts panel with drill/actions,
team + activity feed, and the owner-only multi-store rollup — the daily command centre.

## Depends on
Phases 02 (primitives), 04 (shell/store-scope/date-range), 05 (API client).

## Doc references
- Doc 1 §6.1 (`/dashboard/*` catalog + KPI/alert/OHS shapes), §7.1 (owner load workflow).
- Doc 2 §5.1 (Overview spec), §6 (charts), §4.1/4.6 (KPI tile, OHS gauge).
- Doc 3 §A.3.2 (overview functions), §A.5 (caching).

## Scope (in)
- `app/(dash)/page.tsx` — Overview; header "Good morning, {name}" + store switcher + date-range +
  one "Generate report" CTA.
- `features/overview/overview.queries.ts` — `loadOverview(storeId, range)` (single `/dashboard` or
  granular calls), `loadMultiStore()`.
- `features/overview/components/`:
  - `kpi-bento.tsx` — 4 KPI tiles (Scans today · Expiring next 7d · Pending tasks · Low-stock) from
    `kpis` + trend chips from `kpis.trends`.
  - `ohs-card.tsx` — `<OhsGauge>` from `/dashboard/health-score` + 6-component breakdown.
  - `trend-card.tsx` — 30d line from `/dashboard/trends` (scans/expiry/tasks/inventory toggle).
  - `alerts-panel.tsx` — critical/warning/info from `/dashboard/alerts`; each row drills via
    `actionUrl`; inline "Create task" → routes to Tasks auto-from-alert (wired in Phase 08).
  - `team-card.tsx` — top scanners / task leaders from `/dashboard/team`.
  - `activity-feed.tsx` — `<ActivityItem>` list from `/dashboard/activity?limit=`.
  - `multi-store-grid.tsx` — owner "All stores": store cards w/ mini-KPIs + health from
    `/dashboard/multi-store`; click → that store's overview.
- `features/overview/overview.schema.ts` — Zod for KPI/alert/OHS/trend/team/activity payloads.

## Out of scope
Deep expiry/tasks/inventory screens (their phases). "Create task" only routes; the task action lands
in Phase 08. Saved views / cross-store compare are 🆕 (Phase 18).

## Step-by-step
1. Header with `<PageHeader>` (greeting from `useSession`, one orange "Generate report" CTA →
   `/reports`). Respect global store scope + date range.
2. Z1 KPI bento: 4 `<KpiTile>` (mono count-up, trend chips). Grid 4→2→1 responsive.
3. Z2 two-up: OHS gauge card + trend line card (token-themed Recharts, reduced-motion safe).
4. Z3 alerts panel: group by severity; row → `actionUrl`; inline create-task affordance.
5. Z4 team + activity two-up.
6. Multi-store: when store switcher = "All stores" (owner), render `multi-store-grid` instead of the
   single-store body; card click sets `?storeId=` and returns to single view.
7. All states: skeleton bento/cards, empty ("No activity yet — once your team scans, it shows here"),
   error retry per widget (independent). Verify.

## API wiring
- `GET /api/v1/dashboard?storeId=&from=&to=` (composite) **or** granular:
  `GET /dashboard/kpis`, `/alerts`, `/quick-actions`, `/trends`, `/team`, `/activity?limit=`,
  `/health-score`. `GET /dashboard/multi-store` (owner only). `storeId` UUID required (except multi-store).
- KPI shape, AlertItem types, and OHS components per Doc 1 §6.1.

## Design spec
- Doc 2 §5.1 zones. Mono numbers count up; one orange CTA (Generate report). Category tints on KPI
  tiles (amber/violet/green/teal) ≤12%. Big breaths between zones (32–48px). Eyebrow per zone.
- Charts: low-contrast gridlines, accent series, tooltip keyboard-reachable, empty/error.

## Security checks
- Every call carries the scoped `storeId` from `useStoreScope` (never outside `session.storeIds`).
- Multi-store gated to `owner` (and admin) — `manager/staff/auditor` don't see it (server + client).
- Honest data: render only returned names/numbers; alert `count` and titles verbatim.

## Acceptance criteria
- [ ] Overview renders KPIs, OHS gauge, trends, alerts, team, activity for the selected store/range.
- [ ] Owner "All stores" shows the multi-store grid; non-owners never see it.
- [ ] Alert rows drill via `actionUrl`; "Create task" routes correctly.
- [ ] All widgets have loading/empty/error states independently. One orange CTA only.
- [ ] `build`+`typecheck` clean; anti-slop gate passes.

## Verification
- `npm run typecheck && npm run build`.
- User (dev backend up): load `/` for a store; change store + date range and confirm refetch; switch
  to "All stores" as owner; force an error (stop backend) to see retry states.

## Rollback note
Additive under `features/overview/` + `(dash)/page.tsx` (replaces the Phase 04 placeholder — keep a
copy to restore). No backend or shared-layer changes.
