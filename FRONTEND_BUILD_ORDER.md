# RADHA Mobile — Frontend Build Order

> **Version**: `v1.0.0`
> **Last updated**: 2026-05-17
> **Owner**: Frontend Tech Lead (build order custodian) · Engineering Manager (resourcing)
> **Status**: **Locked for v1.** Reordering requires an ADR and re-baselining the wave map.

This document is the **operational sequence** for building the RADHA Flutter app. The 40 phase docs (`FRONTEND_PHASES/FE-NN_PHASE.md`) describe what each phase delivers; this file describes when each phase can start, who can work in parallel, and what must be true before the next wave begins.

Constrained by:
- **ADR-001** — 40-phase shape locked.
- **ADR-011** — single monorepo (so phases share a CI surface).
- `FRONTEND_PHASES/00_MASTER_FRONTEND_ROADMAP.md` — defines the phases and the wave map.
- `PHASE_DEPENDENCY_MAP.md` — adjacent dependency graph (BE/FE/DB).
- `FRONTEND_QA_SYSTEM.md` — defines what "done" means for handoff.

---

## 1. Critical path (sequential, no parallelism)

The first four phases form a single sequential chain. Nothing else can start until they finish. They take ~2 calendar weeks with one senior Flutter engineer.

```text
FE-01 ──► FE-02 ──► FE-03 ──► FE-04
 (Init)   (Theme)   (Components)  (Motion)
  2-3d     3-4d      5-6d           3-4d
```

**Why sequential**:

- **FE-01 → FE-02**: Theme tokens need a workspace, flavors, and a CI gate to land in. Tokens authored before flavors exist would re-baseline twice.
- **FE-02 → FE-03**: Components consume tokens. Building a `PrimaryButton` against placeholder colors means rebuilding it the moment FE-02 lands. Hard fail on golden tests.
- **FE-03 → FE-04**: Motion couples to component shapes (e.g. Hero choreography depends on `AppCard` having stable identity widgets). FE-04 also exercises every primitive's animated states for golden coverage.
- **FE-04 → first parallel wave**: Motion locks in the animation vocabulary that every later phase consumes via `RadhaMotion`. Without it, screens hardcode durations and fail token-lint.

**Total critical-path duration**: 13–17 calendar days with a single engineer; 11–14 days if a second engineer pairs on FE-03's component sprawl.

**Critical-path discipline**: do not start FE-05/FE-06/FE-07 before FE-04 closes its sign-off gate. Two days of waiting now saves a week of refactor later.

---

## 2. Wave A — Foundation parallel (after FE-04)

Once FE-04 is signed off, three engineers fan out on independent foundation tracks.

```text
                         FE-04 ✓
                            │
                ┌───────────┼───────────┐
              FE-05       FE-06        FE-07
            (Router)     (API Client) (State + Auth)
              3-4d        3-4d          3-4d
                            │             │
                            └─────────────┤
                                          ▼
                                        FE-08
                                       (Drift + Sync UX)
                                          4-5d
```

| Phase | Predecessors | Engineers | Calendar duration | Critical path? |
|---|---|---|---|---|
| FE-05 Router | FE-04 | 1 | 3–4 days | No — independent |
| FE-06 API Client | FE-04 | 1 | 3–4 days | Yes — feeds FE-07 |
| FE-07 State + Auth | FE-05 + FE-06 | 1 | 3–4 days | Yes — feeds FE-08 |
| FE-08 Drift + Sync UX | FE-06 + FE-07 | 1 | 4–5 days | Yes — feeds Waves C/D |

**Why parallelism works**:
- FE-05 (router) builds a stub guard chain that calls `() => null` until FE-07 lands. The interface (`AuthGuard`) is locked at FE-04 sign-off. FE-07 swaps the implementation later.
- FE-06 (API client) is purely transport: `Dio`, interceptors, retry strategy, idempotency keys. No screens consume it yet.
- FE-07 picks up after both: it depends on FE-05 (router needs to know auth state) and FE-06 (auth controllers call the auth endpoint).

**Wave A handoff to Wave B**:

- [ ] FE-05, FE-06, FE-07, FE-08 all signed off.
- [ ] `flutter test` runs all foundation tests in < 90 s.
- [ ] `mobile-ci.yml` is green on `main` for at least 3 consecutive merges.
- [ ] All foundation ADRs (ADR-001..ADR-012) referenced and consistent.
- [ ] No new entries in `TECHNICAL_DEBT_REGISTER.md` with severity Critical or High that are unowned.
- [ ] Drift schema version 1 is migrated cleanly on a fresh device.
- [ ] Auth state survives a cold restart on a test account.

