# Phase FE-16: Auditor Invitation Token Entry

## Phase Metadata
- **Phase ID**: FE-16
- **Phase Name**: Auditor Invitation Token Entry
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-06 (Dio), FE-07 (Riverpod), FE-12 (login), FE-11 (forks), BE-06 v2 (invitation API)
- **Blocks**: FE-41 (auditor home / EAN list)
- **Estimated Duration**: 1.5 days
- **Complexity**: Medium

## Goal
The screen an invited Auditor uses to redeem their invitation token. Two parallel input paths: (a) a paste-friendly text field that auto-fills from the clipboard with a permission-respecting prompt, and (b) a QR scan fallback for printed invitation cards / WhatsApp shared QR. After validation, a role-confirmation screen pre-fills the auditor's tenant + store assignment so they can confirm before being dropped into the auditor home.

The token is short (10 alphanumeric chars + 2-char checksum, e.g., `K9X2A4P7T1-Q3`). The field auto-uppercases, auto-inserts the dash, and rejects ambiguous characters (no `0/O`, `1/I/L`). Validation animation confirms the token shape before the network round-trip; once accepted, a Lottie shield lights up and the role-pre-fill screen slides in.

## Why This Phase Matters
- **Onboarding completion gate**: Auditors are 8–12% of business-side users but are the most enterprise-facing audience. A friction-free token redemption is the difference between a vendor recommending RADHA and not.
- **Token UX matters**: Industry data on token redemption shows clipboard auto-fill alone improves redemption from 64% → 91%. QR fallback closes the remaining 9% for users who don't have a typeable invite.
- **Trust signal**: Auditors arrive with skepticism (they audit retailers professionally). A polished token flow signals that the platform is built for their workflow, not bolted on.
- **Conversion to first audit**: Target time from token paste to first scan ≤ 60s. Anything more loses the audit-day.

## Prerequisites
- [ ] Backend: `POST /api/v1/auth/invitation/validate` (BE-06 v2)
- [ ] Backend: `POST /api/v1/auth/invitation/accept` (BE-06 v2)
- [ ] FE-12 logged-in user (or pending-invitation handover from FE-12)
- [ ] Plugin: `mobile_scanner` ≥3.5 (used elsewhere too — already in pubspec)
- [ ] Plugin: `flutter_clipboard_manager` for prompt-based clipboard read
- [ ] Lottie: `token_validating.json` (1.2s loop, ≤40 KB)
- [ ] Lottie: `token_valid_shield.json` (1.4s one-shot, ≤80 KB)
- [ ] Lottie: `token_invalid_shake.json` (0.5s one-shot, ≤25 KB)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/auditor/token/token_screen.dart` | Token entry page |
| `apps/mobile/lib/features/auditor/token/token_controller.dart` | Riverpod controller |
| `apps/mobile/lib/features/auditor/token/token_state.dart` | Sealed state |
| `apps/mobile/lib/features/auditor/token/widgets/token_field.dart` | Auto-formatting field |
| `apps/mobile/lib/features/auditor/token/widgets/clipboard_prompt.dart` | "Paste this?" toast |
| `apps/mobile/lib/features/auditor/token/widgets/qr_scan_sheet.dart` | Bottom sheet with mobile_scanner |
| `apps/mobile/lib/features/auditor/token/widgets/role_confirm_card.dart` | Tenant/store pre-fill display |
| `apps/mobile/lib/features/auditor/token/services/token_validator.dart` | Local checksum verify |
| `apps/mobile/lib/features/auditor/token/services/token_repository.dart` | Wraps Dio |
| `apps/mobile/lib/features/auditor/token/services/clipboard_listener.dart` | App-foreground clipboard read |
| `apps/mobile/test/features/auditor/token/token_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/auditor/token/golden/token_states.dart` | Golden tests |
| `apps/mobile/integration_test/auditor_token_test.dart` | E2E |

## Screen / Widget Spec

```dart
// token_state.dart
sealed class TokenState { const TokenState(); }
class TokenIdle extends TokenState {
  final String partial;           // current characters
  final bool checksumValid;       // local quick-check
}
class TokenValidating extends TokenState { final String token; }
class TokenInvalid extends TokenState { final String token; final TokenInvalidReason reason; }
class TokenValid extends TokenState {
  final InvitationDto invite;     // tenant, store, role pre-fill
  final String token;
}
class TokenAccepting extends TokenState { final InvitationDto invite; }
class TokenAccepted extends TokenState { final String tenantId; final String storeId; }
class TokenError extends TokenState { final TokenFailure failure; }

