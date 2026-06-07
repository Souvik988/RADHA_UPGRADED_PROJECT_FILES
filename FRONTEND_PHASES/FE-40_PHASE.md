# Phase FE-40: Release Engineering + Security Hardening + Crash Gate

## Phase Metadata
- **Phase ID**: FE-40
- **Phase Name**: Release Engineering + Security Hardening + Crash Gate
- **Section**: Layer 5 — Polish + Cross-cutting (final phase before production)
- **Depends On**: FE-01 (flavors and bundle ids), FE-07 (`flutter_secure_storage` baseline), FE-08 (Dio HTTP client — pinning is layered on this), FE-39 (perf budget — release builds must satisfy it), every prior FE phase (this is the gate that ships them all)
- **Backend Depends On**: BE-48 observability (Sentry/Crashlytics ingestion), BE-29 analytics, BE-47 feature flags (kill switches read at boot)
- **Blocks**: production release on Google Play and Apple App Store
- **Estimated Duration**: 3-4 days
- **Complexity**: High — code-signing, store metadata, security review and rollback all interact

## Goal
Ship signed, obfuscated, hardened, store-ready RADHA builds to Play Internal Testing and TestFlight, with crash reporting verified live, certificate pinning active, secure storage audited, and a documented one-page rollback plan. Specifically:

- **Code obfuscation + symbol upload** — `flutter build apk --obfuscate --split-debug-info=build/symbols/` for Android, `--obfuscate --split-debug-info` for iOS, symbols uploaded to Sentry per build.
- **Certificate pinning** — Dio interceptor + native fallback; SHA-256 fingerprints for `api.radha.app`, `cdn.radha.app`, `media.radha.app`. Two-pin strategy (current + next) so cert rotation never bricks the app.
- **Secure storage audit** — re-verify FE-07 wiring uses Android EncryptedSharedPreferences and iOS Keychain with `KeychainAccessibility.first_unlock`, no `kSecAttrAccessibleAlways`, never written to backups.
- **ProGuard / R8** — keep rules for `mobile_scanner`, `google_mlkit_*`, `drift`, `firebase_messaging`, `flutter_local_notifications`, plus reflection-using packages we shipped.
- **iOS App Transport Security** — production posture is "no exceptions"; if Sentry self-host needs an exception we document it explicitly.
- **Privacy Manifest** — `PrivacyInfo.xcprivacy` declaring required-reason API usage (UserDefaults, FileTimestamp, SystemBootTime, DiskSpace) and tracking domains (none — RADHA does not run trackers).
- **Play Store data safety form** — documented mapping of each permission (camera, microphone, location, contacts, photos) to the in-app feature that needs it; no over-asks.
- **Crash reporting smoke test** — synthetic error thrown on first launch of a release build; verified visible in Sentry within 60 s.
- **Screenshot pipeline** — fastlane `snapshot` capturing 8 screenshots per device class per locale.
- **Release pipeline** — single `mobile-release.yml` workflow runs on tag push: builds, signs, obfuscates, uploads to Play Internal + TestFlight, attaches release notes, files a GitHub Release.

This phase **absorbs the security hardening responsibility** that earlier drafts had spread across multiple late phases.

## Why This Phase Matters
- **An app store is a one-shot rejection environment.** A missing `PrivacyInfo.xcprivacy` triggers a 5–7 day rejection loop. Doing it once, correctly, before submission saves a release cycle.
- **Obfuscation is non-negotiable for a multi-tenant app.** Tenant-aware paywall logic (FE-13), recall acknowledgement (FE-21) and audit-token entry (FE-16) are all reverse-engineering targets. `--obfuscate` plus stable Sentry de-symbolication is the only honest answer.
- **Certificate pinning protects the OTP flow.** A man-in-the-middle on a hotel Wi-Fi sees an OTP and impersonates the user. Pinning is a cheap, big-leverage defense; the cost of getting rotation wrong is bricking the app, which is why we ship a two-pin strategy from day one.
- **Crash gate is the production canary.** A 0.5% session-crash rate is the published red line; above it a staged rollout is auto-halted by Play Console. Wiring the gate now, with thresholds that match Play's own halting policy, prevents a bad release from reaching wider audiences.
- **Privacy manifest is law in 2024+.** Apple began rejecting apps without `PrivacyInfo.xcprivacy` for required-reason APIs in May 2024. India's DPDP Act adds parallel obligations. One artifact satisfies both.
- **Release notes and screenshots are conversion levers.** Apps with localized screenshots in Hindi/Tamil/Telugu/Bengali/Marathi convert 18–25% better in their respective markets than English-only listings (industry estimate). The pipeline ships those for free.
- **Rollback playbook means the on-call engineer is calm at 2 a.m.** The checklist removes guesswork: signing key location, fastlane invocation to halt rollout, Sentry alert acknowledgement, support comms.