---

## 3. Wave B — Onboarding + Auth parallel (after FE-08)

Wave B owns first-impression UX. Eight phases, four engineers, ~2 calendar weeks of true parallel work.

```text
FE-08 ✓
   │
   ├───── Eng 1: FE-09 → FE-11 → FE-12
   │           Splash    OTP entry  OTP verify
   │            2-3d      2-3d       2-3d
   │
   ├───── Eng 2: FE-10 → FE-13
   │            Segments   Premium consumer
   │             3-4d        3-4d
   │
   ├───── Eng 3: FE-14 → FE-15
   │            Family invite Allergens
   │             2-3d            3-4d
   │
   └───── Eng 4: FE-16
                Business activation
                  3-4d
```

| Phase | Predecessors | Engineer | Calendar duration |
|---|---|---|---|
| FE-09 Splash | FE-08 | Eng 1 | 2–3 days |
| FE-10 Segment cards | FE-08 | Eng 2 | 3–4 days |
| FE-11 OTP entry | FE-09 | Eng 1 | 2–3 days |
| FE-12 OTP verify | FE-11 | Eng 1 | 2–3 days |
| FE-13 Premium consumer | FE-12, FE-10 | Eng 2 | 3–4 days |
| FE-14 Family invite | FE-12 | Eng 3 | 2–3 days |
| FE-15 Allergens | FE-14 | Eng 3 | 3–4 days |
| FE-16 Business activation | FE-12 | Eng 4 | 3–4 days |

**Why this split**:
- Engineer 1 owns the auth funnel end-to-end (splash → OTP → in-app). Single owner avoids hand-off bugs in the most-failure-sensitive flow.
- Engineer 2 runs onboarding choice + paywall together because both touch the segment selection state.
- Engineer 3 runs the family invite + allergen pair because allergens are scoped per family member.
- Engineer 4 runs business activation as a fully independent track — it shares only the auth state from Wave A.

**Wave B handoff to Waves C/D**:

- [ ] Splash → OTP → home golden flow is green on Patrol E2E.
- [ ] Subscription state is correctly surfaced via `entitlementsProvider`.
- [ ] Segment selection is durable across cold restart (or DEBT-010 is acknowledged).
- [ ] No PR merged with auth bypass for development.
- [ ] All Wave B ARB keys are present in all 6 locales.

---

## 4. Wave C — Consumer parallel (after FE-08, can start alongside Wave B)

Wave C owns the daily-use loop. Four engineers, ~2 calendar weeks. Can start in parallel with Wave B once FE-08 is signed — the only Wave-B dependency is auth state, and Wave C respects auth via FE-05's guards.

```text
FE-08 ✓
   │
   ├───── Eng 1: FE-17 ──► FE-18 ──► FE-19
   │           Scanner   Scan output  Product detail
   │            5-6d      4-5d         4-5d
   │
   ├───── Eng 2: FE-20, FE-21       (independent)
   │            Expiry cal, Recall inbox
   │             4-5d, 2-3d
   │
   ├───── Eng 3: FE-22, FE-23       (independent)
   │            AI explainer, Alternatives
   │             3-4d, 2-3d
   │
   └───── Eng 4: FE-24
                Shopping list
                  2-3d
```

| Phase | Predecessors | Engineer | Calendar duration |
|---|---|---|---|
| FE-17 Scanner | FE-08 + FE-04 motion | Eng 1 | 5–6 days |
| FE-18 Scan output | FE-17 | Eng 1 | 4–5 days |
| FE-19 Product detail | FE-18 | Eng 1 | 4–5 days |
| FE-20 Expiry calendar | FE-08 | Eng 2 | 4–5 days |
| FE-21 Recall inbox | FE-08 | Eng 2 | 2–3 days |
| FE-22 AI explainer | FE-19 | Eng 3 | 3–4 days |
| FE-23 Alternatives | FE-19 | Eng 3 | 2–3 days |
| FE-24 Shopping list | FE-08 | Eng 4 | 2–3 days |