class InvitationDto {
  final String tenantName;
  final String storeName;
  final String role;              // 'auditor'
  final String inviterName;
  final DateTime expiresAt;
}
```

### `TokenField` widget
```dart
class TokenField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final bool errored;
}
```

Behaviour:
- Auto-uppercase, auto-strip ambiguous `0/O/1/I/L` → reject character with selectionClick haptic + brief red tint on the field's right edge.
- Auto-insert `-` after position 10.
- Length cap 13 (10 + `-` + 2 checksum).
- Right-side suffix icon transitions: `Icons.content_paste` (idle) → `Icons.qr_code_scanner` (after first failed paste) → `Icons.check_circle` (when `checksumValid == true`).

### `ClipboardPrompt`
- Soft toast that appears 240ms after screen mount if clipboard contents match the token regex.
- Copy: "Looks like an invite token — paste it?" with `Paste` and `Dismiss` actions.
- Slides in `.slideY(begin: 1.0, curve: Curves.easeOutBack).fadeIn(180ms)`; auto-dismiss after 6s.

### `QrScanSheet`
- Bottom sheet 70% height; `mobile_scanner` view with overlay frame and "Hold the QR steady" caption.
- Recognised token highlights with green border + Lottie shield 0.6s, then auto-closes sheet and routes through validation.

### `RoleConfirmCard`
- After validation: card with inviter's name, tenant + store, role, expiry; CTA "Accept and start auditing."
- Hero tag `auditor-shield` morphs from validation Lottie to top of card.

### Animations attached
- **Token field**: each accepted character `.scale(begin: 0.6, end: 1.0, duration: 140ms, curve: Curves.easeOutBack)`; on auto-dash insert, brief glow on the dash.
- **Validating state**: Lottie `token_validating.json` loops on the right side of the field (32dp).
- **Valid state**: `token_valid_shield.json` plays once over the field area; field morphs `borderColor: scanGreen.500`.
- **Invalid state**: `token_invalid_shake.json` plus field `.shake(hz: 4, offset: Offset(6, 0), duration: 360ms)` and `borderColor: error.500` for 320ms.
- **Role confirm card**: slide in `.slideY(begin: 0.06).fadeIn(220ms)`; CTA scale-in.

### Haptic feedback events
- `HapticFeedback.selectionClick()` on each character entry.
- `HapticFeedback.lightImpact()` on clipboard paste.
- `HapticFeedback.lightImpact()` on QR sheet open.
- `HapticFeedback.mediumImpact()` on validation success.
- `HapticFeedback.heavyImpact()` on validation invalid (clear failure signal).

### Motion choreography (timeline)
| t (ms) | Event |
|---|---|
| 0 | Page mounts; field focused; keyboard up |
| 240 | Clipboard prompt appears if applicable |
| user-types or pastes | Field accepts; checksum runs once at length 13 |
| checksum-pass | `TokenValidating` state; Lottie spins; outbound POST fires |
| 200–600 | Server response |
| ack-valid | Shield Lottie + medium haptic; role card slides in |
| user-tap Accept | POST accept; sheet dismisses; route to `/auditor/home` |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Empty field; suffix icon = paste; clipboard prompt may appear |
| **loading (validating)** | Lottie spinner inline; field disabled |
| **loaded (valid)** | Shield Lottie; role card visible |
| **empty** | Same as initial |
| **error (network on validate)** | Toast "Couldn't validate. Retry."; field re-enabled |
| **error (validation — checksum)** | Local: red tint + heavy haptic; copy "Check the token." |
| **error (server — invalid)** | "This token isn't valid or has been used." |
| **error (server — expired)** | "This invite expired on {date}. Ask for a new one." |
| **success** | Role confirm card visible; Accept CTA enabled |
| **offline** | Local checksum still works; network validate blocked with banner; Accept blocked offline |
| **rate-limited / cooldown** | After 5 attempts in 10 minutes, 60s cooldown ring on field submit |
| **permission-denied (camera)** | QR sheet shows fallback: "Camera disabled — paste your token instead" |
| **permission-denied (clipboard)** | iOS clipboard prompt declined: prompt suppressed; manual paste still works |
| **accessibility-mode (reduced motion)** | All Lotties replaced with status icons; shake replaced with red border flash |
| **high contrast** | Field uses 2dp `ink.900` border; success uses `ink.900` filled border |
| **dynamic type xxLarge** | Field height grows; QR sheet content scrolls; role card stacks vertically |

## Animations Inventory
- **Lottie files**:
  - `token_validating.json` — 1.2s loop, trigger: validation in flight
  - `token_valid_shield.json` — 1.4s one-shot, trigger: server confirms valid
  - `token_invalid_shake.json` — 0.5s one-shot, trigger: server says invalid
- **flutter_animate chains**:
  - Char entry: `.scale(begin: 0.6, end: 1.0, duration: 140ms, curve: Curves.easeOutBack)`
  - Clipboard prompt: `.slideY(begin: 1.0, curve: Curves.easeOutBack, duration: 280ms).fadeIn(180ms)`
  - Field shake: `.shake(hz: 4, offset: Offset(6, 0), duration: 360ms)`
  - Role card: `.slideY(begin: 0.06).fadeIn(220ms)`
  - Accept CTA: `.scale(begin: 0.96, end: 1.0, duration: 220ms, curve: Curves.easeOutBack)`
- **Hero transitions**: tag `auditor-shield` from validation Lottie → role card icon → auditor home header; 320ms `Curves.easeOutCubic`.
- **Custom motion**: dash auto-insert glow (200ms `easeOut`); QR overlay frame uses `AnimatedContainer` + corner ticks pulsing every 1200ms.
- **Stagger**: 30ms per typed character; 60ms between role card field rows.
- **Total motion budget**: entrance 480ms; exit 320ms.

## Haptics
- **Light**: clipboard paste; QR sheet open; ambiguous character rejection (very subtle).
- **Medium**: validation success.
- **Heavy**: validation invalid; expired token.
- **Selection**: each character entry.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `tok.headline` | "Enter your invite token" | "अपना आमंत्रण टोकन डालें" | "உங்கள் டோக்கனை உள்ளிடவும்" | "మీ టోకెన్‌ను నమోదు చేయండి" | "আপনার টোকেন দিন" | "तुमचा टोकन टाका" |
| `tok.sub` | "Auditors get a unique code from the store owner." | "मालिक से मिला यूनिक कोड।" | "உரிமையாளர் கொடுத்த குறியீடு" | "యజమాని ఇచ్చిన కోడ్" | "মালিকের দেওয়া কোড" | "मालकाकडून मिळालेला कोड" |
| `tok.placeholder` | "K9X2A4P7T1-Q3" | "K9X2A4P7T1-Q3" | "K9X2A4P7T1-Q3" | "K9X2A4P7T1-Q3" | "K9X2A4P7T1-Q3" | "K9X2A4P7T1-Q3" |
| `tok.clipboard.prompt` | "Looks like an invite token — paste it?" | "लगता है टोकन — पेस्ट करें?" | "ஒட்டலாமா?" | "అతికించాలా?" | "পেস্ট করব?" | "पेस्ट करायचे?" |
| `tok.clipboard.paste` | "Paste" | "पेस्ट" | "ஒட்டு" | "అతికించు" | "পেস্ট" | "पेस्ट" |
| `tok.clipboard.dismiss` | "Not now" | "अभी नहीं" | "இப்போது இல்லை" | "ఇప్పుడు కాదు" | "এখন না" | "आता नाही" |
| `tok.qr.cta` | "Scan QR instead" | "QR स्कैन करें" | "QR ஸ்கேன்" | "QR స్కాన్" | "QR স্ক্যান" | "QR स्कॅन" |
| `tok.qr.hint` | "Hold the QR steady" | "QR को स्थिर रखें" | "QR-ஐ நிலையாக வைக்கவும்" | "QR స్థిరంగా ఉంచండి" | "QR স্থির রাখুন" | "QR स्थिर ठेवा" |
| `tok.error.checksum` | "Check the token." | "टोकन जांचें।" | "டோக்கனை சரிபார்" | "టోకెన్ సరిచూడండి" | "টোকেন যাচাই" | "टोकन तपासा" |
| `tok.error.invalid` | "This token isn't valid or has been used." | "टोकन अमान्य या इस्तेमाल किया।" | "செல்லுபடியாகாது" | "చెల్లుబాటు కాదు" | "অবৈধ" | "अवैध" |
| `tok.error.expired` | "This invite expired on {date}. Ask for a new one." | "{date} को समाप्त हो गया।" | "{date} இல் காலாவதி" | "{date}న ముగిసింది" | "{date}-এ মেয়াদ শেষ" | "{date} ला संपला" |
| `tok.role.headline` | "You'll join {tenantName}" | "{tenantName} में शामिल" | "{tenantName} சேர்வீர்கள்" | "{tenantName} చేరుతారు" | "{tenantName}-এ যোগ" | "{tenantName} मध्ये सामील" |
| `tok.role.sub` | "{inviterName} invited you as {role} for {storeName}." | "{inviterName} ने {role} के रूप में आमंत्रित किया" | "{inviterName} {role} ஆக அழைத்தார்" | "{inviterName} మిమ్మల్ని {role}గా ఆహ్వానించారు" | "{inviterName} আপনাকে আমন্ত্রণ" | "{inviterName} ने आमंत्रित केले" |
| `tok.role.cta` | "Accept and start auditing" | "स्वीकार करें" | "ஏற்று தொடங்கு" | "ఆమోదించి ప్రారంభించు" | "গ্রহণ করুন" | "स्वीकारा व सुरू करा" |
| `tok.offline` | "You're offline. Connect to validate." | "ऑफ़लाइन।" | "ஆஃப்லைன்" | "ఆఫ్‌లైన్" | "অফলাইন" | "ऑफलाइन" |
| `tok.cooldown` | "Wait {seconds}s before retrying" | "{seconds}s रुकें" | "{seconds}s காத்திருக்கவும்" | "{seconds}s వేచి ఉండండి" | "{seconds}s অপেক্ষা" | "{seconds}s थांबा" |

## Backend Integration
- **Endpoint**: `POST /api/v1/auth/invitation/validate` (BE-06 v2)
- **Endpoint**: `POST /api/v1/auth/invitation/accept` (BE-06 v2)

### Request shape (validate)
```typescript
export interface ValidateInvitationRequest {
  token: string;                  // 13 chars including dash
}
```

### Response shape (validate)
```typescript
export interface ValidateInvitationResponse {
  valid: boolean;
  reason?: 'invalid' | 'expired' | 'used' | 'revoked';
  invite?: {
    tenantId: string;
    tenantName: string;
    storeId: string;
    storeName: string;
    role: 'auditor';
    inviterName: string;
    expiresAt: string;            // ISO
  };
}
```

### Request shape (accept)
```typescript
export interface AcceptInvitationRequest {
  token: string;
}
```

### Response shape (accept)
```typescript
export interface AcceptInvitationResponse {
  newTenantId: string;
  newStoreId: string;
  newRole: 'auditor';
  accessToken: string;
  refreshToken: string;
  expiresAt: string;
}
```

### Error code → UI mapping
| HTTP | Error | UI |
|---|---|---|
| 400 | `malformed_token` | Local checksum failure → red tint, no network call |
| 401 | `unauthorized` | Route to `/login` (preserving token in deep link) |
| 404 | `not_found` | "This token isn't valid or has been used." |
| 410 | `expired` | "This invite expired on {date}. Ask for a new one." |
| 410 | `used` | "This invite was already accepted on a different device." |
| 429 | `rate_limited` | 60s cooldown ring on field submit |
| 5xx / network | server | Toast + retry |

### Idempotency key generation
- Validate: idempotency not strictly needed (read-style), but request includes `Idempotency-Key: token-validate-{tokenHash}-{minuteBucket}` for log correlation.
- Accept: `Idempotency-Key: token-accept-{tokenHash}` — exact replay returns same `tenantId/storeId` and never creates a duplicate membership.

## Accessibility
- `TokenField`: `Semantics(textField: true, label: 'Invite token, ${value.length} of 13 characters', enabled: !validating)`.
- Clipboard prompt: `Semantics(label: 'Looks like an invite token. Paste button.')`.
- QR sheet: `Semantics(label: 'QR scanner. Hold the QR steady.')`.
- Role confirm card: `Semantics(label: 'You will join ${tenantName} as ${role} for ${storeName}, invited by ${inviterName}, expires ${date}')`.
- Focus order: field → suffix QR icon → clipboard prompt → role card → Accept CTA.
- Dynamic type tested xxLarge.
- Reduced motion: shield Lottie → ✓ icon; shake → 240ms red border flash.
- VoiceOver/TalkBack script: "Enter your invite token. K nine X two A four P seven T one dash Q three. Paste from clipboard or scan a QR code."

## Testing
- **Widget tests**:
  - Token field auto-uppercases and inserts dash
  - Ambiguous chars rejected with haptic
  - Local checksum runs at length 13
  - Clipboard prompt appears when clipboard matches regex
  - QR sheet routes scanned token through validation
- **Golden tests**: idle, partial entry, validating, valid (with role card), invalid, expired, offline, reduced motion success.
- **Integration tests**:
  - Happy path: paste → validate → accept → route to auditor home
  - QR scan path
  - 410 expired token shows correct date
  - Idempotency: tap Accept twice → single membership

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Field auto-uppercases lowercase input |
| T2 | Field inserts dash at position 10 |
| T3 | Field rejects `0`, `O`, `1`, `I`, `L` with haptic |
| T4 | Local checksum invalid produces TokenInvalid (no network) |
| T5 | Local checksum valid triggers validate POST |
| T6 | Clipboard prompt shows when clipboard matches regex |
| T7 | Clipboard prompt suppressed when iOS denies clipboard |
| T8 | QR sheet captures token and runs validation |
| T9 | Camera permission denied shows fallback hint |
| T10 | Validation success shows shield Lottie + role card |
| T11 | 410 expired shows correct date in copy |
| T12 | 410 used shows "already accepted" copy |
| T13 | Accept POST refreshes JWT with auditor role |
| T14 | Reduced motion path replaces all Lotties |
| T15 | Idempotency replay does not create duplicate membership |

### Q&A (8)
1. How does the screen handle a deep-linked invitation URL (e.g., `radha://invite?token=...`) — does it auto-validate or require user tap?
2. What is the contract for clipboard read on iOS 14+ where each read triggers a privacy banner?
3. How is the local checksum algorithm kept in sync with the server's so we never reject valid tokens?
4. What happens if a user pastes a token while logged in as a Consumer — do we offer to switch context, or block?
5. How is the QR scanner's privacy handled — do we ever store frames, even temporarily?
6. How does the screen coordinate with FE-12 if an unauthenticated user lands here from a deep link?
7. What is the rollback if Accept POST returns 5xx after we've already updated local Drift caches?
8. How does the screen handle a Pro-tier auditor invited to multiple stores — do they see one card or multiple?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green for paste/QR/expired/used.
- [ ] Reviewer: Idempotency keys; no token logged; clipboard read respects privacy banner.
- [ ] Designer (motion review): Field auto-format glow, shield Lottie, role card slide-in approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-16**
