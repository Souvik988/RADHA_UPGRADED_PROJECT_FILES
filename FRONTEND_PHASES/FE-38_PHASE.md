# Phase FE-38: Accessibility Audit + A11y Modes

## Phase Metadata
- **Phase ID**: FE-38
- **Phase Name**: Accessibility Audit + A11y Modes
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: every prior FE phase (audit covers them all), particularly FE-02 (tokens — color contrast), FE-33 (motion — reduced motion), FE-34 (interactions — haptic + semantics), FE-35 (i18n — TalkBack/VoiceOver scripts per locale), FE-37 (states — semantic announcements)
- **Backend Depends On**: BE-48 observability (a11y telemetry), BE-29 analytics (`a11y_mode_active` event)
- **Blocks**: FE-40 (release prep gates on a11y green)
- **Estimated Duration**: 4-5 days
- **Complexity**: High — touches every screen, requires real assistive-tech testing

## Goal
Ship to **WCAG 2.1 AA** as the minimum bar across all 25 screens, with measurable, automated, and human-verified compliance. Specifically:

- **Semantics labels on every interactive element** (buttons, cards, tiles, chips, sliders, toggles, list rows, etc.) — no element is invisible to TalkBack/VoiceOver.
- **Focus order** verified screen-by-screen to follow visual reading order, with no traps and no skipped elements.
- **Dynamic type up to xxLarge** (200% scaling) on every screen — no clipping, no overflow, no overlap.
- **Reduced motion mode** (system flag respected) — already wired through FE-33; this phase audits.
- **High contrast mode** (system flag respected) — alternate color tokens for active/focused/error states.
- **Color contrast verified**: 4.5:1 for body text, 3:1 for large text and graphical UI, 7:1 for critical safety surfaces (allergen warnings).
- **VoiceOver and TalkBack walkthrough scripts** per critical user flow (8 flows × 6 languages × 2 platforms = 96 documented walkthroughs).
- **Per-screen a11y scorecard** with pass/fail/note per criterion.
- **Automated a11y test suite** running in CI on every PR (`flutter test --tags a11y`).
- **Two RADHA-specific a11y modes**: "RADHA High Contrast" (stronger than system, uses brand colors) and "RADHA Bold" (1.2× stroke weight everywhere).

This is the gate that decides whether we earn Material Design Award and Apple Design Award nominations.

## Why This Phase Matters
- **Legal compliance**: India's Rights of Persons with Disabilities Act (RPwD 2016) requires accessible digital services for public-interest apps. Food safety + retail audits arguably qualify.
- **App store gates**: Apple has rejected apps in 2024-2025 for missing dynamic type and reduced motion. Google Play's Accessibility Scanner flags issues at submission.
- **Market size**: India has ~26M visually impaired users (WHO 2023). Many are exactly RADHA's target audience: elderly relatives whose family installs RADHA to track allergens and expiry.
- **Award eligibility**: every Material Design Award and Apple Design Award winner in 2023-2024 ships full a11y. It's table stakes.
- **Brand quality**: a11y reveals attention to detail that nothing else does. A visually impaired user who can complete the entire scan-to-save flow with VoiceOver is the strongest brand testimony possible.
- **Engineering hygiene**: a11y audits expose layout bugs (e.g., a `Container` with no semantic role) before users see them — and tighten the entire UI as a side effect.

