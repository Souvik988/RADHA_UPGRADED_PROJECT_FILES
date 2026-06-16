# RADHA Mobile MCP Full Audit

Status: in progress
Device: Android emulator `emulator-5554` / `RadhaPixel`
App package: `com.radha.radha_mobile`
Branch: `codex/radha-final-convergence`
Latest repair commit pushed: `7729ed8 fix(mobile): align product lookup nutrition dto`

## Environment Gates

- Docker Desktop started successfully.
- `radha-postgres` and `radha-redis` were healthy.
- API health returned `status=ok`.
- API readiness returned `status=ready`, with process and database checks ok.
- `pnpm.cmd --filter @radha/server db:migrate` completed with schema current.
- `pnpm.cmd --filter @radha/server db:import:curated` imported curated products; active DB contains global product row for EAN `8901262010016`.
- `pnpm.cmd contracts:check` passed.
- `flutter analyze` passed with no issues after the expiry repair.
- `flutter build apk --debug` passed after the mobile DTO and expiry repairs.
- Android install and launch through Mobile MCP passed.

## Repaired Defects

### MQA-001 - Product lookup DTO drift made valid curated scans show "Product not found"

- Evidence before fix: `docs/qa/screenshots/android-scan-result-amul-butter.png`
- Backend agreement check: authenticated `GET /api/v1/products/lookup/8901262010016?includeNutrition=true` returned `found=true`, product `Amul Pasteurized Butter`, brand `Amul`, source `open-food-facts`, nutrition present.
- Root cause: Flutter `ProductNutrition` expected `containsAllergens` and `isProcessed` as booleans, while the backend returns `containsAllergens: string[]` and `isProcessed: "not" | "lightly" | "ultra"`.
- Fix: `ProductNutrition` now parses allergen lists and processing-level strings; catalog detail reads derived getters.
- Regression test: `apps/mobile/test/core/network/dto/product_lookup_dto_test.dart`.
- Verification: `flutter test test\core\network\dto\product_lookup_dto_test.dart test\features\catalog\catalog_browse_test.dart test\features\product\product_detail_screen_test.dart` passed.
- Evidence after fix: `docs/qa/screenshots/android-scan-result-amul-butter-fixed.png`.
- Commit: `7729ed8`, pushed to origin.

### MQA-002 - Expiry surfaces used stale API contract and failed for no-store users

- Evidence before fix: `docs/qa/screenshots/android-expiry-tab.png`
- Root cause: Flutter was calling old `/api/v1/expiry` routes with UI-only statuses (`near_expiry`, `safe`) and no `storeId`; the backend exposes `/api/v1/expiry-records`, requires `storeId`, returns a bare array, and uses statuses `green`, `yellow`, `red`, `expired`, `unknown`.
- Secondary root cause: the active emulator session is a consumer/no-store account, so store-scoped expiry calls should not be attempted.
- Fix: the API client now reads raw expiry-record arrays from `/expiry-records` and wraps them for existing app code; list/home/calendar pass selected `storeId`; UI statuses map to backend statuses; create payload includes `storeId`, manufacture date, source and shelf location; no-store list/create/calendar states render intentionally.
- Calendar fix: the missing `/expiry/calendar` dependency was removed; the calendar now aggregates the canonical expiry-records list for the selected store/month.
- Regression tests: expiry list, home summary, auth smoke, expiry smoke and offline sync tests now use `/api/v1/expiry-records`.
- Verification: `flutter test test\features\expiry\expiry_list_screen_test.dart test\features\home\home_screen_test.dart test\integration_smoke\expiry_flow_smoke_test.dart test\integration_smoke\auth_flow_smoke_test.dart test\core\offline\sync_service_test.dart` passed.
- Verification: `flutter analyze` passed with no issues.
- Verification: `flutter build apk --debug` passed and the rebuilt APK was installed through Mobile MCP.
- Evidence after fix: `docs/qa/screenshots/android-expiry-no-store-fixed.png`.

## Screens Audited So Far

- Splash / cold launch
- Onboarding slide 1
- Onboarding slide 2
- Onboarding segment selector
- OTP phone entry
- OTP verification
- Home
- Scan permission prompt
- Scanner landing and fallback controls
- Manual barcode entry
- Scan result success and not-found paths
- Expiry tab no-store state
- Expiry API contract through widget/smoke tests

## Remaining Scope

- Expiry create/calendar with a selected business store account
- Tasks tab and create/detail flow
- Profile tab, settings, language, support, subscription, referrals
- Catalog browse/search/product detail from Home
- Saved products, shopping list, recall/allergen locked surfaces
- EAN audit, label scan, gallery path, bulk audit/history where practical on emulator
- Accessibility, localization, empty/loading/error state pass
- Final DB/API cross-checks and crash log scan
