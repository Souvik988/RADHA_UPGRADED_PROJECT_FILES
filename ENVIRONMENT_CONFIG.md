# RADHA Mobile — Environment & Flavor Configuration

> **Scope**: How `apps/mobile/` resolves environment-specific configuration (API URLs, Sentry DSN, FCM project, feature toggles) across the three Flutter build flavors. Implements the contracts referenced by `FRONTEND_PHASES/FE-01_PHASE.md` and consumed by every other FE phase. Companion to `CI_CD_PIPELINE.md` (which builds these flavors) and `ASSET_PIPELINE.md` (which keeps assets shared across them).

---

## 1. Three flavors — locked

There are exactly three flavors. New environments are not added without an architecture review.

| Property | `dev` | `staging` | `prod` |
|---|---|---|---|
| Bundle ID (Android) | `app.radha.mobile.dev` | `app.radha.mobile.staging` | `app.radha.mobile` |
| Bundle ID (iOS) | `app.radha.mobile.dev` | `app.radha.mobile.staging` | `app.radha.mobile` |
| App name | `RADHA Dev` | `RADHA Staging` | `RADHA` |
| API base URL | `https://api-dev.radha.app` | `https://api-staging.radha.app` | `https://api.radha.app` |
| WebSocket URL | `wss://api-dev.radha.app` | `wss://api-staging.radha.app` | `wss://api.radha.app` |
| CDN | `https://cdn-dev.radha.app` | `https://cdn-staging.radha.app` | `https://cdn.radha.app` |
| Sentry environment | `dev` | `staging` | `prod` |
| Sentry DSN | DSN-A (dev project) | DSN-B (staging project) | DSN-C (prod project) |
| FCM project | `radha-dev` | `radha-staging` | `radha-prod` |
| Show flavor banner | yes | yes | no |
| Verbose logging | yes (`Level.verbose`) | yes (`Level.info`) | no (`Level.warning`) |
| Crashlytics enabled | no | yes | yes |
| Performance monitoring | no | yes | yes |
| Analytics enabled | no | yes | yes |
| Cert pinning enforced | no (warn-only) | yes | yes (hard fail) |
| Allow http:// schemes | yes | no | no |
| Default log sink | console + Logcat/Console.app | console + Sentry breadcrumbs | Sentry breadcrumbs only |
| Quota cap (FE-46 mirror) | 10× prod | 1× prod | 1× prod |
| Mock OTP | yes (always `123456`) | no | no |
| Feature flag overrides allowed | yes (debug menu) | yes (debug menu) | no |

> The DSN values, FCM project IDs, and similar are stored in the per-flavor env files (§4) — never inlined in source. The table above states *which* DSN goes where, not *what* it is.

---

## 2. Why `envied` (ADR-007)

`envied` is the chosen mechanism for compile-time injection of these values. Its alternatives were considered and rejected:

| Option | Verdict | Rationale |
|---|---|---|
| `envied` (chosen) | ✅ | Generates strongly-typed Dart classes from `.env` files at build time. Values are baked into the obfuscated binary; no plain-text strings shipped. Works with `flutter build` flavors out of the box. |
| `flutter_dotenv` | ❌ | Reads plain-text `.env` from `assets/` at runtime. The asset is unobfuscated and trivially extractable from any APK. Disqualifying for prod. |
| `--dart-define` | ❌ for prod | Works, but every CI invocation must re-list every key — drift between dev/staging/prod is silent. We use it only for `SENTRY_RELEASE` (dynamic, build-stamped). |
| Firebase Remote Config | ❌ for boot config | Network-dependent; cold start cannot block on it. Used later (FE-46/47) for runtime feature flags, never for API URL or DSN. |

**ADR-007** lives at `docs/adr/007-envied-for-env-injection.md`. Any deviation requires an ADR-007-superseded note + sign-off from the mobile tech lead.

---

## 3. Env file structure

```
apps/mobile/
  env/
    .gitignore                # ignores *.env (real values), tracks *.env.template
    dev.env                   # gitignored — real dev values
    staging.env               # gitignored — real staging values
    prod.env                  # gitignored — real prod values
    dev.env.template          # committed — placeholder values
    staging.env.template      # committed
    prod.env.template         # committed
  lib/
    config/
      env/
        env_dev.dart          # @Envied annotation — generated impl in env_dev.g.dart
        env_staging.dart
        env_prod.dart
        env.dart              # abstract Env contract
        env_provider.dart     # Riverpod provider that exposes the active Env
```

`apps/mobile/env/.gitignore`:

```
# Real env files — never commit
*.env
!*.env.template
```

`apps/mobile/env/dev.env.template`:

