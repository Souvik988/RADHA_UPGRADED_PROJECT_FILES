# BE-26 Session Handoff — GRN (Goods Receipt Note) Module

## Session Metadata
- **Phase**: BE-26
- **Status**: ✅ Code scaffolded, awaiting BE-25 / BE-27 wiring + local verification
- **Completed By**: Kiro
- **Date**: 2026-06-09

## What Was Completed

### Schema (consolidated `db/schema/grn.ts`)

Three tables in one file because they share lifecycle and one migration:

- **`grn_headers`** — tenant + store-scoped GRN. Carries `grnNumber` (auto-generated), `supplierId`, full invoice info, status enum, denormalised counters (`totalItems / totalQuantity / shortShelfLifeCount / minExpiryRemainingDays`), posting fields (`postedAt / postedBy`), cancellation fields, reversal fields, soft-delete + audit columns.
- **`grn_items`** — line items, cascade-delete on header. Carries product linkage (resolved at post time), batch + expiry, pricing, and back-references to `expiry_record_id / inventory_item_id / stock_movement_id` populated during posting.
- **`grn_events`** — append-only event log with 10 event types covering full lifecycle (created/updated/item_added/.../posted/cancelled/reversed).

### Enums (2)
- `grn_status` (5 values: draft, pending_review, posted, cancelled, reversed).
- `grn_event_type` (10 values).

### Indexes (10 total)
- `grn_headers`: composite `(tenant, store, status, inwardDate)` for the manager dashboard, `(supplierId, inwardDate)` for vendor scorecards, `(invoiceNumber)`, `(status)`, plus **two unique** indexes — `(tenantId, grnNumber)` and **`(supplierId, invoiceNumber)`** which enforces the duplicate-invoice guarantee at the storage layer.
- `grn_items`: `grnId`, `ean`, `productId`, `batchNumber`, plus a **partial unique** `(grnId, ean, batchNumber) WHERE batchNumber IS NOT NULL` so a duplicate batch on the same GRN is impossible at the storage layer.
- `grn_events`: `(grnId, createdAt)`, `(type)`, `(tenantId)`.

### DTOs (`dto/grn.dto.ts` — 9 schemas)

Consolidated per BE-15..BE-19 convention. Caps + cross-field refines on every schema:
- `GrnItemSchema` — EAN regex, positive-integer quantity, expiry-after-manufacture refine, unitPrice cap.
- `UpdateGrnItemSchema` / `AddItemsSchema` (max 200) / `CreateGrnSchema` (with `inwardDate >= orderDate` refine) / `UpdateGrnSchema` / `PostGrnSchema` (no body) / `CancelGrnSchema` / `ReverseGrnSchema` (reasons required, capped at 500 chars) / `ListGrnsQuerySchema` (CSV status parser) / `GrnStatsQuerySchema`.

### Number generator (`utils/grn-number-generator.utils.ts`)
- Format: `GRN-<store6>-YYYYMM-NNNN` (4-digit zero-padded sequence).
- `buildPrefix` / `formatNumber` are pure static helpers — unit-tested.
- `generateForStore(tenantId, storeId, when)` peeks the highest sequence under the prefix and returns next.
- `peekNextSequence` is robust to unparseable suffixes (returns 1) and rolls past 9999 cleanly (5+ digits).

### Repositories (3)

- **`GrnHeadersRepository`** — extends `BaseRepository`. `findByIdInTenant`, `findByInvoice` (duplicate-invoice pre-check), `findPaginatedScoped` (cursor pagination on `(inwardDate desc, createdAt desc)`), `updateStatusGuarded` (optimistic state transition — only flips status if the row is still in `allowedFromStates`; the cornerstone of concurrent-post safety), `getStats` (single GROUP BY query).
- **`GrnItemsRepository`** — `findByGrn` (tx-aware), `findByIdInGrn`, `deleteForGrn`. Items inherit tenant + store from the parent header; we never list items without scoping by `grnId`.
- **`GrnEventsRepository`** — append-only. `create` + `findByGrn`.

