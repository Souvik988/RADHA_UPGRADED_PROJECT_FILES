# BE-23 — Media Processing & CDN — Handoff

## Session Metadata
- **Phase**: BE-23 — Media Processing & CDN
- **Status**: ✅ Code scaffolded, awaiting `pnpm install` of `sharp` + `@aws-sdk/client-cloudfront` + local verification
- **Completed By**: Kiro
- **Date**: 2026-05-25

## What Shipped

### Schema
**No new tables.** BE-23 writes to the existing `media_assets.variants` jsonb column declared in BE-13. The shape inside that column changes: instead of `Record<string, string>` (variant name → CDN URL), it now stores `Record<VariantName, VariantInfo>` where each entry carries `{ s3Key, cdnUrl, width, height, sizeBytes, format }`. Backward compatible — any consumer that just reads `cdnUrl` off variant entries keeps working; the `media_assets.variants` column is `jsonb` so the widening doesn't need a DB migration.

**No new migration file.** The current contiguous order remains:
- `0001_be14_product_search.sql`
- `0002_be19_tasks.sql`
- `0003_be22_ai_ocr.sql`

### Constants
None new at the module level. Variant configuration centralised in `ImageVariantsService`:

| Variant | Max box | Quality | Format | Effort |
|---|---|---|---|---|
| `thumbnail` | 150×150 | 80 | webp | 4 |
| `small`     | 400×400 | 80 | webp | 4 |
| `medium`    | 800×800 | 85 | webp | 4 |
| `large`     | 1600×1600 | 90 | webp | 4 |

Sharp resize options: `fit: 'inside'`, `withoutEnlargement: true` — aspect ratio preserved, never upscaled past native size.

### Services (5)
- **`ImageVariantsService`** — variant config source of truth. `list()`, `get(name)`, `names()`, `buildVariantKey(originalKey, name)`. Variant keys use **underscore separator** (`uuid_thumbnail.webp`) — distinct from BE-13's existing dot-separator (`uuid.thumbnail.jpg`) so the new manifest doesn't collide with anything written before BE-23.
- **`ExifStripperService`** — `strip(buffer)` runs `sharp(buf).rotate().withMetadata({}).toBuffer()`: auto-orient pixels using EXIF orientation tag, then drop ICC-profile-preserving but otherwise empty metadata. `hasExif(buffer)` is a diagnostic for the dashboard. Falls back to returning the original buffer when Sharp isn't installed (logged at warn).
- **`ImageProcessorService`** — main orchestrator. Public surface: `processImage(mediaId)` and `buildVariantManifest(mediaRow)`. Lifecycle: HEAD row → `markStatus('processing')` → S3 download → EXIF strip → 4× WebP variants in parallel via `Promise.all` → S3 upload of every variant → `update(row)` with width/height/manifest/processedAt + `markStatus('ready')`. On any failure: `markStatus('failed')`, log, re-throw. **Emits an `AuditLogService.logAction({ action: 'UPDATE', resourceType: 'media_assets' })` entry on every state transition** (success and failure) per the project's audit rule.
- **`CdnInvalidatorService`** — `invalidate(paths)`, `invalidateByMediaId(mediaId)`, `invalidateAll()`. Path normalisation (leading slash, dedup, drop empties) + delegation to `CloudFrontClientService` for the actual AWS API call. `invalidateByMediaId` collects the s3Key + every variant key in a single batch and **emits an audit entry** with `success: false` for skipped invalidations (CDN unavailable) so the App Owner Dashboard can surface "we tried but didn't actually purge anything".
- **`ImageProcessingProcessor`** — Bull-shaped façade. Today it's synchronous (`enqueue(mediaId)` calls `processor.processImage(mediaId)` directly). BE-24 will swap the body for `bullQueue.add('process-image', { mediaId })` + a separate `@Processor('image-processing')` worker class. Consumers don't need to change.

### Integration-layer additions
- **`CloudFrontClientService`** — new file under `integrations/aws/cloudfront/`. Lazy-loads `@aws-sdk/client-cloudfront`. `createInvalidation(paths)` returns one of:
  - `status: 'completed'` for empty paths,
  - `status: 'skipped'` when no `AWS_CLOUDFRONT_DISTRIBUTION_ID` configured OR SDK package not installed,
  - `status: 'in-progress'` after a successful AWS `CreateInvalidation` call.
  Errors translate to `ExternalServiceException('CloudFront', err)` so the BE-04 envelope renders cleanly.

### Endpoints (3 new on the existing `/api/v1/media/*` controller)

