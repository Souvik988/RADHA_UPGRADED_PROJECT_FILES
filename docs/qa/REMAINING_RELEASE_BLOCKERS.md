# Remaining Release Blockers

Status: in progress

## Fixed During Audit

- MQA-001: Valid curated product scans rendered "Product not found" due mobile DTO drift. Fixed and pushed in `7729ed8`.
- MQA-002: Expiry surfaces called stale `/api/v1/expiry` routes without `storeId` and showed a false load error for no-store users. Fixed locally; verified with focused tests, analyzer, debug build and Mobile MCP screenshot.

## Open Blockers / Risks

### RB-001 - Whole-app mobile audit is not complete yet

- Severity: P1 until completed
- Remaining areas: Expiry selected-store create/calendar, Tasks, Profile/settings, catalog/search/detail, saved/shopping, locked subscription surfaces, EAN audit, label scan, gallery, bulk audit/history, localization/accessibility pass.

### RB-002 - CameraX warning on emulator scanner

- Severity: P2 pending physical-device confirmation
- Evidence: logcat warning during scanner open: emulator camera stack reported missing expected camera hardware.
- Current impact: no app crash; scanner fallback controls render.
- Required before release: verify on a real Android device with rear camera.

### RB-003 - Onboarding segment grid clipping

- Severity: P2
- Evidence: `docs/qa/screenshots/android-onboarding-segments.png`
- Required before release: adjust scroll/padding so all persona cards are fully readable above the CTA.

### RB-004 - Generic scan-result error state masks non-not-found errors

- Severity: P2
- Evidence: MQA-001 initially surfaced as "Product not found" even though root cause was DTO parse failure.
- Required before release: classify lookup errors in `ScanResultScreen` similarly to catalog product detail so unauthorized, offline, timeout, parse/server errors are not mislabeled as catalog misses.

### RB-005 - Expiry selected-store path still needs live business-account validation

- Severity: P2
- Evidence: `docs/qa/screenshots/android-expiry-no-store-fixed.png`
- Current impact: The current emulator session has no selected store, so live MCP validation covered the corrected no-store path. Widget and smoke tests cover the store-scoped API contract and create endpoint.
- Required before release: sign in with a business/staff account that has `selectedStoreId`, then live-test expiry list, create, refresh and calendar aggregation against real store records.