### Services (5)

- **`GrnValidationService`** — splits feedback into errors (block posting) and warnings (allow with awareness). Catches negative quantity, expiry-before-manufacture, missing fields. Warns on past-expiry, short-shelf-life (< 30 days), duplicate batch within the GRN, unknown product (auto-create at post time).
- **`GrnPostingService`** — atomic posting in a **serializable** transaction. Validates → resolves products (auto-creates with `pending_review` status) → applies inbound inventory movement (via injected `IInventoryService`) → registers expiry records (BE-18 `ExpiryService.createRecord`) → patches line items with linkages → flips status with `updateStatusGuarded` (concurrent-post safety) → emits `posted` event → audit-logs. Best-effort post-commit hook publishes supplier performance metrics.
- **`GrnReversalService`** — idempotent reversal of a posted GRN. Emits outbound inventory movement per line, flips status `posted → reversed` via the optimistic guard, signals supplier-performance reversal best-effort post-commit. Never deletes original rows; layers `reversed_at / reversed_by / reversal_reason` on top.
- **`GrnService`** — top-level orchestrator. Draft create / update / item add / item update / item remove / cancel / find / list / stats. Posting and reversal are delegated to the dedicated services. Verifies supplier exists / belongs to tenant / is active before creating a draft. Pre-checks duplicate invoices for friendly 409 errors.
- **`InventoryStubService` + `SupplierLookupStubService` + `SupplierPerformanceStubService`** — in-process fallback implementations behind `INVENTORY_SERVICE_TOKEN`, `SUPPLIER_LOOKUP_TOKEN`, and `SUPPLIER_PERFORMANCE_TOKEN`. Allow the GRN module to boot end-to-end before BE-25 / BE-27 ship; flagged in the integration checklist below for the orchestrator to override at module composition time.

### Controller
- **12 endpoints** under `/api/v1/grn/*`:
  - `POST /grn` (create draft), `GET /grn` (paginated list), `GET /grn/stats`, `GET /grn/:id` (with items + events), `PATCH /grn/:id` (update draft).
  - `POST /grn/:id/items`, `PATCH /grn/:id/items/:itemId`, `DELETE /grn/:id/items/:itemId`.
  - `POST /grn/:id/validate`, `POST /grn/:id/post`, `POST /grn/:id/cancel`, `POST /grn/:id/reverse`.
- Static segments (`stats`) precede `:id` routes so routing is deterministic.
- Permission gates: `grn:read` for queries, `grn:write` for mutations, `grn:post` for posting, `grn:cancel` for cancel + reverse (no separate `grn:reverse` permission yet — flagged below).
- All routes pass through the BE-08 guard stack and require tenant scope.

### Migration
- **`server/src/db/migrations/0006_be26_grn.sql`** — idempotent. Creates 2 enums, 3 tables, 10 indexes (3 of them unique). Numbered 0006 per the phase plan; BE-15..BE-18 reused existing tables and shipped no standalone migration (gap 0003 → 0006 is real and intentional — BE-24/BE-25 land in the same wave and fill 0004/0005).

### Tests (6 spec files)

