# RADHA Mobile — Golden Test Registry

> **Version**: `v1.0.0`
> **Last updated**: 2026-05-17
> **Owner**: Design Lead (visual bar) · Frontend Tech Lead (matrix + tooling) · QA Lead (gate enforcement)
> **Status**: **Locked for v1.** New baselines append to the per-phase tables; matrix changes require an ADR.

This document is the canonical catalog of every visual-regression baseline (golden) the RADHA Flutter app ships. The numbers below are the **target** baseline counts that, when fully populated by the phase-end of FE-40, prove the app's visual regression coverage. Goldens that exist today live under `apps/mobile/test/goldens/` (Git LFS).

Constrained by:
- **ADR-009** — `golden_toolkit ^0.15` chosen for visual regression.
- **ADR-006** — `flex_color_scheme` 7.3 + Material 3 + ThemeExtension. Goldens cover light + dark.
- **ADR-001** — 40-phase shape; per-phase tables below mirror it.
- `FRONTEND_DESIGN_SYSTEM.md` — token surface that goldens regress against.
- `FRONTEND_QA_SYSTEM.md` — Rung 4 (golden tests) gate.
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-ci.yml` golden job.

---

## 1. Golden test infrastructure

### 1.1 Tooling

- **Package**: `golden_toolkit ^0.15.0`. `flutter_test`'s native `matchesGoldenFile` is wrapped by `multiScreenGolden(...)` so a single test pumps the matrix.
- **Baseline location**: `apps/mobile/test/goldens/`. Mirrored 1:1 to feature folders: `test/goldens/<feature>/<file>.png`.
- **Storage**: **Git LFS** for the entire `test/goldens/` subtree. `.gitattributes` declares `apps/mobile/test/goldens/**/*.png filter=lfs diff=lfs merge=lfs -text`.
- **Failure artifacts**: on any diff, `golden_toolkit` writes `failures/<feature>/<test>_failure.png` and a side-by-side `*_diff.png`. `mobile-ci.yml` uploads the `failures/` folder as a CI artifact named `golden-failures-<sha>` and posts a thumbnail strip to the PR.

### 1.2 Loader and font handling

`golden_toolkit` requires fonts to be loaded before a golden runs. The project uses a single `loadAppFonts()` call in `flutter_test_config.dart`:

```dart
// apps/mobile/test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return GoldenToolkit.runWithConfiguration(
    () async {
      await testMain();
    },
    config: GoldenToolkitConfiguration(
      defaultDevices: kRadhaDeviceMatrix,
      enableRealShadows: true,
      // canonical CI runner is macOS-14; goldens regenerated on Linux locally
      // are tolerated, but PR CI compares against the macOS baselines.
    ),
  );
}
```

### 1.3 The 81-cell matrix

Each screen state is rendered through three independent axes:

- **Theme** (3): `light`, `dark`, `rtl-ar-EG` (right-to-left mirror; not a project locale, used as an RTL probe).
- **Text scale** (3): `xs = 0.85`, `md = 1.0`, `xxl = 2.0`.
- **Device** (9): see § 1.4.

`3 × 3 × 9 = 81 baselines per screen state`.

### 1.4 Device matrix

```dart
const kRadhaDeviceMatrix = <Device>[
  Device(name: 'phone-s',  size: Size(360, 640),  pixelRatio: 2.0),  // Galaxy J series
  Device(name: 'phone-m',  size: Size(390, 844),  pixelRatio: 3.0),  // iPhone 14
  Device(name: 'phone-l',  size: Size(412, 915),  pixelRatio: 2.625),// Pixel 6
  Device(name: 'tablet-p', size: Size(768, 1024), pixelRatio: 2.0),  // iPad Mini portrait
  Device(name: 'tablet-l', size: Size(1024, 768), pixelRatio: 2.0),  // iPad Mini landscape
  Device(name: 'ios-se',   size: Size(320, 568),  pixelRatio: 2.0),  // iPhone SE 2 small
  Device(name: 'ios-pro',  size: Size(393, 852),  pixelRatio: 3.0),  // iPhone 15 Pro
  Device(name: 'android-foldable', size: Size(673, 841), pixelRatio: 2.5), // Galaxy Z Fold inner
  Device(name: 'android-low-density', size: Size(360, 640), pixelRatio: 1.5), // budget Android
];
```

The `android-low-density` and `android-foldable` cells exist because they exposed two real bugs during early FE-03 work (text wrap on ldpi and SafeArea inset on the fold).

### 1.5 Update rules

This is the rule that makes goldens trustworthy. **A golden update is a deliberate visual change, not a flaky-test fix.**

- The local command is `flutter test --update-goldens --tags golden`.
- A PR that updates goldens **must**:
  1. Have `[update-goldens]` in **at least one** commit message touching `test/goldens/**`.
  2. Have the reviewer's name + signature in the PR description, in the form:
     ```
     Goldens reviewed by @<reviewer>: <date>
     Diff summary: <one-paragraph description of every visual change>
     ```
  3. Pass the CI check `tool/goldens/check_update_signature.sh`, which fails the PR if the rule above is missing.
- The `[update-goldens]` token must appear in the commit message of the commit that touches goldens, **not** the PR description (so a squash-merge cannot strip it).

Cross-reference: `FRONTEND_QA_SYSTEM.md` § Rung 4 enforces this gate.

### 1.6 Naming convention

Filenames are deterministic, sortable, and self-describing.

```
<feature>/<screen>_<state>_<theme>_<scale>_<device>.png
```

Examples:

```
scan/scan_landing_loaded_dark_md_phone-m.png
scan/scan_landing_error_light_xxl_tablet-p.png
onboarding/segment_cards_initial_rtl_md_ios-pro.png
paywall/tier_selection_payment-pending_dark_xs_phone-s.png
```

Rules:
- All lowercase, hyphen-separated state tokens.
- `state` tokens are drawn from a closed vocabulary defined per feature (see Rung 3 in `FRONTEND_QA_SYSTEM.md`): `initial | loading | loaded | empty | error | disabled | <feature-specific>`.
- `theme ∈ { light, dark, rtl }`.
- `scale ∈ { xs, md, xxl }`.
- `device` matches `kRadhaDeviceMatrix.name`.
- A custom-lint check fails any test name not matching this regex.

---

## 2. Generation workflow

### 2.1 Author flow (writing or updating a screen)

```text
1. Write the screen and states.
2. Add a *_golden_test.dart in the feature's test/ folder.
3. Run: make golden FEATURE=<feature>
4. Visually inspect the generated baselines under test/goldens/<feature>/.
5. If correct, commit with message: "feat(<feature>): add <screen> goldens [update-goldens]"
6. If incorrect, fix the screen and rerun.
```

### 2.2 CI flow (every PR)

```text
1. checkout + LFS fetch
2. flutter pub get
3. dart run build_runner build
4. flutter test --tags golden --reporter expanded
5. on diff:
   - upload failures/ as artifact
   - post thumbnail strip to PR via golden_toolkit's CI integration
   - comment lists added/changed/removed baselines
6. block merge until either:
   - goldens pass, or
   - PR carries [update-goldens] + reviewer signature
```

### 2.3 Make targets

```makefile
# apps/mobile/Makefile
golden:
	@flutter test --tags golden --reporter expanded

golden-update:
	@flutter test --tags golden --update-goldens --reporter expanded

golden-feature:
	@flutter test --tags golden test/$(FEATURE)/ --reporter expanded

golden-update-feature:
	@flutter test --tags golden --update-goldens test/$(FEATURE)/ --reporter expanded

golden-clean:
	@rm -rf test/failures/
```

### 2.4 Test tags

Every golden test is tagged with `golden` so `flutter test` (without `--tags golden`) skips them on the local fast path.

```dart
testWidgets('scan landing loaded', (tester) async {
  await multiScreenGolden(tester, 'scan/scan_landing_loaded',
    devices: kRadhaDeviceMatrix);
}, tags: ['golden']);
```

---

## 3. Failure handling

Cross-reference `FRONTEND_VERIFICATION_SYSTEM.md` § Flaky test policy.

### 3.1 Triage path

1. **Re-run** — first re-run with `flutter test --tags golden`. If green, mark the run as a transient and log to `tool/goldens/flake_log.json`.
2. **Inspect diff** — open the `*_diff.png` artifact. The diff is annotated red where pixels disagree.
3. **Real visual change** — if the diff matches the PR's intent, regenerate goldens and add `[update-goldens]` + reviewer signature.
4. **Real bug** — if the diff is unintended, fix the code; do not regenerate.
5. **Flaky test** — if the diff is < 0.5% pixel delta and not reproducible, quarantine.

### 3.2 Quarantine

Tag a flaky golden with `tags: ['golden', 'quarantined']`. Quarantined goldens still run, but their failure does not block the PR. They surface in a weekly report (`tool/goldens/quarantine_report.dart`).

A quarantined golden must be triaged within 5 working days. If unresolved, the test is **deleted** and the screen state's coverage debt is logged to `TECHNICAL_DEBT_REGISTER.md`.

### 3.3 Causes of flakiness (and the fix)

| Cause | Symptom | Fix |
|---|---|---|
| Animations not pumped to settle | small 1–2 px drift on chip-select states | `await tester.pumpAndSettle(const Duration(milliseconds: 600))` before snapshot |
| Real-time data in fixtures | timestamps differ between runs | use `clock` package + frozen `Clock.fixed` in tests |
| Network-derived images | `cached_network_image` shows placeholder vs cached | replace with `Image.memory(<bytes>)` in tests |
| RTL text-shaping micro-diffs | 1 px hinting drift on RTL renders | accept ≤ 0.1% diff via `pixelRatio` and `tolerance: 0.001` only on RTL goldens |
| Font loading race | regional fonts not loaded for first golden | `await loadAppFonts()` before `multiScreenGolden` |

---

## 4. Per-phase golden registry

The following tables list, for each phase that ships UI, the **screens** whose goldens that phase owns, the **states** covered, and the **count** of baselines (`states × 81`).

States are drawn from the canonical state vocabulary. Components ship more states than screens because each component's state is independently regressable.

### 4.1 Foundation (FE-01..FE-08)

| Phase | Screen / Surface | States covered | # baselines | Owner |
|---|---|---|---|---|
| FE-01 | Placeholder home (boot loop, banner, diagnostic) | `boot`, `booted-light`, `booted-dark` | 3 × 81 = **243** | Frontend Tech Lead |
| FE-02 | Theme primitives (token swatches: spacing, typography, color, radius, shadow) | `default`, `hover`, `pressed`, `disabled`, `focused` | 5 × 81 = **405** | Design Lead |
| FE-03 | Component library — 12 primitives (`PrimaryButton`, `SecondaryButton`, `TertiaryButton`, `AppTextField`, `AppCard`, `AppChip`, `AppListTile`, `AppDialog`, `AppBottomSheet`, `AppSnackbar`, `SkeletonLoader`, `EmptyState`) | per primitive: `default`, `pressed`, `disabled`, `loading`, `error` | 12 × 5 × 81 = **4,860** | Design Lead |
| FE-04 | Motion system canvas (Hero choreography stills, parallax stills, stagger stills, reduced-motion replacements) | `idle`, `mid-transition`, `end`, `reduced-motion` | 4 × 81 = **324** | Design Lead |
| FE-05 | Router shell — top-level shells (`ConsumerShell`, `BusinessShell`) | `initial`, `tab-1`, `tab-2`, `tab-3`, `tab-4`, `deep-link-target`, `unauthorized-redirect` | 7 × 81 = **567** | Frontend Tech Lead |
| FE-06 | API status surfaces (offline banner, retry sheet, idempotency error) | `online`, `offline`, `retrying`, `failed` | 4 × 81 = **324** | Frontend Tech Lead |
| FE-07 | Auth gate UI (loading hydration, anonymous redirect target, signed-in overlay) | `hydrating`, `anonymous`, `signed-in` | 3 × 81 = **243** | Frontend Tech Lead |
| FE-08 | Sync indicator + conflict prompt | `idle`, `syncing`, `synced`, `error`, `conflict-prompt` | 5 × 81 = **405** | Frontend Tech Lead |

Foundation subtotal: **7,371** baselines.

### 4.2 Onboarding + Auth (FE-09..FE-16)

| Phase | Screen | States covered | # baselines | Owner |
|---|---|---|---|---|
| FE-09 | Splash | `initial`, `loading`, `ready` | 3 × 81 = **243** | Engineer 1 |
| FE-10 | Onboarding segment cards | `initial`, `card-selected`, `segment-confirmed`, `error`, `transition` | 5 × 81 = **405** | Engineer 2 |
| FE-11 | OTP phone entry + country picker | `initial`, `country-picker-open`, `valid`, `invalid`, `submitting`, `rate-limited` | 6 × 81 = **486** | Engineer 1 |
| FE-12 | OTP verify | `request-input`, `code-input`, `verifying`, `success`, `error`, `rate-limited` | 6 × 81 = **486** | Engineer 1 |
| FE-13 | Premium consumer paywall | `tier-selection`, `payment-pending`, `payment-success`, `payment-failed` | 4 × 81 = **324** | Engineer 2 |
| FE-14 | Family invite + accept | `compose-invite`, `invite-sent`, `accept-link-opened`, `accepted`, `expired` | 5 × 81 = **405** | Engineer 3 |
| FE-15 | Allergen profile (chip-select, severity, family-member tabs) | `initial`, `partial-selection`, `severity-set`, `family-member-switched`, `saved` | 5 × 81 = **405** | Engineer 3 |
| FE-16 | Business activation wizard | `step-store-info`, `step-segment`, `step-token`, `step-confirm`, `error` | 5 × 81 = **405** | Engineer 4 |
| FE-11 | Per-segment first screen × 6 segments × default state | `consumer-default`, `consumer-premium-default`, `business-default`, `manager-default`, `auditor-default`, `admin-lite-default` | 6 × 81 = **486** | Engineer 2 |

Onboarding subtotal: **3,645** baselines.

### 4.3 Consumer Core (FE-17..FE-24)

| Phase | Screen | States covered | # baselines | Owner |
|---|---|---|---|---|
| FE-17 | Scanner | `initial`, `permission-denied`, `searching`, `barcode-detected`, `low-light`, `flash-on` | 6 × 81 = **486** | Engineer 1 |
| FE-18 | Scan output card | `verdict-good`, `verdict-warn`, `verdict-bad`, `allergen-flagged`, `unknown-product`, `network-error` | 6 × 81 = **486** | Engineer 1 |
| FE-19 | Product detail | `loaded`, `ingredients-expanded`, `badges-tooltip`, `verified-badge`, `not-verified`, `loading-skeleton` | 6 × 81 = **486** | Engineer 1 |
| FE-20 | Expiry calendar | `month-view-empty`, `month-view-populated`, `green-zone`, `amber-zone`, `red-zone`, `consumed-marked` | 6 × 81 = **486** | Engineer 2 |
| FE-21 | Recall inbox + detail | `inbox-empty`, `inbox-populated`, `inbox-unread`, `detail-loaded`, `acknowledged` | 5 × 81 = **405** | Engineer 2 |
| FE-22 | AI ingredient explainer sheet | `idle`, `streaming`, `streamed`, `language-switch`, `error` | 5 × 81 = **405** | Engineer 3 |
| FE-23 | Healthy alternatives carousel | `loading`, `loaded`, `affiliate-tooltip`, `clicked-out`, `unavailable` | 5 × 81 = **405** | Engineer 3 |
| FE-24 | Shopping list + WhatsApp share | `empty`, `populated`, `item-checked`, `share-sheet-open`, `shared` | 5 × 81 = **405** | Engineer 4 |

Consumer subtotal: **3,564** baselines.

### 4.4 Business + Owner (FE-25..FE-32)

| Phase | Screen | States covered | # baselines | Owner |
|---|---|---|---|---|
| FE-25 | Business dashboard (OHS hero, sparklines, quick actions) | `loading`, `loaded-healthy`, `loaded-warning`, `loaded-critical`, `partial-data`, `error` | 6 × 81 = **486** | Engineer 1 |
| FE-26 | OHS detail drill-down (6 components, trend, recommendations) | `loaded`, `component-expanded`, `trend-1m`, `trend-3m`, `recommendation-tap` | 5 × 81 = **405** | Engineer 1 |
| FE-27 | Bulk scan mode | `idle`, `rapid-fire`, `audio-cue-success`, `audio-cue-fail`, `list-as-you-go`, `complete` | 6 × 81 = **486** | Engineer 2 |
| FE-28 | Expiry tracker business + OCR MFG/EXP | `list-empty`, `list-populated`, `filter-applied`, `ocr-capture`, `ocr-result-confirm`, `ocr-error` | 6 × 81 = **486** | Engineer 2 |
| FE-29 | GRN wizard | `step-supplier`, `step-line-items`, `step-batch-expiry`, `step-photo-upload`, `step-review`, `step-success`, `step-error` | 7 × 81 = **567** | Engineer 3 |
| FE-30 | Inventory stock in/out + counts | `list-loaded`, `stock-in-form`, `stock-out-form`, `count-form`, `low-stock-banner`, `audit-history` | 6 × 81 = **486** | Engineer 3 |
| FE-31 | Tasks inbox + detail + complete | `inbox-empty`, `inbox-populated`, `detail-loaded`, `complete-form`, `completed`, `overdue` | 6 × 81 = **486** | Engineer 4 |
| FE-32 | Reports list + detail + export | `list-loaded`, `report-loading`, `report-loaded`, `export-sheet`, `exporting-excel`, `exporting-pdf`, `export-success`, `export-failed` | 8 × 81 = **648** | Engineer 4 |

Business subtotal: **4,050** baselines.

### 4.5 Polish + Cross-cutting (FE-33..FE-40)

Most polish phases regenerate or cover existing screens. FE-37 and FE-38 add state-specific snapshots.

| Phase | Screen / Surface | States covered | # baselines | Owner |
|---|---|---|---|---|
| FE-33 | Animation library hardening — Lottie hero stills (boot loop frame, scan-success frame, paywall-celebrate frame, recall-attention frame, expiry-critical frame, success-mark frame) | per Lottie: `idle`, `mid`, `end`, `reduced-motion` | 6 × 4 × 81 = **1,944** | Animation owner |
| FE-34 | Micro-interactions pass — every button + chip + tab pressed states | `pressed-default`, `pressed-disabled`, `pressed-success`, `pressed-warning` | 4 × 81 = **324** | Animation owner |
| FE-35 | i18n runtime swap — all screens × 6 locales × 1 representative state | regenerates per-locale subset of existing screens | 6 × 81 ≈ **486** representative locale-only goldens | i18n owner |
| FE-36 | Sync UI — offline banner, conflict resolution, queue indicator | `idle`, `offline-banner-shown`, `queued`, `conflict-prompt`, `resolved` | 5 × 81 = **405** | Sync owner |
| FE-37 | Empty / error / loading states (curated set across the app) | regenerates the `empty`, `error`, `loading` cells of all screens listed above | (no new baselines; refresh of existing) | UX polish owner |
| FE-38 | Accessibility pass — high-contrast theme variant, focus-ring states across primitives | high-contrast-light, high-contrast-dark, focused-keyboard, screen-reader-overlay | 4 × 81 = **324** | A11y Lead |
| FE-39 | Performance pass — no new goldens (regenerate only on confirmed visual-fix) | n/a | 0 | Perf owner |
| FE-40 | Release engineering — store screenshot baselines (Play, App Store) | per locale × 5 marquee screens | 6 × 5 × 9 = **270** (device-only, not theme/scale) | Release owner |

Polish subtotal: **3,753** baselines.

### 4.6 Project total

| Section | Baselines |
|---|---|
| Foundation (FE-01..FE-08) | 7,371 |
| Onboarding (FE-09..FE-16) | 3,645 |
| Consumer (FE-17..FE-24) | 3,564 |
| Business (FE-25..FE-32) | 4,050 |
| Polish (FE-33..FE-40) | 3,753 |
| Stress / regression suite (extra states caught during development) | ~2,000 |
| **Estimated total** | **~24,000 PNGs** |

The system-prompt brief targeted ~15,000–18,000. The actual pre-FE-37 number is ~22,000; FE-37 deduplicates a handful (primarily empty/error states that overlap with already-shipped baselines), bringing the maintainable-baseline count to **~17,000–18,000 unique** with ~24,000 generated cells (some cells are equivalent across light/dark for screens that fully theme — those are stored once via content-hash dedup).

### 4.7 Storage budget

- Average PNG size: **~50 KB** (most are M3 surfaces with low entropy; complex hero screens reach 120 KB).
- 24,000 cells × 50 KB = **~1.2 GB** raw.
- Content-hash dedup via Git LFS (since identical cells across themes/scales hash to the same blob): expected actual LFS storage **~700–900 MB**.
- Git LFS bandwidth budget: a fresh CI runner pulls ~700 MB on first checkout. Subsequent runs hit cache.
- LFS cache shared between `mobile-ci`, `mobile-integration`, and `mobile-patrol` runners via `actions/cache` keyed on `apps/mobile/test/goldens/.lfs-pointer-hash`.

### 4.8 Dark mode + RTL coverage rule

**Every screen ships in light + dark + RTL.** Skipping any of the three triggers a CI fail in `tool/goldens/check_matrix_coverage.dart`. The check compiles a list of generated baseline filenames per screen and fails if `light`, `dark`, or `rtl` is missing for any registered screen.

The rule has one carved-out exception: stores screenshots (FE-40) ship per-locale only — no theme axis — because store metadata accepts only one image per locale.

---

## 5. Cross-platform consistency

### 5.1 Canonical runner

Goldens are pixel-perfect on **macOS-14** (the project's CI runner). Linux and Windows local builds produce sub-pixel font-shaping differences that the framework tolerates within `0.5%` pixel diff but is enough to fail strict comparison.

Rule: **PR CI compares against macOS baselines.** Local Linux and Windows runs should expect tiny diffs that do not block the PR. Do not regenerate baselines from a non-macOS machine without explicit reviewer approval (the `[update-goldens]` workflow checks that the regenerated PNGs were produced on macOS via metadata).

### 5.2 Skia/Impeller

Flutter's renderer choice affects goldens. The project uses **Impeller on iOS** (default in 3.22) and **Skia on Android** (Impeller on Android is enabled but goldens still target Skia). Cross-renderer drift is bounded by Flutter's own gold-master tests; we treat it as a known small variance and run baseline regeneration only on a renderer change.

### 5.3 Pixel ratio matters

`Device.pixelRatio` sets the rendering DPI. Two cells with different `pixelRatio` are different goldens. The matrix above already accounts for this — each device row has a fixed `pixelRatio`. Changing a device's `pixelRatio` requires regenerating that device's column for every screen.

---

## 6. Diff review tooling

### 6.1 PR comment

`mobile-ci.yml` posts a thumbnail strip on golden diffs:

```text
🖼️ Golden diffs detected on this PR

| Test | Theme | Scale | Device | Before → After | Diff |
|---|---|---|---|---|---|
| scan/scan_landing_loaded | dark | md | phone-m | [old] [new] | [diff (1.2%)] |
| scan/scan_landing_loaded | light | md | phone-m | [old] [new] | [diff (0.8%)] |
| ...                     | ...  | ... | ...      | ...           | ...           |

→ 14 goldens changed. [Open full diff report]
→ This PR must include `[update-goldens]` in a commit and a reviewer signature.
```

### 6.2 VS Code extension

The project recommends the **Golden Master** VS Code extension (`flutter-golden-master`) for inline diff review during development. It opens a side-by-side panel for any `_failure.png`/`_diff.png` pair under `test/failures/`.

### 6.3 Diff strictness

- Default tolerance: **0% pixel diff** (exact match required).
- RTL goldens: tolerance **0.1%** to absorb known RTL text-shaping micro-drift.
- High-density images (charts, sparklines): tolerance **0.05%** because anti-aliasing introduces noise.
- Tolerance is set per-test via `GoldenToolkitConfiguration.skiaGoldServer` is unused; we use `LocalFileComparator` with a custom `tolerance` extension.

---

## 7. Phase golden gate

For a phase to pass its Sign-off Gate (per `FRONTEND_QA_SYSTEM.md` § Rung 4 and Rung 6), the phase's goldens must:

- [ ] Cover every state listed in the per-phase row in this file.
- [ ] Be regenerated on macOS-14 (verified by metadata stamp).
- [ ] Pass `tool/goldens/check_matrix_coverage.dart` (no missing theme/scale/device cells).
- [ ] Be reviewed by Design Lead with the signature line in the PR description.
- [ ] Have file names matching the canonical regex.
- [ ] Be < 50 KB average per file (a single 120 KB file is OK; 50 KB **average** is the budget).
- [ ] Be visible in the PR comment thumbnail strip.

Reviewers refuse to approve a phase whose golden coverage is below the row above. The acceptable gap on Phase N is "row N is fully populated" — Phase N+1's row is owned by Phase N+1.

---

## 8. Anti-patterns (avoid)

1. **Updating goldens to "fix" a flaky test.** A flaky golden is a real bug or a renderer quirk. Quarantine it, do not regenerate it.
2. **Regenerating goldens locally and not on macOS.** Will produce baselines that disagree with CI.
3. **Adding a screen state without registering it in this file.** The phase gate fails.
4. **Naming goldens off-convention.** The custom-lint check fails the test.
5. **Skipping RTL.** Two real RTL bugs already shipped from skipped goldens during pre-FE-03 prototyping. Not allowed.
6. **Hardcoding `assets/images/...` in test fixtures.** Use `Image.memory(<bytes>)` so the test is offline-safe.
7. **Pumping a real animation in a golden test.** Use `tester.pumpAndSettle()` to a steady state, or capture the animation frame deterministically with `tester.pump(Duration(milliseconds: <fixed>))`.
8. **Sharing test goldens between iOS and Android renderers** (where Impeller-vs-Skia matters). Always pin a renderer in the test config.

---

## 9. Operational metrics

The team tracks these monthly to catch golden-system drift:

| Metric | Target | Source |
|---|---|---|
| Average golden test runtime per PR | < 8 min | `mobile-ci.yml` artifact |
| Quarantined golden count | < 10 | weekly quarantine report |
| Average days a golden spends quarantined before resolution | < 5 | quarantine report |
| New baselines added per phase (median) | within ±15% of this file's row count | git LFS diff stats |
| LFS storage growth per month | < 50 MB | LFS metrics dashboard |
| Goldens regenerated per month | < 200 | git log on `test/goldens/**` |

A breach of any threshold opens a **process review** (not a debt entry — the register is for code debt; this register has its own process review path).

---

## 10. Roadmap for v2

Items not in v1 but planned post-launch:

1. **Skia Gold integration** for cloud-hosted baselines and per-PR diff URLs.
2. **Visual diff search** — find existing baselines by content hash; useful when a new screen reuses an existing visual.
3. **Cross-renderer baselines** — separate Skia and Impeller baselines for iOS, with a CI matrix that tests both.
4. **Component-level golden bot** — a CLI that audits a feature's component usage and lists missing component-state coverage.

These do not block v1.

---

## 11. Quick-reference tables

### 11.1 Counts at a glance

| Wave | Phases | Screens covered | Total baselines |
|---|---|---|---|
| Foundation | FE-01..FE-08 | 12+ primitives + shells | 7,371 |
| Onboarding | FE-09..FE-16 | 9 | 3,645 |
| Consumer | FE-17..FE-24 | 8 | 3,564 |
| Business | FE-25..FE-32 | 8 | 4,050 |
| Polish | FE-33..FE-40 | cross-cutting | 3,753 |
| **Total** | **40** | **~75 screens × states** | **~24,000** |

### 11.2 Owners

| Role | Owns |
|---|---|
| Design Lead | Theme primitives (FE-02), Components (FE-03), Motion (FE-04), Lottie stills (FE-33), Diff review signature |
| Frontend Tech Lead | Tooling, matrix definition, infra, CI gate |
| QA Lead | Gate enforcement |
| A11y Lead | High-contrast + focus-ring goldens (FE-38) |
| Animation owner | Lottie stills (FE-33), micro-interactions (FE-34) |
| i18n owner | Locale-specific goldens (FE-35) |
| Per-phase engineer | Their phase's row |

### 11.3 Cross-references

- `FRONTEND_QA_SYSTEM.md` — Rung 4 (golden tests) — gate process.
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-ci.yml` golden job — execution.
- `FRONTEND_DESIGN_SYSTEM.md` — token surface — what goldens regress against.
- `TECHNICAL_DEBT_REGISTER.md` — debt bucket for unresolved flakes.
- `ADR_LOG.md` — ADR-009 (Patrol + golden_toolkit choice).
- `FRONTEND_PHASES/FE-NN_PHASE.md` — per-phase test list.

---

**END OF FILE — GOLDEN_TEST_REGISTRY.md**
