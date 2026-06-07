# RADHA Mobile — CI/CD Pipeline

> **Scope**: GitHub Actions pipelines, branch model, signing, store submission and rollback procedures for the RADHA Flutter app under `apps/mobile/`. This document is the single source of truth referenced by `FRONTEND_PHASES/FE-01_PHASE.md` (CI bootstrap), `FRONTEND_PHASES/FE-39_PHASE.md` (perf gates) and `FRONTEND_PHASES/FE-40_PHASE.md` (release engineering).

---

## 1. Tooling

| Concern | Tool | Notes |
|---|---|---|
| Primary CI | **GitHub Actions** | Free `ubuntu-latest` runners for analyze/test, `macos-14` for iOS builds, self-hosted for device perf/E2E |
| Backup CI | **Codemagic** | On standby. `codemagic.yaml` mirrors the GitHub workflows; activated only if GitHub Actions is regionally degraded > 2 h |
| Store submission | **fastlane 2.220+** | `supply` (Android), `pilot` (TestFlight), `snapshot` (screenshots), `match` (iOS code signing) |
| Coverage | **Codecov** | `codecov-action@v4`, threshold gates configured per workflow, not per file |
| Crash symbols | **sentry-cli 2.32+** | `upload-dif` for split debug info; release tagging matches `git describe --tags` |
| Distribution (dev) | **Firebase App Distribution** | Group `radha-internal` |
| Distribution (staging) | **Play Internal Testing** + **TestFlight internal** | Mirrors org-only access |
| Distribution (prod) | **Play Production** + **App Store** | Staged rollout (10% → 25% → 50% → 100%) |

> **Rule**: any change to `.github/workflows/mobile-*.yml` requires sign-off from one of the platform leads tagged in `CODEOWNERS`. The Codemagic mirror is updated in the same PR or it's not merged.

---

## 2. Branching model

| Branch | Protection | Auto-deploy target | Tag pattern |
|---|---|---|---|
| `main` | Protected; requires green CI + review + signed commits | **none** (release tags drive prod) | `mobile-v<MAJOR>.<MINOR>.<PATCH>` |
| `staging` | Protected; requires green CI | Play Internal + TestFlight internal | — |
| `develop` | Protected; requires green CI | Firebase App Distribution `radha-internal` | — |
| `feat/<scope>` | Open | preview build comment via `mobile-ci.yml` | — |
| `fix/<scope>` | Open | preview build comment via `mobile-ci.yml` | — |
| `release/mobile-v*` | Restricted to release captain | dry-run upload to Play Internal | — |
| `hotfix/<scope>` | Restricted; cuts from `main`, merges back to both `main` and `develop` | TestFlight + Play Internal as soon as green | — |

Merging from `develop` → `staging` and `staging` → `main` is **fast-forward only** — release captain rebases the trailing branches before merge so commits flow linearly.

---

## 3. Pipeline triggers

| Trigger | Workflow | Outcome |
|---|---|---|
| PR opened/updated targeting `develop` | `mobile-ci.yml` | format + analyze + custom-lint + unit + widget + golden + DTO/token/i18n gates + dev APK smoke build + size diff comment |
| PR labeled `perf-check` | `mobile-perf.yml` (FE-39) | Patrol perf integration suite on Pixel 4a self-hosted runner; jank baseline diff posted to PR |
| Merge to `develop` | `mobile-deploy-dev.yml` | dev flavor → Firebase App Distribution; Slack `#mobile-deploys` notification |
| Merge to `staging` | `mobile-deploy-staging.yml` | staging flavor → Play Internal + TestFlight (internal track); Sentry symbol upload |
| Tag `mobile-v*` pushed to `main` | `mobile-release.yml` (FE-40) | prod flavor → Play Production (staged rollout 10%) + App Store; GitHub Release filed |
| Daily 03:00 UTC | `mobile-nightly.yml` | full Patrol E2E + 5-sample cold-start perf regression + 5-min memory soak; results to `#mobile-quality` |
| `workflow_dispatch` | any of the above | Manual re-run with explicit `flavor`, `track` inputs |

---

## 4. `mobile-ci.yml` — full YAML

