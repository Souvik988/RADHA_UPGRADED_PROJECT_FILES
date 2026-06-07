# RADHA Mobile — Manual MCP Test Checklist

End-to-end smoke checklist for the Flutter app at `apps/mobile/`, driven through the two MCP servers configured in `.kiro/settings/mcp.json`:

- `mobile-mcp` (`@mobilenext/mobile-mcp@latest`) — drives a real iOS/Android simulator, emulator, or physical device.
- `playwright` (`@playwright/mcp@latest`) — drives the Flutter Web build running in Chromium.

The checklist mirrors the 23 tasks in `.kiro/specs/radha-platform-design/tasks.md`. Every step is user-runnable. Endpoints are cross-referenced against `API_CONTRACTS.md`.

> Default device IDs in this doc are placeholders. Run `mobile_list_available_devices` once and substitute the ID you get back as `<device-id>` everywhere below.

---

## A. Pre-flight setup

This whole checklist assumes Windows with `cmd.exe`, the Flutter SDK at `C:\src\flutter\bin\flutter.bat`, Docker Desktop installed, and the workspace open at the repo root.

### 1. Start Docker services (Postgres 5433 + Redis 6380)

From the workspace root in `cmd`:

```cmd
docker compose up -d
```

Verify:

```cmd
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

You should see Postgres mapped to `0.0.0.0:5433->5432/tcp` and Redis mapped to `0.0.0.0:6380->6379/tcp`. These ports are intentional — `server/.env.development` reads them.

### 2. Start the NestJS backend (port 3000)

```cmd
pnpm install
pnpm server:dev
```

Wait for `Nest application successfully started` in the logs. From a second terminal:

```cmd
curl http://localhost:3000/api/v1/health
```

Expected: `{"success":true,"data":{"status":"ok",...}}`. If `health` returns 404, the API base path is wrong — re-check `server/.env.development` (`API_PREFIX=api/v1`).

### 3a. Run the mobile app on Chrome (Flutter Web)

```cmd
cd apps\mobile
C:\src\flutter\bin\flutter.bat run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

When the build finishes, Flutter prints a `http://localhost:<random-port>` URL. The Playwright MCP will navigate to that URL.

Tip: a convenience script lives at `apps/mobile/tool/start_dev.bat`. Double-click it or run from `cmd`:

```cmd
apps\mobile\tool\start_dev.bat
```

### 3b. Run the mobile app on an Android emulator

Android's loopback to the host machine is `10.0.2.2`, NOT `localhost`. Adjust `API_BASE_URL` accordingly.

```cmd
C:\src\flutter\bin\flutter.bat devices
cd apps\mobile
C:\src\flutter\bin\flutter.bat run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

(Replace `emulator-5554` with the device ID from `flutter devices`.)

### 3c. Run the mobile app on an iOS simulator (macOS only)

```cmd
C:\src\flutter\bin\flutter.bat run -d "iPhone 15 Pro" --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

iOS simulators share `localhost` with the host machine.

### 4. Verification gates

Before starting the smoke flow, all four must be true:

- [ ] `docker ps` lists the two RADHA containers (`postgres`, `redis`) on ports 5433 and 6380.
- [ ] `curl http://localhost:3000/api/v1/health` returns `success: true`.
- [ ] The mobile app shows the splash screen with the RADHA wordmark and an emerald progress indicator.
- [ ] The splash redirects to `/onboarding` (fresh install) within 2 seconds.

---

## B. Smoke flow checklist (per task)

Conventions used in every subsection:

- **Endpoints** are pulled from `API_CONTRACTS.md`. The base URL is `http://localhost:3000/api/v1`.
- **MCP tool** picks the right MCP based on target. Use `mobile-mcp` for native (Android emulator, iOS simulator, real device). Use `playwright` for Chrome.
- **Pass criteria** is what to assert. If any line fails, log it as a defect and continue.

---

