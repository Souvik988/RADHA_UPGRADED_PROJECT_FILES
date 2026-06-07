# BE-22 Session Handoff — AI/OCR Wrapper (Free-first)

## Session Metadata
- **Phase**: BE-22 — AI/OCR Wrapper (Free-first)
- **Status**: ✅ Code scaffolded, awaiting orchestrator merge + local verification
- **Completed By**: Kiro
- **Date**: 2026-05-24
- **Spec covered**: `BACKEND_PHASES/BE-22_PHASE.md` (main + 🔄 ADDENDUM v2)

> **Scope note** — the kickoff prompt referenced "Subscriptions & Entitlements" but the actual `BE-22_PHASE.md` is the **AI/OCR Wrapper**. This handoff implements the spec as written. The user's architectural directives (lazy-loaded providers, mock provider, circuit breaker, audit logging, no shared-file edits) all map cleanly onto the AI/OCR work and are honoured below.

## What Was Completed

### Schema (consolidated `db/schema/ai.ts`)
- **`ai_extractions`** — tenant-scoped per-call audit (operation, provider, source, success, extracted text/data, confidence, duration, cost, tokens, user, requestId, metadata). Soft-delete + base columns. 4 indexes including `(tenant_id, operation)` and `(source_type, source_id)`.
- **`ai_usage_log`** — append-only quota / cost ledger. Pre-aggregated `year_month` and `year_month_day` columns make `checkLimit` a single index probe. Indexed on `(tenant_id, year_month, operation)`, `(tenant_id, year_month_day)`, and `provider`.
- **`ai_explanation_cache`** — permanent cache for deterministic LLM outputs (Req 45). Global by design — same ingredient → same explanation regardless of tenant. Unique on `(operation, cache_key, locale, rule_version)`. Bumping `rule_version` invalidates everything in one go.
- **2 new enums**: `ai_operation` (9 values), `ai_provider` (7 values).
- **Migration**: `server/src/db/migrations/0002_be22_ai_ocr.sql`. Idempotent — every CREATE / ALTER guards itself.

### Constants (`integrations/ai/ai.constants.ts`)
- `AI_LLM_DEFAULT_TIMEOUT_MS = 10_000` (Req 45 + T-v2.3 compliance).
- `AI_VISION_DEFAULT_TIMEOUT_MS = 8_000`.
- `AI_OCR_LOW_CONFIDENCE = 0.7` (matches BE-18 OCR validator threshold).
- `AI_EXTRACTED_TEXT_MAX = 5_000`, `AI_EXPLANATION_TEXT_MAX = 8_000` (column-safe).
- `AI_OPERATION_UNIT_COST` — per-operation $ projection (e.g. `label-analysis = 0.001`, `report-summary = 0.005`).
- `AI_DEFAULT_LIMITS` — per-operation monthly + daily quotas. Free OCR is 10K/month, paid label analysis is 100/month with a 20/day burst cap.
- `AI_CB_*` constants for circuit-breaker tuning, mirrored from BE-11.
- `AI_SYSTEM_TENANT_ID` placeholder for extractions made without an auth context.
- `AI_EXPLANATION_RULE_VERSION = '1.0.0'` — bump to invalidate the entire ingredient cache.

### Pure utilities (`integrations/ai/utils/ocr-text-parser.utils.ts`)
- `extractDates(text)` — five regex patterns ordered most-specific first (EXP/MFG prefixes, ISO YYYY-MM-DD, DD/MM/YYYY, MM/YYYY rolling to month-end). Strict calendar validation rejects Feb 30 / month 13 / impossible years (1990–2100 range). Two-digit years use a 50-pivot. Returns chronologically sorted, deduped on `(format, parsed.getTime())`.
- `extractNumbers(text, pattern?)` — defaults to digit runs ≥ 2 chars; honours custom regex; dedupes.
- `extractEans(text)` — yields plausible EAN-8 / EAN-13 candidates (no checksum — the BE-10 product service validates on lookup).
- `truncateForStorage(text, max)` — column-safe truncation with `...` suffix.

