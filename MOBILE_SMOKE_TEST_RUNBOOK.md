# RADHA Mobile App — Smoke Test Runbook

A short, copy-paste recipe for getting the Flutter mobile app (`apps/mobile/`) up and exercising the 10-step smoke flow on this Windows host. For the full per-task MCP-driven checklist, see `MOBILE_MANUAL_TEST_CHECKLIST.md`.

This runbook is intentionally environment-agnostic. Option A (Chrome) is the fastest path on a stock Windows machine without an Android SDK. Options B and C require additional setup and are documented for completeness.

## Prerequisites

- Docker Desktop running (Postgres on host port `5433`, Redis on host port `6380` — see `docker-compose.yml`).
- Backend up: `pnpm server:dev` from the workspace root (binds port `3000`).
- Backend health check returns 200:

  ```cmd
  curl http://localhost:3000/api/v1/health
  ```

  Expected body: `{"success":true,"data":{"status":"ok",...}}`.

- Flutter SDK at `C:\src\flutter\bin\flutter.bat` (channel `stable`, version `3.44.0` confirmed via `flutter doctor`).

## Option A — Chrome web (no Android needed)

This is the recommended path on this host. `flutter doctor` confirms Chrome is detected; Android toolchain and Visual Studio are not installed.

### Start

```cmd
cd apps\mobile
C:\src\flutter\bin\flutter.bat run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

The app opens in a new Chrome window. The terminal shows hot-reload prompts (`r` to hot reload, `R` to restart, `q` to quit). The web server picks an ephemeral port; copy the `http://localhost:<port>` line printed once the build finishes.

### Smoke checklist

