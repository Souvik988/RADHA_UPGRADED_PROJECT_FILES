# Phase FE-10: Onboarding Hero — Segment Selection 2×3 Card Grid

## Phase Metadata
- **Phase ID**: FE-10
- **Phase Name**: Onboarding Hero — Segment Selection
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion system), FE-05 (navigation), FE-06 (API client), FE-07 (Riverpod state), FE-09 (splash), BE-34 (segment API)
- **Blocks**: FE-11 (segment-specific flows), FE-12 (OTP), FE-15 (business activation), FE-16 (auditor token entry)
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal
This is the flagship onboarding screen — the single highest-leverage moment in the entire RADHA funnel. Six tap-cards arranged in a 2×3 grid let the user self-identify as **Personal**, **Business Owner**, **Parent**, **Pharmacy**, **Institution**, or **Auditor (invited)**. Each card is a small, animated promise of the experience the user will get if they tap it. The screen's job is not to ask "who are you?" — it is to show six different RADHAs and let the user pick the one that fits.

Every interaction is choreographed: cards stagger in (60ms each, 360ms total), Lottie idle states loop subtly, taps trigger haptic feedback, and the chosen card performs a Hero transition where it expands to fill the screen before routing to the segment-specific flow. The microcopy is A/B tested against PostHog cohorts (BE-29) and the visual hierarchy uses gradient mesh backgrounds to differentiate consumer cards from business cards without an explicit label.

## Why This Phase Matters
- **Conversion lift**: Industry data on segmented onboarding shows a 30–40% activation lift versus generic flows. RADHA's funnel projection assumes 35% lift; missing that target costs ~₹4 lakh/month at 50k MAU.
- **Business activation pipeline**: Three of six cards (Business Owner / Pharmacy / Institution) feed FE-15 directly. The card-to-activation conversion target is **62%** and is the single largest input to the ₹49/₹99/₹199 revenue funnel.
- **Brand impression**: This is the first interactive screen. Animation quality here sets the user's expectation for the next 30 days of use.
- **Personalization signal**: The chosen segment becomes the primary input to default home layouts, scoring profile defaults, language nudges, and notification cadences (BE-24, BE-29).

## Prerequisites
- [ ] Backend: `POST /api/v1/onboarding/segment` (BE-34)
- [ ] FE-04, FE-05, FE-06, FE-07, FE-09 merged
- [ ] Lottie files (one idle loop per card, ≤60 KB each):
  - `onb_personal.json`, `onb_business_owner.json`, `onb_parent.json`, `onb_pharmacy.json`, `onb_institution.json`, `onb_auditor.json`
- [ ] Gradient mesh PNG backgrounds (two variants — consumer warm, business cool)
- [ ] PostHog feature flag `onboarding_copy_variant_v2` provisioned (BE-50)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/onboarding/segment/segment_screen.dart` | Page widget; hosts the 2×3 grid |
| `apps/mobile/lib/features/onboarding/segment/segment_controller.dart` | Riverpod `AsyncNotifier` posts segment to API |
| `apps/mobile/lib/features/onboarding/segment/segment_state.dart` | Sealed state |
| `apps/mobile/lib/features/onboarding/segment/widgets/segment_card.dart` | Single tap-card with Lottie + gradient mesh + ripple |
| `apps/mobile/lib/features/onboarding/segment/widgets/segment_grid.dart` | Stagger-in 2×3 grid |
| `apps/mobile/lib/features/onboarding/segment/widgets/card_fill_hero.dart` | Hero `flightShuttleBuilder` for tap → fill animation |
| `apps/mobile/lib/features/onboarding/segment/data/segment_catalog.dart` | Static metadata (icon, lottie path, gradient, copy keys) |
| `apps/mobile/lib/features/onboarding/segment/data/segment_repository.dart` | Wraps `POST /onboarding/segment` |
| `apps/mobile/lib/features/onboarding/segment/analytics/segment_events.dart` | PostHog event mapper |
| `apps/mobile/test/features/onboarding/segment/segment_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/onboarding/segment/golden/segment_states.dart` | Golden tests |
| `apps/mobile/integration_test/segment_flow_test.dart` | E2E with mock backend |

## Screen / Widget Spec

```dart
// segment_state.dart
sealed class SegmentScreenState { const SegmentScreenState(); }
class SegmentIdle extends SegmentScreenState {
  final List<SegmentCardData> cards;
  final String copyVariant;       // 'control' | 'variant_a' | 'variant_b'
  const SegmentIdle({required this.cards, required this.copyVariant});
}
class SegmentSubmitting extends SegmentScreenState {
  final OnboardingSegment chosen; // for hero coordination
  const SegmentSubmitting(this.chosen);
}
class SegmentRouted extends SegmentScreenState {
  final String nextRoute;
  final OnboardingSegment chosen;
  const SegmentRouted(this.chosen, this.nextRoute);
}
class SegmentError extends SegmentScreenState {
  final OnboardingSegment chosen;
  final SegmentSubmitFailure failure;
  const SegmentError(this.chosen, this.failure);
}

