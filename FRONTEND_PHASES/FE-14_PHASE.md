# Phase FE-14: Allergen Profile Setup (Per-Member)

## Phase Metadata
- **Phase ID**: FE-14
- **Phase Name**: Allergen Profile Setup (Per-Member)
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-06 (Dio), FE-07 (Riverpod), FE-08 (Drift), FE-13 (family setup), BE-37 (allergen-profile API)
- **Blocks**: FE-20 (scan results with allergen warnings), FE-30 (premium home)
- **Estimated Duration**: 2.5 days
- **Complexity**: Medium-High

## Goal
A multi-step wizard to capture each family member's allergen and condition profile. Step 1: pick member from family list (skipped if entered from a member card). Step 2: select allergies via an animated chip grid (common allergens at top, alphabetical below). Step 3: select medical conditions (diabetes, hypertension, lactose intolerance, etc.). Step 4: confirm age band. Step 5: success card with "These warnings will appear on every scan."

The chip grid is the visual centerpiece. Each chip pulses on select, common allergens are visually elevated with a subtle glow, and the chip stack supports both single-tap and long-press-for-detail interactions. Display name is shown encrypted (e.g., "Riya •••") with a small lock icon and microcopy that explicitly says PII stays on-device.

## Why This Phase Matters
- **Safety value**: This is the screen that turns RADHA from "scanner" into "guardian." Every allergen tagged here directly drives a warning at scan time (BE-12 comprehensive scoring). Missed allergens = real-world harm.
- **Premium retention**: Family Sharing + Allergen Profile is the core premium bundle. Users with at least one configured allergen profile retain at 86% D30 vs 51% for premium without.
- **Scan engagement**: Profiles drive personalised scan output. A scanned product warning that names "Riya" by name is the moment the user becomes an evangelist.
- **Trust + privacy signal**: Display name encryption visible in UI is a soft compliance artifact for DPDP Act 2023 — and a competitive differentiator no other Indian scanner ships.

## Prerequisites
- [ ] Backend: `POST /api/v1/allergen/profiles` (BE-37)
- [ ] Backend: `PUT /api/v1/allergen/profiles/:id` (BE-37)
- [ ] Backend: `GET /api/v1/allergen/profiles` (BE-37)
- [ ] FE-13 family list available
- [ ] Allergen taxonomy JSON: `assets/allergen_taxonomy.json` (synced with BE-37 master taxonomy)
- [ ] Lottie: `allergen_pulse.json` (0.5s one-shot, ≤25 KB)
- [ ] Lottie: `profile_complete.json` (1.8s one-shot, ≤90 KB)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/allergen/allergen_wizard_screen.dart` | PageView host for 5 steps |
| `apps/mobile/lib/features/allergen/allergen_controller.dart` | Riverpod controller |
| `apps/mobile/lib/features/allergen/allergen_state.dart` | Sealed state |
| `apps/mobile/lib/features/allergen/steps/step_pick_member.dart` | Step 1 |
| `apps/mobile/lib/features/allergen/steps/step_allergies.dart` | Step 2 — chip grid |
| `apps/mobile/lib/features/allergen/steps/step_conditions.dart` | Step 3 — chip grid |
| `apps/mobile/lib/features/allergen/steps/step_age_band.dart` | Step 4 |
| `apps/mobile/lib/features/allergen/steps/step_success.dart` | Step 5 |
| `apps/mobile/lib/features/allergen/widgets/allergen_chip.dart` | Pulsing chip |
| `apps/mobile/lib/features/allergen/widgets/chip_grid.dart` | Wraps with stagger entry |
| `apps/mobile/lib/features/allergen/widgets/encrypted_name_pill.dart` | "Riya •••" badge |
| `apps/mobile/lib/features/allergen/widgets/wizard_progress.dart` | 5-dot progress |
| `apps/mobile/lib/features/allergen/services/allergen_repository.dart` | Wraps Dio |
| `apps/mobile/lib/features/allergen/services/allergen_taxonomy.dart` | Loads + caches taxonomy |
| `apps/mobile/test/features/allergen/allergen_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/allergen/golden/allergen_states.dart` | Golden tests |
| `apps/mobile/integration_test/allergen_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// allergen_state.dart
sealed class AllergenWizardState { const AllergenWizardState(); }
class AllergenLoading extends AllergenWizardState {}
class AllergenStep extends AllergenWizardState {
  final AllergenStepId stepId;    // pickMember | allergies | conditions | ageBand | success
  final AllergenDraft draft;
  final List<String> commonAllergens;     // taxonomy.commonForAge(draft.ageBand)
  final List<String> allAllergens;
  final List<String> allConditions;
  final bool submitting;
}
class AllergenError extends AllergenWizardState { final AllergenFailure failure; }

