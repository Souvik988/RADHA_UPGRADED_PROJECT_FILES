# RADHA — Validation Report (Subscription/Payment Sprint)

Branch `codex/radha-production-converged` (worktree from `origin/main` = `bd4710b`).
Date 2026-06-14. **No production infra was touched; no live payment was run.**

## Gates (executed here)
| Gate | Result |
|---|---|
| `flutter analyze --fatal-infos` | ✅ **No issues found** |
| `flutter test` | ✅ **227 passing** (45 test files; 0 failing) |
| `dart run build_runner build --delete-conflicting-outputs` | ✅ clean |
| `flutter build apk --debug` | ✅ success (`app-debug.apk`, 214 MB debug; release split ≈46 MB per prior build) |
| `flutter build web --release` | ⛔ N/A — project not web-configured |
| Backend `pnpm test` | ⛔ not run here — `server/node_modules` absent (deps not installed); **mobile-only changes don't touch backend** (was 2059/2059 per CLAUDE.md) |

## Commits on `origin/main`
`9d9814e` catalog port + UI foundation · `8640a51` convergence/contract docs ·
`6a99a8e` product-detail states · `86cb725` payment engine · `a1f3b0a` subscription
contract + entitlements · `1c9ca8c` subscription page · `e7d445e` payment-state-machine doc.

## Automated coverage (the "test every page/function" achievable without a device)
45 test files spanning every feature area + core + 3 integration-smoke flows:
- **Routing:** `core/router/app_router_test.dart` (every registered route builds).
- **Auth/onboarding/splash:** otp_screens, onboarding_screen, splash_screen, `integration_smoke/auth_flow_smoke` (OTP→verify→/home with mocked backend).
- **Catalog/product:** catalog_browse, **catalog_source** (live/offline/unavailable), **product_lookup_state** (404/401/500/offline classification), product_detail_screen.
- **Subscription/payment:** **checkout_engine** (14 — all branches), **subscription_screen** (3 — incl. UUID-not-code guard + billing cycle), entitlement_provider (server-status mapping).
- **Ops:** expiry, tasks, inventory, grn, ohs_dashboard, reports, settings, recall, allergen, alternatives, shopping_list, saved_products, referrals, digest, support, scan (ean_validator), `integration_smoke/{expiry,scan}_flow`.
- **Design/core:** radha_bottom_navigation, radha_status_chip, theme, connectivity_banner, snackbar_host, sync conflict, i18n locale, app_mode, error_codes, offline sync.

## What this sprint fixed & verified (with mocks/fakes)
- Catalog browse: honest live/offline/unavailable + retry; product detail: classified retryable failure states (no silent empty widget); free nutrition ungated.
- Subscription client aligned to plural `/subscriptions/*`; entitlements derived from `/subscriptions/status` (no hardcoded plan→feature map).
- Checkout sends the **plan UUID** (not a code) + explicit billing cycle; Razorpay engine: response validation, external-wallet-not-terminal, single-terminal guard, cancel≠failure, **pending-on-unconfirmed recovery**, timeout; entitlement refresh only after server verification. Banned "Cancel anytime · GST included" removed.

## Blocked in this environment (cannot be verified here — honest)
1. **Live device / mobile-MCP click-through:** no emulator/device connected (`mobile_list_available_devices` → empty; SDK emulator not at the standard path). To run: start an AVD (or plug a device), then `adb install build/app/outputs/flutter-apk/app-debug.apk`.
2. **Backend-dependent live flows & backend tests:** no backend running (nothing on :3000) and `server/node_modules` not installed. To run: `pnpm install && pnpm --filter @radha/server test`, and `pnpm server:dev` with Docker (Postgres 5433 / Redis 6380) up.
3. **Live test-mode Razorpay end-to-end:** needs the backend up with the `.env` test keys + a device. The engine is built to work against it; **no "live-payment-ready" claim is made** until that run passes.
4. **Performance profiling (DevTools):** needs a device/profile build.

## Remaining sprint tasks (not done)
- L10n of the new subscription/catalog strings across the 6 ARBs (currently English).
- Phase 9 backend contract tests verify/extend (run in the user's env per above).
- Phase 11 perf profiling on a device.
- A real device smoke + test-mode payment run, then update this report with results.