### Task 1 — Design tokens, theme, dependencies

**What to test**

1. App fonts are Plus Jakarta Sans (display/body) and JetBrains Mono (mono code). No Inter, no Roboto fallback.
2. Primary accent is a single emerald (`#0F9D58`-ish), not purple/blue.
3. Touch targets on every interactive control are ≥ 44 logical pixels.
4. Card corners are rounded but not over-rounded (radius 12–16, not 24+).

**Expected outcome**

- Type styling is consistent across splash, onboarding, OTP, home.
- No native-default Material purple anywhere.

**Backend endpoints hit**: none.

**MCP tool**

- `playwright`: `browser_navigate` to the running URL → `browser_snapshot` → inspect computed styles via `browser_evaluate`:
  ```js
  () => getComputedStyle(document.body).fontFamily
  ```
- `mobile-mcp`: `mobile_take_screenshot` for visual review.

---

### Task 2 — Networking layer (Dio + interceptors + Retrofit)

**What to test**

1. Every authenticated request includes `Authorization: Bearer <token>` once a session exists.
2. Sensitive fields (`mobile`, `otp`, `password`, `accessToken`, `refreshToken`) are redacted in logs.
3. A 401 on a protected route triggers a single refresh + retry.
4. `User-Agent` header reads `RADHA-Mobile/<version>`.

**Expected outcome**: redaction visible in DevTools console; 401 → refresh round-trip works without bouncing the user to login if the refresh succeeds.

**Backend endpoints hit**: `POST /auth/refresh`.

**MCP tool**

- `playwright`: `browser_network_requests` and `browser_network_request <n> request-headers` to inspect headers; `browser_console_messages` to verify redaction.

---

### Task 3 — Secure session storage and auth state

**What to test**

1. After OTP verify, `access_token` and `refresh_token` exist in secure storage (keychain on iOS, EncryptedSharedPreferences on Android, IndexedDB on web).
2. `currentUserProvider` exposes the logged-in user.
3. Logout clears all six keys (`access_token`, `refresh_token`, `user_id`, `tenant_id`, `roles_json`, `selected_store_id`).

**Expected outcome**: closing and reopening the app keeps you signed in; logout always returns you to `/auth/otp`.

**Backend endpoints hit**: `POST /auth/logout`.

**MCP tool**

- `mobile-mcp`: relaunch with `mobile_terminate_app` then `mobile_launch_app` and confirm you land on `/home`, not `/auth/otp`.
- `playwright`: `browser_evaluate(() => Object.keys(window.localStorage))` to confirm tokens cleared after logout.

---

### Task 4 — GoRouter shell with auth-aware redirects

**What to test**

1. Fresh install routes through `/splash` → `/onboarding` → `/auth/otp`.
2. Logged-in user with one store routes to `/home` directly.
3. Logged-in user with multiple stores routes to `/select-store`.
4. Bottom navigation has exactly 5 tabs (Home, Scan, Expiry, Tasks, Profile).
5. Deep-linking to a protected route while logged out redirects to `/auth/otp`.

**Expected outcome**: redirects fire deterministically; no flash of protected content.

**Backend endpoints hit**: `GET /auth/me`, `GET /stores`.

**MCP tool**

- `playwright`: `browser_navigate('http://localhost:<port>/#/inventory')` while logged out → expect URL to settle on `/auth/otp`.

---

### Task 5 — Splash screen and bootstrap

**What to test**

1. RADHA wordmark renders, with a thin emerald progress indicator below.
2. Splash dismisses in ≤ 2 seconds.
3. Bootstrap fetches `/auth/me` only if a token exists.

**Expected outcome**: smooth fade-out, no flicker, no Material default purple.

**Backend endpoints hit**: `GET /auth/me` (only if a token is present).

**MCP tool**