**Why FE-17 → FE-18 → FE-19 are sequential within Eng 1's track**:
- FE-17's scanner emits a `ScanResult` that FE-18 consumes verbatim. Building FE-18 against a placeholder model creates rework.
- FE-19's product detail screen is the Hero target of FE-18's scan output card. Choreography requires both screens to know each other's `Hero(tag:)` identifiers.

---

## 5. Wave D — Business + Owner parallel (after FE-08, overlaps Wave C)

Wave D owns the business workflow. Four engineers, ~2 calendar weeks. Overlaps Wave C — different feature surface, no shared state beyond auth.

```text
FE-08 ✓
   │
   ├───── Eng 1: FE-25 ──► FE-26
   │           Dashboard  OHS detail
   │            4-5d        3-4d
   │
   ├───── Eng 2: FE-27, FE-28       (independent within track)
   │            Bulk scan, Expiry biz
   │             4-5d, 4-5d
   │
   ├───── Eng 3: FE-29 ──► FE-30
   │           GRN wizard  Inventory in/out
   │            5-6d         4-5d
   │
   └───── Eng 4: FE-31, FE-32       (independent within track)
                Tasks, Reports
                 3-4d, 3-4d
```

| Phase | Predecessors | Engineer | Calendar duration |
|---|---|---|---|
| FE-25 Business dashboard | FE-08 | Eng 1 | 4–5 days |
| FE-26 OHS detail | FE-25 | Eng 1 | 3–4 days |
| FE-27 Bulk scan | FE-08 | Eng 2 | 4–5 days |
| FE-28 Expiry biz | FE-08 | Eng 2 | 4–5 days |
| FE-29 GRN wizard | FE-08 | Eng 3 | 5–6 days |
| FE-30 Inventory in/out | FE-29 | Eng 3 | 4–5 days |
| FE-31 Tasks | FE-08 | Eng 4 | 3–4 days |
| FE-32 Reports | FE-08 | Eng 4 | 3–4 days |

**Why FE-29 must finish before FE-30**:
The GRN wizard is the only data path that creates the `inventory_batches` rows that FE-30's stock-in/out screens read. Building FE-30 against synthetic batches means a guaranteed end-to-end test rebuild when FE-29 lands. Similarly, FE-25 → FE-26 are sequential because FE-26 drills into the OHS card that FE-25 owns; identifier stability matters.

**Wave D handoff to Wave E**:

- [ ] Every Wave D phase signed off and merged.
- [ ] Business dashboard cold-loads ≤ 2.5 s with a real account.
- [ ] GRN → Inventory round-trip is verified in Patrol E2E.
- [ ] Reports export produces a valid Excel + PDF for at least one report type.
- [ ] No Drift migration regressions on existing test data.

---

## 6. Wave E — Polish (sequential, but with interleaving allowed)

Wave E is the last 20% that ships the product. Eight phases. Sequential by default, with an explicit interleave window for FE-33..FE-37.

```text
FE-32 ✓
   │
   ├── (interleave window: any order, single owner)
   │     FE-33 Animation hardening
   │     FE-34 Micro-interactions pass
   │     FE-35 i18n runtime swap
   │     FE-36 Sync UI
   │     FE-37 Empty/error/loading pass
   │
   └── (strict sequential)
         FE-38 ──► FE-39 ──► FE-40
         A11y     Perf      Release
          4-5d     3-4d       3-4d
```

| Phase | Predecessors | Engineer pattern | Calendar duration |
|---|---|---|---|
| FE-33 Animation hardening | Wave D + interleave window open | 1 owner | 3–4 days |
| FE-34 Micro-interactions | Wave D + interleave | 1 owner | 4–5 days |
| FE-35 i18n runtime swap | Wave D + interleave | 1 owner | 3–4 days |
| FE-36 Sync UI | Wave D + interleave | 1 owner | 3–4 days |
| FE-37 Empty/error/loading | Wave D + interleave | 1 owner | 3–4 days |
| FE-38 Accessibility pass | All FE-33..FE-37 done | 1 owner | 4–5 days |
| FE-39 Performance pass | FE-38 done | 1 owner | 3–4 days |
| FE-40 Release engineering | FE-39 done | 1 owner | 3–4 days |

**Why FE-33..FE-37 can interleave**:
Each is cross-cutting (touches every screen). Running them in any order is fine **as long as** each fully completes before the next starts (no concurrent edits on the same screen). The interleave saves 2–3 days vs strict sequential because animation polish often unblocks micro-interaction polish on the same screen, etc.

