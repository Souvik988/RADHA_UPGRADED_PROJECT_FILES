# Phase FE-17: Scanner Camera Screen

## 1. Phase Metadata

- **Phase ID**: FE-17
- **Phase Name**: Scanner Camera Screen
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme/Material You tokens), FE-09 (haptics service), FE-15 (router shell), BE-10 v2 (scan endpoint), BE-45 (image OCR fallback), BE-32 v2 (rate limit)
- **Blocks**: FE-18 (Scan Output), FE-19 (Product Detail), FE-23 (Alternatives Carousel)
- **Estimated Duration**: 3 days
- **Complexity**: High (camera + ML Kit + 60fps target)

## 2. Goal (Engagement Angle)

Deliver the screen where 80% of all RADHA daily-active sessions begin: the live camera scanner. Every interaction must feel **instant, confident, and slightly delightful** — a barcode is recognised in under 350 ms, the reticle visibly *snaps closed* on success, the phone gives a soft thump, and the screen Hero-flies into FE-18. Failure is never a dead end: 2 seconds with no detection automatically surfaces the *"Take photo of label"* CTA wired to BE-45.

## 3. Why This Phase Matters (Retention Metric)

- Scanner is the home-screen primary action; **scan-to-result median latency** is the #1 north-star metric for consumer retention.
- Target: **D1 retention ≥ 42%**, **scans/active-user/week ≥ 6**. Both regress hard if the camera is laggy, the reticle is confusing, or the failure path is hidden.
- Pixel 4a is our reference low-end device — **60 fps preview** is non-negotiable; if the GPU thread drops below 55 fps for >250 ms we must downscale preview resolution rather than ship jank.
- Engagement multiplier: every successful scan within 1 s gets a haptic + flash that creates a "casino moment" — measured to lift session length by ~18% in beta.

## 4. Prerequisites

