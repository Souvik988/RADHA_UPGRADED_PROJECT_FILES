# Phase FE-09: Splash Screen + Branded Boot

## Phase Metadata
- **Phase ID**: FE-09
- **Phase Name**: Splash Screen + Branded Boot
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-01 (project init), FE-02 (design tokens), FE-03 (component library), FE-04 (motion system), FE-05 (navigation/GoRouter), FE-06 (API client/Dio), FE-07 (Riverpod state), FE-08 (Drift local DB)
- **Blocks**: FE-10 (Onboarding Hero), FE-12 (OTP Login)
- **Estimated Duration**: 1.5 days
- **Complexity**: Medium

## Goal
Deliver the very first 2.4 seconds of the RADHA experience: a branded boot sequence that simultaneously (a) renders a Lottie animated wordmark with parallax background, (b) warms up the most expensive Riverpod providers (auth, design tokens, feature flags, locale, Drift connection), and (c) decides the next route based on auth state. The screen must feel intentional, not waiting — every millisecond is choreographed.

The splash is also a brand impression. It is the only moment we have a captive user before they make their first interaction decision, so the visuals must reinforce the RADHA identity (warm scan-green to deep-saffron color wash) and the typography hierarchy that carries through every subsequent screen.

## Why This Phase Matters
- **Cold-start abandonment**: Industry data shows ~12% of users drop off if a cold start exceeds 3.0s and ~22% if it exceeds 4.0s. A 2.4s budget puts RADHA inside the "feels instant" band and lifts D1 retention by 3-5 percentage points.
- **Funnel stability**: The boot is the gate to every subsequent funnel (segment selection → activation → first scan). Any flake here multiplies through the funnel.
- **Trust signal**: A polished splash on a free retail app signals "this is built like a Razorpay/PhonePe app" and primes the user to trust scan results later.
- **Conversion lift**: A warm provider cache shaved off the splash hands the next screen sub-100ms first paint, which the segment-selection cards (FE-10) need to stagger cleanly.

## Prerequisites
- [ ] Backend: `GET /api/v1/auth/session` (BE-06 v2) returns auth state + `bypassedOnboarding` flag
- [ ] Backend: `GET /api/v1/feature-flags` (BE-50) returns boot-time flag bundle
- [ ] FE-01..FE-08 foundation phases merged and green
- [ ] Lottie file `splash_wordmark.json` (Adobe AE export, ≤120 KB, 32fps)
- [ ] Lottie file `splash_loop_idle.json` (loop fallback for slow boots, ≤40 KB)
- [ ] Asset `splash_parallax_bg_far.png` (1080×1920, ≤180 KB)
- [ ] Asset `splash_parallax_bg_near.png` (1080×1920 with alpha, ≤220 KB)
- [ ] Color tokens: `radha.scanGreen.500`, `radha.saffron.500`, `radha.ink.900`

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/splash/splash_screen.dart` | Stateful root widget; orchestrates Lottie + parallax + boot pipeline |
| `apps/mobile/lib/features/splash/splash_controller.dart` | Riverpod `AsyncNotifier<SplashState>` driving boot pipeline |
| `apps/mobile/lib/features/splash/splash_state.dart` | Sealed `SplashState` (booting / ready / error / cooldown) |
| `apps/mobile/lib/features/splash/widgets/parallax_bg.dart` | Two-layer parallax painter responding to gyro tilt |
| `apps/mobile/lib/features/splash/widgets/wordmark_lottie.dart` | Lottie wrapper with reduced-motion fallback to PNG |
| `apps/mobile/lib/features/splash/widgets/color_wash.dart` | `AnimatedContainer` gradient sweep used as transition out |
| `apps/mobile/lib/features/splash/services/boot_pipeline.dart` | Sequenced provider warm-up with budget guard |
| `apps/mobile/lib/features/splash/services/auth_route_decider.dart` | Pure function that maps session → next route name |
| `apps/mobile/test/features/splash/splash_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/splash/golden/splash_states.dart` | Golden tests |
| `apps/mobile/integration_test/splash_boot_test.dart` | End-to-end boot timing test |

## Screen / Widget Spec

```dart
// splash_state.dart
sealed class SplashState {
  const SplashState();
}
class SplashBooting extends SplashState {
  final double progress;          // 0.0 .. 1.0
  final String? currentTask;      // 'auth', 'flags', 'db', 'tokens'
  const SplashBooting({required this.progress, this.currentTask});
}
class SplashReady extends SplashState {
  final String nextRoute;         // '/onboarding/segment' | '/login' | '/home' | ...
  final Map<String, Object?> args;
  const SplashReady(this.nextRoute, [this.args = const {}]);
}
class SplashError extends SplashState {
  final BootFailure failure;      // network / version / db
  const SplashError(this.failure);
}
class SplashCooldown extends SplashState {
  final Duration retryIn;
  const SplashCooldown(this.retryIn);
}