```dotenv
# Copy to dev.env and populate. Real values live in 1Password vault `radha-mobile-env`.
API_BASE_URL=https://api-dev.radha.app
WS_BASE_URL=wss://api-dev.radha.app
CDN_BASE_URL=https://cdn-dev.radha.app
SENTRY_DSN=
SENTRY_ENV=dev
FCM_PROJECT_ID=radha-dev
FCM_API_KEY=
FCM_APP_ID=
FCM_SENDER_ID=
ENABLE_CRASHLYTICS=false
ENABLE_ANALYTICS=false
ENABLE_PERF=false
LOG_LEVEL=verbose
ALLOW_HTTP=true
CERT_PINNING_MODE=warn
MOCK_OTP=true
```

The staging and prod templates have the same shape with appropriate hostnames; staging has `MOCK_OTP=false`, `CERT_PINNING_MODE=enforce`, `ENABLE_CRASHLYTICS=true`. Prod has all telemetry on, `ALLOW_HTTP=false`, `LOG_LEVEL=warning`.

---

## 4. Per-flavor `envied` class

```dart
// lib/config/env/env.dart
abstract class Env {
  String get apiBaseUrl;
  String get wsBaseUrl;
  String get cdnBaseUrl;
  String get sentryDsn;
  String get sentryEnv;
  String get fcmProjectId;
  String get fcmApiKey;
  String get fcmAppId;
  String get fcmSenderId;
  bool   get enableCrashlytics;
  bool   get enableAnalytics;
  bool   get enablePerf;
  String get logLevel;
  bool   get allowHttp;
  String get certPinningMode;
  bool   get mockOtp;
}
```

```dart
// lib/config/env/env_dev.dart
import 'package:envied/envied.dart';
import 'env.dart';
part 'env_dev.g.dart';

@Envied(path: 'env/dev.env', requireEnvFile: true, obfuscate: true)
final class EnvDev implements Env {
  @EnviedField(varName: 'API_BASE_URL') static final String _apiBaseUrl = _EnvDev._apiBaseUrl;
  @EnviedField(varName: 'WS_BASE_URL')  static final String _wsBaseUrl  = _EnvDev._wsBaseUrl;
  @EnviedField(varName: 'CDN_BASE_URL') static final String _cdnBaseUrl = _EnvDev._cdnBaseUrl;
  @EnviedField(varName: 'SENTRY_DSN')   static final String _sentryDsn  = _EnvDev._sentryDsn;
  @EnviedField(varName: 'SENTRY_ENV')   static final String _sentryEnv  = _EnvDev._sentryEnv;
  @EnviedField(varName: 'FCM_PROJECT_ID') static final String _fcmProjectId = _EnvDev._fcmProjectId;
  @EnviedField(varName: 'FCM_API_KEY')   static final String _fcmApiKey   = _EnvDev._fcmApiKey;
  @EnviedField(varName: 'FCM_APP_ID')    static final String _fcmAppId    = _EnvDev._fcmAppId;
  @EnviedField(varName: 'FCM_SENDER_ID') static final String _fcmSenderId = _EnvDev._fcmSenderId;
  @EnviedField(varName: 'ENABLE_CRASHLYTICS') static final bool _enableCrashlytics = _EnvDev._enableCrashlytics;
  @EnviedField(varName: 'ENABLE_ANALYTICS')   static final bool _enableAnalytics   = _EnvDev._enableAnalytics;
  @EnviedField(varName: 'ENABLE_PERF')        static final bool _enablePerf        = _EnvDev._enablePerf;
  @EnviedField(varName: 'LOG_LEVEL')          static final String _logLevel        = _EnvDev._logLevel;
  @EnviedField(varName: 'ALLOW_HTTP')         static final bool _allowHttp         = _EnvDev._allowHttp;
  @EnviedField(varName: 'CERT_PINNING_MODE')  static final String _certPinningMode = _EnvDev._certPinningMode;
  @EnviedField(varName: 'MOCK_OTP')           static final bool _mockOtp           = _EnvDev._mockOtp;

  @override String get apiBaseUrl => _apiBaseUrl;
  @override String get wsBaseUrl  => _wsBaseUrl;
  @override String get cdnBaseUrl => _cdnBaseUrl;
  @override String get sentryDsn  => _sentryDsn;
  @override String get sentryEnv  => _sentryEnv;
  @override String get fcmProjectId => _fcmProjectId;
  @override String get fcmApiKey    => _fcmApiKey;
  @override String get fcmAppId     => _fcmAppId;
  @override String get fcmSenderId  => _fcmSenderId;
  @override bool   get enableCrashlytics => _enableCrashlytics;
  @override bool   get enableAnalytics   => _enableAnalytics;
  @override bool   get enablePerf        => _enablePerf;
  @override String get logLevel          => _logLevel;
  @override bool   get allowHttp         => _allowHttp;
  @override String get certPinningMode   => _certPinningMode;
  @override bool   get mockOtp           => _mockOtp;
}
```

