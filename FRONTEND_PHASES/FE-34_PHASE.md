# Phase FE-34: Micro-Interactions Library

## Phase Metadata
- **Phase ID**: FE-34
- **Phase Name**: Micro-Interactions Library
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: FE-02 (tokens), FE-03 (component foundation), FE-04 (motion bootstrap), FE-33 (motion registry — durations + curves)
- **Blocks**: FE-37 (skeleton loaders consume `ShimmerSkeleton`), FE-38 (a11y audits the haptic story), FE-39 (perf budget asserts no micro-interaction drops a frame)
- **Estimated Duration**: 4-5 days
- **Complexity**: High — every interactive widget in the app changes

## Goal
Replace every "raw" interactive widget — `InkWell`, `GestureDetector`, `Switch`, `Slider`, `RefreshIndicator`, `CircularProgressIndicator`, `Dismissible`, `TextField` — with a RADHA-branded equivalent that pairs **visual feedback** + **haptic feedback** + **timing** in a single reusable component.

By the end of this phase a user can tell a "good" tap from a "missed" tap without looking at the screen, because every meaningful interaction emits one of seven haptic levels at the precise frame the visual responds. Specifically:

- 12 reusable interactive widgets (`PressableCard`, `AnimatedToggle`, `RadhaSlider`, `RadhaTextField`, `ShimmerSkeleton`, `RadhaPullToRefresh`, `SwipeAction`, `ConfettiBurst`, `RippleHotspot`, `LongPressMenuButton`, `SuccessCheckMark`, `FormFieldStatusBadge`).
- One canonical `Haptics` wrapper exposing `tap / light / medium / heavy / success / warning / error` with platform-specific patterns.
- Form-validation feedback choreography codified: 80ms shake on invalid, 120ms green check on valid, inline error message slide-in.
- Pull-to-refresh and swipe-action gestures own their own haptic curves (drag arm, threshold cross, release).
- Loading states served by `ShimmerSkeleton` — never by `CircularProgressIndicator` in primary surfaces.

This phase ships ~1500 lines of Dart and changes ~40 call sites across FE-09..FE-32. It is small in surface, large in feel.

## Why This Phase Matters
- **The "missed tap" problem** is the single largest source of user frustration in mobile apps. A tap that produces no haptic and no immediate visual change is read by the brain as "didn't register" within 100ms. We pair every tap with one of three response signals (ripple + scale + haptic) that fire at < 60ms.
- **Haptics are a brand**. Stripe/Razorpay/Apple Pay all have signature haptic patterns. RADHA needs one. Scan capture must feel different from save, save must feel different from delete, delete must feel different from "you can't do that on Free tier."
- **Form errors are a retention killer**. A user who fails the OTP screen twice often abandons. A 80ms shake + red glow + haptic.error tells them "I noticed, try again" before the error toast even renders, which lifts retry rate by 12-18% in industry data.
- **Skeletons over spinners**. Industry research (Lukew, NN Group) shows skeletons reduce perceived load time by 40% versus spinners. The shimmer animation must match the post-load layout exactly — no layout jump on data arrival.
- **App Store / Play Store featured apps**. Apple's Today section and Google Play's Editor's Choice both score "delight" heavily. This phase is the single most direct contribution to that score.
- **Accessibility intersect**: every haptic must have a TalkBack/VoiceOver semantic announcement equivalent — a deaf-blind user gets the same "tap registered" signal via screen-reader pulse.