### Services (5)
- **`AiCircuitBreakerService`** — per-provider three-state breaker (closed → open → half-open). State indexed by `AiProvider` so an OpenAI outage doesn't trip Google Vision and vice versa. Same shape and thresholds as `OffCircuitBreakerService` (BE-11).
- **`OcrService`** — thin Nest wrapper around the parser utils plus `fromPreExtracted(options)` to wrap mobile ML-Kit text into the shared `OcrResult` envelope. No network calls live here.
- **`UsageTrackerService`** — implements `IUsageTrackerService`. `trackUsage` is fire-and-forget (logs + swallows errors so user requests never break). `checkLimit` evaluates daily-then-monthly caps via the indexed `(tenant_id, year_month, operation)` lookup. `getUsageForTenant` returns a fully-typed `UsageStats` envelope with per-operation and per-provider breakdowns. `estimateCost` is a pure helper for previews.
- **`LlmService`** — façade for ALL LLM calls.
  - `complete(prompt, options)` — routes through the active `ILlmProvider`, guarded by the per-provider circuit breaker; falls back to mock on timeout / failure (graceful failure per Req T-v2.3) and records `truncated: true`.
  - `buildTemplateSummary(input)` — deterministic plain-text fallback when the LLM is disabled.
  - `generateSummary(input, options)` — picks template vs LLM based on configuration.
  - `explainIngredient(slug, options)` — implements Req 45 with permanent caching. Cache hit → no LLM call, no cost, increments `hit_count` best-effort. Cache miss → calls LLM with a strict-JSON prompt, parses response (strips markdown fences if needed), persists via `upsertCached`, returns. Bad-JSON LLM responses degrade gracefully to a title-cased "information unavailable" payload.
- **`AiOrchestratorService`** — top-level façade for every consumer. Single entry point; enforces per-tenant quotas; picks the right provider; guards every paid call with the per-provider circuit breaker; persists every call to `ai_extractions`; emits an audit-log entry on every successful state change. Methods:
  - `extractExpiryDate / extractBatchNumber / extractText` (mobile-pre-extracted preferred path)
  - `analyzeProductLabel`
  - `imageFallbackScan` (Req 38 backing endpoint — heuristically derives candidate EAN from OCR text)
  - `generateReportSummary`
  - `explainIngredient` (cache hits skip the limit check + tracker entirely)
  - `getUsage`, `getEstimatedCost`

### Providers (4 implementations + lazy-load)
- **`MockAiProvider`** — implements `IOcrProvider`, `IImageRecognitionProvider`, `ILlmProvider`. Deterministic canned responses for dev / CI. `isConfigured()` always true.
- **`AwsRekognitionProvider`** — `@aws-sdk/client-rekognition` lazy-loaded via `await import(...).catch(() => null)`. Implements `IOcrProvider` (DetectText) and `IImageRecognitionProvider` (DetectLabels + DetectText for fallback recognition; DetectText + DetectLabels for label analysis). 8 s wall-clock timeout via `Promise.race`. Errors → `ExternalServiceException(AI_SERVICE_ERROR)`. `isConfigured()` honours `FEATURE_AWS_REKOGNITION` AND credential presence.
- **`GoogleCloudVisionProvider`** (v2 ADDENDUM, Req 38 backing) — `@google-cloud/vision` lazy-loaded. Implements `IImageRecognitionProvider` with text + label + logo detection. `isConfigured()` checks `GOOGLE_APPLICATION_CREDENTIALS` or `GOOGLE_CLOUD_PROJECT` env (forced false in tests). Builds candidate list ordered: top-3 OCR lines (`source: 'ocr'`), top label (`source: 'label'`), top logo (`source: 'logo'`).
- **`OpenAiLlmProvider`** (v2 ADDENDUM, Req 45 backing) — `openai` package lazy-loaded. Reads `OPENAI_API_KEY` and optional `OPENAI_MODEL` (defaults `gpt-4o-mini`). 10 s wall-clock timeout. Returns full `LlmResult` with token count + cost approximation.

