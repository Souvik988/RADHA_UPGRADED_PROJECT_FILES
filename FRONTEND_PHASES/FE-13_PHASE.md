# Phase FE-13: Family Member Setup (Premium Flow)

## Phase Metadata
- **Phase ID**: FE-13
- **Phase Name**: Family Member Setup
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-06 (Dio), FE-07 (Riverpod), FE-08 (Drift), FE-12 (login), BE-36 (family-sharing API)
- **Blocks**: FE-14 (allergen profile per-member), FE-30 (premium home with family switcher)
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal
Deliver the screen where a Premium consumer adds up to 5 family members. The list view shows current members with avatar + display name + age band; an empty state Lottie invites the first add. The "+ Add member" CTA opens an animated bottom sheet that captures name, age band, and (optional) mobile number for invitation. The 5-member cap is enforced visually before the user even taps Add — the CTA disables and a soft tooltip appears.

The screen is the front-door of RADHA's family-sharing value prop. Every visual decision exists to make the invite feel like a gift, not a paperwork step.

## Why This Phase Matters
- **Premium retention**: Family Sharing is the single biggest premium retention driver — premium users with ≥2 family members churn at 4.1% vs 11.7% for solo premium. Every added member directly extends LTV.
- **Engagement multiplier**: Each family member becomes an independent active user (own scan history, own allergen profile). 5 members = up to 5× DAU per subscription.
- **Allergen funnel feeder**: This phase is the first half of the parent-fork experience; FE-14 (allergen profile) is gated on at least one member existing.
- **Trust signal**: Storing PII for family members (especially children) requires conspicuous gentle handling — visual hints that names are encrypted on-device build long-term trust.

## Prerequisites
- [ ] Backend: `POST /api/v1/family/invite` (BE-36)
- [ ] Backend: `POST /api/v1/family/accept` (BE-36)
- [ ] Backend: `DELETE /api/v1/family/members/:id` (BE-36)
- [ ] Backend: `GET /api/v1/family/members` (BE-36)
- [ ] FE-12 logged-in user
- [ ] Lottie: `family_empty.json` (3.2s loop, ≤120 KB)
- [ ] Lottie: `member_added.json` (1.4s one-shot, ≤60 KB)
- [ ] Asset: 8 default avatar SVGs (color-blind safe palette)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/family/family_screen.dart` | Page widget |
| `apps/mobile/lib/features/family/family_controller.dart` | Riverpod `AsyncNotifier<FamilyState>` |
| `apps/mobile/lib/features/family/family_state.dart` | Sealed state |
| `apps/mobile/lib/features/family/widgets/member_card.dart` | Single member row |
| `apps/mobile/lib/features/family/widgets/empty_state.dart` | Lottie + headline + CTA |
| `apps/mobile/lib/features/family/widgets/add_member_sheet.dart` | Animated bottom sheet form |
| `apps/mobile/lib/features/family/widgets/member_count_chip.dart` | "3 of 5" visual cap indicator |
| `apps/mobile/lib/features/family/widgets/avatar_picker.dart` | 8-avatar grid in sheet |
| `apps/mobile/lib/features/family/services/family_repository.dart` | Wraps Dio calls |
| `apps/mobile/lib/features/family/services/family_local_cache.dart` | Drift table + sync logic |
| `apps/mobile/test/features/family/family_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/family/golden/family_states.dart` | Golden tests |
| `apps/mobile/integration_test/family_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// family_state.dart
sealed class FamilyState { const FamilyState(); }
class FamilyLoading extends FamilyState {}
class FamilyLoaded extends FamilyState {
  final List<FamilyMember> members;
  final int maxMembers;           // 5 for premium, 0 for free
  final bool capReached;          // members.length == maxMembers
}
class FamilyAdding extends FamilyState {
  final List<FamilyMember> members;
  final AddMemberDraft draft;
  final bool submitting;
}
class FamilyError extends FamilyState { final FamilyFailure failure; }

