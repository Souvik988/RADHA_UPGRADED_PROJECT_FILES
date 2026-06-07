# Phase FE-01: Flutter Project Init, Flavors & CI Bootstrap

## Phase Metadata
- **Phase ID**: FE-01
- **Section**: Layer 1 — Foundation
- **Depends On**: — (root phase)
- **Blocks**: FE-02, FE-03, FE-04, FE-05, FE-06, FE-07, FE-08 (all foundation)
- **Estimated Duration**: 2-3 days
- **Complexity**: Medium

## Goal
Stand up the Flutter monorepo workspace under `apps/mobile`, wire it into the existing pnpm workspace, configure three build flavors (`dev`, `staging`, `prod`) with separate bundle IDs / app icons / API base URLs, and bootstrap a CI pipeline that builds + lints + tests on every push. By the end of this phase, a developer on a fresh machine can run `flutter run --flavor dev -t lib/main_dev.dart` and see a placeholder home screen pointing at `https://api-dev.radha.app`. CI is green on `main`.

This phase ships **zero user-facing UI**. It buys us repeatability — a property the next 39 phases depend on.

## Why This Phase Matters
- **Three flavors prevent the most common production accident**: pushing dev API URLs to the Play Store. Bundle IDs are physically separate, so the wrong build can't replace the right one.
- **CI runs from day one** so when FE-02 lands, golden tests already have a place to fail.
- **Monorepo wiring** means Flutter consumes types from the same `@radha/shared-types` package the backend exports — no drift between client and server contracts. (The Dart equivalent is generated from the TS source via `quicktype` in CI.)
- A clean foundation reduces cumulative interest. The rest of the roadmap leans on this.

## Prerequisites
- [ ] Backend: none — this phase is purely scaffolding.
- [ ] Earlier FE phases: none.
- [ ] Tooling: Flutter 3.22.0+, Dart 3.4+, Xcode 15.4 (macOS), Android Studio Hedgehog+, Java 17, Ruby 3.2 (for fastlane), pnpm 8.10+.
- [ ] Design assets: 3 sets of app icons (`ic_launcher_dev.png`, `ic_launcher_staging.png`, `ic_launcher_prod.png`) at 1024×1024.
- [ ] Secrets: Google services JSON for each flavor (placeholder OK for dev).

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/pubspec.yaml` | Dependencies + assets manifest |
| `apps/mobile/analysis_options.yaml` | Strict lints (very_good_analysis preset) |
| `apps/mobile/lib/main_dev.dart` | Dev entrypoint |
| `apps/mobile/lib/main_staging.dart` | Staging entrypoint |
| `apps/mobile/lib/main_prod.dart` | Prod entrypoint |
| `apps/mobile/lib/main.dart` | Shared bootstrap (calls runner with Flavor) |
| `apps/mobile/lib/app/app.dart` | Top-level `RadhaApp` widget (placeholder) |
| `apps/mobile/lib/app/flavor.dart` | Flavor enum + config getter |
| `apps/mobile/lib/app/bootstrap.dart` | `bootstrap()` — runs zone + error handlers + runApp |
| `apps/mobile/android/app/src/dev/google-services.json` | Dev FCM config |
| `apps/mobile/android/app/src/staging/google-services.json` | Staging FCM config |
| `apps/mobile/android/app/src/prod/google-services.json` | Prod FCM config |
| `apps/mobile/android/app/build.gradle.kts` | `productFlavors { dev, staging, prod }` block |
| `apps/mobile/ios/Runner/Configs/Dev.xcconfig` | Dev iOS config |
| `apps/mobile/ios/Runner/Configs/Staging.xcconfig` | Staging iOS config |
| `apps/mobile/ios/Runner/Configs/Prod.xcconfig` | Prod iOS config |
| `apps/mobile/Makefile` | `make run-dev`, `make build-prod`, `make test`, `make golden` |
| `apps/mobile/.fvmrc` | Pin Flutter SDK version (3.22.x) |
| `.github/workflows/mobile-ci.yml` | Lint + analyze + unit test on every push |
| `.github/workflows/mobile-release.yml` | Build + upload artifact on tag push (skeleton, real signing in FE-40) |
| `apps/mobile/test/smoke/app_boots_test.dart` | First test: app boots, no exceptions |
| `apps/mobile/README.md` | How to run each flavor, where icons live |

## Flavor Configuration

```dart
// lib/app/flavor.dart
enum Flavor { dev, staging, prod }