- [ ] FE-04 done — Material You ColorScheme + `frostedGlass` decoration token
- [ ] FE-09 done — `HapticsService` exposes `light/medium/heavy/selection`
- [ ] FE-15 done — `GoRouter` exposes `/scan` route with shell scaffolding
- [ ] BE-10 v2 deployed — `POST /api/v1/scans` accepting `{ ean, source: 'barcode'|'image' }`
- [ ] BE-45 deployed — `POST /api/v1/scans/image` accepting multipart image
- [ ] BE-32 v2 deployed — 429 envelope with `retryAfterSec` and `upgradeTo`
- [ ] Asset budget approved: Lottie ≤ 80 KB total for this screen
- [ ] Camera + storage runtime permissions strings localised in 6 languages

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/scanner/scanner_screen.dart` | Stateful page widget, camera lifecycle |
| `apps/mobile/lib/features/scanner/widgets/scanner_reticle.dart` | Animated 4-corner brackets |
| `apps/mobile/lib/features/scanner/widgets/scanner_control_bar.dart` | Frosted bottom bar (torch/gallery/recents) |
| `apps/mobile/lib/features/scanner/widgets/recent_scans_drawer.dart` | Bottom-sheet drawer of last 10 scans |
| `apps/mobile/lib/features/scanner/widgets/image_fallback_cta.dart` | "Take photo of label" pulsing card |
| `apps/mobile/lib/features/scanner/widgets/permission_denied_view.dart` | Full-page denial state |
| `apps/mobile/lib/features/scanner/controllers/scanner_controller.dart` | Riverpod `AsyncNotifier` — ML Kit pipeline |
| `apps/mobile/lib/features/scanner/controllers/scanner_state.dart` | Sealed state (idle/scanning/detected/error) |
| `apps/mobile/lib/features/scanner/services/barcode_detector_service.dart` | ML Kit wrapper, throttle, cache |
| `apps/mobile/lib/features/scanner/services/scan_uploader.dart` | Dio call to BE-10 v2 with idempotency key |
| `apps/mobile/lib/features/scanner/data/recent_scans_repository.dart` | Drift table read/write last 10 scans |
| `apps/mobile/lib/features/scanner/animations/reticle_converge.dart` | TweenSequence — 4 corners → centre |
| `apps/mobile/assets/lottie/scan_success_flash.json` | 600 ms green flash + checkmark |
| `apps/mobile/assets/lottie/scan_idle_pulse.json` | 1800 ms looping subtle pulse on reticle |
| `apps/mobile/test/features/scanner/scanner_screen_widget_test.dart` | Widget tests |
| `apps/mobile/test/features/scanner/scanner_screen_golden_test.dart` | Golden snapshots × 3 themes |
| `apps/mobile/integration_test/scanner_flow_test.dart` | Camera-mock e2e |

## 6. Screen / Widget Spec

```dart
// scanner_screen.dart (sketch)
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final CameraController _camera;
  late final AnimationController _reticleCtrl; // 220 ms converge
  Timer? _imageFallbackTimer;                   // fires at 2s
  DateTime? _lastDetectAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reticleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220),
    );
    _bootCamera();
    _imageFallbackTimer = Timer(const Duration(seconds: 2), _showImageFallback);
  }

  Future<void> _onBarcodeDetected(Barcode b) async {
    if (DateTime.now().difference(_lastDetectAt ?? DateTime(0)).inMilliseconds < 1500) return;
    _lastDetectAt = DateTime.now();
    HapticFeedback.mediumImpact();
    await _reticleCtrl.forward();          // converge brackets
    ref.read(scanSuccessFlashProvider.notifier).flash();
    final scan = await ref.read(scannerControllerProvider.notifier)
        .submit(ean: b.rawValue!, source: 'barcode');
    if (!mounted) return;
    context.pushReplacement('/scan/${scan.id}',
      extra: {'heroTag': 'scan-${scan.id}-image'});
  }
  // ...
}
```

```dart
// scanner_reticle.dart (sketch)
class ScannerReticle extends StatelessWidget {
  final Animation<double> converge;            // 0 → 1
  const ScannerReticle({required this.converge, super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: converge,
      builder: (_, __) {
        final t = Curves.easeOutBack.transform(converge.value);
        // 4 corner brackets translate inward by 24*t px, scale 1 → 0.92
        return CustomPaint(
          painter: _CornerBracketsPainter(progress: t,
            color: Theme.of(context).colorScheme.primary),
          size: const Size(260, 260),
        );
      },
    );
  }
}
```

```dart
// scanner_control_bar.dart layout
// Bottom 96 dp safe-area-inset frosted bar, BackdropFilter sigma 18
// Row: [TorchToggle] [GalleryPicker] (centre flexible space) [RecentsButton]
// Each tappable area 48×48 dp, ripple radius 32, contains icon + label semantic.
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI | Notes |
|---|---|---|---|---|
| 1 | **initial** | Screen mounts, permission granted | Black scrim, reticle pulses at 0.6 → 0.9 alpha (Lottie loop), control bar visible | Idle Lottie attached to reticle |
| 2 | **booting-camera** | First 0–500 ms | Indeterminate progress under reticle, control bar disabled | Show even on warm start to mask hand-off |
| 3 | **scanning** | Camera live, no barcode yet | Reticle pulse + tiny "Align barcode" caption fading at 0.3s intervals | Caption hidden after 4s |
| 4 | **barcode-detected** | ML Kit returns valid EAN | Brackets converge 220 ms, green flash 350 ms, haptic medium | Hero pushed to FE-18 |
| 5 | **image-fallback-prompt** | 2 s with no detection | Slides in CTA card from bottom (160 ms), `flutter_animate` `.slideY(begin: 1, curve: easeOutCirc)` | Dismissible by tap-outside |
| 6 | **uploading** | After detect, BE-10 round-trip pending | Reticle morphs to 32 dp circular progress at centre; UI locked | Cancel button after 4 s |
| 7 | **error-network** | Dio timeout / 5xx | Red toast "Couldn't reach RADHA — saved offline" + retry pill, scan persisted via Drift | Hides after 4 s |
| 8 | **error-permission-denied** | Camera permission false | Full-screen empty state: icon + 2-line copy + "Open settings" button | Lottie `permission_lock.json` 1.4s loop |
| 9 | **error-rate-limited** | BE-32 v2 returns 429 | Bottom sheet: copy + "Upgrade to Premium" CTA + scan-counter widget | `upgradeTo: 'premium_consumer'` honoured |
| 10 | **error-validation** | EAN regex fails / unknown product | Inline snackbar "Barcode unrecognised — try image scan" with shortcut to BE-45 | No haptic |
| 11 | **success** | FE-18 ready to receive | Scaffold fades to black 80 ms before Hero animates | Hero tag `scan-{id}-image` |
| 12 | **offline** | Connectivity stream `none` | Persistent amber strip "Offline — scans queue locally" above control bar | Strip 32 dp, dismissible |
| 13 | **accessibility-mode** | `MediaQuery.disableAnimations == true` | Lottie static frame, brackets snap (no converge), success uses solid green box | Honour reduced motion |
| 14 | **torch-on** | User taps torch | Icon fills, ripple, semantics "Torch on" | Persists across pause/resume |
| 15 | **drawer-open** | Tap recents | Drawer rises 240 ms `easeOutCubic`, scrim 60% black | List 10 items via Drift |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `scan_idle_pulse.json` | 1800 ms | state = scanning | Yes | ≤ 22 KB |
| `scan_success_flash.json` | 600 ms | state = barcode-detected | No | ≤ 30 KB |
| `permission_lock.json` | 1400 ms | state = error-permission-denied | Yes | ≤ 18 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| Image fallback CTA | `.fadeIn(150).slideY(begin: 1, end: 0, dur: 200)` | easeOutCirc | 350 ms |
| Recent scans drawer | `.slideY(begin: 1, end: 0, dur: 240)` | easeOutCubic | 240 ms |
| Error toast | `.fadeIn(120).then().shake(hz: 3, dur: 320)` | linear / easeInOut | 440 ms |
| Torch icon flip | `.flipH(dur: 180)` | easeOutBack | 180 ms |
| Reticle converge | TweenSequence 0→1 over 220 ms | easeOutBack | 220 ms |