## Prerequisites
- [ ] FE-01..FE-39 merged. FE-39 perf budget green for the candidate build.
- [ ] Apple Developer Program enrolment, Team ID known. App Store Connect app record created with bundle id `app.radha.mobile`.
- [ ] Google Play Console app record created; first internal test track ready.
- [ ] Upload + app signing keys minted. Play App Signing enrolment complete; upload key stored in 1Password vault `radha-mobile-release`.
- [ ] iOS distribution certificate + App Store provisioning profile downloaded. Match (fastlane) repo seeded.
- [ ] Sentry project `radha-mobile` exists with separate environments `dev`, `staging`, `prod`. DSNs added to per-flavor config (FE-01).
- [ ] BE-48 confirms Sentry ingest at `sentry.radha.app` (self-hosted) is reachable and rate limits are set.
- [ ] BE-47 feature flag `release.kill_switch` exists; default `false`. App reads it at boot and disables paid surfaces (FE-13) if set.
- [ ] Legal: privacy policy URL live at `https://radha.app/privacy`, terms at `https://radha.app/terms`. Required for store listing.
- [ ] Marketing assets: 1024×1024 master icon, 8 screenshots per device class per locale, 30s preview video, short description ≤ 80 chars, full description ≤ 4000 chars.

## Files to Create

| File Path | Purpose |
|---|---|
| `.github/workflows/mobile-release.yml` | Full release pipeline — builds, signs, uploads, files GitHub Release |
| `apps/mobile/android/app/proguard-rules.pro` | R8/ProGuard keep rules for native plugins |
| `apps/mobile/android/app/upload-keystore.jks.template` | Placeholder; real keystore lives in CI secret |
| `apps/mobile/android/key.properties.template` | Template — never committed real |
| `apps/mobile/ios/Runner/PrivacyInfo.xcprivacy` | iOS 17+ privacy manifest (required-reason APIs + tracking domains) |
| `apps/mobile/ios/Runner/Info.plist` (audited) | ATS posture, usage strings, supported orientations |
| `apps/mobile/lib/security/cert_pinning.dart` | Dio interceptor: 2-pin SHA-256 strategy + fallback policy |
| `apps/mobile/lib/security/integrity_check.dart` | Play Integrity API + iOS App Attest wrapper, called on auth-critical paths |
| `apps/mobile/lib/security/secure_storage_audit.dart` | Boot-time assertion that Keychain accessibility is `first_unlock` and Android KeyStore is hardware-backed |
| `apps/mobile/lib/security/crash_smoke_test.dart` | Debug-only `forceCrash()` for verifying Sentry pipeline |
| `apps/mobile/fastlane/Fastfile` | Lanes: `beta`, `release`, `screenshots`, `metadata`, `match` |
| `apps/mobile/fastlane/Appfile` | Bundle ids, Apple Team ID — template values |
| `apps/mobile/fastlane/Pluginfile` | fastlane plugins (firebase_app_distribution, supply, pilot, snapshot) |
| `apps/mobile/fastlane/screenshots/.gitkeep` | Placeholder; generated screenshots committed under here per locale |
| `apps/mobile/fastlane/metadata/android/en-US/full_description.txt` | Play Store full description |
| `apps/mobile/fastlane/metadata/en-US/description.txt` | App Store description |
| `apps/mobile/store/play-store-listing.md` | Source of truth — title, short desc, full desc, what's new, keywords (per locale) |
| `apps/mobile/store/app-store-listing.md` | App Store equivalent + promo text + reviewer notes |
| `apps/mobile/store/data_safety_form.md` | Play Store data-safety mapping — every permission justified |
| `apps/mobile/store/privacy_questionnaire.md` | App Store privacy questions answers |
| `apps/mobile/RELEASE_CHECKLIST.md` | In-repo, version-controlled go-live checklist |
| `apps/mobile/RELEASE_RUNBOOK.md` | On-call rollback playbook |

