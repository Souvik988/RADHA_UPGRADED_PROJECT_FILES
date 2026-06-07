# RADHA Mobile — Observability Plan

> **Version**: `v1.0.0`
> **Last updated**: 2026-05-17
> **Owner**: Frontend Tech Lead (instrumentation) · SRE Lead (alerting + dashboards) · Privacy Officer (PII gates)
> **Status**: **Locked for v1.** Stack changes require an ADR; sampling and alerting thresholds are tuneable per release.

This document defines crash reporting, performance monitoring, analytics, and logging for the RADHA Flutter app (`apps/mobile/`). It is the single source of truth for what the app captures, what it does **not** capture, where the data lives, who watches it, and how a release is gated against observability health.

Constrained by:
- **ADR-008** — Sentry chosen for crash + trace observability.
- **ADR-001** — 40-phase shape; instrumentation lands in FE-40 (release engineering) for full wiring.
- `FRONTEND_QA_SYSTEM.md` — Rung 11 (release verification) gates against observability metrics.
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-release.yml` uploads symbols and gates crash-free.
- `RADHA_CLIENT_OVERVIEW.md` — defines the privacy bar.
- `LOCALIZATION_STRATEGY.md` — ARB key for the analytics opt-out toggle.

---

## 1. Stack

| Layer | Tool | Plan tier | Purpose |
|---|---|---|---|
| Crash reporting | **Sentry** (`sentry_flutter`) | Team | Primary error tracking, release health, performance traces |
| Performance monitoring | **Firebase Performance** | Free | Cold start, network call duration, custom traces (staging + prod only) |
| Analytics events | **Firebase Analytics** | Free | Funnel + retention + feature usage |
| Backend analytics aggregation | BE-29 service | n/a | Cohort + retention dashboards (privacy-respecting) |
| In-app logging | **`package:logging`** | n/a | Structured logging with levels, gated per flavor |
| Native crashes | Sentry native SDKs | Team | Android (Java/Kotlin) + iOS (Swift/Obj-C) crashes auto-routed |

### 1.1 Why this split

- **Sentry primary**: Best-in-class for Flutter (auto-instrumentation of `runZonedGuarded`, `FlutterError`, `PlatformDispatcher`), source-mapped stack traces, release health (sessions/users), performance traces, and breadcrumbs.
- **Firebase Performance supplementary**: Covers cold-start histograms and the network-call distribution graph that Sentry cannot match. Free tier is sufficient.
- **Firebase Analytics for events**: Funnel + retention. Already used by BE-29's analytics aggregator.
- **No custom analytics SDK in v1**: One vendor for events. We can add an aggregator (BE-29) without changing the client SDK.

### 1.2 Three-layer error boundary

The app installs three error handlers, in order:

```dart
// lib/app/bootstrap.dart  (FE-40 wires real Sentry; FE-01 stubbed)
Future<void> bootstrap(FlavorConfig config) async {
  // 1. Initialize Sentry FIRST. If init fails, we still capture the failure.
  await SentryFlutter.init((options) {
    options.dsn = config.sentryDsn;
    options.environment = config.flavor.name;
    options.release = '${kAppVersion}+${kBuildNumber}';
    options.tracesSampleRate = config.flavor == Flavor.prod ? 0.10 : 1.0;
    options.maxBreadcrumbs = 50;
    options.beforeSend = _redactPiiBeforeSend;
    options.attachStacktrace = true;
    options.enableAutoSessionTracking = true;
    options.sessionTrackingIntervalMillis = 30000;
  });

  // 2. Wrap runApp in a guarded zone (Dart async errors).
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 3a. Flutter framework errors.
    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      await Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
        hint: Hint.withMap({'framework': true}),
      );
    };

    // 3b. Platform dispatcher errors (iOS/Android native -> Dart bubbled).
    PlatformDispatcher.instance.onError = (error, stack) {
      Sentry.captureException(error, stackTrace: stack);
      return true; // handled
    };

    runApp(ProviderScope(
      overrides: [flavorConfigProvider.overrideWithValue(config)],
      child: const RadhaApp(),
    ));
  }, (error, stack) async {
    await Sentry.captureException(error, stackTrace: stack);
  });
}
```

Three layers cover:
- Synchronous + async Dart errors (`runZonedGuarded`).
- Flutter framework rendering errors (`FlutterError.onError`).
- Native errors propagated through the platform channel (`PlatformDispatcher.instance.onError`).

Each layer captures independently. Order matters because each surfaces a different class of failure.

---

## 2. What gets captured

### 2.1 Always captured

- **Every uncaught Dart exception** → Sentry with full stack and breadcrumb tail.
- **Every uncaught native exception** (Android Java/Kotlin, iOS Swift/Obj-C) → Sentry via the native SDK auto-init included in `sentry_flutter`.
- **Every BE-46 quota error** (HTTP 429) → custom Sentry tag `quota_breach: <quota_name>` for usage analysis.
- **Every Drift transaction failure** → Sentry breadcrumb (level `error`) plus a captured exception when the failure crosses the screen surface.
- **Every navigation transition** → Firebase Analytics `screen_view` event + Sentry breadcrumb (level `info`).
- **Every API call duration > 500 ms** → Firebase Performance trace `api.<endpoint>` with method + status code attributes.
- **Every cold start** → Firebase Performance trace `_app_start` (auto) + custom analytics event `app_cold_start`.
- **Every authenticated session start** → Sentry session tracking auto-marks the session.
- **Every crash report dispatched** → confirmation analytics event `crash_report_sent`.

### 2.2 NOT captured (privacy)

The app **must not** transmit any of the following:

- **PII fields**: phone number (mobile), email, OTP code, password, JWT tokens, refresh tokens, secure-storage keys.
- **Photo bytes**: only metadata (dimensions, byte size, MIME type) is allowed.
- **Drift query parameters that may contain user input**: only the table name is logged, never the row values.
- **Raw scan codes (EAN/barcode)**: only the verdict outcome (`good | warn | bad`) is logged. EAN itself is high-sensitivity (it implies the user's purchase pattern).
- **Free-text inputs**: shopping list items, allergen notes, GRN remarks are not logged.
- **Location**: the app uses no geolocation; if added in v2, must opt-in explicitly.
- **Device unique identifiers**: hashed `installation_id` only; never IDFA or Android ID raw.

### 2.3 Redaction implementation

A Dio response interceptor redacts request and response bodies before any logger sees them:

```dart
// lib/core/logging/redactor.dart
class PiiRedactor {
  static const _sensitiveKeys = {
    'mobile', 'phone', 'phoneNumber', 'email',
    'otp', 'otpCode', 'password', 'token', 'accessToken', 'refreshToken',
    'ean', 'barcode', 'scanCode',
    'remark', 'note', 'address', 'pincode',
  };

