# Implementation Plan: RADHA Mobile App (Flutter)

> Scope: Build the Flutter mobile app under `apps/mobile/` that consumes the already-shipped NestJS backend (~410 endpoints). Backend is complete and verified — these tasks deliver the consumer/staff/manager surfaces against it.
>
> Stack: Flutter 3.44 + Dart 3.12, Riverpod (state), GoRouter (navigation), Dio + Retrofit (typed HTTP), Drift (offline SQLite), flutter_secure_storage (tokens), mobile_scanner (camera/barcode), google_mlkit_text_recognition (OCR), Material 3 + custom design tokens (Pro Max guidelines applied).
>
> Backend base URL is read from `--dart-define=API_BASE_URL=...` at build time (default `http://localhost:3000/api/v1`).
>
> Each task references requirements from `.kiro/specs/radha-platform-design/requirements.md`. Tasks within the same phase that touch different folders are wave-parallelizable.

## Foundation

- [x] 1. Configure design tokens, theme, and dependencies
  - Update `apps/mobile/pubspec.yaml` to add Riverpod 2.5+, GoRouter 14+, Dio 5+, Retrofit 4+, json_annotation/json_serializable, build_runner, freezed, drift 2+, drift_flutter, sqlite3_flutter_libs, path_provider, flutter_secure_storage 9+, mobile_scanner 5+, google_mlkit_text_recognition 0.13+, intl, dio_smart_retry, connectivity_plus, package_info_plus, flutter_dotenv (dev), and dev deps for build_runner + drift_dev + json_serializable + retrofit_generator + freezed
  - Create `lib/design/tokens.dart` with color palette, spacing scale (4/8/12/16/24/32/48), radius scale (4/8/12/16/24/9999), typography scale (display/headline/title/body/label per Material 3) — applies UI/UX Pro Max §6 typography and high-end-visual-design ANTI-SLOP rules (no Inter, prefer Plus Jakarta or Geist locally; use Google Fonts package for Plus Jakarta Sans + JetBrains Mono)
  - Create `lib/design/theme.dart` with `radhaLightTheme()` and `radhaDarkTheme()` exposing a Material 3 `ThemeData` with seedColor, custom typography, generous component theme overrides for `FilledButton`, `OutlinedButton`, `TextField`, `Card`, `AppBar`, `BottomNavigationBar` matching the Pro Max + high-end-visual-design directives (no harsh shadows, premium spacing, 44pt+ touch targets)
  - Add `lib/design/widgets/primary_button.dart`, `secondary_button.dart`, `app_text_field.dart`, `section_header.dart`, `empty_state.dart`, `error_state.dart`, `skeleton_loader.dart` reusable primitives
  - Run `flutter pub get` then `flutter pub run build_runner build --delete-conflicting-outputs` to verify deps resolve
  - Verify: `flutter analyze` returns 0 errors
  - _Requirements: 39, 40 (token + theming foundation supports all surfaces)_

- [x] 2. Wire networking layer (Dio + interceptors + Retrofit client)
  - Create `lib/core/network/dio_provider.dart` exposing a singleton `Dio` with: base URL from `--dart-define=API_BASE_URL`, 15s connect timeout, 20s receive timeout, JSON content-type, `User-Agent: RADHA-Mobile/<version>`
  - Create `lib/core/network/interceptors/auth_interceptor.dart` that injects `Authorization: Bearer <accessToken>` from secure storage and on 401 attempts a single refresh-token rotation call to `/auth/refresh`, then retries the original request once
  - Create `lib/core/network/interceptors/logging_interceptor.dart` (dev-only via `kDebugMode`) that redacts `mobile`, `email`, `otp`, `password`, `accessToken`, `refreshToken` keys from request/response bodies — mirrors backend Requirement 37
  - Create `lib/core/network/interceptors/error_interceptor.dart` that converts `DioException` into typed `ApiException(statusCode, code, message, details)` with subclasses for 401 / 403 / 409 / 422 / 429 / 5xx
  - Create `lib/core/network/api_client.dart` as a Retrofit `@RestApi` client with method stubs for every endpoint group consumed in this milestone (auth, products, scans, expiry, tasks, inventory, grn, subscriptions, onboarding, allergen, expiry-calendar, recall, ingredient-explainer, healthy-alternatives, referrals, sync, ocr-fallback, shopping-list, public-product, weekly-digest)
  - Run build_runner to generate the Retrofit impl
  - Verify: `flutter analyze` clean
  - _Requirements: 1, 3, 5, 34, 37, 39_

