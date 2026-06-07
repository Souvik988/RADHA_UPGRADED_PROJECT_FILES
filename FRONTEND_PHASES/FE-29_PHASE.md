# Phase FE-29: GRN (Goods Receipt Note) Entry — 4-Step Wizard

## Phase Metadata
- **Phase ID**: FE-29
- **Phase Name**: GRN Entry Flow
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion), FE-05 (routing), FE-06 (API), FE-07 (Riverpod), FE-08 (Drift offline), FE-17 (camera), FE-28 (OCR widget reused for expiry capture per line item), BE-25 (suppliers), BE-26 (GRN posting), BE-26 v2 (vendor quality metric extraction)
- **Blocks**: FE-30 (inventory updates from GRN posting)
- **Estimated Duration**: 5–6 days
- **Complexity**: High

## Goal
GRN is the gateway for stock arriving at the store. The wizard is **four steps in one direction** with a clear back-arrow at every step:
1. **Supplier picker** — typeahead with recent-suppliers chips for one-tap selection.
2. **Add line items** — scan EAN or type, capture batch, expiry (reuses FE-28 OCR), quantity. Per-row swipe-to-edit and swipe-to-delete.
3. **Review summary** — totals, expiry warnings, supplier short-shelf-life flag.
4. **Post** — atomic POST to BE-26. Optimistic UI; if backend rejects, the entire GRN bounces back with a **rollback shake animation** (8dp left/right, 320ms total) and the failing line item highlighted.

The wizard targets **2 minutes per GRN** for an 8-line invoice (versus 9 minutes on paper). Vendor-quality metrics extracted automatically (BE-26 v2) feed into the OHS vendor-quality component (BE-30 v2). Every GRN posted is a regulatory audit trail entry.

## Why This Phase Matters
- **Vendor quality is an OHS component**: the only feature that captures supplier shelf-life and on-time data systematically. Without GRN posting, the vendor-quality OHS component is permanently 0 and the badge is unreachable.
- **Stock-IN gateway**: every inventory item enters the system through GRN (or manual stock-in via FE-30). Mistakes here corrupt inventory accuracy — another OHS component.
- **Time savings**: ~7 minutes/store/day on a typical 3-GRN-per-day store, ₹100/day in staff time.
- **Compliance**: regulators ask for inward records; this is the digital trail.

## Prerequisites
- [ ] Backend: `GET /api/v1/suppliers?q={query}&recent=true` (BE-25)
- [ ] Backend: `POST /api/v1/grn` body draft create (BE-26)
- [ ] Backend: `PATCH /api/v1/grn/{id}/items` body line items
- [ ] Backend: `POST /api/v1/grn/{id}/post` atomic posting (returns InventoryUpdate[] + ExpiryRecord[])
- [ ] Backend: `POST /api/v1/grn/{id}/cancel` (used by rollback flow if posting started client-side and user aborts before ACK)
- [ ] FE-17 camera, FE-28 OCR sheet reused
- [ ] Lottie:
  - `grn_post_success.json` — 1200ms one-shot, ≤90 KB
  - `grn_post_rollback.json` — 600ms one-shot, ≤40 KB; plays on backend rejection
  - `supplier_chip_pulse.json` — 220ms one-shot on recent-supplier chip select, ≤14 KB

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/grn/grn_wizard_screen.dart` | `Stepper`-style host page |
| `apps/mobile/lib/features/business/grn/grn_controller.dart` | Riverpod `Notifier<GrnDraftState>` |
| `apps/mobile/lib/features/business/grn/grn_state.dart` | Sealed state + step enum |
| `apps/mobile/lib/features/business/grn/data/grn_repository.dart` | Wraps BE-26 |
| `apps/mobile/lib/features/business/grn/data/supplier_repository.dart` | Wraps BE-25 |
| `apps/mobile/lib/features/business/grn/steps/step1_supplier.dart` | Supplier picker step |
| `apps/mobile/lib/features/business/grn/steps/step2_items.dart` | Line items step |
| `apps/mobile/lib/features/business/grn/steps/step3_review.dart` | Review summary step |
| `apps/mobile/lib/features/business/grn/steps/step4_post.dart` | Post + result step |
| `apps/mobile/lib/features/business/grn/widgets/supplier_typeahead.dart` | Async typeahead |
| `apps/mobile/lib/features/business/grn/widgets/recent_supplier_chip.dart` | Single chip |
| `apps/mobile/lib/features/business/grn/widgets/line_item_row.dart` | Swipeable row |
| `apps/mobile/lib/features/business/grn/widgets/line_item_editor_sheet.dart` | Edit sheet |
| `apps/mobile/lib/features/business/grn/widgets/short_shelf_life_chip.dart` | Inline warning |
| `apps/mobile/lib/features/business/grn/widgets/post_button.dart` | Animated CTA |
| `apps/mobile/lib/features/business/grn/widgets/rollback_shake.dart` | Shake-on-reject wrapper |
| `apps/mobile/test/features/business/grn/grn_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/grn/golden/grn_states.dart` | Goldens |
| `apps/mobile/integration_test/grn_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// grn_state.dart
enum GrnStep { supplier, items, review, posting, done }