  static dynamic redact(dynamic value) {
    if (value is Map) {
      return value.map((k, v) =>
        _sensitiveKeys.contains(k.toString())
          ? MapEntry(k, '<redacted>')
          : MapEntry(k, redact(v)));
    }
    if (value is List) return value.map(redact).toList();
    return value;
  }
}
```

The `_redactPiiBeforeSend` Sentry hook applies the same logic to:
- `event.request.data`
- `event.request.headers` (drops `Authorization` + `Cookie`)
- `event.extra`
- breadcrumb data fields

A unit test in `test/observability/redactor_test.dart` enforces a fixture-based regression: a request with every banned key returns a redacted form.

---

## 3. Sampling strategy

| Signal | Sampling rate | Notes |
|---|---|---|
| **Crashes** | **100%** (always) | Cannot sample down — any missed crash is a missed bug. |
| **Performance traces (prod)** | **10%** | Configurable via remote config (BE-47 feature flag) without an app release. |
| **Performance traces (staging)** | **100%** | Full visibility on staging where load is low. |
| **Performance traces (dev)** | **0%** | No traces from dev to keep Sentry quota clean. |
| **Breadcrumbs** | **last 50** retained per session | Beyond 50 the oldest evicted. Tuned to fit one user journey. |
| **Analytics events** | **100%** | Event-driven, low volume per user. No high-volume metric events. |
| **Native crashes** | **100%** | Same gate as Dart crashes. |

### 3.1 Why 10% prod traces

Sentry's Team plan caps traces at 100k/month. With ~50,000 sessions/month and ~40 traceable spans per session, 100% would be 2M traces/month. 10% × 2M = 200k, still over cap. The 10% rate plus span-level filtering (only traces longer than 500 ms) keeps us at ~80k traces/month with headroom.

### 3.2 Adaptive sampling

If Sentry quota reaches **80%**, the app **degrades automatically**:
- Performance traces: 10% → 1%
- Breadcrumbs: 50 → 20
- Crashes: still 100% (never lowered)

Driven by a remote-config flag `obs.sample_rate_multiplier` that the SRE can flip without an app update.

---

## 4. Symbol management

### 4.1 What and where

- **iOS**: dSYM bundles produced by `flutter build ipa --release` are uploaded to Sentry via `sentry-cli upload-dif` in `mobile-release.yml`.
- **Android**: `mapping.txt` (R8 ProGuard map) and native debug symbols (NDK builds, if any) are uploaded via the Sentry Gradle plugin.
- **Flutter**: `app.android-arm64.symbols`, `app.android-arm.symbols`, `app.android-x64.symbols`, `app.ios.symbols` are uploaded for stack-trace symbolication of Dart frames.

### 4.2 Retention

- Sentry: **90 days** rolling window (the team plan default).
- Cold archival: dSYMs and mapping files are pushed to S3 (`s3://radha-symbols-archive/<flavor>/<version>/`) for **1 year** in case Sentry cannot resolve a delayed crash report.

