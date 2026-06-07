# Phase FE-11: Segment-Specific Onboarding Flows (Six Forks)

## Phase Metadata
- **Phase ID**: FE-11
- **Phase Name**: Segment-Specific Onboarding Flows
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-07 (Riverpod), FE-09 (splash), FE-10 (segment hero), BE-34 (segment routing)
- **Blocks**: FE-13 (family setup), FE-14 (allergen profile), FE-15 (business activation wizard), FE-16 (auditor token entry)
- **Estimated Duration**: 2.5 days
- **Complexity**: High (six fork paths, careful coordination)

## Goal
Translate the routing decision returned by `POST /api/v1/onboarding/segment` (BE-34) into six fully-realised post-onboarding journeys. Each fork has its own greeting, micro-tutorial, and first-action priming. The fork is not just a router — it is the moment we transform an anonymous tap on the segment hero into a user with a clear next action and the right Riverpod scopes wired up.

The six forks:
1. **Personal** → consumer home + first-scan tutorial overlay
2. **Parent** → family setup (FE-13) → allergen profile (FE-14) → consumer home with member-aware first scan
3. **Business Owner** → activation wizard (FE-15) preset = `business_owner`
4. **Pharmacy** → activation wizard (FE-15) preset = `pharmacy`
5. **Institution** → activation wizard (FE-15) preset = `institution`
6. **Auditor (invited)** → token entry (FE-16) → role-confirmation screen

## Why This Phase Matters
- **First-action conversion**: 71% of users who complete a first meaningful action (first scan, first member added, first activation step) within 3 minutes of choosing a segment retain at D7. The fork must hand the user that first action without friction.
- **Funnel resilience**: Each fork is an independent funnel. A failure in one (e.g., parent fork crashing on family setup) must not cascade to the others. This is why the fork is a phase of its own and not a sub-section of FE-10.
- **Motion continuity**: The Hero transition begun in FE-10 must land cleanly in each fork's first frame. A 60ms timing mistake is visible.
- **Personalization expectation**: From this phase forward, users see RADHA tailored to them — segment-aware copy, segment-aware notifications, segment-aware default home tab.

## Prerequisites
- [ ] FE-09, FE-10 merged
- [ ] Backend: BE-34 routing dto reachable; BE-13 v2 first-scan tutorial flag
- [ ] Lottie: `first_scan_tutorial.json` (4.2s, ≤180 KB)
- [ ] Lottie: `parent_welcome.json`, `business_welcome.json`, `pharmacy_welcome.json`, `institution_welcome.json`, `auditor_welcome.json` (≤80 KB each)
- [ ] Asset: `tutorial_overlay_arrow.svg`

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/onboarding/forks/fork_router.dart` | Pure function: `OnboardingRoutingDto → ForkPlan` |
| `apps/mobile/lib/features/onboarding/forks/fork_plan.dart` | Sealed `ForkPlan` (one per segment) |
| `apps/mobile/lib/features/onboarding/forks/personal_fork.dart` | Personal landing + tutorial trigger |
| `apps/mobile/lib/features/onboarding/forks/parent_fork.dart` | Parent landing → family setup link |
| `apps/mobile/lib/features/onboarding/forks/business_fork.dart` | Business landing → activation wizard with preset |
| `apps/mobile/lib/features/onboarding/forks/auditor_fork.dart` | Auditor landing → token entry |
| `apps/mobile/lib/features/onboarding/forks/widgets/welcome_card.dart` | Shared welcome surface (Lottie + headline + CTA) |
| `apps/mobile/lib/features/onboarding/forks/widgets/first_scan_tutorial.dart` | Coach-mark overlay shown over scanner tab |
| `apps/mobile/lib/features/onboarding/forks/services/fork_progress_repo.dart` | Drift-backed local progress tracker |
| `apps/mobile/lib/features/onboarding/forks/analytics/fork_events.dart` | PostHog event mapper |
| `apps/mobile/test/features/onboarding/forks/fork_router_test.dart` | Pure-function tests for routing matrix |
| `apps/mobile/test/features/onboarding/forks/golden/fork_states.dart` | Golden tests for each fork |
| `apps/mobile/integration_test/onboarding_forks_test.dart` | E2E for all six paths |

## Screen / Widget Spec

```dart
// fork_plan.dart
sealed class ForkPlan {
  const ForkPlan();
  String get welcomeRoute;
  List<ForkStep> get steps;
}
class PersonalForkPlan extends ForkPlan { ... }
class ParentForkPlan extends ForkPlan { ... }
class BusinessForkPlan extends ForkPlan {
  final BusinessPreset preset;    // owner | pharmacy | institution
  const BusinessForkPlan(this.preset);
}
class AuditorForkPlan extends ForkPlan { ... }