- [x] 3. Set up secure session storage and auth state
  - Create `lib/core/auth/session_storage.dart` wrapping `flutter_secure_storage` with keys `access_token`, `refresh_token`, `user_id`, `tenant_id`, `roles_json`, `selected_store_id`, `device_id`
  - Create `lib/core/auth/auth_repository.dart` with methods `requestOtp(mobile)`, `verifyOtp(mobile, otp, requestId)`, `adminLogin(email, password)`, `refresh()`, `logout()`, `currentSession()`, `isLoggedIn()` — calls the Retrofit client and persists tokens via session_storage
  - Create `lib/core/auth/auth_controller.dart` (Riverpod `AsyncNotifier<AuthSession?>`) exposing `requestOtp`, `verifyOtp`, `logout`, `selectStore` and a `currentUserProvider` derived from it
  - Generate `lib/core/auth/auth_session.dart` as a `freezed` data class
  - Verify: `flutter test test/core/auth/auth_repository_test.dart` runs (write a stubbed mock test using `mocktail`)
  - _Requirements: 1, 3, 39_

- [x] 4. Set up GoRouter shell with auth-aware redirects
  - Create `lib/core/router/app_router.dart` exposing a `GoRouter` provider with routes: `/splash`, `/onboarding`, `/auth/otp`, `/auth/otp/verify`, `/select-store`, `/home`, `/scan`, `/scan/result/:ean`, `/expiry`, `/expiry/new`, `/tasks`, `/tasks/:id`, `/inventory`, `/inventory/stock-movement`, `/grn`, `/grn/:id`, `/grn/:id/items`, `/profile`, `/settings`, `/subscription`, `/shopping-list`, `/recall-alerts`, `/allergens`, `/referrals`, `/expiry-calendar`
  - Implement a global `redirect` callback that pushes to `/onboarding` if not seen, `/auth/otp` if no session, `/select-store` if session has no `selected_store_id`, otherwise to the requested route
  - Create a `RootShell` widget with bottom navigation (Home, Scan, Expiry, Tasks, Profile) using Material 3 `NavigationBar` — limit 5 tabs per UI/UX Pro Max nav rule
  - Wire `app_router_provider` into `MaterialApp.router` in `main.dart`
  - Verify: `flutter analyze` clean and `flutter test` for any provided unit tests passes
  - _Requirements: 4, 5, 39_

- [x] 5. Build splash screen and bootstrap sequence
  - Create `lib/features/splash/splash_screen.dart` that during display: ensures `package_info_plus` loads, generates/reads `device_id`, hydrates `AuthController` from secure storage, fetches `/auth/me` if a token exists, then redirects via GoRouter
  - Use design tokens for the splash visual: dark background, large brand wordmark, subtle animated mark loop (≤300ms, ease-out, no decoration-only motion per UI/UX Pro Max §7)
  - Verify: app runs in `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1` and routes to `/onboarding` on a fresh install
  - _Requirements: 39_

- [x] 6. Build onboarding flow (consumes BE-34)
  - Create `lib/features/onboarding/onboarding_screen.dart` — three-page swipeable intro using `PageView`, with the third page asking "Are you here for: shopping for yourself, or for managing a store?" (segments)
  - On finish, call `POST /onboarding/segment` with `{segment: 'consumer' | 'business'}` via the Retrofit client; persist `onboarding_complete = true` in secure storage; route to `/auth/otp`
  - Apply imagegen-frontend-mobile rules: clean first screen, short copy, generous spacing, no fake motivational filler, Plus Jakarta Sans display weight for headline
  - Verify: tapping through three screens produces a successful `POST /onboarding/segment` call (mock the endpoint with a Wiremock or simply rely on backend running locally in `flutter test` widget tests using `dio_mock_adapter`)
  - _Requirements: BE-34 onboarding (mapped via design.md), 5_

- [x] 7. Build OTP login screen (consumes Auth)
  - Create `lib/features/auth/otp_request_screen.dart` with a 10-digit Indian mobile input (formatter `+91 XXXXX XXXXX`), validation per UI/UX Pro Max forms checklist (`input-labels`, `error-placement`, `submit-feedback`), and a primary CTA that invokes `AuthController.requestOtp(mobile)`
  - Create `lib/features/auth/otp_verify_screen.dart` with a 6-digit OTP `Pinput` field, a 60-second resend cooldown (live countdown in the resend button), and CTA that calls `AuthController.verifyOtp(mobile, otp, requestId)`
  - Handle 429 by showing the retry-after seconds; handle 401 by clearing the OTP field and showing inline error
  - On success, route to `/select-store` (or `/home` if user has exactly one store)
  - Verify: log in against the live local backend; confirm a `user_sessions` row is created and tokens are stored in secure storage
  - _Requirements: 1, 3, 39_

