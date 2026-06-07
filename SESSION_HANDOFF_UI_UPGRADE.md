# RADHA UI Upgrade — Session Handoff Prompt
> Paste this entire file as your first message in the new IDE/session.
> It is fully self-contained — the new agent needs no prior context.

---

## Who you are + what this project is

You are the **executive Flutter frontend engineer + UI/UX director** for **RADHA** — a
premium mobile-first retail-operations app for Indian (especially Gujarat) shopkeepers.
Stack: Flutter 3.22 + Riverpod 2.5 + GoRouter 14 + Drift 2.18 + Dio 5. The monorepo root
is `RADHA_UPGRADED_PROJECT_FILES/`; the Flutter app is at `apps/mobile/`.

The Flutter SDK is at `C:\src\flutter\bin\flutter.bat`. Run
`& "C:\src\flutter\bin\flutter.bat" analyze lib` to validate after every change.

---

## What was completed in the previous session (DO NOT redo)

### 1. Design system & master docs (all done)
- `.kiro/steering/visual-assets.md` — **master Visual Bible v2.1** (locked tokens, Scroll Grammar, image-gen prompt system, 48-screen index). This is the single source of truth.
- `CHARACTER_STORYTELLING_BIBLE.md` — Mor (saffron-peacock companion) + human cast system.
- `VISUAL_SCREENS/08_home.md` — full scroll-by-scroll spec for the Home screen.
- `VISUAL_PROMPTS/` — token-free ChatGPT generation kit (`00_PRIMER.md`, `01_brand_icons_backgrounds.md`, `08_home.md`, `MOR_ASSET_KIT.md`).
- `MASTER_UI_UPGRADE_PROMPT.md` — standalone corpus prompt for other IDEs.
- `SESSION_HANDOFF_UI_UPGRADE.md` — this file.

### 2. Foundation code (all written, all `flutter analyze`-clean)
| File | What it does |
|---|---|
| `lib/design/app_assets.dart` | Typed catalog of every `assets/v2/` path — Mor moods, icons, illustrations, Lottie. Screens reference these constants, never raw strings. |
| `lib/design/widgets/mor_companion.dart` | `MorCompanion` widget — renders any `MorMood` static frame with a gentle breathing idle, retina-cached (`cacheWidth`), reduced-motion safe, crash-safe on missing asset. |
| `lib/design/widgets/error_state.dart` | **Upgraded** — now shows **Mor *concern*** by default. Every screen using `ErrorState` gets the companion automatically. |

### 3. Screen upgrades (all `flutter analyze`-clean, wiring untouched)

**Group 1 — Root tabs**
| Screen | What changed |
|---|---|
| `features/home/home_screen.dart` | Warm storefront hero band (`illoHomeStorefront`), **Hero Story Banner** (KPI-driven mission: expiry → tasks → low-stock → all-clear win-beat, **no scan-to-earn**), tinted KPI tiles with glyph wells |
| `features/scan/scan_screen.dart` | Reviewed — already bible-grade, kept |
| `features/scan/scan_result_screen.dart` | v2 health-flag icons (sugar/salt/fat/processed/child) in health chips; Mor *concern* on not-found |
| `features/expiry/expiry_list_screen.dart` | Mor *guard/celebrate* on empty states; Mor *concern* on error |
| `features/tasks/tasks_list_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/profile/profile_screen.dart` | Mor *guard* in the identity card |

**Group 2 — First impression**
| Screen | What changed |
|---|---|
| `features/splash/splash_screen.dart` | Mor *greet* is the splash hero (replaced typographic "R") |
| `features/onboarding/onboarding_screen.dart` | Mor *greet* on welcome page |
| `features/auth/otp_request_screen.dart` | Mor *greet* in brand lockup (replaced orange tile) |
| `features/auth/otp_verify_screen.dart` | Mor *work* watching you type → flips to *celebrate* on success |
| `features/select_store/select_store_screen.dart` | Mor *concern* on "no stores yet" empty |

**Group 3 — Business ops**
| Screen | What changed |
|---|---|
| `features/inventory/inventory_list_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/grn/grn_list_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/subscription/subscription_screen.dart` | Mor *concern* error; Mor *guard* next to "Choose a plan" |

**Group 4 — Consumer / AI / Dashboards**
| Screen | What changed |
|---|---|
| `features/saved_products/saved_products_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/recall/recall_alerts_screen.dart` | Mor *guard* on "no active recalls" |
| `features/shopping_list/shopping_list_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/ohs_dashboard/ohs_dashboard_screen.dart` | Mor *greet* empty; Mor *concern* error |
| `features/referrals/referrals_screen.dart` | Free via `ErrorState` → Mor *concern* |

