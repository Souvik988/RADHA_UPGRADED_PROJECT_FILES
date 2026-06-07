# RADHA Mobile — Frontend Verification System

> **Purpose.** This document specifies the CI pipelines, custom tooling, and automation that prove the QA gates from `FRONTEND_QA_SYSTEM.md` are green. QA defines the bar; verification proves it. Together they form a closed loop.
>
> **Owners.** Frontend Tech Lead (pipelines), DevEx (tooling), QA Lead (gate enforcement), Backend Tech Lead (contract drift).
>
> **Constraints.** ADR-001 (40 phases), ADR-009 (Patrol + golden_toolkit), ADR-011 (single repo), ADR-007 (envied), ADR-008 (Sentry).

---

## 1. CI pipelines

Pipelines live under `.github/workflows/`. All jobs are scoped by `paths:` filters so non-mobile changes do not run mobile jobs.

| Workflow | File | Trigger | Purpose | Budget |
|---|---|---|---|---|
| `mobile-ci` | `mobile-ci.yml` | every PR touching `apps/mobile/**` | static + unit + widget + golden + contract diff | < 12 min |
| `mobile-integration` | `mobile-integration.yml` | PR labeled `integration-check`, merge to `main` | integration_test on emulator | < 25 min |
| `mobile-perf` | `mobile-perf.yml` | PR labeled `perf-check`, weekly cron | full perf integration suite (FE-39) | < 30 min |
| `mobile-patrol` | `mobile-patrol.yml` | merge to `main`, PR labeled `patrol-required` | Patrol E2E on attached device runner | < 35 min |
| `mobile-release` | `mobile-release.yml` | tag `mobile-v*` | full release pipeline (FE-40) | < 60 min |
| `mobile-bundle-size` | `mobile-bundle-size.yml` | every PR touching `apps/mobile/**` | bundle size delta comment | < 8 min |
| `mobile-i18n` | `mobile-i18n.yml` | every PR touching `lib/**` or `lib/l10n/**` | ARB key coverage | < 3 min |

### 1.1 `mobile-ci.yml` — every PR

```yaml
name: mobile-ci
on:
  pull_request:
    paths: ['apps/mobile/**', '.github/workflows/mobile-ci.yml',
            'packages/shared-types/**', 'tool/contracts/**', 'tool/perf_lints/**']
  push:
    branches: [main]
    paths: ['apps/mobile/**']
concurrency:
  group: mobile-ci-${{ github.ref }}
  cancel-in-progress: true
jobs:
  static:
    runs-on: ubuntu-latest
    timeout-minutes: 8
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 8.10.0 }
      - uses: actions/setup-node@v4
        with: { node-version: 18.17.0, cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: dart format --output=none --set-exit-if-changed .
        working-directory: apps/mobile
      - run: flutter analyze --fatal-infos
        working-directory: apps/mobile
      - run: dart run custom_lint
        working-directory: apps/mobile
      - run: dart run dart_code_metrics:metrics analyze lib --reporter=github
        working-directory: apps/mobile
      - run: dart run dependency_validator
        working-directory: apps/mobile
      - run: dart run import_sorter:main --no-comments --exit-if-changed
        working-directory: apps/mobile

  test:
    runs-on: ubuntu-latest
    timeout-minutes: 12
    needs: static
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter test --coverage --reporter expanded --machine > test-results.json
        working-directory: apps/mobile
      - run: dart run tool/qa/check_coverage.dart --min 0.85 --paths lib/features
        working-directory: apps/mobile
      - uses: codecov/codecov-action@v4
        with: { files: apps/mobile/coverage/lcov.info }

  goldens:
    runs-on: macos-14
    timeout-minutes: 10
    needs: static
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter test --tags golden --reporter expanded
        working-directory: apps/mobile
      - if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: apps/mobile/test/goldens/failures/

  contracts:
    runs-on: ubuntu-latest
    timeout-minutes: 6
    needs: static
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 8.10.0 }
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter @radha/shared-types build
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: dart pub global activate quicktype
      - run: dart run tool/contracts/diff_dtos.dart
        working-directory: apps/mobile

  tokens:
    runs-on: ubuntu-latest
    timeout-minutes: 4
    needs: static
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable', cache: true }
      - run: dart run tool/design/lint_tokens.dart
        working-directory: apps/mobile

  i18n:
    runs-on: ubuntu-latest
    timeout-minutes: 3
    needs: static
    steps:
      - uses: actions/checkout@v4
      - run: bash tool/i18n/check_arb_coverage.sh
        working-directory: apps/mobile
```

