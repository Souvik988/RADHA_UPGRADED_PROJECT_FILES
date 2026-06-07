# Phase FE-33: Animation Library + Hero Choreography

## Phase Metadata
- **Phase ID**: FE-33
- **Phase Name**: Animation Library + Hero Choreography
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: FE-02 (design tokens), FE-03 (component library), FE-04 (motion system bootstrap), FE-05 (GoRouter), every Layer 2/3/4 phase that ships a screen
- **Blocks**: FE-34 (micro-interactions inherit `MotionTokens`), FE-37 (skeleton loaders use the same curve table), FE-38 (reduced-motion gate consumed everywhere), FE-39 (perf budget enforced against this library)
- **Estimated Duration**: 3-4 days
- **Complexity**: High — every screen in the app changes its `import` statements

## Goal
Replace the ad-hoc `Duration(milliseconds: 220)` and `Curves.easeInOut` literals scattered across FE-09..FE-32 with a single canonical `MotionTokens` registry and a Hero choreography rulebook that every route, sheet and list reveals through. By the end of this phase:

- Every animation duration in the codebase is one of seven `MotionTokens.duration.*` values.
- Every animation curve is one of nine `MotionTokens.curve.*` Beziers.
- Every Hero transition uses one of five named tag families (`hero.product`, `hero.member`, `hero.task`, `hero.recall`, `hero.report`) with a documented "max one Hero per route transition" rule.
- Every page route is wrapped by one of four `RadhaPageTransition` types (`fade`, `sharedAxisX`, `sharedAxisY`, `containerTransform`) chosen by route metadata, not screen-by-screen.
- Reduced-motion mode (system flag, accessibility setting, or low-end device profile) replaces all transitions with 120ms fades — no exceptions.
- 200ms target entrance animation on Snapdragon 4xx-class devices verified by trace.

The output is a registry, not a feature. It is consumed everywhere. Every prior phase doc that wrote `Curves.easeOutCubic` now imports `MotionTokens.curve.swiftOut`.

## Why This Phase Matters
- **Cohesion test**: Users never explicitly notice consistent motion, but they instantly notice inconsistent motion. A 240ms slide here, a 280ms fade there — the brain reads it as "amateur." Locking the values is the difference between "feels like an app" and "feels like one app."
- **Hero choreography is the platform's single most powerful retention tool**. A product card on the scan screen that "becomes" the product detail header (FE-19) earns 3-5% deeper sessions because the user's spatial model never breaks. Every Material Design Award winner runs Heroes well.
- **Reduced-motion is non-negotiable for App Store / Play Store accessibility review.** Apple has rejected apps in 2024-2025 for ignoring "Reduce Motion." Centralizing the gate now means every future widget inherits compliance.
- **Performance gating per device class**: low-end Snapdragon 4xx and Mediatek Helio devices simply cannot run our 480ms expressive curves at 60fps. The library auto-downgrades to 120ms fades on those devices using the heuristic from FE-39.
- **Pre-flight for Material Design Award submission**: the jury reviews motion as a category. A central registry, well-named, with curves traceable to design intent, scores measurably higher than scattered constants.