## Implementation Spec

### Build commands
```bash
# Android — release build with obfuscation
flutter build appbundle --release --flavor prod \
  --target lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols/android \
  --dart-define=SENTRY_RELEASE=$(git describe --tags)

# iOS — release build with obfuscation
flutter build ipa --release --flavor prod \
  --target lib/main_prod.dart \
  --obfuscate --split-debug-info=build/symbols/ios \
  --export-options-plist=ios/ExportOptions.plist
```

Symbols uploaded to Sentry post-build via `sentry-cli upload-dif` so crash reports de-symbolicate cleanly.

### `cert_pinning.dart`
```dart
class CertPinning {
  // Two-pin strategy: current + next. Rotation flips next → current.
  static const Map<String, List<String>> pins = {
    'api.radha.app': [
      'sha256/PRIMARY_FPR_BASE64==',
      'sha256/BACKUP_FPR_BASE64==',
    ],
    'cdn.radha.app':   ['sha256/CDN_PRIMARY==', 'sha256/CDN_BACKUP=='],
    'media.radha.app': ['sha256/MEDIA_PRIMARY==', 'sha256/MEDIA_BACKUP=='],
  };

  static Interceptor build() => InterceptorsWrapper(
        onResponse: (resp, h) {
          final host = resp.requestOptions.uri.host;
          final cert = resp.requestOptions.extra['cert'] as X509Certificate?;
          if (!_validate(host, cert)) {
            throw DioException(
              requestOptions: resp.requestOptions,
              type: DioExceptionType.unknown,
              message: 'cert_pinning_failed',
            );
          }
          h.next(resp);
        },
      );

  static bool _validate(String host, X509Certificate? cert) { /* sha256 over cert.der */ }
}
```

If both pins fail, the client refuses the request and surfaces an in-app banner: "Security check failed. Try again on a trusted network." This is the cliff that protects OTP and payment paths.

### `integrity_check.dart`
- **Android**: `play_integrity` plugin → `IntegrityManager.requestIntegrityToken(...)`. Server (BE) validates token; failure denies subscription provisioning.
- **iOS**: `app_attest` via `DCAppAttestService`. Token attached to subscription/activation requests.
- Called on: subscription create (FE-13), business activation (FE-16), OTP verify (FE-12).
- Fallback when device doesn't support attestation: log + downgrade trust score; do not block.

### `secure_storage_audit.dart`
- On first boot of a release build, asserts:
  - iOS: every key written via `flutter_secure_storage` carries `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)`. Throws in debug if a key was written with default accessibility.
  - Android: `EncryptedSharedPreferences` is hardware-backed (`KeyStore.getKey` returns a hardware-backed alias). Falls back to software-backed only on devices < API 23 (gracefully).
- Writes a `secure_storage_audit_passed: true` flag to a non-sensitive prefs store; CI integration test reads the flag and fails if false.

### `proguard-rules.pro`
```proguard
# mobile_scanner / ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }

# Drift (sqflite)
-keep class com.simolus.drift.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Flutter local notifications
-keep class com.dexterous.** { *; }

# Sentry
-keep class io.sentry.android.** { *; }
-keep class io.sentry.** { *; }

# Keep all annotations + reflection metadata
-keepattributes *Annotation*, Signature, SourceFile, LineNumberTable
```

### iOS `PrivacyInfo.xcprivacy` (skeleton)
```xml
<dict>
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key><string>NSPrivacyCollectedDataTypeName</string>
      <key>NSPrivacyCollectedDataTypeLinked</key><true/>
      <key>NSPrivacyCollectedDataTypeTracking</key><false/>
      <key>NSPrivacyCollectedDataTypePurposes</key><array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
    </dict>
    <!-- email, phone number, photos (when added in scan), product barcodes -->
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array>
    <dict><key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryUserDefaults</string>
          <key>NSPrivacyAccessedAPITypeReasons</key><array><string>CA92.1</string></array></dict>
    <dict><key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
          <key>NSPrivacyAccessedAPITypeReasons</key><array><string>C617.1</string></array></dict>
    <dict><key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategorySystemBootTime</string>
          <key>NSPrivacyAccessedAPITypeReasons</key><array><string>35F9.1</string></array></dict>
    <dict><key>NSPrivacyAccessedAPIType</key><string>NSPrivacyAccessedAPICategoryDiskSpace</string>
          <key>NSPrivacyAccessedAPITypeReasons</key><array><string>E174.1</string></array></dict>
  </array>
</dict>
```

