# PHASE 09 — Inventory + GRN modules

## Goal
Build Inventory (KPIs, category breakdown, movements, low-stock + rules, stock-in/out/adjust) and
GRN (stats, list, detail with line-item editor and the validate→post→cancel/reverse workflow rail).

## Depends on
Phases 02, 04, 05.

## Doc references
- Doc 1 §6.10 (`/inventory/*`), §6.11 (`/grn/*`), §7.4 (inventory + GRN inward workflow).
- Doc 2 §5.5 (Inventory), §5.6 (GRN), §4.16-style stepper/timeline.
- Doc 3 §A.3.5 (inventory/GRN functions), §A.5 (invalidate inventory+dashboard on GRN post), §B.7.

## Scope (in)
**Inventory** — `app/(dash)/inventory/page.tsx`:
- `features/inventory/inventory.queries.ts` / `.actions.ts`, `.schema.ts`.
- Components: `inventory-kpis.tsx` (summary/category-breakdown/counts), `movements-table.tsx`
  (`/movements`), `low-stock-panel.tsx` (`/low-stock` + rules `/low-stock-rules`),
  `stock-op-panel.tsx` (stock-in/stock-out/adjust drawers, permission-gated).

**GRN** — `app/(dash)/grn/page.tsx` + `app/(dash)/grn/[id]/page.tsx`:
- `features/grn/grn.queries.ts` / `.actions.ts`, `.schema.ts`.
- Components: `grn-stats.tsx` (`/grn/stats`), `grn-table.tsx` (`/grn`, status workflow chips),
  `grn-detail.tsx` (header + workflow rail), `grn-items-editor.tsx` (`/:id/items`),
  `grn-workflow-rail.tsx` (validate→post→cancel/reverse stepper timeline).

## Out of scope
Suppliers (Phase 10 — GRN links to a supplier picker that lands then; here use the existing supplier
ref/id). Sales ledger / GST (out of product V1 scope entirely).

## Step-by-step
1. Inventory KPIs from summary/category-breakdown/counts (mono, count-up).
2. Movements table (`<DataTable>`, mono qty/dates, in/out chips).
3. Low-stock panel + rules view; one orange CTA contextually (e.g. "Stock in").
4. Stock op drawers: stock-in/stock-out (`inventory:write`), adjust (`inventory:adjust`),
   permission-gated; optimistic + invalidate inventory + dashboard caches.
5. GRN list with stats strip + status chips; row → `/grn/[id]`.
6. GRN detail: header + line-item editor (add/patch/delete items) + workflow rail
   validate→post→cancel/reverse; posting invalidates inventory + dashboard (Doc 3 §A.5).
   Breadcrumbs GRN → GRN #id → Item.
7. States: skeletons, empty ("No movements yet"), error retry. Verify.

## API wiring
- Inventory: `GET /inventory/summary`, `/category-breakdown`, `/counts`, `/movements`, `/low-stock`,
  `/low-stock-rules`. `POST /inventory/stock-in`, `/stock-out` (`inventory:write`), `/adjust` (`inventory:adjust`).
- GRN: `GET /grn/stats`, `POST/GET /grn`, `GET/PATCH /grn/:id`, `POST/PATCH/DELETE /grn/:id/items[/:itemId]`,
  `POST /grn/:id/validate|post|cancel|reverse`. Store-scoped.

## Design spec
- Doc 2 §5.5–5.6. Stepper timeline for GRN workflow (vertical connector + node + mono timestamp).
  Status chips (draft/validated/posted/cancelled). Mono qty/amounts/dates. One orange CTA per region.

## Security checks
- Stock ops + GRN workflow permission-gated (`inventory:write|adjust`, `grn:write|post|cancel`); API
  re-enforces. Adjust + reverse + cancel = confirm + audited server-side.
- Store scope on all calls; posting writes audit log (backend). Cache invalidation matches backend.

## Acceptance criteria
- [ ] Inventory KPIs, movements, low-stock + rules render from real endpoints.
- [ ] Stock-in/out/adjust gated correctly; invalidate inventory + dashboard caches.
- [ ] GRN list + stats + detail render; line-item editor CRUD works.
- [ ] Workflow rail validate→post→cancel/reverse functions with confirms; posting updates inventory.
- [ ] All states designed; one orange CTA; `build`+`typecheck` clean; anti-slop passes.

## Verification
- `npm run typecheck && npm run build`.
- User: create a GRN, add items, validate, post (confirm inventory + dashboard update), then reverse;
  perform a stock adjust as manager vs staff (gating); view low-stock panel.

## Rollback note
Additive under `features/inventory/` + `features/grn/` + their pages. No shared-layer/backend changes.
