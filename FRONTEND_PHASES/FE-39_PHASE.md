# Phase FE-39: Performance Pass — 60fps Audit, Image Budget, Jank Trace

## Phase Metadata
- **Phase ID**: FE-39
- **Phase Name**: Performance Pass — 60fps Audit, Image Budget, Jank Trace
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: every prior FE phase that ships UI (FE-09..FE-38) — this phase audits all of them; particularly FE-04 (motion bootstrap), FE-17 (camera/scanner), FE-19 (product detail Hero), FE-32 (reports list), FE-33 (animation registry — feeds `MotionProfile.lowEndAuto`), FE-37 (skeletons), FE-38 (a11y modes that change layout cost)
- **Backend Depends On**: BE-48 observability (consume the perf metrics from cold-start telemetry), BE-29 analytics (perf telemetry events)
- **Blocks**: FE-40 (release engineering reads the published perf budget and refuses to ship a build that violates it)
- **Estimated Duration**: 3-4 days
- **Complexity**: High — every screen is a candidate, profiling is non-trivial, regressions are global

## Goal
Make the perf budget published in `00_MASTER_FRONTEND_ROADMAP.md` **enforceable in CI**, not aspirational in a doc. Specifically, this phase produces a tool-shed (`apps/mobile/tool/performance/`) plus runtime probes that together prove, on every pull request, that the app still meets:

- **Cold start to first frame ≤ 1.5 s** on a Pixel 4a release build (prod flavor).
- **60 fps sustained** through every Hero transition and list scroll (frame budget 16.6 ms, jank rate < 1% of frames).
- **APK size ≤ 35 MB** for `arm64-v8a` release.
- **Memory ceiling < 220 MB** RSS after 5 min of mixed use (scan, scroll, navigate, idle).
- **Scan-to-verdict p95 ≤ 1.5 s** end-to-end (camera open → ML Kit barcode read → product cached lookup → verdict card painted).

The phase ships traces, baselines, lint rules and integration perf tests — not new features. By the end, a developer who regresses cold start by 200 ms cannot merge their PR.

This phase also folds in three cross-cutting hygiene loops that other phases depend on:
- Image lazy-loading enforcement (`CachedNetworkImage` only, never raw `NetworkImage`).
- `const` constructor enforcement via custom analyzer rule (cuts widget-tree rebuild cost).
- Riverpod `select` / `selectWatch` enforcement via custom analyzer rule (prevents whole-state rebuilds).

## Why This Phase Matters
- **Cold start under 1.5 s is a perceived-quality threshold.** Above that, users start to remember the wait. Below it, they don't. Every premium app on the Indian Play Store landed there before they got featured.
- **Jank kills retention more than crashes.** Crashes are loud; jank is quiet. A user who hits 9 fps during a Hero on a Redmi 9A blames "this app is laggy" and uninstalls without a crash event ever firing. The only defence is a profiling pipeline that catches it before merge.
- **APK budget is a feature.** The 35 MB ceiling is informed by India's prepaid data ceilings (Jio 1.5 GB/day plans) and low-storage device habits — users uninstall fast when they need 200 MB free. Holding the line keeps install conversion 6–9% higher than the 50 MB-class peer set (industry estimate).
- **Memory ceiling protects the camera path.** The scanner (FE-17) plus ML Kit detector hold the high-water mark. If we balloon to 280 MB, low-end OEMs (MIUI, ColorOS) will kill the app while it's scanning — the worst possible UX.
- **Auto-detected device class drives motion + skeleton fidelity.** `MotionProfile.lowEndAuto` from FE-33 needs a single source of truth for "is this a low-end device" — this phase publishes `device_class.dart`, and FE-33, FE-37, FE-38 read from it.
- **CI is the only honest enforcer.** Manual perf testing decays the moment the engineer who set up the trace leaves. Trace runs committed as JSON snapshots make regressions self-evident in code review.

