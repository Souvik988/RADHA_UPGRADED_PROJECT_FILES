# Phase FE-15: Business Activation Wizard

## Phase Metadata
- **Phase ID**: FE-15
- **Phase Name**: Business Activation Wizard
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-06 (Dio), FE-07 (Riverpod), FE-08 (Drift), FE-12 (login), FE-11 (forks), BE-35 (activation API), BE-28 (trial pro)
- **Blocks**: FE-40 (business home), FE-50 (trial pro touchpoints)
- **Estimated Duration**: 3 days
- **Complexity**: High

## Goal
A 5-step wizard that turns a Consumer into an Owner with a real business tenant, store, and (optionally) Trial Pro subscription. Steps: business name → store name → address → preset (retail / pharmacy / institution) → trial pro acceptance + verified-eligibility callout. A linear progress bar at the top advances cleanly; each step has its own Hero element that lands as the previous step's CTA expands. Final success: confetti + "RADHA Verified eligible in 30 days" callout that anchors the long-term value proposition.

This wizard is the conversion engine. Every step has measurable drop-off and every interaction has been tuned to feel like a "yes, and" rather than a "fill this out." Default values where possible (city/state from device locale + IP geo), inline error recovery, and a single confident CTA per step.

## Why This Phase Matters
- **Direct revenue gate**: This wizard ends with a Trial Pro acceptance which converts to ₹49/₹99/₹199 paying subscriptions at 31%. Each completed activation = ~₹150 expected lifetime contribution.
- **Funnel conversion target**: Wizard completion target is **74%** from step 1 to step 5. Current consumer-app industry baseline is 38–55% for a 5-step business signup — so this design needs every advantage.
- **Verified-badge anchor**: The "Verified in 30 days" callout sets a 30-day re-engagement contract. Users who see this callout return to RADHA at week 4 at 2.3× the rate.
- **Trust + brand**: Business owners are signing up with their real shop name. Polish here directly affects whether they recommend RADHA to other shopkeepers.

## Prerequisites
- [ ] Backend: `POST /api/v1/account/activate-business` (BE-35)
- [ ] Backend: `GET /api/v1/account/touchpoints` (BE-35)
- [ ] Backend: `POST /api/v1/subscriptions/trial-pro/start` (BE-28 v2)
- [ ] FE-12 logged-in user with role=consumer
- [ ] Lottie: `activation_step_check.json` (0.6s one-shot, ≤30 KB)
- [ ] Lottie: `activation_success_confetti.json` (2.4s one-shot, ≤180 KB)
- [ ] Lottie: `verified_shield.json` (1.6s loop, ≤80 KB)
- [ ] Asset: India state list JSON (28 + 8); pincode validator regex
- [ ] PostHog flag `trial_pro_default_optin` (controls default checkbox state)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/activation/activation_wizard_screen.dart` | PageView host |
| `apps/mobile/lib/features/business/activation/activation_controller.dart` | Riverpod controller |
| `apps/mobile/lib/features/business/activation/activation_state.dart` | Sealed state |
| `apps/mobile/lib/features/business/activation/steps/step_business_name.dart` | Step 1 |
| `apps/mobile/lib/features/business/activation/steps/step_store_name.dart` | Step 2 |
| `apps/mobile/lib/features/business/activation/steps/step_address.dart` | Step 3 |
| `apps/mobile/lib/features/business/activation/steps/step_preset.dart` | Step 4 |
| `apps/mobile/lib/features/business/activation/steps/step_trial_pro.dart` | Step 5 |
| `apps/mobile/lib/features/business/activation/steps/step_success.dart` | Step 6 (success) |
| `apps/mobile/lib/features/business/activation/widgets/wizard_progress_bar.dart` | Linear progress |
| `apps/mobile/lib/features/business/activation/widgets/preset_card.dart` | Preset chooser tile |
| `apps/mobile/lib/features/business/activation/widgets/trial_callout.dart` | Trial Pro pricing card |
| `apps/mobile/lib/features/business/activation/widgets/verified_callout.dart` | "Verified in 30 days" |
| `apps/mobile/lib/features/business/activation/services/activation_repository.dart` | Wraps Dio |
| `apps/mobile/lib/features/business/activation/services/locale_defaults.dart` | City/state defaults |
| `apps/mobile/test/features/business/activation/activation_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/activation/golden/activation_states.dart` | Golden tests |
| `apps/mobile/integration_test/business_activation_test.dart` | E2E |

## Screen / Widget Spec

```dart
// activation_state.dart
sealed class ActivationState { const ActivationState(); }
class ActivationLoading extends ActivationState {}
class ActivationStep extends ActivationState {
  final ActivationStepId stepId;  // businessName | storeName | address | preset | trialPro | success
  final ActivationDraft draft;
  final ValidationErrors errors;
  final bool submitting;
}
class ActivationError extends ActivationState { final ActivationFailure failure; }
class ActivationCompleted extends ActivationState {
  final String tenantId;
  final String storeId;
  final bool trialStarted;
  final DateTime? trialEndsAt;
}

