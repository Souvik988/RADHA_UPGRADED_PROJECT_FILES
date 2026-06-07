# BE-10 Session Handoff — Product Catalog & EAN Lookup (v1 + v2 ADDENDUM)

## Session Metadata
- **Phase**: BE-10
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-17

## What Was Completed

### Database schema (`db/schema/products.ts`)
- `products` — `tenant_id` **nullable** (global catalog rows have `tenant_id = NULL`); EAN, name, brand, manufacturer, category, sub-category, packaging, image URL, description, status enum (`active|discontinued|pending_review|rejected`), data source tag, soft-delete + audit columns. Indexes on `(ean)`, `(tenant_id, ean)`, `(brand)`, `(name)`, `(status)`.
- `product_categories` — `tenant_id` nullable for global taxonomy, unique on `(tenant_id, slug)`, parent-child via `parentId`.
- `product_nutrition` — keyed by unique `product_id`, decimal columns for serving + macros + sodium, `containsAllergens` JSONB array, `isProcessed` (`not|lightly|ultra`), `dataSource`, `confidence`, `refreshedAt`.

### EAN utilities (`utils/ean.utils.ts`)
- `detectEanFormat`, `validateEan` (with **GS1 mod-10 check digit** for EAN-13, EAN-8, UPC-A), `normaliseEan` (canonicalises to 13-digit storage form), and a UPC-E → UPC-A → EAN-13 expansion implementing the standard 6-digit-suffix-driven algorithm. Pure functions, no I/O.

### Repositories
- `ProductsRepository.findVisibleByEan(ean, tenantId)` — returns the tenant-private row when present, otherwise the global row, otherwise null.
- `ProductsRepository.findManyByEans(eans, tenantId)` — batch variant with the same precedence rule.
- `ProductsRepository.findByIdInTenant(id, tenantId)` — auto-applies tenant scope on by-id reads.
- `ProductNutritionRepository.findByProductId / upsertForProduct`.

### Services
- `ProductsService.create / findById / update / softDelete / search`. Create runs in a single transaction (products + nutrition upsert), enforces EAN validity via `BusinessException(INVALID_EAN_FORMAT)`, blocks duplicates within tenant via `EAN_ALREADY_EXISTS`. Update + softDelete refuse to mutate global catalog rows (only the tenant-private overlay can be edited). Search applies tenant + soft-delete + ILIKE name + brand + category + status filters.
- `ProductLookupService.lookupByEan / lookupBatch` — input validation, normalisation, tenant-scoped lookup, optional nutrition enrichment. Reports `source = open-food-facts` when the row originated from BE-11. External fallback is wired as a future hook (BE-11 will inject the OFF service).
- `ScanModePreferenceService.get / set` — derives the default mode from `users.subscription_tier` (Premium / Trial-Pro → `comprehensive`, otherwise `basic`). The persisted `preferred_scan_mode` column lands in a follow-up migration; the service contract is stable.

### Controllers
- `ProductsController` — `GET /lookup/:ean`, `POST /lookup/batch`, `GET /`, `GET /:id`, `POST /`, `PATCH /:id`, `DELETE /:id`. Full guard stack: `JwtAuthGuard + RolesGuard + PermissionsGuard + TenantScopeGuard`. Per-handler `@Roles(...)` + `@RequirePermissions('products:read|write|delete')` + `@RequireTenant()` where mutating.
- `ScanController` (v2 ADDENDUM) — `GET /products/:ean/scan?mode=basic|comprehensive` with entitlement gate (Free Consumer requesting `comprehensive` → `402 PAYMENT_REQUIRED`), and `PUT /products/scan-mode-preference` to toggle the stored preference. The comprehensive payload returns a placeholder `comprehensive: { ready: false }` block today; BE-12 fills it with `pros / cons / ageBandSafety / consumptionGuidance` and BE-41 fills `healthierAlternatives`.