`env_staging.dart` and `env_prod.dart` are structurally identical, each annotated with their own `path:` and emitting their own generated `.g.dart`. `obfuscate: true` produces XOR-encoded literals so the constants are not greppable in the IPA/AAB.

The Riverpod provider:

```dart
// lib/config/env/env_provider.dart
final envProvider = Provider<Env>((ref) {
  throw UnimplementedError('Override in main_<flavor>.dart');
});
```

Each `main_<flavor>.dart` overrides:

```dart
ProviderScope(
  overrides: [envProvider.overrideWithValue(EnvDev())],
  child: const RadhaApp(),
);
```

Cross-flavor imports are physically prevented: `env_dev.dart` lives next to `env_dev.g.dart` and is referenced *only* from `main_dev.dart`. A custom-lint rule (`tool/lint/no_cross_flavor_env.dart`) flags any file outside `lib/config/env/env_<flavor>.dart` and `lib/main_<flavor>.dart` that imports a flavor-specific class. CI fails on violation.

---

## 5. iOS xcconfig chain

```
apps/mobile/ios/
  Flutter/
    Debug.xcconfig            # generated by Flutter
    Release.xcconfig
    Generated.xcconfig        # generated; gitignored
  Runner/
    Configs/
      Common.xcconfig         # PRODUCT_NAME-prefix-shared values
      Dev.xcconfig            # includes Common; sets PRODUCT_BUNDLE_IDENTIFIER, DISPLAY_NAME, ENV_TARGET=dev
      Staging.xcconfig
      Prod.xcconfig
    Runner.xcconfig           # picks Dev/Staging/Prod based on $(CONFIGURATION) suffix
```

`Runner/Configs/Dev.xcconfig`:

```text
#include "Common.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = app.radha.mobile.dev
DISPLAY_NAME              = RADHA Dev
ENV_TARGET                = dev
GOOGLE_SERVICE_INFO_PLIST_PATH = $(SRCROOT)/Runner/Configs/dev/GoogleService-Info.plist
```

`Runner.xcconfig` selects via `Debug-dev.xcconfig`, `Release-dev.xcconfig`, etc. — Xcode build configurations are named `Debug-dev`, `Release-dev`, `Debug-staging`, `Release-staging`, `Debug-prod`, `Release-prod` (six total). Flutter's `--flavor` flag maps to these via `xcode_backend.sh` wiring kept in `apps/mobile/ios/Runner.xcodeproj`.

`Info.plist` reads `$(DISPLAY_NAME)` and `$(PRODUCT_BUNDLE_IDENTIFIER)` from the active xcconfig — so flipping flavors never edits the plist.

---

## 6. Android `productFlavors`

`apps/mobile/android/app/build.gradle.kts`:

```kotlin
android {
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "RADHA Dev")
            manifestPlaceholders["appAuthRedirectScheme"] = "app.radha.mobile.dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
            resValue("string", "app_name", "RADHA Staging")
            manifestPlaceholders["appAuthRedirectScheme"] = "app.radha.mobile.staging"
        }
        create("prod") {
            dimension = "env"
            // no suffix — production keeps the canonical id
            resValue("string", "app_name", "RADHA")
            manifestPlaceholders["appAuthRedirectScheme"] = "app.radha.mobile"
        }
    }
}
```

`AndroidManifest.xml` reads `@string/app_name` so the launcher label flips per flavor without copy/paste. `applicationId` is set in `defaultConfig.applicationId = "app.radha.mobile"` and the suffix above produces `.dev` / `.staging` / canonical.

---

## 7. Per-flavor Firebase config

```
apps/mobile/android/app/src/dev/google-services.json        # dev FCM project, gitignored
apps/mobile/android/app/src/staging/google-services.json    # staging, gitignored
apps/mobile/android/app/src/prod/google-services.json       # prod, gitignored
apps/mobile/android/app/src/dev/google-services.json.template     # committed
apps/mobile/android/app/src/staging/google-services.json.template # committed
apps/mobile/android/app/src/prod/google-services.json.template    # committed

apps/mobile/ios/Runner/Configs/dev/GoogleService-Info.plist        # dev FCM, gitignored
apps/mobile/ios/Runner/Configs/staging/GoogleService-Info.plist    # gitignored
apps/mobile/ios/Runner/Configs/prod/GoogleService-Info.plist       # gitignored
apps/mobile/ios/Runner/Configs/dev/GoogleService-Info.plist.template     # committed
apps/mobile/ios/Runner/Configs/staging/GoogleService-Info.plist.template # committed
apps/mobile/ios/Runner/Configs/prod/GoogleService-Info.plist.template    # committed
```

