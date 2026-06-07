# RADHA Mobile — Frontend QA System

> **Purpose.** This is the QA process every FE-NN phase passes before sign-off. It is an enforced ladder, not a guideline. Phase docs reference it from their **Sign-off Gate** section. Reviewers refuse to approve phases that skip rungs.
>
> **Scope.** Mobile only (`apps/mobile/`). The web QA process is documented separately and is not blocked by this file.
>
> **Owners.** QA Lead (process), Frontend Tech Lead (gate enforcement), Design Lead (visual bar), Accessibility Lead (a11y gate), Product Manager (microcopy).
>
> **Constraints.** ADR-009 (Patrol + golden_toolkit), ADR-002 (Riverpod test overrides), ADR-006 (theme contracts).

---

## 1. The 11-rung quality gate ladder

Every phase passes these gates **in order**. A failure at rung N blocks rungs N+1..11. Skipping rungs requires a written waiver from the Frontend Tech Lead, attached to the phase PR.

### Rung 1 — Static analysis

```bash
cd apps/mobile
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
dart run custom_lint
```

- `flutter analyze` must report **zero** infos, warnings, or errors. The `--fatal-infos` flag promotes infos to failures.
- `dart format` is enforced at print-width 100 (matches the project Prettier baseline).
- `custom_lint` runs the perf + token + i18n rule pack from `tool/perf_lints/`:
  - No `NetworkImage` (use `cached_network_image`).
  - Reachable `const` constructors must be `const`.
  - `ref.watch` must be scoped (no `ref.watch` in `build` for never-changing providers).
  - No hardcoded `Color(0x...)` outside `lib/app/theme/` and `lib/widgets/foundation/`.
  - No hardcoded text strings outside `lib/l10n/*.arb` for user-visible Text widgets.
  - No raw `Duration(milliseconds: ...)` in screen code (must use `RadhaMotion`).

### Rung 2 — Unit tests

```bash
flutter test --coverage --reporter expanded
```