- `playwright`: `browser_take_screenshot({ filename: 'splash.png' })` immediately after `browser_navigate`. Then `browser_wait_for({ time: 2 })` and screenshot again to confirm the next route rendered.
- `mobile-mcp`: `mobile_launch_app` then `mobile_take_screenshot` twice with a 1.5s gap.

---

### Task 6 — Onboarding flow (BE-34)

**What to test**

1. Three swipeable intro pages, no fake testimonials or motivational filler.
2. Final page asks "shopping for yourself" vs "managing a store" with two segments.
3. Tapping a segment posts to `POST /onboarding/segment` with `{segment: 'consumer' | 'business'}`.
4. After success, persists `onboarding_complete = true` in secure storage and navigates to `/auth/otp`.

**Expected outcome**: re-running the app skips onboarding.

**Backend endpoints hit**: `POST /onboarding/segment`.

**MCP tool**

- `mobile-mcp`: `mobile_swipe_on_screen({ direction: 'left' })` twice, then `mobile_list_elements_on_screen` to find the "Managing a store" segment, then `mobile_click_on_screen_at_coordinates`.
- `playwright`: same flow via `browser_click` against the segment buttons.

---

### Task 7 — OTP login

**What to test**

1. Mobile field formats input as `+91 XXXXX XXXXX`.
2. CTA labelled "Send OTP" is disabled until 10 digits are entered.
3. Tapping Send OTP calls `POST /auth/otp/request` with `{mobile: '+919999912345'}` and returns a `requestId`.
4. OTP screen renders a 6-digit Pinput; resend cooldown counts down from 60.
5. Entering `123456` (the dev OTP if `OTP_PROVIDER=dev`) and submitting calls `POST /auth/otp/verify` and lands on `/select-store` or `/home`.
6. 429 from the rate limit shows "Too many attempts, retry in N seconds".
7. 401 on bad OTP clears the Pinput and surfaces an inline error.

**Expected outcome**: a `user_sessions` row is created on success; tokens persisted.

**Backend endpoints hit**: `POST /auth/otp/request`, `POST /auth/otp/verify`.

**MCP tool — sample run on `mobile-mcp`**

```text
mobile_list_available_devices                          → pick <device-id>
mobile_use_device({ device: <device-id> })
mobile_launch_app({ device, packageName: 'com.radha.mobile' })
mobile_take_screenshot                                  # confirm OTP screen
mobile_list_elements_on_screen                          # locate mobile input
mobile_click_on_screen_at_coordinates({ x, y })         # focus input
mobile_type_keys({ text: '9999912345', submit: false })
mobile_list_elements_on_screen                          # locate "Send OTP" CTA
mobile_click_on_screen_at_coordinates({ x, y })
mobile_take_screenshot                                  # confirm OTP verify screen
mobile_type_keys({ text: '123456', submit: true })
mobile_take_screenshot                                  # confirm /home
```

---

### Task 8 — Home dashboard

**What to test**

1. Personalised greeting uses the logged-in user's name.
2. Bento grid shows four quick-action cards (Scan, Add Expiry, New Task, View Inventory) with one tall card on the left.
3. "Today" summary loads three counts in parallel: near-expiry, open tasks, low-stock alerts.
4. Skeleton loaders show while data is in-flight.
5. Empty states are designed (not "No data").

**Expected outcome**: counts match a manual SQL count against the dev database.

**Backend endpoints hit**: `GET /expiry/near-expiry`, `GET /tasks?status=open`, `GET /inventory/low-stock`.

**MCP tool**

- `playwright`: `browser_snapshot` to capture the accessibility tree; verify the bento cards have role `button` and accessible names.

---

### Task 9 — Barcode scanner

**What to test**

