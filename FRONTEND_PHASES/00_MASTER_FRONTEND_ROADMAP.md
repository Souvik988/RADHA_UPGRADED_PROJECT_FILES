# RADHA Mobile — Master Frontend Roadmap

> **One Flutter app. Two audiences. Same scanner. Premium feel on every tap.**

This directory contains **40 frontend execution phases** for the RADHA mobile app. The backend (BE-01..BE-57, 410 endpoints across 24 modules) is feature-complete. This roadmap takes those endpoints and turns them into a world-class mobile experience that consumers reopen weekly and businesses run their entire day on.

---

## North Star

| Pillar | What it means in the app |
|---|---|
| **Customer retention** | Every screen earns the next open. Empty states have personality, push notifications add value, weekly digests teach. |
| **Animation-first** | Lottie + flutter_animate + Hero choreography. Every transition has thought. No jump cuts, no jank. |
| **Premium feel** | Haptics on every meaningful tap, 60fps on Pixel 4a / iPhone SE 2, dark mode by default, dynamic color (Material You). |
| **Offline-first** | Scans, expiry entries, saved products work without signal. Sync when network returns. |
| **Inclusive** | 6 languages (English, Hindi, Tamil, Telugu, Bengali, Marathi), full a11y (Semantics, dynamic type, reduced motion, high contrast). |
| **Dual-mode** | One codebase. Consumer UI vs Business UI gated by role + onboarding segment. Same shell, different surface. |

---

## Tech Stack (locked)

| Layer | Choice | Why |
|---|---|---|
| Framework | **Flutter 3.22+** (Dart 3.4) | Single codebase, native perf, Skia/Impeller. |
| State | **Riverpod 2.5** + `riverpod_generator` | Compile-time safety, test isolation, no global singletons. |
| Routing | **GoRouter 14** | Declarative, deep-link first, type-safe, redirect guards. |
| Local DB | **Drift 2.18** (sqflite/sqlite3) | Reactive streams, generated code, mirrors server schema. |
| HTTP | **Dio 5** + interceptors | Auth, retry, idempotency, correlation IDs, offline queue. |
| Models | **freezed 2.5** + `json_serializable` | Immutable, sealed unions, copyWith, equality. |
| Theme | **flex_color_scheme 7.3** + Material 3 | Light/dark, dynamic color, sub-themes, no hand-rolled. |
| Animation | **flutter_animate 4.5** + **lottie 3** + native AnimatedBuilder | Declarative chains + scripted vector. |
| Scanning | **google_mlkit_barcode_scanning** + **google_mlkit_text_recognition** | Free, on-device, fast. |
| Push | **firebase_messaging** + **flutter_local_notifications** | FCM matches BE-24 stack. |
| Haptics | **gaptic_feedback** (custom wrapper) over `HapticFeedback` | Light/medium/heavy/success/warning/error. |
| i18n | **flutter_localizations** + ARB + `intl_utils` | 6 locales, runtime swap (matches BE-42). |
| Component lab | **widgetbook 3** | Storybook-equivalent for every component, every variant, every state. |
| Auth storage | **flutter_secure_storage** | Keychain / Keystore for JWT. |
| Errors | **sentry_flutter** | Matches BE-48 observability stack. |
| Tests | `flutter_test` + `golden_toolkit` + `integration_test` | Widget + screenshot regression + real device. |

---

## Phase Overview — 40 Phases Across 5 Layers

### Layer 1: Foundation (FE-01..FE-08) — 8 phases
The skeleton. Everything below sits on this. Get this wrong and every later phase pays interest.

| Phase | Name | Duration | Depends On |
|---|---|---|---|
| FE-01 | Flutter Project Init, Flavors, CI Bootstrap | 2-3 days | — |
| FE-02 | Design Tokens & Theme System (light/dark/dynamic) | 3-4 days | FE-01 |
| FE-03 | Component Library Foundation (buttons, inputs, cards, sheets, dialogs) | 5-6 days | FE-02 |
| FE-04 | Motion System (Hero, parallax, stagger, reduced motion) | 3-4 days | FE-02, FE-03 |
| FE-05 | Navigation + Routing (GoRouter, guards, deep links) | 3-4 days | FE-01 |
| FE-06 | API Client + Typed Services (Dio, retry, idempotency, offline queue) | 3-4 days | FE-01 |
| FE-07 | State Management (Riverpod) + Auth State + JWT Refresh | 3-4 days | FE-05, FE-06 |
| FE-08 | Local DB (Drift) + Offline-First Sync UX Hooks | 4-5 days | FE-06, FE-07 |

### Layer 2: Onboarding + Auth (FE-09..FE-16) — 8 phases
First impressions decide retention. These 8 screens are where 30-40% of activation lift comes from.