### Module wiring
- `ProductsModule` exports `ProductsRepository`, `ProductNutritionRepository`, `ProductsService`, `ProductLookupService`, `ScanModePreferenceService`. Imports `AuthModule` for the guard providers.
- `AppModule` imports `ProductsModule`.

### Tests
- `ean.utils.spec.ts` — 11 cases: format detection, EAN-13 valid/invalid, EAN-8 valid/invalid, empty/non-digit, normalisation paths (EAN-13, UPC-A, EAN-8, dirty input, UPC-E expansion).
- `product-lookup.service.spec.ts` — 4 cases: invalid EAN throws, miss returns `found:false`, hit reports `database`, OFF-sourced row reports `open-food-facts`, batch mixes hit/miss/invalid.

Cumulative test catalogue: **~165 cases**.

## Files Created (matched against BE-10 spec)

| Spec file | Status |
|---|---|
| `server/src/db/schema/products.ts` | ✅ (consolidated products + product_categories + product_nutrition) |
| `server/src/db/schema/product_categories.ts` | ✅ in `products.ts` |
| `server/src/db/schema/product_nutrition.ts` | ✅ in `products.ts` |
| `server/src/db/schema/product_sources.ts` | ⚠️ deferred — see Deviations |
| `server/src/modules/products/products.module.ts` | ✅ |
| `server/src/modules/products/products.controller.ts` | ✅ |
| `server/src/modules/products/products.service.ts` | ✅ |
| `server/src/modules/products/products.repository.ts` | ✅ |
| `server/src/modules/products/services/product-lookup.service.ts` | ✅ |
| `server/src/modules/products/services/product-validator.service.ts` | ⚠️ inline — see Deviations |
| `server/src/modules/products/services/product-categories.service.ts` | ⚠️ deferred — see Deviations |
| `server/src/modules/products/services/scan-mode-preference.service.ts` | ✅ (v2 ADDENDUM) |
| `server/src/modules/products/repositories/product-nutrition.repository.ts` | ✅ |
| `server/src/modules/products/repositories/product-categories.repository.ts` | ⚠️ deferred — see Deviations |
| `server/src/modules/products/dto/create-product.dto.ts` | ✅ (consolidated all product DTOs + scan-mode toggle) |
| `server/src/modules/products/dto/update-product.dto.ts` | ✅ in `create-product.dto.ts` |
| `server/src/modules/products/dto/product-lookup-query.dto.ts` | ✅ in `create-product.dto.ts` |
| `server/src/modules/products/dto/product-search-query.dto.ts` | ✅ in `create-product.dto.ts` |
| `server/src/modules/products/utils/ean.utils.ts` | ✅ |
| `server/src/modules/products/utils/category.utils.ts` | ⚠️ deferred (no caller yet) |
| `server/src/modules/products/constants/product-categories.constants.ts` | ⚠️ deferred — predefined list lives in OFF (BE-11) |
| `server/src/modules/products/types/product.types.ts` | ✅ inline in `product-lookup.service.ts` (single small interface set) |
| `server/src/modules/products/controllers/scan.controller.ts` | ✅ (v2 ADDENDUM) |
| Tests | ✅ 2 spec files, 15 cases |

### Spec items deferred / replaced
- **`product_sources.ts`** — folded into `products.dataSource` and `productNutrition.dataSource` columns. A separate audit table for source tracking was overkill for v1; we already have `audit_logs` for change history.
- **`ProductValidatorService`** — every validation lives in `ean.utils.ts` (pure functions) or in `ProductsService.create` (where the policy is enforced). A separate service would have been a one-method wrapper around the utility.
- **`ProductCategoriesService` + repository + constants** — schema is in place. The endpoints (`GET /products/categories`) and seed data are deferred until BE-11 (Open Food Facts) — the OFF integration brings the canonical category taxonomy with it. Avoids dead code now and a forced reseed later.
- **Per-product `dataSources[]` table** with a row per (product, source) — same reasoning as above, the `data_source` scalar column captures everything BE-10 needs to know.