```yaml
name: mobile-ci
on:
  pull_request:
    branches: [develop, staging, main]
    paths: ['apps/mobile/**', 'packages/shared-types/**', '.github/workflows/mobile-ci.yml']
  push:
    branches: [develop]
    paths: ['apps/mobile/**', 'packages/shared-types/**']

concurrency:
  group: mobile-ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  analyze-test:
    name: Analyze + Test
    runs-on: ubuntu-latest
    timeout-minutes: 25
    defaults:
      run:
        working-directory: apps/mobile
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Setup Flutter 3.22.x stable
        uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }

      - name: Setup Java 17 (Android)
        uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }

      - name: Setup Ruby 3.2 (Fastlane)
        uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.2', bundler-cache: true, working-directory: apps/mobile }

      - name: Pub get
        run: flutter pub get

      - name: Format
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Custom lints
        run: dart run custom_lint

      - name: Unit + widget + golden tests
        run: flutter test --coverage --reporter expanded

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: apps/mobile/coverage/lcov.info
          flags: mobile
          fail_ci_if_error: false  # Codecov 5xx must not block — see runbooks below

      - name: DTO drift gate
        run: dart run tool/contracts/diff_dtos.dart

      - name: Design token gate
        run: dart run tool/design/lint_tokens.dart

      - name: i18n coverage gate
        run: bash tool/i18n/check_arb_coverage.sh

      - name: Asset budget gate
        run: dart run tool/assets/check_image_budget.dart

      - name: Build dev APK (smoke)
        run: flutter build apk --flavor dev --debug -t lib/main_dev.dart

      - name: Compute bundle size delta
        id: size
        run: dart run tool/ci/size_diff.dart --base=origin/${{ github.base_ref }}

      - name: Comment size diff on PR
        if: github.event_name == 'pull_request'
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          header: bundle-size
          path: apps/mobile/build/size_report.md
```

> Branch protection on `main` and `staging` requires `analyze-test` to be green. The DTO, token, i18n and asset gates exit non-zero independently and are surfaced as distinct failed steps so failures are diagnosable from the Checks tab without log spelunking.

---

## 5. `mobile-deploy-dev.yml` — full YAML

```yaml
name: mobile-deploy-dev
on:
  push:
    branches: [develop]
    paths: ['apps/mobile/**', 'packages/shared-types/**']
  workflow_dispatch: {}

jobs:
  build-and-distribute:
    runs-on: ubuntu-latest
    timeout-minutes: 35
    environment: dev
    defaults:
      run:
        working-directory: apps/mobile
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }

      - uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }

      - run: flutter pub get

      - name: Hydrate dev env
        run: echo "${{ secrets.DEV_ENV_FILE }}" | base64 -d > env/dev.env

      - name: Build obfuscated dev APK
        run: |
          flutter build apk --release --flavor dev \
            -t lib/main_dev.dart \
            --obfuscate --split-debug-info=build/symbols/dev \
            --dart-define=SENTRY_RELEASE=$(git describe --tags --always)

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID_DEV }}
          token: ${{ secrets.FIREBASE_TOKEN }}
          groups: radha-internal
          file: apps/mobile/build/app/outputs/flutter-apk/app-dev-release.apk
          releaseNotes: |
            ${{ github.event.head_commit.message }}
            commit: ${{ github.sha }}

      - name: Upload Sentry symbols
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: radha
          SENTRY_PROJECT: radha-mobile
        run: |
          npx --yes @sentry/cli@2.32 upload-dif --include-sources build/symbols/dev || true

      - name: Slack notification
        if: always()
        uses: slackapi/slack-github-action@v1.27.0
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
        with:
          payload: |
            {
              "channel": "#mobile-deploys",
              "text": "RADHA dev build *${{ github.sha }}* — ${{ job.status }}\nFirebase: https://appdistribution.firebase.google.com"
            }
```

---

## 6. `mobile-deploy-staging.yml`