class ActivationDraft {
  final String? businessName;
  final String? storeName;
  final String? addressLine1;
  final String? city;
  final String? state;            // 2-letter India code
  final String? pincode;          // /^[1-9][0-9]{5}$/
  final BusinessPreset? preset;   // owner | pharmacy | institution
  final bool acceptTrialPro;
}
```

### `WizardProgressBar`
- Height 4dp; background `surface.100`; foreground `scanGreen.500`.
- `width = (currentStep / totalSteps) * 100%`; transitions over 320ms `Curves.easeOutCubicEmphasized`.
- Step labels (text below bar) `crossFade` between current and next at 50% bar progress.

### `PresetCard`
- 3 cards (Retail / Pharmacy / Institution); each has Lottie icon, title, 1-line description.
- Single-select; selected card morphs `BorderSide` from `1dp surface.200` → `2dp scanGreen.500` and lifts `BoxShadow(blurRadius: 12)` over 200ms.

### `TrialCallout`
- Card with headline "Try Pro free for 14 days," 3-bullet feature list, ₹0 today / ₹49 from Day 15 line, opt-in switch (default per flag).
- Switch toggle haptic = `selectionClick`.

### `VerifiedCallout` (success step)
- Lottie `verified_shield.json` looping behind copy "RADHA Verified — eligible in 30 days."
- Copy: "Keep your store healthy and earn the badge automatically."
- Tappable info icon expands an explanation sheet (uses BE-46 Verified Badge spec).

### Animations attached
- **Wizard transitions**: `PageView` slide + 6% scale on outgoing; 320ms `Curves.easeOutCubicEmphasized`.
- **Step entry**: headline + form fields stagger `.fadeIn(180ms).slideY(begin: 0.04)` with 60ms stagger.
- **Field validation**: errored field shake `.shake(hz: 4, offset: Offset(4, 0), duration: 320ms)`; error helper text slides down `.slideY(begin: -0.2).fadeIn(160ms)`.
- **Step CTA scale**: when form valid, CTA `.scale(begin: 0.96, end: 1.0, duration: 220ms, curve: Curves.easeOutBack)`.
- **Step check Lottie**: between steps, a tiny `activation_step_check.json` flashes over the progress bar at the just-completed step (0.6s).
- **Success step**: full-screen `activation_success_confetti.json` (2.4s); `verified_shield.json` plays underneath; "Done" CTA fades in at 1.6s.

### Hero elements per step
- Step 1: tag `business-name-pill` (input pill rectangle).
- Step 2: tag `store-name-pill`.
- Step 3: tag `address-card`.
- Step 4: tag `preset-card-${preset}`.
- Step 5: tag `trial-card`.
- Step 6: tag `verified-shield` (final element morphs from a small icon on Step 5 into the full shield).

### Haptic feedback events
- `HapticFeedback.lightImpact()` on each step advance.
- `HapticFeedback.selectionClick()` on preset card select; on trial switch toggle.
- `HapticFeedback.mediumImpact()` on final activate POST ACK.
- `HapticFeedback.heavyImpact()` on activation error (e.g., already-owner).

### Motion choreography (timeline) — overall wizard
| t (ms) | Event |
|---|---|
| 0 | Step 1 mounts; progress bar at 1/5 |
| 0–540 | Headline + field stagger |
| user-tap CTA | Light haptic; check Lottie flashes; page slides to Step 2 |
| ... | Repeat for steps 2–4 |
| Step 5 submit | Medium haptic; CTA shows inline progress |
| ack | Page slides to Step 6 |
| Step 6 mount | Confetti Lottie + verified shield; medium haptic |
| 1.6s after | Done CTA fades in |
| user-tap Done | Route push to `/business/home` |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Step 1 with empty business name field |
| **loading (locale defaults)** | City/state fields show shimmer; address step waits for IP geo |
| **loaded (step idle)** | Form fields interactive; CTA disabled until valid |
| **empty** | N/A — wizard always has a current step |
| **error (network on activate)** | Step 5 shows toast "Couldn't activate. Retry."; CTA re-enabled |
| **error (validation)** | Field-level errors with shake; Continue disabled |
| **error (already owner — 409)** | Modal "You're already a business owner" with CTA to business home |
| **success** | Step 6 confetti + verified shield + "Done" CTA |
| **offline** | All steps proceed locally; Step 5 submit blocks with banner "Connect to activate"; outbox NOT used (activation must be live) |
| **rate-limited / cooldown** | 429 on activate → 60s countdown ring on CTA |
| **permission-denied** | Location permission for city/state defaults is optional; user types manually if denied |
| **accessibility-mode (reduced motion)** | Page transitions cross-fade; check Lottie replaced with checkmark icon; confetti replaced with ✓ + announcement |
| **high contrast** | Wizard bar uses 2-color tokens; preset cards use solid backgrounds |
| **dynamic type xxLarge** | Form fields grow; preset cards stack vertically; success Lottie clips to safe area |

## Animations Inventory
- **Lottie files**:
  - `activation_step_check.json` — 0.6s one-shot, trigger: each step advance
  - `activation_success_confetti.json` — 2.4s one-shot, trigger: success step mount
  - `verified_shield.json` — 1.6s loop, trigger: success step
- **flutter_animate chains**:
  - Step entry headline: `.fadeIn(180ms).slideY(begin: 0.04)`
  - Form fields: `.fadeIn(180ms).slideY(begin: 0.04)` + 60ms stagger
  - Field error: `.shake(hz: 4, offset: Offset(4, 0), duration: 320ms)`
  - Error helper: `.slideY(begin: -0.2).fadeIn(160ms)`
  - CTA when valid: `.scale(begin: 0.96, end: 1.0, duration: 220ms, curve: Curves.easeOutBack)`
  - Success Done CTA: `.fadeIn(220ms).slideY(begin: 0.06)` after 1.6s delay
- **Hero transitions**: 5 hero tags listed above; each 320ms `Curves.easeOutCubic`.
- **Custom motion**: progress bar fill `Tween<double>` 320ms `Curves.easeOutCubicEmphasized`; preset card lift via `AnimatedContainer` with shadow + border transitions.
- **Stagger**: 60ms between fields; 80ms between preset cards.
- **Total motion budget**: entrance 480ms; transition 320ms; success 1.6s (allowed exception).

## Haptics
- **Light**: step advance.
- **Medium**: activation success ACK.
- **Heavy**: activation error.
- **Selection**: preset pick; trial switch toggle.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `act.headline.business` | "What's your business called?" | "आपका व्यवसाय का नाम?" | "உங்கள் வணிகப் பெயர்?" | "మీ వ్యాపార పేరు?" | "ব্যবসার নাম?" | "व्यवसायाचे नाव?" |
| `act.headline.store` | "And the store's name?" | "और दुकान का नाम?" | "கடையின் பெயர்?" | "స్టోర్ పేరు?" | "দোকানের নাম?" | "दुकानाचे नाव?" |
| `act.headline.address` | "Where is the store?" | "दुकान कहाँ है?" | "கடை எங்கே?" | "స్టోర్ ఎక్కడ?" | "দোকান কোথায়?" | "दुकान कुठे?" |
| `act.headline.preset` | "Pick the type" | "प्रकार चुनें" | "வகையை தேர்வு" | "రకం ఎంచుకోండి" | "ধরন বেছে নিন" | "प्रकार निवडा" |
| `act.headline.trial` | "Try Pro free for 14 days" | "Pro 14 दिन मुफ्त" | "Pro 14 நாட்கள் இலவசம்" | "Pro 14 రోజులు ఉచితం" | "Pro ১৪ দিন বিনামূল্যে" | "Pro 14 दिवस मोफत" |
| `act.headline.success` | "You're in business" | "आप व्यवसाय में हैं" | "வணிகம் தயார்" | "మీరు బిజినెస్‌లో ఉన్నారు" | "আপনি ব্যবসায়" | "तुम्ही व्यवसायात" |
| `act.preset.retail` | "Retail / kirana" | "किराना / रिटेल" | "சில்லறை" | "రిటైల్ / కిరాణా" | "রিটেল / মুদি" | "रिटेल / किराणा" |
| `act.preset.pharmacy` | "Pharmacy" | "फार्मेसी" | "மருந்தகம்" | "ఫార్మసీ" | "ফার্মেসি" | "फार्मसी" |
| `act.preset.institution` | "Institution / canteen" | "संस्थान / कैंटीन" | "நிறுவனம்" | "సంస్థ / క్యాంటీన్" | "প্রতিষ্ঠান / ক্যান্টিন" | "संस्था / कॅंटीन" |
| `act.trial.bullet1` | "Unlimited scans" | "असीमित स्कैन" | "வரம்பற்ற ஸ்கேன்" | "అపరిమిత స్కాన్‌లు" | "অসীমিত স্ক্যান" | "अमर्याद स्कॅन" |
| `act.trial.bullet2` | "Inventory + GRN" | "स्टॉक + GRN" | "ஸ்டாக் + GRN" | "ఇన్వెంటరీ + GRN" | "ইনভেন্টরি + GRN" | "इन्व्हेंटरी + GRN" |
| `act.trial.bullet3` | "Cancel anytime" | "कभी भी रद्द करें" | "எப்போது வேண்டுமானாலும்" | "ఎప్పుడైనా రద్దు" | "যেকোনো সময় বাতিল" | "केव्हाही रद्द" |
| `act.trial.cta` | "Start 14-day free trial" | "14 दिन का मुफ्त ट्रायल" | "14 நாள் இலவசம்" | "14 రోజుల ఉచిత" | "১৪ দিনের ফ্রি" | "14 दिवस मोफत" |
| `act.continue` | "Continue" | "जारी रखें" | "தொடரு" | "కొనసాగించండి" | "চালিয়ে যান" | "सुरू ठेवा" |
| `act.success.verified_callout` | "RADHA Verified — eligible in 30 days" | "RADHA Verified — 30 दिन में योग्य" | "RADHA Verified — 30 நாட்களில்" | "30 రోజుల్లో అర్హత" | "৩০ দিনে যোগ্য" | "30 दिवसांत पात्र" |
| `act.success.cta` | "Open my store" | "मेरी दुकान खोलें" | "என் கடை திற" | "నా స్టోర్ తెరవండి" | "আমার দোকান খুলুন" | "माझे दुकान उघडा" |
| `act.error.activate` | "Couldn't activate. Retry." | "सक्रिय नहीं हो सका।" | "செயல்படுத்த முடியவில்லை." | "యాక్టివేట్ కాలేదు." | "অ্যাক্টিভেট হয়নি।" | "सक्रिय झाले नाही." |
| `act.error.already_owner` | "You're already a business owner" | "आप पहले से ही व्यवसाय मालिक हैं" | "ஏற்கனவே உரிமையாளர்" | "ఇప్పటికే యజమాని" | "ইতিমধ্যে মালিক" | "आधीच मालक" |

## Backend Integration
- **Endpoint**: `POST /api/v1/account/activate-business` (BE-35)
- **Endpoint**: `POST /api/v1/subscriptions/trial-pro/start` (BE-28 v2) — implicitly via activation when `acceptTrialPro=true`

### Request shape
```typescript
export interface ActivateBusinessRequest {
  businessName: string;            // 1..120
  storeName: string;               // 1..120
  storeAddressLine1?: string;
  storeCity?: string;
  storeState?: string;             // 2-letter India code
  storePincode?: string;           // /^[1-9][0-9]{5}$/
  preset?: 'business_owner' | 'pharmacy' | 'institution';
  acceptTrialPro: boolean;
}
```

### Response shape
```typescript
export interface ActivateBusinessResponse {
  newRole: 'owner';
  newTenantId: string;
  newStoreId: string;
  trialStarted: boolean;
  trialEndsAt?: string;
}
```

### Error code → UI mapping
| HTTP | Error | UI |
|---|---|---|
| 400 | `validation_failed` | Field-level errors; shake; helper slide-down |
| 401 | `unauthorized` | Route to `/login` |
| 409 | `already_owner` | Modal `act.error.already_owner` with CTA to `/business/home` |
| 409 | `trial_already_used` | Step 5 inline note "You've used a trial before — Standard from Day 1" |
| 422 | `payment_method_required` (rare on Trial Pro) | Route to BE-28 add-mandate flow |
| 429 | `rate_limited` | 60s cooldown ring on CTA |
| 5xx / network | server | Toast + retry; never silent |

### Idempotency key generation
- `Idempotency-Key: business-activate-{userId}-{stableHash(payload)}` where stableHash = SHA-256 of canonicalized JSON. Replay returns same `tenantId`.

## Accessibility
- Each step: `Semantics(label: 'Step ${index+1} of 5: ${stepName}', liveRegion: true)`.
- Form fields: each labelled, `Semantics(textField: true, label: ..., enabled: !submitting)`.
- Preset cards: `Semantics(button: true, selected: ..., label: '${title}, ${subtitle}, double tap to select')`.
- Trial switch: `Semantics(toggled: ..., label: 'Start 14-day free trial')`.
- Verified callout: `Semantics(label: 'RADHA Verified, eligible in 30 days, info button to learn more')`.
- Focus order: progress bar (read-only) → headline (read-only) → first field → ... → CTA.
- Dynamic type tested xxLarge; preset cards stack vertically.
- Reduced motion: cross-fades; static SVG instead of Lottie confetti.
- VoiceOver/TalkBack script (success): "You're in business. RADHA Verified, eligible in 30 days. Open my store, button."

## Testing
- **Widget tests**:
  - Each step's form validation (business name length, pincode regex, etc.)
  - Progress bar fill matches step
  - Preset card single-select
  - Trial switch default reflects flag
  - Already-owner 409 routes to business home
- **Golden tests**: 5 steps + success + each error state = 9 goldens; plus reduced motion success.
- **Integration tests**:
  - Full happy path: 5 steps → activate → success → home
  - Trial opt-out: activates without trial
  - 409 already-owner: skip wizard, route to home

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Wizard mounts at Step 1 with empty draft |
| T2 | Pincode validator accepts `400001`, rejects `01234` |
| T3 | State picker lists all 28 states + 8 UTs |
| T4 | Preset selection updates draft and visually lifts the card |
| T5 | Continue disabled until step's required fields valid |
| T6 | Step advance triggers check Lottie + light haptic |
| T7 | Trial switch default state matches feature flag |
| T8 | Activate POST sends correct payload including preset |
| T9 | 409 already-owner shows modal and skips success |
| T10 | 409 trial-already-used renders inline note on Step 5 |
| T11 | 429 cooldown ring counts down on Activate CTA |
| T12 | Success step plays confetti + verified shield |
| T13 | Done CTA routes to `/business/home` with new tenantId in JWT |
| T14 | Reduced motion path replaces Lotties with icons |
| T15 | Idempotency replay returns same tenantId/storeId |

### Q&A (8)
1. How does the wizard reconcile when a user starts as Consumer with family members + allergen profiles already set up?
2. How is the JWT refreshed after activation so subsequent requests use the new owner role + tenantId?
3. What happens to local Drift caches scoped to the old consumer tenant after activation?
4. How do we surface the BE-28 Trial Pro pricing accurately if the server's pricing flag changes between Step 4 and Step 5?
5. What is the rollback path if Step 5 succeeds but the local Riverpod state fails to refresh — does the user see a stuck spinner?
6. How does the wizard coordinate with FE-50 (force-update) if a too-old client tries to activate?
7. How do we handle a network drop after the activate POST has been sent but before the response — do we replay or wait?
8. How does the verified callout integrate with BE-46 once the user actually qualifies — does this screen ever show again?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green for all paths.
- [ ] Reviewer: Idempotency keys verified; PII redaction in logs verified; tenant transition tested.
- [ ] Designer (motion review): Hero per step, confetti, verified shield approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-15**