## Prerequisites
- [ ] FE-01..FE-38 merged. FE-39 audits real code, not stubs.
- [ ] FE-33 `MotionProfile` enum already exposes a `lowEndAuto` slot waiting for this phase's resolver.
- [ ] FE-37 skeleton shimmer rate already configurable per device class (this phase wires the input).
- [ ] Test fleet available: Pixel 4a (Android 13), Redmi Go (Android 8 Go Edition, 1 GB RAM), Nokia C20 (Android 11 Go, 2 GB), iPhone SE 2 (iOS 16), iPhone 8 (iOS 16). All physical devices, not emulators.
- [ ] Flutter DevTools 2.32+ installed; `devtools_app` available on every developer machine.
- [ ] Android Studio Profiler + Xcode Instruments installed for native side checks.
- [ ] CI runner: macOS for iOS builds, Ubuntu for Android. Self-hosted GitHub Actions runners for device-attached perf jobs.
- [ ] Backend: BE-48 observability ingestion endpoint ready to receive `perf_cold_start` and `perf_frame_drop` events.

## Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/tool/performance/run_startup_trace.sh` | Bash: `flutter run --profile --trace-startup` on connected Android device, parse `start_up_info.json`, emit metrics |
| `apps/mobile/tool/performance/run_startup_trace.bat` | Windows equivalent for engineers on Windows dev machines |
| `apps/mobile/tool/performance/jank_baseline.json` | Committed perf snapshot — last green per-screen frame stats. Diffed by CI |
| `apps/mobile/tool/performance/image_budget.yaml` | Per-asset KB budget. CI fails if any asset exceeds entry |
| `apps/mobile/tool/performance/perf_lints.yaml` | Custom-lint config: forbids `NetworkImage`, missing `const`, unscoped `ref.watch` |
| `apps/mobile/tool/performance/diff_jank_baseline.dart` | CLI tool: compare current trace to baseline, exit non-zero on regression |
| `apps/mobile/tool/performance/analyze_apk_size.sh` | Wraps `flutter build apk --analyze-size`, parses output, asserts ≤ 35 MB |
| `apps/mobile/lib/perf/device_class.dart` | Device-class auto-detect — feeds `MotionProfile.lowEndAuto` (FE-33) and skeleton fidelity (FE-37) |
| `apps/mobile/lib/perf/perf_overlay.dart` | Debug-only HUD: live FPS, frame budget bar, dropped-frame count |
| `apps/mobile/lib/perf/perf_telemetry.dart` | Hooks into `WidgetsBinding.addTimingsCallback`; samples and emits frame metrics to BE-48 |
| `apps/mobile/lib/perf/cold_start_marker.dart` | Records `engineEnteredCallback`, `firstFrameRasterized` and `firstUserInteraction` timestamps |
| `apps/mobile/lib/perf/image_cache_tuning.dart` | Configures `PaintingBinding.imageCache` (size + maximumSizeBytes) per device class |
| `apps/mobile/integration_test/perf/cold_start_perf_test.dart` | Cold-start timing under `IntegrationTestWidgetsFlutterBinding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive` |
| `apps/mobile/integration_test/perf/scan_to_verdict_perf_test.dart` | End-to-end scan path: opens scanner, injects fake barcode frame, asserts verdict card paint within 1.5 s p95 |
| `apps/mobile/integration_test/perf/list_scroll_perf_test.dart` | Scrolls Reports list (FE-32) + Recall inbox (FE-21) 1000 px in 1 s; asserts < 1% jank |
| `apps/mobile/integration_test/perf/memory_soak_test.dart` | 5-min soak: scan, scroll, navigate. Reads `ProcessInfo.currentRss`; asserts ceiling < 220 MB |
| `apps/mobile/test/perf/device_class_test.dart` | Unit: classifier returns `lowEnd` for 1 GB RAM, `mid` for 2-4 GB, `high` for ≥ 4 GB |
| `apps/mobile/test/perf/cold_start_marker_test.dart` | Unit: marker timestamps strictly monotonic |
| `.github/workflows/mobile-perf.yml` | CI: runs perf integration tests on a self-hosted Pixel 4a, diffs `jank_baseline.json`, fails on regression |
| `docs/perf/PERF_BUDGET.md` | Engineer-facing budget doc; cross-linked from every phase Risk Assessment |