```yaml
name: mobile-deploy-staging
on:
  push:
    branches: [staging]
  workflow_dispatch: {}

jobs:
  android:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - uses: actions/setup-java@v4
        with: { distribution: 'temurin', java-version: '17' }
      - working-directory: apps/mobile
        run: flutter pub get

      - name: Decode upload keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 -d > apps/mobile/android/app/upload-keystore.jks
          cat > apps/mobile/android/key.properties <<EOF
          storeFile=upload-keystore.jks
          storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          EOF

      - name: Hydrate staging env
        run: echo "${{ secrets.STAGING_ENV_FILE }}" | base64 -d > apps/mobile/env/staging.env

      - name: Build AAB (staging, obfuscated)
        working-directory: apps/mobile
        run: |
          flutter build appbundle --release --flavor staging \
            -t lib/main_staging.dart \
            --obfuscate --split-debug-info=build/symbols/staging \
            --dart-define=SENTRY_RELEASE=$(git describe --tags --always)

      - name: Upload to Play Internal Testing
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GPLAY_JSON }}
          packageName: app.radha.mobile.staging
          releaseFiles: apps/mobile/build/app/outputs/bundle/stagingRelease/app-staging-release.aab
          track: internal
          status: completed
          mappingFile: apps/mobile/build/app/outputs/mapping/stagingRelease/mapping.txt

      - name: Sentry symbol upload
        working-directory: apps/mobile
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: radha
          SENTRY_PROJECT: radha-mobile
        run: npx --yes @sentry/cli@2.32 upload-dif --include-sources build/symbols/staging

  ios:
    runs-on: macos-14
    timeout-minutes: 60
    environment: staging
    needs: android
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.2', bundler-cache: true, working-directory: apps/mobile }

      - name: Hydrate staging env
        run: echo "${{ secrets.STAGING_ENV_FILE }}" | base64 -d > apps/mobile/env/staging.env

      - name: Fetch signing assets via fastlane match
        working-directory: apps/mobile
        env:
          MATCH_GIT_TOKEN: ${{ secrets.MATCH_GIT_TOKEN }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          APPSTORE_CONNECT_API_KEY: ${{ secrets.APPSTORE_CONNECT_API_KEY }}
          APPSTORE_CONNECT_KEY_ID: ${{ secrets.APPSTORE_CONNECT_KEY_ID }}
          APPSTORE_CONNECT_ISSUER_ID: ${{ secrets.APPSTORE_CONNECT_ISSUER_ID }}
        run: bundle exec fastlane match appstore --readonly

      - name: Build IPA (staging, obfuscated)
        working-directory: apps/mobile
        run: |
          flutter build ipa --release --flavor staging \
            -t lib/main_staging.dart \
            --obfuscate --split-debug-info=build/symbols/staging-ios \
            --export-options-plist=ios/ExportOptions.plist

      - name: Upload to TestFlight (no submission)
        working-directory: apps/mobile
        env:
          APPSTORE_CONNECT_API_KEY: ${{ secrets.APPSTORE_CONNECT_API_KEY }}
          APPSTORE_CONNECT_KEY_ID: ${{ secrets.APPSTORE_CONNECT_KEY_ID }}
          APPSTORE_CONNECT_ISSUER_ID: ${{ secrets.APPSTORE_CONNECT_ISSUER_ID }}
        run: bundle exec fastlane pilot upload --skip_submission --ipa build/ios/ipa/Runner.ipa

      - name: Sentry symbol upload (iOS)
        working-directory: apps/mobile
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
          SENTRY_ORG: radha
          SENTRY_PROJECT: radha-mobile
        run: npx --yes @sentry/cli@2.32 upload-dif --include-sources build/symbols/staging-ios
```

---

## 7. `mobile-release.yml` — production cut

Defined in full in `FRONTEND_PHASES/FE-40_PHASE.md`. Summary contract this pipeline must honour:

1. Triggers only on `mobile-v*` tag pushed to `main`.
2. Reuses the same signing flow as `mobile-deploy-staging.yml` but targets the prod keystore + prod App Store Connect record.
3. Halts if FE-39 perf budget (`tool/performance/jank_baseline.json`) regression > 5%.
4. Halts if `flutter analyze --fatal-infos` is dirty on the tagged commit (defensive — should already be green).
5. Posts to Play Production with `track: production` and `userFraction: 0.10` (staged rollout).
6. Posts to App Store via `pilot` then `deliver --submit_for_review false` — humans flip the toggle in App Store Connect.
7. Files a GitHub Release with the changelog from `apps/mobile/CHANGELOG.md`.

---

## 8. `mobile-perf.yml` — perf integration suite