## Prerequisites
- [ ] All FE-09..FE-37 screens merged.
- [ ] Test fleet: at least one Android phone with TalkBack and one iPhone with VoiceOver — production-like, not dev devices.
- [ ] Native screen-reader users on call for 1.5 days of human testing.
- [ ] `accessibility_tools` Flutter package for scanner.
- [ ] Color-contrast checking tool (we use `color_contrast_ratio` Dart package wired to a CI step).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/a11y/a11y_mode.dart` | `enum A11yMode { standard, highContrast, bold, reducedMotion }` |
| `apps/mobile/lib/a11y/a11y_provider.dart` | Riverpod provider that resolves active modes from system + user settings |
| `apps/mobile/lib/a11y/contrast_tokens.dart` | High-contrast color token overrides |
| `apps/mobile/lib/a11y/bold_tokens.dart` | Bold-mode typography + stroke overrides |
| `apps/mobile/lib/a11y/semantics_helpers.dart` | `RadhaSemantics.button(...)`, `RadhaSemantics.heading(...)` etc. — encourages correct usage |
| `apps/mobile/lib/a11y/focus_helpers.dart` | `FocusOrder` widget that asserts traversal order in tests |
| `apps/mobile/lib/a11y/dynamic_type_guard.dart` | Wrapper that asserts no overflow at 2.0× textScaler in debug |
| `apps/mobile/lib/a11y/a11y_diagnostics.dart` | Debug overlay listing missing semantics on visible widgets |
| `apps/mobile/lib/features/settings/a11y_settings_screen.dart` | User-facing toggles |
| `apps/mobile/test/a11y/contrast_test.dart` | Automated contrast scan |
| `apps/mobile/test/a11y/semantics_test.dart` | Asserts every interactive widget has a label |
| `apps/mobile/test/a11y/dynamic_type_overflow_test.dart` | xxLarge layout test |
| `apps/mobile/test/a11y/focus_order_test.dart` | Per-screen traversal test |
| `apps/mobile/integration_test/a11y_walkthrough_test.dart` | Critical-flow walkthroughs |
| `docs/a11y/SCORECARDS.md` | Per-screen scorecard committed to repo |
| `docs/a11y/SCRIPTS.md` | Walkthrough scripts (8 flows × 6 langs × 2 platforms) |

## Implementation Spec

### `A11yMode` resolution
```dart
class A11yProvider extends Notifier<A11ySnapshot> {
  @override
  A11ySnapshot build() => _resolve();

  A11ySnapshot _resolve() {
    final mq = WidgetsBinding.instance.platformDispatcher;
    final user = ref.read(a11yUserSettingsProvider);
    return A11ySnapshot(
      reducedMotion: mq.accessibilityFeatures.disableAnimations || user.reducedMotion,
      highContrast: mq.accessibilityFeatures.highContrast    || user.highContrast,
      bold:           user.bold,
      textScaler:     mq.textScaleFactor.clamp(1.0, 2.0),
      screenReaderOn: mq.accessibilityFeatures.accessibleNavigation,
    );
  }
}
```

### `RadhaSemantics` helpers
```dart
class RadhaSemantics {
  static Widget button({
    required String label,
    required Widget child,
    String? hint,
    bool enabled = true,
    VoidCallback? onTap,
  }) => Semantics(
    button: true,
    enabled: enabled,
    label: label,
    hint: hint,
    onTap: onTap,
    excludeSemantics: true, // we provide our own; don't double-up
    child: child,
  );

  static Widget heading({required String level, required Widget child, required String label}) =>
    Semantics(header: true, label: label, child: child);

