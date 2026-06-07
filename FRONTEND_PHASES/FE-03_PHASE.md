# Phase FE-03: Component Library Foundation

## Phase Metadata
- **Phase ID**: FE-03
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-02
- **Blocks**: FE-04, every screen-level phase
- **Estimated Duration**: 5-6 days
- **Complexity**: High

## Goal
Build the canonical RADHA component set — buttons, inputs, cards, chips, sheets, dialogs, snackbars, tab bars, app bars — every variant, every size, every state, all wired to the FE-02 tokens. Each component has haptics on the right gesture, motion on the right transition, and a Storybook-equivalent (widgetbook) page so designers, QA, and engineers see every variant in isolation. Every component has a golden baseline.

By the end of this phase, building a new screen in later phases is composition, not invention. A button is `RadhaButton.primary(label: 'Continue', onPressed: ...)` — never `ElevatedButton(style: ButtonStyle(...))`.

## Why This Phase Matters
- **Component reuse is the largest velocity multiplier on this roadmap.** 8 components done well save weeks across the next 32 phases.
- **Premium feel is decided here.** A 200ms button press ripple with light haptic vs a generic Material press is the difference between "felt good" and "felt cheap." This phase locks that in.
- **Widgetbook = continuous design QA**. Designers can review 200+ variants without booting the real app.
- **Goldens prevent regression**. A future PR that subtly changes button padding will fail `flutter test --update-goldens` review.