1. Camera preview renders with a centred scan frame and corner indicators.
2. Flashlight toggle is reachable with one tap.
3. A scanned EAN-13 (e.g. `8901030865278` — Maggi 70g, common Indian retail SKU) calls `GET /products/lookup/{ean}?storeId=...` and routes to `/scan/result/:ean`.
4. Result card shows product name, brand, category, image, health badges, and approved-EAN status pill.
5. Haptic feedback fires on capture (native only).
6. EAN-8 / UPC-A also work.
7. Invalid EAN (e.g. `1234`) rejects client-side with an inline message.

**Expected outcome**: a `scans` row is inserted; if session is `ean_verification`, a `scan_session_items` row is too.

**Backend endpoints hit**: `GET /products/lookup/{ean}`, `POST /scan-sessions/{id}/items`.

**MCP tool**

- Real camera scanning is not testable in headless Chrome — use a real device via `mobile-mcp` or a barcode-image upload fallback.
- `mobile-mcp`: aim the device camera at a printed EAN-13. Use `mobile_take_screenshot` to confirm the result card rendered.

---

### Task 10 — Product detail / health card

**What to test**

1. Health label chip color matches the assessment (emerald = healthy, amber = moderate, rose = unhealthy).
2. "Explain ingredients" button calls `GET /ai/ingredients/explain` and renders the response in a sheet.
3. Allergen check highlights any of the user's profile allergens against the product's ingredients.
4. "View healthy alternatives" lists 3–5 alternatives with their own health chips.
5. Each subsection has independent loading and error states.

**Expected outcome**: failure of one provider (e.g. AI explainer 5xx) does not break the rest of the screen.

**Backend endpoints hit**: `GET /products/lookup/{ean}`, `GET /allergen/check/{productId}`, `GET /ai/ingredients/explain`, `GET /healthy-alternatives/{productId}`.

**MCP tool**

- `playwright`: `browser_click` on "Explain ingredients" → `browser_wait_for({ text: 'Sugar' })` (or any expected ingredient term).

---

### Task 11 — Expiry tracking flow

**What to test**

1. Tabs (Near-expiry / Expired / Safe) paginate independently with cursor pagination.
2. Pull-to-refresh re-fetches.
3. Manual entry rejects `mfgDate > expiryDate` client-side before posting.
4. "Use camera" path runs ML Kit OCR locally; on low confidence, falls back to `POST /image-fallback/extract-dates`.
5. Calendar view renders red/amber/green dots per day from `GET /expiry-calendar?month=YYYY-MM`.

**Expected outcome**: `expiry_records.status` is computed server-side, not client-side.

**Backend endpoints hit**: `GET /expiry/near-expiry`, `GET /expiry?status=expired|safe`, `POST /expiry`, `POST /image-fallback/extract-dates`, `GET /expiry-calendar`.

**MCP tool**

- `mobile-mcp`: `mobile_click_on_screen_at_coordinates` on the FAB → fill the form via `mobile_type_keys` → submit → `mobile_take_screenshot` to confirm new row in list.

---

### Task 12 — Tasks flow

**What to test**

1. Filter tabs (My Tasks / All / Completed) and priority chips.
2. Manager-only "Create" FAB hidden for staff role.
3. Status transitions: `open → in_progress → completed` and `open → cancelled` work; illegal transitions disabled.
4. Tasks with `requires_evidence = true` block "Complete" until a photo is uploaded via `POST /media/presign` then PUT to S3.

**Expected outcome**: audit log row written for every status change.

**Backend endpoints hit**: `GET /tasks`, `POST /tasks`, `PATCH /tasks/{id}`, `POST /media/presign`.

**MCP tool**

- `playwright`: `browser_click` on Complete with no evidence → expect inline error "Evidence required".

---

### Task 13 — Inventory + low-stock

**What to test**

1. Inventory list shows current stock per product with batch breakdown.
2. Low-stock badge renders when on-hand ≤ reorder threshold.
3. Stock In / Stock Out tabs each post correctly.
4. Stock Out that would result in negative balance is rejected client-side.
5. Low-stock alerts list refreshes after a Stock In that crosses the threshold.