### 4.3 Verification

The release pipeline fails if symbol upload returns < 100% upload-success. A Sentry "missing debug files" warning on a release blocks promotion to prod (FE-40 gate).

---

## 5. Analytics event taxonomy

All events follow the convention `<surface>_<action>_<outcome>`. Surfaces are screen-level domains, actions are verbs, outcomes are terminal states.

### 5.1 Naming rules

- **All lowercase, snake_case.**
- **Three tokens** unless the action is intransitive (e.g. `app_cold_start`).
- **No tense markers** (always present-perfect): `purchase_success`, not `purchased`.
- **No abbreviations** the SRE doesn't recognize.

### 5.2 Reserved event prefixes

| Prefix | Domain |
|---|---|
| `app_*` | Application-level (cold start, foreground, background, crash) |
| `auth_*` | Authentication (OTP, refresh, logout) |
| `onboarding_*` | First-run flow |
| `paywall_*` | Subscription, payments |
| `scan_*` | Scanner, capture, output |
| `product_*` | Product detail, save, share |
| `expiry_*` | Expiry calendar, mark consumed |
| `recall_*` | Recall inbox, acknowledge |
| `business_*` | Business dashboard, OHS |
| `grn_*` | Goods Received Note flow |
| `inventory_*` | Stock in/out |
| `task_*` | Tasks |
| `report_*` | Reports + exports |
| `crash_*` | Crash report metadata |
| `sync_*` | Offline queue, conflict |
| `family_*` | Family invite + accept |
| `allergen_*` | Allergen profile |

### 5.3 Required properties on every event

Every event includes the following properties (auto-attached via `RadhaAnalytics`):

```text
userId        : String  -- SHA-256 hash of the user's tenant_id+user_id (BE-29 keys cohort by this)
tenantId      : String  -- raw tenant id (multi-tenant scoping; not PII)
flavor        : String  -- dev | staging | prod
appVersion    : String  -- e.g. 1.4.2+812
platform      : String  -- ios | android
osVersion     : String  -- e.g. "iOS 17.5", "Android 14"
deviceClass   : String  -- low | mid | high (from device_info_plus)
locale        : String  -- e.g. "en_IN", "hi_IN"
sessionId     : String  -- per-session UUID
networkType   : String  -- wifi | cellular | offline (snapshot at event time)
```