Templates have placeholder bundle IDs and 0-prefixed sender IDs so a clean clone doesn't accidentally crash with "Default FirebaseApp is not initialized." A pre-build script (`apps/mobile/tool/firebase/check_google_services.sh`) refuses to build if a real `google-services.json` is missing for the active flavor.

---

## 8. Build commands per flavor

| Goal | Command |
|---|---|
| Run on a connected dev device (debug) | `flutter run --flavor dev -t lib/main_dev.dart` |
| Run staging | `flutter run --flavor staging -t lib/main_staging.dart` |
| Run prod (locally — debug build only; release is CI-only) | `flutter run --flavor prod -t lib/main_prod.dart` |
| Build dev APK | `flutter build apk --flavor dev -t lib/main_dev.dart` |
| Build staging AAB (signed, obfuscated) | `flutter build appbundle --release --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols/staging` |
| Build prod AAB (CI only) | see `CI_CD_PIPELINE.md` §6, §7 — never run from a developer laptop |
| Build dev IPA (no codesign) | `flutter build ipa --flavor dev -t lib/main_dev.dart --no-codesign` |
| Build staging IPA (signed) | `flutter build ipa --release --flavor staging -t lib/main_staging.dart --obfuscate --split-debug-info=build/symbols/staging-ios --export-options-plist=ios/ExportOptions.plist` |
| Run integration tests on prod-shaped data | `flutter test integration_test --flavor staging` (we never test against prod) |

The `Makefile` from FE-01 wraps the common ones: `make run-dev`, `make run-staging`, `make build-staging`, `make build-prod-ci`.

---

## 9. Bundle ID isolation

dev, staging and prod **must** install side-by-side on a single device. This is non-negotiable because:

- QA runs prod and staging at the same time to compare behaviour.
- Engineers debug a customer-reported bug on the prod build while iterating in dev.
- Sales demo the prod build while sandboxing the staging build for prospects.

The asserts:

- Android `applicationId` differs by suffix → guaranteed.
- iOS `PRODUCT_BUNDLE_IDENTIFIER` differs in xcconfig → guaranteed.
- App icons are visually distinct (see `ASSET_PIPELINE.md` §10) so they're identifiable in the launcher grid.

A CI job in `mobile-ci.yml` runs `tool/ci/assert_bundle_isolation.sh` which boots an emulator, installs all three APKs, and verifies `pm list packages | grep app.radha.mobile` returns three lines. Failure blocks merge.

---

## 10. Secret rotation

| Secret | Source | Rotation |
|---|---|---|
| `dev.env`, `staging.env`, `prod.env` | 1Password vault `radha-mobile-env` (item per flavor) | Quarterly + on team-member off-boarding |
| Firebase per-flavor configs | Firebase consoles `radha-dev`, `radha-staging`, `radha-prod` | When admin SDK keys are rotated (yearly) |
| iOS GoogleService-Info.plist | Firebase consoles | Same |
| Android `google-services.json` | Firebase consoles | Same |
| Sentry DSNs | Sentry org `radha`, projects per-environment | Static — DSNs are public-keyed; no rotation needed unless project is recreated |
| FCM API keys | Firebase consoles | Yearly or on suspected leak |

Quarterly rotation drill (calendar event owned by mobile tech lead): regenerate the env files, update the 1Password items, rotate the GitHub Actions environment secrets (`DEV_ENV_FILE`, `STAGING_ENV_FILE`, `PROD_ENV_FILE` — see `CI_CD_PIPELINE.md` §11), trigger a fresh CI build to verify boot, post completion to `#mobile-deploys`.

---

## 11. Local dev workflow

```bash
# First-time setup
cd apps/mobile

# Pull env templates → real files
cp env/dev.env.template env/dev.env
cp env/staging.env.template env/staging.env

# Open 1Password (CLI) and populate values
op item get "radha-mobile-env / dev" --format json | jq -r '.fields[] | "\(.label)=\(.value)"' > env/dev.env

# Pull Firebase configs (script asks 1Password for the right doc)
bash tool/firebase/fetch_dev_configs.sh

# Verify env wires
flutter pub run build_runner build --delete-conflicting-outputs   # regenerates env_*.g.dart
flutter run --flavor dev -t lib/main_dev.dart
```