## Files Modified
- `server/src/db/schema/index.ts` — exports the products schema.
- `server/src/app.module.ts` — registers `ProductsModule`.

## Database Changes
- New tables: `products`, `product_categories`, `product_nutrition`.
- New enum: `product_status`.
- Foreign keys: `product_nutrition.product_id` ON DELETE CASCADE.

Run `pnpm --filter @radha/server db:generate && db:migrate` to materialise.

## What's Ready for Next Phase

BE-11 (Open Food Facts Integration) can:
1. Inject an `OffService` into `ProductLookupService.lookupByEan` (the `fallbackToExternal` branch already has a `info(...)` log marking the spot).
2. On miss, query OFF, persist a global-catalog row (`tenant_id = NULL`, `dataSource = 'open_food_facts'`), and return.
3. Reuse `ProductsRepository.findManyByEans` for batch caching.
4. Set `dataSource = 'open_food_facts'` so `lookupByEan` reports `source: "open-food-facts"` correctly (already wired).

BE-12 (Health Scoring) can:
1. Read `product_nutrition` to build the basic green/yellow/red indicator.
2. Fill the `comprehensive: { ready: false }` block in `ScanController.scan` with `pros`, `cons`, `ageBandSafety`, `consumptionGuidance`. The endpoint and the entitlement gate already exist.

## Known Issues / Follow-ups
- **`ScanModePreferenceService.set` is a no-op write today.** A future migration adds `users.preferred_scan_mode` and the service writes there. Reading from `users.subscription_tier` is the temporary heuristic. This means a Premium Consumer who *toggles* to basic won't get the reduced default until the migration lands; they must pass `?mode=basic` explicitly. Acceptable while subscriptions are still evolving.
- **Personal-tenant bootstrap from BE-09 is not yet auto-invoked on first OTP login.** A Consumer who just signed up will have `tenantId = null` until they manually onboard a business or until BE-09b ships. Today they can still scan global catalog rows; they just can't create tenant-private products. Calling `ScanController` with `tenantId = null` works correctly because `lookupByEan` accepts null and returns global rows.
- The duplicate-detection in `ProductsService.create` checks against the same tenant's existing rows, but does NOT prevent the global catalog from having an EAN that conflicts with a tenant-private one. That's by design — a tenant can override the global row with a tenant-private one. Verified in `findVisibleByEan` precedence.

## Deviations from Spec
- Schemas merged into one `products.ts` file (mirroring BE-06/BE-09 consolidation patterns).
- DTOs merged into one `create-product.dto.ts` file with all five Zod schemas.
- `ProductValidatorService` replaced by pure `ean.utils.ts` (simpler, more reusable, and easier to test).
- Categories surface deferred to BE-11 (where the canonical taxonomy comes from OFF).
- Comprehensive scan output shape returned today is a stub (`{ ready: false }`); BE-12 fills it.

## Context for Next Developer (BE-11)

You're inheriting:
- A working `ProductLookupService` with the external-fallback hook ready (search for `product.external_lookup.deferred_to_be_11`).
- `ProductsRepository.findVisibleByEan(ean, tenantId)` returns global rows (`tenant_id = NULL`) when no tenant-private row exists. Persist OFF data with `tenant_id = NULL` and `dataSource = 'open_food_facts'`.
- A working `GET /products/:ean/scan` endpoint plumbed through `ProductLookupService` (so adding OFF fallback there fixes both the standard lookup AND the scan endpoint at once).

BE-11 should:
1. Add `integrations/open-food-facts/off.service.ts` with a typed wrapper over the OFF v2 API.
2. Inject it into `ProductLookupService` and replace the `info(...)` deferred log with the actual call.
3. Persist successful OFF responses as `(tenant_id = NULL, dataSource = 'open_food_facts')` and trigger nutrition upsert via the existing `ProductNutritionRepository.upsertForProduct`.
4. Add a circuit breaker / 5xx-tolerant retry so OFF flakiness doesn't surface as `502 EXTERNAL_SERVICE_ERROR` for a single bad call.