Defined in full in `FRONTEND_PHASES/FE-39_PHASE.md`. Summary contract:

- Triggered by PR label `perf-check` and by `mobile-nightly.yml`.
- Runs on self-hosted runner labelled `flutter-android-pixel-4a` and `flutter-ios-iphone-se-2`.
- Executes `apps/mobile/integration_test/perf/` suite + `tool/performance/run_startup_trace.sh` × 5 samples.
- Diffs against `tool/performance/jank_baseline.json`; non-zero exit on regression > tolerance band.
- Posts a markdown table of frame-time p50/p95/p99 to the PR.

---

## 9. `mobile-nightly.yml`

```yaml
name: mobile-nightly
on:
  schedule:
    - cron: '0 3 * * *'   # 03:00 UTC
  workflow_dispatch: {}

jobs:
  e2e-android:
    runs-on: [self-hosted, flutter-android-pixel-4a]
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4
      - working-directory: apps/mobile
        run: |
          flutter pub get
          flutter test integration_test --device-id=$DEVICE_ID --reporter=expanded
          dart run patrol test --target integration_test/e2e/

      - name: Cold-start perf regression (5 samples)
        working-directory: apps/mobile
        run: bash tool/performance/run_startup_trace.sh --samples 5 --baseline tool/performance/jank_baseline.json

      - name: Memory soak (5 min)
        working-directory: apps/mobile
        run: dart run tool/performance/memory_soak.dart --duration 300

  e2e-ios:
    runs-on: [self-hosted, flutter-ios-iphone-se-2]
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4
      - working-directory: apps/mobile
        run: |
          flutter pub get
          dart run patrol test --target integration_test/e2e/ --device "iPhone SE (2nd generation)"

  notify:
    needs: [e2e-android, e2e-ios]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: slackapi/slack-github-action@v1.27.0
        env: { SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }} }
        with:
          payload: |
            {
              "channel": "#mobile-quality",
              "text": "Nightly RADHA E2E + perf — android: ${{ needs.e2e-android.result }}, ios: ${{ needs.e2e-ios.result }}"
            }
```

---

## 10. Required CI checks on `main`

Branch protection on `main` requires **all** of the following before a PR is mergeable:

| Check | Workflow | Required |
|---|---|---|
| `analyze-test` | `mobile-ci.yml` | yes |
| Bundle size diff posted | `mobile-ci.yml` | yes (informational; not blocking) |
| `mobile-perf.yml` | label-driven | recommended; required for PRs touching `lib/perf/`, `lib/animations/`, `lib/screens/scan/` |
| DCO sign-off | `dcoCheck.yml` | yes |
| `Codecov / project` | Codecov status | yes (≥ 75% project coverage) |
| `Codecov / patch` | Codecov status | yes (≥ 80% patch coverage) |
| `CODEOWNERS approval` | GitHub | yes (one platform lead) |
| Branch up-to-date | GitHub | yes (`Require branches to be up to date before merging`) |
| Signed commits | GitHub | yes |

The same set applies to `staging`, with patch coverage relaxed to 70%.

---

## 11. Secrets management

All secrets live in **GitHub Actions Environments** (`dev`, `staging`, `prod`). The `prod` environment requires manual approval from a release captain before any job can read it. Rotation is tracked in 1Password vault `radha-mobile-release` with calendar reminders.