`prod.env` is **not** populated on developer machines except for the rare local release-debug session, which requires explicit tech-lead approval. Force of habit: developers should never carry `prod.env` on their laptops.

The `apps/mobile/.gitignore` and the workspace root `.gitignore` both list `*.env` and `!*.env.template`. CI runs `gitleaks` on every PR (see `CI_CD_PIPELINE.md` §11) to catch accidental commits.

---

## 12. Switching env at runtime — explicitly NOT supported

The flavor is compile-time. There is no in-app "switch to staging" menu. Switching environments requires uninstalling the current build and installing a different flavor APK/IPA — by design.

Reasons:

- A runtime switcher would mean *both* DSNs, *both* CDN URLs, *both* FCM projects had to ship in a single binary. That doubles attack surface and bloats the obfuscated code.
- Telemetry contamination: switching mid-session would tag prod events as staging or vice versa.
- DRY violation: every consumer of `Env` would need to invalidate caches on switch — an entire class of bugs avoided by the constraint.

A small **debug menu** in dev and staging lets engineers override individual feature flags (FE-47 territory) at runtime — but it cannot change `apiBaseUrl`, `wsBaseUrl`, `sentryDsn`, or `fcmProjectId`. Those four are locked to the active flavor.

---

## 13. Boot sequence — flavor → Env → app

```dart
// lib/main_dev.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = EnvDev();
  await bootstrap(env);
}
```

```dart
// lib/app/bootstrap.dart  (extends FE-01)
Future<void> bootstrap(Env env) async {
  // 1. Sentry — only if DSN present (dev DSN may be empty)
  if (env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((opts) {
      opts.dsn = env.sentryDsn;
      opts.environment = env.sentryEnv;
      opts.release = const String.fromEnvironment('SENTRY_RELEASE', defaultValue: 'dev-local');
    });
  }
  // 2. Firebase — uses google-services.json / GoogleService-Info.plist of the active flavor
  await Firebase.initializeApp();
  if (env.enableCrashlytics) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }
  // 3. Logging — level driven by env.logLevel
  Logger.root.level = _parseLevel(env.logLevel);
  // 4. Run app with envProvider override
  runApp(ProviderScope(
    overrides: [envProvider.overrideWithValue(env)],
    child: const RadhaApp(),
  ));
}
```

The boot order is the same in all three flavors — only the `Env` value differs. This keeps the test surface uniform.

---

## 14. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| **Real env file committed to git** | Medium (history shows engineers do it) | `.gitignore` enforced + nightly `gitleaks` scan against the diff between `main` and `develop`; pre-commit hook (`tool/git/pre-commit`) blocks any `*.env` outside the templates |
| **Prod env hot-loaded into a dev build** | Low/Critical | `envied`-generated classes are flavor-specific; cross-flavor import lint (`no_cross_flavor_env.dart`) is a custom-lint rule; CI fails on violation; runtime assert at `bootstrap()` checks `env.sentryEnv` matches the expected value derived from `String.fromEnvironment('FLAVOR')` |
| **Dev keystore committed** | Medium | `.gitignore` already lists `apps/mobile/android/app/upload-keystore.jks`; `gitleaks` rule `mobile-keystore` matches `.jks` and `.keystore` extensions |
| **Quarterly rotation skipped** | Medium | Calendar event owned by mobile tech lead; rotation step gated by checklist in `CI_CD_PIPELINE.md` §11; missed rotation surfaces in `secret-scan.yml` daily report after 95 days |
| **Firebase project mis-mapping** | Low | `tool/firebase/check_google_services.sh` parses the active config and asserts `project_id` matches `Env.fcmProjectId`; runs as a pre-build hook |
| **Bundle ID collision with another tenant's white-label** | Low | Bundle IDs are reserved at Apple Developer + Google Play Console; reservation kept in `radha-mobile-release` 1Password vault so the next white-label does not accidentally collide |
| **Switching flavor in CI by editing wrong workflow** | Low | Each workflow lists its `environment:` (`dev`/`staging`/`prod`) which scopes the secrets; a workflow named `*deploy-staging*` cannot accidentally pull `PROD_ENV_FILE` because it isn't in the staging environment |

---

## 15. Cross-references

- `CI_CD_PIPELINE.md` — how each flavor is built and deployed
- `LOCALIZATION_STRATEGY.md` — locales are flavor-independent (same 6 across all flavors)
- `ASSET_PIPELINE.md` — assets are shared across flavors except launcher icons
- `FRONTEND_PHASES/FE-01_PHASE.md` — original flavor + bootstrap spec
- `FRONTEND_PHASES/FE-40_PHASE.md` — release engineering, signing, store submission