class FamilyMember {
  final String id;
  final String displayName;       // encrypted at rest server-side
  final AgeBand ageBand;
  final String avatarKey;         // 'a01'..'a08'
  final String? phoneE164;        // null = self-managed
  final InviteStatus status;      // pending / accepted / self
}
```

### `MemberCard` widget
```dart
class MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;       // open allergen profile
  final VoidCallback onRemove;    // confirm dialog
}
```

Layout:
- 64dp avatar (left) → 1-line name + age band chip (center) → trailing icon (chevron if accepted, "pending" pill if invited, X if removable).
- Background: `surface.50` with `BorderRadius(12dp)`; subtle `BoxShadow(blurRadius: 6, color: ink.900.withOpacity(0.04))`.

### `AddMemberSheet`
- `showModalBottomSheet` with `isScrollControlled: true`, `useRootNavigator: true`, `clipBehavior: Clip.antiAlias`, `shape: RoundedRectangleBorder(top: 24dp)`.
- Sheet animates `from: Offset(0, 1)` to `Offset.zero` over 320ms `Curves.easeOutCubicEmphasized`.
- Form fields: Name (`TextFormField`, max 48 chars), Age band picker (segmented `ChoiceChip` row), Avatar grid (8 SVGs, single-select), optional Mobile number (with country picker).
- Submit button: full-width, scales `0.96 → 1.0` once form valid.
- Encryption hint: small lock icon + microcopy "Names are encrypted on your device" below the name field, fades in on first focus.

### Animations attached
- **List entrance**: each `MemberCard` `.fadeIn(180ms).slideX(begin: -0.04)` with 50ms stagger.
- **New member added**: card slides in from bottom `.slideY(begin: 0.4, curve: Curves.easeOutBack, duration: 360ms)` + plays `member_added.json` confetti overlay (1.4s).
- **Removed member**: card `.slideX(end: 0.6).fadeOut(220ms)` then collapses height with `AnimatedSize`.
- **Empty state**: Lottie `family_empty.json` loops; CTA scales in after 320ms.
- **Cap reached**: tooltip slides in `.fadeIn(140ms).slideY(begin: -0.1)` near disabled CTA.

### Haptic feedback events
- `HapticFeedback.lightImpact()` on Add sheet open.
- `HapticFeedback.selectionClick()` on age band / avatar picker change.
- `HapticFeedback.mediumImpact()` on successful add (match the confetti).
- `HapticFeedback.heavyImpact()` on remove confirm.
- `HapticFeedback.lightImpact()` blocked-tap (cap reached) — short, soft.

### Motion choreography (timeline) — first add
| t (ms) | Event |
|---|---|
| 0 | Page mounts; list either empty or loading |
| 0–320 | Empty Lottie fades in; CTA scales in |
| user-tap CTA | Light haptic; sheet slides up |
| sheet+0 | Name field focused; keyboard shows |
| user-fills | Validation states animate |
| submit | Submit button shows inline progress |
| ack | Sheet slides down `.slideY(end: 1)`; confetti Lottie plays; new card slides in |
| ack+1400 | Confetti dissolves |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | List skeleton (3 shimmer cards) |
| **loading (fetch members)** | Shimmer cards animating |
| **loaded (with members)** | Member cards rendered; `MemberCountChip` shows "n of 5" |
| **empty** | Full-screen Lottie + "Build your family circle" + CTA |
| **error (network on fetch)** | Banner "Couldn't load family. Retry?" with retry button |
| **error (network on add)** | Sheet stays open; inline error "Couldn't add member. Retry."; submit re-enabled |
| **error (validation)** | Field-level error chips; submit disabled until cleared |
| **error (cap reached)** | CTA disabled; tooltip "5 members maximum" appears for 2s |
| **success** | Confetti + new card slide-in + medium haptic |
| **offline** | Add still works; queued in Drift outbox; card shown with "syncing" badge until acceptance |
| **rate-limited / cooldown** | After 6 invites in 10 minutes, CTA disabled; tooltip with countdown |
| **permission-denied (contacts)** | Optional: contacts importer disabled; manual entry only |
| **accessibility-mode (reduced motion)** | Stagger replaced with `crossFade(180ms)`; confetti replaced with checkmark + announcement |
| **high contrast** | Cards use 1dp `ink.900` border; avatar background uses solid token color |
| **dynamic type xxLarge** | Card height grows from 80dp → 120dp; sheet content scrolls |

## Animations Inventory
- **Lottie files**:
  - `family_empty.json` — 3.2s loop, trigger: empty state mount
  - `member_added.json` — 1.4s one-shot, trigger: successful add ACK
- **flutter_animate chains**:
  - Card entrance: `.fadeIn(180ms).slideX(begin: -0.04)` + 50ms stagger
  - New card: `.slideY(begin: 0.4, curve: Curves.easeOutBack, duration: 360ms)`
  - Removed card: `.slideX(end: 0.6).fadeOut(220ms)` + `AnimatedSize` collapse
  - Empty CTA: `.scale(begin: 0.96, end: 1.0, duration: 220ms)` + delay 320ms
  - Tooltip: `.fadeIn(140ms).slideY(begin: -0.1)`
  - Encryption hint: `.fadeIn(180ms)` on first name-field focus
- **Hero transitions**: tag `family-member-${id}` from card → allergen profile screen header (FE-14); 320ms `Curves.easeOutCubic`.
- **Custom motion**: bottom sheet uses `AnimatedPadding` to lift content above keyboard; `MemberCountChip` morphs color from `scanGreen.500` → `warning.500` when reaching 5/5.
- **Stagger**: 50ms between cards.
- **Total motion budget**: entrance 470ms; exit 220ms (within budgets).

## Haptics
- **Light**: open sheet; cap-reached tap; tooltip dismiss.
- **Medium**: successful add.
- **Heavy**: remove confirm.
- **Selection**: age band / avatar pick; field validation transition.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `family.headline` | "Your family circle" | "आपका परिवार" | "உங்கள் குடும்பம்" | "మీ కుటుంబం" | "আপনার পরিবার" | "तुमचे कुटुंब" |
| `family.empty.headline` | "Build your family circle" | "अपना परिवार बनाएं" | "உங்கள் குடும்பத்தை உருவாக்கு" | "మీ కుటుంబాన్ని సృష్టించండి" | "পরিবার তৈরি করুন" | "तुमचे कुटुंब बनवा" |
| `family.empty.sub` | "Add up to 5 members. Each gets their own scans, profile, and alerts." | "5 तक सदस्य जोड़ें। प्रत्येक के अपने स्कैन।" | "5 உறுப்பினர்கள் வரை சேர்" | "5 సభ్యులను జోడించండి" | "৫ পর্যন্ত সদস্য যোগ" | "5 पर्यंत सदस्य जोडा" |
| `family.cta.add` | "+ Add member" | "+ सदस्य जोड़ें" | "+ உறுப்பினர் சேர்" | "+ సభ్యుడిని జోడించండి" | "+ সদস্য যোগ" | "+ सदस्य जोडा" |
| `family.cap.reached` | "5 members maximum" | "अधिकतम 5 सदस्य" | "அதிகபட்சம் 5" | "గరిష్టంగా 5" | "সর্বোচ্চ ৫" | "जास्तीत जास्त 5" |
| `family.sheet.name` | "Display name" | "नाम" | "பெயர்" | "పేరు" | "নাম" | "नाव" |
| `family.sheet.age_band` | "Age" | "उम्र" | "வயது" | "వయసు" | "বয়স" | "वय" |
| `family.sheet.avatar` | "Pick an avatar" | "अवतार चुनें" | "அவதார் தேர்ந்தெடு" | "అవతార్ ఎంచుకోండి" | "অবতার বেছে নিন" | "अवतार निवडा" |
| `family.sheet.phone` | "Mobile number (optional)" | "मोबाइल नंबर (वैकल्पिक)" | "மொபைல் (விருப்ப)" | "మొబైల్ (ఐచ్ఛిక)" | "মোবাইল (ঐচ্ছিক)" | "मोबाइल (पर्यायी)" |
| `family.sheet.cta` | "Add member" | "सदस्य जोड़ें" | "உறுப்பினர் சேர்" | "సభ్యుడిని జోడించండి" | "সদস্য যোগ" | "सदस्य जोडा" |
| `family.encryption_hint` | "Names are encrypted on your device" | "नाम आपके डिवाइस पर एन्क्रिप्टेड हैं" | "பெயர்கள் என்க்ரிப்ட்" | "పేర్లు ఎన్‌క్రిప్ట్" | "নামগুলি এনক্রিপ্টেড" | "नावे एन्क्रिप्टेड" |
| `family.member.pending` | "Invite pending" | "निमंत्रण लंबित" | "அழைப்பு நிலுவையில்" | "ఆహ్వానం పెండింగ్" | "আমন্ত্রণ মুলতুবি" | "आमंत्रण प्रलंबित" |
| `family.remove.confirm` | "Remove {name}?" | "{name} को हटाएं?" | "{name}-ஐ அகற்றலாமா?" | "{name}ని తొలగించాలా?" | "{name} সরাবেন?" | "{name} काढायचे?" |

## Backend Integration
- **Endpoint**: `GET /api/v1/family/members` (BE-36)
- **Endpoint**: `POST /api/v1/family/invite` (BE-36)
- **Endpoint**: `POST /api/v1/family/accept` (BE-36) — used in FE-12 flow when invitee logs in
- **Endpoint**: `DELETE /api/v1/family/members/:id` (BE-36)

### Request shape (invite)
```typescript
export interface FamilyInviteRequest {
  displayName: string;            // 1..48 chars; will be encrypted server-side
  ageBand: 'infant' | 'toddler' | 'child' | 'adolescent' | 'adult' | 'senior';
  avatarKey: string;              // 'a01'..'a08'
  phoneE164?: string;             // optional; if provided, SMS invite is sent
}
```

### Response shape (invite)
```typescript
export interface FamilyInviteResponse {
  member: FamilyMemberDto;        // includes id, status='pending'|'self'
  remainingSlots: number;         // 5 - members.length
  smsSent: boolean;
}
```

### Error code → UI mapping
| HTTP | Error | UI |
|---|---|---|
| 400 | `invalid_payload` | Inline field error |
| 402 | `payment_required` (free user) | Modal "Family Sharing is a Premium feature" → upgrade CTA |
| 409 | `cap_exceeded` | Tooltip "5 members maximum" + close sheet |
| 409 | `already_member` | Inline "{phone} is already in your family" |
| 429 | `rate_limited` | Cooldown on CTA with countdown |
| 5xx / network | server | Outbox; card shown with `syncing` badge |

### Idempotency key generation
- `Idempotency-Key: family-invite-{userId}-{nameHash}-{phoneE164OrLocalNonce}` — same name + phone → same key, stays idempotent across retries.

## Accessibility
- `MemberCard` semantics: `Semantics(button: true, label: '${displayName}, ${ageBand}, ${status}, double tap to view profile')`.
- Empty CTA: `Semantics(button: true, label: 'Add a family member')`.
- Sheet form: each field labelled; submit button announces validation state.
- Focus order: name → age band → avatar grid → phone → submit.
- Dynamic type tested xxLarge — sheet content scrolls.
- Reduced motion: cross-fades replace stagger and confetti.
- VoiceOver/TalkBack script: "Your family circle, three of five members. Riya, child, double tap to view profile."

## Testing
- **Widget tests**:
  - Empty state renders Lottie + CTA
  - 5/5 cap disables CTA + shows tooltip
  - Add sheet validates name length (1..48)
  - Avatar picker single-select
  - Remove confirm dialog requires explicit confirm
- **Golden tests**: empty, 1-member, 5-member capped, sheet open with valid form, sheet error state, offline.
- **Integration tests**:
  - Add member → POST → confetti → list updates
  - Remove member → DELETE → card collapses
  - Free user opens screen → sees premium upsell modal

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | List loads from `GET /family/members` |
| T2 | Empty state renders correctly |
| T3 | Add sheet rejects empty name |
| T4 | Add sheet rejects name longer than 48 chars |
| T5 | Avatar picker requires exactly one selection |
| T6 | Submit POSTs `/family/invite` with correct payload |
| T7 | Successful add fires confetti + medium haptic |
| T8 | 5/5 cap disables CTA and shows tooltip |
| T9 | Free user gets premium upsell modal on open |
| T10 | Remove flow requires confirm |
| T11 | DELETE refreshes list and recomputes count |
| T12 | Pending invite shows "syncing" badge until accepted |
| T13 | Offline add queues outbox and renders optimistic card |
| T14 | TalkBack reads member card semantics |
| T15 | Idempotency replay returns same `member.id` |

### Q&A (8)
1. How does the screen decide between "self" and "invited member" — is there always a self entry visible?
2. What happens to existing members if the primary cancels Premium — do they disappear or are they shown read-only with a banner?
3. How does FE-13 coordinate with FE-12 if an invited member is also being asked to log in via OTP?
4. What is the contract for `displayName` encryption — does the client encrypt before send, or is the field encrypted at rest server-side only?
5. How is the avatar key kept in sync if we ship new avatar SVGs in a future release?
6. What is the offline-add UX exactly — when does the optimistic card flip from "syncing" to "accepted"?
7. How do we handle a phone number invitation that resolves to the same primary user (self-invite)?
8. How does this screen relate to FE-14 — does adding a member auto-route to allergen profile, or is that a separate "+ allergens" CTA on the card?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green for add/remove/cap/free-upsell.
- [ ] Reviewer: Outbox path verified; idempotency keys verified; PII never logged.
- [ ] Designer (motion review): Confetti + sheet curve + cap tooltip approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-13**