## Prerequisites
- [ ] FE-33 motion tokens locked. This phase imports them everywhere.
- [ ] FE-03 component library exists (we extend it; we don't bypass it).
- [ ] Designer-supplied `interactions.fig` Figma file with 12 reference videos (slow-motion 4× speed) — one per widget.
- [ ] Lottie pack from FE-33 (`successCheck`, `errorCross`, `confettiBurst` files).
- [ ] Audio pack `radha_audio_pack_v1.zip` containing 3 optional sound effects (scan-success, save-tick, recall-alert) — disabled by default; opt-in via Settings → Sounds.
- [ ] Hardware test fleet: Pixel 4a, Pixel 7, iPhone SE 2, iPhone 14, OnePlus Nord (mid-range).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/interactions/haptics.dart` | Canonical haptic wrapper — 7 named levels + platform routing |
| `apps/mobile/lib/interactions/sounds.dart` | Audio wrapper, opt-in only |
| `apps/mobile/lib/interactions/pressable_card.dart` | Replaces every `InkWell`-on-`Card` pattern |
| `apps/mobile/lib/interactions/animated_toggle.dart` | Replaces every `Switch` |
| `apps/mobile/lib/interactions/radha_slider.dart` | Slider with detent haptics |
| `apps/mobile/lib/interactions/radha_text_field.dart` | Text field with valid/invalid choreography |
| `apps/mobile/lib/interactions/shimmer_skeleton.dart` | Reusable skeleton primitive |
| `apps/mobile/lib/interactions/radha_pull_to_refresh.dart` | Custom indicator with elastic + haptic stages |
| `apps/mobile/lib/interactions/swipe_action.dart` | List swipe (delete/archive) with two-stage feedback |
| `apps/mobile/lib/interactions/confetti_burst.dart` | One-shot success celebration |
| `apps/mobile/lib/interactions/ripple_hotspot.dart` | Touch-targeted ripple with origin point |
| `apps/mobile/lib/interactions/long_press_menu_button.dart` | Long-press context menu pattern |
| `apps/mobile/lib/interactions/success_check_mark.dart` | Lottie-backed `successCheck` widget |
| `apps/mobile/lib/interactions/form_field_status_badge.dart` | Inline ✓ / ✗ / 🔒 trailing icon for forms |
| `apps/mobile/lib/interactions/interaction_audit.dart` | Debug overlay listing every interaction fired |
| `apps/mobile/test/interactions/*_test.dart` | One test file per widget (12) |
| `apps/mobile/test/interactions/golden/*.png` | One golden per state per widget |
| `apps/mobile/integration_test/interactions_haptic_smoke_test.dart` | Smoke test that exercises every widget once |

## Implementation Spec

### `haptics.dart`
```dart
enum HapticLevel { tap, light, medium, heavy, success, warning, error }

class Haptics {
  static final _provider = HapticsProvider.platform();
  static bool _enabled = true;            // toggled in Settings
  static const Duration _minGap = Duration(milliseconds: 60);
  static DateTime _lastFire = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> fire(HapticLevel level) async {
    if (!_enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastFire) < _minGap) return; // debounce
    _lastFire = now;
    await _provider.fire(level);
  }

  // Composable patterns (e.g., scan-capture = light + success after 80ms)
  static Future<void> scanCapture() async {
    await fire(HapticLevel.light);
    await Future.delayed(const Duration(milliseconds: 80));
    await fire(HapticLevel.success);
  }
}
```

| Level | iOS pattern | Android pattern | When |
|---|---|---|---|
| `tap` | `selectionClick` | `EFFECT_TICK` | tab/chip toggle, checkbox |
| `light` | `lightImpact` | `EFFECT_CLICK` | button press, card tap |
| `medium` | `mediumImpact` | `EFFECT_HEAVY_CLICK` (downscaled) | sheet snap, scan capture front |
| `heavy` | `heavyImpact` | `EFFECT_DOUBLE_CLICK` | recall alert, expiry critical |
| `success` | UINotificationFeedback.success | 2-tap pattern (50/30/50) | scan verified, OTP success, save complete |
| `warning` | UINotificationFeedback.warning | 1-long pulse (180ms) | allergen flag, near-quota |
| `error` | UINotificationFeedback.error | 3-tap pattern (50/40/50/40/50) | OTP wrong, network fail, quota exceeded |

### `pressable_card.dart`
```dart
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HapticLevel hapticOnPress;    // default: light
  final HapticLevel? hapticOnLongPress;
  final double pressedScale;          // default: 0.97
  final Duration pressDuration;       // default: tokens.fast (120ms)
  final Curve pressCurve;             // default: tokens.curve.standardOut
  final bool   showRipple;            // default: true
  final bool   disabled;
  // States: idle, pressed, focused (keyboard), disabled.
  // Trigger: onTapDown → scale 0.97 + haptic.light (immediate, < 60ms)
  // Release: onTapUp → scale 1.0 + onTap callback at the end
  // Cancel: onTapCancel → scale 1.0, no callback, no haptic.
}
```

### `radha_text_field.dart` validation choreography
```dart
// State transitions:
// idle      → focus    : 200ms border color animate, label moves up
// focus     → valid    : 120ms green border + Lottie successCheck (0.2x scale, 200ms)
// focus     → invalid  : 80ms shake (translate ±6dp 4 cycles) + red border + haptic.error
//                        + inline error message slide-down (200ms, standard curve)
// invalid   → editing  : red border fades to neutral over 200ms
// disabled  : 50% opacity, no haptics, no animations
```

### `shimmer_skeleton.dart`
```dart
class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final ShimmerStyle style;          // .text | .card | .avatar | .image
  // Linear gradient sweep, 1400ms loop, easeInOut
  // Colors: surface.container.lowest → surface.container.high → surface.container.lowest
  // Reduced motion: replaces shimmer with static surface tint, no animation
  // Convention: skeleton dimensions MUST match the loaded widget's intrinsic size
  //             (asserts when tested with --debug-paint-sizes)
}
```

## Patterns / Reusable Widgets

### Full widget catalog
| Widget | Trigger event | Visual response | Duration | Curve | Haptic | Sound (opt-in) |
|---|---|---|---|---|---|---|
| `PressableCard` | tap-down | scale 1.0 → 0.97, ripple from touch point | 120ms | swiftOut | light | — |
| `PressableCard` | tap-up | scale 0.97 → 1.0 | 120ms | standard | — | — |
| `PressableCard` | long-press (500ms) | scale 0.95 + soft glow | 200ms | standard | medium | — |
| `AnimatedToggle` | tap | thumb slide + track color crossfade | 200ms | expressive | tap | — |
| `RadhaSlider` | drag start | thumb scale 1.0 → 1.2 | 120ms | standard | light | — |
| `RadhaSlider` | drag step (per detent) | — | — | — | tap | — |
| `RadhaSlider` | drag release | thumb scale 1.2 → 1.0 + bounce | 200ms | celebrate | medium | — |
| `RadhaTextField` | focus | border 1dp → 2dp + label rise | 200ms | standard | tap | — |
| `RadhaTextField` | invalid | shake ±6dp ×4 + red border | 80ms | standard | error | — |
| `RadhaTextField` | valid | green check Lottie + border green | 200ms | celebrate | success | — |
| `ShimmerSkeleton` | mount | shimmer sweep loop | 1400ms loop | easeInOut | — | — |
| `RadhaPullToRefresh` | drag arm (50% threshold) | indicator stretch | follows finger | linear | — | — |
| `RadhaPullToRefresh` | threshold cross | indicator snap + haptic | 80ms | standard | medium | — |
| `RadhaPullToRefresh` | release & refresh | Lottie loader spin | until network | — | — | — |
| `RadhaPullToRefresh` | refresh complete | check + collapse | 320ms | celebrate | success | save-tick |
| `SwipeAction` | drag past 25% | reveal action + color tint | follows finger | linear | tap (once) | — |
| `SwipeAction` | drag past 70% | full-bleed action color + commit-on-release | follows finger | linear | medium | — |
| `SwipeAction` | release commit | slide off-screen + remove | 200ms | swiftOut | success/error per action | — |
| `ConfettiBurst` | imperative trigger | particle physics 0.8s | 800ms | celebrate | success | — |
| `RippleHotspot` | tap | radial ink expand from origin | 200ms | linear | tap | — |
| `LongPressMenuButton` | long-press | scale + menu fly out | 200ms | expressive | medium | — |
| `SuccessCheckMark` | imperative trigger | Lottie 0 → 1 | 480ms | expressive | success | — |
| `FormFieldStatusBadge` | state change | crossfade between icons | 200ms | standard | none | — |

### Composite patterns

| Pattern | Composition |
|---|---|
| **Scan capture** | `Haptics.scanCapture()` (light + 80ms + success) + `SuccessCheckMark` overlay + scan-success sound (opt-in) |
| **Save to list** | `PressableCard` press + `SuccessCheckMark` mini (24dp) + haptic.success |
| **Quota exceeded** | Shake 80ms + `Haptics.fire(error)` + upgrade-prompt sheet |
| **Allergen detected** | `ConfettiBurst.warning` (red particles) + haptic.warning + Lottie warningPulse on the offending ingredient row |
| **OTP wrong** | 6-box wiggle + red glow + haptic.error |
| **OTP correct** | Each box flips green sequentially (stagger.tight) + haptic.success on the final box |

## Configuration / Tokens

| Token | Value | Why |
|---|---|---|
| `interactions.press.scale` | 0.97 | Below 0.95 looks broken, above 0.98 is invisible |
| `interactions.press.duration` | 120ms | Aligns with FE-33 `motion.duration.fast` |
| `interactions.press.curve` | `swiftOut` | Snappy enter, no overshoot |
| `interactions.haptic.minGap` | 60ms | Below this, haptics blur into a buzz on Android |
| `interactions.shake.amplitude` | 6dp | Visible without disorienting |
| `interactions.shake.cycles` | 4 | Three feels intentional; five feels broken |
| `interactions.shake.duration` | 80ms | Total — fast enough to feel like correction, slow enough to register |
| `interactions.shimmer.duration` | 1400ms | Industry standard; matches Facebook/LinkedIn |
| `interactions.shimmer.gradientWidth` | 30% of viewport | Sweep size that reads as "loading" not "broken animation" |
| `interactions.swipe.armThreshold` | 25% of row width | First haptic fires here |
| `interactions.swipe.commitThreshold` | 70% of row width | Releasing past this commits the action |
| `interactions.confetti.particleCount` | 24 | Enough for joy, few enough for 60fps |
| `interactions.confetti.duration` | 800ms | `motion.duration.celebrate` |
| `interactions.refresh.armDistance` | 64dp | Industry standard |
| `interactions.refresh.maxOverscroll` | 96dp | Caps elastic stretch |
| `interactions.target.tapResponseMs` | 60 | Visual response must start within this window of `onTapDown` |
| `interactions.target.tapTotalMs` | 200 | onTap callback fires by this time at the latest |

## Per-Screen Application Checklist

| Screen / Phase | `PressableCard` | `RadhaTextField` | `AnimatedToggle` | `ShimmerSkeleton` | `PullToRefresh` | `SwipeAction` | `ConfettiBurst` | Custom haptic |
|---|---|---|---|---|---|---|---|---|
| Onboarding cards FE-10 | ✓ (6 cards) | — | — | — | — | — | — | tap on select |
| OTP entry FE-11 | — | ✓ phone | — | — | — | — | — | — |
| OTP verify FE-12 | — | ✓ 6-box | — | — | — | — | — | success on final box |
| Premium subscribe FE-13 | ✓ plan cards | — | ✓ auto-renew | — | — | — | ✓ on success | — |
| Family invite FE-14 | ✓ member tile | ✓ phone | — | ✓ list | ✓ | ✓ remove | — | — |
| Allergen setup FE-15 | ✓ allergen chip | — | — | — | — | — | — | tap on chip toggle |
| Business activation FE-16 | ✓ steps | ✓ business name | — | — | — | — | — | — |
| Scanner FE-17 | — | — | — | — | — | — | — | scan-capture composite |
| Scan output FE-18 | ✓ save action | — | — | ✓ while loading | — | — | ✓ on save | warning if allergen |
| Product detail FE-19 | ✓ ingredient row | — | — | ✓ ingredients | — | — | — | — |
| Expiry calendar FE-20 | ✓ day cell | — | — | ✓ month grid | ✓ | ✓ mark consumed | — | warning if <7d |
| Recall inbox FE-21 | ✓ row | — | — | ✓ list | ✓ | ✓ acknowledge | — | heavy on open |
| Ingredient explainer FE-22 | — | — | — | ✓ stream warm | — | — | — | — |
| Healthy alternatives FE-23 | ✓ alt card | — | — | ✓ carousel | — | — | — | — |
| Shopping list FE-24 | ✓ item row | ✓ add | — | ✓ list | ✓ | ✓ tick/delete | — | tap on tick |
| Business dashboard FE-25 | ✓ KPI card | — | — | ✓ everywhere | ✓ | — | — | — |
| OHS detail FE-26 | ✓ component | — | — | ✓ trends | — | — | — | — |
| Bulk scan FE-27 | — | — | — | — | — | ✓ remove last | — | scan-capture composite |
| Expiry tracker biz FE-28 | ✓ row | — | — | ✓ list | ✓ | ✓ mark | — | — |
| GRN wizard FE-29 | ✓ supplier tile | ✓ qty | — | — | — | ✓ remove line | — | — |
| Inventory FE-30 | ✓ row | ✓ qty | — | ✓ list | ✓ | ✓ adjust | — | — |
| Tasks FE-31 | ✓ row | — | ✓ complete | ✓ list | ✓ | ✓ snooze | ✓ on done | success on complete |
| Reports FE-32 | ✓ row | — | — | ✓ list | ✓ | — | — | — |

## Backend Integration

| Backend tie | What it changes |
|---|---|
| **BE-46 rate limit** | When a quota-exceeded 429 lands, the offending widget shakes 80ms + haptic.error + the upgrade-prompt sheet from FE-37 opens. The widget itself never knows the HTTP status — it consumes a `QuotaExceededException` from the Riverpod stream. |
| **BE-44 sync** | `RadhaPullToRefresh` triggers a sync flush (FE-36) before the network refresh. The Lottie loader holds while sync is in flight; when sync completes the loader transitions to a check + haptic.success. If sync errors, the loader transitions to errorCross + haptic.error and the FE-36 sync-error banner pins. |
| **BE-29 analytics** | Each widget emits a low-volume analytics event on use: `interaction_fired` with `{widget, screen, hapticLevel}`. Sampled at 5% to avoid noise. |
| **BE-47 feature flags** | Two flags: `interactions.haptics_enabled` (kill-switch for haptics globally) and `interactions.sounds_default_on` (controls default for new installs). |

## Accessibility & Platform Variants

### TalkBack / VoiceOver mapping
- Every haptic level has a paired `SemanticsService.announce` if the user has TalkBack enabled. `success` announces "Saved." `error` announces the actual error message. `warning` announces "Warning."
- A `PressableCard` exposes `Semantics(button: true, label: …, onTap: …)` so the screen reader can both describe and activate.
- Form-field shake animation is suppressed when TalkBack is on (it confuses focus tracking); the error message slide is also delivered as a `liveRegion` announcement.

### Reduced-motion
- Press scale: kept at 0.97 (it's < 100ms — too fast to disorient).
- Shake animation: replaced by a 200ms red-border crossfade.
- ConfettiBurst: replaced by a static `successCheck` Lottie.
- Shimmer: replaced by a static surface tint, no animation.
- All haptics still fire (haptic ≠ motion).

### Sound
- All sounds are off by default. Settings → Notifications → Sounds toggle turns on the 3 packs.
- Sound files are 22kHz mono ≤ 12 KB each. Total pack size ≤ 36 KB.
- Sounds duck under accessibility services (TalkBack, VoiceOver) so they never collide with screen reader speech.

### Android specifics
- Haptic patterns use `VibrationEffect.createWaveform` (API 26+) for `success/warning/error`. On API 25 and below we fall back to a single 50ms vibration; the visual response remains identical.
- Material You ripples kept on `PressableCard`'s ripple layer — we additively layer our scale + ripple.

### iOS specifics
- iOS 13+: full UIImpactFeedbackGenerator + UINotificationFeedbackGenerator. Below: fall back to `HapticFeedback.lightImpact()` only.
- Avoid haptics during scroll deceleration to honour Apple HIG.

### Tablet
- All scale animations use the same value; tablets feel slightly less responsive at 0.97. Designer review at FE-33 confirmed leaving as-is rather than introducing a tablet-only token.

### Low-end devices
- `MotionProfile.lowEndAuto` from FE-33 cascades here: shake amplitude drops 6dp → 4dp; press scale 0.97 → 0.98; shimmer animation pauses when off-screen.

## Testing

### Widget tests (one per widget — 12 files)
- Press scale animates 1.0 → 0.97 → 1.0 within 120 + 120 ms.
- Tap-cancel returns to 1.0 without firing onTap.
- Toggle thumb position matches state in 200ms.
- Slider step haptics fire exactly once per detent crossed.
- TextField shake produces 4 cycles in 80ms.
- TextField valid state shows successCheck Lottie.
- Shimmer dimension asserts equal post-load widget dimension (no layout jump).
- PullToRefresh fires medium haptic at exactly 64dp drag.
- SwipeAction fires tap haptic at 25%, medium at 70%.
- ConfettiBurst spawns 24 particles, animation completes in 800ms.

### Golden tests
- One golden per widget per state (idle / pressed / focused / valid / invalid / disabled / loading) — 60+ goldens.
- Light + dark + reduced-motion variants — 3× multiplier — 180+ goldens total.

### A11y audit per widget
- TalkBack pass: confirm announce-on-trigger.
- VoiceOver pass: confirm semantic labels.
- Dynamic-type xxLarge: widget bounds expand without clipping.
- Focus order: keyboard-only navigation lands on each widget once.

### Perf benchmarks
- DevTools timeline: a screen with 30 `PressableCard` instances scrolls at 60fps on Pixel 4a.
- Cold-start delta from this phase: ≤ 80ms.
- APK size delta: ≤ 220 KB (mostly Lotties).

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `PressableCard` `onTapDown` to first visual frame ≤ 60ms (DevTools trace, Pixel 4a) |
| T2 | `PressableCard` `onTap` callback fires by 200ms total |
| T3 | `Haptics.fire(error)` two consecutive calls within 60ms emit only one haptic (debounce) |
| T4 | `RadhaTextField` invalid → valid transition completes in ≤ 200ms; haptic fires once |
| T5 | `ShimmerSkeleton` dimensions match the post-load widget intrinsic size to ≤ 2dp tolerance (no layout jump) |
| T6 | `RadhaPullToRefresh` arming haptic fires at 64dp ± 4dp, not before |
| T7 | `SwipeAction` 25% threshold haptic fires once per pass; not on each frame |
| T8 | `ConfettiBurst` runs at 60fps on Pixel 4a (DevTools timeline shows zero dropped frames) |
| T9 | TalkBack on: `PressableCard` tap announces label and emits `success` haptic without secondary speech collision |
| T10 | Reduced-motion on: shake replaced by 200ms red crossfade; verified by widget test polling animation controller status |
| T11 | All 12 widgets render correctly at dynamic-type xxLarge (golden) |
| T12 | Sound pack turned off (default): no audio events emitted across a 60-second smoke run |
| T13 | Quota-exceeded composite: 429 → shake + haptic.error + upgrade prompt opens — full chain in ≤ 400ms |
| T14 | Custom lint flags any `InkWell` outside `lib/interactions/`, `lib/components/` |
| T15 | Custom lint flags any `HapticFeedback.*` call outside `lib/interactions/haptics.dart` |

### Q&A Questions (8)

1. Why a 60ms haptic debounce — what happens above and below this window on iOS vs Android?
2. The `RadhaTextField` shake is 80ms, the press scale is 120ms. If a user taps "Next" on a form with one invalid field, both fire — in what order, and does the user perceive a collision?
3. How does `ShimmerSkeleton` know what dimensions to use without the post-load data? (Hint: skeleton library + per-screen explicit sizing — explain trade-off.)
4. Sounds are opt-in. What's the discoverability story — how does a user even know they exist?
5. `ConfettiBurst` particle count is 24. What's the rationale, and what fps drop occurs at 100 particles on Pixel 4a?
6. How does this phase coordinate with FE-37 empty/error/skeleton states — specifically, who owns the screen-level skeleton orchestration?
7. The custom lint forbids `InkWell` outside our library. How do we handle 3rd-party widgets (e.g., a `DataTable`) that ship `InkWell` internally?
8. `HapticLevel.heavy` on Android API 25 is just a 50ms vibration. Is the user experience materially worse, and if so what's the migration plan when API 25 share drops below 1%?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 95% on `lib/interactions/**`; custom lint live in CI.
- [ ] Developer: 8 Q&A answered.
- [ ] Developer: every per-screen migration row complete (table above).
- [ ] Reviewer: ran every widget on a real device with haptics on and off.
- [ ] Reviewer: verified no `InkWell` / `HapticFeedback.*` call sites remain outside the library.
- [ ] Designer: every micro-interaction matches the `interactions.fig` reference video to ≤ 30ms timing tolerance.
- [ ] Accessibility reviewer: TalkBack and VoiceOver pass on every widget.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-34 — DO NOT PROCEED WITHOUT APPROVAL**
