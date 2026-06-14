# Product Detail Completion Report

Generated: 2026-06-15

## Scope

This unit completes the Product Detail contract repair after the local commit recovery and API drift gate were established. The change is mobile-focused: it removes stale Product Detail API calls, keeps factual product/nutrition data visible when available, and localizes the new error and ingredient states across all supported app locales.

## Contract Repairs

| Old mobile surface | Status | Replacement / behavior |
| --- | --- | --- |
| `GET /api/v1/products/ean/{ean}` | Removed | `GET /api/v1/products/lookup/{ean}` |
| `GET /api/v1/allergens/product/{productId}` | Removed | Uses the lookup nutrition `containsAllergens` signal when present; otherwise shows an explicit unavailable state. |
| `POST /api/v1/ingredients/explain` | Removed | Inline Product Detail no longer posts raw ingredient lists. When a label is needed, users are routed to label scan. |
| `GET /api/v1/healthy-alternatives/{productId}` | Removed | Alternatives use `GET /api/v1/products/{ean}/alternatives`. |
| `GET /api/v1/public/products/{ean}` | Removed | No Product Detail caller remains; public product routes are slug/sitemap surfaces outside mobile Product Detail. |

Verified Product Detail routes now present in the generated contract matrix:

- `GET /api/v1/products/lookup/{ean}` locked
- `GET /api/v1/catalog/categories` locked
- `GET /api/v1/catalog/products` locked
- `GET /api/v1/ingredients/{slug}/explanation`
- `GET /api/v1/products/{ean}/alternatives`
- `GET /api/v1/saved-products`
- `POST /api/v1/saved-products`
- `DELETE /api/v1/saved-products/{id}`

## User-Facing Behavior

Product Detail now classifies lookup failures into explicit states:

- `404`: not found
- `401`: unauthorized
- `403`: forbidden
- connection error: offline
- timeout class / `408` / `504`: timeout
- all other failures: server failure

The screen preserves known product identity while section-level failures render localized, actionable states. A forbidden nutrition response no longer shows a retry button, while a timeout remains retryable.

Free factual product and nutrition information remains ungated because it is core trust data for scan and catalog decisions. Premium interpretation and follow-up actions stay entitlement-aware.

## Localization

Added 7 Product Detail messages across 6 locale files, for 42 localized entries:

- `catalogDetailIngredientNeedsLabel`
- `catalogDetailAllergenSignalDetected`
- `catalogDetailAllergenSignalUnavailable`
- `catalogDetailNutritionAccessDeniedTitle`
- `catalogDetailNutritionAccessDeniedBody`
- `catalogDetailNutritionTimeoutTitle`
- `catalogDetailNutritionTimeoutBody`

Generated localization Dart files were regenerated from the ARB sources.

## Tests Added Or Updated

- Product Detail 403 state: identity remains visible, access restriction appears, retry is hidden.
- Product Detail timeout state: identity remains visible and retry is available.
- Product lookup classifier: 401, 403, 404, offline, timeout and 500 mappings.
- Scan result smoke and integration stubs now use the canonical lookup envelope.
- Alternatives and legacy Product Detail tests now use `getProductLookup` instead of removed client methods.

## Verification

Passed:

- `flutter gen-l10n`
- `dart run build_runner build --delete-conflicting-outputs`
- `pnpm.cmd contracts:check`
- `flutter analyze --fatal-infos`
- `flutter test --reporter compact --file-reporter json:full_test_results.jsonl` - 243 tests passed
- `pnpm.cmd test -- modules/products/__tests__/consumer-catalog.service.spec.ts modules/products/__tests__/product-lookup.service.spec.ts modules/saved-products/__tests__/saved-products.service.spec.ts modules/payments/__tests__/payments.service.spec.ts modules/subscriptions/__tests__/subscriptions.service.spec.ts modules/tenants/__tests__/tenant-onboarding.service.spec.ts --runInBand` - 6 suites, 41 tests passed

Notes:

- The contract matrix currently reports 291 server routes, 81 mobile Retrofit routes, 107 dashboard BFF routes and 256 classified mismatches. The remaining mismatches are outside this Product Detail repair and include backend-only, dashboard, marketing, admin and not-yet-mobile-wired surfaces.
- The locked production drift gate is green.
- The Flutter dependency resolver reports newer package versions available; no dependency change was made in this unit.