| Phase | Name | Duration | Maps To Backend |
|---|---|---|---|
| FE-09 | Splash + App Boot Flow (cold start, theme handoff, Lottie hero) | 2-3 days | None (boot only) |
| FE-10 | Onboarding Segment Cards (2×3 grid, tap-card animation) | 3-4 days | BE-34 `POST /api/v1/onboarding/segment` |
| FE-11 | OTP Phone Entry + Country Picker | 2-3 days | BE-06 `POST /auth/otp/request` |
| FE-12 | OTP Verify + 6-Box Pin + Auto-Resend Timer | 2-3 days | BE-06 `POST /auth/otp/verify` |
| FE-13 | Premium Consumer Subscribe (UPI mandate, paywall sheet) | 3-4 days | BE-36 `POST /api/v1/subscriptions/premium-consumer` |
| FE-14 | Family Member Invite + Accept | 2-3 days | BE-36 `/api/v1/family/*` |
| FE-15 | Allergen Profile Setup (chip-select, severity, family-member tabs) | 3-4 days | BE-37 `/api/v1/allergens/*` |
| FE-16 | Business Activation Wizard + Auditor Token Entry | 3-4 days | BE-35 `/api/v1/business/activate`, BE-08 |

### Layer 3: Consumer Core (FE-17..FE-24) — 8 phases
The reason consumers reopen the app. This is the daily-use loop.

| Phase | Name | Duration | Maps To Backend |
|---|---|---|---|
| FE-17 | Scanner Screen (camera, ML Kit, focus reticule, tactile feedback) | 5-6 days | BE-10 `POST /api/v1/products/scan`, BE-46 quotas |
| FE-18 | Scan Output Card (verdict, allergen warning, save action) | 4-5 days | BE-12 comprehensive output |
| FE-19 | Product Detail Screen (Hero animated, ingredients accordion, badges) | 4-5 days | BE-10, BE-52 verified badge |
| FE-20 | Expiry Calendar (month view, color zones, mark-consumed) | 4-5 days | BE-38 `/api/v1/expiry-calendar` |
| FE-21 | Recall Alert Inbox + Detail | 2-3 days | BE-39 `/api/v1/recalls/*` |
| FE-22 | AI Ingredient Explainer Sheet (LLM stream, language switch) | 3-4 days | BE-40 `/api/v1/ai/explain-ingredient` |
| FE-23 | Healthy Alternatives Carousel + Affiliate Click-Out | 2-3 days | BE-41 `/api/v1/alternatives/*` |
| FE-24 | Shopping List + WhatsApp Share | 2-3 days | BE-55 `/api/v1/shopping-list/*` |

### Layer 4: Business + Owner (FE-25..FE-32) — 8 phases
The business runs the store from this app. Speed and accuracy beat polish here, but polish still wins retention.

| Phase | Name | Duration | Maps To Backend |
|---|---|---|---|
| FE-25 | Business Dashboard (OHS hero card, sparklines, quick actions) | 4-5 days | BE-30 `/api/v1/dashboard/*`, BE-52 |
| FE-26 | OHS Detail Drill-Down (6 components, trend, recommendations) | 3-4 days | BE-30 OHS endpoint |
| FE-27 | Bulk Scan Mode (rapid-fire, audio cues, list-as-you-go) | 4-5 days | BE-15, BE-16, BE-17 |
| FE-28 | Expiry Tracker Business (filters, OCR MFG/EXP entry) | 4-5 days | BE-18, BE-22 OCR |
| FE-29 | GRN Wizard (supplier picker, line items, batch+expiry capture) | 5-6 days | BE-25, BE-26 |
| FE-30 | Inventory Stock In/Out + Counts | 4-5 days | BE-27 |
| FE-31 | Tasks Inbox + Detail + Complete | 3-4 days | BE-19 |
| FE-32 | Reports List + Detail + Export Sheet (Excel/PDF) | 3-4 days | BE-20, BE-21 |

### Layer 5: Polish + Cross-cutting (FE-33..FE-40) — 8 phases
The last 20% that ships the difference between "good app" and "premium product."

| Phase | Name | Duration | Maps To Backend |
|---|---|---|---|
| FE-33 | Animation Library Hardening (Lottie pack, reduced-motion paths) | 3-4 days | — |
| FE-34 | Micro-Interactions Pass (every button, every state) | 4-5 days | — |
| FE-35 | i18n Runtime Swap (6 locales, RTL-ready) | 3-4 days | BE-42 |
| FE-36 | Sync UI (offline banner, conflict resolution, queue indicator) | 3-4 days | BE-44 |
| FE-37 | Empty / Error / Loading States Pass (every screen, with personality) | 3-4 days | — |
| FE-38 | Accessibility Pass (Semantics, focus, contrast, dynamic type) | 4-5 days | — |
| FE-39 | Performance Pass (60fps audit, image budget, jank trace) | 3-4 days | — |
| FE-40 | Release Engineering (signing, Play/AppStore metadata, crash gate) | 3-4 days | BE-48 |