### CI pipeline `mobile-release.yml`
```yaml
name: mobile-release
on:
  push:
    tags: ['mobile-v*']
jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: stable, cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - name: Decode keystore
        run: echo "$KEYSTORE_BASE64" | base64 -d > apps/mobile/android/upload-keystore.jks
        env: { KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE }} }
      - run: flutter build appbundle --release --flavor prod --target lib/main_prod.dart --obfuscate --split-debug-info=build/symbols/android --dart-define=SENTRY_RELEASE=${{ github.ref_name }}
        working-directory: apps/mobile
      - name: Upload symbols to Sentry
        run: sentry-cli upload-dif --org radha --project radha-mobile build/symbols/android
      - name: Upload to Play Internal
        uses: r0adkll/upload-google-play@v1
        with: { serviceAccountJsonPlainText: ${{ secrets.GPLAY_JSON }}, packageName: app.radha.mobile, releaseFiles: apps/mobile/build/app/outputs/bundle/prodRelease/app-prod-release.aab, track: internal }
  ios:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: stable, cache: true }
      - run: bundle install && bundle exec fastlane match appstore --readonly
        working-directory: apps/mobile
      - run: flutter build ipa --release --flavor prod --target lib/main_prod.dart --obfuscate --split-debug-info=build/symbols/ios --export-options-plist=ios/ExportOptions.plist
        working-directory: apps/mobile
      - run: bundle exec fastlane pilot upload
        working-directory: apps/mobile
      - run: sentry-cli upload-dif --org radha --project radha-mobile build/symbols/ios
```

### `RELEASE_CHECKLIST.md` (in-repo)
- Version bump in `pubspec.yaml` (semver + buildNumber).
- Tag: `mobile-v$VERSION` pushed.
- `mobile-release.yml` green.
- Sentry release marked `production` and tagged.
- Crash smoke test executed on a TestFlight build; event visible in Sentry.
- Cert pinning verified against staging (toggle pin to invalid hash, confirm error UX).
- Privacy manifest updated if any new SDK added.
- Play data-safety form re-confirmed.
- Staged rollout starts at 1%, 24-hour bake → 10% → 25% → 50% → 100%.
- TestFlight external review submitted; App Store reviewer notes attached.

## Visual Behaviour
This phase ships **no new in-app surfaces**, but it changes existing surfaces' failure modes:

| State | Visual |
|---|---|
| **Pinning failure (man-in-the-middle)** | Inline error banner on auth + paywall: "Connection blocked. Try a different network." Sentry breadcrumb fires |
| **Integrity check fails on subscription** | Paywall (FE-13) shows error sheet with `Try again` + `Contact support`; subscription not created |
| **Kill switch on (`release.kill_switch=true`)** | Paywall, business activation hidden behind a maintenance banner; non-paid features unaffected |
| **Crash smoke (debug only)** | `forceCrash()` triggers a synthetic exception; toast confirms event id queued for Sentry |
| **Release-build first launch** | `secure_storage_audit_passed=true` is silently set; no UI |
| **Staged rollout halt by crash gate** | App still functions for already-installed users; new installs from Play stop until rollout resumes |

## Animations
This phase **adds no animations**. The release-blocking pinning failure banner reuses the standard inline-error component from FE-37 (200 ms fade + slide). No phase-specific motion.

## Accessibility
- Pinning-failure banner inherits the FE-37 critical-error semantics (`liveRegion: true`, 7:1 contrast on red surface).
- Integrity-check failure dialog is `Semantics(button: true)` on `Try again` and `Contact support` — focus-first on `Try again`.
- Crash smoke `forceCrash()` is **not** reachable from any user-discoverable UI in release; debug-only entry from a long-press in dev menu.
- Release notes pulled from `app-store-listing.md` are the source of truth for VoiceOver "What's New" — kept short (≤ 200 chars per language) so the screen reader reads them in under 30 s.
- Privacy manifest itself doesn't render in-app, but the in-app `Settings → Privacy` link (FE-37) is the user-facing surface for this data — keyboard reachable, focus-orderable.

## Testing

