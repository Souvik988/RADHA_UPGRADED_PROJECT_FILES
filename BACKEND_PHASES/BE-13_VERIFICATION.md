# BE-13 Verification Pack — Product Image Management & S3

> Run after `pnpm install && pnpm db:generate && pnpm db:migrate`. Six suites: pure-unit (A), HTTP integration (B), tenant invariants (C), security gates (D), idempotency (E), mock fallback (F).

## Pre-flight

```bash
HOST=http://localhost:3000
PSQL="psql $DATABASE_URL"

OWNER_TOKEN=...     # tenant owner with products:write
MANAGER_TOKEN=...   # tenant manager with products:read+write
FREE_TOKEN=...      # free_consumer (no products:write)
A_TOKEN=...         # tenant A owner
B_TOKEN=...         # tenant B owner
PRODUCT_ID=...      # any product the OWNER can see
```

Real AWS verification requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_S3_BUCKET` set in the API process. With those empty, BE-13 falls back to `MockS3Service` and Suite F applies instead of B.

## Suite A — Unit (no DB, no network)

```bash
pnpm --filter @radha/server test src/modules/media src/integrations/aws
```
**Expect**:
- `file-key.utils.spec.ts` — 11 cases.
- `image-validator.service.spec.ts` — 24 cases.
- `mock-s3.service.spec.ts` — 7 cases.
- `cloudfront.service.spec.ts` — 5 cases.
- `media.service.spec.ts` — 14 cases.

**Total**: 61 new cases. Cumulative project total ≈ 277.

## Suite B — HTTP integration on real S3

### B1 — Presign upload returns a usable URL

```bash
curl -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerType\": \"product\",
    \"ownerId\": \"$PRODUCT_ID\",
    \"contentType\": \"image/jpeg\",
    \"contentLength\": 102400
  }" | jq
```
**Expect**:
```json
{
  "data": {
    "mediaId": "<uuid>",
    "uploadUrl": "https://radha-dev-media.s3.ap-south-1.amazonaws.com/",
    "uploadFields": {
      "Content-Type": "image/jpeg",
      "x-amz-meta-media-id": "<uuid>",
      "key": "<tenantId>/product/<productId>/<mediaId>.jpg",
      "policy": "...",
      "x-amz-signature": "..."
    },
    "expiresIn": 600,
    "cdnUrl": "https://<cdn-domain>/<tenantId>/product/<productId>/<mediaId>.jpg",
    "s3Key": "<tenantId>/product/<productId>/<mediaId>.jpg"
  }
}
```
Confirm the row landed:
```sql
SELECT id, status, s3_key FROM media_assets WHERE id = '<mediaId>';
-- 1 row, status = 'pending'
```

### B2 — Direct upload to S3 (bypass backend)

Use the response from B1 and POST your image bytes directly to S3:
```bash
# Construct multipart form with all uploadFields then file=@payload.jpg
curl -i -X POST "<uploadUrl>" \
  -F "Content-Type=image/jpeg" \
  -F "key=<key from response>" \
  -F "policy=<policy from response>" \
  -F "x-amz-signature=<signature from response>" \
  -F "x-amz-meta-media-id=<mediaId>" \
  -F "x-amz-meta-tenant-id=<tenantId>" \
  -F "x-amz-meta-owner-type=product" \
  -F "file=@./test/fixtures/sample.jpg"
```
**Expect**: HTTP 204 from S3. The backend is never touched.

### B3 — Confirm upload

```bash
curl -s -X POST "$HOST/api/v1/media/<mediaId>/confirm" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"mediaId":"<mediaId>"}' | jq
```
**Expect**: `data.status = "ready"`, `data.uploadedAt` populated, `data.cdnUrl` resolves to a real image when fetched.

### B4 — Read media

```bash
curl -s "$HOST/api/v1/media/<mediaId>" -H "Authorization: Bearer $OWNER_TOKEN" | jq
```
**Expect**: full view including `variants.thumbnail | medium | full` (all three URLs identical until BE-23 ships, but valid URLs).

### B5 — List by owner

```bash
curl -s "$HOST/api/v1/media?ownerType=product&ownerId=$PRODUCT_ID" \
  -H "Authorization: Bearer $OWNER_TOKEN" | jq 'length'
```
**Expect**: a positive integer (the count of media for this product).

### B6 — Migrate from URL

```bash
curl -s -X POST "$HOST/api/v1/media/migrate-from-url" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"https://images.openfoodfacts.org/images/products/301/762/042/2003/front_en.3.400.jpg\",
    \"productId\": \"$PRODUCT_ID\"
  }" | jq
```
**Expect**: `data.status = "ready"`, `data.sourceUrl` = the OFF URL, `data.contentType` matches what OFF served. Confirm row + S3 object both exist.

### B7 — Delete media

```bash
curl -i -X DELETE "$HOST/api/v1/media/<mediaId>" -H "Authorization: Bearer $OWNER_TOKEN"
```
**Expect**: 204 No Content. Then:
```sql
SELECT deleted_at, s3_key FROM media_assets WHERE id = '<mediaId>';
-- deleted_at populated
```
And the S3 object is gone (`HEAD` returns 404).

## Suite C — Tenant isolation invariants

### C1 — Cross-tenant read returns 404

1. Tenant A uploads media (B1+B2+B3 above).
2. Tenant B tries to read it:
   ```bash
   curl -i -s "$HOST/api/v1/media/<A_mediaId>" -H "Authorization: Bearer $B_TOKEN"
   ```
   **Expect**: HTTP 404, `error.code = "E5000"` (NOT_FOUND).
3. Tenant B tries to delete it:
   ```bash
   curl -i -X DELETE "$HOST/api/v1/media/<A_mediaId>" -H "Authorization: Bearer $B_TOKEN"
   ```
   **Expect**: HTTP 404. The row remains. The S3 object remains.

### C2 — Global media (tenant_id IS NULL) visible to both

```sql
INSERT INTO media_assets (id, tenant_id, owner_type, owner_id, s3_bucket, s3_key,
                          content_type, content_length, status, uploaded_by)