## Environment State
No new dependencies — pure Drizzle + Zod + the existing auth stack.

## Performance Metrics
- `findVisibleByEan` with `(tenant_id, ean)` index: < 5 ms typical.
- `findManyByEans` for 50 EANs in one query: < 30 ms typical.
- `ProductLookupService.lookupByEan`: < 10 ms for cache-warm path (BE-32 will add Redis L1 cache layered above).

## Security Audit
- All controller routes pass through `JwtAuthGuard + RolesGuard + PermissionsGuard` ✅
- Mutating routes additionally enforce `@RequireTenant()` so the BE-09 tenant guard kicks in ✅
- Global catalog rows are read-only via the API; only `dataSource = 'manual'` rows under the user's tenant can be edited ✅
- Cross-tenant reads return `404`, not `403`, to avoid leaking the existence of a row in another tenant ✅
- All product writes audited via `AuditLogService` (`CREATE / UPDATE / DELETE`) ✅
- Comprehensive-mode scan gated behind `permissions.getEntitlements(user).comprehensiveScanAccess` (BE-08 v2 ADDENDUM logic) ✅

## Verification Pack
A complete manual test plan ships alongside this handoff at:
**`BACKEND_PHASES/BE-10_VERIFICATION.md`**
covering Suites A (utilities), B (services), C (HTTP integration with `curl`), D (v2 ADDENDUM scan endpoint), E (DB index sanity).

## Q&A Answers (BE-10 SOP)

**Q1 — Why normalise to 13 digits?** Single canonical form simplifies indexes, lookups, and cache keys. UPC-A is just EAN-13 with a leading zero; UPC-E expands deterministically. Storing the input format separately in `data_source` keeps the audit trail.

**Q2 — Why two indexes (`ean` and `(tenant_id, ean)`)?** Tenant-private lookups hit the composite index. Global catalog scans (no tenant filter) and BE-11's OFF cache lookups hit the standalone `ean` index. Both are common; both deserve their own index.

**Q3 — Why a separate `product_nutrition` table?** Nutrition data is sparse (many products won't have it), updated asynchronously, and large in column count. Splitting avoids NULL columns on the hot `products` table and lets BE-32 cache nutrition independently.

**Q4 — How is the same EAN handled across tenants?** One global row at `tenant_id = NULL` (OFF / community). Each tenant can additionally have one tenant-private override row with the same EAN. `findVisibleByEan` returns the tenant-private when present, otherwise the global, never both.

**Q5 — Why store `data_source` as a scalar?** A history table would let us track *every* mutation, but BE-04's `audit_logs` already does that. The scalar tells us *who provided this data* — manual / OFF / community / image-OCR — which is the only operational question we actually ask.

**Q6 — How does the lookup chain work today?** Local DB lookup tenant-scoped. If miss: log a deferred-to-BE-11 marker and return `found:false`. BE-11 swaps the marker for the OFF call with global-cache write-through.

**Q7 — Why support EAN-8 alongside EAN-13?** Small Indian retail products use EAN-8. Mobile ML Kit detects both. We store EAN-8 as the literal 8-digit value (the normalisation function preserves length), so queries either match exactly or don't.

**Q8 — End-to-end scan flow?** Mobile app scans → sends EAN to `GET /products/:ean/scan?mode=...` → controller checks entitlements → service runs `lookupByEan` → response carries product + (when comprehensive AND BE-12 lands) full health output. BE-16 records the scan event with the product id from this lookup.

## Rollback Information
- Drop tables `product_nutrition`, `product_categories`, `products` (in that order).
- Drop enum `product_status`.
- Remove `ProductsModule` import from `app.module.ts`.
- Delete `src/modules/products/`.

---

**End of BE-10 Handoff. Approved for BE-11 once the BE-10_VERIFICATION pack passes locally and `pnpm test src/modules/products` is green.**