### 5.4 Banned properties

The `RadhaAnalytics` wrapper rejects any property whose key matches the redactor's banned set (mobile, email, otp, password, token, ean, barcode, scanCode, remark, note, address, pincode). Attempting to send one throws `BannedPropertyError` in debug, silently drops in release with a Sentry warning breadcrumb.

### 5.5 Example events

```text
onboarding_segment_select   { segmentId: "consumer-premium" }
onboarding_segment_confirm  { segmentId: "consumer-premium", durationMs: 12340 }
auth_otp_request_send       { method: "sms", country: "IN" }
auth_otp_verify_success     { attempts: 1, durationMs: 4200 }
auth_otp_verify_fail        { attempts: 3, reason: "invalid_code" }
scan_capture_attempt        { source: "camera" }
scan_capture_success        { verdict: "good", durationMs: 820, source: "camera" }
scan_capture_fail           { reason: "low_light", durationMs: 5000 }
paywall_view                { tier: "consumer_99" }
paywall_tier_purchase       { tier: "consumer_99", currency: "INR", amount: 99 }
paywall_purchase_success    { tier: "consumer_99", durationMs: 12000 }
paywall_purchase_fail       { tier: "consumer_99", reason: "card_declined" }
recall_view                 { recallId: "<uuid>" }
recall_acknowledge          { recallId: "<uuid>", durationMs: 8200 }
crash_report_sent           { eventId: "<sentry-id>" }
app_cold_start              { durationMs: 1340 }
app_crash                   { type: "flutter_error" | "platform" | "zone" }
sync_outbox_drain           { itemCount: 14, durationMs: 3200, failed: 0 }
```

### 5.6 Funnel keys

The retention dashboard (BE-29) keys cohorts by:

- **Activation funnel**: `app_cold_start` → `auth_otp_verify_success` → `onboarding_segment_confirm` → first feature event (`scan_capture_success` or `business_dashboard_view`).
- **Subscription funnel**: `paywall_view` → `paywall_tier_purchase` → `paywall_purchase_success`.
- **Engagement funnel**: weekly active users defined as ≥ 1 of `scan_capture_success | business_dashboard_view | grn_submit_success | task_complete_success | recall_acknowledge` per 7-day rolling window.

---

## 6. Critical events

The following events **must always fire** and **must always succeed** (i.e. dispatched even if the analytics dispatcher itself errors). They are queued via the offline outbox if the network is down.

| Event | Why critical |
|---|---|
| `app_cold_start` | Every session must start with this. Missing → broken instrumentation. |
| `auth_otp_verify_success` | Funnel cornerstone. Missing → broken activation reporting. |
| `paywall_purchase_success` | Revenue tracking. Missing → can't reconcile against payment provider. |
| `recall_acknowledge` | Compliance event. Regulator may request proof of acknowledgment. |
| `crash_report_sent` | Confirms the crash pipeline. Anti-canary for instrumentation drift. |
| `app_crash` | Fired from `FlutterError.onError`. Not the crash itself — Sentry handles that. This is the analytics counterpart for funnel decoration. |

A weekly job in BE-29 verifies that for every active user, `app_cold_start` fired at least once in the period. Drift below 99% triggers a paging alert.

---

## 7. Logging framework

### 7.1 Tool

**`package:logging`** with a flavor-gated root level:

| Flavor | Root level | Console output | Sentry breadcrumb output |
|---|---|---|---|
| dev | `Level.ALL` | yes | no |
| staging | `Level.INFO` | yes (file only, retained 7 days) | yes (filtered to `info+`) |
| prod | `Level.WARNING` | no | yes (filtered to `warning+`) |

### 7.2 Logger setup