// segment_controller.dart — public API
abstract interface class SegmentController {
  Future<void> select(OnboardingSegment segment);
  Future<void> retry();
}
```

### `SegmentCard` widget
```dart
class SegmentCard extends ConsumerStatefulWidget {
  final SegmentCardData data;
  final int index;                  // 0..5 — drives stagger delay
  final VoidCallback onTap;
  final bool isHeroOrigin;          // true for the tapped card during transition
  const SegmentCard({super.key, required this.data, required this.index, required this.onTap, this.isHeroOrigin = false});
}
```

Each card composes:
- `Hero(tag: 'segment-${data.id}')` wrapping the entire card surface
- `GradientMeshBackground(meshA, meshB, animatedOffset)` using `CustomPainter`
- `Lottie.asset(data.lottiePath, repeat: true, frameRate: FrameRate(30))` clipped to the card top half
- Title text with `MaterialLocalizations` value
- 1-line subtitle microcopy
- `InkWell` with `splashColor: data.accent.withOpacity(0.18)`

### Animations attached
- **Stagger entrance**: each card runs `.fadeIn(220ms).slideY(begin: 0.08, curve: Curves.easeOutCubic).scale(begin: 0.96)` with `delay: Duration(milliseconds: index * 60)` — total 60×5 + 220 = 520ms.
- **Idle loop**: Lottie repeats indefinitely.
- **Tap feedback**: `AnimatedScale(scale: pressed ? 0.97 : 1.0, duration: 90ms, curve: Curves.easeOut)`.
- **Card fill (Hero)**: tapped card uses `flightShuttleBuilder` to scale from card rect to full screen rect with `Curves.easeInOutCubicEmphasized`, 420ms.
- **Color wash on hero target**: receiving screen tints `data.accent.withOpacity(0.12)` for first 240ms then settles to neutral.

### Haptic feedback events
- `HapticFeedback.selectionClick()` on first ever press-down (signals "you can pick").
- `HapticFeedback.lightImpact()` on tap-up (signals "selected").
- `HapticFeedback.mediumImpact()` at the start of the Hero flight (signals "we're going").
- `HapticFeedback.heavyImpact()` on `SegmentError` toast.

### Motion choreography (timeline)
| t (ms) | Event |
|---|---|
| 0 | Page mounts; header `radha-wordmark` Hero arrives from splash |
| 0–360 | Header settles, "Welcome — pick your RADHA" fades in |
| 80 | First card begins its entrance |
| 80–600 | Six cards stagger in |
| 600+ | Idle loops play; PostHog `segment_screen_viewed` fires |
| user-tap | `selectionClick`; card scales to 0.97 |
| tap+90ms | `lightImpact`; outbound POST kicks off optimistically |
| tap+120ms | Hero flight begins; non-tapped cards `.fadeOut(180ms)` |
| tap+540ms | Backend ACK; `pushReplacement(nextRoute)` |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Cards invisible (opacity 0); header visible |
| **loading (cards rendering)** | Stagger entrance running; cards not yet tappable until t≥360ms |
| **loaded (idle)** | All six cards interactive; Lottie loops playing |
| **empty** | N/A — catalog is static |
| **error (network on submit)** | Tapped card shrinks back to 1.0 with a red `BorderSide(2dp)` flash; toast "Couldn't save your choice. Retry?"; other cards re-enable |
| **error (validation 400)** | Should not happen — defensive: same toast plus Sentry breadcrumb |
| **success** | Hero flight completes; next screen owns transition |
| **offline** | Cards still tappable; submission queued in Drift outbox; routes optimistically; banner on next screen "Will sync when online" |
| **rate-limited / cooldown** | After 5 rapid taps in 3s, all cards disabled; tooltip "One sec…" for 1.5s |
| **permission-denied** | None — screen needs no runtime permissions |
| **accessibility-mode (reduced motion)** | Stagger replaced with single `crossFade(220ms)`; Lottie replaced with static PNG; Hero flight replaced with `MaterialPageRoute` with `transitionDuration: 200ms` |
| **high contrast** | Gradient mesh swapped for solid token-based backgrounds; 2dp contrast border on each card |
| **dynamic type xxLarge** | Card titles wrap to 2 lines; subtitle truncates with ellipsis; min card height grows from 168dp to 220dp; grid switches to single column on widths < 360dp |

## Animations Inventory
- **Lottie files** (one per card; loop; 30fps; ≤60 KB each):
  - `onb_personal.json` — basket icon with bouncing apple, 1800ms loop, trigger: card mount
  - `onb_business_owner.json` — receipt with checkmarks, 2200ms loop
  - `onb_parent.json` — heart with two small dots orbiting, 1600ms loop
  - `onb_pharmacy.json` — green cross pulsing, 1400ms loop
  - `onb_institution.json` — building with rotating gear, 2400ms loop
  - `onb_auditor.json` — magnifying glass sweep, 1800ms loop
- **flutter_animate chains**:
  - Card entrance: `.fadeIn(220ms).slideY(begin: 0.08).scale(begin: 0.96, curve: Curves.easeOutCubic)`
  - Header: `.fadeIn(180ms).slideY(begin: -0.06)`
  - Toast: `.slideY(begin: 1.0, curve: Curves.easeOutBack).fadeIn(160ms)`
- **Hero transitions**: tag `segment-{id}` from card rect to full-screen header of next route; custom curve `Curves.easeInOutCubicEmphasized`; 420ms.
- **Custom motion**: gradient mesh offset cycles using `AnimationController` with `Tween<Offset>(begin: (0,0), end: (0.04, -0.03))` over 6000ms `Curves.easeInOut` reverse-loop; non-Hero cards `fadeOut(180ms)` during flight.
- **Stagger**: 60ms between siblings (index 0..5).
- **Total motion budget**: entrance 600ms (within 600ms guideline at the very edge; justified because this is the flagship); exit 420ms (Hero, justified; fade-out of non-hero cards is 180ms within 200ms guideline).

## Haptics
- **Light**: tap-up on a card.
- **Medium**: Hero flight start (route confirm).
- **Heavy**: submit error.
- **Selection**: tap-down (first interaction).

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `seg.headline` | "Pick your RADHA" | "अपनी RADHA चुनें" | "உங்கள் RADHA தேர்ந்தெடுக்கவும்" | "మీ RADHAని ఎంచుకోండి" | "আপনার RADHA বেছে নিন" | "तुमची RADHA निवडा" |
| `seg.subtitle` | "One app. Built around you." | "एक ऐप। आपके लिए।" | "ஒரு ஆப். உங்களுக்காக." | "మీ కోసం ఒక యాప్." | "একটি অ্যাপ। আপনার জন্য।" | "एक अॅप. तुमच्यासाठी." |
| `seg.personal.title` | "Personal" | "व्यक्तिगत" | "சொந்த" | "వ్యక్తిగత" | "ব্যক্তিগত" | "वैयक्तिक" |
| `seg.personal.sub` | "Scan, save, eat better" | "स्कैन करें, सहेजें, बेहतर खाएं" | "ஸ்கேன், சேமி, நலமாக சாப்பிடு" | "స్కాన్, సేవ్, ఆరోగ్యంగా" | "স্ক্যান, সেভ, ভালো খান" | "स्कॅन, सेव्ह, उत्तम खा" |
| `seg.business_owner.title` | "Business Owner" | "व्यवसाय मालिक" | "வணிக உரிமையாளர்" | "వ్యాపార యజమాని" | "ব্যবসায়ী" | "व्यवसाय मालक" |
| `seg.business_owner.sub` | "Run audits, prove quality" | "ऑडिट चलाएं, गुणवत्ता साबित करें" | "ஆடிட் செய், தரம் காட்டு" | "ఆడిట్‌లు నిర్వహించండి" | "অডিট চালান, মান প্রমাণ করুন" | "ऑडिट चालवा, दर्जा सिद्ध करा" |
| `seg.parent.title` | "Parent" | "अभिभावक" | "பெற்றோர்" | "తల్లిదండ్రులు" | "অভিভাবক" | "पालक" |
| `seg.parent.sub` | "Allergy-safe shopping" | "एलर्जी-सुरक्षित खरीदारी" | "ஒவ்வாமை பாதுகாப்பு" | "అలెర్జీ సురక్షితం" | "অ্যালার্জি-নিরাপদ কেনাকাটা" | "अलर्जी-सुरक्षित खरेदी" |
| `seg.pharmacy.title` | "Pharmacy" | "फार्मेसी" | "மருந்தகம்" | "ఫార్మసీ" | "ফার্মেসি" | "फार्मसी" |
| `seg.pharmacy.sub` | "Stock + expiry, the right way" | "स्टॉक + एक्सपायरी, सही तरीका" | "ஸ்டாக் + காலாவதி" | "స్టాక్ + ఎక్స్‌పైరీ" | "স্টক + এক্সপায়ারি" | "स्टॉक + एक्स्पायरी" |
| `seg.institution.title` | "Institution" | "संस्थान" | "நிறுவனம்" | "సంస్థ" | "প্রতিষ্ঠান" | "संस्था" |
| `seg.institution.sub` | "Compliance for canteens & schools" | "कैंटीन व स्कूलों के लिए" | "உணவகங்கள் & பள்ளிகள்" | "క్యాంటీన్‌లకు" | "ক্যান্টিন ও স্কুলের জন্য" | "कॅंटीन व शाळांसाठी" |
| `seg.auditor.title` | "Auditor (invited)" | "ऑडिटर (आमंत्रित)" | "ஆடிட்டர் (அழைப்பு)" | "ఆడిటర్ (ఆహ్వానం)" | "অডিটর (আমন্ত্রিত)" | "ऑडिटर (आमंत्रित)" |
| `seg.auditor.sub` | "Paste your invite token" | "अपना आमंत्रण टोकन डालें" | "அழைப்பு டோக்கனை ஒட்டு" | "ఆహ్వాన టోకెన్‌ను అతికించండి" | "ইনভাইট টোকেন পেস্ট করুন" | "इनवाइट टोकन पेस्ट करा" |
| `seg.error.submit` | "Couldn't save your choice. Retry?" | "आपकी पसंद सहेज नहीं सकी।" | "தேர்வு சேமிக்க முடியவில்லை." | "మీ ఎంపిక సేవ్ కాలేదు." | "পছন্দ সংরক্ষণ হয়নি।" | "तुमची निवड सेव्ह झाली नाही." |

(Variants `variant_a` / `variant_b` resolved at runtime via PostHog flag; copy keys suffixed `__a` / `__b` in the ARB.)

## Backend Integration
- **Endpoint**: `POST /api/v1/onboarding/segment` (BE-34)

### Request shape
```typescript
export interface SelectSegmentRequest {
  segment: 'personal' | 'business_owner' | 'parent' | 'pharmacy' | 'institution' | 'auditor_invited';
}
```

### Response shape
```typescript
export interface OnboardingRoutingDto {
  segment: OnboardingSegment;
  nextScreen:
    | 'consumer_home'
    | 'consumer_home_with_allergen_setup'
    | 'business_activation_flow'
    | 'auditor_invitation_token_entry';
  presetForBusinessActivation?: 'business_owner' | 'pharmacy' | 'institution';
  bypassedOnboarding: boolean;
}
```

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 400 | `invalid_segment` | Toast `seg.error.submit`; Sentry breadcrumb |
| 401 | `unauthorized` | Force route to `/login`; clear secure storage |
| 409 | `already_activated` | Toast "You're already set up — opening your home"; route to `/home` |
| 429 | `rate_limited` | Disable cards 1.5s, then re-enable |
| 5xx / network | — | Outbox the request in Drift; optimistically route |

### Idempotency key generation
- Header `Idempotency-Key: onboarding-segment-{userId}-{nonce}` where nonce = SHA-1 of (userId + segment + dayKey). Same key on retry → same response.

## Accessibility
- Each `SegmentCard` exposes `Semantics(button: true, label: '${title}. ${subtitle}. Double tap to choose.', enabled: !submitting)`.
- Focus order: header → card[0] → card[1] → ... → card[5]. `FocusTraversalGroup(policy: ReadingOrderTraversalPolicy())`.
- Dynamic type tested up to xxLarge (1.6× scale factor).
- Reduced motion: stagger replaced with `crossFade`, Lottie → PNG, Hero → standard slide.
- VoiceOver/TalkBack script: "Welcome to RADHA. Pick the option that fits you. Personal — scan, save, eat better. Double tap to choose." (Repeats for each card.)

## Testing
- **Widget tests**:
  - 6 cards rendered
  - Stagger delays computed correctly (0, 60, 120, 180, 240, 300)
  - Tap dispatches `select(segment)` exactly once
  - Loading state disables all cards
  - Reduced motion path renders PNGs
- **Golden tests**: each of 6 segments × 3 device sizes = 18 goldens; plus error and offline.
- **Integration tests**:
  - Tap each card → backend ACK → correct route push (6 paths)
  - 409 routes to `/home`
  - Offline tap routes optimistically and queues outbox

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Six cards render in 2×3 grid in correct order |
| T2 | Stagger entrance completes within 600ms |
| T3 | Tap on Personal POSTs `{segment:'personal'}` and routes to `/home` |
| T4 | Tap on Business Owner POSTs and routes to `/business/activation` |
| T5 | Tap on Pharmacy includes preset `pharmacy` in routing payload |
| T6 | Tap on Auditor routes to `/auditor/token` |
| T7 | Tapping a second card while submission is in flight is ignored |
| T8 | 409 response routes to `/home` and shows toast |
| T9 | 401 response routes to `/login` and clears storage |
| T10 | Offline tap queues outbox entry and routes optimistically |
| T11 | Hero transition tag `segment-{id}` lands on next-screen header |
| T12 | PostHog `onboarding_segment_selected` fires once per choice |
| T13 | Reduced motion path skips Lottie and stagger |
| T14 | TalkBack reads each card's full label |
| T15 | Idempotency-Key replay returns same routing |

### Q&A (8)
1. How does the screen reconcile if the user already has a segment server-side but reaches this screen via deep link?
2. What is the priority when copy variant flag, language, and reduced motion all change mid-frame?
3. How do we coordinate the Hero `flightShuttleBuilder` with a backend that hasn't ACKed yet — i.e., is the route optimistic?
4. What happens if the user chooses Auditor but never received an invite — do we let them proceed and fail at FE-16, or block here?
5. How is the gradient mesh background painted without burning battery (target ≤ 1% CPU during idle)?
6. How does the screen handle a returning user whose segment was previously `parent` and now they tap `personal`?
7. What is the empty-state behavior if the catalog metadata file fails to load?
8. How is the A/B copy variant attributed in PostHog so we can compute conversion lift?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green on Pixel 4a + iPhone 12.
- [ ] Reviewer: Hero coordination correct; outbox path verified.
- [ ] Designer (motion review): Stagger, Hero curve, gradient mesh, Lottie idle approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-10**
