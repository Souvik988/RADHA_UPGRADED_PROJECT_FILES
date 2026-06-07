# BE-12 Verification Pack — Health Scoring Engine

> Run after migrations. Five suites: pure-unit (A), HTTP integration on the comprehensive scan endpoint (B), DB invariants (C), entitlement gating (D), filter/stats/bulk-recompute (E).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

# Tokens (mint with the BE-06/BE-08 helpers used in earlier phases):
FREE_TOKEN=...        # free_consumer
PREMIUM_TOKEN=...     # premium_consumer
OWNER_TOKEN=...       # tenant owner
ADMIN_TOKEN=...       # platform admin
```

`world.openfoodfacts.org` egress required only the first time a fresh EAN is scanned (BE-11 will cache it).

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/health-scoring
```
**Expect**:
- `scoring-engine.service.spec.ts` — 9 cases pass.
- `child-safety.service.spec.ts` — 11 cases pass.
- `allergen-detection.service.spec.ts` — 10 cases pass.
- `consumption-guidance.service.spec.ts` — 6 cases pass.

**Total**: 36 new cases. Cumulative project total ≈ 216.

## Suite B — Comprehensive scan integration

We use Nutella `3017620422003` again (BE-11 already cached this row — sugar=56.3, fat=30.9, saturated=10.6, sodium=39 mg).

### B1 — Basic mode returns a clean envelope

```bash
curl -s "$HOST/api/v1/products/3017620422003/scan?mode=basic" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq
```
**Expect**:
```json
{
  "data": {
    "mode": "basic",
    "ean": "3017620422003",
    "found": true,
    "product": { "name": "Nutella", "brand": "Ferrero" }
  }
}
```
No `comprehensive` key.

### B2 — Comprehensive mode fills the full shape

```bash
curl -s "$HOST/api/v1/products/3017620422003/scan?mode=comprehensive" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq '.data.comprehensive'
```
**Expect** (abbreviated):
```json
{
  "ean": "3017620422003",
  "name": "Nutella",
  "brand": "Ferrero",
  "healthStatus": "red",
  "expiryStatus": "unknown",
  "ingredients": ["sugar", "palm oil", "hazelnuts", "..."],
  "allergensDetected": ["milk", "soy"],
  "pros": [],
  "cons": [
    { "type": "high_sugar", "severity": "high", "message": "Very high sugar content" },
    { "type": "high_oil", "severity": "high", "message": "Very high fat content" },
    { "type": "high_saturated_fat", "severity": "high", "message": "High saturated fat" },
    { "type": "ultra_processed", "severity": "high", "message": "Ultra-processed food" }
  ],
  "ageBandSafety": {
    "infantSafe": false,
    "toddlerSafe": false,
    "childSafe": false,
    "adolescentSafe": false,
    "rationale": "Elevated: sugar 56.3 g, fat 30.9 g, saturated 10.6 g, ultra-processed"
  },
  "consumptionGuidance": {
    "summary": "Best avoided. Look for healthier alternatives.",
    "cadence": "avoid",
    "notes": ["High sugar — pair with protein/fiber to slow absorption.", "High fat — keep portion small and balance with vegetables.", "Saturated fat is elevated — limit to small portions.", "Ultra-processed — fresh whole-food alternatives are preferable."]
  },
  "healthierAlternatives": [],
  "allergenProfileMatches": [],
  "overallGrade": "E",
  "overallScore": 0,
  "isProcessed": "ultra",
  "ruleVersion": "1.0.0"
}
```
Signals: grade `E`, score `0` (clamped from -45 after sugar -25 + fat -20), all four age bands unsafe.

### B3 — Healthy product returns grade A + child-safe

Use a yogurt EAN you've previously scanned (any product with sugars ≤ 5, fat ≤ 5, sodium ≤ 100, protein ≥ 12 in `product_nutrition` will do).

```bash
curl -s "$HOST/api/v1/products/<healthy_ean>/scan?mode=comprehensive" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq '.data.comprehensive | {overallGrade, healthStatus, ageBandSafety, consumptionGuidance: .consumptionGuidance.cadence}'
```
**Expect**: `overallGrade: "A"`, `healthStatus: "green"`, `childSafe: true`, cadence `"daily"`.

### B4 — Missing nutrition data → graceful degradation

Insert a product with no nutrition row (BE-19 manual create path):
```bash
curl -s -X POST "$HOST/api/v1/products" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ean":"9991234567894","name":"Mystery Box","brand":"Unknown"}'

curl -s "$HOST/api/v1/products/9991234567894/scan?mode=comprehensive" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq '.data.comprehensive | {overallGrade, healthStatus, "tags?": .warnings[0].type}'
```
**Expect**: `overallGrade: "U"`, `healthStatus: "data_unavailable"`, first warning `type: "insufficient_data"`.