  static Widget liveRegion({required Widget child, String? announcement}) =>
    Semantics(liveRegion: true, label: announcement, child: child);
}
```

### Focus order verification
```dart
class FocusOrder extends StatelessWidget {
  final List<Widget> children;       // expected traversal order
  // In tests, calls `tester.binding.focusManager.primaryFocus` after Tab presses
  // and asserts each child receives focus in declared order.
}
```

### `A11ySettingsScreen`
| Section | Toggle |
|---|---|
| Vision | High contrast (system) — read-only mirror |
| Vision | RADHA High Contrast (extra-strong) — user toggle |
| Vision | RADHA Bold (1.2× stroke) — user toggle |
| Vision | Show contrast ratio overlay (debug builds) |
| Motion | Reduced motion (system) — read-only mirror |
| Motion | Force reduced motion (override system) — user toggle |
| Hearing | Captions for instructional Lotties — user toggle |
| Touch | Haptics enabled — user toggle (mirrors FE-34) |
| Reading | Native digits in numbers (Devanagari/Tamil/Telugu/Bengali) — user toggle |

## Patterns / Reusable Widgets

| Helper | API |
|---|---|
| `RadhaSemantics.button / heading / liveRegion / image` | Encourages correct semantic role usage |
| `A11yMode` snapshot via Riverpod | Read by themes, motion tokens, and selected widgets |
| `FocusOrder` test helper | Declares + verifies traversal order |
| `DynamicTypeGuard` debug widget | Asserts no overflow at 2× scaler |
| `A11yDiagnostics` debug overlay | Lists missing labels in dev builds |
| Contrast-token swap | At `Theme` level — all colors switch when high contrast is on |
| `RadhaBoldText` | Optional wrapper applying 1.2× font weight + 1.05× letter spacing in bold mode |

## Configuration / Tokens

| Token | Value | Source |
|---|---|---|
| `a11y.target.WCAG` | 2.1 AA | The bar |
| `a11y.contrast.body.minRatio` | 4.5 : 1 | WCAG AA |
| `a11y.contrast.largeText.minRatio` | 3 : 1 | ≥ 18pt or ≥ 14pt bold |
| `a11y.contrast.graphical.minRatio` | 3 : 1 | icons, graphical UI |
| `a11y.contrast.criticalSafety.minRatio` | 7 : 1 | allergen warnings, recall alerts |
| `a11y.dynamicType.maxScaler` | 2.0× | xxLarge |
| `a11y.touchTarget.minSize` | 48 × 48 dp Android, 44 × 44 pt iOS | OS guidelines |
| `a11y.touchTarget.recommendedSize` | 56 × 56 dp | Industry recommendation |
| `a11y.focus.outlineWidth` | 3 dp | Visible without intrusive |
| `a11y.focus.outlineColor` | `primary.500` | Brand-consistent focus ring |
| `a11y.semantics.live.debounceMs` | 800 | Avoid screen-reader chatter |
| `a11y.boldMode.weightDelta` | +200 (e.g., 400 → 600) | Approx 1.2× perceived stroke |
| `a11y.boldMode.letterSpacingFactor` | 1.05 | Slight spacing for legibility |
| `a11y.scoreCard.passThreshold` | 100% on critical, ≥ 95% on standard | Per-screen gate |

## Per-Screen A11y Scorecard

Each screen produces a row in `docs/a11y/SCORECARDS.md` with:

| Column | What |
|---|---|
| Screen / Phase | Name |
| Semantics labels | % interactive elements with label (target 100%) |
| Touch targets ≥ 48dp | % (target 100%) |
| Contrast ≥ 4.5:1 | pass/fail per text style |
| Focus order | reviewed: yes/no |
| Dynamic type xxLarge | renders without clip: yes/no |
| Reduced motion | tested: yes/no |
| High contrast | tested: yes/no |
| TalkBack walkthrough | recorded: yes/no |
| VoiceOver walkthrough | recorded: yes/no |
| Critical safety contrast 7:1 | pass/fail (only screens with allergen/recall) |
| Score | 0–100 |

| Screen / Phase | Critical safety surface? |
|---|---|
| Splash FE-09 | — |
| Onboarding cards FE-10 | — |
| OTP entry FE-11 | — |
| OTP verify FE-12 | — |
| Premium subscribe FE-13 | — |
| Family invite FE-14 | — |
| Allergen setup FE-15 | ✓ (chip semantics) |
| Business activation FE-16 | — |
| Scanner FE-17 | — |
| Scan output FE-18 | ✓ (allergen warning) |
| Product detail FE-19 | ✓ (allergen warning, ingredient list) |
| Expiry calendar FE-20 | ✓ (red ≤ 7 days) |
| Recall inbox FE-21 | ✓ (recall reason) |
| Ingredient explainer FE-22 | — |
| Healthy alternatives FE-23 | — |
| Shopping list FE-24 | — |
| Business dashboard FE-25 | — |
| OHS detail FE-26 | — |
| Bulk scan FE-27 | — |
| Expiry tracker biz FE-28 | ✓ (≤ 30 days) |
| GRN wizard FE-29 | — |
| Inventory FE-30 | — |
| Tasks FE-31 | — |
| Reports FE-32 | — |
| Settings — Sync Queue | — |
| Settings — Language Switcher | — |
| Settings — A11y | — |

## Critical Flow Walkthrough Scripts (8 flows)

Each script is recorded as a screen-recording + transcript and committed to `docs/a11y/SCRIPTS.md`.

1. **Sign up** — first launch → segment select → OTP → home (TalkBack + VoiceOver).
2. **Scan a product** — open scanner → capture → hear verdict → save (TalkBack + VoiceOver).
3. **Add an allergen profile** — settings → allergens → add member → select chips → save.
4. **Open a recall alert from push** — tap notification → recall detail → acknowledge.
5. **Subscribe to Premium** — paywall → choose plan → UPI mandate consent → confirmation.
6. **Bulk scan an aisle (business)** — start session → scan 10 → review → submit.
7. **Run an audit report** — reports → run new → completion → export.
8. **Switch language** — settings → language → pick Tamil → confirm voice prompts in Tamil.

Each flow tested in 6 languages × 2 platforms = 96 walkthroughs. Pass condition: each can be completed end-to-end without sighted assistance.

## Backend Integration

| Backend | Role |
|---|---|
| **BE-29 analytics** | Emits `a11y_mode_active` on app start with `{reducedMotion, highContrast, bold, screenReader, textScaler}`. Used to size the a11y user base. |
| **BE-48 observability** | A semantic-label-missing assertion in debug builds emits a Sentry warning with the widget tree. Catches regressions without crashing release builds. |
| **BE-47 feature flags** | `a11y.bold_mode.enabled` and `a11y.high_contrast.enabled` flags allow ops to disable RADHA-specific modes if they regress in production. |

## Accessibility & Platform Variants

### Android specifics
- TalkBack: every screen begins with a `liveRegion` heading announcement on mount.
- TalkBack two-finger swipe to scroll honoured (default Flutter behaviour, but verified).
- Switch Access: every interactive widget reachable in linear order (no nested traps).
- Brightness HardwareAccelerated views (e.g., camera scanner) provide a `Semantics` description ("Camera viewfinder, scan a barcode") since the camera surface itself isn't readable.
- Android 14 grammatical inflection respected when locale is Hindi/Tamil/Telugu/Bengali/Marathi.

### iOS specifics
- VoiceOver: rotor groups configured per screen — Headings, Buttons, Form Fields rotor entries work.
- VoiceOver "Speak Screen" gesture works on Product Detail (FE-19) — the entire ingredient list reads sequentially.
- iOS Voice Control: every button has a unique speakable label.
- iOS Dynamic Type via UIContentSizeCategory respected up to AccessibilityXXXL.

### Tablet
- Focus order reviewed at master-detail layouts (Sync Queue tablet, Reports tablet).

### Low-end / older devices
- TalkBack on Android API 23 verified; older Android Switch Access tested on a Pixel 4a 7.0 emulator (lowest supported).
- VoiceOver on iOS 13 verified.

## Testing

### Automated tests
- `contrast_test.dart`: scan every text style × every theme variant × light/dark; assert ≥ 4.5:1 (or ≥ 7:1 on critical-safety surfaces). Generates a CSV report committed in CI.
- `semantics_test.dart`: walks every screen; asserts every Tappable widget has a non-empty Semantics label.
- `dynamic_type_overflow_test.dart`: pumps each screen at `MediaQuery(textScaler: TextScaler.linear(2.0))`; asserts no `RenderFlex overflow` errors.
- `touch_target_test.dart`: walks every screen; asserts every Tappable has a hit-test rect ≥ 48 × 48 dp.
- `focus_order_test.dart`: per-screen `FocusOrder` declarations checked.
- `accessibility_scanner_test.dart`: Google's Flutter `accessibility_tools` runs on every screen in CI.

### Golden tests
- High contrast mode goldens for 8 representative screens × light/dark = 16 frames.
- Bold mode goldens for 8 representative screens × light/dark = 16 frames.
- xxLarge dynamic type goldens for 8 representative screens = 8 frames.

### Integration tests
- `a11y_walkthrough_test.dart`: scripted TalkBack-style traversal of the 8 critical flows. Uses `tester.semantics` to traverse and verify each step.
- `screen_reader_announcement_test.dart`: verifies `liveRegion` announcements fire on key state changes.

### Human testing
- 8 flows × 2 native screen-reader users × 1 day each = 16 person-days of human walkthrough recorded.
- A blind tester validates the scanner flow (FE-17 → FE-18) end-to-end. Pass condition: completion in < 90 seconds without sighted help.

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Every interactive widget has a Semantics label (automated `semantics_test.dart` pass) |
| T2 | Every text style passes 4.5:1 contrast in light + dark themes (automated `contrast_test.dart` pass) |
| T3 | Allergen warning + recall alert text passes 7:1 contrast (critical safety) |
| T4 | All 25 screens render without overflow at `textScaler: 2.0` |
| T5 | All touch targets ≥ 48 dp (Android) / 44 pt (iOS) — automated assertion |
| T6 | Reduced motion on: 100% of animations replaced or shortened per FE-33 |
| T7 | High contrast on: theme swaps to high-contrast tokens; goldens unchanged on `--update-goldens` re-run after fix |
| T8 | RADHA Bold mode: typography weight + letter spacing applied across 8 representative screens |
| T9 | TalkBack walkthrough of "Scan a product" completes end-to-end in < 90 seconds with no skipped or unreachable elements |
| T10 | VoiceOver walkthrough of same flow on iOS in < 90 seconds |
| T11 | Focus order traversal on every screen matches declared `FocusOrder` |
| T12 | iOS Voice Control: every button reachable by spoken name without ambiguity |
| T13 | Switch Access (Android): linear traversal of every screen in ≤ 1 minute per screen |
| T14 | `a11y_mode_active` analytics event fires with correct snapshot on cold start |
| T15 | Per-screen scorecard committed at ≥ 95% on standard rows, 100% on critical-safety rows |

### Q&A Questions (8)

1. We require 7:1 contrast on critical-safety surfaces. The scan output's "Allergen detected" red runs against a red-tinted card. Do we use white text or blackcard? What's the rule?
2. RADHA Bold mode adds 1.2× stroke. On Indic scripts where stroke is already part of the glyph (Tamil consonant clusters), does the bold mode break legibility?
3. TalkBack and VoiceOver have different conventions for live regions (Android announces every change; iOS announces only one per second). Do we throttle device-side or rely on platform debouncing?
4. The scanner screen shows a live camera. The camera surface is invisible to screen readers. What's our story for a blind user attempting to scan a barcode?
5. The user enables RADHA High Contrast. The system's high-contrast flag is off. What's the conflict resolution?
6. We test `textScaler: 2.0` (200%). iOS Accessibility offers up to ~310%. Why cap at 2.0 — and what's the user's experience above that?
7. Walkthroughs are recorded with one native blind tester per platform per language. What's the bias risk, and how do we counter it?
8. The `a11y_mode_active` event reports modes on cold start only. A user who toggles RADHA High Contrast mid-session is invisible to this metric. Do we ship a second event?

## Sign-off Gate
- [ ] Developer: 15 tests pass; CI a11y suite green.
- [ ] Developer: 8 Q&A answered.
- [ ] Developer: Per-screen scorecard committed at ≥ 95% standard, 100% critical-safety.
- [ ] Reviewer: ran TalkBack walkthrough on 4 critical flows on a real device.
- [ ] Reviewer: ran VoiceOver walkthrough on the same 4 flows on iPhone.
- [ ] Designer: high-contrast and bold mode goldens approved.
- [ ] Accessibility reviewer (external if available): final sign-off; produced an audit memo committed at `docs/a11y/AUDIT_<date>.md`.
- [ ] Native blind testers: signed off on the scanner flow + scan-output flow.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-38 — DO NOT PROCEED WITHOUT APPROVAL**