## Core Capabilities

- [x] 8. Build Home dashboard
  - Create `lib/features/home/home_screen.dart` showing a personalised greeting (uses `currentUserProvider`), a quick-actions bento grid (Scan, Add Expiry, New Task, View Inventory), a "Today" summary block (near-expiry count, open tasks count, low-stock alerts count) loaded from `/expiry/near-expiry`, `/tasks?status=open`, `/inventory/low-stock` via parallel Riverpod providers
  - Apply design-taste-frontend §9 Bento paradigm: asymmetric grid (2-col with one tall card), generous padding (24-32), no nested cards, layout transitions on data change
  - Show skeleton loaders while data resolves; show beautifully composed empty states
  - Verify: `flutter analyze` clean; manual run loads counts from running backend
  - _Requirements: 14, 16, 18_

- [x] 9. Build barcode scanner screen (consumes Products R6 + Scan R11/R12)
  - Create `lib/features/scan/scan_screen.dart` using `mobile_scanner` with a live camera preview, a centered scan frame with corner indicators, a flashlight toggle, and a "scan history" bottom sheet
  - On EAN detected: validate format (EAN-8 / EAN-13 / UPC-A) client-side, then call `GET /products/lookup/{ean}` with the selected `storeId`
  - Route to `/scan/result/:ean` showing a `ProductResultCard` with: product name, brand, category, image (CachedNetworkImage), nutrition badges (high sugar/salt/fat/processed/child-suitable from `Health_Assessment`), approved-EAN status pill (pass/fail/unknown), and primary actions (Add to expiry, Add to stock, Save to shopping list)
  - If session is `ean_verification` type, also call `POST /scan-sessions/{id}/items` to record the pass/fail
  - Apply UI/UX Pro Max §2 Touch & Interaction: 44pt+ tap targets, haptic feedback on capture, immediate visual pressed feedback
  - Verify: `flutter analyze` clean; on web (`-d chrome`) emulate via barcode-image upload fallback
  - _Requirements: 6, 7, 8, 10, 11, 12_