sealed class GrnDraftState { const GrnDraftState(); }
class GrnDraft extends GrnDraftState {
  final GrnStep step;
  final Supplier? supplier;
  final List<GrnLineDraft> lines;
  final String? draftId;        // server draft id once step1 confirmed
  final GrnValidation validation;
  final bool offlineQueued;
  const GrnDraft({...});
}
class GrnPosting extends GrnDraftState { const GrnPosting(); }
class GrnPosted extends GrnDraftState { final GrnPostResult result; const GrnPosted(this.result); }
class GrnRejected extends GrnDraftState {
  final GrnDraft snapshot;
  final List<GrnLineError> errors;     // pinpoints offending lines
  const GrnRejected(this.snapshot, this.errors);
}

// grn_controller.dart
abstract interface class GrnController {
  Future<void> chooseSupplier(Supplier supplier);
  Future<void> addLine(GrnLineDraft line);
  Future<void> updateLine(int index, GrnLineDraft line);
  Future<void> removeLine(int index);
  void nextStep();
  void previousStep();
  Future<void> post();           // atomic
  Future<void> retry();
}
```

### `LineItemRow` widget
```dart
class LineItemRow extends StatelessWidget {
  final GrnLineDraft line;
  final int index;
  final bool isHighlighted;       // true when this row caused the rejection
  final VoidCallback onEdit;
  final VoidCallback onDelete;
}
```
- Row layout: product name (1 line, `TextOverflow.ellipsis`), batch + qty (small caption), expiry pill on the right.
- Swipe right → blue Edit; swipe left → red Delete; both with `Dismissible` + custom `confirmDismiss`.
- If `isHighlighted`, container wraps in a 2dp red border and triggers `RollbackShake` once on enter.

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **step1 idle** | Search field focused; recent suppliers chips visible (up to 6); empty state has illustration |
| 2 | **step1 typeahead loading** | Skeleton rows in dropdown |
| 3 | **step1 supplier selected** | Chip pulses (220ms); next button enables; recent chips fade out (180ms) |
| 4 | **step2 empty** | "Scan or add items" empty state with single FAB to open scanner; manual-add link below |
| 5 | **step2 with items** | List of rows; FAB always visible bottom-right; total qty + lines count in app bar |
| 6 | **step2 short-shelf-life warning** | Per-row inline chip "Short shelf life — {n} d"; tap shows tooltip; non-blocking |
| 7 | **step2 swipe-to-edit** | Edit sheet slides up (260ms `easeOutCubic`); fields pre-filled |
| 8 | **step2 swipe-to-delete** | Delete confirmation modal; haptic warning |
| 9 | **step3 review** | Read-only summary with totals, supplier name, invoice number, "Edit" links per section |
| 10 | **step3 short-shelf-life summary** | If any line < 30 days, banner top: "{n} items have short shelf life — proceed?" |
| 11 | **step4 posting** | Big "Posting…" with subtle indeterminate progress (240ms cycle); back button disabled |
| 12 | **step4 success** | Lottie `grn_post_success` plays once (1200ms); summary card shows posted line count + GRN number; CTA "Open inventory" routes to FE-30 |
| 13 | **step4 rejection** | Lottie `grn_post_rollback` plays once (600ms); wizard auto-navigates back to step2 with offending line(s) highlighted; rollback shake animation runs |
| 14 | **offline post** | Banner "You're offline — GRN will post when online"; success-style success sheet but with cloud-off icon and outbox indicator |
| 15 | **error (auth 401)** | Hard route to `/login` |
| 16 | **error (supplier inactive)** | Inline error in step1 with "Choose another supplier" CTA |
| 17 | **reduced motion** | All step transitions are instant cross-fades; rollback shake replaced with single 1dp red border flash |
| 18 | **dynamic type xxLarge** | Step indicator collapses to a chip; supplier chip wraps |

## Animations Inventory

Business motion budget: stays subtle except on success/rejection, where the screen *must* communicate the outcome unambiguously.

- **Lottie**:
  - `supplier_chip_pulse.json` — 220ms on recent-supplier chip select
  - `grn_post_success.json` — 1200ms one-shot on success step (justified: this is the "you saved 7 min" moment)
  - `grn_post_rollback.json` — 600ms one-shot on rejection
- **flutter_animate chains**:
  - Step transitions: `.fadeIn(220ms).slideX(begin: 0.06, curve: Curves.easeOutCubic)` forward, `slideX(begin: -0.06)` backward
  - Line item enter: stagger 40ms, `.fadeIn(180ms).slideY(begin: 0.04)`
  - Line item delete: `.slideX(end: 1.0, duration: 200ms, curve: Curves.easeInCubic).fadeOut(160ms)`
  - Recent chip fade-out on selection: `.fadeOut(180ms)`
  - Post button: pressed scale 0.97 over 90ms, returns to 1.0
- **Hero**: `Hero(tag: 'grn-supplier-{id}')` from step1 chip to step3 supplier label (220ms `easeInOutCubic`)
- **Custom — RollbackShake**: `Tween<double>(begin: 0, end: 1)` driving an `Animation` that translates X by `sin(t * pi * 4) * 8dp` over 320ms with `Curves.easeOut` envelope. Triggers once on rejection state.

## Haptics
- **selection** — recent supplier chip tap, step navigation
- **light** — line item row tap, edit save, post button press
- **medium** — successful post (single confirmation), step transition forward
- **warning** — short-shelf-life summary banner appears
- **heavy** — rollback shake (rejection)

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `grn.title` | "New GRN" | "नया GRN" | "புதிய GRN" | "కొత్త GRN" | "নতুন GRN" | "नवीन GRN" |
| `grn.step1.title` | "Supplier" | "विक्रेता" | "விற்பனையாளர்" | "విక్రేత" | "সরবরাহকারী" | "विक्रेता" |
| `grn.step1.search` | "Search supplier" | "विक्रेता खोजें" | "விற்பனையாளர் தேடு" | "విక్రేత వెతకండి" | "সরবরাহকারী খুঁজুন" | "विक्रेता शोधा" |
| `grn.step1.recent` | "Recent" | "हाल ही में" | "சமீபத்திய" | "ఇటీవలి" | "সাম্প্রতিক" | "अलीकडील" |
| `grn.step2.title` | "Items" | "आइटम" | "பொருட்கள்" | "వస్తువులు" | "আইটেম" | "वस्तू" |
| `grn.step2.add` | "Scan or add" | "स्कैन या जोड़ें" | "ஸ்கேன் அல்லது சேர்" | "స్కాన్ లేదా జోడించండి" | "স্ক্যান বা যোগ করুন" | "स्कॅन किंवा जोडा" |
| `grn.step2.empty` | "No items yet — scan to start" | "आइटम जोड़ें" | "பொருட்களைச் சேர்" | "వస్తువులను జోడించండి" | "আইটেম যোগ করুন" | "वस्तू जोडा" |
| `grn.step2.short_shelf` | "Short shelf life — {n} d" | "कम शेल्फ़ — {n} दिन" | "குறுகிய ஆயுள் — {n}" | "తక్కువ షెల్ఫ్ — {n}" | "অল্প শেলফ — {n}" | "अल्प शेल्फ — {n}" |
| `grn.step3.title` | "Review" | "समीक्षा" | "மதிப்பீடு" | "సమీక్ష" | "পর্যালোচনা" | "पुनरावलोकन" |
| `grn.step3.warning` | "{n} items short-shelf-life — proceed?" | "{n} आइटम कम शेल्फ़" | "{n} பொருட்கள்" | "{n} వస్తువులు" | "{n} আইটেম" | "{n} वस्तू" |
| `grn.step4.posting` | "Posting…" | "पोस्ट हो रहा…" | "பதிவிடுதல்…" | "పోస్ట్ అవుతోంది…" | "পোস্ট করা হচ্ছে…" | "पोस्ट होत आहे…" |
| `grn.step4.success` | "GRN {grnNumber} posted" | "GRN {grnNumber} पोस्ट" | "GRN {grnNumber} பதிவு" | "GRN {grnNumber} పోస్ట్" | "GRN {grnNumber} পোস্ট" | "GRN {grnNumber} पोस्ट" |
| `grn.step4.rollback` | "Couldn't post — fix highlighted items" | "हाइलाइट की गई वस्तुएं ठीक करें" | "சரிசெய்யவும்" | "సరిచేయండి" | "ঠিক করুন" | "दुरुस्त करा" |
| `grn.offline.queued` | "Will post when online" | "ऑनलाइन होने पर पोस्ट" | "ஆன்லைனில் பதிவு" | "ఆన్‌లైన్‌లో పోస్ట్" | "অনলাইনে পোস্ট" | "ऑनलाइन झाल्यावर" |
| `grn.action.open_inventory` | "Open inventory" | "इन्वेंटरी खोलें" | "சரக்கைத் திற" | "ఇన్వెంటరీ తెరవండి" | "ইনভেন্টরি খুলুন" | "इन्व्हेंटरी उघडा" |

## Backend Integration
- **POST /api/v1/grn** body `{ supplierId, storeId, invoiceNumber, invoiceDate, inwardDate }` → `{ id, grnNumber, status: 'draft' }`
- **PATCH /api/v1/grn/{id}/items** body `{ items: GrnLineDraft[] }`
- **POST /api/v1/grn/{id}/post** atomic. Response on success `{ grn, inventoryUpdates, expiryRecordsCreated, alertsGenerated }`. On failure: `{ errors: [{ itemId, code, message }] }` with HTTP 422.

### Idempotency
- `Idempotency-Key: grn-post-{draftId}` so a retry never double-posts inventory.

### Vendor quality (BE-26 v2)
- Server extracts metrics from the post (delivery days, short-shelf-life count). UI does not need to do anything beyond posting; the next dashboard fetch reflects the updated vendor-quality OHS component.

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | — | success step |
| 400 | `validation_error` | rollback shake; bounce to offending step (step2 if line-item, step1 if supplier) |
| 401 | `unauthorized` | force `/login` |
| 403 | `not_in_role` | toast; back to FE-25 |
| 404 | `supplier_not_found` | step1 reopens with banner |
| 409 | `duplicate_invoice` | banner with "Open existing GRN" deep link |
| 422 | `expiry_before_manufacture` / `insufficient_data` | rollback to step2; offending line highlighted |
| 429 | `rate_limited` | tooltip; disable post 30s |
| 5xx / network | — | offline outbox path; success-style sheet with cloud-off icon |

## Charts & Data Viz
Step3 review uses a small **summary stat strip** (no chart): total qty, total lines, soonest expiry, total amount.
- Soonest expiry uses the same `DaysPill` from FE-28
- For tenants who care about amounts, totals are shown right-aligned with thousands separator
- Accessibility: `Semantics(label: 'Total {totalQty} units across {lines} lines, soonest expiry in {n} days')`

## Accessibility
- Stepper exposes `Semantics(header: true, label: 'Step {n} of 4: {title}')`
- Step1 typeahead: live region announces "{n} suppliers match"
- Line item row labels mirror FE-28
- Reduced motion: step transitions instant; rollback shake replaced with single 1dp red border flash; Lottie disabled
- Dynamic type xxLarge: stepper indicator becomes a chip; recent chips wrap to 3 columns
- Focus order: app bar back → step content → step actions → bottom nav
- Voice input on numeric quantity fields

## Testing
- **Widget tests**:
  - 4 steps render correctly and forward/back navigation works
  - Recent supplier chips show after first GRN with that supplier
  - Line item swipe-edit preserves field values
  - Rollback shake plays once on rejection state
  - Reduced motion disables all animations
- **Golden tests**: 8 states × 3 sizes = 24 goldens
- **Integration tests**:
  - Happy path: supplier → 3 lines → review → post → success → inventory deep link
  - Rejection path: post returns 422 with offending item; wizard returns to step2 with highlight
  - Offline post: queues in outbox; reconnect drains; success sheet appears

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Step1 typeahead returns suppliers in < 400ms p95 |
| T2 | Recent suppliers chips show after first selection |
| T3 | Step2 scan adds line with batch+expiry from FE-28 OCR sheet |
| T4 | Manual line entry validates qty > 0 and expiry > manufacture |
| T5 | Swipe-to-edit opens sheet with fields pre-filled |
| T6 | Swipe-to-delete confirms and removes line with slide-out animation |
| T7 | Step3 shows short-shelf-life banner when any line < 30 days |
| T8 | Step4 successful post shows Lottie + GRN number + inventory CTA |
| T9 | Step4 rejection runs rollback shake and lands on step2 with highlight |
| T10 | Idempotency-Key replay returns same post result |
| T11 | Offline post enqueues in Drift outbox and shows cloud-off icon |
| T12 | 409 duplicate invoice surfaces "Open existing GRN" deep link |
| T13 | Reduced motion: shake replaced with border flash; Lottie disabled |
| T14 | TalkBack reads step header and current step content in order |
| T15 | Vendor-quality metric updates within one dashboard fetch after post |

### Q&A (8)
1. How do we keep the wizard's draft alive across cold-restarts (e.g., user closes the app at step2)?
2. What is the policy for partial posts — never (atomic) or per-line — and why?
3. How does the rollback shake animation interact with users who have reduced motion enabled?
4. How do we surface vendor short-shelf-life patterns over time without making this screen busy?
5. What is the offline outbox cap for GRN posts before we surface a hard "go online" warning?
6. How does step1 typeahead avoid burning bandwidth on every keystroke (debounce strategy)?
7. How do we handle a supplier who is `inactive` server-side but appears in recent chips?
8. What is the analytics taxonomy for "GRN posted" so the Owner Dashboard can compute supplier funnel metrics?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; happy-path latency < 1.5s post-to-success
- [ ] Reviewer: Idempotency verified end-to-end; rollback path on hardware
- [ ] Designer (motion review): Step transitions, success Lottie, rollback shake on hardware
- [ ] PM: Microcopy reviewed in all 6 languages

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-29**