### B5 — Idempotency (cached lookup)

Repeat B2 immediately. Latency should drop (cached) and the response shape must be byte-identical except for `computedAt`. Confirm:
```bash
$PSQL -c "SELECT count(*) FROM product_health_assessments WHERE product_id = (SELECT id FROM products WHERE ean='3017620422003');"
-- one row only
```
Run B2 a second time:
```bash
$PSQL -c "SELECT computed_at FROM product_health_assessments WHERE product_id = (SELECT id FROM products WHERE ean='3017620422003');"
-- timestamp does NOT change between calls (cache hit, no recompute)
```

## Suite C — DB invariants

### C1 — Rule version traceability

```sql
SELECT rule_version, count(*) FROM product_health_assessments GROUP BY rule_version;
-- All current rows: rule_version = '1.0.0'
```

### C2 — `(product_id, rule_version)` is unique

```bash
curl -s -X POST "$HOST/api/v1/products/<product-id>/health/recompute" \
  -H "Authorization: Bearer $OWNER_TOKEN"
```
```sql
SELECT count(*) FROM product_health_assessments WHERE product_id = '<product-id>';
-- still 1
```

### C3 — Cascade delete on product

```bash
curl -s -X DELETE "$HOST/api/v1/products/<product-id>" \
  -H "Authorization: Bearer $OWNER_TOKEN"
```
```sql
SELECT count(*) FROM product_health_assessments WHERE product_id = '<product-id>';
-- 0  — the FK ON DELETE CASCADE removed the assessment automatically
```

### C4 — Stats aggregation matches row count

```bash
curl -s "$HOST/api/v1/health-scoring/stats" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
```sql
SELECT count(*) FROM product_health_assessments;
SELECT count(*) FILTER (WHERE child_safety_status = 'suitable') FROM product_health_assessments;
SELECT count(*) FILTER (WHERE is_processed = 'ultra') FROM product_health_assessments;
SELECT count(*) FILTER (WHERE jsonb_array_length(allergens) > 0) FROM product_health_assessments;
```
The four counts must match the JSON output's `totalProducts`, `childSafe`, `ultraProcessed`, `withAllergens`.

## Suite D — Entitlement gating

### D1 — Free Consumer hits 402 on comprehensive

```bash
curl -i -s "$HOST/api/v1/products/3017620422003/scan?mode=comprehensive" \
  -H "Authorization: Bearer $FREE_TOKEN"
```
**Expect**: HTTP 402, `error.code = "E4008"` (`PAYMENT_REQUIRED`), no scoring computed.

### D2 — Free Consumer succeeds on basic

```bash
curl -i -s "$HOST/api/v1/products/3017620422003/scan?mode=basic" \
  -H "Authorization: Bearer $FREE_TOKEN"
```
**Expect**: HTTP 200, basic shape returned.

### D3 — Premium Consumer + Trial Pro both pass comprehensive

```bash
curl -s "$HOST/api/v1/products/3017620422003/scan?mode=comprehensive" \
  -H "Authorization: Bearer $PREMIUM_TOKEN" | jq '.data.comprehensive.overallGrade'
# "E"
```

## Suite E — filter / stats / bulk-recompute

### E1 — `GET /health-scoring/rules` returns the v1 rule list

```bash
curl -s "$HOST/api/v1/health-scoring/rules" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
**Expect**: `version: "1.0.0"`, 8 rules with stable ids (`sugar-high`, `fat-high`, `saturated-fat-high`, `trans-fat`, `sodium-high`, `ultra-processed`, `high-protein`, `high-fiber`).

### E2 — `GET /health-scoring/stats` admin-only

```bash
curl -i -s "$HOST/api/v1/health-scoring/stats" \
  -H "Authorization: Bearer $FREE_TOKEN"
# 403 — consumer can't read stats

curl -s "$HOST/api/v1/health-scoring/stats" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
# 200 — owner sees aggregates
```

### E3 — `POST /products/health/bulk-recompute` (admin)

```bash
curl -s -X POST "$HOST/api/v1/products/health/bulk-recompute" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"productIds":["<id-1>","<id-2>","<id-3>"]}' | jq 'length'
# 3 — one assessment per id
```

### E4 — Filter endpoint stub

```bash
curl -s "$HOST/api/v1/products/health/filter?childSafe=true&minGrade=B" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
# { "productIds": [] }  — placeholder until BE-25 ships the query builder
```

## Final sign-off

- [ ] Suite A: 36 unit cases pass
- [ ] Suite B: 5 comprehensive-scan scenarios pass
- [ ] Suite C: DB invariants verified in psql
- [ ] Suite D: entitlement gates correct
- [ ] Suite E: rule list, stats, bulk-recompute, filter stub respond as documented

**Verified by**: ___________________________
**Date**: ___________________________