The PR auto-comment workflow (§7) summarises each job and posts a single comment per PR.

### 1.2 `mobile-perf.yml` — perf integration suite

```yaml
name: mobile-perf
on:
  pull_request:
    types: [labeled, synchronize]
  schedule:
    - cron: '0 4 * * 1'   # Monday 04:00 UTC
jobs:
  perf:
    if: github.event_name == 'schedule' || contains(github.event.pull_request.labels.*.name, 'perf-check')
    runs-on: [self-hosted, mobile, pixel-4a]
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable' }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter drive --profile -t integration_test/perf/cold_start_test.dart
        working-directory: apps/mobile
      - run: flutter drive --profile -t integration_test/perf/scan_to_verdict_test.dart
        working-directory: apps/mobile
      - run: flutter drive --profile -t integration_test/perf/memory_soak_test.dart
        working-directory: apps/mobile
      - run: dart run tool/qa/check_perf_budget.dart --report build/perf-report.json
        working-directory: apps/mobile
      - uses: actions/upload-artifact@v4
        with:
          name: perf-report
          path: apps/mobile/build/perf-report.json
```

`check_perf_budget.dart` reads the budget table from `00_MASTER_FRONTEND_ROADMAP.md` (mirrored in code) and fails on any miss.

### 1.3 `mobile-patrol.yml` — Patrol E2E

```yaml
name: mobile-patrol
on:
  push:
    branches: [main]
    paths: ['apps/mobile/**']
  pull_request:
    types: [labeled, synchronize]
jobs:
  patrol:
    if: github.event_name == 'push' || contains(github.event.pull_request.labels.*.name, 'patrol-required')
    runs-on: [self-hosted, mobile, device-farm]
    timeout-minutes: 35
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable' }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: dart pub global activate patrol_cli 3.4.0
      - run: patrol test --target integration_test/patrol/ --device pixel_4a_api_34
        working-directory: apps/mobile
      - run: patrol test --target integration_test/patrol/ --device iphone_se_2_ios17
        working-directory: apps/mobile
      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: patrol-reports
          path: apps/mobile/build/patrol/
```

Self-hosted runners host the device farm. Their uptime is owned by the QA Lead (see `FRONTEND_QA_SYSTEM.md` §10).

### 1.4 `mobile-release.yml` — tag `mobile-v*`

```yaml
name: mobile-release
on:
  push:
    tags: ['mobile-v*']
jobs:
  android:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable' }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter build appbundle --flavor prod --release --obfuscate --split-debug-info=build/symbols
        working-directory: apps/mobile
      - name: Upload symbols to Sentry
        run: sentry-cli debug-files upload --include-sources build/symbols
        working-directory: apps/mobile
        env:
          SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
      - run: dart run tool/release/check_no_dev_strings.dart
        working-directory: apps/mobile
      - uses: actions/upload-artifact@v4
        with:
          name: android-aab
          path: apps/mobile/build/app/outputs/bundle/prodRelease/*.aab

  ios:
    runs-on: macos-14
    timeout-minutes: 40
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.22.x', channel: 'stable' }
      - run: flutter pub get
        working-directory: apps/mobile
      - run: dart run build_runner build --delete-conflicting-outputs
        working-directory: apps/mobile
      - run: flutter build ipa --flavor prod --release --obfuscate --split-debug-info=build/symbols
        working-directory: apps/mobile
      - name: Upload dSYM to Sentry
        run: sentry-cli debug-files upload --include-sources build/symbols
        working-directory: apps/mobile
      - run: dart run tool/release/check_privacy_manifest.dart
        working-directory: apps/mobile
```

The release pipeline does not auto-publish. After artifacts upload, the Release Manager runs the manual Play / App Store upload through Fastlane.

### 1.5 `mobile-bundle-size.yml`