**Group 5 — Detail / AI screens (error states only)**
| Screen | What changed |
|---|---|
| `features/product/product_detail_screen.dart` | Mor *concern* on load failure |
| `features/ai/ingredient_explainer_screen.dart` | Mor *concern* on load failure |
| `features/alternatives/healthy_alternatives_screen.dart` | Mor *concern* on load failure |
| `features/digest/weekly_digest_screen.dart` | Mor *concern* on load failure |
| `features/reports/reports_screen.dart` | Mor *concern* on load failure |
| `features/inventory/low_stock_alerts_screen.dart` | Mor *concern* on load failure |

---

## Current state — what is already in place

### Assets (v2 set, already in `apps/mobile/assets/v2/` and registered in `pubspec.yaml`)
```
assets/v2/character/mor/
  sheet-turnaround.png   sheet-expressions.png   glyph.png
  parts/parts-sheet.png
  static/{idle,greet,think,work,celebrate,shelter,concern,guard,sleep}.png
  hero-splash.png   hero-offline.png   hero-win.png
assets/v2/character/humans/sheet.png   ramesh-onit.png
assets/v2/icons/  (clock-expiry, box-lowstock, clipboard-tasks, truck-grn, scan-barcode, home,
                   tasks-list, profile-user, sugar-drop, fat-droplet, salt-shaker,
                   processed-factory, child-star, …)
assets/v2/illustration/home-storefront.png   home-mission.png
assets/v2/illustrations/cat-set-8.png   scan-frame.png   spot-expiry.png   spot-storehealth.png
assets/v2/lottie/  (splash.json, scan-success.json, offline-sync.json, win-beat-petals.json)
                   ← these are PLACEHOLDER stubs (≈400 bytes each). Real authored Lottie is TODO.
assets/v2/rive/README.md  ← Rive rig not yet built. Mor is static + breathing idle only.
assets/v2/mockup/  (home.png + states + other screens — design references, not UI)
```

### Design tokens (LOCKED — do not change without reading the bible first)
- **Primary:** burnt-orange `#EA580C` · deep `#9A3412` · tint `#FED7AA`
- **Canvas:** cream `#FFFBF5` (never flat white) · raised `#FFFFFF` · sunken `#F5F1E8`
- **Ink:** `#1C1917` (never pure black) · soft `#57534E`
- **Type:** Plus Jakarta Sans (display + body) · JetBrains Mono (ALL numbers/EAN/dates)
- **No:** Inter, Roboto, emerald green, purple/blue gradients, scan-to-earn rewards

---

## What is REMAINING — the work queue

### Priority 1: `flutter test` regression pass (run first)
```powershell
Set-Location "C:\Users\sayan\Downloads\RADHA_UPGRADED_PROJECT_FILES new\RADHA_UPGRADED_PROJECT_FILES\apps\mobile"
& "C:\src\flutter\bin\flutter.bat" test
```
Visual changes to Home, splash, scan-result, onboarding, OTP likely need **golden test
re-baselines**. For each failing golden: inspect, confirm it looks correct visually, then
run `flutter test --update-goldens` for that specific test file. Fix any non-golden
failures (those are real bugs).

### Priority 2: The five "wow" signature moments (Mor motion)
These make Mor feel *alive* — not just static images. Do these in order:

1. **Splash Lottie** (`assets/v2/lottie/splash.json`) — author a real Lottie: Mor *greet*
   pose draws in, crest rises, tail fans, RADHA wordmark letter-draws. Replace the stub.
   Wire into `splash_screen.dart` using the `lottie` package (add to `pubspec.yaml`).

2. **Scan-success beat** (`scan-success.json`) — on a verified EAN scan: Mor *celebrate*
   + 5 marigold petal particles (`#F59E0B`). Wire into `scan_result_screen.dart` after
   the approval pill confirms `matched`.

3. **Offline shelter beat** (`offline-sync.json`) — Mor *shelter* with a pulsing glow on
   the saved-data box; on reconnect: sync-spark then Mor *celebrate*. Wire into
   `design/widgets/connectivity_banner.dart` (or wherever the offline state is surfaced).

4. **Win-beat petals** (`win-beat-petals.json`) — marigold confetti burst on: audit
   complete, all expiries cleared, GRN posted. Wire wherever those success outcomes fire.

5. **Mor breathing idle** — already in `mor_companion.dart` via `AnimatedBuilder`
   (scale 1.0 + 0.035 * t, offset −2dp). Tune if needed. Add blink (eyelid swap using
   `morMoodFrame(MorMood.idle)` → a "closed" frame every 3–4 seconds).

**Package to add to `pubspec.yaml`:**
```yaml
dependencies:
  lottie: ^3.1.0
```
Then `flutter pub get`.

**Lottie authoring note:** the stub JSONs are minimal placeholders. Author real Lotties
as proper keyframe animations (use LottieFiles editor, or hand-write JSON for simpler
ones). Each must be < 60 KB and respect `MediaQuery.disableAnimations`.

### Priority 3: Remaining screen upgrades (visual layer only, wiring untouched)
These screens have NOT been upgraded yet. For each: read the file, add Mor to any empty/
error states, follow the bible (§ visual-assets.md). Run `flutter analyze lib` after each.