class FlavorConfig {
  final Flavor flavor;
  final String appName;        // 'RADHA Dev', 'RADHA Staging', 'RADHA'
  final String apiBaseUrl;     // https://api-dev.radha.app, ...
  final String wsBaseUrl;      // wss://api-dev.radha.app
  final bool   showFlavorBanner; // true except prod
  final String sentryDsn;      // empty for dev
  final bool   enableLogging;  // false for prod

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.showFlavorBanner,
    required this.sentryDsn,
    required this.enableLogging,
  });

  static FlavorConfig of(BuildContext context) =>
      ProviderScope.containerOf(context).read(flavorConfigProvider);
}
```

```dart
// lib/main_dev.dart
import 'app/bootstrap.dart';
import 'app/flavor.dart';

void main() => bootstrap(const FlavorConfig(
      flavor: Flavor.dev,
      appName: 'RADHA Dev',
      apiBaseUrl: 'https://api-dev.radha.app',
      wsBaseUrl: 'wss://api-dev.radha.app',
      showFlavorBanner: true,
      sentryDsn: '',
      enableLogging: true,
    ));
```

```dart
// lib/app/bootstrap.dart
Future<void> bootstrap(FlavorConfig config) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      // forwarded to Sentry in FE-40
      debugPrint('FlutterError: ${details.exception}');
    };
    runApp(
      ProviderScope(
        overrides: [
          flavorConfigProvider.overrideWithValue(config),
        ],
        child: const RadhaApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}
```

## Android `productFlavors`

```kotlin
// android/app/build.gradle.kts
android {
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "RADHA Dev")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "RADHA Staging")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "RADHA")
        }
    }
}
```

Bundle IDs:
- `app.radha.mobile.dev`
- `app.radha.mobile.staging`
- `app.radha.mobile`

iOS counterparts via xcconfig + a `Runner.xcconfig` include chain.

## CI Pipeline Spec

```yaml
# .github/workflows/mobile-ci.yml
name: mobile-ci
on:
  push: { paths: ['apps/mobile/**', '.github/workflows/mobile-ci.yml'] }
  pull_request: { paths: ['apps/mobile/**'] }
jobs:
  analyze-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart format --output=none --set-exit-if-changed .
        working-directory: apps/mobile
      - run: flutter analyze --fatal-infos
        working-directory: apps/mobile
      - run: flutter test --coverage --reporter expanded
        working-directory: apps/mobile
      - uses: codecov/codecov-action@v4
        with: { files: apps/mobile/coverage/lcov.info }