**Why FE-38 → FE-39 → FE-40 are strict**:
- FE-38 (a11y) reshuffles widget trees (Semantics nodes, focus order). Performance traces from before this pass are invalid.
- FE-39 (perf) baselines metrics that FE-40 (release) gates against.
- FE-40 (release) ships only if FE-39 budget is green.

**Wave E exit criteria** (also FE-40 sign-off):

- [ ] All 40 phases signed off.
- [ ] `mobile-ci.yml`, `mobile-integration.yml`, `mobile-patrol.yml`, `mobile-bundle-size.yml` all green.
- [ ] Crash-free sessions ≥ 99.5% on staging over 7 days.
- [ ] Cold start ≤ 1.5 s on Pixel 4a (release build, prod flavor).
- [ ] APK ≤ 35 MB single-ABI (or DEBT-007 actively in cleanup).
- [ ] Privacy manifest, Play Store metadata, App Store metadata all submitted.

---

## 7. Visual ASCII timeline

The full 40-phase build, laid over a 14-week calendar at the 4-engineer staffing level. Each `█` is one weekday. `·` is a buffer day. Calendar columns are weeks.

```text
Week:                W1     W2     W3     W4     W5     W6     W7     W8     W9    W10    W11    W12    W13    W14

Critical path (all eng on FE-01..FE-04):
  FE-01  ███ · ·
  FE-02  · · · ████ ·
  FE-03  · · · · · · ██████ ·
  FE-04  · · · · · · · · · ████

Wave A (3 engineers on FE-05/06/07; 1 on FE-08 once 06+07 done):
  FE-05 (Eng A)   · · · · · · · · · ████ · ·
  FE-06 (Eng B)   · · · · · · · · · ████ · ·
  FE-07 (Eng C)   · · · · · · · · · · · · ████ ·
  FE-08 (Eng A)   · · · · · · · · · · · · · · ·  █████

Wave B (4 engineers on FE-09..FE-16):
  FE-09 (Eng 1)                                                ███
  FE-10 (Eng 2)                                                ████
  FE-11 (Eng 1)                                                · · · ███
  FE-12 (Eng 1)                                                · · · · · ███
  FE-13 (Eng 2)                                                · · · · ████
  FE-14 (Eng 3)                                                · · · · · ███
  FE-15 (Eng 3)                                                · · · · · · · ████
  FE-16 (Eng 4)                                                · · ████

Wave C (overlaps Wave B end + extends; 4 engineers FE-17..FE-24):
  FE-17 (Eng 1)                                                                ██████
  FE-18 (Eng 1)                                                                · · · · · · █████
  FE-19 (Eng 1)                                                                · · · · · · · · · · █████
  FE-20 (Eng 2)                                                                █████
  FE-21 (Eng 2)                                                                · · · · · ███
  FE-22 (Eng 3)                                                                · · · · · ████
  FE-23 (Eng 3)                                                                · · · · · · · · · ███
  FE-24 (Eng 4)                                                                ███

Wave D (parallel with Wave C; 4 engineers FE-25..FE-32):
  FE-25 (Eng 1*)                                                               █████
  FE-26 (Eng 1*)                                                               · · · · · ████
  FE-27 (Eng 2*)                                                               █████
  FE-28 (Eng 2*)                                                               · · · · · █████
  FE-29 (Eng 3*)                                                               ██████
  FE-30 (Eng 3*)                                                               · · · · · · █████
  FE-31 (Eng 4*)                                                               ████
  FE-32 (Eng 4*)                                                               · · · · ████

Wave E (1 owner per phase; FE-33..FE-37 interleave, FE-38/39/40 sequential):
  FE-33                                                                                              ████
  FE-34                                                                                              · · · · █████
  FE-35                                                                                              · · · · · · · · · ████
  FE-36                                                                                              · · · · · · · · · · · · ████
  FE-37                                                                                              · · · · · · · · · · · · · · · · ████
  FE-38                                                                                              · · · · · · · · · · · · · · · · · · · · █████
  FE-39                                                                                              · · · · · · · · · · · · · · · · · · · · · · · · · ████
  FE-40                                                                                              · · · · · · · · · · · · · · · · · · · · · · · · · · · · · ████
```