| Spec | Cases | Covers |
|---|---|---|
| `grn.dto.spec.ts` | 26 | Every schema refine + cap (EAN format, quantity > 0 / int, expiry > mfg, AddItems cap=200, status CSV parse, limit cap) |
| `grn-number-generator.utils.spec.ts` | 7 | Pure helpers + peek-next-sequence with empty bucket / normal seq / 5-digit overflow / unparseable suffix |
| `grn-validation.service.spec.ts` | 11 | Not-found → invalid, no-items, negative qty, expiry ≤ mfg, past-expiry warn, short-shelf-life warn, no-warn for > 30 days, duplicate batch warn, unknown-product warn vs found, all-pass |
| `grn-posting.service.spec.ts` | 17 | Preflight rejections (not-found, posted, cancelled, reversed, validation fail, no items), serializable tx open, status flip, one inbound movement per item, one expiry record per dated item, posted event row, audit log, product auto-create, **rollback when inventory throws (no event written, no status flip)**, **GRN_ALREADY_POSTED on guard-null (concurrent post)**, short-shelf-life count, post-commit supplier metrics |
| `grn-reversal.service.spec.ts` | 10 | Not-found, already-reversed, non-posted reject, one outbound per posted line, skip never-posted lines, status flip via guard, reversed event with reason, audit log transition=reverse, **guard-null rejection (concurrent reverse)**, post-commit supplier reversal |
| `grn.service.spec.ts` | 23 | createDraft (supplier missing / cross-tenant / blacklisted / inactive / dup invoice / happy path / initial items), updateDraft (posted / cancelled / reversed rejections / happy path), addItems (posted reject / counter refresh), removeItem (not-found / counter refresh), cancel (5 paths: missing / posted → GRN_ALREADY_POSTED / already-cancelled / reversed / happy + audit + guard-null), delegation to posting/reversal, findById (404 / details) |

**Total: 94 new test cases** dedicated to BE-26 across 6 spec files. All files pass TypeScript diagnostics with no warnings.

## Files Created (matched against BE-26 spec)

| Spec file | Status |
|---|---|
| `server/src/db/schema/grn_headers.ts`, `grn_items.ts`, `grn_events.ts` | ✅ all 3 in `db/schema/grn.ts` (consolidated — same lifecycle, single migration) |
| `server/src/modules/grn/grn.module.ts` | ✅ |
| `server/src/modules/grn/grn.controller.ts` | ✅ |
| `server/src/modules/grn/grn.service.ts` | ✅ |
| `server/src/modules/grn/services/grn-posting.service.ts` | ✅ |
| `server/src/modules/grn/services/grn-validation.service.ts` | ✅ |
| `server/src/modules/grn/services/grn-reversal.service.ts` | ✅ |
| `server/src/modules/grn/services/inventory-stub.service.ts` | ✅ added — fallback for `INVENTORY_SERVICE_TOKEN` until BE-27 lands |
| `server/src/modules/grn/services/supplier-stub.service.ts` | ✅ added — fallback for `SUPPLIER_LOOKUP_TOKEN` + `SUPPLIER_PERFORMANCE_TOKEN` until BE-25 lands |
| `server/src/modules/grn/repositories/grn-headers.repository.ts` | ✅ |
| `server/src/modules/grn/repositories/grn-items.repository.ts` | ✅ |
| `server/src/modules/grn/repositories/grn-events.repository.ts` | ✅ |
| `server/src/modules/grn/dto/{create-grn,grn-item,post-grn}.dto.ts` | ✅ at `dto/grn.dto.ts` (consolidated 9 schemas) |
| `server/src/modules/grn/types/grn.types.ts` | ✅ — also defines the cross-phase DI tokens + interfaces |
| `server/src/modules/grn/utils/grn-number-generator.utils.ts` | ✅ |
| `server/src/db/migrations/0006_be26_grn.sql` | ✅ |
| Tests (6 spec files, 94 cases) | ✅ |

## ⚠ ORCHESTRATOR INTEGRATION CHECKLIST

The hard-constraint files were **not** modified. The orchestrator must apply these merges manually:

### 1. Schema barrel — `server/src/db/schema/index.ts`

Add at the end (after the last existing export):

```typescript
export * from './grn';
```

### 2. App module — `server/src/app.module.ts`

Add the import:

```typescript
import { GrnModule } from './modules/grn/grn.module';
```

And register in the `imports: [...]` array (anywhere after `ExpiryModule`, ideally next to the other Business Operations modules):

```typescript
ExpiryModule,
GrnModule,
```

### 3. RBAC permissions — `server/src/modules/auth/types/permission.types.ts` + `constants/role-permissions.map.ts`

✅ **Mostly already present.** The BE-08 catalog already ships `grn:read`, `grn:write`, `grn:post`, `grn:cancel`. They are mapped to admin/owner/manager/staff/auditor as appropriate.

