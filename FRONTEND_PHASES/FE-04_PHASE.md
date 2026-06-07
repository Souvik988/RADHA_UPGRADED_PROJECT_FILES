# Phase FE-04: Motion System

## Phase Metadata
- **Phase ID**: FE-04
- **Section**: Layer 1 — Foundation
- **Depends On**: FE-02 (motion tokens), FE-03 (components)
- **Blocks**: FE-05 (route transitions), FE-09+ (every screen-level phase uses these primitives)
- **Estimated Duration**: 3-4 days
- **Complexity**: High

## Goal
Define the global motion choreography rules for RADHA: entrance, exit, shared element (Hero), parallax, stagger, list-item-reveal, scroll-driven, and gesture-driven motion. Encapsulate them as reusable widgets and `flutter_animate` chains so every screen author composes motion instead of inventing it. Hard rule: every motion path must hit 60fps on Pixel 4a (3rd-gen mid-range Android) and iPhone SE 2nd gen, and must collapse cleanly when the user has reduced motion enabled.

This phase ships zero user-visible features. It ships a vocabulary. The vocabulary lives in `lib/design_system/motion/` and a demo screen that puts every motion primitive next to its name.

## Why This Phase Matters
- **Premium feel is mostly motion.** The same widget tree feels cheap with abrupt cuts and feels expensive with thoughtful transitions. The same dev cost.
- **One canonical Hero pattern** keeps shared-element transitions consistent across Scanner → Scan Output → Product Detail (FE-17/18/19) — the highest-traffic flow in the app.
- **Stagger + parallax** turn a list of cards into a moment, a hero image into a story. Cheap when systematized, expensive when bespoke.
- **Reduced motion respect** is non-negotiable for accessibility (WCAG 2.3.3) and for our older-user segment (parents using allergen profiles).
- **60fps gate**: skipped frames during onboarding are correlated with day-1 churn. We measure here, not later.