> Asterisked engineers in Wave D are different humans from Wave C's Eng 1..4 — Waves C and D run in parallel because the team has 8 engineers total at that point. If only 4 engineers are available, run Wave D after Wave C (adds ~2 weeks to the calendar).

---

## 8. Dependency matrix (full 40×40 sparse listing)

For each phase, the phases that **block** it (must be done first) and the phases that **it blocks** (cannot start until this phase is done). Read this when scheduling reorders.

```text
FE-01 blocks: 02, 03, 04, 05, 06, 07, 08
FE-01 needs:  —

FE-02 blocks: 03, 04, 25, 26
FE-02 needs:  01

FE-03 blocks: 04, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 37
FE-03 needs:  02

FE-04 blocks: 09, 17, 18, 19, 25, 33, 34
FE-04 needs:  02, 03

FE-05 blocks: 07, 09, 12, 16, 21, 25, 31
FE-05 needs:  01

FE-06 blocks: 07, 08, 17, 25, 28, 29, 32
FE-06 needs:  01

FE-07 blocks: 08, 09, 11, 12, 13, 14, 15, 16, 25, 36
FE-07 needs:  05, 06

FE-08 blocks: 09, 10, 17, 20, 21, 24, 25, 27, 28, 29, 30, 31, 32, 36
FE-08 needs:  06, 07

FE-09 blocks: 11
FE-09 needs:  04, 05, 07, 08

FE-10 blocks: 13, 16
FE-10 needs:  03, 07, 08

FE-11 blocks: 12
FE-11 needs:  03, 09

FE-12 blocks: 13, 14, 16
FE-12 needs:  03, 11

FE-13 blocks: —
FE-13 needs:  10, 12

FE-14 blocks: 15
FE-14 needs:  12

FE-15 blocks: 18
FE-15 needs:  03, 14

FE-16 blocks: 25, 27, 28, 29, 30, 31, 32
FE-16 needs:  05, 10, 12

FE-17 blocks: 18, 27
FE-17 needs:  03, 04, 06, 08

FE-18 blocks: 19
FE-18 needs:  15, 17

FE-19 blocks: 22, 23
FE-19 needs:  03, 04, 18

FE-20 blocks: —
FE-20 needs:  03, 08

FE-21 blocks: 36
FE-21 needs:  03, 05, 08

FE-22 blocks: —
FE-22 needs:  19

FE-23 blocks: —
FE-23 needs:  19

FE-24 blocks: —
FE-24 needs:  03, 08

FE-25 blocks: 26
FE-25 needs:  02, 03, 04, 05, 06, 07, 08, 16

FE-26 blocks: —
FE-26 needs:  02, 25

FE-27 blocks: —
FE-27 needs:  03, 08, 16, 17

FE-28 blocks: —
FE-28 needs:  03, 06, 08, 16

FE-29 blocks: 30
FE-29 needs:  03, 06, 08, 16

FE-30 blocks: —
FE-30 needs:  03, 08, 16, 29

FE-31 blocks: —
FE-31 needs:  03, 05, 08, 16

FE-32 blocks: —
FE-32 needs:  03, 06, 08, 16

FE-33 blocks: 34, 38
FE-33 needs:  03, 04 (and Wave D done)

FE-34 blocks: 38
FE-34 needs:  03, 33

FE-35 blocks: 38
FE-35 needs:  Wave D done

FE-36 blocks: 38
FE-36 needs:  07, 08, 21

FE-37 blocks: 38
FE-37 needs:  Wave D done

FE-38 blocks: 39
FE-38 needs:  33, 34, 35, 36, 37

FE-39 blocks: 40
FE-39 needs:  38

FE-40 blocks: —  (terminal phase)
FE-40 needs:  39
```

How to read this:
- `FE-25 needs: 02, 03, 04, 05, 06, 07, 08, 16` — the dashboard cannot start until eight other phases are signed off. That is why FE-25 sits at the front of Wave D.
- `FE-13 blocks: —` — no other phase depends on the paywall directly. FE-13 can ship slightly later than its calendar slot without breaking the wave map.
- The longest blocking chain is `FE-01 → FE-02 → FE-03 → FE-04 → FE-08 → FE-25 → FE-26 → FE-33 → FE-34 → FE-38 → FE-39 → FE-40`. That's the absolute minimum critical path = 12 phases. Everything else fans out around it.

---

## 9. Wave-handoff checklists (consolidated)