## Implementation Spec

### `device_class.dart` — single source of truth for device tier
```dart
enum DeviceClass { lowEnd, mid, high }

class DeviceProbe {
  final int totalMemoryMb;
  final double refreshHz;
  final int sdkInt;          // Android API level; -1 on iOS
  final String? iosModel;    // 'iPhone8,1' etc; null on Android
  final bool isPhysicalDevice;

  const DeviceProbe({...});

  DeviceClass classify() {
    if (totalMemoryMb < 2048) return DeviceClass.lowEnd;
    if (refreshHz < 60) return DeviceClass.lowEnd;
    if (sdkInt > 0 && sdkInt < 26) return DeviceClass.lowEnd;
    if (_iosLowEndModels.contains(iosModel)) return DeviceClass.lowEnd;
    if (totalMemoryMb < 4096) return DeviceClass.mid;
    return DeviceClass.high;
  }

  static const _iosLowEndModels = {
    'iPhone8,1', 'iPhone8,2',           // iPhone 6s family
    'iPhone9,1', 'iPhone9,3',           // iPhone 7
    'iPhone10,1', 'iPhone10,4',         // iPhone 8
    'iPad6,11', 'iPad6,12',             // iPad 5th gen
  };
}

final deviceClassProvider = Provider<DeviceClass>((ref) =>
    ref.watch(deviceProbeProvider).classify());
```

### `cold_start_marker.dart`
```dart
class ColdStartMarker {
  static final DateTime processStart = DateTime.now();
  static DateTime? engineReady;
  static DateTime? firstFrame;
  static DateTime? firstInteraction;

  static void engineReadyNow() => engineReady ??= DateTime.now();
  static void firstFrameNow()  => firstFrame  ??= DateTime.now();
  static void firstInteractionNow() => firstInteraction ??= DateTime.now();

  static Map<String, int> snapshot() => {
    'engineMs':   engineReady?.difference(processStart).inMilliseconds ?? -1,
    'firstFrameMs': firstFrame?.difference(processStart).inMilliseconds ?? -1,
    'firstInteractionMs':
        firstInteraction?.difference(processStart).inMilliseconds ?? -1,
  };
}
```

`firstFrame` is captured in `WidgetsBinding.instance.addPostFrameCallback` from `bootstrap()` (FE-01). The snapshot is shipped to BE-48 once the user is past the splash.

### `perf_overlay.dart` — debug HUD
```dart
class PerfOverlay extends StatefulWidget {
  // Wraps `MaterialApp.builder`. Renders top-right pill with:
  //   - rolling 60-frame avg FPS
  //   - 99-pct frame time
  //   - dropped frames in last 1s
  //   - current image cache fill
  //   - active animation count (from MotionDiagnostics in FE-33)
  // Disabled in release builds via const guard.
}
```

### `perf_telemetry.dart`
```dart
class PerfTelemetry {
  static void install() {
    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> frames) {
      for (final f in frames) {
        final totalMs = f.totalSpan.inMicroseconds / 1000;
        if (totalMs > 16.6) _bucketDrop(totalMs);
      }
    });
  }
  // Aggregated and flushed to BE-29 every 30s, sampled at 1% in prod.
}
```

### `image_cache_tuning.dart`
```dart
void tuneImageCacheFor(DeviceClass cls) {
  final cache = PaintingBinding.instance.imageCache;
  switch (cls) {
    case DeviceClass.lowEnd:
      cache.maximumSize = 50;
      cache.maximumSizeBytes = 24 << 20;   // 24 MB
    case DeviceClass.mid:
      cache.maximumSize = 100;
      cache.maximumSizeBytes = 48 << 20;   // 48 MB
    case DeviceClass.high:
      cache.maximumSize = 200;
      cache.maximumSizeBytes = 96 << 20;   // 96 MB
  }
}
```

