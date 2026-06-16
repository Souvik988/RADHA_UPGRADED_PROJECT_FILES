# Android Test Evidence

Status: in progress

## Device

- `emulator-5554`
- Android 14 emulator
- Screen size reported by Mobile MCP: 1080x2340
- Package: `com.radha.radha_mobile`

## Build And Install

- `flutter build apk --debug` passed.
- `flutter analyze` passed with no issues.
- APK installed through Mobile MCP from `apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- App launched through Mobile MCP.

## Automated Tests

- `flutter test test\core\network\dto\product_lookup_dto_test.dart` passed.
- `flutter test test\core\network\dto\product_lookup_dto_test.dart test\features\catalog\catalog_browse_test.dart test\features\product\product_detail_screen_test.dart` passed.
- `flutter test test\features\expiry\expiry_list_screen_test.dart test\features\home\home_screen_test.dart test\integration_smoke\expiry_flow_smoke_test.dart test\integration_smoke\auth_flow_smoke_test.dart test\core\offline\sync_service_test.dart` passed.
- `pnpm.cmd --filter @radha/server test -- bullmq-queue.provider.spec.ts --runInBand` passed earlier in this audit run.
- Full server test suite passed earlier in this audit run: 213 suites, 2061 tests.

## Manual Evidence Screenshots

- `docs/qa/screenshots/android-clean-launch.png`
- `docs/qa/screenshots/android-onboarding.png`
- `docs/qa/screenshots/android-onboarding-features.png`
- `docs/qa/screenshots/android-onboarding-segments.png`
- `docs/qa/screenshots/android-onboarding-segment-selected.png`
- `docs/qa/screenshots/android-auth-phone.png`
- `docs/qa/screenshots/android-auth-phone-invalid-partial.png`
- `docs/qa/screenshots/android-auth-phone-valid.png`
- `docs/qa/screenshots/android-auth-otp.png`
- `docs/qa/screenshots/android-auth-verified-home.png`
- `docs/qa/screenshots/android-scan-tab.png`
- `docs/qa/screenshots/android-scan-camera.png`
- `docs/qa/screenshots/android-scan-manual-entry.png`
- `docs/qa/screenshots/android-scan-manual-ean-entered.png`
- `docs/qa/screenshots/android-scan-result-amul-butter.png`
- `docs/qa/screenshots/android-scan-result-amul-butter-fixed.png`
- `docs/qa/screenshots/android-expiry-tab.png`
- `docs/qa/screenshots/android-expiry-no-store-fixed.png`

## API And DB Agreement Evidence

- Active DB row exists for global product EAN `8901262010016`: `Amul Pasteurized Butter`, brand `Amul`, status `active`, source `open_food_facts`.
- Authenticated API lookup for EAN `8901262010016` returned `found=true`, product name `Amul Pasteurized Butter`, brand `Amul`, source `open-food-facts`, nutrition present.
- Expiry mobile contract now targets backend `/api/v1/expiry-records`, which requires `storeId`, accepts comma-separated statuses, and returns a bare array. Widget/smoke tests cover list/home/create/offline-sync clients against that shape.
- Current emulator account has no selected store, so live Expiry validation is the no-store state rather than store-backed records.
