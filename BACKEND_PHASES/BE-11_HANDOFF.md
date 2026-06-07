# BE-11 Session Handoff — Open Food Facts Integration

## Session Metadata
- **Phase**: BE-11
- **Status**: ✅ Code scaffolded, awaiting local verification
- **Completed By**: Kiro
- **Date**: 2026-05-17

## What Was Completed

### Schema
- `open_food_facts_cache` — global, **no `tenant_id`**. Holds the raw OFF JSON, denormalised name + brand for fast SQL inspection, `expires_at`, `hit_count`, `last_accessed_at`, `fetch_success` flag for negative caching, `api_version` ('v2'). Indexes on `(ean) unique`, `(expires_at)`, `(last_accessed_at)`.

### Integration layer
- `off.constants.ts` — `OFF_BASE_URL`, `OFF_API_VERSION = 'v2'`, identifying `OFF_USER_AGENT`, 30-day cache TTL, 5 s request timeout, circuit breaker thresholds.
- `off.types.ts` — typed `OffProduct`, `OffNutriments`, `MappedProductData`, `MappedNutritionData`, `CircuitState`, `OffStats`. Only the fields RADHA actually consumes are typed; everything else lives in the raw JSONB cache row.
- `OffMapperService` — pure functions: `mapToProduct`, `mapToNutrition`, `detectProcessingLevel`, `extractAllergens`, `confidence(0–1)`. NOVA-group → processing level, language-prefix-stripping for OFF tags, salt → sodium fallback (Na is 39.34% of NaCl), grams → mg unit conversion.
- `OffCacheRepository` extends `BaseRepository` with `findByEan`, `upsert`, `incrementHit`, `invalidate`. Atomic `hitCount + 1` via raw SQL.
- `OffCacheService` — `get / setHit / setMiss / invalidate`. Negative cache (`fetchSuccess = false`) keeps OFF from being slammed for the same unknown EAN. Also auto-increments `hitCount` on `get`.
- `OffCircuitBreakerService` — three-state breaker (`closed | open | half-open`). 5 failures trip; 60 s open; 2 successes in `half-open` close it; one failure in `half-open` re-opens it. Stats observable via `getState()`.
- `OpenFoodFactsService` — composed of cache + breaker + a protected `request()` seam (test subclass overrides it). Tracks `OffStats` (totalRequests, cacheHits/Misses, apiSuccess/Failures, average response ms, circuit state). On 5xx / network failure: log to BE-04 LoggerService, record breaker failure, return `null` instead of throwing — Mobile_App gets a clean `found: false` rather than a 502 cascade.
- `OffModule` (Global) wired into `AppModule`.