## Prerequisites
- [ ] Backend: none.
- [ ] Earlier FE: FE-02 (tokens + theme).
- [ ] Design assets: component spec sheet (variants × sizes × states matrix) from designer.
- [ ] Lottie files for inline progress: `assets/lottie/spinner_dots.json` (≤ 10 KB, 1 s loop).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/design_system/components/button/radha_button.dart` | Button widget |
| `apps/mobile/lib/design_system/components/button/radha_icon_button.dart` | Icon button |
| `apps/mobile/lib/design_system/components/button/radha_fab.dart` | Floating action button |
| `apps/mobile/lib/design_system/components/input/radha_text_field.dart` | Text input |
| `apps/mobile/lib/design_system/components/input/radha_otp_field.dart` | 6-digit OTP boxes |
| `apps/mobile/lib/design_system/components/input/radha_search_field.dart` | Search input |
| `apps/mobile/lib/design_system/components/input/radha_picker_field.dart` | Tap-to-pick (date, store, supplier) |
| `apps/mobile/lib/design_system/components/card/radha_card.dart` | elevated/filled/outlined |
| `apps/mobile/lib/design_system/components/chip/radha_chip.dart` | filter, choice, input chips |
| `apps/mobile/lib/design_system/components/sheet/radha_bottom_sheet.dart` | Modal + persistent |
| `apps/mobile/lib/design_system/components/dialog/radha_dialog.dart` | Action / alert / confirm |
| `apps/mobile/lib/design_system/components/snackbar/radha_snackbar.dart` | Info / success / warn / error |
| `apps/mobile/lib/design_system/components/tabs/radha_tab_bar.dart` | M3 tab bar |
| `apps/mobile/lib/design_system/components/app_bar/radha_app_bar.dart` | Standard + large + transparent |
| `apps/mobile/lib/design_system/components/feedback/radha_progress.dart` | Linear + circular + Lottie dots |
| `apps/mobile/lib/design_system/components/feedback/radha_skeleton.dart` | Shimmer skeletons |
| `apps/mobile/lib/design_system/feedback/haptics.dart` | Wrapper around `HapticFeedback` (matches roadmap vocab) |
| `apps/mobile/lib/design_system/feedback/sound.dart` | Optional success/error tones (off by default) |
| `apps/mobile_widgetbook/` (new app target) | Widgetbook root with one page per component |
| `apps/mobile/test/design_system/components/*.dart` | Unit + widget tests for each component |
| `apps/mobile/test/goldens/components/*.png` | Golden baselines |

## Component Catalog (5 button variants × 4 sizes = 20)

```dart
// design_system/components/button/radha_button.dart
enum RadhaButtonVariant {
  primary,    // saffron filled, on white text — high-emphasis CTA
  secondary,  // outlined teal — secondary action
  tertiary,   // text-only saffron — inline action
  destructive,// danger filled — irreversible action
  ghost,      // surface-tinted with no border — bottom-sheet defaults
}

enum RadhaButtonSize {
  xs,  // h: 32, padX: 12, label textXs
  sm,  // h: 40, padX: 16, label textSm
  md,  // h: 48, padX: 20, label textMd  (DEFAULT)
  lg,  // h: 56, padX: 24, label textLg  (paywall, primary CTAs)
}

class RadhaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final RadhaButtonVariant variant;
  final RadhaButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final bool useHaptic;        // default true
  final HapticStrength haptic; // default light

  const RadhaButton.primary({...}) : variant = RadhaButtonVariant.primary;
  const RadhaButton.secondary({...}) : variant = RadhaButtonVariant.secondary;
  // ...
}
```

### Button States (every variant × every size handles all 7)

| State | Visual |
|---|---|
| Default (idle) | Solid fill / outline per variant; 12px radius; e1 elevation for primary, e0 for outlined/ghost |
| Pressed | Scale 0.97, 120 ms `motion.fast`, opacity 0.85, light haptic |
| Hover (foldable / desktop / web preview) | +1 elevation level, surface tint +6% |
| Focused (keyboard) | 2px outline ring, color = `colors.brand`, offset 2px |
| Disabled | Opacity 0.38, no haptic, no ripple |
| Loading (`isLoading=true`) | Lottie 3-dot spinner replaces label, button still has its width (no jump) |
| Success (programmatic) | Quick scale-pulse 1.0 → 1.04 → 1.0 over 240 ms + success haptic |

### Inputs

```dart
class RadhaTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText; // wins over helper
  final IconData? leadingIcon;
  final Widget? trailingAction;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final RadhaInputSize size; // sm/md/lg
}
```

States (every input handles all 8):

1. Empty + unfocused
2. Empty + focused (label floats up via 200 ms `motion.normal`, brand-colored bottom border)
3. Filled + unfocused
4. Filled + focused
5. Error (red border, error text fades in 120 ms, leading icon swaps to alert)
6. Disabled (40% opacity, no border)
7. Loading (right side shows spinner — used for async validation)
8. Success (right side shows green check, 800 ms `motion.celebrate` glow, then fades)

OTP field — 6 boxes, auto-advance, paste handling, autofocus first box, error shake animation (4× 8px translate over 280 ms).

### Cards

```dart
enum RadhaCardVariant { elevated, filled, outlined }

class RadhaCard extends StatelessWidget {
  final Widget child;
  final RadhaCardVariant variant;
  final EdgeInsets padding; // default s4 (16)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadiusGeometry? borderRadius; // defaults to r3
  final String? semanticLabel;
}
```

When `onTap != null`: ripple, light haptic, scale 0.99 on press, 120 ms.

### Chips

3 variants (filter / choice / input), 3 sizes (sm / md / lg). Filter chip has check-mark slide-in (180 ms `motion.fast`, slide from left + opacity).

### Bottom sheets

```dart
class RadhaBottomSheet {
  static Future<T?> show<T>(BuildContext context, {
    required WidgetBuilder builder,
    bool draggable = true,
    List<double> snapPoints = const [0.5, 0.9],
    bool barrierDismissible = true,
    String? title,
  }) { ... }
}
```

Snap behaviour: drag releases use `SpringSimulation` (mass 1, stiffness 200, damping 18) — feels native, never sluggish.

### Dialogs

`RadhaDialog.action()`, `RadhaDialog.alert()`, `RadhaDialog.confirm()`. All open with 200 ms `motion.normal` scale-fade (0.92 → 1.0 + opacity 0 → 1) and dismiss with 160 ms reverse.

### Snackbars

```dart
RadhaSnackbar.show(context,
  message: 'Scan saved',
  variant: RadhaSnackbarVariant.success,
  action: RadhaSnackbarAction(label: 'Undo', onTap: ...),
  duration: Duration(seconds: 4),
);
```

Variants change icon + accent stripe color (success/info/warning/danger). All slide up from bottom with 240 ms `motion.slow`.

### Tab bar / App bar

`RadhaTabBar` extends M3 with: animated underline that follows the active tab via `AnimatedAlign` 200 ms; selection haptic on tap; pages use `PageView` with `physics: const PageScrollPhysics()`.

`RadhaAppBar` has 3 forms: `standard()` (h 56), `large()` (h 96, large title), `transparent()` (no surface, no shadow, used over Hero hero images). Title respects M3 `MediaQuery.platformBrightnessOf` for status-bar icon color.

### Progress + skeleton

`RadhaProgress.linear()` — 4px, brand color, indeterminate gradient.
`RadhaProgress.circular()` — 32 dp, M3-style.
`RadhaProgress.dots()` — Lottie 3-dot loop, 24 dp, used inside buttons.

`RadhaSkeleton.box(w, h, radius)` and `RadhaSkeleton.text(lines, width)` — 1.4 s shimmer loop using `flutter_animate` linear-gradient sweep.

## Widgetbook (component lab)

```dart
// apps/mobile_widgetbook/lib/main.dart
void main() {
  runApp(Widgetbook.material(
    addons: [
      MaterialThemeAddon(themes: [
        WidgetbookTheme(name: 'Light', data: RadhaTheme.light()),
        WidgetbookTheme(name: 'Dark', data: RadhaTheme.dark()),
        WidgetbookTheme(name: 'HC Light', data: RadhaTheme.light(highContrast: true)),
      ]),
      DeviceFrameAddon(devices: [Devices.android.pixel4a, Devices.ios.iPhoneSE]),
      LocalizationAddon(locales: [const Locale('en'), const Locale('hi'), const Locale('ta')]),
      TextScaleAddon(scales: [1.0, 1.4]),
    ],
    directories: [
      WidgetbookFolder(name: 'Buttons', children: _buttonStories),
      WidgetbookFolder(name: 'Inputs', children: _inputStories),
      // ... one folder per component
    ],
  ));
}
```

Story pattern: every variant × every size × every state on its own page. ≥ 200 stories at the end of this phase.

## Visual Behaviour (per-component states summary table)

| Component | States covered | Total stories in widgetbook |
|---|---|---|
| Button | 5 variants × 4 sizes × 7 states | 140 |
| Input | 4 types × 3 sizes × 8 states | 96 |
| Card | 3 variants × {tap, no-tap} × {with-leading, plain} | 12 |
| Chip | 3 types × 3 sizes × {selected, unselected, disabled} | 27 |
| Sheet | {standard, draggable} × {one-snap, two-snap} × {with-title, plain} | 8 |
| Dialog | 3 types × {with-icon, plain} | 6 |
| Snackbar | 4 variants × {with-action, plain} | 8 |
| Tab bar | {2 tabs, 3 tabs, 4 tabs, scrollable} | 4 |
| App bar | 3 forms × {with-actions, plain} | 6 |
| Progress | 3 forms | 3 |
| Skeleton | {box, 1-line text, 3-line text, card} | 4 |

## Haptics + Sound Wrapper

```dart
// design_system/feedback/haptics.dart
enum HapticStrength { tap, light, medium, heavy, success, warning, error }

class RadhaHaptics {
  static Future<void> trigger(HapticStrength s) async {
    if (await _reducedMotion()) return;
    switch (s) {
      case HapticStrength.tap:    return HapticFeedback.selectionClick();
      case HapticStrength.light:  return HapticFeedback.lightImpact();
      case HapticStrength.medium: return HapticFeedback.mediumImpact();
      case HapticStrength.heavy:  return HapticFeedback.heavyImpact();
      case HapticStrength.success: return _pattern([20, 80, 20]);
      case HapticStrength.warning: return _pattern([20, 60, 20, 60]);
      case HapticStrength.error:   return _pattern([60, 60, 60, 60, 60]);
    }
  }
}
```

User can disable haptics globally in settings (`RadhaHaptics.setEnabled(false)`).

## Animations
- **Button press**: 120 ms `motion.fast`, AnimatedScale 1.0 → 0.97 → 1.0 + Material ripple.
- **Input focus**: 200 ms `motion.normal`, AnimatedAlign label, AnimatedContainer underline.
- **Sheet open**: 320 ms `motion.slow`, M3 spec scale + fade backdrop.
- **Sheet drag release**: physics-driven `SpringSimulation`.
- **Snackbar enter**: 240 ms `motion.slow` slide-up + fade.
- **Tab underline**: 200 ms `motion.normal`, `AnimatedAlign` + `AnimatedContainer` width.
- **Skeleton shimmer**: 1.4 s linear-gradient sweep, indefinite.
- **Lottie spinner**: 1 s loop, 3 dots, 24 dp.

Total motion budget on a typical screen using these: ≤ 1.5 s aggregated.

## Accessibility
- Every component supplies `Semantics(button|textField|header|label, ...)`.
- Buttons have minimum 48×48 hit target even when visual size is smaller (transparent inflate).
- Inputs report `hint`, `label`, `value`, `errorText` to assistive tech.
- OTP field announces "OTP digit X of 6, current value Y."
- Sheets and dialogs use `excludeSemantics` on backdrop scrim and trap focus.
- Reduced motion: animations collapse via `RadhaMotion` wrapper; ripples become 0-duration; shimmer becomes static.
- Color is never the only signal — error has icon + bold text + color; success has check + color.

## Testing
- **Per-component widget test**: builds each variant, taps, verifies state changes.
- **Per-component golden test**: at least 4 baselines per component (light/dark + 1.0×/1.4× text scale). ≥ 60 baselines total.
- **Haptic test**: when reduced-motion is on, `RadhaHaptics.trigger` is a no-op (mock platform channel).
- **OTP integration**: typing into box 1 auto-advances to box 2; backspace on empty box jumps back; paste of "123456" fills all six.
- **Sheet drag test**: drag below 50% snap, release, expect closed; drag above, expect 90% snap.
- **Snackbar queue test**: showing two snackbars within 100 ms shows the second after the first dismisses (M3 spec).
- **Widgetbook smoke test**: app launches; first page of every folder renders without exception.
- **Performance test**: 200-story widgetbook scroll holds 60fps on Pixel 4a (`integration_test` with `binding.reportData`).

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Component API drift between phases | High | Lock public API in this phase. Adding fields = new minor; removing = breaking change requires reviewer + roadmap update. |
| Goldens flake on CI (rendering differences) | High | Run goldens only on Linux with a fixed Skia revision; pixel-tolerance 0.01 (`golden_toolkit`). |
| Haptic feels different on iOS vs Android | Inherent | Use platform-specific patterns; document behavior in widgetbook story notes. |
| Widgetbook target ships in main APK | Critical | Separate package, build target, never imported from `lib/`. CI guards. |
| Lottie progress dots too heavy | Low | File ≤ 10 KB, replaced by static if reduced-motion. |
| Sheet drag-release feels "stuck" on slow devices | Medium | Use physics-driven spring (frame-rate independent), tested on a low-end device emulator. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `RadhaButton.primary(label: 'X', onPressed: () {})` renders correctly in all 4 sizes; goldens stable. |
| T2 | Pressing a primary button triggers a light haptic and shrinks scale to 0.97 within 120 ms. |
| T3 | `isLoading: true` swaps label for Lottie dots without changing button width by more than 1 px. |
| T4 | OTP field: typing `1` in box 1 advances focus to box 2; backspace on empty box 2 returns to box 1 with cursor at end. |
| T5 | OTP field paste of `123456` fills all six boxes; calling `onCompleted` fires once with `123456`. |
| T6 | OTP field error: setting `errorText` triggers shake (4 keyframes, 280 ms total). |
| T7 | Text field with `errorText`: leading icon swaps to alert, helper hidden, color flips to danger within 120 ms. |
| T8 | Text field with async validator returning a `Future`: spinner appears in trailing slot for the duration. |
| T9 | `RadhaCard.elevated(onTap: ...)` produces ripple + light haptic on tap. |
| T10 | Bottom sheet drag from snap 0.5 below to 0.4 then release: sheet closes with 320 ms motion. |
| T11 | Bottom sheet drag from 0.5 to 0.7 and release: sheet snaps to 0.9 via spring. |
| T12 | Snackbar with `RadhaSnackbarVariant.danger` shows red stripe, alert icon, error haptic. |
| T13 | Tab bar: tapping tab 3 of 4 animates the underline from tab 1 to tab 3 in a single 200 ms tween. |
| T14 | All 60+ goldens pass with zero diff after a fresh CI run. |
| T15 | Widgetbook scroll across 200 stories on Pixel 4a holds ≥ 58 fps average (DevTools timeline). |

### Q&A Questions (8)

1. Why are buttons named by variant (`primary`, `destructive`) rather than by elevation/style? What happens when design wants a 6th variant?
2. Why does the OTP field shake on error instead of flashing red — and what's the spec for the shake (amplitude, frequency, duration)?
3. How does `RadhaBottomSheet` interact with the system back gesture on Android, especially gesture-nav predictive back (Android 14+)?
4. What is the failure mode when `RadhaHaptics.trigger` is called rapidly (e.g. 30 times/sec on a hot path)? Should the wrapper rate-limit?
5. How does widgetbook stay in sync — do designers ever edit it, or is it strictly engineering?
6. Why a separate `apps/mobile_widgetbook` workspace target vs a debug-mode flag? What's the deployment story?
7. How are component golden tests reviewed when a designer legitimately changes padding by 2 px?
8. What's the upgrade path when M3 spec changes (e.g. M3 Expressive in 2026)? How wide is the blast radius?

## Sign-off Gate
- [ ] Developer: 15 tests pass, ≥ 60 golden baselines committed.
- [ ] Developer: 200+ widgetbook stories render without exception.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Reviewer: walked through widgetbook on Pixel 4a + iPhone SE 2 in light + dark + dynamic + 1.4× text.
- [ ] Reviewer: confirmed haptic feels right on real iOS + real Android device.
- [ ] Reviewer: confirmed widgetbook target excluded from main APK build.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-04**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-03 — DO NOT PROCEED WITHOUT APPROVAL**