class ForkStep {
  final String id;                // 'welcome', 'family_setup', 'allergen', 'activation', 'token', 'first_scan_tutorial'
  final String routeName;
  final bool isOptional;          // user can skip
  final bool isCompleted;         // sourced from fork_progress_repo
}

// fork_router.dart
ForkPlan planFor(OnboardingRoutingDto dto) {
  return switch (dto.segment) {
    OnboardingSegment.personal => const PersonalForkPlan(),
    OnboardingSegment.parent => const ParentForkPlan(),
    OnboardingSegment.businessOwner => const BusinessForkPlan(BusinessPreset.owner),
    OnboardingSegment.pharmacy => const BusinessForkPlan(BusinessPreset.pharmacy),
    OnboardingSegment.institution => const BusinessForkPlan(BusinessPreset.institution),
    OnboardingSegment.auditorInvited => const AuditorForkPlan(),
  };
}
```

### `WelcomeCard` widget (shared by all forks)
```dart
class WelcomeCard extends StatelessWidget {
  final String lottiePath;        // segment-specific
  final String headline;          // welcome.{segment}.headline
  final String subtitle;          // welcome.{segment}.sub
  final String ctaLabel;          // welcome.{segment}.cta
  final VoidCallback onCta;
  final VoidCallback? onSkip;     // nullable; not all forks allow skip
}
```

### Animations attached
- **Hero arrival**: tag `segment-{id}` from FE-10 lands on welcome card top edge; receiving Hero `flightShuttleBuilder` morphs from card → full-bleed top stripe over 360ms `Curves.easeOutCubicEmphasized`.
- **Welcome content entrance**: headline `.fadeIn(220ms).slideY(begin: 0.06)`, subtitle delayed 80ms, CTA delayed 160ms.
- **First-scan tutorial**: coach-mark with `Lottie.asset('first_scan_tutorial.json')` looping (3.6s); overlay arrow uses `flutter_animate` `.shake(hz: 1.5, offset: Offset(0, 6))` on dwell after 4s without tap.

### Haptic feedback events
- `HapticFeedback.lightImpact()` on welcome CTA tap.
- `HapticFeedback.selectionClick()` on tutorial dismiss tap.
- No haptic on skip (skip should feel free).

### Motion choreography (timeline) — Personal fork example
| t (ms) | Event |
|---|---|
| 0 | Hero arrives from segment screen |
| 0–360 | Top stripe morph + Lottie welcome plays |
| 220 | Headline fades in |
| 300 | Subtitle fades in |
| 380 | CTA "Start scanning" fades in + scale 0.96→1.0 |
| user-tap | Light haptic; route to `/home` |
| home+200 | Tutorial overlay fades in over scanner tab |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Welcome card invisible, awaiting Hero arrival |
| **loading (welcome rendering)** | Hero morph in flight; CTA disabled |
| **loaded (welcome idle)** | Lottie loops; CTA tappable |
| **empty** | N/A |
| **error (network)** | If backend route push needs backend (e.g., business activation), inline error banner "Couldn't continue. Retry?"; CTA replaced with retry |
| **error (deep-link mismatch)** | Defensive: if user lands directly on a fork route without a segment, route to `/onboarding/segment` |
| **success** | CTA tap → next route push |
| **offline** | Personal/Parent/Auditor forks proceed offline (local routes); Business fork blocks with banner "Connect to start your business setup" |
| **rate-limited / cooldown** | Rare: only Auditor fork hits backend on mount. 429 → 30s cooldown ring on CTA |
| **permission-denied** | Personal fork: if camera denied at first-scan tutorial, replace with "Allow camera in Settings" CTA |
| **accessibility-mode (reduced motion)** | All Hero morphs replaced with `crossFade(220ms)`; coach-mark static SVG; Lottie → PNG |
| **high contrast** | Welcome card uses solid background instead of gradient overlay |
| **dynamic type xxLarge** | Headlines wrap; CTA expands to full width; min welcome card height 360dp → 460dp |

## Animations Inventory
- **Lottie files**:
  - `first_scan_tutorial.json` — 3.6s loop, trigger: scanner tab first mount
  - `parent_welcome.json` — 2.4s loop, trigger: parent fork mount
  - `business_welcome.json` — 2.6s loop
  - `pharmacy_welcome.json` — 2.0s loop
  - `institution_welcome.json` — 2.4s loop
  - `auditor_welcome.json` — 2.2s loop
- **flutter_animate chains**:
  - Headline: `.fadeIn(220ms).slideY(begin: 0.06)`
  - Subtitle: `.fadeIn(220ms).slideY(begin: 0.06)` + delay 80ms
  - CTA: `.fadeIn(220ms).scale(begin: 0.96, curve: Curves.easeOutBack)` + delay 160ms
  - Tutorial arrow: `.shake(hz: 1.5, offset: Offset(0, 6))` after 4s dwell
- **Hero transitions**: tag `segment-{id}`; from FE-10 card → fork welcome top stripe; 360ms `Curves.easeOutCubicEmphasized`.
- **Custom motion**: top stripe morph paints a `LinearGradient` blend across the morph; coach-mark backdrop blurs from 0 → 6 sigma over 240ms.
- **Stagger**: 80ms between headline / subtitle / CTA.
- **Total motion budget**: entrance 540ms (within 600ms); exit 240ms (within 200ms+ tolerance for Hero handoff).

## Haptics
- **Light**: welcome CTA tap.
- **Medium**: business fork "Begin activation" CTA (signals heavy commitment).
- **Heavy**: deep-link mismatch defensive redirect.
- **Selection**: tutorial dismiss; tutorial step advance.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `welcome.personal.headline` | "Let's get scanning" | "स्कैन करना शुरू करें" | "ஸ்கேன் தொடங்குவோம்" | "స్కానింగ్ ప్రారంభిద్దాం" | "চলুন স্ক্যান শুরু করি" | "स्कॅन सुरू करूया" |
| `welcome.personal.cta` | "Start scanning" | "स्कैन शुरू करें" | "ஸ்கேன் தொடங்கு" | "స్కాన్ ప్రారంభించండి" | "স্ক্যান শুরু" | "स्कॅन सुरू" |
| `welcome.parent.headline` | "Let's keep your family safe" | "अपने परिवार को सुरक्षित रखें" | "உங்கள் குடும்பம் பாதுகாப்பு" | "మీ కుటుంబాన్ని కాపాడండి" | "পরিবারকে নিরাপদ রাখুন" | "कुटुंब सुरक्षित ठेवा" |
| `welcome.parent.cta` | "Add a family member" | "सदस्य जोड़ें" | "உறுப்பினர் சேர்" | "సభ్యుడిని జోడించండి" | "সদস্য যোগ করুন" | "सदस्य जोडा" |
| `welcome.business.headline` | "Let's set up your store" | "अपनी दुकान सेट करें" | "உங்கள் கடையை அமை" | "మీ స్టోర్ సెటప్ చేయండి" | "আপনার দোকান সেট আপ" | "तुमचे दुकान सेट करा" |
| `welcome.business.cta` | "Begin activation" | "सक्रियण शुरू करें" | "செயல்பாடு தொடங்கு" | "యాక్టివేషన్ ప్రారంభం" | "অ্যাক্টিভেশন শুরু" | "अॅक्टिव्हेशन सुरू" |
| `welcome.pharmacy.headline` | "Stock + expiry, the right way" | "स्टॉक + एक्सपायरी, सही तरीका" | "ஸ்டாக் + காலாவதி" | "స్టాక్ + ఎక్స్‌పైరీ" | "স্টক + এক্সপায়ারি" | "स्टॉक + एक्स्पायरी" |
| `welcome.institution.headline` | "Compliance made easy" | "अनुपालन आसान" | "ஒத்திசைவு எளிதாக" | "కంప్లయన్స్ సులభం" | "কমপ্লায়েন্স সহজ" | "अनुपालन सोपे" |
| `welcome.auditor.headline` | "Paste your invite token" | "अपना आमंत्रण टोकन डालें" | "டோக்கனை ஒட்டு" | "టోకెన్ అతికించండి" | "টোকেন পেস্ট করুন" | "टोकन पेस्ट करा" |
| `welcome.auditor.cta` | "Continue" | "जारी रखें" | "தொடரு" | "కొనసాగించండి" | "চালিয়ে যান" | "सुरू ठेवा" |
| `tutorial.first_scan` | "Tap to scan a barcode" | "बारकोड स्कैन करने के लिए टैप करें" | "பார்கோடு ஸ்கேன் டேப்" | "బార్‌కోడ్ స్కాన్ చేయండి" | "বারকোড স্ক্যান টাপ" | "बारकोड स्कॅनसाठी टॅप" |
| `tutorial.skip` | "Skip" | "छोड़ें" | "தவிர்" | "దాటవేయి" | "এড়িয়ে যান" | "वगळा" |

## Backend Integration
- **Endpoint**: `POST /api/v1/onboarding/segment` (BE-34) — already called by FE-10; this phase consumes the response.
- **Endpoint**: `GET /api/v1/account/touchpoints` (BE-35) — checked on Personal fork mount to seed contextual prompts (later, not on first frame).
- **Endpoint**: `POST /api/v1/onboarding/fork-step-completed` (BE-34 v2 ext.) — optional ping when each step finishes.

### Request shape (fork-step-completed)
```typescript
export interface ForkStepCompletedRequest {
  segment: OnboardingSegment;
  stepId: 'welcome' | 'family_setup' | 'allergen' | 'activation' | 'token' | 'first_scan_tutorial';
  durationMs: number;
}
```

### Response shape
```typescript
export interface ForkStepCompletedResponse {
  acknowledged: boolean;
  forkProgress: number;           // 0.0 .. 1.0
}
```

### Error code → UI mapping
| HTTP | Error | UI |
|---|---|---|
| 401 | unauth | Route `/login` |
| 409 | step already completed | Silent no-op |
| 5xx | server | Drift outbox; retry on next session |

### Idempotency key
- `Idempotency-Key: fork-{userId}-{stepId}` — same step always same key.

## Accessibility
- Each welcome screen `Semantics(label: '${headline}. ${subtitle}. CTA: ${ctaLabel}.')`.
- Focus order: headline → subtitle (read-only) → CTA → optional skip.
- Dynamic type tested up to xxLarge.
- Reduced motion: stagger and Hero replaced with cross-fades; coach-mark uses static SVG.
- VoiceOver/TalkBack script per fork (e.g., Personal: "Let's get scanning. Tap Start scanning to open the camera.").

## Testing
- **Widget tests**:
  - `planFor` returns correct `ForkPlan` for each segment (6 cases)
  - `WelcomeCard` renders Lottie + microcopy + CTA
  - Skip path hides skip button when `onSkip == null`
  - Tutorial overlay re-prompts after 4s dwell
- **Golden tests**: 6 forks × 3 device sizes = 18 goldens; plus offline business fork.
- **Integration tests**:
  - All 6 fork happy paths
  - Personal fork renders tutorial after route to `/home`
  - Business fork blocks offline with banner
  - Auditor fork mounts token entry next

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Personal fork lands on `/home` and shows tutorial |
| T2 | Parent fork routes to `/family/setup` after CTA |
| T3 | Business Owner fork routes to `/business/activation` with preset=owner |
| T4 | Pharmacy fork preset=pharmacy carries through |
| T5 | Institution fork preset=institution carries through |
| T6 | Auditor fork routes to `/auditor/token` |
| T7 | Hero transition tag matches segment id end-to-end |
| T8 | Skip on Personal tutorial routes to `/home` and persists "skipped" |
| T9 | Reduced motion path replaces Lottie + Hero with crossfade |
| T10 | Offline business fork shows blocking banner |
| T11 | Deep-link to `/business/activation` without segment redirects to `/onboarding/segment` |
| T12 | `fork-step-completed` ping fires for each step (PostHog confirms) |
| T13 | First-scan tutorial dwell-shake fires after 4s of no tap |
| T14 | TalkBack reads welcome semantics on each fork |
| T15 | Idempotency key replay returns same `forkProgress` |

### Q&A (8)
1. How do we keep fork state recoverable if the user kills the app mid-fork — do they resume on cold start?
2. What is the contract between FE-11 fork progress and FE-50 onboarding-completion analytics — when is "onboarding complete" emitted?
3. If a user backs out of the fork (Android system back button), do we route to segment screen or kill the app?
4. How does the Parent fork sequence Family Setup before Allergen Profile — does the user see two screens, or a single wizard?
5. What is the priority when a deep link (push notification) arrives mid-fork?
6. How are fork lottie files preloaded so the welcome screen never shows a blank frame?
7. How does the Business fork coordinate with FE-15 to receive the `preset`, given FE-15 is its own controller?
8. What is the rollback if the user picked the wrong segment and wants to switch — and what data is preserved?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green for all 6 forks.
- [ ] Reviewer: Routing pure function audited for exhaustiveness; deep-link defenses verified.
- [ ] Designer (motion review): Hero handoff to each fork verified on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-11**