**Expected outcome**: server returns updated `stock_movements` row; alert resolved if applicable.

**Backend endpoints hit**: `GET /inventory`, `POST /inventory/stock-in`, `POST /inventory/stock-out`, `GET /inventory/low-stock`.

**MCP tool**

- `mobile-mcp`: `mobile_swipe_on_screen({ direction: 'down' })` on the list to refresh.

---

### Task 14 — GRN flow

**What to test**

1. List filters by Draft / Pending Review / Posted.
2. Header creation captures supplier, invoice number/date, expected delivery.
3. Adding items rejects `mfg > exp`, shows running totals.
4. "Move to Pending Review" available only on Draft.
5. "Post" available only with `post_grn` permission and only on Pending Review.
6. After post, the response summary includes `resolvedLowStockAlertCount`.

**Expected outcome**: stock posted; low-stock alerts resolved server-side.

**Backend endpoints hit**: `GET /grn`, `POST /grn`, `POST /grn/{id}/items`, `POST /grn/{id}/submit`, `POST /grn/{id}/post`.

**MCP tool**

- `playwright`: `browser_evaluate` on the post-success snackbar to assert it mentions the resolved-alert count.

---

### Task 15 — Subscription + entitlement gating

**What to test**

1. Plan compare table shows Free Trial vs ₹49 Basic vs ₹99 Standard vs ₹199 Premium with a current-plan badge.
2. Trial-days-remaining counter is correct.
3. Locked features (Advanced Reports, Inventory, GRN, Allergen, Recall, Weekly Digest on Free) display a `LockedFeature` overlay.
4. Tapping the overlay routes to `/subscription` with the originating feature highlighted.

**Expected outcome**: locked overlays disappear after upgrading.

**Backend endpoints hit**: `GET /subscription/status`, `POST /subscription/upgrade`.

**MCP tool**

- `playwright`: visit `/inventory` while on Free plan → snapshot to verify the overlay text reads "Upgrade to Standard".

---

### Task 16 — Offline-first queue + sync (BE-44)

**What to test**

1. Stop the backend (`Ctrl+C` on the `pnpm server:dev` terminal).
2. Scan a product, add an expiry record, and complete a task in the app.
3. The sync banner shows "Offline — your work is being saved".
4. Restart the backend.
5. Within 60 seconds the queue drains, banner disappears, and rows show up server-side.
6. After 6 retry exhaustion (simulate by pointing `API_BASE_URL` at an unreachable host), the user sees a notification per R38.3.

**Expected outcome**: no data loss; eventual consistency holds.

**Backend endpoints hit**: any write endpoint; replay is transparent to the API.

**MCP tool**

- `playwright`: kill backend, perform writes, restart backend, `browser_wait_for({ textGone: 'Offline' })`.

---

### Task 17 — Allergen profile + recall alerts (BE-37, BE-39)

**What to test**

1. Allergen profile screen shows multi-select chips for the standard list (peanut, tree nut, dairy, eggs, soy, wheat, fish, shellfish, sesame, gluten, etc.).
2. `PUT /allergen/profile/{userId}` persists the selection.
3. Recall alerts list shows severity badges (low / medium / high / critical).
4. Tapping a recall row deep-links to product detail with the recall banner active.

**Expected outcome**: scanning a product whose ingredients contain a profiled allergen surfaces a red banner on the result card.

**Backend endpoints hit**: `GET /allergen/profile/{userId}`, `PUT /allergen/profile/{userId}`, `GET /allergen/check/{productId}`, `GET /recall-alerts`.

**MCP tool**

- `mobile-mcp`: list elements, tap each chip, save, then `mobile_terminate_app` + `mobile_launch_app` to confirm persistence.

---

### Task 18 — Shopping list + healthy alternatives (BE-55, BE-41)

**What to test**