```dart
// lib/core/logging/logger.dart
final _root = Logger.root;

void initLogging(FlavorConfig config) {
  _root.level = switch (config.flavor) {
    Flavor.dev     => Level.ALL,
    Flavor.staging => Level.INFO,
    Flavor.prod    => Level.WARNING,
  };
  _root.onRecord.listen((record) {
    if (config.enableLogging) {
      // ignore: avoid_print
      print('${record.level.name} ${record.loggerName}: ${record.message}');
    }
    if (record.level >= Level.INFO) {
      Sentry.addBreadcrumb(Breadcrumb(
        message: record.message,
        category: record.loggerName,
        level: _toSentryLevel(record.level),
        data: PiiRedactor.redact(record.object) as Map<String, dynamic>?,
      ));
    }
    if (record.level >= Level.SEVERE) {
      Sentry.captureMessage(
        record.message,
        level: SentryLevel.error,
        params: [if (record.error != null) record.error!],
      );
    }
  });
}
```

### 7.3 Logger naming

Loggers are named after the file's feature path. Example:

```dart
final _log = Logger('features.scan.controller');
```

This places log lines in their feature bucket so Sentry can filter by component.

---

## 8. Wiring rules

### 8.1 No analytics in `build()`

Analytics events fire only from controllers/services. Calling `RadhaAnalytics.fire(...)` from a `build` method is forbidden — it produces duplicate events on rebuild and decouples the event from the user's actual action.

`tool/perf_lints/no_analytics_in_build.dart` enforces this. The lint scans for any call to `RadhaAnalytics.*` inside a method named `build` and fails the analyzer.

### 8.2 Singleton wrapper

```dart
// lib/core/observability/radha_analytics.dart
class RadhaAnalytics {
  RadhaAnalytics._(this._firebase, this._props);
  static late final RadhaAnalytics instance;

  final FirebaseAnalytics _firebase;
  final RadhaPropsProvider _props;

  Future<void> fire(String name, [Map<String, Object?> params = const {}]) async {
    if (_optedOut) return;
    final enriched = {...await _props.required(), ...params};
    final filtered = PiiRedactor.redact(enriched) as Map<String, Object>;
    await _firebase.logEvent(name: name, parameters: filtered.map((k, v) => MapEntry(k, v as Object)));
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'analytics.$name',
      data: filtered,
      level: SentryLevel.info,
    ));
  }
}
```

The singleton is created in `bootstrap()` after Sentry init, before `runApp`.

### 8.3 GoRouter integration

```dart
final router = GoRouter(
  observers: [
    SentryNavigatorObserver(),                       // breadcrumb per route
    AnalyticsNavigatorObserver(RadhaAnalytics.instance), // screen_view per route
  ],
  // ...
);
```

The analytics navigator observer fires `screen_view` with parameter `screen_name = <route_name>` automatically.

---

## 9. Alerting

Alerts route to PagerDuty. Severity levels match the on-call rotation.

| Alert | Threshold | Severity | Action |
|---|---|---|---|
| Crash-free sessions (prod) | < 99.5% over rolling 1 hr | **Page** on-call | Investigate top crashes; consider rollback |
| Crash-free users (prod) | < 99.0% over rolling 24 hr | **Page** on-call | Same as above; broader cohort impact |
| p95 cold start (prod) | > 2.0 s over rolling 24 hr | Notify (Slack) | Investigate; FE-39 owner reviews |
| Sentry quota | > 80% of monthly cap | Notify (Slack) | Engage adaptive sampling; review noisy events |
| Sentry symbol upload failure | any | Notify (Slack) | Block release pipeline until resolved |
| Critical event drop-out (e.g. `app_cold_start` missing for 10% of sessions) | any | Notify (Slack) | Verify analytics dispatcher; check release SDK config |
| API error rate (4xx + 5xx) | > 2% over rolling 5 min | Notify (Slack) | Check BE health; consider circuit breaker on client |
| Patrol smoke test (post-release) | failure | **Page** on-call | Roll back release |

### 9.1 Page vs notify