---

## Total Duration

- **40 phases sequential**: ~135-175 days
- **With Wave parallelization**: 70-90 days (3-4 engineers)
- **Solo build**: 6 months

---

## Wave Map (parallel team execution)

The backend wave map proved out: split phases into waves that share zero state. Each wave below ships independently.

### Wave A — Foundation (must finish first, blocks all others)
- FE-01 → FE-02 → FE-03 → FE-04
- FE-01 → FE-05
- FE-01 → FE-06 → FE-07 → FE-08

**Critical path**: FE-01 → FE-02 → FE-03. Everything else waits.

### Wave B — Onboarding (parallel after Wave A)
- Engineer 1: FE-09, FE-10, FE-11, FE-12
- Engineer 2: FE-13, FE-14
- Engineer 3: FE-15
- Engineer 4: FE-16

### Wave C — Consumer (parallel after FE-08)
- Engineer 1: FE-17 → FE-18 → FE-19
- Engineer 2: FE-20, FE-21
- Engineer 3: FE-22, FE-23
- Engineer 4: FE-24

### Wave D — Business (parallel after FE-08, can overlap Wave C)
- Engineer 1: FE-25 → FE-26
- Engineer 2: FE-27, FE-28
- Engineer 3: FE-29, FE-30
- Engineer 4: FE-31, FE-32

### Wave E — Polish (after C and D)
- FE-33, FE-34, FE-35, FE-36, FE-37, FE-38, FE-39, FE-40 — sequential gate.

---

## Reading Order

For new engineers joining the team:

1. **Read this file end to end.**
2. Read `RADHA_CLIENT_OVERVIEW.md` (product context).
3. Read `BACKEND_PHASES/00_MASTER_BACKEND_ROADMAP.md` (what the API does).
4. Read `FE-01_PHASE.md` through `FE-08_PHASE.md` (foundation — non-negotiable).
5. Pick your wave from the wave map.
6. Read your phase doc end-to-end before opening an editor.
7. Run all 15 test procedures in the Mandatory SOP before requesting review.
8. Answer all 8 Q&A questions in the handoff.

---

## File Standards

Every phase file (`FE-NN_PHASE.md`) contains:

1. Phase Metadata (ID, layer, dependencies, blocks, duration, complexity)
2. Goal (concrete, engagement-focused)
3. Why This Phase Matters (user / business reason)
4. Prerequisites (backend endpoints, prior FE phases, design assets)
5. Files to Create (paths under `apps/mobile/lib/`)
6. Component / Widget Spec (Dart code sketches with public API)
7. Visual Behaviour (8+ interaction states per screen)
8. Animations (Lottie refs, flutter_animate chains, motion budget)
9. Accessibility (Semantics, focus order, dynamic type, reduced motion, high contrast)
10. Testing (widget + golden + integration)
11. Risk Assessment (perf, layout, platform-specific)
12. **Mandatory SOP** — 15 test procedures + 8 Q&A
13. **Sign-off Gate** (Developer signature → Reviewer approval)

---

## Status Table (template — phase leads update as they ship)

| Phase | Status | Owner | Started | Completed | Reviewer | Notes |
|---|---|---|---|---|---|---|
| FE-01 | 📝 Pending | — | — | — | — | — |
| FE-02 | 📝 Pending | — | — | — | — | — |
| FE-03 | 📝 Pending | — | — | — | — | — |
| FE-04 | 📝 Pending | — | — | — | — | — |
| FE-05 | 📝 Pending | — | — | — | — | — |
| FE-06 | 📝 Pending | — | — | — | — | — |
| FE-07 | 📝 Pending | — | — | — | — | — |
| FE-08 | 📝 Pending | — | — | — | — | — |
| FE-09..FE-16 | 📝 Pending | — | — | — | — | Onboarding wave |
| FE-17..FE-24 | 📝 Pending | — | — | — | — | Consumer wave |
| FE-25..FE-32 | 📝 Pending | — | — | — | — | Business wave |
| FE-33..FE-40 | 📝 Pending | — | — | — | — | Polish wave |

Status legend: 📝 Pending · 🚧 In progress · 🟡 In review · ✅ Done · ❌ Blocked

---

## Hard Performance Budget (every phase enforces this)