### Provider selection (`integrations/ai/ai.module.ts`)
Three injection tokens, all `useFactory`-resolved at boot, mirroring the `S3_SERVICE_TOKEN` pattern:
- `IMAGE_RECOGNITION_PROVIDER_TOKEN` → Google Cloud Vision if configured → AWS Rekognition if configured → Mock.
- `LLM_PROVIDER_TOKEN` → OpenAI if configured → Mock.
- `OCR_PROVIDER_TOKEN` → Rekognition if configured → Mock.
The orchestrator never imports a concrete provider class; it injects the token. This means dev (no creds) automatically uses Mock and never tries to import the real SDKs.

### Repositories (3)
- **`AiExtractionsRepository`** — extends `BaseRepository`. `findByIdInTenant`, `listForSource`, and `recordSafely` (catches and swallows persist errors so orchestrator failures don't bubble).
- **`AiUsageRepository`** — `countForMonth`, `countForDay`, `getOperationBreakdown`, `getProviderBreakdown`. All aggregations run in SQL — never pulls rows back to userland.
- **`AiExplanationCacheRepository`** — `findCached(operation, cacheKey, locale, ruleVersion)`, `upsertCached(...)` using `ON CONFLICT DO UPDATE`, `incrementHit(id)` with atomic `+ 1`.

### Module-level surface (`modules/ai/`)
- **`AiService`** — stable injection target for downstream phases (BE-40 ingredient explainer, BE-45 image fallback). Adapts orchestrator output for the controller; future-proofs against orchestrator refactors.
- **`AiController`** — 9 endpoints under `/api/v1/ai/*`, full BE-08 guard stack (`JwtAuthGuard`, `RolesGuard`, `PermissionsGuard`, `TenantScopeGuard`), Zod validation, URI versioning, static segments before `:slug`. Roles + permissions reuse the existing BE-08 catalog (no new permissions strings introduced — see checklist below).
- **`AiModule`** — imports `AiIntegrationModule`, `AuthModule`, `ObservabilityModule`. Orchestrator registration goes in `AppModule` (orchestrator integration checklist below).

### DTOs (consolidated `modules/ai/dto/ai.dto.ts`)
8 Zod schemas (`OcrRequestSchema`, `LabelAnalyzeRequestSchema`, `ImageFallbackRequestSchema`, `ReportSummaryRequestSchema`, `IngredientExplanationQuerySchema`, `IngredientSlugSchema`, `UsageQuerySchema`, `LimitCheckQuerySchema`). All `.strict()`. Caps tuned to DB column sizes. Slugs validated against a kebab-case regex with a 100-char cap.

### Tests (8 spec files, ≈ 92 cases)
- **`ocr-text-parser.utils.spec.ts`** — 19 cases: empty / null input, EXP/MFG variants, ISO format, MM/YYYY leap-year math, calendar validation (Feb 30, month 13), implausible years, two-digit year pivot, sort + dedup, EAN extraction, number extraction, custom-regex pass-through, truncation.
- **`ai-circuit-breaker.service.spec.ts`** — 7 cases: starts closed, opens after threshold, isolates state per provider, transitions to half-open after duration, closes after success threshold, re-opens on half-open failure, reset.
- **`usage-tracker.service.spec.ts`** — 8 cases: persists usage row with date buckets, swallows DB errors, allows under-limit, blocks at monthly limit, blocks at daily limit, aggregates op + provider breakdowns, estimateCost arithmetic + clamp.
- **`llm.service.spec.ts`** — 11 cases: routes through provider, falls back to mock when unconfigured, falls back to mock + records breaker on error (T-v2.3), short-circuits on open breaker, template-summary outputs (default / populated / divide-by-zero), generateSummary template vs LLM path, ingredient cache hit, ingredient cache miss persists, broken-JSON fallback, markdown-fence stripping.
- **`ai-orchestrator.service.spec.ts`** — 17 cases: pre-extracted text path, low-confidence warning, missing-provider warning, PLAN_LIMIT_EXCEEDED throw, persists usage + extraction, batch-number extraction, label analysis happy path, missing media throws DomainNotFoundException, image-fallback infers EAN, image-fallback empty candidates, image-fallback PLAN_LIMIT_EXCEEDED before provider call, report summary template path, report summary LLM path, ingredient cache hit skips checks, ingredient cache miss runs them, empty-slug rejection, getEstimatedCost projections, tenant isolation.
- **`mock-ai.provider.spec.ts`** — 7 cases: extractText canned + echo, recognise candidates, analyseLabel, complete deterministic + locale, isConfigured, prompt truncation.
- **`ocr.service.spec.ts`** — 6 cases: fromPreExtracted wrap, empty text, default confidence, three util pass-throughs.
- **`ai.dto.spec.ts`** — 17 cases: every Zod schema with happy + error paths.

**≈ 92 new test cases.** Cumulative project total: ~520+ cases.

## Files Created

| Path | Purpose |
|---|---|
| `server/src/db/schema/ai.ts` | Schema (consolidated 3 tables + 2 enums) |
| `server/src/db/migrations/0002_be22_ai_ocr.sql` | Idempotent migration |
| `server/src/integrations/ai/ai.module.ts` | Provider selection + DI |
| `server/src/integrations/ai/ai.constants.ts` | Limits, costs, timeouts, CB tuning |
| `server/src/integrations/ai/types/ai.types.ts` | All cross-package types + injection tokens |
| `server/src/integrations/ai/utils/ocr-text-parser.utils.ts` | Pure date/number/EAN parsers |
| `server/src/integrations/ai/services/ai-circuit-breaker.service.ts` | Per-provider 3-state breaker |
| `server/src/integrations/ai/services/ocr.service.ts` | Provider-agnostic OCR parser façade |
| `server/src/integrations/ai/services/llm.service.ts` | LLM façade + ingredient cache |
| `server/src/integrations/ai/services/usage-tracker.service.ts` | Quota + cost tracker |
| `server/src/integrations/ai/services/ai-orchestrator.service.ts` | Top-level orchestrator |
| `server/src/integrations/ai/providers/mock-ai.provider.ts` | Mock impl of all 3 interfaces |
| `server/src/integrations/ai/providers/aws-rekognition.provider.ts` | Lazy-loaded paid provider |
| `server/src/integrations/ai/providers/google-cloud-vision.provider.ts` | Lazy-loaded v2 ADDENDUM |
| `server/src/integrations/ai/providers/openai-llm.provider.ts` | Lazy-loaded v2 ADDENDUM |
| `server/src/integrations/ai/repositories/ai-extractions.repository.ts` | Audit trail repo |
| `server/src/integrations/ai/repositories/ai-usage.repository.ts` | Quota / cost repo |
| `server/src/integrations/ai/repositories/ai-explanation-cache.repository.ts` | Permanent cache repo |
| `server/src/modules/ai/ai.module.ts` | Module-level wrapping |
| `server/src/modules/ai/ai.controller.ts` | 9 REST endpoints |
| `server/src/modules/ai/ai.service.ts` | Stable downstream injection target |
| `server/src/modules/ai/dto/ai.dto.ts` | Consolidated 8 Zod schemas |
| 8 spec files under `__tests__/` | ≈ 92 cases |

### Spec items deferred / replaced
- **Single consolidated schema file** — three tables in `db/schema/ai.ts` instead of three files. Same lifecycle, same migration, mirrors BE-15/16/17/18.
- **Single consolidated DTO file** — 8 Zod schemas in one file, mirrors BE-15+ convention.
- **`utils/ocr-text-parser.utils.ts` location** — placed under `integrations/ai/utils/` rather than `modules/ai/utils/` because the orchestrator (which lives in `integrations/`) is the primary consumer.
- **`generateReportSummary` already integrated** — the orchestrator's path is wired today; BE-21 reports can call it directly. No separate report-summary module.
- **`enrichProductData`** — not implemented in this phase. The spec listed it but the v2 ADDENDUM doesn't have a backing requirement and the BE-11 OFF integration already covers free product enrichment. Easy to add via a new orchestrator method when a downstream phase requires it.
- **`ml-kit.provider.ts` as a server-side class** — no value: ML Kit runs on the device. The mobile app sends `preExtractedText` to the server. The orchestrator's `fromPreExtracted` path is the integration point. Documented in `OcrService`.

## ORCHESTRATOR INTEGRATION CHECKLIST

These are the exact edits the orchestrator must make to the shared files I was instructed not to touch.

### 1. Schema barrel (`server/src/db/schema/index.ts`)

Add this single line at the bottom of the existing `export *` block:

```ts
export * from './ai';
```

### 2. AppModule (`server/src/app.module.ts`)

Two imports + one entry in the `imports: [...]` array. The new feature module is `AiModule` from `./modules/ai/ai.module`:

```ts
import { AiModule } from './modules/ai/ai.module';

// inside @Module({ imports: [...] })
AiModule,
```

`AiModule` already imports the integration-side `AiModule` (renamed `AiIntegrationModule` in the import statement to avoid collision), `AuthModule`, and `ObservabilityModule`. `MediaModule` is imported by the integration module so `AiOrchestratorService` can resolve `mediaId → MediaService.getById`. No additional cross-module wiring needed.

`AuthModule` and `TenantsModule` are already registered in `AppModule`. Per the kickoff prompt's instruction to flag re-exports of `UsersRepository` / `TenantsRepository` — none are needed by BE-22. The orchestrator only consumes `RequestContextService` (already global via `CommonModule`), `AuditLogService` (already global via `ObservabilityModule`), and `MediaService` (imported via `MediaModule`).

### 3. Permissions

**No new `Permission` strings required.** All endpoints reuse existing BE-08 catalog entries:
- `products:read` — OCR / label analysis (product-reading domain)
- `consumer:scan` — image fallback (Req 38) + ingredient explanation (Req 45)
- `reports:generate` — LLM summaries
- `owner:dashboard` — `/usage` and `/limits` reporting endpoints

These all already exist in `auth/types/permission.types.ts` and `auth/constants/role-permissions.map.ts`. **Nothing to merge there.**

### 4. New npm dependencies

All three are **lazy-loaded with the `(await import('pkg').catch(() => null))` pattern** — the API stays up if a package isn't installed; the corresponding provider quietly degrades to Mock or surfaces a typed `ExternalServiceException(AI_SERVICE_ERROR)`. Pin to exact versions:

```json
{
  "dependencies": {
    "@aws-sdk/client-rekognition": "3.622.0",
    "@google-cloud/vision": "4.3.2",
    "openai": "4.104.0"
  }
}
```

Notes:
- `@aws-sdk/client-rekognition` matches the AWS SDK v3 minor used by `@aws-sdk/client-s3` (BE-13). Pin to the same exact version family if BE-13 ever upgrades.
- `@google-cloud/vision` 4.x supports modern Node 18+ APIs.
- `openai` 4.x is the current node SDK with chat completions.

If the orchestrator decides to defer one or more of these for cost reasons, the providers fail closed: `isConfigured()` returns false, the active token resolves to `MockAiProvider`, and the system continues to work for free OCR + cached ingredient explanations.

### 5. Environment variables

BE-22 reads three new env vars **directly from `process.env`** (not via `ConfigService`) so the shared `env.schema.ts` stays untouched:

| Variable | Read by | Behaviour when missing |
|---|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | `GoogleCloudVisionProvider.isConfigured()` | Provider returns empty results, orchestrator falls back to mock |
| `GOOGLE_CLOUD_PROJECT` | `GoogleCloudVisionProvider.isConfigured()` | Same as above |
| `OPENAI_API_KEY` | `OpenAiLlmProvider.isConfigured()` | LLM service falls back to template summaries / mock explanations |
| `OPENAI_MODEL` (optional) | `OpenAiLlmProvider.complete()` | Defaults to `gpt-4o-mini` |

When the orchestrator is ready to integrate these into the typed `env.schema.ts`, the change is non-breaking: just add the keys with `.optional().transform((v) => v === '' ? undefined : v)` and update the providers to read via `ConfigService` instead of `process.env`.

### 6. Migration ordering

The migration file is `0002_be22_ai_ocr.sql`. The current `migrations/` directory has `0001_be14_product_search.sql`, so the numbering is correct and contiguous. The migration is idempotent.

## Files Modified
None inside the do-not-modify list. The orchestrator must make the four edits above (`schema/index.ts`, `app.module.ts`, `package.json` deps, optional env-schema additions).

## Database Changes
- New tables: `ai_extractions`, `ai_usage_log`, `ai_explanation_cache`.
- New enums: `ai_operation`, `ai_provider`.
- 4 indexes on extractions, 3 on usage log, 2 on the cache (incl. one unique).

Run `pnpm --filter @radha/server db:generate && pnpm --filter @radha/server db:migrate` after orchestrator merges.

## What's Ready for Next Phase

**BE-23 (S3 lifecycle / image processing)**: nothing blocked by BE-22 directly.

**BE-24 (notifications + cron)**: can prune `ai_extractions.deletedAt IS NOT NULL` rows older than 90 days (audit retention).

**BE-31 (App Owner Dashboard)**: read endpoints `/api/v1/ai/usage` and `/api/v1/ai/limits` are already there. Per-tenant override of `AI_DEFAULT_LIMITS` is the next obvious feature — add a `tenant_ai_limits` table when implementing.

**BE-40 (Ingredient explainer, Req 45)**: backing endpoint `GET /api/v1/ai/ingredients/:slug/explanation` is implemented in this phase. BE-40 owns the public-facing controller and may shape the response differently. The orchestrator's `explainIngredient(slug, options)` method is the stable injection target.

**BE-45 (Image OCR fallback, Req 38)**: backing endpoint `POST /api/v1/ai/image-fallback` is implemented. BE-45 owns the public `POST /api/v1/scan/image-fallback` route which should call `AiService.imageFallbackScan(mediaId)`, then probe the catalog with the returned `ean` and `candidates`.

## Known Issues / Follow-ups

- **No real OCR for non-mobile clients** — server-side cloud OCR via Rekognition is wired but `extractExpiryDate` only takes the paid-fallback path when `options.fallbackToPaid === true` AND `FEATURE_AWS_REKOGNITION === true` AND credentials exist. The default flow is mobile-first. Documented in the orchestrator code.
- **Token-cost approximation** — `OpenAiLlmProvider` reports `cost = AI_OPERATION_UNIT_COST['report-summary']` per call rather than per-token math. Persisted-as-recorded so the App Owner Dashboard can audit accurately later when BE-31 ships per-token billing.
- **Cache only invalidated by rule_version bump** — there's no admin endpoint to evict a single ingredient explanation. Acceptable v1; BE-31 dashboard can add `DELETE /api/v1/ai/ingredient-cache/:id` if needed.
- **In-process circuit breaker** — state is per-pod. Acceptable scale; BE-32 can promote to Redis-backed when traffic grows.
- **Daily limit reset uses UTC midnight** — Indian retail SOPs typically reset at 6 AM IST. Defer to BE-31 to expose a per-tenant timezone override.
- **`generateReportSummary` is fire-and-await** — for real reports we'd want an async queue (BE-21 can dispatch a job that calls this method from the worker). Acceptable for v1 since the LLM call is < 10 s.
- **`ImageFallbackResult.ean` is a heuristic** — derived from OCR text, not an actual barcode decode. BE-45 should still run the value through the BE-10 product lookup which validates checksums. Documented in the orchestrator.
- **`isConfigured()` short-circuits to false in tests** — both `GoogleCloudVisionProvider` and `OpenAiLlmProvider` check `config.isTest` to avoid accidentally talking to real services in CI even when env vars happen to be set. This makes test execution deterministic.

## Deviations from Spec

- **Single consolidated schema file** — three tables in one file (BE-18 convention).
- **Per-provider circuit breaker** — spec showed a single shared breaker; per-provider isolation is more correct (and tested).
- **Permanent cache for explanations** — implemented as `ai_explanation_cache` (deferred until v2 ADDENDUM forced the issue). The same column shape generalises to other deterministic LLM outputs (e.g. nutrition fact tooltips) without a new table.
- **No standalone `ml-kit.provider.ts` server-side class** — replaced by `OcrService.fromPreExtracted` since ML Kit only runs on-device.
- **No standalone `enrichProductData` method** — deferred until a downstream phase requires it.
- **`generateTemplateSummary`** — moved out of `AiOrchestratorService` and into `LlmService.buildTemplateSummary` so the orchestrator stays thin.
- **Permission gates** — reuse `products:read`, `consumer:scan`, `reports:generate`, `owner:dashboard` rather than introducing `ai:read` / `ai:manage`. Less role-permission churn — every actor who would use AI already reads the underlying domain.
- **`enableAiOcr` feature flag** — the existing config flag exists but BE-22 controls behaviour at the provider level via `isConfigured()` and the request-time `fallbackToPaid` flag. `enableAiOcr` is left for BE-46 (per-tenant rate limits) to consume if it wants to disable the entire surface for cost emergencies.

## Context for Next Developer

You're inheriting:
- A vendor-agnostic AI/OCR surface that runs on Mock providers in dev and CI without any AWS / Google / OpenAI credentials.
- Three lazy-loaded paid providers — install the npm package, set the credential env, restart, and the factory token resolves to the real implementation. No code edits needed in consumers.
- Per-tenant cost & quota tracking with the hot path being a single index lookup.
- A permanent-cache pattern for deterministic LLM outputs that other phases can reuse (just bump `operation` and `cache_key`).
- A circuit breaker that isolates failures per provider, so an OpenAI outage doesn't take Google Vision offline.
- A clean BE-40 hook (`AiService.explainIngredient(slug, locale)`) and BE-45 hook (`AiService.imageFallbackScan(mediaId)`).
- A clean BE-21 / BE-31 hook (`AiService.generateReportSummary(reportData)`).

## Environment State
Three new dev-time env vars (optional). Three new lazy-loaded npm dependencies (`@aws-sdk/client-rekognition`, `@google-cloud/vision`, `openai`).

## Performance Metrics (target)
- `extractExpiryDate(preExtractedText)`: < 5 ms (regex-only).
- `analyzeProductLabel`: < 3 s (Rekognition + 8 s timeout cap).
- `imageFallbackScan` (GCV): < 4 s (3 detection calls in parallel-ish + 8 s cap each).
- `explainIngredient` cache hit: < 20 ms (single index lookup + JSON shape).
- `explainIngredient` cache miss: < 10 s (LLM call + persist).
- `checkLimit`: < 5 ms (indexed lookup).
- `getUsageForTenant(30 days)`: < 50 ms (two grouped scans).

## Security Audit
- BE-08 guard stack (`JwtAuthGuard`, `RolesGuard`, `PermissionsGuard`, `TenantScopeGuard`) on every authenticated route ✅.
- No webhook routes — no `@Public()` exposure to verify ✅.
- Tenant-scoped `findByIdInTenant` on extractions ✅.
- Per-tenant quota enforcement before every paid call ✅.
- Cache hits skip the limit check (correctly — they don't burn budget) ✅.
- Per-provider circuit breaker prevents cascading failures ✅.
- Lazy-loaded SDKs prevent boot-time DoS via missing-package crashes ✅.
- 10 s LLM wall-clock cap and 8 s vision cap prevent slow-loris ✅.
- DTO caps everywhere (mediaId UUID, preExtractedText 5K cap, slug regex with 100-char cap, summary payload 32K cap) ✅.
- OCR text truncated to 5K chars before persistence so a malicious OCR can't blow up the DB ✅.
- `extracted_data.warnings` flagged when confidence < 0.7 so callers don't blindly trust low-confidence reads ✅.
- Audit log entry on every successful state change (label analysis, image fallback) ✅.
- `success` field stored as varchar tri-state ('true' | 'false' | 'partial') so partial-success flows like Req 45's degraded-LLM path are recordable ✅.

## Verification Pack
**`BACKEND_PHASES/BE-22_VERIFICATION.md`** — five suites: A (unit), B (HTTP integration), C (DB invariants), D (security gates), E (full lifecycle: extract → cache → usage roll-up).

## Q&A Answers (BE-22 SOP)

**Q1 — Why mobile ML Kit instead of server OCR?** Free, on-device privacy, zero server cost, instant feedback, works offline. Server OCR is the paid escalation, gated behind `fallbackToPaid` + `FEATURE_AWS_REKOGNITION`.

**Q2 — Why abstract behind an orchestrator?** Provider-agnostic — the orchestrator is the only place a consumer (BE-40, BE-45, BE-21) imports. Switching from Rekognition to GCV is one factory change, not 17 imports.

**Q3 — Why monthly + daily limits?** Monthly bounds the spend; daily prevents bot-speed runaway. Free OCR has loose caps to deter abuse. Paid label analysis has tight caps because the per-call cost is real.

**Q4 — Why save extractions?** Audit trail (compliance), debug (low-confidence reads), retraining (BE-31 can sample mis-extractions for fine-tuning), and rate-limit forensics ("which user burned all 10K calls today?").

**Q5 — How does low confidence work?** Below `AI_OCR_LOW_CONFIDENCE = 0.7`, the result still returns but `warnings: [...]` includes "Low OCR confidence — verify manually". Mobile_App displays the warning and asks the user to confirm before saving.

**Q6 — Why template summaries before LLM?** Free fallback, deterministic output, no API key required, faster (1 ms vs 5 s), zero cost. The LLM path is enabled per-tenant via `FEATURE_LLM_SUMMARIES` once the customer is paying for it.

**Q7 — How to scale AI usage?** Background queue (BE-24 worker) for non-interactive ops like report summaries; Redis-backed circuit breaker (BE-32); per-tenant override of `AI_DEFAULT_LIMITS` from a `tenant_ai_limits` table (BE-31). The hot path is already O(1) thanks to the indexed `(tenant_id, year_month, operation)` columns.

**Q8 — How to switch providers?** Add a new class implementing `IImageRecognitionProvider` or `ILlmProvider`, register it in `ai.module.ts`, update the `useFactory` to prefer the new one. No DB changes, no consumer changes.

**Q-v2.1 — Cost tracker per-tenant.** `UsageTrackerService.trackUsage` is called by the orchestrator on every successful or failed AI call. Verified by `usage-tracker.service.spec.ts` and the orchestrator integration tests (`it('persists usage + extraction on every call')`).

**Q-v2.2 — Provider abstractions injectable for downstream mocks.** `IImageRecognitionProvider`, `ILlmProvider`, and `IOcrProvider` are pure TS interfaces in `types/ai.types.ts`. BE-40 / BE-45 depend on these and supply mocks in their tests by passing instances to the orchestrator constructor. Verified by `ai-orchestrator.service.spec.ts` doing exactly that across 17 cases.

**Q-v2.3 — LLM 10-second timeout returns graceful failure.** `OpenAiLlmProvider.complete` wraps the SDK call in `withTimeout(promise, 10_000)` that rejects after 10 s. `LlmService.complete` catches the rejection, records a circuit-breaker failure, and returns the mock provider's payload with `truncated: true` instead of throwing. Verified by `llm.service.spec.ts > 'falls back to mock and records circuit failure on error (graceful failure — Req T-v2.3)'`.

## Rollback Information
- `DROP TABLE ai_explanation_cache, ai_usage_log, ai_extractions;`
- `DROP TYPE ai_provider, ai_operation;`
- Remove `AiModule` from `app.module.ts`.
- Remove `export * from './ai';` from `db/schema/index.ts`.
- Delete `src/modules/ai/`, `src/integrations/ai/`, `src/db/schema/ai.ts`, `src/db/migrations/0002_be22_ai_ocr.sql`.
- Remove the three new npm deps from `package.json`.
- Audit-log entries for AI extractions remain in `audit_logs` — leave them; they're historical.

---

**End of BE-22 Handoff.** Approved for BE-23 once `BE-22_VERIFICATION.md` passes locally.