- **Page** = wakes someone up. Used only for production user-facing breakage.
- **Notify** = posts to `#radha-mobile-alerts` Slack. Reviewed within business hours.

### 9.2 Quiet hours

The on-call rotation honors quiet hours (22:00 IST – 07:00 IST). Page-grade alerts always page. Notify-grade alerts are queued and surfaced in the morning standup.

---

## 10. Dashboards

### 10.1 Sentry dashboards

- **Per-flavor crash dashboard**: filtered by `environment = prod | staging | dev`. Top issues, release health, regression candidates.
- **"Crashes by phase introduced"**: custom view that groups issues by the `release` field's phase tag (`fe-21`, `fe-25`, etc., set on each Sentry release). Lets the team trace which phase introduced which crash.
- **Performance**: p50/p95/p99 transaction durations for the named transactions: `bootstrap`, `auth.otp.verify`, `scan.capture`, `dashboard.load`, `grn.submit`.

### 10.2 Firebase dashboards

- **Cold-start histogram**: bucketed at 100 ms intervals; FE-39 budget overlay.
- **Scan-to-verdict latency**: from `scan_capture_attempt` to `scan_capture_success`.
- **Network call distribution**: by endpoint, status code, latency bucket.

### 10.3 BE-29 owner dashboard

The RADHA business owner consumes BE-29's aggregated dashboards (private Next.js — separate from this app). Key panels:

- **Weekly active users** (WAU), per segment.
- **Activation funnel**: cold start → OTP → segment confirm → first feature event.
- **Paywall conversion**: paywall_view → paywall_purchase_success rate, by tier.
- **Scans per user**: histogram, weekly.
- **Sentry release health summary**: imported via Sentry → BE-29 webhook.

These dashboards do not contain PII — only the hashed `userId` and aggregate counts.

---

## 11. Privacy compliance

### 11.1 Regulatory scope

- **DPDP (India Digital Personal Data Protection Act)**: primary regulatory regime.
- **GDPR**: applied as a stricter superset (the app may be used by NRI users).
- **Apple ATT**: tracking transparency required; the app does not use IDFA, so the prompt is not shown. A privacy manifest declares "no tracking".
- **Google Play Data Safety**: declared declarations match what this document captures.

### 11.2 User rights

- **Opt-out toggle**: Settings → Privacy → "Help improve RADHA" toggle. When disabled:
  - `Firebase.setAnalyticsCollectionEnabled(false)` — no analytics events sent.
  - `SentryFlutter` continues to send **crashes only** (errors that are user-impacting). Breadcrumbs and performance traces are disabled via `options.beforeSend` returning `null` for non-crash events.
  - Users see a one-line explanation: *"We will still capture crashes so we can fix what broke for you."*
  - The toggle state is stored in `flutter_secure_storage` and read at app boot before instrumentation initialises.
- **Data export**: GET `/api/v1/user/me/observability/export` (BE-29) returns a JSON of all analytics events for that user in the last 90 days.
- **Data deletion**: DELETE `/api/v1/user/me/analytics` (BE-29) purges Firebase Analytics user data + asks Sentry to forget the user via Sentry's user deletion API. The client clears its local Sentry user identifier on success.

### 11.3 Default behavior

- Analytics opt-in is **on by default**. The user has not opted in until they accept the privacy notice during onboarding (FE-09 → FE-12 path).
- The privacy notice text is part of the ARB key `privacyNotice.observability` and the toggle has key `settings.privacy.helpImproveToggle`.

### 11.4 Children

The app's primary audience excludes users under 13. If the user signals (via the family-member flow at FE-15) that the device is shared with a minor, the analytics opt-in for that user remains off until a parent explicitly toggles it on.

---

## 12. Local debugging

### 12.1 Dev-only crash viewer

A debug menu (`Settings → Debug → Recent crashes`) is built only in dev/staging flavors. It reads from Sentry's local cache (`sentry_flutter` SDK exposes the on-disk envelope queue) and shows the last 10 crashes:

```
2026-05-17 12:42 — Exception: Drift database is closed (auth.repository.dart:142)
2026-05-15 09:11 — RangeError (length): index out of range (scan.controller.dart:88)
...
```

Tapping an entry shows the full envelope and a "Copy to clipboard" button.

### 12.2 Disable observability flag

For offline development on a plane or in a country where Sentry is blocked:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=DISABLE_OBSERVABILITY=true
```

The flag short-circuits `bootstrap()` so neither Sentry nor Firebase nor analytics initialise. The placeholder no-op `RadhaAnalytics` and `Logger` are wired so feature code does not branch.

### 12.3 Verbose mode

`--dart-define=OBS_VERBOSE=true` raises the logger root to `Level.ALL` and routes every breadcrumb to `print` — used to diagnose instrumentation gaps.

---

## 13. Release engineering integration (FE-40)

The release pipeline (`mobile-release.yml`) integrates observability as a release gate:

```yaml
# excerpt
release:
  steps:
    - name: Build prod
      run: flutter build appbundle --flavor prod --release
    - name: Build iOS
      run: flutter build ipa --flavor prod --release
    - name: Upload symbols to Sentry
      run: |
        sentry-cli upload-dif --project=radha-mobile build/app/outputs/symbols/
        sentry-cli upload-dif --project=radha-mobile build/ios/archive/Runner.xcarchive/dSYMs/
    - name: Mark Sentry release
      run: |
        sentry-cli releases new ${RELEASE_TAG}
        sentry-cli releases set-commits ${RELEASE_TAG} --auto
        sentry-cli releases finalize ${RELEASE_TAG}
    - name: Verify symbols
      run: sentry-cli releases info ${RELEASE_TAG} --json | jq -e '.symbolsUploaded == true'
    - name: Pre-flight observability check
      run: dart run tool/observability/preflight.dart --release ${RELEASE_TAG}