### Wave A → Wave B handoff
Already listed above. Re-summarised for skim:
- All foundation phases signed.
- CI green for 3 consecutive merges on `main`.
- Drift schema v1 migrates cleanly.
- Auth survives cold restart.
- No unowned Critical/High debt.

### Wave B → Wave C/D handoff
- Auth funnel green on Patrol.
- Entitlements correctly surfaced.
- Segment selection durable (or DEBT-010 acknowledged).
- Locale ARB keys complete for Wave B.
- No auth bypass left in dev builds.

### Wave C ⊕ Wave D handoff to Wave E
- All consumer + business phases signed.
- E2E flows green: scan → product → save; GRN → inventory → reports.
- Performance budgets met within 10% on representative devices.
- Drift schema migrations clean across all v1..vN steps.

### Wave E exit
- All 40 phases signed.
- Cold start ≤ 1.5 s.
- Crash-free sessions ≥ 99.5% over 7 days on staging.
- All 6 locales ARB-complete.
- Privacy + store metadata submitted.
- `OBSERVABILITY_PLAN.md` dashboards live and watched.

---

## 10. Parallelism cost analysis

How does staffing change calendar time?

| Staffing | Calendar duration | Notes |
|---|---|---|
| 1 senior engineer, sequential | ~6 months | Solo build. Critical-path FE-01..FE-04 already takes ~3 weeks. The remaining 36 phases at ~3.5 days each = 126 days. With buffer = 6 months. |
| 2 engineers, light parallel | ~4 months | Pair on critical path; one runs Wave A/E sequentially while the other runs Waves B/C/D. ~110 calendar days. |
| 4 engineers (recommended) | 70–90 days | The wave map's design point. Critical path 2 weeks; Wave A 1.5 weeks; Waves B/C parallel ~3 weeks; Wave D parallel ~2.5 weeks; Wave E 4 weeks. |
| 8 engineers (Wave C + Wave D fully parallel) | 60–75 days | Wave C and Wave D run side-by-side. Saves ~2 weeks vs 4-engineer plan. Diminishing returns past this point — Wave E and critical path are fundamentally serial. |
| 12+ engineers | ~60 days (no further gain) | Wave E and critical path are bottlenecks. Adding humans adds coordination cost. |

### Cost of breaking the order

The wave map is not advice — it is a contract. Breaking it is expensive.

**Example 1 — Starting FE-17 (scanner) before FE-04 (motion) is signed.**
- The scanner uses Hero choreography on capture-success. FE-17 ships against placeholder motion tokens.
- FE-04 lands two weeks later with the real `motion.expressive` curve.
- FE-17's golden tests fail across all 81 device/theme/scale combinations.
- Fix: rebuild FE-17 against the real tokens, regenerate goldens.
- **Real cost**: ~5 engineer-days of rework. **Doubled work** for the screen.

**Example 2 — Starting FE-25 (business dashboard) before FE-08 (Drift) is signed.**
- The dashboard caches OHS scores and recent activity locally.
- FE-25 ships against an in-memory mock that doesn't survive cold restart.
- FE-08 lands and the dashboard data layer must be rewritten.
- **Real cost**: ~4 engineer-days; one round of API contract churn with backend.

**Example 3 — Skipping FE-38 (a11y) and going straight from FE-37 to FE-39.**
- FE-39 baselines performance on widget trees that FE-38 will reshuffle.
- After FE-38, the perf baseline is invalid. FE-39 reruns from scratch.
- **Real cost**: ~3 engineer-days, but worse: invalid pre-launch performance numbers reach review.

**Example 4 — Running FE-29 and FE-30 in true parallel with two engineers.**
- FE-30 needs `inventory_batches` rows that FE-29 creates.
- Eng on FE-30 builds against synthetic batches.
- When FE-29 lands, the FE-30 implementation rewrites the read-side.
- **Real cost**: ~3 engineer-days plus likely E2E test churn.

The pattern: **breaking the order produces a cost ratio of roughly 1.5×–2× vs respecting it**. The wave map exists because we measured this on the backend's BE-01..BE-57 build, which had two such violations and paid for both.

---

## 11. Dependency rules summary

A short reference card to drop on the wall.