```

Branch protection on `main`: this workflow must be green to merge.

## Visual Behaviour
This phase ships placeholder UI only. The placeholder home screen shows:

| State | Visual |
|---|---|
| **First boot** | Solid M3 surface color, centered Lottie spinner (radha_logo_loop.json), 24sp text "RADHA — booting…" |
| **Booted** | Full-screen Material 3 scaffold, AppBar title = `FlavorConfig.appName`, body = "Foundation: FE-01 ✓" centered |
| **Dev/staging only** | Top-right banner badge "DEV" / "STAGING" rotated 45° (standard `Banner` widget) |
| **Tap home** | Light haptic + ripple (proves haptics package wires correctly) |
| **Long-press home** | Show flavor diagnostic dialog: API URL, build number, Flutter version |
| **Network down at boot** | Same scaffold, no error (no API calls yet — that's FE-06) |
| **Dark mode toggle (system)** | Surface flips to dark M3 surface within 200ms |
| **Reduced motion** | Lottie boot loop replaced by static image |

Eight states, all from a screen that ships no real feature. Sets the bar.

## Animations
- **Boot Lottie**: `assets/lottie/radha_logo_loop.json` — 60-frame loop, 1.2 s cycle. Total motion budget on this screen: < 60 KB.
- **Banner reveal**: 200 ms `motion.normal`, opacity 0→1 + scale 0.95→1.0. Skipped if reduced motion.
- **No Hero on this screen** — Hero choreography starts in FE-04/FE-05.

## Accessibility
- Placeholder home has `Semantics(label: 'RADHA, foundation phase booted')`.
- Lottie has `excludeSemantics: true` and a sibling `Semantics(label: 'Loading')`.
- Dynamic type: text uses `Theme.of(context).textTheme.titleLarge` — scales with system text size.
- `MediaQuery.disableAnimationsOf(context)` honoured: when true, Lottie replaced by static frame 0.
- High contrast: surface colors come from `flex_color_scheme` — no hardcoded hex.
- Banner is decorative; screen reader skips it via `ExcludeSemantics`.

## Testing
- **Widget test** `app_boots_test.dart`: pump `RadhaApp(flavor: dev)`, expect "Foundation: FE-01 ✓" finder. No uncaught exceptions.
- **Widget test** flavor-banner-test: dev flavor → finds `Banner`; prod flavor → no `Banner`.
- **Golden test** placeholder-home-light + placeholder-home-dark + placeholder-home-rtl. Generates 3 baseline PNGs in `test/goldens/`.
- **Build test** (CI matrix): `flutter build apk --flavor dev --debug` succeeds on Linux runner; `flutter build ios --flavor dev --no-codesign` on macOS runner (added in FE-40, skipped here).
- **Coverage gate**: ≥ 80% on `lib/app/**`. Bootstrap is small; this is achievable.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| iOS xcconfig flavor wiring breaks signed builds | Medium | Keep `Runner-Bridging-Header.h` un-flavored; flavors only swap `Configurations/*.xcconfig`. Document in README. |
| `google-services.json` for prod committed by mistake | Low/Critical | `.gitignore` real `google-services.json`; commit `.template.json` only; CI fails if real file detected. |
| Flutter SDK version drift between dev machines | High | `.fvmrc` + `pubspec.yaml` `environment.flutter` constraint + CI version check. |
| `flutter_localizations` heavy on cold start | Low | Defer locale loading to FE-35; only English bundled in FE-01. |
| `widgetbook` adds 3+ MB to app | n/a | `widgetbook` is a separate `apps/mobile_widgetbook` target — never shipped to users. |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | `flutter pub get` resolves clean on a fresh checkout (no warnings). |
| T2 | `flutter analyze --fatal-infos` exits 0 on `apps/mobile/lib/`. |
| T3 | `dart format --output=none --set-exit-if-changed .` passes. |
| T4 | `flutter run --flavor dev -t lib/main_dev.dart` launches on Pixel 4a emulator and shows "RADHA Dev" app bar within 5 s. |
| T5 | `flutter run --flavor staging -t lib/main_staging.dart` launches with bundle id `app.radha.mobile.staging`. |
| T6 | `flutter run --flavor prod -t lib/main_prod.dart` launches with bundle id `app.radha.mobile` and **no** flavor banner. |
| T7 | `flutter build apk --flavor prod --release --no-shrink` produces an APK ≤ 35 MB (gate target; relaxed if Lottie not stripped yet). |
| T8 | All three flavors install side-by-side on a single device without uninstalling each other. |
| T9 | `flutter test` runs `app_boots_test.dart`, `flavor_banner_test.dart`, golden tests — all pass. |
| T10 | `flutter test --coverage` shows ≥ 80% on `lib/app/**`. |
| T11 | CI workflow `mobile-ci.yml` is green on a sample PR. |
| T12 | CI fails when `flutter analyze` reports any new `info`. |
| T13 | Long-pressing the home placeholder shows the diagnostic dialog with the correct API URL for that flavor. |
| T14 | `MediaQuery.disableAnimations` set to true via accessibility settings: Lottie loop is not running (verified by `tester.binding.framePolicy`). |
| T15 | Cold start time on Pixel 4a (release build, prod flavor) ≤ 1.5 s from tap to first frame, measured with `flutter run --profile --trace-startup`. |

### Q&A Questions (8)

1. Why three flavors instead of a single `--dart-define=ENV=…`? Trade-offs?
2. How does the Dart-side `FlavorConfig` stay in sync with Android's `applicationIdSuffix` and iOS's `BUNDLE_IDENTIFIER`?
3. What is the exact procedure for adding a new top-level dependency (e.g. `dio`)? Who reviews? Where does the constraint go?
4. How do you run a full clean rebuild on a corrupted Flutter project (the right order: `flutter clean`, `pod deintegrate`, `pub get`, `pod install`)?
5. Why is `widgetbook` a separate app target instead of a debug-mode toggle inside the main app?
6. How does CI prevent a PR from regressing app size by, say, 5 MB? (Hint: not in this phase — but who owns it later?)
7. What is the rollback plan if a Flutter SDK upgrade (e.g. 3.22 → 3.23) breaks goldens?
8. How do production crash reports route to Sentry given that the DSN is set per-flavor?

## Sign-off Gate
- [ ] Developer: 15 tests pass on local + CI.
- [ ] Developer: 8 Q&A answered in the handoff doc.
- [ ] Developer: README walks a new engineer from `git clone` to `flutter run --flavor dev` in ≤ 10 minutes.
- [ ] Reviewer: ran each flavor on a real device.
- [ ] Reviewer: confirmed no real `google-services.json` is committed.
- [ ] Reviewer: confirmed CI is required-to-merge on `main`.

**Developer Signature**: ___________________________

**☐ APPROVED — Proceed to FE-02**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF FE-01 — DO NOT PROCEED WITHOUT APPROVAL**
