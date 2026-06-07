# Phase FE-12: OTP Login Flow

## Phase Metadata
- **Phase ID**: FE-12
- **Phase Name**: OTP Login Flow
- **Section**: Frontend Execution — Onboarding & Auth
- **Depends On**: FE-04 (motion), FE-05 (navigation), FE-06 (Dio), FE-07 (Riverpod), FE-08 (Drift), FE-09 (splash), BE-06 (OTP endpoints)
- **Blocks**: All authenticated screens (FE-13 onwards depend on a logged-in user)
- **Estimated Duration**: 2.5 days
- **Complexity**: Medium-High

## Goal
Build the OTP login flow that turns a phone number into an authenticated user. Two screens: mobile entry (with libphonenumber-style validation, country picker defaulting to India `+91`) and OTP entry (six animated digit boxes, SMS auto-fill via SmsAutoFill plugin, bounce-in success). Rate-limit handling is a first-class state with a cooldown ring that counts down without ever blocking the user from understanding what is happening.

This is the only screen in RADHA where a user types a number that determines the next 30 days of their life. The validation must be forgiving (auto-format `9876543210` → `+91 98765 43210`), the autofill must work the moment the SMS arrives (no second tap), and the success Lottie must feel like a tiny celebration without delaying the transition.

## Why This Phase Matters
- **Funnel completion gate**: 100% of authenticated user value flows through this phase. A 1% improvement in OTP success rate = ~₹40k/month at projected ARPU.
- **Drop-off risk**: India OTP funnels typically lose 8–14% of users at the OTP step due to delayed SMS or input friction. The auto-fill + paste-friendly box design targets ≤5%.
- **Rate-limit clarity**: MSG91 caps at 5 OTPs / number / hour. Users hitting that cap with a confusing error churn permanently. The cooldown ring + clear copy keeps them.
- **Trust impression**: OTP is the only moment the user shares an asset (their phone number). The flow must feel as careful as a bank's.