### `image_budget.yaml`
```yaml
# Per-asset budgets. CI tool walks assets/, fails if any file exceeds.
defaults:
  png_kb: 60
  jpg_kb: 80
  webp_kb: 40
  svg_kb: 8
  lottie_kb: 80
overrides:
  assets/onboarding/hero_*.webp: { kb: 120 }
  assets/lottie/radha_logo_loop.json: { kb: 60 }
  assets/icons/*.svg: { kb: 4 }
totals:
  assets_total_mb: 8       # ceiling for everything under assets/
  fonts_total_mb: 4
```

### `jank_baseline.json` (committed example shape)
```json
{
  "version": 1,
  "device": "pixel_4a",
  "build": "release-prod",
  "screens": {
    "scan": { "p50_frame_ms": 9.2, "p99_frame_ms": 14.8, "jank_pct": 0.4 },
    "product_detail": { "p50_frame_ms": 8.1, "p99_frame_ms": 16.0, "jank_pct": 0.7 },
    "reports_list_scroll": { "p50_frame_ms": 9.7, "p99_frame_ms": 15.4, "jank_pct": 0.6 }
  },
  "regression_tolerance": { "p99_frame_ms": 1.5, "jank_pct_abs": 0.3 }
}
```

CI's `diff_jank_baseline.dart` compares the new run against this snapshot and fails if any screen exceeds tolerances.

### `run_startup_trace.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
DEVICE_ID="${1:-}"
flutter build apk --release --flavor prod --target lib/main_prod.dart
flutter install --release --flavor prod -d "$DEVICE_ID"
flutter run --profile --flavor prod \
  --target lib/main_prod.dart \
  --trace-startup \
  --no-resident \
  -d "$DEVICE_ID"
