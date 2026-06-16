# Screen And Control Matrix

Status: in progress

| Area | Screen | Controls checked | Evidence | Result | Notes |
| --- | --- | --- | --- | --- | --- |
| Startup | Splash | App launch, status/navigation bars | `android-clean-launch.png`, `android-first-launch.png` | Pass | Cold launch transitions to onboarding after app data reset. |
| Onboarding | Intro | Continue | `android-onboarding.png` | Pass with polish note | Large vertical whitespace on first viewport. |
| Onboarding | Feature slide | Continue | `android-onboarding-features.png` | Pass | Copy and icon hierarchy are readable. |
| Onboarding | Segment selector | Six persona cards, Get started disabled/enabled | `android-onboarding-segments.png`, `android-onboarding-segment-selected.png` | Pass with layout note | Bottom row is partly hidden behind sticky CTA on 1080x2340 emulator. |
| Auth | Phone entry | Field formatting, invalid partial input, valid input, Send OTP | `android-auth-phone.png`, `android-auth-phone-invalid-partial.png`, `android-auth-phone-valid.png` | Pass | Indian mobile formatter works; CTA state tracks validity. |
| Auth | OTP verify | Debug OTP helper, masked phone, resend copy, verify route | `android-auth-otp.png`, `android-auth-verified-home.png` | Pass | Debug OTP helper is visible only in debug build. |
| Home | Main dashboard | Search pill, KPI cards, health scan CTA, quick actions, bottom nav | `android-auth-verified-home.png` | Pass with UX note | Home and Scan both receive strong visual emphasis in bottom nav. |
| Scan | Permission prompt | Android camera permission choices | `android-scan-tab.png` | Pass | System prompt appears on first scan use. |
| Scan | Scanner | Back, gallery/stack, flash, scan label, gallery, manual entry, bulk audit, history | `android-scan-camera.png` | Pass with emulator caveat | Emulator camera logs CameraX missing expected camera warnings, no app crash. |
| Scan | Manual barcode | Enter barcode, Look up, dismiss | `android-scan-manual-entry.png`, `android-scan-manual-ean-entered.png` | Pass | Deterministic EAN lookup path works after DTO repair. |
| Scan | Result | Product header, approval pill, health card, explain ingredients, add to expiry/stock/save | `android-scan-result-amul-butter-fixed.png` | Pass with polish note | Health chip icons appear as tiny/odd glyphs in screenshot. |
| Expiry | No-store state | Tab navigation, empty-state copy, contact-manager CTA, hidden calendar/FAB | `android-expiry-tab.png`, `android-expiry-no-store-fixed.png` | Pass after repair | Old build showed a false load error; rebuilt APK now renders a deliberate no-store state for the current consumer account. |
| Expiry | API contract | List/home/calendar/create route contract through widget and smoke tests | Automated test logs | Pass after repair | Mobile now calls `/api/v1/expiry-records` with selected `storeId` and backend statuses `yellow,red`, `expired`, `green`. |

## Pending Screens

- Expiry create/calendar with a selected business store account
- Tasks list/create/detail
- Profile/settings/language/support/subscription/referrals
- Catalog search/browse/product detail
- Saved products/shopping list
- Recall/allergen locked states
- EAN audit, label scan, gallery, bulk audit/history