1. Add an item via `POST /shopping-list/items`.
2. Check off via `PATCH /shopping-list/items/{id}`.
3. Remove via `DELETE /shopping-list/items/{id}`.
4. From product detail, "Add healthy alternative to list" pushes the alt directly.

**Expected outcome**: list survives app relaunch.

**Backend endpoints hit**: `GET /shopping-list`, `POST /shopping-list/items`, `PATCH /shopping-list/items/{id}`, `DELETE /shopping-list/items/{id}`, `GET /healthy-alternatives/{productId}`.

**MCP tool**

- `playwright`: `browser_fill_form` to add an item, `browser_click` to check it off, `browser_snapshot` to confirm visual state.

---

### Task 19 — Referrals + multi-language switcher (BE-42, BE-43)

**What to test**

1. Referral code is shown and copyable.
2. Share button uses the OS share sheet (`share_plus`).
3. Invitee count and rewards earned reflect `GET /referrals/me`.
4. Language picker offers en, hi, ta, te, bn, mr.
5. Selecting a language calls `PUT /user/language` and rebuilds the app's `Locale`; UI strings re-render in the chosen language for at least the foundational ~50 strings.

**Expected outcome**: relaunch keeps the chosen language.

**Backend endpoints hit**: `GET /referrals/me`, `POST /referrals/redeem`, `PUT /user/language`.

**MCP tool**

- `mobile-mcp`: change language to Hindi, then `mobile_take_screenshot` to confirm Devanagari rendering on the splash and OTP screens.

---

### Task 20 — Error boundary, snackbars, connectivity banner

**What to test**

1. Forcing an exception (e.g. point `API_BASE_URL` to a route that returns malformed JSON) renders the friendly fallback screen with a "Report" CTA.
2. Success / info / error snackbars render via the global host with the correct icon and color per variant.
3. Disabling Wi-Fi / network shows the sticky connectivity banner; re-enabling hides it.

**Expected outcome**: no white-screen-of-death, no raw stack traces shown to users.

**Backend endpoints hit**: any (used to provoke errors).

**MCP tool**

- `playwright`: `browser_evaluate(() => navigator.onLine === false)` after toggling offline mode in DevTools.

---

### Task 21 — Splash icon, app icon, launch theme

**What to test**

1. Android: launcher icon visible in the app drawer.
2. iOS: app icon visible on home screen.
3. Web: favicon renders in browser tab.
4. Native splash screen (before Flutter engine loads) matches the app's splash visual.

**Expected outcome**: no Flutter default debug `?` icon anywhere.

**Backend endpoints hit**: none.

**MCP tool**

- `mobile-mcp`: `mobile_press_button({ button: 'HOME' })` then `mobile_take_screenshot` to capture the launcher.
- `playwright`: `browser_evaluate(() => document.querySelector('link[rel~="icon"]').href)`.

---

### Task 22 — Integration smoke tests

**What to test**

1. `flutter test integration_test/auth_flow_test.dart` passes.
2. `flutter test integration_test/scan_flow_test.dart` passes.
3. `flutter test integration_test/expiry_flow_test.dart` passes.

**Expected outcome**: all three green; no live backend required (tests use `dio_mock_adapter`).

**Run command (from `apps/mobile/`)**:

```cmd
C:\src\flutter\bin\flutter.bat test integration_test
```

**MCP tool**: not applicable — these are Flutter test runner tests, not interactive flows.

---

### Task 23 — Final verification pass

**What to test**

1. `flutter analyze --fatal-infos` returns 0 issues.
2. `flutter test` passes.
3. `flutter test integration_test/` passes.
4. `flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1` produces `apps/mobile/build/web/main.dart.js`.
5. App boots in Chrome and OTP login round-trips against the running backend.

**Run commands (from `apps/mobile/`)**:

```cmd
C:\src\flutter\bin\flutter.bat analyze --fatal-infos
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat test integration_test
C:\src\flutter\bin\flutter.bat build web --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

**MCP tool**: `playwright` for the end-to-end OTP round-trip.

---

## C. MCP tool usage examples

### mobile-mcp (native devices)

The `mobile-mcp` server, configured at `.kiro/settings/mcp.json`, exposes these tools (auto-approved subset shown in **bold**):

- **`mobile_list_devices`** / **`mobile_list_available_devices`** — discover simulators, emulators, real devices.
- **`mobile_use_default_device`** / **`mobile_use_device`** — pick which device subsequent calls target.
- **`mobile_get_screen_size`** — used to translate logical taps into pixel coordinates.
- **`mobile_take_screenshot`** — visual snapshot.
- **`mobile_list_apps`** — find the app's package name.
- `mobile_launch_app` / `mobile_terminate_app` — start/stop your build.
- **`mobile_list_elements_on_screen`** — accessibility tree with coordinates and labels (preferred over screenshots for clicking).
- `mobile_click_on_screen_at_coordinates` / `mobile_long_press_on_screen_at_coordinates` / `mobile_double_tap_on_screen` — pointer events.
- `mobile_swipe_on_screen` — gestures.
- `mobile_type_keys` — text entry into the focused field.
- `mobile_press_button` — hardware buttons (HOME, BACK, ENTER, VOLUME_UP/DOWN).
- `mobile_open_url` — launch a deeplink.
- **`mobile_get_orientation`** / `mobile_set_orientation` — portrait/landscape.
- `mobile_save_screenshot` — write a PNG to disk.
- `mobile_start_screen_recording` / `mobile_stop_screen_recording` — capture an MP4.

#### Recipe — verify the OTP screen on a real Android device

```text
mobile_list_available_devices
  → use the returned device id as <device-id>

mobile_use_device({ device: <device-id> })
mobile_list_apps({ device: <device-id> })
  → confirm com.radha.mobile is installed

mobile_launch_app({ device: <device-id>, packageName: 'com.radha.mobile' })
mobile_take_screenshot({ device: <device-id> })
  → save baseline image

mobile_list_elements_on_screen({ device: <device-id> })
  → locate the mobile-number input; capture its (x, y) center

mobile_click_on_screen_at_coordinates({ device: <device-id>, x, y })
mobile_type_keys({ device: <device-id>, text: '9999912345', submit: false })

mobile_list_elements_on_screen({ device: <device-id> })
  → locate the "Send OTP" button

mobile_click_on_screen_at_coordinates({ device: <device-id>, x, y })
mobile_take_screenshot({ device: <device-id> })
  → confirm OTP verification screen renders

mobile_type_keys({ device: <device-id>, text: '123456', submit: true })
mobile_take_screenshot({ device: <device-id> })
  → confirm /home loaded
```

### playwright (Flutter Web in Chromium)

The `playwright` server exposes (auto-approved subset shown in **bold**):

- **`browser_navigate`** — go to a URL.
- **`browser_snapshot`** — accessibility-tree snapshot (preferred over screenshot for assertions).
- **`browser_take_screenshot`** — PNG/JPEG capture.
- **`browser_console_messages`** — read browser console logs.
- **`browser_evaluate`** — run JavaScript in the page.
- **`browser_resize`** — set viewport size (e.g. 414×896 to mimic an iPhone 11).
- `browser_click`, `browser_hover`, `browser_type`, `browser_fill_form`, `browser_press_key` — interactions.
- `browser_network_requests` / `browser_network_request` — inspect HTTP traffic.
- `browser_wait_for` — wait for text/time.
- `browser_close`, `browser_tabs` — tab management.

#### Recipe — verify the OTP screen on Chrome

```text
browser_resize({ width: 414, height: 896 })
browser_navigate({ url: 'http://localhost:<flutter-port>' })
browser_wait_for({ text: 'Send OTP' })
browser_snapshot
  → assert structure includes a textbox labelled "Mobile number" and a button "Send OTP"