- Coverage gate: **≥ 85% line coverage on `lib/features/<phase>/**`** (the phase's own code).
- Coverage gate: **≥ 80% on `lib/core/**`** and `lib/data/**`.
- `lcov` report uploaded to Codecov; PR comment must show no negative delta on the touched files.
- Tests must run deterministically (no `Future.delayed` longer than `Duration.zero` for control flow; use fake clocks).

### Rung 3 — Widget tests

Same `flutter test` invocation; widget tests live in `test/widget/` and `test/<feature>/`.

Every screen has tests for **five canonical states**:
1. **Loading** — provider in `AsyncValue.loading()` → SkeletonLoader visible.
2. **Loaded** — provider in `AsyncValue.data(...)` with a populated fixture → primary content visible.
3. **Empty** — provider in `AsyncValue.data(<empty>)` → `EmptyState` visible with the correct copy.
4. **Error** — provider in `AsyncValue.error(...)` → `ErrorState` visible with retry CTA wired.
5. **Disabled / Read-only** — entitlement provider returns "no permission" → primary CTAs disabled, semantics announce "disabled".

Riverpod overrides (`ProviderScope(overrides: [...])`) drive every state. No mock libraries against globals.

### Rung 4 — Golden tests

```bash
flutter test --tags golden
```

Goldens cover:
- **Light mode** + **dark mode**.
- **RTL** (`ar-EG` smoke locale) for layout safety.
- **Three text scales**: xs (0.85), md (1.0), xxl (2.0).

That is **3 themes × 3 scales = 9 baselines per screen state**, generated for every primitive in `lib/widgets/` and every primary screen.

Update protocol:
- `flutter test --update-goldens` is **only allowed** when:
  1. The commit message contains `[update-goldens]`.
  2. A reviewer signs the PR description with `Goldens reviewed by: <name>`.
  3. The PR includes a "before/after" thumbnail attached to the conversation.
- Bulk golden updates without these three checks fail the auto-comment workflow.

### Rung 5 — Integration tests

```bash
flutter test integration_test/<phase>_test.dart -d <device>
```

Every phase ships at minimum these three flows:
- **Happy path** — primary success scenario, end-to-end, with a real Drift DB and stubbed Dio responses.
- **Error path** — provider error → user retries → recovers.
- **Offline path** — airplane mode → action queues to outbox → network returns → outbox flushes (FE-08, FE-36 rely on this).

Integration tests run on a real device or device farm — never on a Linux runner without a display. Output: HTML report under `build/integration/`.

### Rung 6 — Patrol E2E (permissioned flows only)

```bash
patrol test --target integration_test/patrol/<phase>_e2e.dart
```

Patrol covers flows that touch native dialogs:
- **FE-09** — notification permission prompt.
- **FE-11/FE-12** — OTP autofill, SMS retriever.
- **FE-17** — camera permission, photo capture (via Patrol's native automation).
- **FE-21** — push notification deep link from background and terminated states.
- **FE-29** — file picker (supplier invoice photo).
- **FE-31** — task push deep link.
- **FE-40** — biometric unlock (where enabled).

Patrol runs on the merge-to-main pipeline, not on every PR (cost). PRs labeled `patrol-required` opt into the suite.

### Rung 7 — Manual QA on the physical device matrix

Required devices for every UI phase:

| Class | Device | OS | Why |
|---|---|---|---|
| Low-end Android | **Redmi Go** (1 GB RAM, Android 10) | Android 10 | proves performance budget on weakest hardware in the target market |
| Mid-range Android | **Pixel 4a** | Android 14 | reference device for jank-rate, battery, cold start |
| Low-end iOS | **iPhone SE (2nd gen)** | iOS 15 minimum | smallest supported iOS surface |
| Older iOS | **iPhone 8** | iOS 16 | proves iOS 15 build still installs |

Manual QA checklist per phase (signed by reviewer):

```
[ ] App launches in <2.5s on Pixel 4a, <4s on Redmi Go (release build).
[ ] Every screen tested in light mode + dark mode.
[ ] Every screen tested at xs and xxl text scale (no clipping).
[ ] Every CTA produces the correct haptic (verified by feel).
[ ] Every animation respects the system reduce-motion setting.
[ ] All 6 locales render without overflow on the smallest device.
[ ] Back button works from every screen, including error states.
[ ] Permission prompts appear at the correct moment (not on app launch).
[ ] Network-down behaviour shows the correct empty/offline state.
[ ] Pull-to-refresh works where present and only where present.
[ ] No console errors or warnings during a 2-minute exploratory session.
Reviewer: __________________   Date: __________
```

The reviewer must hold one of each device. Approval from a desk without device interaction is invalid.

### Rung 8 — Accessibility

- **TalkBack walk** on Android (Pixel 4a): every screen narrates correctly, focus order matches reading order, no "Button. Button. Button." stacks.
- **VoiceOver walk** on iOS (iPhone SE 2): same.
- **Dynamic type at xxLarge** (`Settings > Accessibility > Display > Text Size`): no clipping, no overflow.
- **Reduced motion ON** (`Settings > Accessibility > Reduce Motion`): every Lottie swaps to static frame, no parallax, no Hero zoom.
- **High contrast / Increase Contrast ON**: outlines double in alpha, focus rings thicken.
- **Color-blind audit** for chips and status indicators: a Deuteranopia simulator is run on the OHS dashboard (FE-25), recall list (FE-21), and expiry calendar (FE-20).

Per-phase a11y checklist:

```
[ ] Every Semantics-relevant widget has a meaningful semanticLabel.
[ ] Decorative Lotties carry excludeSemantics: true.
[ ] Dynamic type tested at scaleFactor 2.0; layouts do not clip.
[ ] Reduced motion verified; Lotties are static frames.
[ ] TalkBack and VoiceOver scripts pass without dead ends.
[ ] All foreground/background pairs meet WCAG AA.
A11y reviewer: __________________   Date: __________
```

### Rung 9 — Performance

The performance budget from `00_MASTER_FRONTEND_ROADMAP.md` is enforced:

| Metric | Budget | Tool |
|---|---|---|
| Cold start to first frame | < 1.5 s on Pixel 4a (release) | `flutter run --profile --trace-startup` |
| Splash to home (logged-in) | < 2.5 s | DevTools timeline |
| Frame time | 16.6 ms (60 fps) | DevTools timeline |
| Jank rate | < 1% of frames during Hero transitions | DevTools |
| Scan to verdict | < 1.5 s p95 (online) | integration test instrumentation |
| Offline scan to local cache | < 800 ms | integration test instrumentation |
| APK size (release, arm64-v8a) | ≤ 35 MB | `flutter build apk --analyze-size` |
| Memory ceiling (5-min soak) | < 220 MB | DevTools memory tab |
| Battery drain (1 hr scanning) | < 8% on Pixel 4a | manual measurement |

UI phases ship a DevTools timeline JSON in `qa-artifacts/<phase>/timeline.json` proving the budget was met. FE-39 owns the cumulative budget audit.

### Rung 10 — Backend alignment (contract drift)

```bash
dart run tool/contracts/diff_dtos.dart
```

This script:
1. Runs `quicktype` against `packages/shared-types/src/*.ts`.
2. Generates Dart equivalents in a temp folder.
3. Diffs against `apps/mobile/lib/core/dto/`.
4. Fails CI on any drift.

`apps/mobile/.contracts.lock.json` pins the schema fingerprint; bumps require an explicit "contract review" comment from the backend lead on the PR.

The phase's QA artifacts include the lock-file diff in plain text.

### Rung 11 — Release gate (FE-40 only)

The release gate combines all earlier rungs plus:

- **R8 / ProGuard** obfuscation enabled, mappings uploaded to Sentry.
- **TLS pinning** verified against staging cert; misconfigured pin fails launch in staging smoke.
- **Integrity** (Play Integrity API on Android, App Attest on iOS) verified once per session.
- **Secure storage audit**: JWT, refresh token, biometric flag stored in Keychain/Keystore, never SharedPreferences.
- **Privacy manifest** (iOS `PrivacyInfo.xcprivacy`) lists every API used and reason.
- **Data Safety form** (Play Console) matches `core/dto/` payloads (no undeclared fields).
- **Crash smoke** in staging: 200 sessions on staging produce zero un-symbolicated crashes.
- **Final QA sign-off** from QA Lead, Design Lead, A11y Lead, Engineering Manager, PM.

Owned end-to-end by FE-40. Earlier phases are not subject to this rung.

---

## 2. Per-phase QA artifacts (mandatory before sign-off)

Every phase PR includes a `qa-artifacts/<phase>/` folder containing:

| File | Format | Source |
|---|---|---|
| `test-report.html` | HTML | `flutter test` HTML reporter |
| `coverage.html` + `lcov.info` | HTML + LCOV | `flutter test --coverage` + `genhtml` |
| `golden-diff.png` (or `goldens-clean.txt`) | PNG / text | `golden_toolkit` diff or "no diff" banner |
| `timeline.json` | JSON | DevTools timeline export (UI phases only) |
| `screenshots/` | 12 PNGs | 6 light + 6 dark, primary states |
| `walkthrough.mp4` | ≤ 2 min | recorded on a real device |
| `manual-qa-checklist.md` | signed Markdown | Rung 7 checklist |
| `a11y-checklist.md` | signed Markdown | Rung 8 checklist |
| `contract-diff.txt` | text | Rung 10 output |
| `perf-report.md` | Markdown | Rung 9 metrics with budget delta |

The PR template requires every artifact path. Missing artifacts auto-comment a checklist of gaps.

The 12 screenshots cover the canonical states: loading, loaded, empty, error, disabled, success — in both modes. Screenshot naming convention: `<phase>-<state>-<mode>.png` (e.g. `fe-17-scanner-loaded-dark.png`).

Walkthrough video conventions:
- ≤ 2 minutes total.
- Recorded at native 60 fps on the reference device.
- Narration is optional; on-screen captions are required for non-obvious gestures.
- Filed alongside the PR; not committed to git (uploaded to the QA artifact bucket).

---

## 3. Bug taxonomy and SLAs

| Severity | Definition | Examples | SLA |
|---|---|---|---|
| **Critical** | App unusable; data loss; security exposure | crash on launch; outbox loses scans; JWT logged in plaintext | block release; fix < 24 h; hotfix path |
| **High** | Major feature broken or wrong | OTP loop never resolves; expiry calendar off by one day | block phase sign-off; fix in same sprint |
| **Medium** | Visible defect with workaround | wrong haptic on a button; layout overflow at xxl text scale | next sprint; fix before parent layer ships |
| **Low** | Polish / nice-to-have | minor copy tweak; small icon misalignment | tracked, batched into a polish phase |

Every bug filed has: severity, phase, repro steps, device + OS + locale + theme, expected vs actual, screenshot or video, error correlation ID (if applicable). Sentry issues link back to bug IDs in the issue tracker.

A phase **cannot sign off** with open Critical or High bugs against it.

---

## 4. Regression matrix

Every phase regression-tests its predecessors that are at risk of breaking:

| Phase | Must regression-test |
|---|---|
| FE-04 (motion) | FE-03 component states — animations must not break visuals |
| FE-07 (auth state) | FE-05 router guards |
| FE-08 (Drift) | FE-06 outbox semantics |
| FE-13 (paywall) | FE-12 OTP success path (entry into subscribe) |
| FE-17 (scanner) | FE-06 quota interceptor (BE-46) |
| FE-19 (product detail) | FE-18 scan card hero choreography |
| FE-25 (business dashboard) | FE-07 role-based gating |
| FE-28 (expiry business) | FE-22 OCR input path |
| FE-30 (inventory) | FE-29 GRN posting (stock side-effect) |
| FE-31 (tasks) | FE-21 push deep link semantics |
| FE-33 (animation pack) | FE-04 motion tokens, FE-09 splash |
| FE-35 (i18n) | every prior phase's user-visible strings |
| FE-36 (sync UI) | FE-08 outbox |
| FE-38 (a11y) | every prior phase, full TalkBack/VoiceOver pass |
| FE-39 (perf) | every prior phase against the perf budget |
| FE-40 (release) | every prior phase end-to-end |

The regression matrix is enforced by a script (`tool/qa/check_regression.dart`) that requires the phase's PR description to mention the listed predecessors and link to a passing run.

---

## 5. Definition of Done (per phase)

A phase is Done when **all** of the following are true:

```
[ ] All 11 quality gate rungs pass.
[ ] All per-phase QA artifacts present and signed.
[ ] Coverage delta on touched files is ≥ 0.
[ ] No new Critical or High bugs filed against the phase.
[ ] Regression matrix predecessors verified green.
[ ] All 6 locales render without overflow on the smallest device.
[ ] Designer signed motion + microcopy on hardware.
[ ] Accessibility reviewer signed TalkBack + VoiceOver flows.
[ ] PM signed microcopy in all 6 languages (en, hi, ta, te, bn, mr).
[ ] Manual QA reviewer ran on each device in the device matrix.
[ ] CHANGELOG entry written.
[ ] Phase doc Sign-off Gate signatures present.
[ ] No unaddressed code review comments.
```

The Sign-off Gate at the bottom of the phase doc is the canonical record. PR merge is blocked until the developer and reviewer signatures are in place.

---

## 6. Reviewer responsibilities

The reviewer of a phase PR:

1. **Holds a real device.** Approval is invalid without running the build on a physical Pixel 4a (Android) and iPhone SE 2 (iOS) at minimum.
2. **Reviews goldens visually.** Opens every changed PNG. A green CI alone is insufficient — the reviewer must confirm the visual change is intentional.
3. **Walks every screen the phase touches** in both light and dark mode at the default text scale, then once at xxl.
4. **Verifies haptics by feel** on at least one Android and one iOS device.
5. **Reads the code with token-lint awareness:** any hardcoded literal (color, spacing, duration) outside permitted folders is a comment.
6. **Verifies the manual QA checklist matches reality** — does not approve a checklist signed by the developer alone.
7. **Tests the offline path** for any phase that writes data.
8. **Confirms accessibility** by switching TalkBack/VoiceOver on for at least one screen.

Reviewers who cannot perform this routine flag the PR for a different reviewer.

---

## 7. Designer responsibilities

The Design Lead (or delegate) signs every UI phase:

1. **Reviews motion on hardware.** Looking at Lottie files in a browser is insufficient; spring curves and stagger timings must be felt on the target device.
2. **Reviews microcopy in context.** All copy is reviewed inside the actual screen, not in a string sheet, to catch line breaks and overflow.
3. **Confirms tokens.** Every color, spacing, radius, shadow value seen on screen must trace to a token in `FRONTEND_DESIGN_SYSTEM.md`. Off-token values are rejected.
4. **Confirms dark mode parity.** Every screen looks intentional in dark mode (not "dark for the sake of dark").
5. **Approves Empty + Error + Loading states** as first-class designs, not afterthoughts.

---

## 8. Accessibility reviewer responsibilities

The Accessibility Lead (or delegate):

1. **Runs TalkBack on Android** for every new screen; verifies semantic labels are meaningful.
2. **Runs VoiceOver on iOS** for the same.
3. **Tests dynamic type at xxLarge** and at xs.
4. **Tests reduced motion ON.**
5. **Tests high contrast ON.**
6. **Color-blind simulates** any screen using color to convey meaning (status chips, progress, recall severity).
7. **Confirms WCAG AA** contrast on every text-on-surface pair using the design system tokens.

Phases that fail any of the above receive a hard block until remediated.

---

## 9. PM responsibilities

The Product Manager:

1. **Approves microcopy in all 6 languages.** Translations are reviewed against the source-of-truth English copy and validated for tone and clarity by native speakers (vendor or in-house, recorded in the phase QA artifacts).
2. **Approves user-visible string changes** before goldens are updated.
3. **Validates the empty + error microcopy** has personality — not "Something went wrong" generics.
4. **Confirms the success state** earns a moment (haptic, micro-animation) where the design intends it.

---

## 10. QA Lead responsibilities

The QA Lead owns the process itself:

1. Maintains the device matrix; replaces devices when a manufacturer EOLs an OS.
2. Maintains the regression matrix; updates it whenever a phase changes scope.
3. Audits a random 10% of phase QA artifact bundles per quarter for drift.
4. Owns the Patrol device-farm runner uptime.
5. Runs the per-quarter exploratory bug-bash, escalates findings to the relevant phase owners.

---

## 11. CI surface for QA gates

Every gate above maps to a CI job:

| Gate | Workflow | Trigger |
|---|---|---|
| Rungs 1–4 | `mobile-ci.yml` | every PR |
| Rung 5 (integration) | `mobile-integration.yml` | PRs touching `lib/features/**` |
| Rung 6 (Patrol) | `mobile-patrol.yml` | merge to `main`, or PR with `patrol-required` label |
| Rung 7 (manual QA) | manual checklist in PR | always |
| Rung 8 (a11y) | manual checklist + `flutter test --tags a11y` | always |
| Rung 9 (perf) | `mobile-perf.yml` | PRs labeled `perf-check`, and merge to `main` |
| Rung 10 (contract) | `mobile-ci.yml` (sub-job) | every PR |
| Rung 11 (release) | `mobile-release.yml` | tag `mobile-v*` |

Detailed workflow specs live in `FRONTEND_VERIFICATION_SYSTEM.md`.

---

## 12. Escalation path

When a phase fails a gate and the team disagrees on severity:

1. **Developer + Reviewer** attempt resolution within the PR thread (target 1 day).
2. Unresolved → **Frontend Tech Lead + QA Lead** review and decide (target 1 day).
3. Still unresolved → **Engineering Manager + Design Lead + Product** triage (target 1 day).
4. Still unresolved → schedule a 30-minute live walkthrough on the device with all parties; decision recorded in the phase doc.

The default decision is **block**. Phases ship with a green ladder, not with debate hanging.

---

## 13. Audit trail

Every phase's QA artifacts are committed to a separate `qa-artifacts` branch (or uploaded to the QA artifact bucket if size-prohibitive) and tagged with the phase ID and date. The audit trail allows post-incident reviews to reconstruct the state of the app at a point in time.

Retention: 18 months. Older artifacts are summarised into a phase ledger and deleted to control storage cost.

---

**See also**: `ADR_LOG.md` (ADR-009 testing stack), `FRONTEND_DESIGN_SYSTEM.md` (golden contract), `FRONTEND_VERIFICATION_SYSTEM.md` (CI implementation), `00_MASTER_FRONTEND_ROADMAP.md` (perf budget).