## Prerequisites
- [ ] FE-02 design tokens shipped (`RadhaColors`, `RadhaTypography`, `RadhaSpacing` already importable).
- [ ] FE-04 motion system bootstrap shipped (`MotionTokens` already exists with `motion.normal/fast/slow`; this phase **expands** and **enforces** it).
- [ ] FE-05 GoRouter routes have a `meta` map (so we can attach a `transition` key without changing route names).
- [ ] All FE-09..FE-32 screens merged. This phase is the first one that touches them all simultaneously — running it before they exist would be wasted work.
- [ ] Designer-supplied curve table (handed off as a Figma node `motion/curves.fig` and a CSV with t-values for every named Bezier).
- [ ] Lottie pack `radha_motion_pack_v1.zip` containing 14 reusable Lotties (loaders, success, error, empty illustrations).
- [ ] Performance budget from FE-39 published as `motion_budget.yaml` in the repo (this phase reads it but doesn't define it).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/motion/motion_tokens.dart` | The registry — durations, curves, named springs |
| `apps/mobile/lib/motion/motion_profile.dart` | `MotionProfile` enum — `full`, `reduced`, `lowEndAuto` |
| `apps/mobile/lib/motion/motion_provider.dart` | Riverpod provider that resolves the active profile per device + system flag |
| `apps/mobile/lib/motion/hero_tags.dart` | Centralized Hero tag factory — type-safe tag constructors |
| `apps/mobile/lib/motion/hero_flight_shuttles.dart` | Custom `flightShuttleBuilder` per tag family |
| `apps/mobile/lib/motion/page_transitions.dart` | `RadhaPageTransition` sealed class + 4 implementations |
| `apps/mobile/lib/motion/page_transition_resolver.dart` | Maps GoRouter route meta to a `RadhaPageTransition` |
| `apps/mobile/lib/motion/list_reveal.dart` | `RadhaListReveal` widget — staggered list-item entrance |
| `apps/mobile/lib/motion/animation_extensions.dart` | `extension MotionContext on BuildContext` — `context.motion` shorthand |
| `apps/mobile/lib/motion/lottie_registry.dart` | Type-safe references to the 14 Lotties (no string literals at call sites) |
| `apps/mobile/lib/motion/motion_diagnostics.dart` | Debug overlay (debug builds only) showing every running animation's name + duration |
| `apps/mobile/test/motion/motion_tokens_test.dart` | Token immutability + budget guards |
| `apps/mobile/test/motion/page_transitions_golden_test.dart` | Golden frames at t=0/50/100/200ms |
| `apps/mobile/test/motion/hero_choreography_test.dart` | Hero-from-A-to-B integration test |
| `apps/mobile/test/motion/reduced_motion_test.dart` | Reduced-motion mode swaps every animation with fade |

## Implementation Spec

### `motion_tokens.dart`
```dart
@immutable
class MotionTokens {
  const MotionTokens._();

  // ─── Durations ─────────────────────────────────────────────
  static const Map<String, Duration> duration = {
    'instant':    Duration.zero,
    'micro':      Duration(milliseconds: 80),   // ripple, chip toggle
    'fast':       Duration(milliseconds: 120),  // press feedback, hover
    'normal':     Duration(milliseconds: 200),  // sheets, dialogs, default
    'slow':       Duration(milliseconds: 320),  // route transitions
    'expressive': Duration(milliseconds: 480),  // Heroes, big reveals
    'celebrate':  Duration(milliseconds: 800),  // success, confetti
  };

  // ─── Curves ────────────────────────────────────────────────
  // Names match Material 3 motion taxonomy + a few RADHA-specific.
  static const Map<String, Curve> curve = {
    'standard':    Cubic(0.20, 0.00, 0.00, 1.00),  // default emphasized
    'standardIn':  Cubic(0.30, 0.00, 0.80, 0.15),  // entering
    'standardOut': Cubic(0.20, 0.00, 0.00, 1.00),  // exiting
    'emphasized':  Cubic(0.20, 0.00, 0.00, 1.00),  // attention-grabbing
    'swiftIn':     Cubic(0.40, 0.00, 1.00, 1.00),  // quick entrance
    'swiftOut':    Cubic(0.00, 0.00, 0.00, 1.00),  // quick exit
    'expressive':  Cubic(0.16, 1.00, 0.30, 1.00),  // Heroes (RADHA signature)
    'celebrate':   Cubic(0.34, 1.56, 0.64, 1.00),  // overshoot for success
    'linear':      Curves.linear,                   // progress bars only
  };

  // ─── Springs (for SpringSimulation) ─────────────────────────
  static const Map<String, SpringDescription> spring = {
    'gentle':   SpringDescription(mass: 1, stiffness: 150, damping: 18),
    'snappy':   SpringDescription(mass: 1, stiffness: 280, damping: 22),
    'bouncy':   SpringDescription(mass: 1, stiffness: 200, damping: 12),
  };

  // ─── Stagger schedules ──────────────────────────────────────
  static const Map<String, Duration> staggerStep = {
    'tight':  Duration(milliseconds: 28),
    'normal': Duration(milliseconds: 48),
    'loose':  Duration(milliseconds: 80),
  };

  // ─── Reduced-motion fallback (single source of truth) ───────
  static const Duration reducedDuration = Duration(milliseconds: 120);
  static const Curve   reducedCurve   = Curves.linear;
}
```

### `motion_profile.dart`
```dart
enum MotionProfile { full, reduced, lowEndAuto }

extension MotionProfileX on MotionProfile {
  Duration resolve(String tokenKey) =>
    this == MotionProfile.full
      ? MotionTokens.duration[tokenKey] ?? MotionTokens.duration['normal']!
      : MotionTokens.reducedDuration;

  Curve resolveCurve(String tokenKey) =>
    this == MotionProfile.full
      ? MotionTokens.curve[tokenKey] ?? MotionTokens.curve['standard']!
      : MotionTokens.reducedCurve;
}
```

### `hero_tags.dart`
```dart
abstract class RadhaHero {
  // Five tag families. Adding a sixth requires architecture review.
  static String product(String ean)   => 'hero.product.$ean';
  static String member(String userId) => 'hero.member.$userId';
  static String task(String taskId)   => 'hero.task.$taskId';
  static String recall(String recallId) => 'hero.recall.$recallId';
  static String report(String reportId) => 'hero.report.$reportId';
}
```

> **Rule**: maximum **one** Hero per route transition. A screen with five product cards Heroes only the *tapped* card to the destination — never the surrounding chrome. Verified by `hero_choreography_test.dart` failing if more than one Hero crosses a transition.

### `page_transitions.dart`
```dart
sealed class RadhaPageTransition {
  const RadhaPageTransition();

  Page<T> buildPage<T>({required Widget child, required GoRouterState state});

  static const fade               = _FadePageTransition();
  static const sharedAxisX        = _SharedAxisXPageTransition();
  static const sharedAxisY        = _SharedAxisYPageTransition();
  static const containerTransform = _ContainerTransformPageTransition();
}
```

| Variant | Duration | Curve | When |
|---|---|---|---|
| `fade` | 200ms | `standard` | Tab switch, modal-style routes, reduced-motion default |
| `sharedAxisX` | 320ms | `expressive` | Sibling-level navigation (next product, prev day) |
| `sharedAxisY` | 320ms | `expressive` | Going deeper / coming back (list → detail) |
| `containerTransform` | 480ms | `expressive` | Card → full screen (the Hero-equivalent for routes without a single shared element) |

### List reveal pattern
```dart
class RadhaListReveal extends StatelessWidget {
  final List<Widget> children;
  final String stagger;     // 'tight' | 'normal' | 'loose'
  final Duration delay;     // optional global delay before first item
  final Axis axis;          // Axis.vertical default
  // Each child fades in (200ms standard) and slides 16dp in `axis` direction.
  // Stagger step per index from MotionTokens.staggerStep[stagger].
  // Reduced-motion: drops slide, halves duration, no stagger.
}
```

## Patterns / Reusable Widgets

| Widget / Helper | API surface | Used by |
|---|---|---|
| `MotionTokens` | static `duration`, `curve`, `spring`, `staggerStep` maps | every screen, every `AnimatedX` widget |
| `MotionProfile` enum + `motionProfileProvider` | resolves to `full` / `reduced` / `lowEndAuto` per device | top-level `RadhaApp` |
| `context.motion.duration('normal')` | extension shorthand | every widget call site |
| `RadhaHero.product/member/task/recall/report` | tag factories | scan, scan-output, product-detail, recall list/detail, tasks list/detail, reports |
| `RadhaPageTransition.{fade,sharedAxisX,sharedAxisY,containerTransform}` | sealed transition variants | GoRouter `pageBuilder` for every route |
| `pageTransitionResolver(GoRouterState)` | reads route meta `transition` key, returns variant | central GoRouter config |
| `RadhaListReveal` | staggered list entrance | every list/grid screen (FE-20 calendar, FE-21 recalls, FE-31 tasks, FE-32 reports) |
| `LottieRegistry.loaderDots`, `.successCheck`, `.errorCross` (14 entries) | type-safe Lottie refs | every loading/success/error path |
| `MotionDiagnostics` overlay | debug-only HUD listing active animations | engineering, perf reviews |

## Configuration / Tokens

| Token | Value | Justification |
|---|---|---|
| `motion.duration.micro` | 80ms | Material 3 ripple guideline |
| `motion.duration.fast` | 120ms | Press feedback floor — anything under feels instant |
| `motion.duration.normal` | 200ms | Sheet open — user perception sweet spot for "modal appears" |
| `motion.duration.slow` | 320ms | Route transition ceiling on phones; iPad bumps to 380ms |
| `motion.duration.expressive` | 480ms | Hero ceiling — beyond this users tap-tap because they think it didn't register |
| `motion.duration.celebrate` | 800ms | Confetti/success — long enough to feel earned, short enough to dismiss |
| `motion.duration.reduced` | 120ms | Single fallback for every reduced-motion swap |
| `motion.curve.standard` | `Cubic(.2, 0, 0, 1)` | Material 3 emphasized |
| `motion.curve.swiftOut` | `Cubic(0, 0, 0, 1)` | Material 3 quick exit |
| `motion.curve.expressive` | `Cubic(.16, 1, .3, 1)` | RADHA signature — anticipation + settle |
| `motion.curve.celebrate` | `Cubic(.34, 1.56, .64, 1)` | Overshoot 1.06× for success states |
| `motion.staggerStep.tight` | 28ms | 8-row dense lists |
| `motion.staggerStep.normal` | 48ms | 4-6 item card grids |
| `motion.staggerStep.loose` | 80ms | Hero galleries, onboarding cards |
| `motion.heroes.maxPerRoute` | 1 | Hard rule — checked by integration test |
| `motion.lowEndAuto.deviceMemoryMbCutoff` | 2048 | Below this, force `MotionProfile.reduced` |
| `motion.lowEndAuto.refreshHzMin` | 60 | Below this, force `MotionProfile.reduced` |
| `motion.target.entrance.lowEndMs` | 200 | Trace-verified on Pixel 4a |

## Per-Screen Application Checklist

Every shipped screen migrates from literal durations to tokens. Track in PR.

| Screen / Phase | Hero usage | Page transition variant | Stagger token | List reveal | Migration status |
|---|---|---|---|---|---|
| Splash (FE-09) | none | fade | n/a | no | ☐ |
| Onboarding cards (FE-10) | none | fade | loose | yes | ☐ |
| OTP entry (FE-11) | none | sharedAxisX | n/a | no | ☐ |
| OTP verify (FE-12) | none | sharedAxisX | n/a | no | ☐ |
| Premium subscribe (FE-13) | none | sharedAxisY | n/a | no | ☐ |
| Family invite (FE-14) | `hero.member` | sharedAxisY | normal | yes | ☐ |
| Allergen setup (FE-15) | none | sharedAxisY | normal | yes | ☐ |
| Business activation (FE-16) | none | sharedAxisX | n/a | no | ☐ |
| Scanner (FE-17) | none | fade | n/a | no | ☐ |
| Scan output card (FE-18) | `hero.product` ↗ FE-19 | sharedAxisY | n/a | no | ☐ |
| Product detail (FE-19) | `hero.product` ↘ FE-18 | containerTransform | tight | yes (ingredients) | ☐ |
| Expiry calendar (FE-20) | none | sharedAxisY | normal | yes (per day) | ☐ |
| Recall inbox (FE-21) | `hero.recall` | sharedAxisY | normal | yes | ☐ |
| Ingredient explainer (FE-22) | none | sharedAxisY | n/a | no (sheet) | ☐ |
| Healthy alternatives (FE-23) | `hero.product` | containerTransform | normal | yes | ☐ |
| Shopping list (FE-24) | none | sharedAxisY | tight | yes | ☐ |
| Business dashboard (FE-25) | none | fade | normal | yes (cards) | ☐ |
| OHS detail (FE-26) | none | sharedAxisY | tight | yes | ☐ |
| Bulk scan (FE-27) | none | fade | n/a | no | ☐ |
| Expiry tracker biz (FE-28) | none | sharedAxisY | tight | yes | ☐ |
| GRN wizard (FE-29) | none | sharedAxisX (steps) | n/a | no | ☐ |
| Inventory (FE-30) | none | sharedAxisY | tight | yes | ☐ |
| Tasks (FE-31) | `hero.task` | sharedAxisY | normal | yes | ☐ |
| Reports (FE-32) | `hero.report` | sharedAxisY | normal | yes | ☐ |

A PR that adds a screen without filling this row is rejected by review.

## Backend Integration
This phase has **no direct backend dependency** — it is a client-only registry. Indirect ties:

- **BE-47 feature flags**: a kill-switch flag `motion.expressive_curves_enabled` allows ops to demote the entire app to reduced-motion in case of a cross-device perf regression in production. The flag is read at app boot and re-read every 5 minutes (per BE-47 contract). Toggle propagation < 5 minutes.
- **BE-48 observability**: every Hero transition over the 480ms expressive budget on a non-low-end device emits a `motion_overrun` Sentry breadcrumb (sampled 1%) with the route name and measured duration. This catches regressions where a phase author accidentally adds a 700ms tween.
- **BE-29 analytics**: emits one event `motion_profile_resolved` on cold start with `{profile, deviceTier, refreshHz, reducedMotionFlag}`. Used to size the Reduced-Motion population for design decisions.

## Accessibility & Platform Variants

### Reduced-motion (system flag)
- Read once at app boot via `MediaQuery.disableAnimationsOf(context)` plus `Platform.isIOS ? UIAccessibility.isReduceMotionEnabled : Settings.System.ANIMATOR_DURATION_SCALE == 0`.
- When `true`, `motionProfileProvider` returns `MotionProfile.reduced` regardless of device class.
- Every `AnimatedX` widget reads from `context.motion`, so the swap is automatic. No widget needs `if (reducedMotion)` branches.
- Hero transitions degrade to a 120ms cross-fade between source and destination — the spatial connection is lost, but the visual handoff still tells the user "you went somewhere."
- `RadhaListReveal` drops the slide and stagger; all items fade together.

### Low-end auto-downgrade (`MotionProfile.lowEndAuto`)
- Triggers when device memory < 2 GB **or** display refresh < 60 Hz **or** Android API < 26 **or** iOS device older than iPhone 8.
- Same outcome as `reduced` for everything **except** Hero transitions, which keep their motion (Heroes are critical to spatial understanding) but drop their curve to `swiftOut` and duration to 200ms.
- Verified on the test fleet: Redmi Go (1 GB), Nokia C20 (2 GB), iPhone 8.

### Android specifics
- Edge-to-edge route transitions respect the system gesture insets — `RadhaPageTransition` uses `SafeArea` internally so back-gesture predictive transitions (Android 14+) layer correctly.
- Predictive back gesture: containerTransform variants opt in via `PopScope` + `onPopInvoked` to scrub the transition with the user's finger.

### iOS specifics
- iOS swipe-to-go-back interactive pop: `sharedAxisX` variants implement `CupertinoPageTransitionsBuilder` fallback so the rubber-band gesture from the left edge feels native.
- Dynamic Island / notch: Hero flight paths clip against the safe area via `flightShuttleBuilder` overrides.

### Tablet
- Page transitions over 600dp width: durations bump 1.2× (320 → 380ms slow, 480 → 560ms expressive). Codified in `MotionProfile.tablet` (a future flag — registered now, off by default).

## Testing

### Widget tests
- `motion_tokens_test.dart`: tokens are immutable; map keys are exhaustive against the `MotionToken` enum; no duration exceeds 800ms.
- `motion_profile_test.dart`: profile resolver returns `reduced` when `MediaQuery.disableAnimations == true`; `lowEndAuto` when device-memory probe returns < 2 GB.
- `page_transitions_test.dart`: each variant builds a `Page` with the documented duration and curve.
- `list_reveal_test.dart`: 10-child reveal with `normal` stagger completes at `200 + 9*48 = 632ms`.

### Golden tests
- One golden per page-transition variant at t=0, 100, 200, 320 ms — 16 frames total — under both light and dark themes.
- One golden per Hero family at flight midpoint — 5 frames.
- Reduced-motion variant of every above golden — 21 more frames.

### Integration tests
- `hero_choreography_test.dart`: navigate scan → product detail; assert exactly one Hero crosses; assert flight duration within ±20ms of `expressive`.
- `reduced_motion_test.dart`: enable `MediaQueryData.disableAnimations`, replay 10 navigations, assert each completes in ≤ 130 ms.
- `low_end_simulation_test.dart`: set fake `deviceMemoryMb=1024`; assert profile resolves to `lowEndAuto`; assert non-Hero animations use `reducedDuration`.

### Perf benchmarks
- Trace 5 cold cold-starts on Pixel 4a (release build). 95th-percentile entrance animation duration must be ≤ 200ms with `MotionProfile.lowEndAuto`.
- DevTools timeline: zero dropped frames during a Hero between scan output and product detail on Pixel 4a.
- APK size delta from this phase: ≤ 80 KB (registry is data, not assets; Lotties already counted in FE-04).

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `MotionTokens.duration.values` contains exactly 7 entries — all between 0 and 800ms |
| T2 | `MotionTokens.curve.values` contains exactly 9 entries — every curve is a `Cubic` or `Curves.linear` |
| T3 | Static analyzer rule (custom lint) flags any `Duration(milliseconds: …)` literal in `lib/features/**` outside `motion/` |
| T4 | Static analyzer rule flags any direct use of `Curves.easeInOut*` in `lib/features/**` outside `motion/` |
| T5 | GoRouter is configured so every route resolves to one of the 4 `RadhaPageTransition` variants — boot fails if any route omits the meta key |
| T6 | Hero integration: tap product card on FE-18 → product detail FE-19; assert flight duration within ±20ms of 480ms; assert exactly 1 Hero |
| T7 | Hero rule: a screen with two declared `RadhaHero.product` tags throws assertion in debug mode |
| T8 | Reduced-motion enabled at OS level: replay 20 navigations, assert each ≤ 130ms total |
| T9 | Low-end auto-downgrade: simulate 1 GB device, assert `motionProfileProvider` returns `lowEndAuto` |
| T10 | Pixel 4a release build: cold start to first frame ≤ 1.5s; first interaction-to-Hero-complete ≤ 200ms |
| T11 | iPhone SE 2 release build: same budget as T10 |
| T12 | DevTools jank trace during Hero transition shows zero dropped frames over 3 consecutive runs |
| T13 | `RadhaListReveal` with 50 items completes in ≤ 200 + 49×28 = 1572ms (`tight` stagger) — and aborts new entries if user scrolls past them (no off-screen animation work) |
| T14 | BE-47 feature flag `motion.expressive_curves_enabled=false` flips entire app to reduced-motion within 5 minutes of toggle |
| T15 | Sentry breadcrumb `motion_overrun` fires when a synthetic 700ms Hero is forced in a debug build, and **does not** fire on a normal 480ms Hero (verified by sampled assertion) |

### Q&A Questions (8)

1. Why exactly seven duration tokens and not five or twelve? What was rejected and why?
2. How do we enforce the "max 1 Hero per route transition" rule across a team of 4 engineers shipping different screens — code review checklist, lint, runtime assertion, all three?
3. When a screen has both an outgoing slide transition (route push) and an incoming list reveal, in what order do they execute and how do we prevent visual collision?
4. How does this phase interact with the iOS predictive-back gesture and Android 14 predictive-back? Specifically, does `containerTransform` reverse cleanly under user finger control?
5. The Lottie registry holds references to 14 files totalling ~1.8 MB. Is that lazy-loaded or bundled? What's the cold-start impact?
6. If a designer hands us a 9th curve, what's the change-control process — token-only PR, design review, both?
7. How does `MotionProfile.lowEndAuto` decide a device is low-end? What's the false-positive rate and how do we let users override?
8. What's the rollback procedure if `motion.expressive_curves_enabled=false` is flipped accidentally in production — does the app downgrade silently or surface a banner?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage on `lib/motion/**` ≥ 95%; custom lint enforced in CI.
- [ ] Developer: 8 Q&A answered in the handoff doc.
- [ ] Developer: every screen owner has merged their migration PR (per the table above).
- [ ] Reviewer: spot-checked 5 random screens — no `Duration(milliseconds:` or `Curves.easeIn*` literals remain.
- [ ] Reviewer: reduced-motion experience reviewed end-to-end on a real device with system flag on.
- [ ] Designer (motion review): every curve and duration matches Figma `motion/curves.fig`; any deviations explained.
- [ ] Accessibility reviewer: confirmed reduced-motion + low-end-auto behaviour on Redmi Go and iPhone 8.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-33 — DO NOT PROCEED WITHOUT APPROVAL**