browser_fill_form({ fields: [{ target: '<ref-from-snapshot>', name: 'Mobile number', type: 'textbox', value: '9999912345' }] })
browser_click({ target: '<send-otp-button-ref>', element: 'Send OTP button' })
browser_wait_for({ text: 'Enter OTP' })
browser_take_screenshot({ filename: 'otp-verify.png' })
```

---

## D. Anti-slop visual verification

Before ticking a screen as "done", run this 30-second visual checklist. These mirror the workspace skills `high-end-visual-design`, `design-taste-frontend`, and UI/UX Pro Max.

**Universal rules**

- [ ] No Inter font anywhere. Display = Plus Jakarta Sans (or comparable), mono = JetBrains Mono.
- [ ] Single accent color (emerald). No purple/blue gradients.
- [ ] No nested cards-inside-cards-inside-cards.
- [ ] Touch targets ≥ 44pt.
- [ ] Generous spacing (24–32) between major sections.
- [ ] Skeleton loaders, not spinners, while data is in flight.
- [ ] Empty states are illustrated and have a CTA, never bare "No data".

**Per-screen checks**

- **Splash**: dark background, centred wordmark, single emerald progress bar.
- **Onboarding**: wide editorial typography, three pages max, no fake testimonials.
- **OTP request**: phone field formatted as `+91 XXXXX XXXXX`, single primary CTA.
- **OTP verify**: 6-digit Pinput cells with 12–16 corner radius, 60s resend countdown live in the button.
- **Home**: bento grid with one tall Scan card on the left, three smaller cards on the right; "Today" summary as a single calm row of three counts.
- **Scanner**: full-bleed camera, centred frame with corner indicators, flashlight pill bottom-right, scan-history sheet at bottom-left.
- **Product detail**: hero image, health chip, ingredients list, a single AI-explainer button (not five overlapping CTAs).
- **Expiry list**: tabbed; rows have a left-edge color bar (red/amber/green) instead of a full-card tint.
- **Tasks**: priority chip on the left of the title, due date right-aligned, FAB bottom-right.
- **Inventory**: search bar pinned, batch breakdown collapsed by default.
- **GRN**: stepper visible at top, line-item totals live-summed at bottom of the items screen.
- **Subscription**: plan compare table with the current plan visually emphasised (left edge bar, not a full-card highlight).
- **Settings → Language**: each option in its native script (हिंदी, தமிழ், తెలుగు, বাংলা, मराठी, English).
- **Connectivity banner**: amber, slim (≤ 32 logical px tall), bottom-anchored, non-blocking.

---

## E. Known limitations / not covered

- **Camera-based barcode scanning in headless Chrome**: `mobile_scanner` requires a real camera. On Chrome it falls back to barcode-image upload. For the real flow use `mobile-mcp` against an Android emulator or a real device with a printed barcode.
- **Push notifications**: FCM token registration and notification render are not part of the v1 mobile checklist. Backend BE-43-style triggers exist but in-app delivery surfacing is deferred.
- **OCR fallback (BE-45)**: `POST /image-fallback/extract-dates` requires a network call to the running backend; offline-only validation cannot exercise this path.
- **Real OTP delivery**: in `dev` provider mode the OTP is `123456` and the SMS is mocked. Real MSG91 delivery requires `OTP_PROVIDER=msg91` and live credentials.
- **iOS simulator on Windows**: not possible. Use Android emulator + `mobile-mcp` or web + `playwright`.
- **Subscription upgrade / payment**: the in-app upgrade CTA hits `POST /subscription/upgrade` but the actual payment gateway (Razorpay) integration is server-only in v1.
- **Multi-store switching**: covered by `/select-store` but switching stores while inside a flow (e.g. mid-GRN) is intentionally blocked.
- **Localisation depth**: only ~50 foundational strings are translated for hi/ta/te/bn/mr. Deeper module-specific strings remain in English.