# Output: build/start_up_info.json
python3 tool/performance/parse_startup.py build/start_up_info.json
```

## Visual Behaviour
This phase ships **no user-facing UI** in release builds. Debug-only surfaces:

| State | Visual |
|---|---|
| **Debug build, perf overlay on** | Top-right pill, 14 sp mono, semi-transparent background, FPS / 99-pct frame ms / dropped-frame count |
| **Debug build, frame drop > 32 ms** | Pill flashes red for 200 ms; line written to `flutter logs` with stack trace of last frame |
| **Debug build, image cache full** | Pill shows `cache: 96/100 ▮▮▮▮▮▮▮▮▮▯` |
| **Debug build, low-end device detected** | Pill prefix `LE` in amber to confirm `MotionProfile.lowEndAuto` is active |
| **Profile build, scan-to-verdict trace** | Trace event emitted to DevTools timeline with name `radha.scan_to_verdict` |
| **Release build, all paths** | Zero overlay, zero log, only sampled telemetry to BE-29 |

## Animations
This phase **adds no animations**. It defines the budget the rest of the app respects:

- Total motion budget per route transition: ≤ 480 ms (Hero ceiling from FE-33).
- Skeleton shimmer cycle: 1.4 s on mid/high; 2.0 s (slower, calmer) on `lowEnd`.
- List reveal stagger: capped at 28 ms per item on `lowEnd` (the FE-33 `tight` token), no exceptions.
- Per-frame allocation budget: ≤ 16.6 ms on Pixel 4a / iPhone SE 2; ≤ 11.1 ms (90 fps frame) where the device reports ≥ 90 Hz refresh.

## Accessibility
- Perf telemetry emits `accessibilityFeatures` snapshot alongside frame metrics so we can isolate jank caused by TalkBack/VoiceOver tree traversal (FE-38 surfaces this).
- `device_class.dart` does **not** auto-degrade for users on screen readers — accessibility takes precedence over motion-fidelity downgrade.
- Perf overlay is `excludeSemantics: true` so it never appears in TalkBack focus order.
- Image cache tuning honours `MediaQuery.disableAnimationsOf` — animated `Image`s are pre-decoded to avoid frame drops when reduced motion is on.

## Testing

### Unit tests
- `device_class_test.dart`: classifier branch coverage (1 GB → lowEnd, 1.5 GB → lowEnd, 2 GB → lowEnd if refresh < 60, 2.5 GB → mid, 4 GB → mid, 6 GB → high).
- `cold_start_marker_test.dart`: timestamps monotonic; missing markers return -1.
- `image_cache_tuning_test.dart`: image cache configured to documented bytes per class.

### Integration tests (`integration_test/perf/`)
- `cold_start_perf_test.dart`: 5 cold launches per device class. Asserts p95 first-frame ≤ 1.5 s on mid/high, ≤ 2.0 s on `lowEnd`.
- `scan_to_verdict_perf_test.dart`: stub camera frame source; assert paint of verdict card within 1.5 s p95.
- `list_scroll_perf_test.dart`: drives `Scrollable.ensureVisible` over 1000 px in 1 s; asserts dropped frames < 1%.
- `memory_soak_test.dart`: 5-min mixed workload; asserts `ProcessInfo.currentRss < 220 MB` on Pixel 4a.

### CI gates
- `mobile-perf.yml`:
  1. Build profile APK for prod flavor.
  2. Install on attached Pixel 4a runner.
  3. Run `run_startup_trace.sh`.
  4. Run all four `integration_test/perf/*` tests.
  5. Run `analyze_apk_size.sh`.
  6. Run `diff_jank_baseline.dart`.
  7. Upload artifacts: `start_up_info.json`, `timeline_summary.json`, `apk-analysis.json`.
- Required check on `main`: a PR cannot merge red.

### Trace artifacts
Every CI run uploads:
- DevTools timeline JSON.
- `start_up_info.json` per cold-start sample.
- APK size analysis breakdown (Dart vs assets vs native libs).
- Frame-time histogram per audited screen.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Self-hosted device runner flakes (battery, USB cable) | High | Two-of-three retry policy in CI; nightly runner health check; alarm to on-call |
| `--trace-startup` numbers vary ±15% on the same device | Medium | Take 5 samples, use p95; tolerance band in `jank_baseline.json` covers normal variance |
| Skia → Impeller migration changes perf profile mid-roadmap | Medium | Pin to Impeller on iOS, Skia on Android until Flutter 3.27 ships Impeller-Android stable; revisit before FE-40 |
| Image budget triggers on legitimate hero asset (e.g., paywall illustration) | Medium | `image_budget.yaml` `overrides` section with per-path opt-up; reviewed by designer + tech lead |
| `selectWatch` lint produces false positives on legitimate whole-state reads | Low/Medium | Allowlist via `// ignore: radha_select_required` with reviewer sign-off |
| Pixel 4a EOL — Google stops shipping security updates | Low/Long-term | Roadmap calls for swap to Pixel 6a as primary perf target by 2026; baseline JSON re-recorded |
| ProcessInfo.currentRss not available on all platforms | Low | Use `dart:developer` `Service.getMemoryUsage` fallback; document gap |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `flutter build apk --release --flavor prod --analyze-size` produces an arm64-v8a APK ≤ 35 MB; `analyze_apk_size.sh` exits 0 |
| T2 | `flutter run --profile --flavor prod --trace-startup` on Pixel 4a reports first-frame ≤ 1.5 s averaged over 5 cold launches |
| T3 | Same trace on Redmi Go reports first-frame ≤ 2.0 s (relaxed `lowEnd` budget) |
| T4 | DevTools timeline of scan→verdict on Pixel 4a shows zero `Engine::BeginFrame → vsync` overruns |
| T5 | `scan_to_verdict_perf_test.dart` p95 ≤ 1.5 s; integration test green |
| T6 | `list_scroll_perf_test.dart` reports jank rate < 1% on Reports list (FE-32) and Recall inbox (FE-21) |
| T7 | `memory_soak_test.dart` reports steady-state RSS < 220 MB after 5 minutes on Pixel 4a |
| T8 | `device_class.classify()` returns `lowEnd` on Redmi Go and Nokia C20; `mid` on Pixel 4a; `high` on Pixel 7 |
| T9 | `MotionProfile.lowEndAuto` (FE-33) reads from `deviceClassProvider` and downgrades curves accordingly — verified by toggling `DeviceProbe` test override |
| T10 | `image_budget.yaml` enforced: a deliberately oversized asset (200 KB PNG) introduced to a PR fails CI |
| T11 | Custom lint flags any new `NetworkImage(` outside `apps/mobile/lib/perf/` |
| T12 | Custom lint flags any non-`const` constructor that could be `const` (uses `prefer_const_constructors` baseline) |
| T13 | Custom lint flags `ref.watch(someBigProvider)` that doesn't `.select(...)` for a single field — at least 5 hits on a known-bad commit |
| T14 | `--no-tree-shake-icons` baseline check: `flutter build apk --release --no-tree-shake-icons` size delta vs default ≤ 1.2 MB (icon font usage stays scoped) |
| T15 | `jank_baseline.json` updated and committed when a phase legitimately changes perf characteristics; PR description explains delta; reviewer signs off |

### Q&A Questions (8)

1. The frame budget is 16.6 ms (60 fps) but Pixel 4a refresh is 60 Hz and Pixel 7 is 90 Hz. Do we hold a single 16.6 ms target everywhere, or per-device 1/refresh? What's the practical impact on `jank_baseline.json` shape?
2. What are the dominant causes of jank in Flutter on Android? Rank them: garbage collection pauses, Skia/Impeller shader compilation jank, oversized image decode, Dart isolate scheduling, platform channel hops, layout passes triggered by `setState` over-watching.
3. Skia vs Impeller — given Flutter 3.22 ships Impeller as default on iOS but Skia remains the Android default, do our budgets differ per platform? When Impeller-Android lands stable, what re-baseline do we expect?
4. List virtualization: the Reports list (FE-32) can be 5k rows. What's the rule for choosing `ListView.builder` vs `SliverList` vs `ListView.separated`? Which one we picked and why, with `cacheExtent` value.
5. Image cache sizing: we cap at 50/100/200 entries per device class. Why not just `imageCache.maximumSizeBytes`? What's the failure mode if both are unbounded?
6. Cold start has three measurable phases — binary load (linker/dex/dyld), Dart isolate ready, first frame rasterized. Where does most of our budget go on Pixel 4a, and what is the lever for each phase if we have to shave 200 ms?
7. Platform channel overhead: `mobile_scanner` and ML Kit cross the channel per frame on the scanner. What's our amortized per-frame cost, and what's the threshold at which we'd refactor to a `FFI`/`Pigeon` direct path?
8. Frame scheduler: explain how `SchedulerBinding.scheduleFrameCallback` interacts with `addTimingsCallback`. Why do `addTimingsCallback` numbers sometimes appear 1 frame late, and how does our `perf_telemetry.dart` correct for that?

## Sign-off Gate
- [ ] Developer: 15 tests pass on local + CI; `mobile-perf.yml` green on three consecutive PR runs.
- [ ] Developer: 8 Q&A answered in the handoff doc.
- [ ] Developer: `jank_baseline.json` committed with traces from Pixel 4a, Redmi Go, iPhone SE 2.
- [ ] Developer: `docs/perf/PERF_BUDGET.md` cross-linked from every Layer 2/3/4 phase Risk Assessment.
- [ ] Reviewer: ran one full perf trace locally, attached DevTools screenshot to PR.
- [ ] Reviewer: confirmed `device_class.dart` consumed by FE-33 `MotionProfile.lowEndAuto` and FE-37 skeleton shimmer rate.
- [ ] Reviewer: confirmed CI required-to-merge on `main` for `mobile-perf.yml`.
- [ ] Tech lead: signed off on regression tolerance values in `jank_baseline.json`.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-40**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

**Tech Lead Signature**: ___________________________

---

**END OF FE-39 — DO NOT PROCEED WITHOUT APPROVAL**