VALUES ('22222222-2222-2222-2222-222222222222', NULL, 'product', '<global-product-id>',
        'radha-dev-media', 'global/product/<global-product-id>/22222222.jpg',
        'image/jpeg', 1024, 'ready', 'system');
```
Both tokens read it successfully:
```bash
curl -s "$HOST/api/v1/media/22222222-2222-2222-2222-222222222222" -H "Authorization: Bearer $A_TOKEN" | jq '.data.id'
curl -s "$HOST/api/v1/media/22222222-2222-2222-2222-222222222222" -H "Authorization: Bearer $B_TOKEN" | jq '.data.id'
```
Both responses succeed.

## Suite D — Security gates

### D1 — Unsupported content-type → 400

```bash
curl -i -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ownerType":"product","contentType":"application/exe","contentLength":1024}'
```
**Expect**: HTTP 400, `error.code = "E2000"` (VALIDATION_ERROR).

### D2 — Oversized request → 400

```bash
curl -i -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ownerType":"product","contentType":"image/jpeg","contentLength":52428800}'
```
**Expect**: HTTP 400. Size limit enforced before any AWS call.

### D3 — Magic-number rejection on URL migration

Stage a hostile URL responder (test fixture):
```bash
echo '<?php echo "evil"; ?>' > /tmp/evil.jpg
python3 -m http.server 8080 --directory /tmp &
```
Then:
```bash
curl -i -s -X POST "$HOST/api/v1/media/migrate-from-url" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"http://localhost:8080/evil.jpg\",\"productId\":\"$PRODUCT_ID\"}"
```
**Expect**: HTTP 400. Bytes recognised as not a real image.

### D4 — Free Consumer cannot upload

```bash
curl -i -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $FREE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ownerType":"product","contentType":"image/jpeg","contentLength":102400}'
```
**Expect**: HTTP 403 (`products:write` permission denied).

### D5 — Presigned URL expires

After D1-style presign, wait 11 minutes (or set `AWS_S3_PRESIGNED_EXPIRY_SECONDS=10` in dev), then attempt the upload:
**Expect**: 403 from S3 with `RequestTimeTooSkewed` / `Policy expired`.

### D6 — Confirm rejects size mismatch

Upload a file larger than declared:
1. Presign with `contentLength: 1024`.
2. Try to upload a 100 KB file.
**Expect**: 403 from S3 (`content-length-range` policy violation). The backend confirm path won't even fire because the upload itself fails.

## Suite E — Idempotency

### E1 — Double confirm returns the same row

```bash
curl -s -X POST "$HOST/api/v1/media/<mediaId>/confirm" -H "Authorization: Bearer $OWNER_TOKEN" -d "{\"mediaId\":\"<mediaId>\"}" -H "Content-Type: application/json"
curl -s -X POST "$HOST/api/v1/media/<mediaId>/confirm" -H "Authorization: Bearer $OWNER_TOKEN" -d "{\"mediaId\":\"<mediaId>\"}" -H "Content-Type: application/json"
```
**Expect**: both responses return `status: "ready"`. Single row in DB, single S3 object.

### E2 — Duplicate URL migration de-duplicates

Run B6 twice with the same URL + productId:
```bash
curl -s -X POST "$HOST/api/v1/media/migrate-from-url" -H "Authorization: Bearer $OWNER_TOKEN" -d "...same body as B6..."
curl -s -X POST "$HOST/api/v1/media/migrate-from-url" -H "Authorization: Bearer $OWNER_TOKEN" -d "...same body as B6..."
```
**Expect**: both responses identical (same mediaId, same s3Key). Confirm:
```sql
SELECT count(*) FROM media_assets WHERE source_url = '<the URL>' AND owner_id = '<productId>';
-- 1
```

## Suite F — Mock fallback (no AWS credentials)

Set `AWS_ACCESS_KEY_ID=""` and restart the API. Re-run B1:

```bash
curl -s -X POST "$HOST/api/v1/media/presign" \
  -H "Authorization: Bearer $OWNER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ownerType":"product","contentType":"image/jpeg","contentLength":102400}' | jq '.data.uploadUrl'
```
**Expect**: `"http://localhost:3000/_mock-s3/upload/..."`. The dev fallback is working — no AWS calls leaked.

Re-run B7 (delete) — the mock cleanup works without AWS credentials.

## Final sign-off

- [ ] Suite A: 61 unit cases pass
- [ ] Suite B: 7 HTTP integration cases on real S3 + CloudFront
- [ ] Suite C: tenant isolation verified in psql
- [ ] Suite D: 6 security gates fire correctly
- [ ] Suite E: idempotency confirmed (no duplicate rows / duplicate S3 objects)
- [ ] Suite F: mock fallback works without AWS credentials

**Verified by**: ___________________________
**Date**: ___________________________