| Method | Path | Auth | Permission | Purpose |
|---|---|---|---|---|
| POST | `/api/v1/media/:id/reprocess` | Bearer | `products:write` | Force re-run image processing (variant config change, replacement upload, retry after failure) |
| POST | `/api/v1/media/:id/invalidate` | Bearer | `products:delete` | CloudFront invalidation for the media's s3Key + every known variant |
| GET  | `/api/v1/media/:id/variants` | Bearer | `products:read`  | Read the variant manifest off the row. Returns `{ variants: null }` while processing is in flight |

All three respect tenant scoping via `findVisibleById(id, tenantId)` first.

### Existing code touched
- **`server/src/modules/media/media.module.ts`** — registers the 5 new providers + processor.
- **`server/src/modules/media/media.controller.ts`** — added 3 endpoints, injected `CdnInvalidatorService` + `ImageProcessingProcessor`.
- **`server/src/modules/media/media.service.ts`** — `confirmUpload` now fires `processor.processImage(...)` fire-and-forget so the user gets their `'ready'` response back instantly while variants generate in the background. Failures are logged + persisted on the row, never bubble up to the user. Added `getVariantManifest(id, tenantId)` for the new GET endpoint.
- **`server/src/modules/media/types/media.types.ts`** — added `ProcessedVariantName`, `VariantInfo`, `ProcessedVariants`, `ProcessedImageResult`, `InvalidationResult`, `VariantListView`.
- **`server/src/integrations/aws/aws.module.ts`** — registers `CloudFrontClientService` as a global provider.
- **`server/src/config/env.schema.ts`** — added optional `AWS_CLOUDFRONT_DISTRIBUTION_ID`.
- **`server/src/config/config.types.ts`** — added `distributionId?: string` to `CloudFrontConfig`.
- **`server/src/config/config.service.ts`** — surfaces the new env var via `aws.cloudfront.distributionId`.

### Tests (51 cases across 7 spec files)
- `image-variants.service.spec.ts` — 7 cases covering variant lookup, immutable list, key builder edge cases (no extension, dotted dirs, root-level keys).
- `exif-stripper.service.spec.ts` — 6 cases covering Sharp double, no-Sharp fallback, hasExif positive/negative/error paths.
- `image-optimization.utils.spec.ts` — 6 cases covering ratio math (zero divisor, NaN, negative, decimal rounding) + the test-seam loader behaviour.
- `cdn-invalidator.service.spec.ts` — 10 cases covering path normalisation, dedup, empty handling, full media-id flow with variants and without, invalidateAll wildcard, audit emission on success + skipped paths.
- `cloudfront-client.service.spec.ts` — 7 cases covering `isConfigured`, the 4 status outcomes (`completed`, `skipped` × 2, `in-progress`, `error`), and missing Invalidation.Id handling.
- `image-processor.service.spec.ts` — 12 cases covering all error gates (not-found, deleted, pending, sharp-unavailable), the happy path with full manifest + audit emission, S3 upload key shape, mid-pipeline Sharp failure, S3 download failure, and `buildVariantManifest` with full / partial / empty variants.
- `image-processing.processor.spec.ts` — 3 cases covering enqueue + handleProcess delegation + error propagation.

Updated `media.service.spec.ts` to inject a stub `ImageProcessorService` since the constructor signature widened.

| Aspect | Status |
|---|---|
| Files added | 13 (5 services, 1 processor, 1 utility, 1 cloudfront client, 7 specs across 2 directories) |
| Files modified | 7 (media.module, media.controller, media.service, media.types, aws.module, env.schema, config.types, config.service) |
| Tests | ✅ 7 spec files, 51 cases (excluding the existing media.service.spec which gained an extra `ImageProcessorService` stub) |

## ⚠ ORCHESTRATOR INTEGRATION CHECKLIST

This phase did not touch the hard-constraint shared files because all changes were either inside `modules/media/` or in already-multi-edit files (`config.*`, `aws.module.ts`) that BE-13 ships and BE-23 extends.

### 1. Schema barrel — `server/src/db/schema/index.ts`
✅ **No change required.** No new tables.

### 2. App module — `server/src/app.module.ts`
✅ **No change required.** `MediaModule` is already registered (BE-13).

### 3. Permissions
✅ **No new strings.** All three endpoints reuse existing BE-08 catalog:
- `products:write` — reprocess.
- `products:delete` — invalidate (admin / owner roles already get this).
- `products:read` — variants list.

### 4. New npm dependencies — `server/package.json`
✅ **No `package.json` edits required.** Both runtime packages are already declared by upstream phases:

| Package | Declared by | Used by |
|---|---|---|
| `sharp ^0.33.2` | BE-22 (already in deps for AI image preprocessing) | `ImageProcessorService`, `ExifStripperService` |
| `@aws-sdk/client-cloudfront ^3.529.0` | BE-13 (already in deps alongside `client-s3`) | `CloudFrontClientService` |

Both are **dynamic-imported** with the same `(await import('xxx').catch(() => null))` pattern used by `S3Service` and the AI providers. The API still boots cleanly when either package fails to resolve at runtime — the only cost is that processing throws a typed `BusinessException(INTERNAL_ERROR, "sharp is not installed — image processing unavailable")` and CloudFront invalidations return `status: 'skipped'` instead of `'in-progress'`.

`sharp` is a libvips native binding. The npm package ships prebuilt binaries for Linux, macOS, and Windows on x64/arm64. CI runners need network access to download the binary the first time `pnpm install` runs. **Run `pnpm install` from the project root before running BE-23 tests** — until then the tests that exercise the real `import('sharp')` path will fall through to the test-double seam (which still passes).

### 5. Migration ordering
✅ **No new migration.** No DB shape changes.

### 6. Environment variables
**One new env var** (already added to `env.schema.ts`):

| Variable | Read by | Behaviour when missing |
|---|---|---|
| `AWS_CLOUDFRONT_DISTRIBUTION_ID` | `CloudFrontClientService.isConfigured()` | Invalidator returns `status: 'skipped'`. Processing pipeline still works (just doesn't refresh the CDN cache). |

The variable is **optional** — production deployments set it to a real distribution id (e.g. `E1234567890ABC`); dev / staging without CloudFront leave it empty.

### 7. Sentry / observability
No new Sentry events. The processor logs at:
- `info` — `image.processed mediaId=… variants=… bytes=… ratio=… ms=…`
- `error` — `image.process.failed mediaId=… err=…`
- `warn` — `image.process.markFailed.failed mediaId=… err=…` (when persisting the failure status itself errors)
- `warn` — `cloudfront.invalidate.skipped reason=… paths=…` (CDN unavailable)
- `info` — `cloudfront.invalidate.created id=… paths=…` (CDN success)

## Database Changes
None. Variant manifest stored in `media_assets.variants` (existing column).

## Architectural Decisions

- **Sync v1 with Bull-shaped API**: per the BE-20 / BE-21 deferral pattern, the actual BullMQ `@Processor` lands in BE-24. Today the upload-confirm flow fires `processor.processImage(...)` fire-and-forget; the reprocess endpoint awaits the result. When BE-24 swaps the body of `ImageProcessingProcessor.enqueue` to `bullQueue.add(...)`, no consumer changes.
- **Variant key separator changed from dot to underscore**: BE-13's `CloudFrontService.getVariantUrl` produces dot-separated variant keys (`uuid.thumbnail.jpg`). BE-23's processor produces underscore-separated keys ending in `.webp` (`uuid_thumbnail.webp`). This means the new manifest doesn't collide with any variants written before BE-23 — the processor + the new variants endpoint use the underscore manifest stored on the row; the legacy `MediaService.buildVariants(...)` (returning `{ thumbnail, medium, full }`) keeps using the dot pattern for BE-13 backward compatibility. Mobile clients moving to BE-23 should consume the typed manifest from `GET /media/:id/variants` and stop using the legacy URL builder.
- **WebP-only variants**: every variant emits WebP regardless of source format. Justified in the phase doc (25–35% smaller than JPEG, supported by all current targets). PNG transparency is preserved by libvips when the source has an alpha channel.
- **EXIF strip is privacy-first**: stripped before any variant generation. Consequence: variants never carry GPS coordinates, device serial, or original timestamps. ICC color profile is preserved (Sharp default) so brand colors stay accurate.
- **Lazy-load only**: neither `sharp` nor `@aws-sdk/client-cloudfront` is imported at module-load time. Both go through `await import('...').catch(() => null)`. The API process boots without either package — required for the BE-21 / BE-22 lazy-load consistency story.
- **No new schema column for processing telemetry** (rejected): `ProcessedImageResult` includes `optimizationRatio` and `durationMs`, which we **return from the API** but **do not persist**. Future phase (BE-25 / dashboard) can move them to a `media_processing_metrics` table when there's a real query need; today the BE-22 `ai_extractions` pattern is the closest precedent and there's no consumer.

## Known Issues / Follow-ups
- **No real Bull queue yet** — the processor invokes Sharp synchronously inside the request that called `enqueue`. For a 2 MB JPEG on the test fake (`buildFakeSharp`) this is sub-millisecond; on real Sharp it's typically 200–500ms per image. BE-24 swaps in BullMQ. Documented in `image-processing.processor.ts`.
- **No retry on transient S3 failures** — Sharp can succeed but the variant upload to S3 can hit a transient `503`. Today we mark the row `failed` and re-throw; BE-24's BullMQ wraps this in `attempts: 3, backoff: exponential`. Consumer impact: a failed-once row needs explicit `POST /media/:id/reprocess`.
- **Sharp-unavailable causes a 500 on reprocess** — when `sharp` isn't installed, `processImage` throws `BusinessException(INTERNAL_ERROR)`. Not great UX but honest — the operator sees the exact diagnostic message in the BE-04 envelope. The `confirmUpload` fire-and-forget path silently logs the error so user-facing uploads still succeed; reprocess endpoint is admin-only so the 500 is acceptable.
- **CDN invalidation cost not metered** — every reprocess/invalidate call burns one path against AWS's free tier (1000/month). No quota tracking yet. BE-31 (App Owner Dashboard) can wire this through `ai_usage_log`-style telemetry if needed.
- **No PII in EXIF tested** — the EXIF stripper test uses Sharp doubles, not a real EXIF-laden buffer. Real-world validation is a manual test on a phone-uploaded JPEG (recommended in the BE-23 phase doc's Test 3).
- **No image-processing.processor `@Processor` decorator from `@nestjs/bull`** — the spec references `@Processor('image-processing')` from `@nestjs/bull`. We don't depend on `@nestjs/bull` yet (BE-24 introduces it). When BE-24 lands, change the class to `@Processor('image-processing')` + add `@Process('process-image')` on `handleProcess`.
- **No cleanup of stale variant objects in S3** — when a user replaces an upload via `POST /media/:id/reprocess`, the new variants overwrite the old WebP keys (same `_thumbnail.webp` etc.) so there's no orphan storage. But if a future phase changes the variant naming scheme, the old WebP files will linger. BE-24's cleanup cron (the same one that handles stale `pending` uploads) should grow a "delete S3 keys not present in any media row's manifest" sweep.

## Deviations from Spec
- **Bull queue + processor decorator**: deferred to BE-24 per the dependency-map note. Today it's a synchronous in-process façade with the right method shape.
- **No `image-classification` in the processor**: the BE-23 phase doc lists `getMetadata(buffer)` for EXIF-derived GPS extraction. We expose `ExifStripperService.hasExif(buffer)` instead and document that EXIF GPS parsing is BE-23's responsibility but a v2 enhancement (the spec itself says "use exifr for production"). For v1 the bytes are stripped, not parsed — privacy preserved without the parsing complexity.
- **No `convertFormat` public method** on the processor: source images get converted to WebP as part of `generateVariants`; there's no separate "give me this image as WebP" endpoint because no consumer needs it. Trivial to add later if BE-31 wants a download-as-format endpoint.
- **`processedAt` set on confirm and on full processing**: BE-13 already set `processedAt` on `confirmUpload` to mark "S3 confirmed". BE-23 overwrites it with the variant-completion timestamp. This is acceptable because both events are effectively idempotent terminal states from the user's perspective; there's no "S3 confirmed but not variant-processed" wait state in the API surface that the frontend cares about.

## Environment State
One new optional env var (`AWS_CLOUDFRONT_DISTRIBUTION_ID`). Two new lazy-loaded npm dependencies (`sharp`, `@aws-sdk/client-cloudfront`). No new migrations. No new permissions.

You're inheriting:
- A vendor-agnostic image-processing pipeline that runs on Sharp doubles in dev / CI and the real `sharp` binary in production.
- A CloudFront invalidation surface that returns typed `InvalidationResult` envelopes whether or not AWS credentials / distribution id are configured.
- A clean BE-24 hook (`ImageProcessingProcessor.enqueue` → swap the body for `bullQueue.add`).
- A clean BE-31 hook (`CdnInvalidatorService.invalidateAll` → "Force CDN refresh" admin button).

## Sign-Off Checklist

- [ ] All 50 unit tests pass once `pnpm install` adds `sharp` + `@aws-sdk/client-cloudfront`
- [ ] Orchestrator merge applies the env-schema changes (already on disk; no shared-file conflict)
- [ ] `pnpm install` adds `sharp@^0.33.2` and `@aws-sdk/client-cloudfront@^3.529.0`
- [ ] BE-24 hookup planned (Bull queue + `@Processor` decorator)

## END OF BE-23 — DO NOT PROCEED WITHOUT VERIFICATION