## Prerequisites
- [ ] Backend: none.
- [ ] Earlier FE: FE-02, FE-03.
- [ ] Lottie pack: `assets/lottie/scan_pulse.json` (40 KB), `assets/lottie/success_check.json` (60 KB), `assets/lottie/recall_alert.json` (80 KB), `assets/lottie/empty_calendar.json` (50 KB), `assets/lottie/confetti_premium.json` (90 KB). Total Lottie budget for FE-04 demo: ≤ 320 KB.
- [ ] Performance harness: a Pixel 4a (real device) and an iPhone SE 2 (real device) on the build machine, OR two emulators with throttled CPU.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/design_system/motion/radha_motion.dart` | Re-exports tokens, primitives |
| `apps/mobile/lib/design_system/motion/entrances.dart` | `FadeInUp`, `ScaleFadeIn`, `SlideInFromBottom` etc. |
| `apps/mobile/lib/design_system/motion/exits.dart` | Mirror set |
| `apps/mobile/lib/design_system/motion/hero/radha_hero.dart` | Wrapper around `Hero` with consistent flightShuttleBuilder |
| `apps/mobile/lib/design_system/motion/parallax/parallax_image.dart` | Scroll-driven parallax wrapper |
| `apps/mobile/lib/design_system/motion/stagger/staggered_list.dart` | List items reveal with delay-per-index |
| `apps/mobile/lib/design_system/motion/scroll/scroll_reveal.dart` | Reveals on first viewport entry |
| `apps/mobile/lib/design_system/motion/gesture/swipe_to_dismiss.dart` | Spring-physics swipe |
| `apps/mobile/lib/design_system/motion/lottie/radha_lottie.dart` | Wrapper: handles reduced-motion fallback |
| `apps/mobile/lib/design_system/motion/reduced_motion_provider.dart` | Riverpod provider for `MediaQuery.disableAnimations` |
| `apps/mobile/lib/design_system/motion/perf/frame_callback_logger.dart` | Dev-only: logs frame budget violations to console |
| `apps/mobile/lib/design_system/showcase/motion_gallery.dart` | Internal demo screen |
| `apps/mobile/test/design_system/motion/*_test.dart` | Widget + integration tests |
| `apps/mobile/test/integration/motion_perf_test.dart` | Frame-budget integration test |

## Motion Primitives

### Entrances

```dart
class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;       // default RadhaMotion.normal
  final Duration delay;          // default Duration.zero
  final double fromOffsetY;      // default 16
  final Curve curve;             // default RadhaMotion.expressiveOut
  final bool useReducedMotion;   // default true (auto-degrades)

  @override
  Widget build(BuildContext context) {
    final reduce = ReducedMotion.of(context);
    if (reduce && useReducedMotion) return child; // no animation
    return child
      .animate(delay: delay)
      .fadeIn(duration: duration, curve: curve)
      .slideY(begin: fromOffsetY / 100, end: 0, duration: duration, curve: curve);
  }
}
```

Other entrances: `ScaleFadeIn` (0.94 → 1.0 + opacity), `SlideInFromBottom`, `SlideInFromRight` (route-transition friendly), `RevealFromCenter` (clip path).

### Exits

Mirror of entrances. `FadeOutDown`, `ScaleFadeOut`. Used when a card is dismissed or a sheet closes via custom path.

### RadhaHero

```dart
class RadhaHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final HeroFlightShuttleBuilder? customShuttle;
  // RADHA hero rule: shuttle interpolates corner radius (square → r3 → r4)
  // and fades a subtle drop-shadow during flight.
}
```

Canonical use: scanner thumbnail → product detail full image. Tag format: `'product:$ean:image'`. Shuttle preserves a 1:1 aspect ratio across the flight.

Hero policy:
- Never share Hero between siblings on the same route (Flutter throws).
- Tags must be **EAN-scoped** for products, **UUID-scoped** for tasks/reports.
- Flight duration: 320 ms `motion.slow` on push; 240 ms on pop (asymmetric — feels right).

### Parallax

```dart
class ParallaxImage extends StatelessWidget {
  final ScrollController controller;
  final ImageProvider image;
  final double parallaxFactor; // 0.3 default; 1.0 == native scroll, 0 == fixed
  final double height;
}
```

Uses `Transform.translate` with `controller.offset * parallaxFactor`. Tested at 60fps on a 16:9 1080×608 image.

### Stagger

```dart
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;       // default 0
  final Duration perItemDelay;    // default 60ms
  final int maxStaggerCount;      // cap stagger to first N items (default 8) so a 200-item list doesn't take 12 seconds
  final Curve curve;
}
```

Items beyond `maxStaggerCount` fade in instantly. Prevents the "infinite reveal" anti-pattern.

### Scroll-reveal

```dart
class ScrollReveal extends StatefulWidget {
  // Uses VisibilityDetector. Triggers FadeInUp the first time
  // the widget enters viewport. Stays visible thereafter.
}
```

### Gesture: swipe-to-dismiss

Spring physics on release. Not Flutter's default `Dismissible` — that uses tween. Ours uses `SpringSimulation(mass: 1, stiffness: 200, damping: 22)`. Frame-rate independent.

### Lottie wrapper

```dart
class RadhaLottie extends StatelessWidget {
  final String assetPath;
  final bool repeat;
  final double? width;
  final double? height;
  final ImageProvider? reducedMotionFallback; // shown if reduced motion
  final VoidCallback? onComplete;
}
```

If reduced motion is on, `RadhaLottie` shows a static frame (or `reducedMotionFallback`). Frame count and JSON size logged in dev mode to surface bloat.

## Choreography Rules (the canonical document)

These are the rules every later phase obeys. They live in `docs/motion_rules.md` and are referenced by FE-NN docs.

| Rule | Definition |
|---|---|
| **R1: Direction has meaning** | Entrances come from the direction the content "lives." Sheet enters from bottom. Detail from right. Toast from top of bottom-zone. Never random direction. |
| **R2: Asymmetric durations** | Push transitions are slower than pop (320 ms vs 240 ms). Reveals are slower than dismissals. Feels lighter. |
| **R3: One Hero at a time** | A route transition has at most one Hero. Multiple Heroes across the same flight cause z-fighting on Android. |
| **R4: Stagger is for first 8** | Beyond 8 list items, stop staggering. Cap protects long lists. |
| **R5: Curves are tokens** | Never `Curves.easeIn` inline. Always `RadhaMotion.easeOut` etc. |
| **R6: Motion respects reduced-motion** | Every primitive auto-disables; we never show a tween that ignores `MediaQuery.disableAnimations`. |
| **R7: 60fps or revert** | If a transition can't hit 60fps on Pixel 4a, simplify or remove. No "looks great on iPhone 15 Pro" excuses. |
| **R8: Lottie is for emotion, not utility** | Lottie for celebrate / empty-state / error-page. Never for a generic spinner if a Material progress will do. |
| **R9: Gesture beats button** | Where a swipe and a button compete (close sheet, dismiss snackbar), gesture wins. |
| **R10: No motion exceeds 800 ms** | Anything longer feels broken. Confetti is the only exception, capped at 1.6 s. |

## Visual Behaviour — Motion Gallery Demo Screen

The screen showcases every primitive next to its name. States:

| State | Visual |
|---|---|
| **Default load** | Top: title "Motion System". Below: list of 14 cards, one per primitive (`FadeInUp`, `ScaleFadeIn`, Hero, parallax image, staggered list, scroll-reveal, swipe-to-dismiss, scan_pulse Lottie, success Lottie, recall Lottie, parallax-only, stagger-cap demo, route-from-right demo, route-from-bottom demo). |
| **Tap a card** | Triggers that primitive in isolation, replays it. Shows the source code in a bottom sheet with a "Copy" button. |
| **Hero demo tap** | Pushes a route showing the same image at 1.0×; flight is 320 ms; back gesture pops in 240 ms. |
| **Stagger-cap demo tap** | Renders 30 items; first 8 stagger, remaining 22 instant. Toggle the cap to see the difference. |
| **Reduced motion toggle (top-right)** | Switch flips the provider. All animations on the screen become instant. Lottie freezes at frame 0. Same screen, same tap, no motion. |
| **60fps overlay (top-left)** | Shows current frame budget while a primitive plays. Red flash if a frame > 16.6 ms. |
| **Long-press primitive card** | Logs the primitive's spec (duration, curve, file size if Lottie) to console. |
| **Empty state (no Lottie loaded)** | If a Lottie asset fails to load, primitive card shows static fallback + "Lottie missing" warning. |

## Animations (used inside this phase)

- **Card entrance** (each primitive card): `FadeInUp` with stagger 60 ms × index. Cap 8.
- **Tap-to-replay**: card reverses (300 ms `motion.expressive`), then primitive plays.
- **Source-code sheet**: 320 ms `motion.slow` slide-up, 24 dp radius top.
- **Lottie demos**: each runs once (`repeat: false`) with `onComplete` triggering a small confetti for `success_check.json`.

Total motion budget for this screen: ≤ 1.5 s aggregated entrance, < 320 KB Lottie payload.

## Accessibility
- `Semantics(label: 'Demo of <primitive name>, tap to replay')` on every card.
- Reduced-motion toggle is a system-honoured switch — also persists in app settings.
- Lottie animations have `excludeSemantics: true` and a sibling `Semantics(label: '<emotion>, animated')`.
- Frame-budget overlay is dev-only and `excludeSemantics: true`.
- High-contrast theme verified — primitive cards remain legible.

## Testing
- **Unit**: every primitive widget builds with default args without error.
- **Widget**: `FadeInUp` with reduced-motion ON: child rendered at full opacity in frame 1 (no tween).
- **Widget**: `RadhaHero` with mismatched tags between routes: throws controlled exception, no crash.
- **Widget**: `StaggeredList` with `maxStaggerCount: 4` and 10 children: items 0-3 have animation, items 4-9 are instant.
- **Widget**: `RadhaLottie` with reduced-motion ON: composition's animation controller never advances (verify via `controller.value == 0`).
- **Integration (perf)**: on Pixel 4a emulator throttled to 50% CPU, run motion gallery for 30 seconds tapping every primitive twice. Assert frame timeline shows no frame > 16.6 ms in 99% of frames during animation phases. Use `binding.reportData`.
- **Golden**: motion gallery initial frame in light, dark, reduced-motion. 3 baselines.
- **Hero golden**: capture mid-flight frame (50% progress) deterministically — uses `pumpAndSettle` with custom duration. Goldens for push and pop.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Hero z-fighting on Android during predictive back | High on Android 14+ | Use `HeroController` from `MaterialApp.router`, test on Android 14 emulator. Document fallback (no Hero on predictive back) in motion_rules.md. |
| Lottie compositions blocking the UI thread | Medium | Lottie 3.0+ defers parsing to isolate. We pre-parse on app boot for the 5 hot files. |
| `flutter_animate` chain causes rebuild storm | Low | Each chain is wrapped in a single `AnimatedBuilder`; do not nest multiple `.animate()` on same widget. Lint rule guards. |
| Stagger feels "too long" on long lists | Medium | Cap at 8 items, durations from tokens, designer review. |
| Reduced-motion not respected by 3rd-party widgets | Medium | Wrap third-party motion (e.g. `flutter_staggered_animations`) inside our `ReducedMotion.guard()` helper. |
| Frame logger left on in production | Low | Lives behind `kDebugMode` flag; CI test asserts not exposed in release. |
| 60fps target unrealistic on Android Go devices | Out-of-scope for v1 | Targeted: Pixel 4a / iPhone SE 2. Android Go support deferred to a later phase. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `FadeInUp(duration: RadhaMotion.normal, child: Text('hi'))` reaches full opacity at exactly 200 ms ± 1 frame. |
| T2 | With `MediaQuery.disableAnimations: true`, `FadeInUp` renders the child at full opacity in frame 1. |
| T3 | `RadhaHero` push transition completes in 320 ms ± 16 ms; pop in 240 ms ± 16 ms. |
| T4 | `StaggeredList` with 12 children and `maxStaggerCount: 8` — items 0..7 animate, items 8..11 are instant (verified by querying widget opacity at t=0). |
| T5 | `ParallaxImage(parallaxFactor: 0.3)` shifts vertically by 30% of scroll offset; verified on a 1000-px scroll. |
| T6 | `ScrollReveal` does not animate until widget is ≥ 25% visible (using `VisibilityDetector`). |
| T7 | `RadhaLottie` with reduced-motion on: composition controller's `.value` stays at 0 across 3 seconds. |
| T8 | Motion gallery runs for 30 s on Pixel 4a (throttled CPU emulator) — < 1% jank rate (frames > 16.6 ms). |
| T9 | Motion gallery cold-starts to first frame in ≤ 1.5 s. |
| T10 | All 5 Lottie assets total ≤ 320 KB on disk. |
| T11 | All 5 Lottie assets parse without error in `RadhaLottie.preload()` on boot. |
| T12 | Hero with mismatched tags throws an `AssertionError` in debug, logs error in release — does not crash. |
| T13 | `SwipeToDismiss` released at 30% offset returns to origin via spring; released at 70% completes dismissal. |
| T14 | Reduced-motion provider returns true within 100 ms of toggling system setting (verified via `tester.binding.platformDispatcher`). |
| T15 | Lint rule rejects an inline `Curves.easeIn` reference in `lib/features/**` — points reviewer to `RadhaMotion.easeOut`. |

### Q&A Questions (8)

1. Why are push transitions slower than pop transitions? What's the cognitive principle?
2. How does the Hero shuttle interpolate corner radius from square to `r4` — what's the math?
3. Why cap stagger at 8 instead of staggering all items? What if a designer asks for 12?
4. How does `flutter_animate` compare to using raw `AnimatedBuilder` for our use cases? When would you reach for raw?
5. What's the right way to respect predictive back gesture (Android 14) given Hero animations?
6. Why a separate `RadhaLottie` wrapper instead of using `lottie` package directly? What does the wrapper own?
7. How do we keep designers and engineers in sync on motion specs — what's the artifact?
8. What's the recovery story when a Lottie asset fails to load on a low-end device?

## Sign-off Gate
- [ ] Developer: 15 tests pass, motion gallery + 5 Lottie files committed.
- [ ] Developer: 8 Q&A answered in handoff.
- [ ] Developer: `docs/motion_rules.md` ships with R1..R10 documented.
- [ ] Developer: Frame-budget integration test green on CI (Linux emulator).
- [ ] Reviewer: ran motion gallery on Pixel 4a + iPhone SE 2 with reduced-motion on and off.
- [ ] Reviewer: confirmed Lottie payload total ≤ 320 KB.
- [ ] Reviewer: confirmed lint rule blocks inline curves outside `tokens/`.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-05**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-04 — DO NOT PROCEED WITHOUT APPROVAL**