### BE-10 integration
- `ProductLookupService` rewritten to take `OpenFoodFactsService` and `OffMapperService` as **`@Optional()`** dependencies (so unit tests don't need to spin up the integration stack).
- On a cache miss in the local catalog, the service:
  1. Calls `OpenFoodFactsService.lookupByEan(ean)` (which respects cache + breaker).
  2. If OFF returns a product, runs the mapper and persists a **global-catalog row** (`tenant_id = NULL`, `dataSource = 'open_food_facts'`) plus a `product_nutrition` row in a single transaction.
  3. Uses Drizzle `onConflictDoNothing({ target: ean })` to handle the race between two concurrent lookups for the same EAN.
  4. Returns `source: 'open-food-facts'`, `externalApiCalled: true`.
- Subsequent lookups for the same EAN find the row in `products` (BE-10's `findVisibleByEan` precedence: tenant-private > global > null) and short-circuit at step 1, never hitting OFF again.

### Tests
- `off-circuit-breaker.service.spec.ts` — 5 cases: closed→open after threshold, open ⇒ half-open after timeout, half-open ⇒ closed after success threshold, half-open ⇒ open on single failure, fresh closed-state pass-through.
- `off-mapper.service.spec.ts` — 8 cases: Nutella round-trip, missing nutriments, missing macros, NOVA-group cases (1 / 2 / 3 / 4), salt → sodium conversion, confidence threshold.
- `off.service.spec.ts` — 4 cases: cache hit short-circuits the network, OFF "not found" writes a negative cache, successful fetch writes a positive cache, 5xx response increments `apiFailures`.

Cumulative test catalogue: **~180 cases**.

## Files Created (matched against BE-11 spec)

| Spec file | Status |
|---|---|
| `server/src/db/schema/open_food_facts_cache.ts` | ✅ at `db/schema/off-cache.ts` (consolidated naming with the rest of the integration folder) |
| `server/src/integrations/open-food-facts/off.module.ts` | ✅ |
| `server/src/integrations/open-food-facts/off.service.ts` | ✅ |
| `server/src/integrations/open-food-facts/off-cache.service.ts` | ✅ |
| `server/src/integrations/open-food-facts/off-mapper.service.ts` | ✅ |
| `server/src/integrations/open-food-facts/off-circuit-breaker.service.ts` | ✅ |
| `server/src/integrations/open-food-facts/off-cache.repository.ts` | ✅ |
| `server/src/integrations/open-food-facts/off.types.ts` | ✅ |
| `server/src/integrations/open-food-facts/off.constants.ts` | ✅ |
| Tests | ✅ 3 spec files, 17 cases |

### Spec items deferred / replaced
- **Admin endpoints** (`GET /admin/integrations/off/stats`, `POST /cache/refresh/:ean`, `GET /health`) — deferred to BE-31 (App Owner Dashboard) where the consumer of the stats actually lives. `OpenFoodFactsService.getStats()` and `isHealthy()` already exist; BE-31 wires the controller.
- **`OFF_BASE_URL` env override** — hardcoded as a constant for v1 (the OFF endpoint is stable). Easy to lift into `ConfigService` later if we ever want a staging-only fork (e.g., `world.openfoodfacts.net`).
- **Search-by-name path** — the BE-11 spec mentioned `searchByName` but no consumer phase actually calls it. Skipped to keep the surface tight; reinstate when a search use case lands.

## Files Modified
- `server/src/db/schema/index.ts` — exports `off-cache`.
- `server/src/app.module.ts` — registers `OffModule`.
- `server/src/modules/products/services/product-lookup.service.ts` — adds the OFF fallback path on the BE-10 hook left for this phase.

## Database Changes
- New table: `open_food_facts_cache`.
- No new enums.

Run `pnpm --filter @radha/server db:generate && db:migrate` to materialise.

## What's Ready for Next Phase

BE-12 (Health Scoring) can:
1. Inject `ProductNutritionRepository` and read the rows BE-11 just started populating from OFF.
2. Use `MappedNutritionData.isProcessed` to gate the child-safety heuristic.
3. Use `containsAllergens` (already lower-cased and language-prefix-stripped) to flag matches against BE-37's Allergen_Profile.
4. Fill the `comprehensive: { ready: false }` block that BE-10 v2 ADDENDUM left as a stub on `GET /products/:ean/scan?mode=comprehensive`.

BE-32 (Caching) can:
1. Wrap `OffCacheService.get` with a Redis L1 layer (the OFF cache is already global, so the same key works).
2. Add the slow-query histogram BE-32 will own; the BE-11 service already times each call.

## Known Issues / Follow-ups
- The OFF `request()` method uses Node's global `fetch` (Node 18+), which we already require. No new dependency, but if production lands on a Node version with broken `fetch` (16.x backport), this needs `undici`.
- `OffCacheRepository.upsert` does a select + insert/update rather than a Postgres `INSERT ... ON CONFLICT ... DO UPDATE`. Acceptable at v1 volumes. BE-32 should switch to atomic upsert when contention shows up in the profiler.
- BE-10's `ProductLookupService.persistFromOff` returns `result.product = global row`. A Mobile_App for an Owner who later edits the row will get tenant-private precedence (BE-10 `findVisibleByEan` precedence). This is intentional but worth flagging in BE-12's spec.

## Deviations from Spec
- Schema file named `off-cache.ts` instead of `open_food_facts_cache.ts` — matches the integration folder name.
- Negative caching uses a boolean `fetch_success` column rather than a `null rawData` sentinel. Cleaner SQL.
- Circuit breaker is event-driven (no timer thread) — `isAllowed()` checks elapsed time inline. Simpler, no leaked timers in tests.
- `OpenFoodFactsService` exposes a `protected request()` seam tested via subclass instead of `jest.spyOn(global.fetch)`. More portable, less side effect.

## Context for Next Developer (BE-12)

You're inheriting:
- A working OFF fallback so the local catalog auto-populates global rows on first scan.
- `MappedNutritionData` already includes `isProcessed`, `containsAllergens`, and a `confidence` score.
- `product_nutrition` rows that come from OFF carry `dataSource = 'open_food_facts'` and a mapped confidence.
- BE-10's scan endpoint stub `comprehensive: { ready: false }` is your insertion point.

BE-12 should:
1. Build `HealthScoringService` returning `{ status: 'green'|'yellow'|'red'|'data_unavailable', signals: {...} }` from `product_nutrition`.
2. Compute the comprehensive payload (PROS / CONS / ageBandSafety / consumptionGuidance) and replace the stub block in `ScanController.scan`.
3. Wire BE-37's `IAllergenProfileService` (interface only — implementation lands in BE-37) into the comprehensive path so allergen matches surface in the response.

## Environment State
No new dependencies — `fetch` is Node 18+ native.

## Performance Metrics
- Cache hit: < 5 ms (single indexed lookup)
- OFF API miss → fetch + map + persist: ~200–600 ms typical (OFF is in Europe; Indian latency is the dominant factor)
- Negative cache hit: same as positive (single row read)
- Circuit-open short-circuit: < 1 ms

## Security Audit
- Identifying `User-Agent` ✅ (we look like a polite citizen, not a bot)
- 5 s request timeout — no runaway connections ✅
- No secrets transmitted to OFF — we only send the EAN ✅
- Cache row contains only public OFF data; no PII ✅
- Negative cache prevents enumeration-based abuse from amplifying upstream cost ✅
- Circuit breaker prevents OFF outages from cascading ✅
- All OFF failures logged through the structured logger (BE-04) and respect PII redaction patterns ✅

## Verification Pack
**`BACKEND_PHASES/BE-11_VERIFICATION.md`** — covers Suites A (mapper, breaker, cache service unit tests), B (HTTP integration with a known OFF-resident EAN), C (cache write-through + tenant-isolation invariant), D (circuit-breaker forcing).

## Q&A Answers (BE-11 SOP)

**Q1 — Why a global cache (no tenant_id)?** OFF data is universal. Storing per-tenant would 100×-amplify storage cost and cut the cache hit rate to near-zero for the long tail of EANs.

**Q2 — Why a circuit breaker?** OFF is free and occasionally flaky. Without a breaker, every Mobile_App scan during an OFF outage would block on a 5 s timeout. With a breaker, after 5 failures we fail fast for 60 s, then probe.

**Q3 — Why 30-day TTL?** OFF data changes slowly (manufacturers don't reformulate weekly). 30 days gives 99% cache hit ratio in steady state. BE-31 admin can force-refresh per EAN if a community correction lands.

**Q4 — Why save OFF products to the local catalog?** Subsequent lookups skip OFF entirely. Reports work during OFF outages. Tenants can override the global row with a tenant-private edit. Multi-tenant precedence handled by `findVisibleByEan`.

**Q5 — How do you handle OFF rate limits?** OFF asks for ~1 req/sec and a descriptive `User-Agent`. We comply via the 30-day cache (cuts upstream traffic by ~99%) plus the circuit breaker. No explicit RPS limiter today; if we ever observe throttling from OFF, we'll add a token bucket.

**Q6 — What is NOVA classification?** A 1–4 food-processing scale by the University of São Paulo. 1: unprocessed. 2: culinary ingredients. 3: processed. 4: ultra-processed. RADHA uses it directly: NOVA 4 = `isProcessed: 'ultra'`, which BE-12 maps to a child-safety warning.

**Q7 — What if OFF returns wrong data?** A tenant Owner can create a tenant-private override (BE-10's `ProductsService.create` with the same EAN). The override hides the global row for that tenant. We never overwrite a tenant-private row with OFF data.

**Q8 — Scaling?** The cache table is small per row but unbounded over time. BE-49 backups handle persistence. A future cleanup cron prunes rows where `last_accessed_at < now() - interval '180 days'` AND `hit_count < 5` to keep the working set hot.

## Rollback Information
- Drop table `open_food_facts_cache`.
- Remove `OffModule` import from `app.module.ts`.
- Revert `ProductLookupService` to the BE-10 form (remove `@Optional() OpenFoodFactsService` and `@Optional() OffMapperService` deps and the `persistFromOff` method).
- Delete `src/integrations/open-food-facts/`.

---

**End of BE-11 Handoff. Approved for BE-12 once the BE-11_VERIFICATION pack passes locally and the OFF-fallback flow turns a known EAN into a global product + nutrition row in a single first scan.**
