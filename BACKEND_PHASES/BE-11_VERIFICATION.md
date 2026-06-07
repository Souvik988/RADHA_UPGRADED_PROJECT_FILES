# BE-11 Verification Pack — Open Food Facts Integration

> Run after migrations. The verification covers four suites: pure-unit (A), HTTP integration (B), cache + tenant invariants (C), circuit-breaker forcing (D).

## Pre-flight

```bash
HOST=http://localhost:3000
TOKEN=...        # Owner / Manager / Staff bearer from BE-09 onboarding
```

Internet egress to `https://world.openfoodfacts.org` is required for the integration suites.

## Suite A — Unit (no DB / no network)

```bash
pnpm --filter @radha/server test src/integrations/open-food-facts
```
**Expect**:
- `off-circuit-breaker.service.spec.ts` — 5 cases pass.
- `off-mapper.service.spec.ts` — 8 cases pass.
- `off.service.spec.ts` — 4 cases pass.

## Suite B — HTTP integration (real OFF)

We use the canonical Nutella EAN `3017620422003` because it's well-documented and stable.

### B1 — First scan: cache miss → OFF call → row persisted

```bash
curl -s "$HOST/api/v1/products/lookup/3017620422003" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**:
```json
{
  "data": {
    "found": true,
    "source": "open-food-facts",
    "externalApiCalled": true,
    "product": { "name": "Nutella", "brand": "Ferrero", "ean": "3017620422003" }
  }
}
```
Confirm in psql:
```sql
SELECT ean, brand, fetch_success FROM open_food_facts_cache WHERE ean='3017620422003';
SELECT id, ean, tenant_id, data_source FROM products WHERE ean='3017620422003';
SELECT product_id, calories, sugars, is_processed FROM product_nutrition
  WHERE product_id IN (SELECT id FROM products WHERE ean='3017620422003');
```
Cache row exists, `products.tenant_id IS NULL`, nutrition row populated, `is_processed = 'ultra'`.

### B2 — Second scan: cache hit, no OFF call

```bash
curl -s "$HOST/api/v1/products/lookup/3017620422003" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**: `data.source = "database"` (or `"open-food-facts"` if BE-10 detects the dataSource), `data.externalApiCalled = false`. Latency < 50 ms in dev.

### B3 — Unknown EAN → negative cache

Use a syntactically valid EAN that OFF won't have, e.g. `1234567890128` (valid check digit, not a real product):
```bash
curl -s "$HOST/api/v1/products/lookup/1234567890128" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**: `data.found = false`. Then in psql:
```sql
SELECT ean, fetch_success FROM open_food_facts_cache WHERE ean='1234567890128';
-- one row, fetch_success = false
```
Repeating B3 should not increment `apiSuccess` further (the cache absorbs the request).

### B4 — Invalid EAN format

```bash
curl -i -s "$HOST/api/v1/products/lookup/abc123" -H "Authorization: Bearer $TOKEN"
```
**Expect**: `400`, `error.code = "E2000"` (`VALIDATION_ERROR`). OFF is never called.

## Suite C — Cache + tenant isolation invariants

### C1 — Two tenants share the OFF cache, but each gets their own product row override

1. Login as Tenant A's Owner, scan `3017620422003` (B1 above).
2. Login as Tenant B's Owner, scan the same EAN.
3. `SELECT count(*) FROM products WHERE ean='3017620422003';` → `1` (the global row).
4. `SELECT count(*) FROM open_food_facts_cache WHERE ean='3017620422003';` → `1`.
5. As Tenant A's Manager, create a tenant-private override:
   ```bash
   curl -s -X POST "$HOST/api/v1/products" \
     -H "Authorization: Bearer $A_MANAGER_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"ean":"3017620422003","name":"Tenant A custom name","brand":"Ferrero"}'
   ```
6. `SELECT count(*) FROM products WHERE ean='3017620422003';` → `2`.
7. Tenant A's lookup now returns the override:
   ```bash
   curl -s "$HOST/api/v1/products/lookup/3017620422003" \
     -H "Authorization: Bearer $A_TOKEN" | jq '.data.product.name'
   # "Tenant A custom name"
   ```
8. Tenant B's lookup still returns the global row (`"Nutella"`).

## Suite D — Circuit breaker

### D1 — Force breaker open via DNS-blocking proxy

Easiest local approach: change `OFF_BASE_URL` constant to `http://127.0.0.1:9` (closed port) and restart. Issue 5 lookups for distinct EANs you haven't cached:
```bash
for ean in 1111111111111 2222222222222 3333333333333 4444444444444 5555555555555; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    "$HOST/api/v1/products/lookup/$ean" -H "Authorization: Bearer $TOKEN"
done
```
**Expect**: each request returns 200 with `data.found = false`. After the 5th failure, the BE-04 logger emits `off.circuit.transition: closed → open`. Subsequent calls return immediately (no network attempt).

### D2 — Half-open recovery

Restore `OFF_BASE_URL`, restart, wait 60 s, scan a known EAN. Logs:
- `off.circuit.transition: open → half-open`
- on success: `off.circuit.transition: half-open → closed`

## Final sign-off

- [ ] Suite A: 17 unit tests pass
- [ ] Suite B: 4 integration cases pass against live OFF
- [ ] Suite C: tenant isolation + global cache invariants verified in psql
- [ ] Suite D: breaker transitions observed in logs

**Verified by**: ___________________________
**Date**: ___________________________