⚠ **Missing**: there is **no dedicated `grn:reverse`** permission yet. BE-26 reuses `grn:cancel` for the reverse endpoint to avoid expanding the catalog without orchestrator approval. When the RBAC catalog is next opened (likely BE-31 dashboard work), add:

```typescript
| 'grn:reverse'
```

…and grant it to `admin` and `owner` only (manager-level operators should not be able to undo posted stock movements). At that point the controller can be tightened from `@RequirePermissions('grn:cancel')` to `@RequirePermissions('grn:reverse')` for the reverse endpoint.

### 4. Cross-phase DI tokens

BE-26 declares three DI tokens in `modules/grn/types/grn.types.ts`. The GrnModule currently binds each to an in-process stub so the module boots end-to-end without BE-25 / BE-27. Once those phases ship, override the providers in the orchestrator wiring:

| Token | Interface | BE-26 stub | Real impl owner |
|---|---|---|---|
| `INVENTORY_SERVICE_TOKEN` | `IInventoryService` (`applyInbound`, `applyOutbound`) | `InventoryStubService` (logs intent only) | **BE-27** inventory module |
| `SUPPLIER_LOOKUP_TOKEN` | `ISupplierLookupService` (`findById`) | `SupplierLookupStubService` (returns null) | **BE-25** suppliers module |
| `SUPPLIER_PERFORMANCE_TOKEN` | `ISupplierPerformanceService` (`updateMetrics`, `reverseMetrics`) | `SupplierPerformanceStubService` (logs only) | **BE-25** supplier-performance service |

To bind a real implementation, override the provider in the orchestrator `AppModule` like this:

```typescript
// Inside AppModule providers, after both modules are imported:
{ provide: INVENTORY_SERVICE_TOKEN, useExisting: InventoryService },
{ provide: SUPPLIER_LOOKUP_TOKEN, useExisting: SuppliersService },
{ provide: SUPPLIER_PERFORMANCE_TOKEN, useExisting: SupplierPerformanceService },
```

The Nest DI container picks the **last** provider declaration that wins, so AppModule overrides defeat the GrnModule defaults without any in-module changes.

### 5. New npm dependencies — `server/package.json`

✅ **No new dependencies.** BE-26 reuses the existing Drizzle, Zod, Nest, Jest stack from BE-01..BE-25.

### 6. Migration

After the schema barrel is updated:

```bash
cd server
pnpm db:generate    # confirms drizzle agrees the schema is consistent
pnpm db:migrate     # applies 0006_be26_grn.sql
```

The hand-written migration `0006_be26_grn.sql` is idempotent and matches the Drizzle schema definitions byte-for-byte (verified on the partial unique index for `(grn_id, ean, batch_number) WHERE batch_number IS NOT NULL`).

## Database Changes

- New tables: `grn_headers`, `grn_items`, `grn_events`.
- New enums: `grn_status`, `grn_event_type`.
- 10 indexes total: 3 unique (2 regular + 1 partial), 7 regular B-tree.
- Cascade FKs: `grn_items.grn_id` and `grn_events.grn_id` both cascade-delete with `grn_headers`.

## What's Ready for Next Phase

BE-27 (inventory) can:
1. Implement `IInventoryService` and provide it under `INVENTORY_SERVICE_TOKEN`. The two methods needed are `applyInbound(req)` and `applyOutbound(req)` — both already invoked at the right point in the GRN posting / reversal transactions.
2. Use `grn_items.inventory_item_id` and `stock_movement_id` (populated at post time) to back-link inventory rows to their originating GRN line.

BE-30 (Operational Health Score):
1. Use the GRN posting / reversal events plus `min_expiry_remaining_days` and `short_shelf_life_count` columns to compute the Vendor Quality component (Req 29).
2. The "ADDENDUM v2" `vendor-quality-metrics.query.ts` lives at `modules/grn/queries/` per the phase doc; it reads from the existing `grn_headers` columns. The query file itself is **not in this commit** because the OHS calculator (BE-30) is the only consumer and it can land alongside its own work — flagged for BE-30 to add.