A small pipeline that builds a release APK for the touched flavor, compares the size to `main`, and posts a comment with the delta. Fails the PR if delta exceeds **+750 KB** without a `[size-allowed]` token in the commit message.

### 1.6 `mobile-i18n.yml`

Runs `tool/i18n/check_arb_coverage.sh`. Fails when a key referenced from `lib/` is missing in any of the six locales.

---

## 2. Required checks on `main`

Branch protection on `main` requires the following workflows to be green before merge:

- `mobile-ci / static`
- `mobile-ci / test`
- `mobile-ci / goldens`
- `mobile-ci / contracts`
- `mobile-ci / tokens`
- `mobile-ci / i18n`
- `mobile-bundle-size`
- `mobile-i18n` (when `lib/l10n/**` changes)
- `mobile-patrol / patrol` (post-merge — failures revert the merge or open a hotfix issue automatically)
- `mobile-perf / perf` (weekly; failures open a perf-regression issue)

Approval rules:
- **2 code-owner approvals** for any PR touching `lib/widgets/`, `lib/app/theme/`, or `lib/core/dto/`.
- **1 design-owner approval** for golden-updating PRs.
- **1 product-owner approval** for `lib/l10n/**`.

---

## 3. Verification tooling

### 3.1 Task runner — `melos`

