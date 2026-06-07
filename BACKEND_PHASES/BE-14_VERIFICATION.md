# BE-14 Verification Pack — Product Search & Filtering

> Run after `pnpm db:migrate`. Five suites: pure-unit (A), HTTP integration (B), tenant invariants (C), security gates (D), performance (E).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...      # tenant owner with products:read
FREE_TOKEN=...       # free_consumer
PREMIUM_TOKEN=...    # premium_consumer
A_TOKEN=...          # tenant A owner
B_TOKEN=...          # tenant B owner
```

Seed at least 100 products (mix of brands, categories, processed levels) before Suite B. The fixtures should include obvious search targets: "Chocolate Bar", "Cadbury Dairy Milk", "Coca-Cola", "Tata Salt", "Maggi 2-Minute Noodles".

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/products/__tests__
```
**Expect** the BE-14 test files to pass:
- `search-query.utils.spec.ts` — 14 cases.
- `search-analytics.service.spec.ts` — 5 cases.
- `product-search.service.spec.ts` — 7 cases.

**Total**: 26 new cases. Cumulative project total ≈ 303.

## Suite B — HTTP integration

### B1 — Full-text search

```bash
curl -s "$HOST/api/v1/products/search?q=chocolate" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
**Expect**:
```json
{
  "data": {
    "data": [{ "id": "<uuid>", "name": "Chocolate Bar", "brand": "..." }, ...],
    "total": <int>,
    "nextCursor": "<base64url or null>",
    "query": "chocolate",
    "durationMs": <int>
  }
}
```
First page returns ≤ 20 rows (Free tier cap, but Owner is paid; the default `limit` is 20). The first row should contain "Chocolate" in `name` (weight A wins).

### B2 — Trigram fuzzy match

```bash
curl -s "$HOST/api/v1/products/search?q=chocolat" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.total'
```
**Expect**: positive integer — typo'd query still finds "chocolate" results because the trigram fallback ILIKE catches `chocolat%`.

### B3 — Brand search ranks high (weight B)

```bash
curl -s "$HOST/api/v1/products/search?q=Cadbury" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data[].brand'
```
**Expect**: rows where brand = "Cadbury" appear at the top.

### B4 — Category filter

Pick a category UUID:
```sql
SELECT id, name FROM product_categories WHERE name = 'Snacks' LIMIT 1;
```
Then:
```bash
curl -s "$HOST/api/v1/products/search?category=<uuid>" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data[].categoryId'
```
**Expect**: every row's `categoryId` matches the input.

### B5 — Health-grade filter

```bash
curl -s "$HOST/api/v1/products/search?healthGrade=A&healthGrade=B" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.total'
```
**Expect**: integer ≥ 0. Verify in psql:
```sql
SELECT pha.overall_grade, count(*)
FROM product_health_assessments pha
JOIN products p ON p.id = pha.product_id
WHERE pha.overall_grade IN ('A', 'B') AND p.deleted_at IS NULL
GROUP BY pha.overall_grade;
```
The sum matches the API total.

### B6 — Autocomplete

```bash
curl -s "$HOST/api/v1/products/autocomplete?q=cho" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
**Expect**: 1..10 suggestions. Each has `text`, `productId`, `matchedField` ('name' or 'brand'). Latency < 50 ms in dev.

### B7 — Facets

```bash
curl -s "$HOST/api/v1/products/search?q=snack&includeFacets=true" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.facets'
```
**Expect**:
```json
{
  "categories": [{ "value": "<uuid>", "label": "<uuid>", "count": <int> }, ...],
  "brands": [{ "value": "Cadbury", "label": "Cadbury", "count": <int> }, ...],
  "healthGrades": [{ "value": "A", "label": "A", "count": <int> }, ...],
  "processingLevels": [{ "value": "ultra", "label": "ultra", "count": <int> }, ...]
}
```

### B8 — Pagination

```bash
# First page
RES=$(curl -s "$HOST/api/v1/products/search?q=&limit=10" -H "Authorization: Bearer $OWNER_TOKEN")
CURSOR=$(echo "$RES" | jq -r '.data.nextCursor')

# Second page using the cursor
curl -s "$HOST/api/v1/products/search?q=&limit=10&cursor=$CURSOR" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data[].id'
```
**Expect**: zero ID overlap between page 1 and page 2.

### B9 — Empty query returns recent

```bash
curl -s "$HOST/api/v1/products/search" -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data | length'
```
**Expect**: 1..20 — most recent products surface.

### B10 — Popular products endpoint

Pre-seed popularity (or run a few scans first):
```sql
INSERT INTO popular_products (product_id, tenant_id, scan_count) VALUES
  ('<some-product-id>', '<tenantId>', 50);
```
Then:
```bash
curl -s "$HOST/api/v1/products/popular?limit=10" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data | length'
```
**Expect**: rows ordered by scan_count desc.

### B11 — Similar products

```bash
curl -s "$HOST/api/v1/products/<product-id>/similar" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data | length'
```
**Expect**: up to 10 (or 20 capped) products in the same category, same brand, or trigram-similar name. Source product itself never appears.

## Suite C — Tenant invariants

### C1 — Cross-tenant search returns zero rows from other tenant