1. **No phase starts until all its `needs:` predecessors are signed off.** (Sign-off ≠ merged: it requires the Mandatory SOP gate from the phase doc to be checked.)
2. **No wave starts until the previous wave's handoff checklist is fully green.**
3. **No engineer works on two phases concurrently** within the same wave. Switch costs are too high.
4. **CI failure on `main` blocks every wave.** A foundation regression invalidates all in-progress feature work.
5. **The critical path is one engineer.** Adding humans to FE-01..FE-04 saves no time and adds review overhead.
6. **Wave D's FE-29 → FE-30 sequence is non-negotiable.** GRN feeds inventory.
7. **Wave E's FE-38 → FE-39 → FE-40 sequence is non-negotiable.** A11y reshuffles the tree; perf baselines depend on the final tree; release depends on perf budget.
8. **Adding a new phase requires an ADR and a wave-map update.** Do not slip new work into existing phases.

---

## 12. When an engineer joins late

A new engineer joining at, say, Wave C reads (in this order):
1. `RADHA_CLIENT_OVERVIEW.md` — product context.
2. `FRONTEND_PHASES/00_MASTER_FRONTEND_ROADMAP.md` — phase shape.
3. `ADR_LOG.md` — design decisions.
4. `FRONTEND_DESIGN_SYSTEM.md` — token vocabulary.
5. **This file** (FRONTEND_BUILD_ORDER.md) — wave map and dependencies.
6. The phase docs they will own, end-to-end.
7. `FRONTEND_QA_SYSTEM.md` and `FRONTEND_VERIFICATION_SYSTEM.md`.

Estimate: 1 engineer-day of reading. They do not write code on Day 1.

---

## 13. Reference table — phase-to-wave map

For quick lookup:

| Phase | Wave | Sequential / Parallel | Notes |
|---|---|---|---|
| FE-01 | Critical path | Sequential | Workspace + flavors + CI |
| FE-02 | Critical path | Sequential | Tokens + theme |
| FE-03 | Critical path | Sequential | Component library |
| FE-04 | Critical path | Sequential | Motion |
| FE-05 | Wave A | Parallel | Router |
| FE-06 | Wave A | Parallel | API client |
| FE-07 | Wave A | Sequential after 05+06 | State + auth |
| FE-08 | Wave A | Sequential after 07 | Drift + sync UX |
| FE-09 | Wave B | Engineer 1 | Splash |
| FE-10 | Wave B | Engineer 2 | Segments |
| FE-11 | Wave B | Engineer 1 | OTP entry |
| FE-12 | Wave B | Engineer 1 | OTP verify |
| FE-13 | Wave B | Engineer 2 | Premium consumer |
| FE-14 | Wave B | Engineer 3 | Family invite |
| FE-15 | Wave B | Engineer 3 | Allergens |
| FE-16 | Wave B | Engineer 4 | Business activation |
| FE-17 | Wave C | Engineer 1 | Scanner |
| FE-18 | Wave C | Engineer 1 | Scan output |
| FE-19 | Wave C | Engineer 1 | Product detail |
| FE-20 | Wave C | Engineer 2 | Expiry calendar |
| FE-21 | Wave C | Engineer 2 | Recall inbox |
| FE-22 | Wave C | Engineer 3 | AI explainer |
| FE-23 | Wave C | Engineer 3 | Alternatives |
| FE-24 | Wave C | Engineer 4 | Shopping list |
| FE-25 | Wave D | Engineer 1 | Business dashboard |
| FE-26 | Wave D | Engineer 1 | OHS detail |
| FE-27 | Wave D | Engineer 2 | Bulk scan |
| FE-28 | Wave D | Engineer 2 | Expiry biz |
| FE-29 | Wave D | Engineer 3 | GRN wizard |
| FE-30 | Wave D | Engineer 3 | Inventory |
| FE-31 | Wave D | Engineer 4 | Tasks |
| FE-32 | Wave D | Engineer 4 | Reports |
| FE-33 | Wave E | 1 owner, interleave | Animation hardening |
| FE-34 | Wave E | 1 owner, interleave | Micro-interactions |
| FE-35 | Wave E | 1 owner, interleave | i18n |
| FE-36 | Wave E | 1 owner, interleave | Sync UI |
| FE-37 | Wave E | 1 owner, interleave | Empty/error/loading |
| FE-38 | Wave E | Sequential | A11y |
| FE-39 | Wave E | Sequential | Perf |
| FE-40 | Wave E | Sequential | Release |

---

**END OF FILE — FRONTEND_BUILD_ORDER.md**