```

The pre-flight check verifies:
- Sentry release exists.
- Symbols uploaded successfully.
- Critical events list is intact in `tool/observability/critical_events.json`.
- Privacy manifest declares the same SDKs as the runtime initialises.

A red pre-flight blocks promotion to internal testing → public beta → production.

### 13.1 Release health gates

FE-40's release gate refuses to promote a build to prod if the staging release has:
- crash-free sessions < 99.5% over a 24-hour staging soak,
- p95 cold start > 2.0 s,
- a Sentry "regression" tag on any issue introduced by the staging release.

---

## 14. Anti-patterns (avoid)

1. **Logging PII inadvertently** — every new logger call passes through `PiiRedactor`. CI lint `no_pii_in_logs.dart` flags string-formatted logs that contain `${user.email}` or similar.
2. **Calling Firebase Analytics directly** — bypasses the singleton wrapper, drops required properties, and may include banned keys.
3. **Adding a new event without taxonomy approval** — every event must follow `<surface>_<action>_<outcome>`. New events are reviewed in the weekly analytics planning.
4. **Capturing Sentry exceptions inside hot paths** — `Sentry.captureException` is async + I/O. Keep it off the scan hot path; let breadcrumbs trail and capture only on terminal failure.
5. **Changing sampling rates without an ADR** — sampling affects budget and observability fidelity. Treat it as configuration, but version it.
6. **Putting user-readable error text into Sentry** — error messages should reference internal constants, not localised user-facing strings (which fragment the issue grouping).

---

## 15. Operational runbook

### 15.1 First crash investigation

1. Open Sentry → top issues by frequency in the last hour.
2. Click the issue → review the stack, breadcrumbs, request data, device info.
3. Reproduce locally on the closest matching device (device class + OS version).
4. If reproducible, file a bug + open a hotfix branch.
5. If not reproducible, mark as `needs-info` and add a custom breadcrumb in the suspected component to gather more context on the next occurrence.

### 15.2 Mid-week dashboard review

Every Wednesday 10:00 IST, the SRE Lead and Frontend Tech Lead review:
- Top 5 issues by user count.
- Crash-free sessions trend (7-day window).
- Performance regression candidates.
- Sentry quota usage (project against month-end).
- New analytics events (drift from taxonomy).
- Open `TECHNICAL_DEBT_REGISTER.md` items related to observability (currently DEBT-009).

### 15.3 Incident-response loop

A **Sev1** observability-affecting incident (Sentry down, analytics pipeline broken) follows:

1. SRE acknowledges in PagerDuty.
2. Incident channel opened in Slack.
3. App continues to enqueue events locally (Sentry envelope queue, analytics outbox).
4. Once observability provider recovers, queues drain and instrumentation catches up.
5. Postmortem within 5 working days; learnings filed in `docs/postmortems/`.

The app's local queues hold up to **24 hours** of analytics events and **7 days** of crash reports.

---

## 16. Phase-by-phase instrumentation map

The full wiring lands in FE-40, but each earlier phase contributes its events.

| Phase | Events introduced |
|---|---|
| FE-01 | `app_cold_start` (basic), `app_crash` (3-layer error boundary stub) |
| FE-05 | `screen_view` (per route, automatic via observer) |
| FE-06 | `api_*_*` performance traces, `quota_breach_*` tags |
| FE-07 | `auth_otp_*`, `auth_refresh_*`, `auth_logout` |
| FE-08 | `sync_*` events, Drift transaction breadcrumbs |
| FE-09 | `app_cold_start` finalised |
| FE-10 | `onboarding_segment_*` |
| FE-13 | `paywall_*` |
| FE-14 | `family_invite_*`, `family_accept_*` |
| FE-15 | `allergen_*` |
| FE-17 | `scan_capture_*` |
| FE-18 | `scan_verdict_*` |
| FE-19 | `product_view`, `product_save`, `product_share` |
| FE-21 | `recall_view`, `recall_acknowledge` |
| FE-22 | `ai_explainer_open`, `ai_explainer_complete` |
| FE-25 | `business_dashboard_view`, `ohs_view` |
| FE-29 | `grn_submit_attempt`, `grn_submit_success`, `grn_submit_fail` |
| FE-30 | `inventory_*` |
| FE-31 | `task_*` |
| FE-32 | `report_export_*` |
| FE-36 | `sync_outbox_drain`, `sync_conflict_*` |
| FE-40 | `crash_report_sent`, full Sentry release wiring |

---

## 17. Quick-reference

### 17.1 What instruments what

| Concern | Tool |
|---|---|
| Crashes (Dart + native) | Sentry |
| Performance traces | Sentry + Firebase Performance |
| Funnel events | Firebase Analytics |
| Cohort + retention | BE-29 (sourced from Firebase) |
| Local debug logs | `package:logging` + console |
| Privacy redaction | `PiiRedactor` (Dio interceptor + Sentry beforeSend) |

### 17.2 Where to look

| Symptom | Where |
|---|---|
| Crash spike | Sentry → Issues |
| Cold start regression | Firebase Performance → `_app_start` |
| Funnel drop-off | BE-29 dashboard → Activation funnel |
| Network errors | Sentry → Performance → `api.*` |
| User reported a bug | Sentry user search by hashed `userId` |
| Symbols missing | Sentry release page → "Missing debug files" |

### 17.3 Cross-references

- `ADR_LOG.md` — ADR-008 Sentry choice.
- `FRONTEND_QA_SYSTEM.md` — Rung 11 release gate references this file.
- `FRONTEND_VERIFICATION_SYSTEM.md` — `mobile-release.yml` symbol upload steps.
- `FRONTEND_PHASES/FE-40_PHASE.md` — release engineering implementation.
- `TECHNICAL_DEBT_REGISTER.md` — DEBT-009 (recall foreground refetch) tracked here for sync-driven cleanup.
- `LOCALIZATION_STRATEGY.md` — ARB key for the opt-out toggle copy.
- `RADHA_CLIENT_OVERVIEW.md` — privacy posture.

---

**END OF FILE — OBSERVABILITY_PLAN.md**