1. Tenant A creates a product "TenantA-Only-Widget".
2. Tenant B searches:
   ```bash
   curl -s "$HOST/api/v1/products/search?q=TenantA-Only-Widget" \
     -H "Authorization: Bearer $B_TOKEN" | jq '.data.total'
   ```
   **Expect**: 0.

### C2 — Global products visible across tenants

OFF-imported products live with `tenant_id IS NULL`. Both tokens must see them:
```bash
curl -s "$HOST/api/v1/products/search?q=Nutella" -H "Authorization: Bearer $A_TOKEN" | jq '.data.total'
curl -s "$HOST/api/v1/products/search?q=Nutella" -H "Authorization: Bearer $B_TOKEN" | jq '.data.total'
```
Both > 0.

### C3 — Tenant-private overrides take precedence

If Tenant A has a private "Nutella" override and the global Nutella also exists, Tenant A's search returns the override (tenant-private wins via the precedence in `findVisibleByEan` — but for search we just return both; Mobile_App displays tenant-private first via the result order).

```sql
SELECT count(*) FROM products WHERE ean='3017620422003';
-- 2 (1 global + 1 tenant-A private)
```
A search query for the tenant returns 2 rows, ordered by relevance.

## Suite D — Security gates

### D1 — SQL injection attempt returns no results, not 500

```bash
curl -i -s "$HOST/api/v1/products/search?q=%27%20OR%201%3D1%20--" \
  -H "Authorization: Bearer $OWNER_TOKEN"
```
**Expect**: HTTP 200, `data.total=0` (the literal string `' OR 1=1 --` matches nothing). Drizzle parameterised the bind variable.

### D2 — Query length cap

```bash
LONG=$(python3 -c "print('a'*200)")
curl -i -s "$HOST/api/v1/products/search?q=$LONG" -H "Authorization: Bearer $OWNER_TOKEN"
```
**Expect**: HTTP 400 (Zod rejects `q.length > 80`).

### D3 — Free-tier hard cap of 20

```bash
curl -s "$HOST/api/v1/products/search?q=&limit=100" \
  -H "Authorization: Bearer $FREE_TOKEN" | jq '.data.data | length'
```
**Expect**: ≤ 20 (the controller caps Free tier).

### D4 — Premium tier can request more

```bash
curl -s "$HOST/api/v1/products/search?q=&limit=100" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq '.data.data | length'
```
**Expect**: ≤ 100 (PAID_LIMIT_CAP).

### D5 — Wildcards in user input don't widen the search

Add a product named "100%". Then:
```bash
curl -s "$HOST/api/v1/products/search?q=50%25" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data[].name'
```
**Expect**: Only products with "50%" in name (literal). Not "100%".

### D6 — Analytics never throws when DB is unreachable

Stop Postgres briefly, then issue a search. The HTTP request should still respond (analytics is fire-and-forget) — but only after the read finishes, so this test is purely about not catastrophically 500-ing on analytics-only failures. Restart Postgres before continuing.

## Suite E — Performance + index usage

### E1 — EXPLAIN ANALYZE confirms GIN index

```sql
EXPLAIN ANALYZE
SELECT id, name FROM products
WHERE tenant_id = '<tenantId>'
  AND search_tsv @@ plainto_tsquery('english', 'chocolate')
LIMIT 20;
```
**Expect**: `Bitmap Index Scan on products_search_tsv_idx` in the plan. Total time < 10 ms on 10K rows.

### E2 — Trigram index used for autocomplete

```sql
EXPLAIN ANALYZE
SELECT id, name FROM products
WHERE tenant_id = '<tenantId>' AND name ILIKE 'cho%'
ORDER BY similarity(name, 'cho') DESC LIMIT 10;
```
**Expect**: `Bitmap Index Scan on products_name_trgm_idx`. Total time < 15 ms.

### E3 — End-to-end latency

```bash
time curl -s "$HOST/api/v1/products/search?q=chocolate" \
  -H "Authorization: Bearer $OWNER_TOKEN" -o /dev/null
```
**Expect**: total < 500 ms (Req 39 SLO P95).

### E4 — Trigger maintains tsv on update

```sql
UPDATE products SET name = 'Updated Chocolate Name'
WHERE id = '<some-product-id>';

SELECT name, search_tsv::text FROM products WHERE id = '<some-product-id>';
```
**Expect**: `search_tsv` reflects the new name (`'updated':1A 'chocolat':2A 'name':3A` or similar). Then a search:
```bash
curl -s "$HOST/api/v1/products/search?q=Updated%20Chocolate" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data.data[0].id'
```
**Expect**: the updated product id.

### E5 — Analytics ledger populated

After running B1 a few times:
```sql
SELECT query_text, result_count, duration_ms, source FROM search_queries
ORDER BY created_at DESC LIMIT 5;
```
**Expect**: rows logged for each search call.

## Final sign-off

- [ ] Suite A: 26 unit cases pass
- [ ] Suite B: 11 HTTP integration scenarios pass
- [ ] Suite C: tenant invariants verified in psql
- [ ] Suite D: 6 security gates fire correctly
- [ ] Suite E: indexes are hit + 500 ms SLO held + analytics ledger populated

**Verified by**: ___________________________
**Date**: ___________________________