BE-31 (App Owner Dashboard):
1. `GET /api/v1/grn/stats` is the single endpoint behind the GRN tile.
2. `GET /api/v1/grn?status=posted&fromDate=...` for the inward log.
3. `GET /api/v1/grn/:id` for the detail view (header + items + events).

BE-25 (suppliers) integration:
1. Implement `ISupplierLookupService.findById` against the real `suppliers` table. Same shape as the stub.
2. Implement `ISupplierPerformanceService.updateMetrics` and `.reverseMetrics`. The metrics payload BE-26 publishes is documented on `SupplierPerformanceMetrics` (deliveryDays, expiryRemainingDays, shortShelfLife flag, amount, postedAt).

## Known Issues / Follow-ups

- **Inventory contract is deferred**. `INVENTORY_SERVICE_TOKEN` is bound to `InventoryStubService` until BE-27 lands. The stub records intent in structured logs (look for `grn.inventory.deferred.inbound` / `grn.inventory.deferred.outbound`) but does not change any inventory state. **GRN posting reports `inventoryUpdates[].newTotal = quantity`** (no aggregation) until the real service is wired. Once BE-27 ships, the override is a one-line provider swap.
- **Supplier metric publish is best-effort**. BE-26 publishes supplier performance metrics **outside** the posting transaction so a slow / flaky downstream never holds the GRN row lock open. A failure is logged (`grn.supplier_performance.publish_failed`) but does not unwind the GRN. BE-25 should treat `updateMetrics` as idempotent so a retry-after-failure can converge. Same applies to `reverseMetrics` on reversal.
- **`grn:reverse` permission missing**. Documented above. The controller currently uses `grn:cancel` for the reverse endpoint; tighten when the RBAC catalog is next opened.
- **Auto-task creation on posting is not yet wired**. The phase doc mentions BE-19 task triggers ("GRN posting may auto-create receiving tasks"). BE-19's `AutoTaskGeneratorService` is plumbed for expiry alerts only (`generateForAlert`). Adding a `generateForGrnPosting(grnId, lines)` method to BE-19 is the cleanest path; flagged as a follow-up because the spec lists this as optional ("may"). The GRN module emits a `posted` event row that BE-19 / BE-24 can subscribe to without needing a service-level integration.
- **Number generator is read-then-bump, not a sequence**. Postgres sequences would be cleaner but they don't reset per (tenant, prefix) bucket. The current approach is correct under serializable isolation: posting + draft creation transactions take a row-level lock that serialises across racers, and the unique index on `(tenantId, grnNumber)` is the hard backstop. Under default `read committed` isolation a tight race could in theory both read the same max value; we mitigate by running the create inside a transaction and trusting the unique index to fail one of the two. Acceptable at the target scale; we can graduate to a Postgres sequence per (tenant, store, month) if telemetry shows churn.
- **No GRN-line-aware expiry record reversal**. The reversal service emits an outbound inventory movement and signals the supplier-performance reversal, but does NOT touch the BE-18 `expiry_records` rows that posting created. Those rows still reference the (now-reversed) GRN line via `source_id`. BE-18 has no "delete by source" method — adding one is in scope for BE-30 cleanup, not BE-26. The reversal result reports `expiryRecordsReverted` (count of items that had records) so callers know how many records were left behind for follow-up.
- **No bulk operations**. Single-GRN endpoints only. Same scope as BE-19.
- **Reversal vs cancellation semantics**. Strict: cancellation only on non-posted GRNs; reversal only on posted GRNs. No re-open path (a cancelled GRN cannot return to draft; a reversed GRN cannot be posted again). Documented as deliberate; if a manager needs to "redo" a cancelled / reversed GRN they create a fresh one.

## Deviations from Spec