### Unit tests
- `cert_pinning_test.dart`: known-good fingerprint passes; mutated byte fails; backup pin works when primary rotated.
- `integrity_check_test.dart`: token attached to subscription request; absent token short-circuits to UX error.
- `secure_storage_audit_test.dart`: assertion fails on iOS keys written with `KeychainAccessibility.always`.

### Integration tests
- `crash_smoke_release_test.dart`: forced exception in a profile build is captured + symbolicated within 60 s.
- `kill_switch_test.dart`: BE-47 returns `release.kill_switch=true`; paywall + activation surfaces hidden.
- `staged_rollout_simulation_test.dart`: simulated crash gate trips at 1.5% rate; client logs the alert breadcrumb.

### Build / pipeline tests
- `mobile-release.yml` dry-run on a non-tag branch (matrix that skips upload) succeeds end-to-end.
- `flutter build appbundle --release --flavor prod --obfuscate` produces an `.aab` ≤ 35 MB after Play splits per ABI.
- `flutter build ipa --release --flavor prod --obfuscate` produces an `.ipa` accepted by `xcrun altool --validate-app`.
- `fastlane snapshot` produces 8 screenshots per locale × per device class.
- `fastlane match appstore --readonly` resolves cleanly on a fresh CI runner.

### Manual security checks (one-time, repeated per release)
- `apkanalyzer` on the produced AAB: no PEM, no `.env`, no `firebase_app_id_file.json` in non-flavor paths, no `.dart` source.
- `strings` on the iOS binary: no plaintext API keys; obfuscated symbol names dominate.
- Charles Proxy run with a forged cert: pinning blocks the request; banner appears.
- Sentry: a forced crash from a TestFlight build appears with a symbolicated stack within 60 s.

## Risk Assessment
| Risk | Likelihood | Mitigation |
|---|---|---|
| Upload signing key lost or rotated incorrectly | Low/Critical | Play App Signing enrolled (Google holds the app signing key); upload key in 1Password vault + offline backup; runbook step 7 documents recovery |
| Cert pinning bricks the app on cert rotation | Medium/High | Two-pin strategy (current + next); ops rotates `next` 30 days before cert change; remote kill switch can disable pinning if both pins fail in production |
| Apple rejects on missing privacy manifest | Medium | `PrivacyInfo.xcprivacy` shipped; reviewed before each release; CI lints for new required-reason APIs |
| Play data-safety form gets out of sync after a permission added | Medium | `data_safety_form.md` is the single source; CI fails if `AndroidManifest.xml` introduces a permission not listed in the form |
| Obfuscation breaks reflection in a plugin we missed | Medium | `proguard-rules.pro` reviewed every minor SDK bump; release smoke test exercises every plugin path before promotion |
| Symbols fail to upload to Sentry, crashes are unreadable | Medium | CI step `sentry-cli upload-dif` is required-to-pass; `--no-resident` retry on transient |
| Staged rollout halt due to a benign locale-specific crash | Medium | Per-locale crash dashboards in BE-48; release manager can resume rollout once root cause is filed |
| Fastlane match cert chain expires mid-release | Low | Match repo monitored; cron renews 7 days before expiry |
| iOS App Attest unavailable on simulators causes false test failures | Low | Test harness short-circuits attestation on simulator detection (`UIDevice.isSimulator`) |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15 — release sequence)

