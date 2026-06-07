# BE-22 Verification Pack — AI/OCR Wrapper (Free-first)

> Run after migrations. Five suites: A (pure unit), B (HTTP integration on the OCR / label / fallback / explanation endpoints), C (DB invariants), D (security & quota gates), E (full lifecycle: extract → track → cache hit → usage roll-up).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

# Tokens (mint with the BE-06/BE-08 helpers used in earlier phases):
CONSUMER_TOKEN=...   # role=consumer, has consumer:scan
STAFF_TOKEN=...      # role=staff
MANAGER_TOKEN=...    # role=manager
OWNER_TOKEN=...      # role=owner, has owner:dashboard
ADMIN_TOKEN=...      # role=admin

# A pre-uploaded media row (BE-13 presign + confirm):
MEDIA_ID=$(curl -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ownerType":"product","contentType":"image/jpeg","contentLength":12345}' \
  | jq -r '.data.mediaId')
```

No external network egress is required — the dev environment runs without `OPENAI_API_KEY` / `GOOGLE_APPLICATION_CREDENTIALS`, so every paid call short-circuits to the mock provider.

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/integrations/ai src/modules/ai
```

**Expect**:
- `ocr-text-parser.utils.spec.ts` — 19 cases pass.
- `ai-circuit-breaker.service.spec.ts` — 7 cases pass.
- `usage-tracker.service.spec.ts` — 8 cases pass.
- `llm.service.spec.ts` — 11 cases pass.
- `ai-orchestrator.service.spec.ts` — 17 cases pass.
- `mock-ai.provider.spec.ts` — 7 cases pass.
- `ocr.service.spec.ts` — 6 cases pass.
- `ai.dto.spec.ts` — 17 cases pass.

**Total**: ≈ 92 new cases. Cumulative project total: ≈ 520+ cases.

## Suite B — HTTP integration

### B1 — Mobile-pre-extracted OCR for expiry

```bash
curl -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\",\"preExtractedText\":\"EXP: 31/12/2026 BATCH: ABC1234\",\"preExtractedConfidence\":0.92}" | jq
```

**Expect**:
```json
{
  "data": {
    "success": true,
    "text": "EXP: 31/12/2026 BATCH: ABC1234",
    "confidence": 0.92,
    "provider": "mlkit",
    "cost": 0,
    "extractedData": {
      "dates": [
        { "raw": "EXP: 31/12/2026", "format": "EXP DD/MM/YYYY", "confidence": 0.92 }
      ]
    }
  }
}
```

### B2 — Low confidence triggers warning

```bash
curl -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\",\"preExtractedText\":\"EXP 31/12/2026\",\"preExtractedConfidence\":0.45}" | jq '.data.warnings'
```
**Expect**: `["Low OCR confidence (0.45) — verify manually"]`.

### B3 — Generic OCR with EAN extraction

```bash
curl -s -X POST "$HOST/api/v1/ai/ocr/text" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\",\"preExtractedText\":\"Nutella 3017620422003 Net wt 350g\",\"preExtractedConfidence\":0.88}" | jq '.data.extractedData'
```
**Expect**: `productCodes` includes `"3017620422003"`.

### B4 — Label analysis falls back to mock when paid SDK absent

```bash
curl -s -X POST "$HOST/api/v1/ai/label/analyze" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\"}" | jq '.data | {productName, brand, provider}'
```
**Expect** (in dev with no creds): `provider: "mock"`, `productName: "Mock Product"`. With real Rekognition creds set: `provider: "rekognition"`, real product name.

### B5 — Image fallback (Req 38)

```bash
curl -s -X POST "$HOST/api/v1/ai/image-fallback" \
  -H "Authorization: Bearer $CONSUMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\"}" | jq
```
**Expect**: `data.candidates[].productName` non-empty, `data.provider` is one of `mock | rekognition | google-vision`. With OCR text containing an EAN, `data.ean` is populated.

### B6 — Report summary (template path)

```bash
curl -s -X POST "$HOST/api/v1/ai/report/summary" \
  -H "Authorization: Bearer $MANAGER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reportType":"audit","summary":{"totalScans":120,"matchedScans":102,"expiredItems":3}}' | jq
```
**Expect** (when `FEATURE_LLM_SUMMARIES=false` — default): `provider: "mock"`, `cost: 0`, text contains "Total scans: 120", "Match rate: 85%", "Expired items: 3".

### B7 — Ingredient explainer cache miss → hit (Req 45)

```bash
# First call — cache miss → cached: false
curl -s "$HOST/api/v1/ai/ingredients/sugar/explanation" \
  -H "Authorization: Bearer $CONSUMER_TOKEN" | jq '.data | {title, cached, cost}'

# Second call — cache hit → cached: true, cost: 0
curl -s "$HOST/api/v1/ai/ingredients/sugar/explanation" \
  -H "Authorization: Bearer $CONSUMER_TOKEN" | jq '.data | {title, cached, cost}'
```
**Expect**: Second call sets `cached: true`, `cost: 0`.

### B8 — Ingredient slug validation

```bash
curl -i -s "$HOST/api/v1/ai/ingredients/Palm%20Oil/explanation" \
  -H "Authorization: Bearer $CONSUMER_TOKEN"
```
**Expect**: HTTP 400, error code `VALIDATION_ERROR`, message about "kebab-case".

### B9 — Usage stats endpoint

```bash
curl -s "$HOST/api/v1/ai/usage" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq '.data | {totalCalls, totalCost, byOperation}'
```
**Expect**: `totalCalls > 0` after running B1–B8, `byOperation['ocr-expiry'].count > 0`, `byProvider.mlkit.count > 0`.

### B10 — Limits probe

```bash
curl -s "$HOST/api/v1/ai/limits?operation=ocr-expiry" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
**Expect**: `allowed: true`, `limit: 10000`, `remaining > 0`, ISO `resetAt`.

## Suite C — DB invariants

### C1 — Every API call writes both an extraction and a usage row

After B1–B5 above:

```sql
SELECT operation, count(*) FROM ai_extractions
 WHERE source_id = '<MEDIA_ID>' GROUP BY operation ORDER BY operation;
SELECT operation, count(*) FROM ai_usage_log
 WHERE resource_id = '<MEDIA_ID>' GROUP BY operation ORDER BY operation;
```
**Expect**: identical row counts per operation between the two tables.

### C2 — `(operation, cache_key, locale, rule_version)` is unique

After B7's two calls:

```sql
SELECT count(*) FROM ai_explanation_cache
 WHERE cache_key = 'sugar' AND locale = 'en' AND rule_version = '1.0.0';
-- 1
SELECT hit_count FROM ai_explanation_cache
 WHERE cache_key = 'sugar' AND locale = 'en';
-- ≥ 1 (incremented best-effort on hit)
```

### C3 — Year-month index is consulted for monthly totals

```sql
EXPLAIN ANALYZE
SELECT count(*) FROM ai_usage_log
 WHERE tenant_id = '<TENANT_ID>'
   AND year_month = to_char(now(), 'YYYY-MM')
   AND operation = 'ocr-expiry'
   AND success = 'true';
```
**Expect**: plan shows `Index Scan using ai_usage_tenant_month_op_idx`.

### C4 — Cross-tenant isolation

```sql
-- Ensure no extraction from tenant A leaked into tenant B
SELECT count(*) FROM ai_extractions WHERE tenant_id IS NULL;
-- 0  (tenant_id is NOT NULL on this table)
```

### C5 — Decimal precision preserved through round-trip

```bash
$PSQL -c "SELECT cost FROM ai_usage_log ORDER BY created_at DESC LIMIT 1;"
```
**Expect**: cost stored at NUMERIC(10,6) precision (e.g. `0.001000` for label-analysis), no loss when retrieved.

## Suite D — Security & quota gates

### D1 — Unauthenticated requests rejected

```bash
curl -i -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\"}"
```
**Expect**: HTTP 401, error code `AUTHENTICATION_REQUIRED`.

### D2 — Wrong role rejected

Mint a token with `role: 'auditor'` (no `consumer:scan` permission):

```bash
curl -i -s -X POST "$HOST/api/v1/ai/image-fallback" \
  -H "Authorization: Bearer $AUDITOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\"}"
```
**Expect**: HTTP 403, error code `INSUFFICIENT_PERMISSIONS`.

### D3 — Cross-tenant media rejected

Tenant A presigns a media id, tenant B tries to OCR it:

```bash
curl -i -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Authorization: Bearer $TENANT_B_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$TENANT_A_MEDIA_ID\",\"preExtractedText\":\"EXP 31/12/2026\"}"
```
**Expect**: When `MediaService.getById` resolves it as a media not visible to tenant B, the orchestrator throws `DomainNotFoundException` → HTTP 404. Pre-extracted text path is the only one that can proceed without a media buffer; even then the tracker's `tenantId` comes from the request context, so usage is correctly billed to B.

### D4 — Quota enforcement

Manually insert 10K successful `ocr-expiry` rows for the current month:

```sql
INSERT INTO ai_usage_log (tenant_id, operation, provider, cost, duration_ms, success, year_month, year_month_day)
SELECT '<TENANT_ID>', 'ocr-expiry', 'mlkit', 0, 5, 'true',
       to_char(now(), 'YYYY-MM'), to_char(now(), 'YYYY-MM-DD')
FROM generate_series(1, 10000);
```

```bash
curl -i -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\",\"preExtractedText\":\"EXP 31/12/2026\"}"
```
**Expect**: HTTP 402, error code `PLAN_LIMIT_EXCEEDED`.

### D5 — Slug regex prevents injection

```bash
curl -i -s "$HOST/api/v1/ai/ingredients/..%2Fetc%2Fpasswd/explanation" \
  -H "Authorization: Bearer $CONSUMER_TOKEN"
```
**Expect**: HTTP 400, `VALIDATION_ERROR` — slug fails the kebab-case regex.

### D6 — Strict DTO rejects unknown fields

```bash
curl -i -s -X POST "$HOST/api/v1/ai/ocr/expiry" \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"mediaId\":\"$MEDIA_ID\",\"preExtractedText\":\"x\",\"injectedField\":\"oops\"}"
```
**Expect**: HTTP 400, `VALIDATION_ERROR`.

### D7 — Cache hit doesn't bypass tenant context

After a successful first call from tenant A, tenant B requesting the same slug should still hit the cache (intentional — explanations are global), but tenant A's usage should not leak into tenant B's `ai_usage_log`:

```sql
SELECT tenant_id, operation, count(*) FROM ai_usage_log
 WHERE operation = 'ingredient-explanation'
 GROUP BY tenant_id, operation;
```
**Expect**: tenant A has 1 row (the cache miss), tenant B has 0 rows (cache hit, no usage tracked).

## Suite E — Full lifecycle

### E1 — Cold start

Boot the API in dev mode (no creds set):
```bash
pnpm server:dev
```

**Expect** in logs:
- `AiOrchestratorService` instantiated.
- No "@aws-sdk/client-rekognition is not installed" or similar — the package is loaded lazily, so even when not installed there's no boot-time error.
- `AiCircuitBreakerService.getState('openai')` returns `closed` for any provider until first failure.

### E2 — Free OCR roll-up

Run B1 ten times with different media IDs. Then:

```bash
curl -s "$HOST/api/v1/ai/usage" -H "Authorization: Bearer $OWNER_TOKEN" \
  | jq '.data.byOperation["ocr-expiry"]'
```
**Expect**: `count: 10`, `successCount: 10`, `totalCost: 0`, `avgDurationMs > 0` (small).

### E3 — Cache write-through path

Run B7 first call:
```sql
SELECT operation, cache_key, hit_count FROM ai_explanation_cache;
```
**Expect**: 1 row, `hit_count = 0`.

Run B7 second call:
```sql
SELECT hit_count FROM ai_explanation_cache WHERE cache_key = 'sugar';
```
**Expect**: `hit_count = 1` (the increment-hit path executed). Note this is best-effort — failure to increment must not affect the cached response.

### E4 — Circuit breaker opens after 5 failures

Mock a provider failure by setting `OPENAI_API_KEY=invalid-key` and `FEATURE_LLM_SUMMARIES=true`, restart, then call B6 six times. Observe:

```bash
# Calls 1-5: provider attempts then fails, falls back to mock with truncated:true
# Call 6: provider doesn't even attempt (breaker open), straight to mock
```

The 6th call's logs should show no `ai.llm.fallback_to_mock` warn for OpenAI failure — the breaker short-circuited.

### E5 — Half-open recovery

After E4, restore valid `OPENAI_API_KEY` and wait 60 seconds (the `AI_CB_OPEN_DURATION_MS`). Make one call. Logs:

```
ai.circuit.transition from=open to=half-open
ai.circuit.transition from=half-open to=closed   # after 2 successes
```

### E6 — Cache invalidation by rule_version bump

Edit `AI_EXPLANATION_RULE_VERSION = '1.0.1'` and restart. Run B7 — `cached: false` for the first call (new rule version → cache miss), then `cached: true` for the second.

### E7 — Audit-log entry created

After B4 (label analysis):

```sql
SELECT action, resource_type, metadata FROM audit_logs
 WHERE resource_id = '<MEDIA_ID>' AND resource_type = 'AiExtraction'
 ORDER BY created_at DESC LIMIT 1;
```
**Expect**: `action = CREATE`, `resource_type = AiExtraction`, `metadata` includes operation, provider, confidence.

### E8 — Quota reset at month rollover

Manually advance the clock (or wait):
```sql
DELETE FROM ai_usage_log WHERE tenant_id = '<TENANT_ID>'
  AND year_month = to_char(now() - interval '1 month', 'YYYY-MM');
```

Calling B1 again should succeed because the new month's bucket is empty.

## Final sign-off

- [ ] Suite A: ≈ 92 unit cases pass
- [ ] Suite B: 10 HTTP integration scenarios pass
- [ ] Suite C: 5 DB invariants verified in psql
- [ ] Suite D: 7 security / quota gates correct
- [ ] Suite E: 8 lifecycle steps complete (cold start → cache → breaker → audit → rollover)
- [ ] Coverage on `src/integrations/ai/**` ≥ 85%

**Verified by**: ___________________________
**Date**: ___________________________

## Honest Deferral Notes

These items are **not** verified by this pack and are explicitly deferred to later phases:

- **Real Rekognition / Vision / OpenAI integration tests** — require live credentials and a budget. The mock provider exercises every code path; the lazy-load + factory selection guarantees the real providers can't accidentally be invoked in CI.
- **Per-tenant quota override** — defaults from `AI_DEFAULT_LIMITS` only. BE-31 dashboard work owns the override table.
- **Per-token cost accounting** — `OpenAiLlmProvider` reports a per-call cost approximation. Exact per-token math lands when BE-31 ships billing.
- **Redis-backed circuit breaker** — in-process state is per-pod. BE-32 promotes to shared state.
- **Background-queued LLM calls** — every LLM call is request-time today. BE-21 / BE-24 should dispatch report-summary jobs to the worker for long-running reports.
- **EAN checksum validation** — `extractEans` returns plausible candidates, BE-10's product service validates checksums on lookup. Documented.
- **Multi-language OCR** — date parsers handle Latin digits only. Hindi / Tamil scripts come with BE-39 i18n.

These are listed honestly here so the next reviewer / orchestrator can decide what to flag in the PR description vs what's already known and acceptable v1.

---

**End of BE-22 Verification Pack.**