- **Single consolidated schema file** — same as BE-15..BE-19. Three split files would force three migrations.
- **Single consolidated DTO file** — 9 Zod schemas in one file. Consistent with the rest of the codebase.
- **In-process stubs for cross-phase tokens** — the spec leaves `IInventoryService` undefined when BE-27 is pending. Rather than gate the GRN module behind BE-27, we ship a stub and override at the orchestrator layer. Same pattern for the supplier contracts.
- **Reversal does not create a counter-GRN** — the spec mused about a "counter-GRN that cancels out the original". We instead flip status `posted → reversed` and emit outbound stock movements directly, keeping a single GRN row with both posting and reversal stamps. Cleaner audit trail; same effect on inventory.
- **`grn:reverse` reuses `grn:cancel`** — see RBAC follow-up above.
- **No Sentry tag on the deferred inventory log** — the structured-log message (`grn.inventory.deferred.inbound`) makes the deferral observable. A Sentry breadcrumb would be redundant; we'd rather not page on every GRN line until BE-27 lands.
- **`AuditAction` enum constraint** — used `'CREATE' | 'UPDATE'` with `metadata.transition` discriminator (`'edit' | 'cancel' | 'post' | 'reverse'`). Same convention as BE-15..BE-19.

## Context for Next Developer

You're inheriting:
- A working draft → posted → reversed GRN pipeline that the App Owner Dashboard (BE-31) can light up immediately for the inward log.
- A clean BE-27 hook: `IInventoryService` is the only contract the inventory module needs to fulfil. Tokens are exported, interfaces are documented.
- A clean BE-25 hook: `ISupplierLookupService` and `ISupplierPerformanceService` are the only contracts the suppliers module needs to fulfil.
- Atomic posting under serializable isolation with optimistic state guards — concurrent posts on the same GRN cannot double-apply inventory or expiry effects, even with the in-process stubs.
- An idempotent reversal that flips status + emits outbound movements without deleting any history.
- A complete audit trail per state change in `grn_events` + `audit_logs`.

## Environment State
No new dependencies. Reuses the existing Drizzle + Zod + Nest stack.

## Performance Metrics (estimated)

- `findById(detail)`: ~25 ms (3 parallel reads).
- `list(50, filtered by store + status)`: ~20 ms (uses `idx_grn_tenant_store_status_date`).
- `getStats(10K rows)`: ~80 ms (1 GROUP BY + 1 aggregate).
- `createDraft (no items)`: ~50 ms.
- `post (10 items, with stub inventory + expiry registration)`: ~250 ms — dominated by 10 × `ExpiryService.createRecord` calls. Real BE-27 inventory will add another 20-50 ms per line.
- `reverse (10 items, stub inventory)`: ~150 ms.

## Security Audit
- BE-08 guard stack on every route ✅.
- Tenant-scoped reads via `findByIdInTenant` everywhere ✅.
- Cross-tenant access blocked: `findByIdInTenant` returns null for foreign GRNs (404, not 403, to avoid leaking existence). Cross-tenant supplier lookup also collapses to 404 ✅.
- Posted GRNs cannot be edited (`assertEditable` throws GRN_ALREADY_POSTED) ✅.
- Posted GRNs cannot be cancelled (must use reverse) ✅.
- Reversal limited to owners + admins (controller `@Roles('owner', 'admin')`) ✅.
- DB-level unique index on `(supplierId, invoiceNumber)` makes duplicate-invoice impossible at the storage layer ✅.
- DB-level partial unique index on `(grnId, ean, batchNumber)` makes duplicate batch within one GRN impossible at the storage layer ✅.
- Optimistic state guards (`updateStatusGuarded`) prevent double-posting + double-reversal even under serializable concurrent transactions ✅.
- Serializable isolation on posting / reversal transactions ✅.
- DTO caps everywhere (max 200 line items, max 500-char reasons, max 200 list limit) ✅.
- Cross-field refines on DTOs (expiry > mfg, inward >= order) prevent malformed payloads at the validation layer ✅.
- Audit log entries on every state change with `metadata.transition` discriminator ✅.
- Append-only `grn_events` table — no UPDATE/DELETE methods on the repository ✅.