| # | Step |
|---|---|
| T1 | **Freeze the branch** — open `release/mobile-vX.Y.Z`; merge window closed; only release fixes accepted. |
| T2 | **Bump versions** — `pubspec.yaml` `version: X.Y.Z+N`, `Info.plist` `CFBundleShortVersionString`, Android `versionName/versionCode`. |
| T3 | **Run full perf suite** — FE-39 `mobile-perf.yml` green on the candidate commit. |
| T4 | **Build Android obfuscated AAB** — `flutter build appbundle --release --flavor prod --obfuscate --split-debug-info=build/symbols/android`; verify size ≤ 35 MB after split. |
| T5 | **Build iOS obfuscated IPA** — `flutter build ipa --release --flavor prod --obfuscate --split-debug-info=build/symbols/ios`; verify `xcrun altool --validate-app` passes. |
| T6 | **Upload symbols** — `sentry-cli upload-dif build/symbols/android` and `…/ios`. |
| T7 | **Pinning self-test** — install on a device behind Charles Proxy with forged cert; assert pinning banner appears, request is refused. |
| T8 | **Integrity self-test** — call subscription endpoint without integrity token; assert BE rejects with `403 integrity_required`. |
| T9 | **Crash smoke test** — long-press dev menu (debug build) → `forceCrash()`; verify event in Sentry within 60 s, symbolicated. |
| T10 | **Secure storage audit** — fresh install on a clean iPhone + Android; `secure_storage_audit_passed` flag is `true`. |
| T11 | **Privacy manifest validation** — Xcode 15 build log shows zero `NSPrivacyAccessedAPI` warnings; `PrivacyInfo.xcprivacy` matches reviewer notes. |
| T12 | **Data-safety form parity** — `data_safety_form.md` lists every permission declared in `AndroidManifest.xml` and every `*Description` key in `Info.plist`. |
| T13 | **Tag and trigger pipeline** — `git tag mobile-vX.Y.Z && git push --tags`; `mobile-release.yml` runs end-to-end green. |
| T14 | **Submit to Play Internal Testing + TestFlight** — fastlane `pilot upload` and `supply --track internal`; release notes attached; Apple reviewer notes filled. |
| T15 | **Staged rollout begin at 1%** — Play Console rollout slider at 1%; bake 24 h; on-call monitors Sentry crash-free sessions ≥ 99.5%. Promote to 10%/25%/50%/100% only when each tier holds for 24 h. |

### Q&A Questions (8)

1. **Obfuscation rollback** — a customer reports a stack trace your team can't symbolicate because `build/symbols/` was lost. What's the recovery path? Can the build be re-symbolicated from the original AAB, and what does that imply about retention policy on the symbols artifact?
2. **Signing-key loss recovery** — the upload key is irrecoverable. What's the procedure with Google Play (key reset request, identity verification, downstream impact on existing installs)? With Apple (re-issue distribution cert, rebuild Match repo)?
3. **Version-bump rules** — when do we bump major (X), minor (Y), patch (Z), build (+N)? What does each bump mean to Play (new release vs same release with new APK) and to App Store (new version vs build update of an existing version)?
4. **Staged rollout %** — we start at 1%. Why 1% and not 5%? When do we promote to the next tier, what halts a tier, and what's the longest tier dwell we'll accept before promoting?
5. **Crash gate threshold** — Play halts a rollout at 1.8% session-crash rate by default; we use 0.5% as our internal red line. Why is ours stricter, and what's the data we use to justify it?
6. **Certificate rotation** — explain the full 90-day rotation: when the new pin enters the app, when ops rotates server cert to use it, when the old pin is removed, and what happens to a user who hasn't updated the app during the rotation window.
7. **App Store rejection appeal** — Apple rejects citing 4.3 (Spam) or 5.1.1 (Privacy). What's the appeal sequence, the SLA on each round, and what we'd attach as evidence (logs, demo video, written justification)?
8. **Expedited review** — when do we request an expedited review (Apple) or a priority review (Play)? What does abuse of expedited review cost us in the next regular review?

## Sign-off Gate
- [ ] Developer: 15 release-sequence steps complete; `mobile-release.yml` green on the tag.
- [ ] Developer: 8 Q&A answered in the handoff doc.
- [ ] Security reviewer: pinning, integrity, secure storage and obfuscation audited; reviewer memo committed at `docs/security/RELEASE_<version>.md`.
- [ ] Privacy reviewer: `PrivacyInfo.xcprivacy` and Play data-safety form reviewed against the latest dependency tree.
- [ ] Release manager: staged-rollout plan filed; on-call schedule covers the 5-day rollout window.
- [ ] Reviewer: confirmed crash smoke test event visible in Sentry, symbolicated.
- [ ] Reviewer: confirmed every prior FE phase's Sign-off Gate is signed before production rollout begins.
- [ ] Tech lead: signed `RELEASE_CHECKLIST.md` for the candidate version.

**Developer Signature**: ___________________________

**☐ APPROVED — Submit to Play Internal + TestFlight, begin staged rollout**
**☐ CHANGES REQUESTED**

**Security Reviewer Signature**: ___________________________

**Privacy Reviewer Signature**: ___________________________

**Release Manager Signature**: ___________________________

**Tech Lead Signature**: ___________________________

---

**END OF FE-40 — DO NOT SHIP TO PRODUCTION WITHOUT ALL SIGNATURES**

**END OF RADHA MOBILE FRONTEND ROADMAP — FE-01 → FE-40 COMPLETE**