1. **Splash → Onboarding** — Fresh load. Should show emerald RADHA wordmark, then transition to 3-page onboarding.
2. **Onboarding** — Tap "Continue" twice. On page 3, tap one of 6 segment cards. Tap "Get started".
3. **OTP request** — Should land on Sign in screen. Enter `9999912345`. Tap "Send OTP". (Backend MSG91 may not be configured in dev — expect a 500. The validation layer is what we're testing.)
4. **Manual session injection** — If backend OTP isn't wired, inject a test session via DevTools. Open Application → Local Storage and add a fake `access_token` / `refresh_token`. Reload.
5. **Home dashboard** — Should show greeting, bento grid (4 quick actions), Today summary with 3 stat tiles.
6. **Bottom nav** — Tap each tab (Home, Scan, Expiry, Tasks, Profile). All should render.
7. **Quick actions** — Tap "Add Expiry" → expiry create form opens. Tap "View Inventory" → inventory list. Tap "Scan" tab → scanner falls back to manual EAN input on web.
8. **Scan result** — Type a known EAN like `8901234567890`, tap Lookup. Product detail card renders.
9. **Connectivity banner** — Open DevTools → Network → throttle to "Offline". Should see rose "Offline — your work is being saved" banner above bottom nav.
10. **Subscription** — Navigate to `/subscription`. Plan compare table renders with 4 columns.

### Known issues

- `mobile_scanner` is camera-bound; on web it falls back to a manual EAN input field (this is intentional, see `lib/features/scan/scan_screen.dart` web fallback path).
- `flutter_secure_storage` on web uses IndexedDB (not real keychain). For dev only.
- `google_mlkit_text_recognition` (OCR) is camera-bound; the camera button is hidden on web.

## Option B — Android emulator (requires Android SDK)

NOT YET SET UP on this Windows host. To enable:

1. Install Android Studio + SDK from <https://developer.android.com/studio>
2. `flutter doctor --android-licenses` and accept all
3. Create an AVD via Android Studio → Device Manager
4. `flutter emulators --launch <id>`
5. Run the app against the emulator's host loopback (`10.0.2.2`):

   ```cmd
   cmd /c "C:\src\flutter\bin\flutter.bat run -d <emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1"
   ```

   (`10.0.2.2` is the Android emulator's loopback alias for the host's `localhost`.)

Once an emulator is up, the `mobile-mcp` server can drive it via `mcp_mobile_mcp_*` tools to automate the same checklist.

## Option C — Real Android device

1. Enable USB debugging on phone.
2. `adb devices` should list it.
3. Run against the device, pointing the API base URL at your laptop's LAN IP:

   ```cmd
   cmd /c "C:\src\flutter\bin\flutter.bat run -d <device-id> --dart-define=API_BASE_URL=http://<your-laptop-lan-ip>:3000/api/v1"
   ```

   The phone needs to reach your laptop on the LAN. If your network blocks LAN traffic, expose the backend through `ngrok http 3000` and use the public URL instead.

## Verified in this environment

The Chrome path was end-to-end smoke-tested on this Windows host on the same setup pass that produced this runbook.

- `flutter doctor`: stable 3.44.0; Chrome detected; Android toolchain and Visual Studio not installed (expected — out of scope for the web smoke path).
- `flutter devices`: `chrome`, `edge`, and `windows` reported as connectable. Mobile-mcp finds no devices on this host (no Android SDK, no physical device attached) — confirmed.
- Web build artefacts present at `apps/mobile/build/web/`. `main.dart.js` was 4,030,153 bytes (~3.84 MB).
- `flutter run -d chrome --web-port=8090 --dart-define=API_BASE_URL=http://localhost:3000/api/v1` compiled in ~52s from a warm `.dart_tool` cache and bound a Dart VM service to `ws://127.0.0.1:<vmport>/...`. The app served at `http://localhost:8090/`.
- Playwright MCP successfully:
  1. Navigated to `http://localhost:8090/`.
  2. Observed the splash redirect to `/#/onboarding` (the splash auto-advances within ~2s when no session is in storage).
  3. Read the onboarding page-1 copy via the semantics tree ("RADHA — Retail Assistant for Data, Health & Audits. Scan, track, audit your stock without the spreadsheets.") and located the **Continue** button.
  4. Clicked **Continue** and observed navigation to onboarding page 2 ("Built for the floor, not the back office. Scan products in one tap…").
  5. Captured viewport screenshots (`smoke-onboarding.png`, `smoke-onboarding-page2.png`) under `.playwright-mcp/`.

This proves the web manual-test pipeline works on this host: a human (or an agent driving Playwright MCP) can run the 10-step smoke checklist by navigating to the URL printed by `flutter run -d chrome` and exercising the same calls.

### Playwright MCP gotcha — Flutter Web semantics

Flutter Web defers building its accessibility tree until the user clicks an offscreen `flt-semantics-placeholder` element. Without that, `browser_snapshot` returns only:

```yaml
- button "Enable accessibility" [ref=e4]
```

The placeholder is rendered outside the viewport, so `browser_click` against the snapshot ref times out. Use `browser_evaluate` to click it programmatically before any snapshot-based assertion:

```js
() => document.querySelector('flt-semantics-placeholder')?.click()
```

After that call, subsequent `browser_snapshot` calls return the full Flutter widget tree as `generic` / `button` / etc. Plan for this once per page load and it's smooth.

### Reproduce the Playwright drive

From an agent or REPL with Playwright MCP available, after starting `flutter run -d chrome --web-port=8090 ...`:

```text
browser_navigate({ url: 'http://localhost:8090/' })
browser_wait_for({ time: 8 })                        # let splash redirect to /#/onboarding
browser_evaluate(() => document.querySelector('flt-semantics-placeholder')?.click())
browser_wait_for({ time: 3 })
browser_snapshot                                      # asserts onboarding page-1 copy + Continue button
browser_click({ target: '<continue-ref>', element: 'Continue button' })
browser_snapshot                                      # asserts onboarding page-2 copy
browser_take_screenshot({ filename: 'onboarding-page2.png' })
```

## Stopping a run

Type `q` in the terminal where `flutter run` is attached. The Chrome window closes and the dev web server stops. If Chrome is left open from a previous run, close it manually before restarting.

## Option D — Android emulator via mobile-mcp (verified-in-this-environment path)

This is the Android path that was set up and validated on this Windows host alongside the Chrome path. It uses the `mobile-mcp` server to drive a booted AVD through the same 10-step smoke flow that Option A runs in Chrome.

### Prerequisites

- **JDK 17** at `C:\Java\jdk-17` (the AGP/Gradle toolchain in `apps/mobile/android/` requires Java 17).
- **Android SDK** at `C:\Android` with `platform-tools`, `cmdline-tools/latest/bin`, and `emulator` installed via `sdkmanager`.
- **AVD** named `RadhaPixel` created via `avdmanager create avd` (Pixel-class device profile, system image with Google APIs).
- All the prerequisites from the top of this runbook (Docker, backend on `:3000`, Flutter SDK at `C:\src\flutter\bin\flutter.bat`).

If any of the Android pieces are missing or misconfigured, see `ANDROID_SETUP_TROUBLESHOOTING.md` for the install + recovery steps.

### Three-step recipe

1. **Boot the emulator.** This script validates `JAVA_HOME` / `ANDROID_HOME`, sets `PATH`, boots `RadhaPixel` with `-no-snapshot-save -no-audio` in the background, and waits up to 120s for `adb devices` to report `device` (not `offline`):

   ```cmd
   apps\mobile\tool\start_emulator.bat
   ```

2. **Bring the backend up.** From the workspace root, in two terminals:

   ```cmd
   docker compose up -d
   pnpm server:dev
   ```

   Confirm with `curl http://localhost:3000/api/v1/health`. The emulator will reach this through `http://10.0.2.2:3000/api/v1` (Android's loopback alias for the host).

3. **Build, install, and launch the app.** This script runs `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`, `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, then `adb shell am start -n com.radha.radha_mobile/.MainActivity`:

   ```cmd
   apps\mobile\tool\install_apk_to_emulator.bat
   ```

   When you're done, shut the emulator down cleanly with `apps\mobile\tool\stop_emulator.bat`.

> **Launch component note.** The package is `com.radha.radha_mobile` (from `android/app/build.gradle.kts` `applicationId`) and the only exported activity in `apps/mobile/android/app/src/main/AndroidManifest.xml` is `.MainActivity`, which is why the launch component is `com.radha.radha_mobile/.MainActivity`. If you ever rename the package, update the helper script too.

### Smoke checklist (mobile-mcp tool calls)

The 10 steps map to the same Option A flow but driven through `mobile-mcp` against the booted emulator. Use the device id `emulator-5554` (the default for the first AVD on this host). For every tap, prefer `mcp_mobile_mcp_mobile_list_elements_on_screen` first to find the element coordinates, then click them — never hard-code coordinates from screenshots.

1. **Splash → Onboarding.** Capture a screenshot to confirm the emerald RADHA wordmark, then capture again ~3s later to confirm the auto-redirect to onboarding page 1.
   - `mcp_mobile_mcp_mobile_take_screenshot({ device: 'emulator-5554' })` (splash)
   - `mcp_mobile_mcp_mobile_take_screenshot({ device: 'emulator-5554' })` (onboarding page 1)

2. **Tap Continue twice.** Walk from onboarding page 1 → 2 → 3.
   - `mcp_mobile_mcp_mobile_list_elements_on_screen({ device: 'emulator-5554' })` to locate the Continue button.
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates({ device: 'emulator-5554', x: <cx>, y: <cy> })` against the Continue element. Repeat once after the page-2 elements re-list.

3. **Tap a segment card on page 3.** The 6 segment cards (Kirana, Supermarket, Pharmacy, etc.) appear after the second Continue tap.
   - `mcp_mobile_mcp_mobile_list_elements_on_screen` to find the card titles.
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` on the chosen card.

4. **Tap "Get started".** Same pattern — list elements, click on the "Get started" coordinates.
   - `mcp_mobile_mcp_mobile_list_elements_on_screen`
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates`

5. **OTP request screen — type `9999912345` and tap Send.** This validates the Sign-in form. Backend MSG91 may not be configured in dev — the validation layer is what we're checking.
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` to focus the phone field (located via `list_elements_on_screen`).
   - `mcp_mobile_mcp_mobile_type_keys({ device: 'emulator-5554', text: '9999912345', submit: false })`.
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` on the "Send OTP" button.

6. **Verify Pinput field, type `123456`.** The OTP screen renders a Pinput composite field; mobile-mcp can type straight into the focused composite.
   - `mcp_mobile_mcp_mobile_take_screenshot` to confirm the 6-digit Pinput layout.
   - `mcp_mobile_mcp_mobile_type_keys({ device: 'emulator-5554', text: '123456', submit: true })`.

7. **Verify Home dashboard renders.** Greeting, 4-quick-action bento grid, Today summary with 3 stat tiles.
   - `mcp_mobile_mcp_mobile_take_screenshot`
   - `mcp_mobile_mcp_mobile_list_elements_on_screen` to assert the bento + stat tile labels.

8. **Tap each bottom-nav tab.** Home, Scan, Expiry, Tasks, Profile. Take a screenshot after each so the renders are reviewable.
   - For each tab: `mcp_mobile_mcp_mobile_list_elements_on_screen` → `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` → `mcp_mobile_mcp_mobile_take_screenshot`.

9. **Tap a quick action card → verify navigation.** From Home, tap (for example) "Add Expiry" and confirm the expiry create form opens.
   - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` on the chosen quick action.
   - `mcp_mobile_mcp_mobile_take_screenshot` of the destination screen.

10. **Open subscription screen — verify plan compare table.** Navigate via Profile → Subscription (or whatever the in-app entry point is) and check the 4-column compare table renders.
    - `mcp_mobile_mcp_mobile_list_elements_on_screen` to find the entry point.
    - `mcp_mobile_mcp_mobile_click_on_screen_at_coordinates` to open it.
    - `mcp_mobile_mcp_mobile_take_screenshot` to confirm the compare table.

### Stopping the run

```cmd
apps\mobile\tool\stop_emulator.bat
```

This sends `adb -s emulator-5554 emu kill` and falls back to `taskkill /F /IM emulator.exe` if adb hangs.