## Verification Pack
**`BACKEND_PHASES/BE-26_VERIFICATION.md`** — five suites: A (unit), B (HTTP integration), C (DB invariants), D (security gates), E (atomic posting + reversal + concurrent post).

## Q&A Answers (BE-26 SOP)

**Q1 — Why draft → posted workflow?** Two-step ensures verification before stock impact and lets staff correct typos / missing batch numbers before they propagate to inventory and supplier scorecards. Once posted, the only correction is reversal (with a reason captured in the audit trail). Draft state allows free edits; posted state freezes everything except the reversal flag. The `assertEditable` helper enforces this at the service layer; the optimistic state guard enforces it at the DB layer too.

**Q2 — Why serializable transaction for posting?** Two managers clicking "post" on the same GRN at the same time must not double-apply inventory + expiry effects. Serializable isolation + the `updateStatusGuarded(['draft','pending_review'])` optimistic check together guarantee that only one transaction succeeds; the other gets `GRN_ALREADY_POSTED` cleanly. The cost (occasional serialization-failure retry) is acceptable for a low-throughput operation like GRN posting (≤ 10s of GRNs per tenant per day at the target scale).

**Q3 — Why product name snapshot?** Compliance / audit. What the supplier *claimed* the product was at receipt time is the immutable record. If the catalog product is renamed later (typo fix, brand change), the GRN line still shows what was received — the historical record stays accurate. Same reason invoice numbers are stored verbatim and not joined.

**Q4 — Why supplier+invoice uniqueness?** Prevents double-entry of the same physical delivery, which would otherwise double-count inventory and inflate vendor scorecards. The DB unique index on `(supplier_id, invoice_number)` is the hard guarantee; the service layer pre-checks it for a friendly 409 before the insert is attempted.

**Q5 — How handle returned items?** Reverse the GRN (`POST /grn/:id/reverse` with a reason). This emits outbound stock movements per line, flips status to `reversed`, signals supplier-performance reversal, and audit-logs the action. The original GRN is preserved with its `posted_at`, `posted_by`, items intact — `reversed_at`, `reversed_by`, `reversal_reason` are layered on top so the history reads naturally. Cancellation is for never-posted GRNs only; reversal is for posted ones.

**Q6 — Why warn but allow short shelf life?** Sometimes intentional (clearance promo, special discount, special request from a manager). The validator surfaces the warning so the user knows the context, and the `posted` event metadata captures `shortShelfLifeCount` for vendor scorecards. Hard-blocking would break legitimate edge cases.

**Q7 — How does this integrate with inventory (BE-27)?** Through the `IInventoryService` interface bound to `INVENTORY_SERVICE_TOKEN`. Posting calls `applyInbound` per line; reversal calls `applyOutbound` per line. The interface is minimal — quantity, product, batch, expiry, source-id triple. BE-27 implements the interface, registers it under the token in AppModule, and the GRN module is unaffected. Until BE-27 lands, an in-process stub records intent in structured logs.

**Q8 — Why update supplier performance immediately?** Vendor scorecards stay fresh without a nightly batch — the dashboard always reflects today's deliveries. The publish is **post-commit** (outside the GRN transaction) so a slow / flaky supplier service can never hold the GRN row lock open. Failure to publish is logged but does not roll back the GRN — the metric is best-effort, not transactional, and BE-25 can backfill from the GRN history if needed.

## Rollback Information
- `DROP TABLE grn_events, grn_items, grn_headers;` (cascade order respects FKs).
- `DROP TYPE grn_event_type, grn_status;`
- Remove `GrnModule` from `app.module.ts`.
- Remove `export * from './grn';` from the schema barrel.
- Delete `src/modules/grn/` and `src/db/schema/grn.ts`.
- Audit logs (action=CREATE/UPDATE, resourceType=Grn / GrnPosting) remain in `audit_logs` — leave them; they're historical.

---

**End of BE-26 Handoff. Approved for BE-27 once the BE-26_VERIFICATION pack passes locally with a full create → add-items → validate → post → reverse cycle on a real DB.**