**Secondary operation screens:**
- `features/expiry/expiry_create_screen.dart` — form screen; add Mor *think* as a small
  companion near the OCR-assist affordance (character endorses the AI step).
- `features/expiry/expiry_calendar_screen.dart` — add Mor *guard* when the month grid
  has no entries.
- `features/tasks/task_create_screen.dart` — form; no Mor needed (clean form).
- `features/tasks/task_detail_screen.dart` — add Mor *celebrate* when task status is
  `completed`.
- `features/inventory/stock_movement_screen.dart` — form; no Mor.
- `features/grn/grn_create_screen.dart` — form; no Mor.
- `features/grn/grn_items_screen.dart` — add Mor *work* empty (no items yet).
- `features/scan/ean_audit_screen.dart` — two icon-based `EmptyState` calls (lines 188
  and 570); replace both icons with `MorCompanion(mood: MorMood.guard)` (audit context).

**Account / growth screens (check each for `Icons.error_outline` and bare empty states):**
- `features/settings/settings_screen.dart`
- `features/settings/language_picker.dart`
- `features/support/support_screen.dart`
- Any `home/` or `onboarding/` sub-screens not yet touched.

**Not yet specced (lower priority, create VISUAL_SCREENS files first):**
- Business activation wizard
- Verified badge screen
- Community contribute screen
- Family sharing screen
- Notifications screen

### Priority 4: VISUAL_SCREENS deep specs for remaining 47 screens
`VISUAL_SCREENS/08_home.md` is the template. For each remaining screen, create
`VISUAL_SCREENS/<nn>_<slug>.md` following the §7 template in `visual-assets.md`:
scroll zones · components · tokens · motion · states · asset briefs · a11y · done-gate.
Then generate mockups via `VISUAL_PROMPTS/` in ChatGPT (token-free, see `00_PRIMER.md`).

---

## Quality gates / SOP (run in this order before shipping)

### Step 1 — Static analysis
```powershell
Set-Location "…\apps\mobile"
& "C:\src\flutter\bin\flutter.bat" analyze lib
```
Must exit `No issues found`. Fix all issues before proceeding.

### Step 2 — Unit + widget tests
```powershell
& "C:\src\flutter\bin\flutter.bat" test
```
- Golden failures on the screens we touched → **expected**; re-baseline with
  `--update-goldens` after visual inspection.
- Logic/provider failures → **real bugs**; fix before proceeding.

### Step 3 — Build verification
```powershell
& "C:\src\flutter\bin\flutter.bat" build apk --debug `
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```
Must complete without errors. Alternatively use `.tmp-build-apk.bat` which sets the
required `JAVA_HOME` / `ANDROID_HOME` env vars first.

### Step 4 — Device smoke test (use `mobile-mcp` or manual)
Run on Pixel 4a (or emulator) and verify the "wow five":
1. **Splash** — Mor greet appears; no jank on cold start.
2. **Onboarding** — Mor visible on welcome page; segment cards animate correctly.
3. **OTP verify** — Mor *work* while typing; flips to *celebrate* on success.
4. **Home** — storefront hero visible; Hero Story Banner shows real KPI-driven text
   (not "scan-to-earn"); all-clear beat shows "Shabaash!" when nothing urgent.
5. **Scan → verified** — scan-success beat fires (once Lottie is authored).

Performance checklist (all on Pixel 4a):
- Cold start to first frame < 1.5 s
- Home scroll at 60fps (no jank on KPI tile reveal)
- APK release size < 35 MB (`flutter build apk --release --split-per-abi`)

### Step 5 — Anti-slop gate (per screen)
Before marking any screen "done": could someone say "an AI made that" without doubt?
If yes → fix the structure, not the paint. Check: one orange focal point · Mor present on
empty/error · no nested cards · no generic Material icons where custom ones exist.

---

## Non-negotiables (always, forever)

1. **Visual layer only.** Preserve every Riverpod provider, API call, DTO, route,
   validation, and entitlement gate. Never skip `flutter analyze`.
2. **Bible first.** Before touching any screen, re-read `.kiro/steering/visual-assets.md`.
3. **No scan-to-earn.** No rewards. No fake promo. Real backend missions only.
4. **Mor's teal is ≤ 10%.** Don't make it blue. Don't add gradients.
5. **Tokens only.** No hard-coded colors/spacing/radius/duration in feature code.
6. **Honest data.** Never fabricate product names, counts, or scores.
7. **Performance budget.** `.riv` < 150 KB, Lottie < 60 KB, 60fps on Pixel 4a.
8. **Reduced-motion.** Every animation has a static fallback. Gate on
   `MediaQuery.disableAnimations`.
9. **Windows shell.** The host is PowerShell. Flutter SDK is at
   `C:\src\flutter\bin\flutter.bat`. Don't start dev-servers from agent tools.
10. **`flutter analyze lib`** — run after every file change. If it exits with issues,
    fix them before moving on. The app must always be in an analyze-clean state.