## Prerequisites
- [ ] Backend: `POST /api/v1/auth/otp/send` (BE-06)
- [ ] Backend: `POST /api/v1/auth/otp/verify` (BE-06)
- [ ] Backend: `GET /api/v1/auth/session` (BE-06 v2)
- [ ] Plugin: `sms_autofill` ≥2.4.0
- [ ] Plugin: `country_code_picker` or in-house equivalent
- [ ] Lottie: `otp_success.json` (1.6s, ≤80 KB)
- [ ] Lottie: `otp_error_shake.json` (0.6s, ≤30 KB)
- [ ] App-signature hash registered with MSG91 for SMS retriever API

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/auth/login/mobile_entry_screen.dart` | Phone number entry |
| `apps/mobile/lib/features/auth/login/otp_entry_screen.dart` | 6-digit OTP entry |
| `apps/mobile/lib/features/auth/login/login_controller.dart` | Riverpod `AsyncNotifier` |
| `apps/mobile/lib/features/auth/login/login_state.dart` | Sealed state |
| `apps/mobile/lib/features/auth/login/widgets/country_picker.dart` | Country chooser bottom sheet |
| `apps/mobile/lib/features/auth/login/widgets/digit_box.dart` | Single OTP digit cell |
| `apps/mobile/lib/features/auth/login/widgets/cooldown_ring.dart` | Circular progress for rate-limit |
| `apps/mobile/lib/features/auth/login/widgets/resend_button.dart` | Resend with cooldown gating |
| `apps/mobile/lib/features/auth/login/services/sms_autofill_listener.dart` | Wraps `sms_autofill` plugin |
| `apps/mobile/lib/features/auth/login/services/phone_validator.dart` | E.164 + India-specific rules |
| `apps/mobile/lib/features/auth/login/services/login_repository.dart` | Wraps Dio calls |
| `apps/mobile/test/features/auth/login/login_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/auth/login/golden/login_states.dart` | Golden tests |
| `apps/mobile/integration_test/login_flow_test.dart` | E2E test |

## Screen / Widget Spec

```dart
// login_state.dart
sealed class LoginState { const LoginState(); }
class LoginPhoneEntry extends LoginState {
  final String dialCode;          // '+91'
  final String partial;           // partial digits user has typed
  final bool isValid;             // formatted and within length
}
class LoginSendingOtp extends LoginState { final String e164; }
class LoginOtpEntry extends LoginState {
  final String e164;
  final List<int?> digits;        // 6 entries; null = empty
  final Duration resendIn;        // 0 once user can resend
  final int attemptsLeft;         // typically 3
}
class LoginVerifying extends LoginState { final String e164; final String code; }
class LoginSuccess extends LoginState { final String userId; }
class LoginError extends LoginState { final LoginFailure failure; }
class LoginCooldown extends LoginState { final Duration retryIn; final CooldownReason reason; }
```

### `DigitBox` widget
```dart
class DigitBox extends StatefulWidget {
  final int? value;               // 0..9 or null
  final bool focused;
  final bool errored;
  final bool celebrating;         // true after verify success
}
```

Animations:
- New digit accept: `.scale(begin: 0.6, end: 1.0, curve: Curves.easeOutBack, duration: 220ms)` + `.fadeIn(160ms)`.
- Focused box border: `AnimatedContainer` morphs `BorderSide` from `1dp scanGreen.300` → `2dp scanGreen.500` over 140ms.
- Error: shake `.shake(hz: 4, offset: Offset(6, 0), duration: 360ms)` + `.fadeColor(end: error.500)` for 240ms.
- Celebrating (post-verify): `.scale(begin: 1.0, end: 1.08, curve: Curves.easeOutBack)` then settle.

### `CooldownRing`
- `CustomPainter` over `CircularProgressIndicator(value: 1 - (elapsed / total))` painted with `scanGreen.500`.
- Center text "Resend in 28s" updates each second.
- Diameter 56dp; stroke 4dp.

### Animations attached
- **Mobile entry**: number text field uses `AnimatedSize` to show/hide validation hint; "Continue" button `.scale(begin: 0.96, end: 1.0)` once `isValid`.
- **OTP entry**: digit boxes appear with stagger 40ms each (0..5); SMS auto-fill triggers a synchronised "burst" — all 6 boxes scale from 0.6 → 1.0 with 30ms stagger and a single `mediumImpact`.
- **Success**: full-screen Lottie `otp_success.json` overlays for 900ms then fades out as next route pushes.

### Haptic feedback events
- `HapticFeedback.selectionClick()` on each digit typed.
- `HapticFeedback.lightImpact()` on country picker selection.
- `HapticFeedback.mediumImpact()` on auto-fill burst.
- `HapticFeedback.heavyImpact()` on OTP error (3-time vibration pattern).
- `HapticFeedback.lightImpact()` on success Lottie start.

### Motion choreography (mobile entry)
| t (ms) | Event |
|---|---|
| 0 | Page mounts; header + headline `.fadeIn(180ms).slideY(begin: -0.04)` |
| 220 | Country picker chip + text field fade in |
| user-types | Digits appear; validation hint animates open if invalid |
| valid | Continue button scales in |
| user-tap | Send OTP request fires; button shows inline `CircularProgressIndicator(20dp)` |
| ack | Hero transition to OTP screen using `phone-pill` tag |

### Motion choreography (OTP entry)
| t (ms) | Event |
|---|---|
| 0 | Hero `phone-pill` lands at top |
| 0–240 | Digit boxes stagger in (40ms each) |
| 240+ | Cursor blink in box 0; auto-fill listener armed |
| sms-arrive | Burst animation; all 6 boxes fill |
| verify-ack | Success Lottie overlays |
| ~900 | Route push to next screen |

## Visual Behaviour & Interaction States

| State | Visual |
|---|---|
| **initial** | Mobile entry blank; country flag = India `+91` |
| **loading (sending OTP)** | Continue button shows spinner; field disabled |
| **loaded (OTP entry)** | 6 digit boxes; resend countdown running |
| **empty** | OTP entry with all boxes empty; cursor in box 0 |
| **error (network — send)** | Toast "Couldn't send OTP. Check your connection."; Continue button re-enabled |
| **error (validation — phone)** | Inline hint under field "Enter a valid 10-digit Indian mobile" with subtle slide-in |
| **error (validation — OTP)** | All 6 boxes shake + red border + Lottie shake; copy "Wrong code. Try again." (`attemptsLeft` decremented) |
| **error (3 wrong attempts)** | Boxes locked; modal "Too many wrong attempts. Resend a new code." with single CTA |
| **success** | Success Lottie + light haptic + route push |
| **offline** | Send OTP gated with banner "You're offline. Connect to receive an OTP." (no spurious requests) |
| **rate-limited / cooldown** | Send disabled; cooldown ring with Retry-After countdown; copy "Too many tries. Wait {seconds}s." |
| **permission-denied (SMS)** | Auto-fill silently disabled; manual entry still works; subtle copy "Type the code from SMS" |
| **permission-denied (notification)** | Irrelevant to login; ignored |
| **accessibility-mode (reduced motion)** | Digit boxes use `crossFade(120ms)` instead of scale-bounce; success Lottie replaced with checkmark icon + AnnounceForAccessibility |
| **high contrast** | Boxes use 2dp `ink.900` border; focused border uses `scanGreen.700` |
| **dynamic type xxLarge** | Digit boxes grow from 48dp → 64dp; layout reflows to two rows of 3 if width insufficient |

## Animations Inventory
- **Lottie files**:
  - `otp_success.json` — 1.6s one-shot, trigger: verify success
  - `otp_error_shake.json` — 0.6s one-shot, trigger: verify failure
- **flutter_animate chains**:
  - Headline: `.fadeIn(180ms).slideY(begin: -0.04)`
  - Continue button: `.scale(begin: 0.96, end: 1.0, curve: Curves.easeOutBack, duration: 200ms)` when valid
  - Digit boxes entrance: `.fadeIn(160ms).slideY(begin: 0.05)` with 40ms stagger
  - Auto-fill burst: `.scale(begin: 0.6, end: 1.0, curve: Curves.easeOutBack)` with 30ms stagger
  - Validation hint: `.slideY(begin: -0.2).fadeIn(160ms)`
- **Hero transitions**: tag `phone-pill` from mobile entry pill to OTP top header; 320ms `Curves.easeOutCubic`.
- **Custom motion**: cooldown ring uses `CustomPainter` with `arc` sweep updated each `Ticker` tick; resend button enables with `.scale(begin: 0.94)` once countdown hits 0.
- **Stagger**: 40ms entrance, 30ms auto-fill burst.
- **Total motion budget**: entrance 480ms (within 600ms); exit 320ms (Hero, within 200ms+Hero tolerance).

## Haptics
- **Light**: country selection; success start; resend tap.
- **Medium**: auto-fill burst (signals "we caught your code").
- **Heavy**: wrong-code error (3-pulse).
- **Selection**: each digit typed.

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `login.phone.headline` | "What's your number?" | "आपका नंबर क्या है?" | "உங்கள் எண் என்ன?" | "మీ నంబర్ ఏమిటి?" | "আপনার নম্বর?" | "तुमचा नंबर?" |
| `login.phone.subtitle` | "We'll text you a code" | "हम कोड भेजेंगे" | "உங்களுக்கு குறியீடு" | "మీకు కోడ్ పంపుతాం" | "আমরা কোড পাঠাব" | "आम्ही कोड पाठवू" |
| `login.phone.placeholder` | "98765 43210" | "98765 43210" | "98765 43210" | "98765 43210" | "98765 43210" | "98765 43210" |
| `login.phone.invalid` | "Enter a valid 10-digit number" | "10 अंकों का सही नंबर डालें" | "சரியான எண் உள்ளிடவும்" | "సరైన నంబర్‌ను ఇవ్వండి" | "সঠিক ১০ ডিজিটের নম্বর" | "10 अंकी नंबर द्या" |
| `login.phone.cta` | "Continue" | "जारी रखें" | "தொடரு" | "కొనసాగించండి" | "চালিয়ে যান" | "सुरू ठेवा" |
| `login.otp.headline` | "Enter the code" | "कोड डालें" | "குறியீடு உள்ளிடு" | "కోడ్ ఎంటర్ చేయండి" | "কোড দিন" | "कोड टाका" |
| `login.otp.subtitle` | "We sent it to {phone}" | "हमने भेजा {phone} पर" | "{phone} க்கு அனுப்பப்பட்டது" | "{phone} కి పంపాం" | "{phone}-এ পাঠানো হয়েছে" | "{phone}वर पाठवले" |
| `login.otp.resend_in` | "Resend in {seconds}s" | "{seconds}s में पुनः भेजें" | "{seconds}s இல் மீண்டும்" | "{seconds}s తరువాత" | "{seconds}s পর পুনরায়" | "{seconds}s नंतर पुन्हा" |
| `login.otp.resend` | "Resend code" | "कोड पुनः भेजें" | "மீண்டும் அனுப்பு" | "మళ్ళీ పంపండి" | "পুনরায় কোড" | "पुन्हा कोड" |
| `login.otp.error.wrong` | "Wrong code. Try again." | "गलत कोड। फिर प्रयास करें।" | "தவறான குறியீடு" | "తప్పు కోడ్." | "ভুল কোড।" | "चुकीचा कोड." |
| `login.otp.error.locked` | "Too many wrong attempts." | "बहुत सारी गलत कोशिशें।" | "அதிக தவறான முயற்சிகள்." | "ఎక్కువ తప్పు ప్రయత్నాలు." | "অনেক ভুল চেষ্টা।" | "खूप चुकीचे प्रयत्न." |
| `login.cooldown` | "Wait {seconds}s before retrying" | "{seconds}s रुकें" | "{seconds}s காத்திருக்கவும்" | "{seconds}s వేచి ఉండండి" | "{seconds}s অপেক্ষা" | "{seconds}s थांबा" |
| `login.offline` | "You're offline. Connect to receive an OTP." | "ऑफ़लाइन। OTP के लिए कनेक्ट करें।" | "ஆஃப்லைன். OTP-க்காக இணைக்கவும்." | "ఆఫ్‌లైన్. OTP కోసం కనెక్ట్ చేయండి." | "অফলাইন। OTP-এর জন্য সংযোগ করুন।" | "ऑफलाइन. OTP साठी कनेक्ट करा." |

## Backend Integration
- **Endpoint**: `POST /api/v1/auth/otp/send` (BE-06)
- **Endpoint**: `POST /api/v1/auth/otp/verify` (BE-06)

### Request shape (send)
```typescript
export interface OtpSendRequest {
  e164: string;                   // '+919876543210'
  appHash?: string;               // SMS retriever app signature (Android)
  locale: 'en' | 'hi' | 'ta' | 'te' | 'bn' | 'mr';
}
```

### Response shape (send)
```typescript
export interface OtpSendResponse {
  requestId: string;              // for verify
  cooldownMs: number;             // ms until resend allowed
  attemptsAllowed: number;        // typically 3
  expiresInMs: number;            // OTP validity, e.g., 600000
}
```

### Request shape (verify)
```typescript
export interface OtpVerifyRequest {
  requestId: string;
  code: string;                   // '123456'
}
```

### Response shape (verify)
```typescript
export interface OtpVerifyResponse {
  accessToken: string;
  refreshToken: string;
  expiresAt: string;              // ISO
  session: SessionDto;            // see FE-09
  bypassedOnboarding: boolean;
}
```

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 400 | `invalid_phone` | Inline "Enter a valid 10-digit number" |
| 400 | `invalid_code` | Box shake + counter decrement |
| 401 | `request_expired` | Modal "Code expired. Resend?" |
| 409 | `pending_invitation` | Route to FE-16 auditor token entry |
| 429 | `rate_limited` (per number) | Cooldown ring with `Retry-After` |
| 429 | `rate_limited` (per ip) | Cooldown ring; copy "Many tries from this network" |
| 5xx / network | server | Toast + retry; never silently consume an attempt |

### Idempotency key generation
- Send: `Idempotency-Key: otp-send-{e164}-{minuteBucket}` (60s window).
- Verify: `Idempotency-Key: otp-verify-{requestId}-{code}` — exact replay returns same response and does not consume an attempt.

## Accessibility
- Phone field: `Semantics(textField: true, label: 'Mobile number, with country code ${dialCode}')`.
- OTP boxes: each `Semantics(label: 'Digit ${index+1} of 6, ${value ?? "empty"}')`.
- Resend button: `Semantics(button: true, label: countdown > 0 ? 'Resend available in $countdown seconds' : 'Resend code')`.
- Focus order: phone field → country picker → continue; on OTP screen: box 0 → 1 → ... → 5 → resend.
- Dynamic type tested xxLarge; boxes resize to 64dp.
- Reduced motion: cross-fade everywhere.
- VoiceOver/TalkBack script: "Enter the 6-digit code we sent to nine eight seven six five four three two one zero. Resend available in 28 seconds."

## Testing
- **Widget tests**:
  - `phone_validator` accepts `9876543210`, `+91 98765 43210`; rejects `1234`, `0987654321`
  - Country picker default = India
  - SMS auto-fill burst fills boxes once on receive
  - Wrong code shake decrements `attemptsLeft`
  - Resend disabled until cooldown reaches 0
- **Golden tests**: phone entry empty, phone entry valid, OTP entry empty, OTP entry filled, OTP error, cooldown, offline.
- **Integration tests**:
  - Happy path: phone → OTP → success → next route
  - Cooldown path: 6 sends in a minute → cooldown
  - Wrong code 3× → lock modal

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | `phone_validator` accepts E.164 and 10-digit Indian formats |
| T2 | Country picker default = India `+91` |
| T3 | Sending OTP returns `requestId` and starts resend cooldown |
| T4 | Auto-fill burst fills 6 boxes once and only once |
| T5 | Wrong code triggers shake + Lottie + counter decrement |
| T6 | 3 wrong attempts shows lock modal |
| T7 | Resend re-arms after cooldown reaches 0 |
| T8 | Rate-limit 429 shows cooldown ring with Retry-After |
| T9 | Offline shows banner and disables Continue |
| T10 | Pending invitation 409 routes to auditor token entry |
| T11 | Hero `phone-pill` transitions cleanly between screens |
| T12 | Success Lottie completes before route push (no jank) |
| T13 | Reduced motion path replaces all animations with cross-fade |
| T14 | TalkBack reads each box label correctly |
| T15 | Replay of verify with same `Idempotency-Key` does not consume an attempt |

### Q&A (8)
1. How do we keep OTP attempts in sync between client UI and server when the network drops mid-verify?
2. What happens if the user receives the SMS but switches apps before auto-fill — does manual entry still work?
3. How do we handle dual-SIM Android where the SMS arrives on the non-default SIM?
4. What is the policy when a user pastes the OTP from an old SMS — do we accept and let the server reject, or strip non-current codes?
5. How do we coordinate with FE-16 auditor token entry when an unauthenticated user clicks an audit invite link?
6. How is `appHash` registered with MSG91 and rolled across app versions?
7. What is the exact UX when MSG91 itself is degraded — do we fallback to call-based OTP?
8. How does this flow integrate with FE-50 force-update if the user is on a too-old client version?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; integration green; auto-fill verified on real device.
- [ ] Reviewer: Idempotency keys correctly scoped; rate-limit cooldown semantics verified; PII never logged.
- [ ] Designer (motion review): Digit box bounce, auto-fill burst, success Lottie approved on hardware.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-12**