| Metric | Budget | Tested on |
|---|---|---|
| Cold start to first frame | < 1.5 s | Pixel 4a |
| Splash to home (logged-in) | < 2.5 s | Pixel 4a |
| Frame budget | 16.6 ms (60fps) | Pixel 4a, iPhone SE 2 |
| Jank rate (DevTools timeline) | < 1% of frames | Hero transitions |
| Scan to verdict | < 1.5 s p95 | Pixel 4a, online |
| Offline scan to local cache | < 800 ms | Airplane mode |
| APK size (release, single ABI) | < 35 MB | arm64-v8a |
| Memory ceiling (steady state) | < 220 MB | After 5 min of use |
| Battery drain (1 hr of scanning) | < 8% | Pixel 4a |

A phase that misses budget can't ship. The performance pass (FE-39) is a gate, not a polish step.

---

## Animation Vocabulary (used across every phase)

| Token | Duration | Curve | Used for |
|---|---|---|---|
| `motion.instant` | 0 ms | linear | toggles, state-only |
| `motion.fast` | 120 ms | `Curves.easeOutCubic` | hover, press feedback |
| `motion.normal` | 200 ms | `Curves.easeInOutCubic` | sheet open, dialog enter |
| `motion.slow` | 320 ms | `Curves.easeOutQuint` | route transitions |
| `motion.expressive` | 480 ms | custom Bezier (0.16, 1, 0.3, 1) | Hero, big reveals |
| `motion.celebrate` | 800 ms | spring (200, 18) | success states, confetti |

Every phase doc references these tokens. No magic numbers in screen code.

---

## Haptics Vocabulary

| Token | Native | When |
|---|---|---|
| `haptic.tap` | `HapticFeedback.selectionClick` | tab switch, chip toggle |
| `haptic.light` | `HapticFeedback.lightImpact` | button press |
| `haptic.medium` | `HapticFeedback.mediumImpact` | sheet snap, scan capture |
| `haptic.heavy` | `HapticFeedback.heavyImpact` | recall alert, expiry critical |
| `haptic.success` | platform-specific pattern | scan verified, OTP success |
| `haptic.warning` | platform-specific pattern | allergen flag |
| `haptic.error` | platform-specific pattern | OTP wrong, network fail |

---

## Backend Endpoint Coverage Map

Every backend endpoint must have a frontend caller. The roadmap above maps them; this file is the source of truth.

| Backend module | Phases that consume it |
|---|---|
| BE-06 OTP | FE-11, FE-12 |
| BE-08 Roles | FE-07, FE-25 |
| BE-10 Products / Scan | FE-17, FE-18, FE-19 |
| BE-12 Health Scoring | FE-18, FE-19 |
| BE-15..BE-17 EAN + Bulk | FE-27 |
| BE-18 Expiry Business | FE-28 |
| BE-19 Tasks | FE-31 |
| BE-20, BE-21 Reports | FE-32 |
| BE-22 OCR | FE-28 |
| BE-24 Notifications | FE-21, FE-36 |
| BE-25 Suppliers | FE-29 |
| BE-26 GRN | FE-29 |
| BE-27 Inventory | FE-30 |
| BE-28 Subs | FE-13 |
| BE-30 Client Dash | FE-25, FE-26 |
| BE-34 Onboarding | FE-10 |
| BE-35 Business Activation | FE-16 |
| BE-36 Premium + Family | FE-13, FE-14 |
| BE-37 Allergens | FE-15, FE-18 |
| BE-38 Expiry Calendar | FE-20 |
| BE-39 Recalls | FE-21 |
| BE-40 AI Explainer | FE-22 |
| BE-41 Alternatives | FE-23 |
| BE-42 i18n | FE-35 |
| BE-44 Sync | FE-08, FE-36 |
| BE-46 Rate Limits | FE-06, FE-17 |
| BE-47 Feature Flags | FE-07 |
| BE-48 Observability | FE-40 |
| BE-52 Verified Badge | FE-19, FE-25 |
| BE-55 Shopping List | FE-24 |

If a phase doc references an endpoint not in BE-01..BE-57, that's a bug in the doc.

---

## Spirit

The app must FEEL premium. Every tap has feedback. Every transition has thought. Every empty state has personality. Customer retention is the design north star — we don't optimize for installs, we optimize for the **fourth open**.

A user who opens RADHA four times has decided it's part of their week. Everything in this roadmap exists to earn that fourth open.

---

**Last Updated**: 2026-05-17
**Total Phases**: 40
**Layer 1 (Foundation) Status**: 📝 Specs drafted (FE-01..FE-08)
**Layer 2..5 Status**: 📝 Roadmap entries only — detailed phase docs pending
