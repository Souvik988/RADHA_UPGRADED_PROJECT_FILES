# BE-10 Verification Pack — Product Catalog & EAN Lookup

> Run this against a freshly migrated DB and a tenant onboarded via BE-09.
> Replace `<HOST>` (default `http://localhost:3000`), `<TOKEN>` (consumer/manager bearer), and tenant-specific values where indicated.

## Pre-flight

```bash
HOST=http://localhost:3000
# 1. From BE-09 onboarding, obtain a tenant + grab an OTP-issued JWT for the owner.
# 2. Confirm the tenant id and store id from the onboarding response, e.g.
#    TENANT_ID=...  STORE_ID=...
# 3. Issue a bearer token for the manager / staff if you need to test permission gates.
```

## Suite A — Pure utilities (no DB)

| # | Test | Command | Pass criteria |
|---|---|---|---|
| A1 | EAN-13 valid | `pnpm --filter @radha/server test src/modules/products/__tests__/ean.utils.spec.ts` | All 11 cases pass |
| A2 | EAN-13 wrong check digit rejected | (covered by A1) | `valid:false`, error mentions "check digit" |
| A3 | EAN-8 round-trip | (covered by A1) | `valid:true` for `45678905` |
| A4 | UPC-A → EAN-13 normalisation | (covered by A1) | `036000291452` → `0036000291452` |
| A5 | Non-digits stripped | (covered by A1) | `400-6381-333931` → `4006381333931` |

## Suite B — Service contract (no HTTP)

| # | Test | Command | Pass criteria |
|---|---|---|---|
| B1 | Lookup invalid EAN throws ValidationException | `pnpm --filter @radha/server test src/modules/products/__tests__/product-lookup.service.spec.ts` | All 4 cases pass |
| B2 | Lookup miss returns `found:false` | (B1) | `source:"unknown"` |
| B3 | Lookup hit reports `database` | (B1) | `source:"database"` |
| B4 | OFF-sourced row reports `open-food-facts` | (B1) | `source:"open-food-facts"` |
| B5 | Batch mixes hit / miss / invalid | (B1) | All three keys resolve correctly |

## Suite C — HTTP integration (DB required)

### C1 — Auth required

```bash
curl -i -X GET "$HOST/api/v1/products/lookup/4006381333931"
```
**Expect**: `401`, body `error.code = "E3000"` (`AUTHENTICATION_REQUIRED`).

### C2 — Lookup unknown EAN returns found=false

```bash
curl -s -X GET "$HOST/api/v1/products/lookup/4006381333931" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**:
```json
{
  "success": true,
  "data": { "found": false, "source": "unknown", "externalApiCalled": false }
}
```

### C3 — Lookup invalid EAN returns 400 VALIDATION_ERROR

```bash
curl -s -X GET "$HOST/api/v1/products/lookup/abc123" \
  -H "Authorization: Bearer $TOKEN" -i
```
**Expect**: HTTP `400`, body `error.code = "E2000"` (`VALIDATION_ERROR`).

### C4 — Manager creates a product

```bash
curl -s -X POST "$HOST/api/v1/products" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ean":"4006381333931",
    "name":"Staedtler Eraser",
    "brand":"Staedtler",
    "packageSize":"1",
    "packageUnit":"pcs",
    "nutrition":{ "isProcessed":"not" }
  }' | jq
```
**Expect**: `201` with envelope `data.id`, `data.ean = "4006381333931"`, `data.tenantId = $TENANT_ID`. Confirm row in DB:
```sql
SELECT id, ean, name, tenant_id FROM products WHERE ean = '4006381333931';
SELECT product_id, is_processed FROM product_nutrition WHERE product_id = '<from-above>';
```

### C5 — Duplicate EAN within same tenant rejected

Repeat C4 once more.
**Expect**: `409`, body `error.code = "E6002"` (`EAN_ALREADY_EXISTS`).

### C6 — Staff cannot create a product

```bash
curl -s -X POST "$HOST/api/v1/products" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ean":"4006381333931","name":"x"}' -i
```
**Expect**: `403`, body `error.code = "E4001"` (`INSUFFICIENT_PERMISSIONS`).

### C7 — Read product by id

```bash
curl -s "$HOST/api/v1/products/<id-from-C4>" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**: `200` with the product.

### C8 — Cross-tenant read returns 404

Login as a user from a *different* tenant, repeat C7 with the same product id.
**Expect**: `404`, body `error.code = "E5000"` (`NOT_FOUND`). The repository filters by tenant before returning.

### C9 — Owner soft-deletes; subsequent fetch is 404

```bash
curl -s -X DELETE "$HOST/api/v1/products/<id>" \
  -H "Authorization: Bearer $OWNER_TOKEN" -i
```
**Expect**: `204`. Then:
```sql
SELECT id, deleted_at FROM products WHERE id = '<id>';
```
`deleted_at` is non-null. Then `GET /products/<id>` returns `404`.

### C10 — Search by query and brand

```bash
curl -s "$HOST/api/v1/products?q=Staedtler&brand=Staedtler&limit=10" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**: list of products, `data` is an array.

## Suite D — v2 ADDENDUM (`?mode=basic|comprehensive`)

### D1 — Default mode is `basic`

```bash
curl -s "$HOST/api/v1/products/4006381333931/scan" \
  -H "Authorization: Bearer $TOKEN" | jq
```
**Expect**: `data.mode = "basic"`. No `comprehensive` block.

### D2 — Free Consumer requesting comprehensive returns 402

Login as a default-tier consumer (`subscription_tier = 'free_consumer'`):
```bash
curl -s "$HOST/api/v1/products/4006381333931/scan?mode=comprehensive" \
  -H "Authorization: Bearer $FREE_CONSUMER_TOKEN" -i
```
**Expect**: HTTP `402`, body `error.code = "E4008"` (`PAYMENT_REQUIRED`).

### D3 — Premium Consumer comprehensive returns stub block

Update the user's tier in psql for the test:
```sql
UPDATE users SET subscription_tier = 'premium_consumer' WHERE id = '<id>';
```
Then:
```bash
curl -s "$HOST/api/v1/products/4006381333931/scan?mode=comprehensive" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq
```
**Expect**: `data.mode = "comprehensive"`, `data.comprehensive.ready = false` (BE-12 will populate).

### D4 — Toggle preference

```bash
curl -s -X PUT "$HOST/api/v1/products/scan-mode-preference" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mode":"comprehensive"}' | jq
```
**Expect**: `data.mode = "comprehensive"`.

## Suite E — Database / index sanity

```sql
-- E1: Lookup uses index on (tenant_id, ean) for tenant rows.
EXPLAIN ANALYZE
SELECT * FROM products WHERE tenant_id = '<tenant>' AND ean = '4006381333931';
-- expect "Index Scan using products_tenant_ean_idx"

-- E2: Global-row lookup uses ean index.
EXPLAIN ANALYZE
SELECT * FROM products WHERE ean = '4006381333931' AND tenant_id IS NULL;
-- expect "Index Scan using products_ean_idx"

-- E3: Soft-delete fence.
SELECT count(*) FROM products WHERE deleted_at IS NOT NULL AND status = 'active';
-- expect 0
```

## Final sign-off

- [ ] All A1–A5 unit tests green
- [ ] All B1–B5 service tests green
- [ ] HTTP suite C1–C10 passes (manual or via the `verify.http` file)
- [ ] v2 ADDENDUM D1–D4 passes
- [ ] DB index plan E1–E3 confirms expected access patterns

**Verified by**: ___________________________
**Date**: ___________________________