The Flutter project uses [`melos`](https://melos.invertase.dev) as the local task runner.

`apps/mobile/melos.yaml`:

```yaml
name: radha_mobile
packages:
  - .
scripts:
  analyze:
    run: flutter analyze --fatal-infos
  format:
    run: dart format --set-exit-if-changed .
  test:
    run: flutter test --coverage --reporter expanded
  goldens:
    run: flutter test --tags golden
  build:
    run: dart run build_runner build --delete-conflicting-outputs
  watch:
    run: dart run build_runner watch --delete-conflicting-outputs
  perf-lints:
    run: dart run custom_lint
  token-lints:
    run: dart run tool/design/lint_tokens.dart
  contracts:
    run: dart run tool/contracts/diff_dtos.dart
  i18n:
    run: bash tool/i18n/check_arb_coverage.sh
  metrics:
    run: dart run dart_code_metrics:metrics analyze lib --reporter=console
  imports:
    run: dart run import_sorter:main --no-comments
  deps:
    run: dart run dependency_validator
```

Local pre-commit hook runs `melos run format && melos run analyze && melos run perf-lints && melos run token-lints`.

### 3.2 Custom-lint pack — `tool/perf_lints/`

A Dart package that registers `custom_lint` rules:

| Rule ID | Rejects |
|---|---|
| `no_network_image` | `NetworkImage(...)` (use `cached_network_image`) |
| `missing_const` | A reachable widget constructor that could be `const` but is not |
| `unscoped_ref_watch` | `ref.watch(...)` in `build` for a provider known to be never-changing |
| `no_hardcoded_color` | `Color(0x...)` outside `lib/app/theme/` and `lib/widgets/foundation/` |
| `no_hardcoded_text` | `Text('...')` with non-empty literal outside `lib/widgets/foundation/`, `test/`, and any file with `.debug.dart` extension |
| `no_raw_duration` | `Duration(milliseconds: ...)` for animation durations (must use `RadhaMotion`) |
| `no_cupertino_in_screens` | `CupertinoButton`, `CupertinoSwitch`, `CupertinoSlider` inside `lib/features/` |
| `no_cross_feature_import` | `import 'package:radha_mobile/features/<a>/...'` from `features/<b>/` |
| `min_tap_target` | `GestureDetector`/`InkWell` whose enclosing constraint is < 48 dp on either axis |
| `no_print` | `print(...)` in `lib/` (use the logger) |

Each rule is unit-tested in `tool/perf_lints/test/`.

### 3.3 Code metrics — `dart_code_metrics`

`apps/mobile/analysis_options.yaml` configures:

```yaml
dart_code_metrics:
  rules-exclude:
    - test/**
  metrics:
    cyclomatic-complexity: 10
    maximum-nesting-level: 4
    number-of-parameters: 4
    source-lines-of-code: 500
    lines-of-executable-code: 80
  metrics-exclude:
    - test/**
    - tool/**
```

CI runs `dart_code_metrics:metrics analyze lib --fatal-style --fatal-warnings`.

### 3.4 Goldens — `golden_toolkit`

- Goldens stored at `apps/mobile/test/goldens/`.
- `--update-goldens` is **gated**:
  - Local invocation requires `RADHA_ALLOW_GOLDEN_UPDATE=1` env var.
  - CI invocation requires `[update-goldens]` in the commit message **and** a `Goldens reviewed by: <name>` line in the PR description; missing either fails the PR auto-comment.
- `loadAppFonts()` runs in every golden test to ensure Plus Jakarta Sans + JetBrains Mono are loaded.
- Golden device matrix uses `Device.phone`, `Device.iphone11`, `Device.tabletPortrait` from `golden_toolkit`.

### 3.5 Dependency hygiene — `dependency_validator`

Runs every PR. Fails on:
- Unused dependencies in `pubspec.yaml`.
- Imports of packages not declared in `pubspec.yaml`.
- Pinned-to-`any` versions (every dep must have a caret bound).

### 3.6 Import sorting — `import_sorter`

Enforces three groups: `dart:`, `package:`, relative. Within a group, alphabetical.

CI uses `--exit-if-changed` so unsorted imports fail.

### 3.7 Contract drift — `tool/contracts/diff_dtos.dart`

Pseudocode:

```dart
Future<void> main() async {
  final tsRoot = '../../packages/shared-types/src';
  final tmpDart = await Directory.systemTemp.createTemp('quicktype_dart_');
  await Process.run('quicktype', ['--src-lang', 'typescript',
                                  '--lang', 'dart',
                                  '--out', tmpDart.path,
                                  tsRoot]);
  final lockFile = File('.contracts.lock.json');
  final expectedFp = jsonDecode(await lockFile.readAsString()) as Map;
  final currentFp = await fingerprint(tmpDart.path);
  if (!const DeepCollectionEquality().equals(expectedFp, currentFp)) {
    final diff = renderDiff(expectedFp, currentFp);
    stderr.writeln('Contract drift detected:\n$diff');
    exit(1);
  }
  // Compare generated against checked-in:
  final diffOut = await Process.run('diff', ['-r', '-u', tmpDart.path, 'lib/core/dto']);
  if (diffOut.exitCode != 0) {
    stderr.writeln('DTO drift between shared-types and lib/core/dto:\n${diffOut.stdout}');
    exit(1);
  }
}
```

Schema fingerprint pinned in `apps/mobile/.contracts.lock.json`. Bumps require a "contract review" comment from a backend code-owner. The lock file is part of the regular PR review.

### 3.8 Token compliance — `tool/design/lint_tokens.dart`

Walks `apps/mobile/lib/**/*.dart` outside the allow-listed folders and flags:
- `Color(0x...)` and `Colors.<name>` literals.
- Numeric literals used as `EdgeInsets.all(N)` where `N` is not in `{4, 8, 12, 16, 24, 32, 48, 64}`.
- `BorderRadius.circular(N)` where `N` is not in `{4, 8, 12, 16, 24, 9999}`.
- `fontSize:` overrides outside `lib/app/theme/`.
- `fontFamily:` overrides for `Inter`, `Roboto`, `Arial`, `Helvetica`.

Allow-list mechanism: a single-line trailing comment `// design:ok by <reviewer>` on the same line bypasses the rule, but `tool/design/audit_design_ok.dart` lists every such waiver and posts a count to the PR comment so the team tracks debt.

### 3.9 i18n coverage — `tool/i18n/check_arb_coverage.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
root="$(dirname "$0")/../.."
keys_used=$(grep -roE "AppLocalizations\.of\(context\)!\.[a-zA-Z][a-zA-Z0-9_]*" "$root/lib" \
  | sed -E 's/.*!\.([a-zA-Z0-9_]+).*/\1/' | sort -u)
for arb in "$root/lib/l10n"/*.arb; do
  for key in $keys_used; do
    if ! jq -e --arg k "$key" 'has($k)' "$arb" > /dev/null; then
      echo "MISSING: $arb is missing key '$key'" >&2
      exit 1
    fi
  done
done
echo "i18n coverage OK ($(echo "$keys_used" | wc -l) keys × $(ls "$root/lib/l10n"/*.arb | wc -l) locales)"
```

### 3.10 Telemetry verification

Two periodic checks (run nightly via `mobile-telemetry-check.yml`):

1. **Synthetic telemetry round-trip.** A canary integration test on the device farm fires three known events tagged `synthetic=1`. A backend probe queries BE-29 within 60 s and asserts the events arrived. Failure pages on-call.
2. **Sentry symbol integrity.** For the latest release tag, the script queries Sentry's `dif` API and asserts the `mapping.txt` (Android) and `dSYM` (iOS) artifacts exist for the corresponding build ID. Missing symbols fail the next deploy.

---

## 4. Pre-merge verification checklist (auto-comment)

A GitHub Action (`mobile-pr-checklist.yml`) posts and updates a single comment per PR. The comment contains:

```markdown
### Mobile PR checklist

| Check | Status |
|---|---|
| `mobile-ci / static` | ✅ |
| `mobile-ci / test` (coverage delta: +0.4%) | ✅ |
| `mobile-ci / goldens` | ✅ |
| `mobile-ci / contracts` | ✅ |
| `mobile-ci / tokens` (waivers: 2) | ⚠️ 2 `// design:ok` waivers |
| `mobile-ci / i18n` (6 locales × 412 keys) | ✅ |
| `mobile-bundle-size` (delta: +210 KB) | ✅ |
| `mobile-patrol` (PR not labeled) | ⏭ skipped |
| Goldens reviewed | ❌ no `Goldens reviewed by:` line |
| Phase Sign-off Gate signatures | ❌ Reviewer signature missing |
| ADR mentioned | ✅ ADR-002 |
| ENVIRONMENT_CONFIG.md updated | n/a |
```

Required-to-merge:
- All checks ✅ (or ⏭ when intentionally skipped).
- No new design tokens without a corresponding ADR.
- No new env vars without an `ENVIRONMENT_CONFIG.md` update.
- Phase doc Sign-off Gate signatures present (for phase PRs).
- Goldens not blindly updated (commit message and PR description checks both pass).

The auto-comment job re-runs on every push to keep the checklist current.

---

## 5. Post-merge verification

When a PR merges to `main`, the following run automatically and post artifacts to the merge commit:

### 5.1 Bundle size diff

`mobile-bundle-size.yml` re-runs and posts the absolute size for each flavor along with the diff vs. `main^`. Threshold: > **+750 KB** opens an automated bundle-size issue tagged `perf-regression`.

### 5.2 Coverage delta

`mobile-ci / test` posts the LCOV diff against `main^`:
- Total coverage delta.
- Per-feature coverage table.
- New uncovered lines highlighted.

A negative delta on `lib/features/<phase>/**` opens a "coverage regression" issue.

### 5.3 Golden diff thumbnail

Any updated goldens have their before/after thumbnails posted as an inline comment on the merge commit. The thumbnail strip uses `golden_toolkit`'s diff renderer and embeds the image via the GitHub artifact link.

### 5.4 Patrol post-merge

`mobile-patrol.yml` runs on the merge commit. Failures revert the merge by opening a revert PR and pinging the on-call channel.

### 5.5 Telemetry probe

The synthetic telemetry round-trip runs against the staging build produced by the merge. Failures alert on-call.

---

## 6. Local developer flow

The local equivalent of the CI pipeline:

```bash
# One-time setup
melos bootstrap
melos run build

# Tight loop
melos run watch          # in another terminal
flutter run --flavor dev -t lib/main_dev.dart

# Pre-push
melos run format
melos run analyze
melos run perf-lints
melos run token-lints
melos run test
melos run goldens
```

A pre-commit hook (`.husky/pre-commit`) runs `melos run format && melos run analyze && melos run perf-lints && melos run token-lints`. The pre-push hook adds `melos run test --tags=!golden && melos run i18n && melos run contracts`.

Hooks are managed through Husky (the project root already has Husky for the backend); mobile hooks are added under the same configuration.

---

## 7. Failure handling and recovery

### 7.1 Flaky goldens

When a golden flake is suspected:
1. The author re-runs `mobile-ci / goldens` once.
2. If it flakes a second time, the suspected golden is moved to `test/goldens/quarantine/` and a `golden-flake` issue opened.
3. Quarantined goldens must be repaired or deleted within 7 days.

### 7.2 Contract drift after a backend bump

When BE merges a `@radha/shared-types` change:
1. CI on the next mobile PR will fail `mobile-ci / contracts`.
2. The frontend developer runs `dart run tool/contracts/regenerate_dtos.dart` locally; the script regenerates DTOs and bumps `.contracts.lock.json`.
3. The PR includes the lock-file diff. A backend code-owner must approve the lock bump.

### 7.3 Patrol device-farm outage

If the Patrol runner is offline at merge time:
1. The merge waits up to 30 minutes for the runner to come back.
2. If still offline, the QA Lead may issue a one-time skip (recorded in the merge commit message).
3. Patrol runs on the next merge; if the new merge fails, both merges are reverted.

### 7.4 Perf regression

A perf-budget miss in the weekly cron run:
1. Opens a `perf-regression` issue with the metric, the offending phase area, and the timeline JSON attached.
2. Blocks the next release until resolved.

---

## 8. Tool versioning

Tool versions are pinned in three places, all kept in sync:

| Tool | Pinned in | Version |
|---|---|---|
| Flutter SDK | `apps/mobile/.fvmrc`, `pubspec.yaml`, `mobile-ci.yml` | 3.22.x |
| Dart SDK | implied by Flutter | 3.4.x |
| `melos` | `pubspec.yaml` dev_dependencies | ^4.0.0 |
| `patrol_cli` | `mobile-patrol.yml`, `pubspec.yaml` | 3.4.0 |
| `quicktype` | `pubspec.yaml` activate command | latest stable, pinned monthly |
| `dart_code_metrics` | `pubspec.yaml` | ^5.7.6 |
| `custom_lint`, `riverpod_lint` | `pubspec.yaml` | ^0.6.0 / ^2.3.0 |
| `golden_toolkit` | `pubspec.yaml` | ^0.15.0 |
| `dependency_validator`, `import_sorter` | `pubspec.yaml` | latest |

Bumping any of these requires:
- A Dependabot or manual PR with the lockfile change.
- Green CI under the new version.
- An entry in the mobile CHANGELOG.

---

## 9. Audit and traceability

Every CI run uploads:
- `test-results.json` (Rung 2 + 3 outputs).
- `coverage/lcov.info` (Rung 2).
- `golden-failures/` on golden failures.
- `perf-report.json` from perf jobs.
- `patrol/` reports from Patrol jobs.

These artifacts are retained for 90 days. The release pipeline copies them into the QA artifact bucket under `qa-artifacts/<phase>/<git-sha>/` for the 18-month retention required by `FRONTEND_QA_SYSTEM.md` §13.

The PR auto-comment links to every artifact bundle. Reviewers click through; nothing is hidden behind "see logs".

---

## 10. Disaster recovery

The verification system itself can fail:
- A bad `custom_lint` rule release breaks every PR. Mitigation: pinned version (§8); bumps go through a single canary PR.
- A self-hosted runner image rot breaks Patrol. Mitigation: monthly runner-image rebuilds (`tool/runner/rebuild_image.sh`).
- A Sentry outage blocks symbol upload at release time. Mitigation: the release job gates on symbol upload but emits an artifact tarball that the Release Manager can re-upload manually within 24 h.

The Frontend Tech Lead reviews a verification health report quarterly: false-positive rate, average PR pipeline time, runner uptime, and waiver count from the token-lint allow-list.

---

**See also**: `ADR_LOG.md` (ADR-001/008/009/011), `FRONTEND_QA_SYSTEM.md` (gates that this system enforces), `FRONTEND_DESIGN_SYSTEM.md` (token contract), `FRONTEND_PHASES/FE-01_PHASE.md` (initial CI bootstrap), `FRONTEND_PHASES/FE-39_PHASE.md` (perf budget owner), `FRONTEND_PHASES/FE-40_PHASE.md` (release pipeline).