class AllergenDraft {
  final String? memberId;
  final String displayName;
  final AgeBand ageBand;
  final Set<String> allergyTags;
  final Set<String> conditionTags;
  final String? existingProfileId;        // edit mode
}
```

### `AllergenChip` widget
```dart
class AllergenChip extends StatefulWidget {
  final String tag;
  final bool selected;
  final bool common;              // visually elevated when true
  final VoidCallback onToggle;
  final VoidCallback onLongPress; // open detail sheet
}
```

Visual:
- Unselected, not common: `Container` with `surface.50`, `BorderRadius(20dp)`, padding `10dp 14dp`, label only.
- Common (unselected): `BoxShadow(color: scanGreen.500.withOpacity(0.18), blurRadius: 8)` + leading `🌟` glyph.
- Selected: background `scanGreen.500.withOpacity(0.18)`, border `scanGreen.500 1.5dp`, leading checkmark icon.
- Pulse on toggle: `.scale(begin: 1.0, end: 1.08, duration: 160ms, curve: Curves.easeOutBack).then(.scale(end: 1.0, duration: 140ms))`.
- Tiny `allergen_pulse.json` Lottie overlays at chip center for 500ms after select.

### `EncryptedNamePill`
- Pill showing `Riya •••` with `🔒` lock icon and tooltip on tap: "Display name is encrypted on your device."
- Microcopy variant: when name is empty, shows "You" with same lock.

### Animations attached
- **Chip grid entrance**: chips appear with `.fadeIn(160ms).slideY(begin: 0.04)` + 30ms stagger across rows; common allergens stagger first.
- **Step transitions**: `PageView` swiping with custom `PageTransitionsBuilder` — slide + 8% scale on outgoing page; 320ms `Curves.easeOutCubicEmphasized`.
- **Wizard progress dots**: each dot fills `width 6dp → 18dp` when active (current step) with `easeOutCubic` 220ms; completed dots stay `8dp` filled.
- **Success step**: Lottie `profile_complete.json` plays once; "Done" CTA scales in 320ms after Lottie peak.
- **Chip "common" badge**: subtle `BreathingScale(begin: 1.0, end: 1.04, duration: 1800ms)` to draw eyes.

### Haptic feedback events
- `HapticFeedback.selectionClick()` on every chip toggle.
- `HapticFeedback.lightImpact()` on step advance.
- `HapticFeedback.mediumImpact()` on final submit ACK (success step entry).
- `HapticFeedback.heavyImpact()` on submit error.

### Motion choreography (timeline) — chip grid step
| t (ms) | Event |
|---|---|
| 0 | Step mounts; encrypted name pill fades in |
| 0–520 | Chips stagger in (common first, ~30 chips × 30ms ≈ 900ms total but capped at 520 visible) |
| user-tap | Chip pulses; selectionClick |
| user-long-press | Detail sheet slides up with explanation |
| user-tap Continue | Page slides to next step |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Step 1 with member list shimmer |
| **loading (taxonomy fetch)** | Chip grid shimmers; CTA disabled |
| **loaded (step idle)** | Chips interactive; progress dots showing current step |
| **empty (no allergies / conditions selected)** | "Skip" CTA prominent; "Add an allergy" hint above grid |
| **error (network on submit)** | Toast "Couldn't save profile. Retry."; CTA re-enabled |
| **error (validation — duplicate profile)** | Step 1 banner "Riya already has a profile. Edit it?" with edit CTA |
| **success** | Step 5 Lottie + "Done" CTA + medium haptic |
| **offline** | All steps proceed; submit queued in Drift outbox; success step shows "Will sync when online" badge |
| **rate-limited / cooldown** | Submit disabled 30s with countdown ring on CTA |
| **permission-denied** | None — no runtime permissions needed |
| **accessibility-mode (reduced motion)** | Chip pulses replaced with color flash only; page transitions replaced with cross-fade; Lottie → checkmark icon |
| **high contrast** | Chips use 2dp `ink.900` border; selection state uses `ink.900` background + `surface.50` text |
| **dynamic type xxLarge** | Chips wrap to 2 lines; grid switches to single column |

## Animations Inventory
- **Lottie files**:
  - `allergen_pulse.json` — 0.5s one-shot per chip select
  - `profile_complete.json` — 1.8s one-shot, trigger: success step mount
- **flutter_animate chains**:
  - Chip entry: `.fadeIn(160ms).slideY(begin: 0.04)` + 30ms stagger
  - Chip pulse: `.scale(begin: 1.0, end: 1.08, duration: 160ms, curve: Curves.easeOutBack).then(.scale(end: 1.0, duration: 140ms))`
  - Wizard dots: `.tween(begin: 6.0, end: 18.0, curve: Curves.easeOutCubic, duration: 220ms)` for active dot width
  - Success CTA: `.scale(begin: 0.96, end: 1.0, duration: 240ms, curve: Curves.easeOutBack)`
  - Encrypted pill: `.fadeIn(180ms)` + `.shake(hz: 0.5, offset: Offset(2, 0))` once on first show
- **Hero transitions**: tag `family-member-${id}` from FE-13 card → wizard header pill; 320ms `Curves.easeOutCubic`.
- **Custom motion**: `PageView` step transitions — slide + 8% scale on outgoing; 320ms; `Curves.easeOutCubicEmphasized`.
- **Stagger**: 30ms between chips; 50ms between common-vs-rest groups.
- **Total motion budget**: entrance per step 520ms; transition 320ms; well-managed.

## Haptics
- **Light**: step advance; long-press detail sheet open.
- **Medium**: submit ACK (success step entry).
- **Heavy**: submit error.
- **Selection**: chip toggle (high-frequency event).

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `allergen.headline` | "What are {name}'s allergies?" | "{name} की एलर्जी क्या हैं?" | "{name}-இன் ஒவ்வாமைகள்?" | "{name} యొక్క అలెర్జీలు?" | "{name}-এর অ্যালার্জি?" | "{name}च्या अ‍ॅलर्जी?" |
| `allergen.sub` | "Tap any that apply. We'll warn you on every scan." | "टैप करें। हम स्कैन में चेताएंगे।" | "தொடர்புடையதை தேர்வு" | "సంబంధితవి టాప్ చేయండి" | "প্রযোজ্যগুলি ট্যাপ করুন" | "लागू असलेले टॅप करा" |
| `allergen.common_label` | "Common" | "सामान्य" | "பொதுவான" | "సాధారణం" | "সাধারণ" | "सामान्य" |
| `allergen.all_label` | "All allergens" | "सभी एलर्जी" | "எல்லா ஒவ்வாமைகள்" | "అన్ని అలెర్జీలు" | "সমস্ত অ্যালার্জি" | "सर्व अ‍ॅलर्जी" |
| `allergen.empty_hint` | "No allergies for {name}? Tap Skip." | "कोई एलर्जी नहीं? Skip करें।" | "ஒவ்வாமை இல்லையா?" | "అలెర్జీలు లేవా?" | "অ্যালার্জি নেই?" | "अ‍ॅलर्जी नाही?" |
| `allergen.skip` | "Skip" | "छोड़ें" | "தவிர்" | "దాటవేయి" | "এড়িয়ে যান" | "वगळा" |
| `allergen.continue` | "Continue" | "जारी रखें" | "தொடரு" | "కొనసాగించండి" | "চালিয়ে যান" | "सुरू ठेवा" |
| `allergen.conditions.headline` | "Any medical conditions?" | "कोई चिकित्सीय स्थिति?" | "மருத்துவ நிலை?" | "మెడికల్ కండిషన్?" | "চিকিৎসা অবস্থা?" | "वैद्यकीय स्थिती?" |
| `allergen.age_band.headline` | "Confirm age" | "उम्र पुष्टि करें" | "வயது உறுதி" | "వయస్సు నిర్ధారించండి" | "বয়স নিশ্চিত করুন" | "वय निश्चित करा" |
| `allergen.success.headline` | "All set" | "तैयार" | "தயார்" | "సిద్ధం" | "তৈরি" | "तयार" |
| `allergen.success.sub` | "Warnings will appear on every scan for {name}." | "{name} के लिए हर स्कैन में चेतावनी।" | "{name}-க்கு ஒவ்வொரு ஸ்கேனிலும்" | "ప్రతి స్కాన్‌లో హెచ్చరిక" | "প্রতি স্ক্যানে সতর্কতা" | "प्रत्येक स्कॅनवर इशारा" |
| `allergen.encryption_hint` | "Display names are encrypted on your device" | "नाम आपके डिवाइस पर एन्क्रिप्टेड" | "பெயர்கள் என்க்ரிப்ட்" | "పేర్లు ఎన్‌క్రిప్ట్" | "নাম এনক্রিপ্টেড" | "नावे एन्क्रिप्टेड" |
| `allergen.error.submit` | "Couldn't save. Retry." | "सहेजा नहीं जा सका।" | "சேமிக்க முடியவில்லை." | "సేవ్ కాలేదు." | "সংরক্ষণ হয়নি।" | "जतन झाले नाही." |

## Backend Integration
- **Endpoint**: `POST /api/v1/allergen/profiles` (BE-37)
- **Endpoint**: `PUT /api/v1/allergen/profiles/:id` (BE-37) — edit mode
- **Endpoint**: `GET /api/v1/allergen/profiles` (BE-37)
- **Endpoint**: `GET /api/v1/allergen/profiles/:id/active` (BE-37)

### Request shape (upsert)
```typescript
export interface UpsertAllergenProfileRequest {
  id?: string;                    // present in edit mode
  familyMemberUserId?: string;    // null = self
  displayName: string;            // 1..48
  ageBand: 'infant' | 'toddler' | 'child' | 'adolescent' | 'adult' | 'senior';
  allergyTags: string[];          // taxonomy keys
  conditionTags: string[];        // taxonomy keys
}
```

### Response shape
```typescript
export interface AllergenProfileDto {
  id: string;
  familyMemberUserId: string | null;
  displayNamePreview: string;     // first 1..2 chars + '•••'
  ageBand: AgeBand;
  allergyTags: string[];
  conditionTags: string[];
  createdAt: string;
  updatedAt: string;
}
```

### Error code → UI mapping
| HTTP | Error | UI |
|---|---|---|
| 400 | `unknown_tag` | Inline "Some tags are out of date. Refreshing taxonomy." (auto-retry) |
| 402 | `quota_exceeded` (free user, already has 1) | Modal "Premium unlocks 5 profiles" with upgrade CTA |
| 409 | `duplicate_for_member` | Banner on Step 1 "Already has a profile — edit?" |
| 5xx / network | server | Outbox; success step shows "Will sync" |

### Idempotency key generation
- `Idempotency-Key: allergen-{userId}-{familyMemberUserId ?? 'self'}-{revision}` where `revision` is a monotonic counter local to the device.

## Accessibility
- Each chip: `Semantics(button: true, toggled: selected, label: '${tag}, ${common ? "common, " : ""}${selected ? "selected" : "not selected"}, double tap to toggle')`.
- Wizard progress: `Semantics(label: 'Step ${index+1} of 5: ${stepName}', liveRegion: true)`.
- Encrypted pill: `Semantics(label: '${displayNamePreview}, name is encrypted')`.
- Focus order: encrypted pill (info) → first chip → ... → continue.
- Dynamic type tested xxLarge.
- Reduced motion: chip pulses use color flash; page transitions cross-fade.
- VoiceOver/TalkBack script: "Step 2 of 5. What are Riya's allergies. Common: peanut, button. Wheat, button. Long press for details."

## Testing
- **Widget tests**:
  - Chip toggles update draft state
  - Common allergens render first
  - Wizard progress dot fills on advance
  - Free user attempting second profile sees upgrade modal
  - Success step shows "Will sync" when offline
- **Golden tests**: each step (5) × 2 device sizes = 10 goldens; plus duplicate-profile banner and offline state.
- **Integration tests**:
  - Full happy path 5 steps → POST → success
  - Edit existing profile via PUT
  - Offline path queues outbox

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Step 1 lists family members from FE-13 |
| T2 | Step 2 chip grid renders common at top |
| T3 | Chip toggle updates draft tag set |
| T4 | Long press opens explanation sheet |
| T5 | Skip on Step 2 advances to Step 3 with empty allergies |
| T6 | Step 3 conditions follow same chip pattern |
| T7 | Step 4 age band picker single-select |
| T8 | Submit on Step 4 POSTs upsert and routes to Step 5 |
| T9 | Edit mode pre-fills draft from existing profile |
| T10 | Free user 2nd profile shows premium upsell |
| T11 | Duplicate profile banner appears on Step 1 |
| T12 | Offline submit shows "Will sync" badge |
| T13 | Reduced motion replaces pulse with color flash |
| T14 | TalkBack reads chip toggled state |
| T15 | Idempotency replay returns same profile id |

### Q&A (8)
1. How does the client keep its allergen taxonomy in sync with BE-37 master taxonomy across versions?
2. What is the contract for "common allergens for age band" — does the client compute or fetch?
3. How do we handle a chip that the user long-pressed for detail but the taxonomy doesn't ship a description for?
4. What happens to existing profiles when BE-37 adds a new allergen tag — does the client surface the new tag retroactively?
5. How is the encrypted display name shown without the client ever holding the cleartext after submit?
6. How do we test the matcher behaviour without leaking PII into test fixtures?
7. What is the active-profile selection persistence — is it device-local or follows the user across devices?
8. How does FE-14 coordinate with FE-30 premium home so the profile shows up immediately as "Active" in the family switcher?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green for create/edit/offline.
- [ ] Reviewer: Idempotency keys; PII never logged; taxonomy version pinning verified.
- [ ] Designer (motion review): Chip pulse, wizard dots, success Lottie approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-14**