// splash_controller.dart — public API
abstract interface class SplashController {
  Future<void> bootstrap();       // kicked off in initState
  Future<void> retry();           // user-triggered after error
  void onWordmarkLoopComplete();  // hook from Lottie controller
}
```

### Animations attached to widgets
- **`WordmarkLottie`** runs `splash_wordmark.json` once (1100ms). The Lottie controller exposes `progress` so we can hold the final frame until `SplashReady` emits.
- **`ParallaxBg`** consumes `accelerometerEvents` (sensors_plus). Far layer translates `±4dp`, near layer translates `±10dp`, both clamped and damped (0.85 lerp factor).
- **`ColorWash`** is the exit choreography: an `AnimatedContainer` whose gradient sweeps from `scanGreen.500 → saffron.500 → ink.900` over 320ms with `Curves.easeInOutCubic` while the wordmark scales from `1.0 → 1.06 → 0.92` and fades to 0.

### Haptic feedback events
- None on entry (boot must feel automatic, not interactive).
- `HapticFeedback.lightImpact()` fires the moment the route push transition begins (handoff signal to the next screen).
- `HapticFeedback.mediumImpact()` fires only on `SplashError` retry button tap.

### Motion choreography (timeline)
| t (ms) | Event |
|---|---|
| 0 | Native splash hides; Flutter splash shown; parallax painter ready |
| 0–80 | Background parallax fades in `Opacity 0 → 1` |
| 80–1180 | Wordmark Lottie plays |
| 0–2200 | Boot pipeline running in parallel |
| 2200 | If pipeline ready, `ColorWash` begins; if not, idle Lottie loops |
| 2200–2520 | Color wash + scale + fade |
| 2400 | GoRouter `pushReplacement(nextRoute)` — Hero transition takes over |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Native iOS/Android splash (single image, matched colors) — handed off in <40ms |
| **loading (booting, progress < 1.0)** | Parallax bg + wordmark lottie + invisible 2dp progress bar at bottom (debug builds only) |
| **loaded (ready)** | Color wash exit; wordmark scale-fade; route push triggered |
| **empty** | N/A — splash is never empty |
| **error (network)** | Wordmark frozen on final frame; toast `SnackBar` "Couldn't reach RADHA. Retry?"; retry button slides in from bottom (`slideY(begin: 0.4).fadeIn(180ms)`) |
| **error (validation/version)** | Modal `AlertDialog` "Update RADHA to continue" with single CTA to Play Store / App Store |
| **success** | Same as `loaded` plus subtle `HapticFeedback.lightImpact` on handoff |
| **offline** | Boots from local Drift cache; nextRoute resolved from cached session; banner "You're offline" pinned to next screen, not splash |
| **rate-limited / cooldown** | Server returns 429 on `/auth/session` → `SplashCooldown` with countdown ring (CircularProgressIndicator over 30/60/120s tiers) |
| **permission-denied** | Splash itself needs no runtime permissions; gyro is opt-in, parallax silently disables if denied |
| **accessibility-mode (reduced motion)** | Parallax disabled; Lottie replaced with static PNG wordmark; color wash replaced with `crossFade` (200ms); haptics suppressed if `MediaQuery.disableAnimations == true` |
| **high contrast** | Background gradient swapped for solid `ink.900`; wordmark uses `scanGreen.300` for AA contrast |
| **dynamic type xxLarge** | Splash carries no body text; "RADHA" is rendered as Lottie shape, not type, so dynamic type does not apply |

## Animations Inventory
- **Lottie files**:
  - `splash_wordmark.json` — 1100ms one-shot, trigger: `initState`
  - `splash_loop_idle.json` — 1600ms loop, trigger: pipeline still running at t=1200ms
- **flutter_animate chains**:
  - Retry button: `.fadeIn(180ms).slideY(begin: 0.4, curve: Curves.easeOutCubic)`
  - Background fade-in: `.fadeIn(80ms)`
  - Wordmark exit: `.scale(begin: 1.0, end: 0.92, duration: 320ms, curve: Curves.easeInOutCubic).fadeOut(280ms)`
- **Hero transitions**: tag `radha-wordmark` carries from splash to `/onboarding/segment` header; custom `CurveTween(Curves.easeOutCubic)`, 360ms.
- **Custom motion**: parallax damping 0.85 lerp every frame (60fps); color wash gradient sweep `easeInOutCubic` 320ms.
- **Stagger**: none (single hero element).
- **Total motion budget**: entrance 1180ms (Lottie); exit 320ms; well within 600/200ms guideline since splash is the one allowed exception per the motion system charter.

## Haptics
- **Light**: route handoff at t=2400ms.
- **Medium**: retry confirm tap on error state.
- **Heavy**: not used here (reserved for FE-12 OTP errors).
- **Selection**: not used here.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `splash.error.network` | "Couldn't reach RADHA. Check your connection." | "RADHA से कनेक्ट नहीं हो सका। कनेक्शन जांचें।" | "RADHA-வை அணுக முடியவில்லை." | "RADHAని చేరుకోలేకపోయాం." | "RADHA-তে পৌঁছানো যায়নি।" | "RADHA पर्यंत पोहोचता आले नाही." |
| `splash.error.retry` | "Retry" | "पुनः प्रयास करें" | "மீண்டும் முயல்" | "మళ్ళీ ప్రయత్నించండి" | "আবার চেষ্টা" | "पुन्हा प्रयत्न" |
| `splash.update_required` | "Update RADHA to continue" | "जारी रखने के लिए RADHA अपडेट करें" | "தொடர RADHA-ஐ புதுப்பிக்கவும்" | "కొనసాగించడానికి RADHA అప్‌డేట్ చేయండి" | "চালিয়ে যেতে RADHA আপডেট করুন" | "सुरू ठेवण्यासाठी RADHA अपडेट करा" |
| `splash.cooldown` | "Too many attempts. Try in {seconds}s" | "बहुत प्रयास। {seconds}s में प्रयास करें" | "{seconds} வினாடிகளில் முயலவும்" | "{seconds}సె తరువాత ప్రయత్నించండి" | "{seconds}s পরে চেষ্টা করুন" | "{seconds}s नंतर प्रयत्न करा" |

(All strings keyed in `lib/l10n/splash.arb` and re-exported from `intl` codegen.)

## Backend Integration
- **Endpoint**: `GET /api/v1/auth/session` (BE-06 v2)
- **Endpoint**: `GET /api/v1/feature-flags` (BE-50)

### Request shape (from `@radha/shared-types`)
```typescript
// no body — Bearer token from secure storage
```

### Response shape
```typescript
export interface SessionDto {
  authenticated: boolean;
  userId?: string;
  tenantId?: string;
  role?: 'consumer' | 'owner' | 'manager' | 'staff' | 'auditor';
  onboardingSegment?: OnboardingSegment | null;
  bypassedOnboarding: boolean;
  premiumActive: boolean;
  serverTime: string; // ISO
  minClientVersion: string; // semver
}
```

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 401 | `token_expired` | Clear secure storage; route to `/login` |
| 403 | `client_too_old` | Show `splash.update_required` modal |
| 429 | `rate_limited` | `SplashCooldown` with `Retry-After` countdown |
| 5xx | `upstream_unavailable` | Fall back to cached session in Drift; banner on next screen |
| network | `offline` | Same fallback path |

### Idempotency key generation
- `GET` requests; idempotency keys not required.
- Boot pipeline tags every outbound request with `X-Boot-Id` (UUID v4 generated once per cold start) for log correlation against BE-23 (observability).

## Accessibility
- Semantics tree: single `Semantics(label: 'RADHA — loading')` on the wordmark; `liveRegion: true` so screen readers announce state changes ("RADHA loaded").
- Focus order: not relevant (no interactive elements during success path).
- Dynamic type: no body copy; not applicable.
- Reduced motion: `MediaQuery.disableAnimations` short-circuits Lottie + parallax; `crossFade` substitution.
- VoiceOver/TalkBack script: "RADHA, retail assistant for data, health and audits, loading."

## Testing
- **Widget tests**:
  - Boot pipeline emits `SplashReady` once all sub-providers complete
  - Network failure produces `SplashError(BootFailure.network)`
  - Cooldown state countdown decrements correctly
  - Reduced motion replaces Lottie with PNG
- **Golden tests** (one per state, `iPhone 14`, `Pixel 6`, `tablet`): `initial`, `booting@500ms`, `error_network`, `error_version`, `cooldown`, `accessibility_high_contrast`.
- **Integration tests**:
  - Cold start to first frame ≤ 800ms on Pixel 4a
  - Cold start to `pushReplacement` ≤ 2400ms on Pixel 4a
  - Offline boot routes to cached session in <1.8s

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Cold start on a fresh install routes to `/onboarding/segment` |
| T2 | Cold start with a valid token + segment chosen routes to `/home` |
| T3 | Cold start with valid token but no segment routes to `/onboarding/segment` |
| T4 | Cold start with `auditor_invited` segment routes to auditor token entry |
| T5 | 401 from `/auth/session` clears secure storage and routes to `/login` |
| T6 | 403 `client_too_old` shows update modal and blocks navigation |
| T7 | 429 with `Retry-After: 30` triggers `SplashCooldown` with 30s countdown |
| T8 | Network offline boots from Drift cache and proceeds in <1.8s |
| T9 | Lottie wordmark plays exactly once, then holds final frame |
| T10 | Parallax disables when accelerometer permission denied (no crash) |
| T11 | Reduced motion swap renders PNG wordmark and skips color wash |
| T12 | Boot pipeline never exceeds 2.4s budget on Pixel 4a (P95) |
| T13 | Splash never sends a second `/auth/session` within a single cold start |
| T14 | `X-Boot-Id` correlates across all boot-time requests (verified in logs) |
| T15 | TalkBack announces "RADHA, loading" on screen mount |

### Q&A (8)
1. How does the splash decide between Trial Pro touchpoint and the Onboarding Segment screen for a returning user who has a token but no segment?
2. What happens if the device clock is more than 5 minutes off — does the splash trust `serverTime` or device time for cooldown countdowns?
3. How does the splash coordinate with FE-50 force-update so we never block users running an OTA-downgraded version?
4. If the cold start exceeds 2.4s due to a slow network, do we delay route handoff or push immediately and let the next screen show its own skeleton?
5. How are the warmed-up providers handed to the next route without re-fetching?
6. How does the splash interact with deep links (e.g., a recall-alert push tap)?
7. What is the fallback if the Lottie file fails to decode on very old Android devices?
8. How is the boot pipeline retried after a transient `5xx` without breaking the "single 2.4s" perception?

## Sign-off Gate
- [ ] Developer: All 15 tests pass; coverage ≥ 90%; integration test green on Pixel 4a + iPhone 12.
- [ ] Reviewer: Boot pipeline reads correctly; no business logic in widget.
- [ ] Designer (motion review): Lottie timing, color wash curve, parallax damping approved.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-09**