| Secret | Stored in | Used by | Rotation |
|---|---|---|---|
| `ANDROID_KEYSTORE` (base64 JKS) | `staging`, `prod` | deploy-staging, release | Yearly; coordinated with Play upload-key rotation |
| `ANDROID_STORE_PASSWORD` | `staging`, `prod` | deploy-staging, release | Yearly with keystore |
| `ANDROID_KEY_ALIAS` | `staging`, `prod` | deploy-staging, release | Yearly with keystore |
| `ANDROID_KEY_PASSWORD` | `staging`, `prod` | deploy-staging, release | Yearly with keystore |
| `GPLAY_JSON` (Play service-account JSON) | `staging`, `prod` | deploy-staging, release | 90 days |
| `APPSTORE_CONNECT_API_KEY` (P8, base64) | `staging`, `prod` | deploy-staging, release | 180 days |
| `APPSTORE_CONNECT_KEY_ID` | `staging`, `prod` | deploy-staging, release | with API key |
| `APPSTORE_CONNECT_ISSUER_ID` | `staging`, `prod` | deploy-staging, release | static |
| `MATCH_GIT_TOKEN` | `staging`, `prod` | deploy-staging, release | 180 days |
| `MATCH_PASSWORD` | `staging`, `prod` | deploy-staging, release | yearly + on team-member offboarding |
| `SENTRY_AUTH_TOKEN` | `dev`, `staging`, `prod` | every deploy workflow | 180 days |
| `FIREBASE_TOKEN` | `dev` | deploy-dev | 90 days |
| `FIREBASE_APP_ID_DEV` | `dev` | deploy-dev | static |
| `SLACK_WEBHOOK_URL` | `dev`, `staging`, `prod` | every deploy + nightly | revoke + recreate when channel changes |
| `DEV_ENV_FILE` (base64 of `env/dev.env`) | `dev` | deploy-dev | quarterly |
| `STAGING_ENV_FILE` | `staging` | deploy-staging | quarterly |
| `PROD_ENV_FILE` | `prod` | release | quarterly |

> **Off-boarding rule**: when a team member with vault access leaves, `MATCH_PASSWORD`, `SENTRY_AUTH_TOKEN`, `FIREBASE_TOKEN` and `GPLAY_JSON` are rotated within 24 h, regardless of the calendar schedule. The release captain owns this drill.

A nightly `secret-scan.yml` job runs `gitleaks` against the diff between `main` and `develop` and fails loudly into `#mobile-quality` if any of the keys above leak into source.

---

## 12. Self-hosted runner setup

| Runner label | Hardware | OS | Purpose |
|---|---|---|---|
| `flutter-android-pixel-4a` | Pixel 4a, USB tethered | Mac mini M2 (host) / Android 13 (device) | perf + nightly E2E (Android) |
| `flutter-ios-iphone-se-2` | iPhone SE 2 (2020), USB tethered | Mac mini M2 (host) / iOS 17.5 (device) | perf + nightly E2E (iOS) |
| `flutter-mac-builder` | same Mac mini M2 | macOS 14 | iOS release builds when GitHub-hosted macOS is queueing > 15 min |

**Host configuration**:

- Mac mini sits on a UPS in the office; ethernet, not Wi-Fi.
- `actions-runner` daemon under user `radha-ci`, auto-start via `launchctl`.
- Devices kept in **stay-awake-while-charging** + **USB debugging** (Android) / **trust this computer** (iOS) — verified by the runner's `pre-job-health.sh`.
- Nightly `cron` (02:30 UTC) reboots devices via `adb reboot` / `idevicereboot` then waits for `device.online` before the 03:00 UTC nightly job starts.
- Runner labels are pinned in workflow `runs-on:`; **no fallback** for nightly E2E (we want the alarm if devices are offline).

**Failure escalation**: if a self-hosted runner is offline at job dispatch, the workflow fails fast and posts to `#mobile-quality` with `runner-offline` runbook link (see §14).

---

## 13. Rollback procedure

### 13.1 Halt a staged Play rollout

```bash
cd apps/mobile
bundle exec fastlane supply --track production \
  --rollout 0.0 \
  --package_name app.radha.mobile \
  --skip_upload_apk --skip_upload_aab \
  --skip_upload_changelogs \
  --skip_upload_metadata --skip_upload_images
```

This sets the user fraction to `0.0`, freezing further user exposure while preserving the rollout for analysis. Communicate immediately in `#mobile-deploys` with:

- Tag halted (`mobile-vX.Y.Z`)
- Sentry crash-free-session %
- Reason for halt
- Expected ETA for hotfix or full rollback

### 13.2 Roll back to previous tag

```bash
# Resume previous tag at 100% (only works because Play retains the previous AAB)
bundle exec fastlane supply --track production \
  --rollout 1.0 \
  --version_code <previous_versionCode>
```

If Play has already discarded the previous AAB (rare), build a `hotfix/<scope>` from the last known-good tag, bump `versionCode`, push a new `mobile-v*` tag, and let `mobile-release.yml` produce a fresh AAB.

### 13.3 Revert a tag

Tags are immutable from the user's perspective — we never delete them. Instead:

```bash
git checkout main
git revert <bad-tag>^..<bad-tag> --no-edit
git tag mobile-vX.Y.(Z+1)
git push origin main mobile-vX.Y.(Z+1)
```

`mobile-release.yml` runs against the new tag and ships the corrected build.

### 13.4 Push a hotfix

1. Cut `hotfix/<scope>` from `main`.
2. Land the fix; PR runs `mobile-ci.yml` + `mobile-perf.yml`.
3. Merge to `main` (fast-forward) and to `develop` in a single PR with both targets.
4. Push tag `mobile-vX.Y.(Z+1)`.
5. `mobile-release.yml` ships at 10% rollout. Stand by Sentry for 30 min before bumping to 25%.

---

## 14. Failure modes and runbooks

| Failure | Symptom | Action |
|---|---|---|
| **Codecov 5xx** | `codecov-action@v4` reports upload failure; PR check stuck | Retry job once via re-run UI. `mobile-ci.yml` is configured with `fail_ci_if_error: false` for the upload step itself; the *gate* lives at codecov.io status checks, which retry server-side. If still red after 1 h, mark required-but-flexible by force-merging via release captain (logged in `#mobile-deploys`). |
| **App Store cert expired** | `fastlane match appstore --readonly` fails: `No matching profile found` | `bundle exec fastlane match nuke distribution` then `bundle exec fastlane match appstore` to recreate. Update `MATCH_PASSWORD` rotation date in 1Password. ETA 30 min. |
| **Sentry symbol upload timed out** | `sentry-cli upload-dif` fails after 10 min | Retry in-job up to 2 times with exponential backoff. **Do not block the release.** File `tool/observability/missing-symbols-<release>.txt` for next-day backfill. |
| **Self-hosted runner offline** | `mobile-perf.yml` or `mobile-nightly.yml` fails fast at job start | Apply `[skip-perf]` PR label to fall back to `mobile-ci.yml` analyze/test only. File JIRA `MOB-RUNNER-<n>` with the device serial; on-call walks to office and replugs USB. Nightly job re-runs at next 03:00 UTC. |
| **Play upload "version code already used"** | `r0adkll/upload-google-play@v1` returns 403 with conflict | Bump `versionCode` in `apps/mobile/android/app/build.gradle.kts` (+1), re-tag with patch bump. Never reuse a `versionCode`. |
| **TestFlight processing stuck** | `pilot upload` succeeds but build never appears for testers | Wait 1 h. If still missing, check App Store Connect for missing export-compliance answer. Fastfile sets `uses_non_exempt_encryption: false` — if iTunes asks again, re-add to `Info.plist`. |
| **GitHub-hosted macOS queue > 15 min** | `mobile-deploy-staging.yml` `ios` job idle | Manually re-target to `flutter-mac-builder` self-hosted via `workflow_dispatch` input. |
| **DTO drift gate fail** | `tool/contracts/diff_dtos.dart` exits 1 | Either regenerate from `packages/shared-types` (`make codegen`) or block until backend phase is merged. Never override locally. |
| **i18n coverage gate fail** | `tool/i18n/check_arb_coverage.sh` exits 1 | Add the missing key to all 6 ARBs (use English placeholder + Lokalise tag); see `LOCALIZATION_STRATEGY.md` §8. |
| **Asset budget gate fail** | `tool/assets/check_image_budget.dart` exits 1 | Re-export image at the budget; see `ASSET_PIPELINE.md`. Override only via PR to `tool/performance/image_budget.yaml` with designer + tech-lead approval. |

Each runbook entry maps to a one-page wiki page under `RUNBOOKS/mobile-ci/` with shell snippets and screenshots so on-call can act without reading this doc end-to-end.

---

## 15. Cross-references

- `ENVIRONMENT_CONFIG.md` — flavor-specific build commands, env file plumbing
- `LOCALIZATION_STRATEGY.md` — i18n CI gate (`check_arb_coverage.sh`)
- `ASSET_PIPELINE.md` — asset budget CI gates
- `FRONTEND_PHASES/FE-01_PHASE.md` — original CI bootstrap
- `FRONTEND_PHASES/FE-39_PHASE.md` — perf integration suite specifications
- `FRONTEND_PHASES/FE-40_PHASE.md` — release engineering, signing, store submission