### Hero Transitions

| From | To | Tag | Curve | Duration |
|---|---|---|---|---|
| Reticle frame | FE-18 product image | `scan-{id}-image` | `Curves.easeInOutCubic` | 380 ms |

### Custom Motion Budgets

- **Total entrance budget**: 540 ms (camera-fade-in 80 + reticle-pulse-fade 200 + control-bar-rise 260)
- **Detection-to-Hero budget**: ≤ 600 ms (220 converge + 350 flash + 30 hand-off)
- **Failure budget**: 2000 ms before image-fallback CTA (must be configurable via remote flag `scanner.fallback_ms`)

## 9. Haptics

| Event | Type | Notes |
|---|---|---|
| Barcode detected | `HapticFeedback.mediumImpact()` | Single thump on first valid frame |
| Torch toggle | `HapticFeedback.selectionClick()` | Both on and off |
| Recents drawer open/close | `HapticFeedback.lightImpact()` | Once per gesture |
| Image fallback CTA appears | `HapticFeedback.lightImpact()` | Subtle bid for attention |
| Permission denied → Open Settings | `HapticFeedback.heavyImpact()` | Communicates the "blocked" feeling |
| 429 rate-limit sheet | `HapticFeedback.heavyImpact()` | Once on appearance |

## 10. Microcopy (en + 5 Indic placeholders)

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `scanner.title` | Scan a product | TODO_HI | TODO_TA | TODO_TE | TODO_BN | TODO_MR |
| `scanner.align_hint` | Align the barcode inside the frame | TODO | TODO | TODO | TODO | TODO |
| `scanner.fallback_cta` | Take a photo of the label instead | TODO | TODO | TODO | TODO | TODO |
| `scanner.permission_title` | RADHA needs your camera | TODO | TODO | TODO | TODO | TODO |
| `scanner.permission_body` | Without it, scanning won't work. You can change this any time in Settings. | TODO | TODO | TODO | TODO | TODO |
| `scanner.permission_action` | Open Settings | TODO | TODO | TODO | TODO | TODO |
| `scanner.error_network` | Couldn't reach RADHA — your scan is saved offline | TODO | TODO | TODO | TODO | TODO |
| `scanner.error_unknown` | Barcode not recognised. Try the image scan. | TODO | TODO | TODO | TODO | TODO |
| `scanner.rate_limit_title` | You've hit your free daily scans | TODO | TODO | TODO | TODO | TODO |
| `scanner.rate_limit_cta` | Upgrade to Premium for unlimited scans | TODO | TODO | TODO | TODO | TODO |
| `scanner.recents_title` | Recent scans | TODO | TODO | TODO | TODO | TODO |
| `scanner.recents_empty` | Your scans will appear here | TODO | TODO | TODO | TODO | TODO |
| `scanner.offline_strip` | You're offline — scans will sync later | TODO | TODO | TODO | TODO | TODO |