- [x] 10. Build product detail / health card (consumes Products + Health Score + Allergen + Ingredient Explainer + Healthy Alternatives)
  - Create `lib/features/product/product_detail_screen.dart` displaying everything `GET /products/lookup/{ean}` returns, plus on demand: `GET /allergen/check/{productId}` (highlights user allergens against the user's allergen profile), `GET /ai/ingredients/explain` (BE-40), `GET /healthy-alternatives/{productId}` (BE-41) — wrap each in its own `AsyncValue` provider so loading/error states are local
  - Show Health label as a colored chip (healthy = emerald, moderate = amber, unhealthy = rose) — desaturated per design-taste-frontend rule "max 1 accent, saturation < 80%"
  - Provide an "Explain ingredients" button that calls the AI explainer endpoint and renders the response in a sheet
  - Verify: `flutter analyze` clean
  - _Requirements: 6, 8, BE-37 allergen, BE-40 explainer, BE-41 alternatives_

- [x] 11. Build expiry tracking flow (consumes Expiry R13/R14/R15 + Expiry Calendar BE-38 + Image OCR Fallback BE-45)
  - Create `lib/features/expiry/expiry_list_screen.dart` showing a tabbed list (Near-expiry / Expired / Safe), cursor paginated, sorted by `expiry_date asc`, with status pills and pull-to-refresh
  - Create `lib/features/expiry/expiry_create_screen.dart` allowing manual entry of `productId`, `mfgDate`, `expiryDate`, `batchNumber`, `quantity`, `location`; reject `mfgDate > expiryDate` client-side and show inline error
  - Add an "Use camera" path that uses `google_mlkit_text_recognition` on-device OCR to suggest dates; if confidence is low or local OCR fails, upload the image to `POST /image-fallback/extract-dates` (BE-45) for cloud fallback
  - Create `lib/features/expiry/expiry_calendar_screen.dart` rendering BE-38's calendar response as a month grid with red/amber/green dots per day (use `table_calendar` package)
  - Verify: `flutter analyze` clean; create a record against a running backend; confirm `expiry_records.status` is computed correctly server-side
  - _Requirements: 13, 14, 15, 30, 31, BE-38, BE-45_

- [x] 12. Build tasks flow (consumes Tasks R16)
  - Create `lib/features/tasks/tasks_list_screen.dart` with filter tabs (My Tasks, All, Completed), priority chips, and a FAB to create
  - Create `lib/features/tasks/task_detail_screen.dart` showing title, description, type, priority, due date, evidence requirement, status; provide "Start" / "Complete" / "Cancel" buttons gated on the legal transitions per R16; require evidence (photo upload via `POST /media/presign` then PUT to S3) when `requires_evidence = true`
  - Create `lib/features/tasks/task_create_screen.dart` (manager-only — gated on role) with title, description, type, priority, store, assignee picker, due date, evidence toggle
  - Verify: `flutter analyze` clean; all 5 transitions tested against running backend
  - _Requirements: 4, 16, 31_

- [x] 13. Build inventory + low-stock screens (consumes Inventory R17/R18)
  - Create `lib/features/inventory/inventory_list_screen.dart` showing current stock per product with batch breakdown, low-stock badge, and search
  - Create `lib/features/inventory/stock_movement_screen.dart` with two tabs (Stock In / Stock Out), each posting to the corresponding endpoint with reason picker, batch + expiry capture, quantity, notes; reject negative results client-side per R17.3
  - Create `lib/features/inventory/low_stock_alerts_screen.dart` listing active alerts with quick "Open in stock movement" action
  - Verify: `flutter analyze` clean; movements + alerts behave per R17, R18 against running backend
  - _Requirements: 4, 17, 18_

- [x] 14. Build GRN flow (consumes GRN R19/R20)
  - Create `lib/features/grn/grn_list_screen.dart` with status filter (Draft, Pending Review, Posted), sort by date desc
  - Create `lib/features/grn/grn_create_screen.dart` for the header (supplier picker, invoice number, invoice date, expected delivery)
  - Create `lib/features/grn/grn_items_screen.dart` to add items (product picker, quantity, batch, mfg/exp dates, unit price); reject `mfg > exp` client-side per R19.3; show running totals
  - Add "Move to Pending Review" and "Post" actions gated on permissions (post requires `post_grn`); show success summary including resolved low-stock alert count per R20
  - Verify: `flutter analyze` clean; full lifecycle works against running backend
  - _Requirements: 4, 19, 20_

- [x] 15. Build subscription + entitlement gating (consumes Subscription R21/R22 + Premium Consumer BE-36)
  - Create `lib/features/subscription/subscription_screen.dart` showing current plan, billing cycle, days remaining in trial, plan compare table (Free Trial vs Basic ₹49 vs Standard ₹99 vs Premium ₹199), and "Upgrade" CTA per plan
  - Create `lib/core/entitlements/entitlement_provider.dart` (Riverpod) caching `GET /subscription/status`; expose helpers `canAccess(Feature)`, `usageOf(Feature)`
  - Create `lib/design/widgets/locked_feature.dart` overlay that any feature screen can wrap to show "Upgrade required" if the entitlement is denied
  - Apply locked-feature overlays to: Advanced Reports, Inventory, GRN, Premium consumer features (allergen, recall alerts, weekly digest)
  - Verify: `flutter analyze` clean; locking behaves correctly against the running backend
  - _Requirements: 21, 22, BE-36_

- [x] 16. Build offline-first queue + sync (consumes Sync BE-44 + R38)
  - Create `lib/core/offline/db.dart` defining a Drift database with tables `pending_writes(id, endpoint, method, body_json, created_at, retry_count, last_error)` and `cached_products(ean, payload_json, fetched_at)`
  - Run drift generator to produce `db.g.dart`
  - Create `lib/core/offline/sync_service.dart` exposing `enqueue(write)`, `processQueue()`, `evictExpiredProductCache()`; on enqueue, immediately attempt the write — if offline (per `connectivity_plus`) or 5xx, store in `pending_writes` and retry with exponential backoff (1s, 2s, 4s, ...max 60s, max 6 retries)
  - Wire scan-create, expiry-create, task-status-change, stock-movement, grn-item-add to `enqueue()` instead of calling Dio directly
  - Add a `lib/features/sync/sync_status_banner.dart` shown across screens when there are pending writes
  - On startup and on connectivity change, run `processQueue()`; on 6 retry exhaustion, surface a notification to the user per R38.3
  - Verify: kill the backend, scan items, restart backend, confirm queue drains and entries appear in the database
  - _Requirements: 38, BE-44_

- [x] 17. Build allergen profile + recall alerts (consumes BE-37 + BE-39)
  - Create `lib/features/allergen/allergen_profile_screen.dart` to manage `GET/PUT /allergen/profile/{userId}` — multi-select chips for the standard allergen list (peanut, tree nut, dairy, eggs, soy, wheat, fish, shellfish, sesame, gluten, etc.)
  - Create `lib/features/recall/recall_alerts_screen.dart` consuming `GET /recall-alerts` with severity badges; tapping a row opens product detail
  - Wire allergen check into product detail screen (Task 10)
  - Verify: `flutter analyze` clean; tested against running backend
  - _Requirements: BE-37, BE-39_

- [x] 18. Build shopping list + healthy alternatives surfaces (consumes BE-55 + BE-41)
  - Create `lib/features/shopping_list/shopping_list_screen.dart` with add/remove/check-off semantics calling `GET /shopping-list`, `POST /shopping-list/items`, `PATCH /shopping-list/items/{id}`, `DELETE /shopping-list/items/{id}`
  - Add an "Add healthy alternative to list" action on the product detail screen that pushes the alternative directly into the shopping list
  - Verify: `flutter analyze` clean
  - _Requirements: BE-41, BE-55_

- [x] 19. Build referrals + multi-language switcher (consumes BE-43 + BE-42)
  - Create `lib/features/referrals/referrals_screen.dart` showing referral code, share button (uses `share_plus`), invitee count, rewards earned via `GET /referrals/me` and `POST /referrals/redeem`
  - Create `lib/features/settings/language_picker.dart` calling `PUT /user/language` with one of `en`, `hi`, `ta`, `te`, `bn`, `mr`; rebuild the app's `Locale` on change using a `LocaleController` Riverpod provider
  - Add `flutter_localizations` and an `l10n.yaml` + arb files for the 6 languages — only translate the foundational ~50 strings used in onboarding/auth/scanner/home; deeper translation is deferred
  - Verify: `flutter analyze` clean; switching languages re-renders the app
  - _Requirements: BE-42, BE-43_

## Quality and Polish

- [x] 20. Add error boundary, global snackbars, and connectivity banner
  - Create `lib/design/widgets/error_boundary.dart` wrapping the app with a `runZonedGuarded` block that captures uncaught exceptions and shows a friendly fallback screen with "Report" CTA
  - Add a global `lib/design/widgets/snackbar_host.dart` with success/info/error variants
  - Add `lib/design/widgets/connectivity_banner.dart` (sticky at bottom of `RootShell`) that watches `connectivity_plus` and shows "Offline — your work is being saved" when disconnected
  - Verify: `flutter analyze` clean
  - _Requirements: 38_

- [x] 21. Add splash icon, app icon, launch theme
  - Add `flutter_launcher_icons` and `flutter_native_splash` dev dependencies
  - Create a placeholder square brand mark at `apps/mobile/assets/brand/icon.png` (1024×1024) and `apps/mobile/assets/brand/splash.png`
  - Configure both packages in `pubspec.yaml` and run their generators for Android/iOS/Web
  - Verify: app icons render in `apps/mobile/android/app/src/main/res/`, `apps/mobile/ios/Runner/Assets.xcassets/`, and `apps/mobile/web/icons/`
  - _Requirements: 39 (polish, not a hard requirement; delivers a believable shippable artifact)_

- [x] 22. Write integration smoke tests for happy paths
  - Create `apps/mobile/integration_test/auth_flow_test.dart` simulating OTP request → verify → home land
  - Create `apps/mobile/integration_test/scan_flow_test.dart` injecting a mock `mobile_scanner` controller with a known EAN, asserting product detail loads
  - Create `apps/mobile/integration_test/expiry_flow_test.dart` adding an expiry record and asserting it appears in near-expiry list
  - Use `dio_mock_adapter` to stub backend responses so the tests run without a live server
  - Verify: `flutter test integration_test/` passes
  - _Requirements: covers R1, R6, R13_

- [x] 23. Final verification pass
  - Run `flutter analyze --fatal-infos` and resolve any remaining infos
  - Run `flutter test` and `flutter test integration_test/`
  - Run `flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1` and confirm `apps/mobile/build/web/main.dart.js` is produced
  - Confirm the app boots in Chrome and a real OTP login round-trips against the running backend
  - Update `RADHA_CLIENT_OVERVIEW.md` "What's done" section to mark mobile app as shipped
  - _Requirements: end-to-end verification_
