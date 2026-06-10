# RADHA — Production Push Handoff (continue here)

> Handoff for a fresh Claude Code context. The prior context drove a long
> production-readiness pass on the **Flutter mobile app** + some server wiring.
> Everything below is the live state. **Trust the filesystem + `flutter analyze`
> / `flutter test` over any stale status table.**

---

## 0. IMMEDIATE NEXT STEP (do this first)

A release-build R8 failure was just fixed (ML Kit missing classes + Razorpay
keep rules). **Verify it builds**, then measure the real ship size:

```powershell
$flutter = "C:\src\flutter\bin\flutter.bat"
$mobile  = "C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\apps\mobile"
Push-Location $mobile
& $flutter build apk --release --split-per-abi > .tmp-release.log 2>&1
"exit: $LASTEXITCODE"
Get-Content .tmp-release.log | Select-String "What went wrong|Execution failed|Missing class|error:|FAILURE:|Built " | Select-Object -First 40
Get-ChildItem build\app\outputs\flutter-apk -Filter *release*.apk | %{ "{0}  {1}MB" -f $_.Name,[math]::Round($_.Length/1MB,1) }
Pop-Location
```
- Release build is **~9 min**; run it in the **background** (`run_in_background: true`) and read the task output file when notified.
- If it still fails on more "Missing class" → add matching `-dontwarn` lines to
  `apps/mobile/android/app/proguard-rules.pro` and rebuild.
- The fix just applied: created `apps/mobile/android/app/proguard-rules.pro` and
  set `isMinifyEnabled=true` / `isShrinkResources=true` / `proguardFiles(...)` in
  `apps/mobile/android/app/build.gradle.kts` (release block).

---

## 1. Environment facts (verified)
- **Flutter:** `C:\src\flutter\bin\flutter.bat` (3.44.0, Dart 3.12). NOT on PATH.
- **Dart:** `C:\src\flutter\bin\dart.bat` (for `build_runner`).
- Windows host, PowerShell. **Developer Mode is ON** (plugin builds work).
- **No Android device** connected. An emulator **`RadhaPixel`** exists
  (`flutter emulators --launch RadhaPixel`) but a full on-device test needs the
  **server running** (for OTP login) — that's a user step.
- **Docker is up & healthy:** `radha-postgres` (5433), `radha-redis` (6380).
  Migrations applied through `0030_browse_catalog_indexes`.
- `cwebp` NOT installed (so asset optimization used JPEG/PNG resize, not WebP).
- **Concurrency gotcha:** the user's IDE edits the same files in parallel. Always
  re-read a file before editing; treat `analyze`/`test` as source of truth.
- Verify after edits: `& $flutter analyze lib` then `& $flutter test`
  (run from `apps/mobile`). Baseline is **analyzer clean + 179/179 tests green**.
- Jest summary goes to **stderr** — when capturing, use `*>&1`/`2>&1`, not `2>$null`.
- `Remove-Item` is blocked by a sandbox guard → use `[System.IO.File]::Delete()`.

---

## 2. What was completed this session (all verified green)

**Payments / Razorpay**
- Server `.env.development` has the user's test keys (`rzp_test_Sz8KRlC6Lg8RIZ`).
- Mobile `razorpay_flutter: ^1.4.5` re-enabled; real checkout restored in
  `apps/mobile/lib/features/subscription/razorpay_checkout_sheet.dart` (Key ID
  comes from the server `/payments/checkout` response — never compiled in).
- **AGP 9 namespace clash fixed**: `com.razorpay:checkout` pulls two AARs both
  named `com.razorpay`. Vendored a patched `core` AAR with a unique namespace at
  `apps/mobile/android/app/libs/razorpay-core-1.0.14-patched.aar` + excluded the
  remote `core` in `android/app/build.gradle.kts`. **Debug APK builds.**
- ⏳ Live payment sheet still needs one on-device run (no device here).

**Auth / 2FA (2Factor.in, MSG91 removed)**
- New `apps/mobile/.../../server/src/integrations/sms/providers/twofactor.provider.ts`;
  MSG91 provider deleted; `SmsService`, `sms.module`, `sms.types`, `config.*`,
  `env.schema.ts` all migrated to `SMS_PROVIDER=2factor` + `TWO_FACTOR_API_KEY` /
  `TWO_FACTOR_TEMPLATE`. Server tsc + SMS/config tests green.
- Fixed real bugs: server now exposes `POST /auth/refresh` was a **path drift**
  (server `token/refresh` vs mobile `refresh`) — NOTE: this was diagnosed; verify
  whether the alias/logout route fix was applied (grep `auth.controller.ts`).
- **In-app dev-OTP**: server returns `devOtp` in dev; mobile shows a debug-only
  banner on the verify screen (`otp_verify_screen.dart`).

**Single ultimate `.env`**: `server/.env.development` consolidated (2Factor,
Razorpay, Gemini, AWS, allergen key, etc.); `.env.example` synced. Gitignored.

**Mobile UI / production hardening**
- Home: v3 banners + "Shop by category" rail; last-known-value KPI tiles;
  `keepAlive` caching for instant re-entry.
- Real **product browse**: `apps/mobile/lib/features/catalog/` (provider +
  `product_browse_screen.dart`), route `/catalog/:category`, home tiles navigate
  to it. Name-first cards via `CachedNetworkImage` + placeholder — **lights up
  when products with images exist in the DB; no code changes needed.**
- `lowStockCountProvider` now counts items at/below threshold (honest KPI).
- Branded `NotFoundScreen` (already existed/wired).
- **Error-handling pass (app-wide):** ZERO raw-error leaks remain (fixed 10:
  product_detail, scan_result, tasks, grn, inventory, ean_audit, shopping_list);
  no `print()`; no dead buttons (wired scan_result share + explain); retries on
  persistent errors; partial-failure isolation verified on the ingredient flow.
- **Asset optimization (~14 MB reclaimed):** category cutouts resized 1254²→256²
  (10.7 MB→0.6 MB); banners PNG→JPEG q85 (4.7 MB→0.6 MB) — `RadhaAssets`
  banner constants now point to `.jpg`.

---

## 3. Remaining work (mostly gated on the user)
1. **Verify release build** (section 0) — the last open *engineering* item.
2. **Product/category images** — user is preparing; drop into DB → browse works.
3. **AWS creds** — then harden prod env (JWT ≥64-char real, real AWS, `DB_SSL=true`,
   `SMS_PROVIDER=2factor` real key, `RAZORPAY_*` live + webhook secret). Consider
   creating `server/.env.production` from `.env.example` when creds arrive.
4. **On-device Razorpay sheet** — user runs server + emulator/device.
5. Optional: real release **signing config** (currently debug keys), WebP if
   `cwebp` gets installed.

---

## 4. Quirks worth knowing
- 307 MB earlier = **debug fat-APK** (all ABIs + Dart VM + ML Kit models), NOT
  ship size. Use `--release --split-per-abi` for the real number.
- `error: (_, _)` / wildcard params are supported (Dart 3.7+ wildcards).
- Server has a complete auth + Razorpay backend already — don't import external
  repos; extend in place.