All keys live in `lib/l10n/app_en.arb` (and 5 siblings). CI fails if any key is missing in any locale.

## 11. Backend Integration

### Endpoints

| Method | Path | Used For | Source |
|---|---|---|---|
| `POST` | `/api/v1/scans` | Submit detected EAN | BE-10 v2 |
| `POST` | `/api/v1/scans/image` | Image fallback (multipart) | BE-45 |
| `GET` | `/api/v1/scans/recent?limit=10` | Recents drawer hydrate | BE-10 v2 |

### Request shapes (from `@radha/shared-types`)

```ts
// ScanCreateRequest
{ ean: string; source: 'barcode' | 'image' | 'manual';
  capturedAt: string; deviceModel?: string; idempotencyKey: string }
// ScanCreateResponse
{ id: string; productId?: string; status: 'matched'|'unknown'|'pending_ocr';
  rateLimit?: { remaining: number; resetAt: string } }
```

### Idempotency Key Strategy

- Key = `sha256(userId + ean + capturedAt-rounded-1s)` truncated to 32 chars.
- Stored in Drift `scan_outbox` until server ACK.
- On retry, identical key → BE-10 returns cached response (server-side dedupe).

### Error → UI Mapping

| HTTP / Code | Server `error.code` | UI Behaviour |
|---|---|---|
| 401 | `auth.expired` | Push login screen, preserve scan in outbox |
| 403 | `entitlement.scan_quota_exceeded` | Show rate-limit sheet (state #9) |
| 404 | `product.not_found` | Show validation snackbar (state #10) + image-fallback CTA |
| 422 | `scan.invalid_ean` | Same as 404 |
| 429 | `rate.limited` | Sheet with `retryAfterSec` countdown |
| 5xx / network | — | Toast + outbox queue |

## 12. Accessibility

- **Semantics**: Reticle = `Semantics(label: 'Barcode scanner viewfinder', liveRegion: true)`. Torch button = `Semantics(button: true, label: 'Torch', toggled: state.torchOn)`.
- **Focus order**: AppBar back → Torch → Gallery → Recents → Image-fallback CTA (when present). TalkBack/VoiceOver traverse in this order.
- **Dynamic type**: All captions use `Theme.textTheme.bodyMedium` and scale up to `MediaQuery.textScaler.scale(1.5)`. Reticle frame stays fixed at 260 dp.
- **Reduced motion**: When `MediaQuery.disableAnimations` is true: no Lottie loop (static first frame), reticle converge replaced with snap, success flash replaced by solid green Container 200 ms.
- **VoiceOver / TalkBack script**: On state-change to `barcode-detected`, post `SemanticsService.announce('Product detected, opening details', TextDirection.ltr)`.
- **Colour contrast**: Caption text on dark camera preview must satisfy WCAG AA (min 4.5:1) — backed by `Colors.black54` scrim if needed.

## 13. Testing

### Widget tests (Jest equivalent: `flutter_test`)

- Reticle renders 4 brackets, each at correct corner.
- Tapping torch toggles icon and fires `selectionClick`.
- 2 s without detection → image fallback CTA appears.
- Permission denied state shows Open-Settings button.
- 429 response renders rate-limit sheet with correct copy.

### Golden tests

- Idle state (light + dark + dynamic-type-1.5x) — 3 goldens.
- Detected-flash mid-frame — 1 golden.
- Permission denied — 1 golden.

### Integration tests

- Full mocked-camera flow: simulate barcode frame → asserts navigation to FE-18 with correct Hero tag and scan id.
- Offline path: airplane-mode mock → asserts Drift outbox has row + amber strip visible.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Cold start to first preview frame ≤ 800 ms on Pixel 4a |
| T2 | Sustained preview FPS ≥ 55 over 60 s on Pixel 4a (perf overlay capture) |
| T3 | Barcode detection fires haptic exactly once per scan, even if same EAN re-detected within 1.5 s |
| T4 | Reticle converge animation completes in 220 ± 20 ms |
| T5 | Image fallback CTA appears at 2000 ± 50 ms with no detection |
| T6 | Camera releases on `WidgetsBindingObserver.didChangeAppLifecycleState(paused)` |
| T7 | Camera re-acquires on resume within 400 ms |
| T8 | Torch state persists across lifecycle pause/resume |
| T9 | Permission denial deep-links to OS settings page |
| T10 | Offline scan persists to Drift `scan_outbox` and syncs on reconnect (BE-44 v2) |
| T11 | Rate-limit (429) sheet displays `retryAfterSec` counter ticking down |
| T12 | Idempotency key is identical on retry of the same scan within 1 s |
| T13 | VoiceOver announces `barcode-detected` once and only once |
| T14 | Reduced-motion flag suppresses Lottie loops and replaces converge with snap |
| T15 | Hero tag `scan-{id}-image` matches the tag consumed by FE-18 |

### Q&A Questions (8)

1. How does the scanner behave when ML Kit returns multiple barcodes in the same frame (e.g., shelf with adjacent products)?
2. What is the strategy for memory pressure when the user lingers on the screen for >2 minutes (image stream still firing)?
3. How is the `idempotencyKey` regenerated if the user scans the *same* EAN deliberately twice in quick succession?
4. How does the screen interact with the BE-32 v2 *fail-open* policy when Redis is down — do we still meter client-side?
5. What's the rollback path if the on-device ML Kit model is corrupted or fails to load?
6. How are recents pruned when the user clears app data vs. when they sign out (Drift table lifecycle)?
7. How do we test the 60 fps target in CI given there is no real camera in the test runner?
8. What is the upgrade path for a user who hits the free-tier 50/day cap mid-aisle in a supermarket — can the rate-limit sheet open the Premium paywall in ≤ 2 taps?

### Sign-off Gate

- [ ] All 15 SOP tests pass on Pixel 4a hardware
- [ ] All 8 Q&A answered in handoff
- [ ] Designer has reviewed the converge animation and signed off the curve
- [ ] Animation budgets respected (entrance ≤ 600 ms, detect ≤ 600 ms)
- [ ] Code reviewed, golden tests merged

**Developer Signature**: ___________________________

**Reviewer Approval** ☐ APPROVED — Proceed to FE-18 ☐ CHANGES REQUESTED

**Reviewer Signature**: ___________________________

**Designer Approval** ☐ APPROVED ☐ CHANGES REQUESTED

**Designer Signature**: ___________________________

---

**END OF FE-17 — DO NOT PROCEED WITHOUT APPROVAL**
