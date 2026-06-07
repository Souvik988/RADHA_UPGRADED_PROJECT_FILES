# Phase FE-28: Expiry Tracking — Three-Tab Triage with OCR Date Capture

## Phase Metadata
- **Phase ID**: FE-28
- **Phase Name**: Expiry Tracking Screen
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion), FE-06 (API), FE-07 (Riverpod), FE-08 (Drift offline), FE-17 (camera reuse), BE-18 (expiry tracking API), BE-22 (OCR via Cloud Vision fallback)
- **Blocks**: FE-29 (GRN line items can deep-link here on expiry capture), FE-31 (tasks created from expiry rows)
- **Estimated Duration**: 4–5 days
- **Complexity**: High

## Goal
Expiry is the most expensive operational miss in retail — one batch missed costs more than a month of subscription. Expiry Tracking gives the operator a **three-tab triage**: *Expired* (action: remove), *Near-Expiry* (action: discount or move forward), *Safe* (read-only confirmation). The tab indicator color-codes the workload at a glance: red for Expired, amber for Near-Expiry, green for Safe. Each row shows product name, a **days-until-expiry pill** (red ≤ 0 / amber 1–14 / green 15+), batch number, and qty. Adding a new expiry record uses an **OCR-assisted capture flow**: photograph the date stamp → ML Kit text recognition extracts a date suggestion → the user confirms or edits in a single bottom sheet.

This screen turns expiry from a weekly aisle walk into a **daily 90-second triage**. Pilot tenants who use it daily reduce expired-stock losses by an estimated **₹4,200/store/month**.

## Why This Phase Matters
- **Expiry hygiene is an OHS component (BE-30 v2)**: each captured expiry record + each handled near-expiry alert pushes the metric up.
- **OCR is the activation hook**: typing a date is friction. Cameras-as-keyboards is the differentiator that makes daily use sticky. ML Kit is on-device and free; Cloud Vision (BE-22) is the paid fallback for hard cases.
- **Direct revenue impact**: the only screen in RADHA that has a measurable rupee value per use — every captured near-expiry record averts ~₹38 of potential loss.
- **Cross-feature**: feeds tasks (FE-31), reports (FE-32), GRN (FE-29 captures expiry on receipt).

## Prerequisites
- [ ] Backend: `GET /api/v1/expiry?storeId={uuid}&bucket={expired|near|safe}&cursor={cursor}` (BE-18)
- [ ] Backend: `POST /api/v1/expiry` body `{ productId, storeId, batchNumber, expiryDate, manufactureDate?, quantity, capturedVia: 'manual'|'ocr_local'|'ocr_cloud' }`
- [ ] Backend: `POST /api/v1/ocr/dates` (BE-22) — Cloud Vision fallback, returns `{ candidates: [{ date, confidence }] }`
- [ ] Backend: `PATCH /api/v1/expiry/{id}` for edits, `DELETE /api/v1/expiry/{id}` for removed-from-shelf
- [ ] FE-17 camera widget reused
- [ ] ML Kit text recognition v2 plugin configured
- [ ] Lottie:
  - `ocr_scan_loop.json` — 1100ms loop while OCR is processing, ≤45 KB
  - `ocr_success_check.json` — 360ms one-shot when a date is confirmed, ≤24 KB
  - `expiry_empty_safe.json` — 1800ms loop for Safe tab empty state, ≤80 KB

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/expiry/expiry_screen.dart` | Page with `TabBar` |
| `apps/mobile/lib/features/business/expiry/expiry_controller.dart` | Riverpod `AsyncNotifier<ExpiryTabState>` per tab |
| `apps/mobile/lib/features/business/expiry/expiry_state.dart` | Sealed state |
| `apps/mobile/lib/features/business/expiry/data/expiry_repository.dart` | Wraps BE-18 |
| `apps/mobile/lib/features/business/expiry/data/ocr_repository.dart` | ML Kit local + BE-22 fallback |
| `apps/mobile/lib/features/business/expiry/widgets/expiry_tab_bar.dart` | Color-coded tab indicators |
| `apps/mobile/lib/features/business/expiry/widgets/expiry_row.dart` | Single product row with days pill |
| `apps/mobile/lib/features/business/expiry/widgets/days_pill.dart` | Red/amber/green pill |
| `apps/mobile/lib/features/business/expiry/widgets/ocr_capture_sheet.dart` | OCR camera + date confirm |
| `apps/mobile/lib/features/business/expiry/widgets/date_suggestion_chip.dart` | Single OCR candidate chip |
| `apps/mobile/lib/features/business/expiry/widgets/manual_date_picker.dart` | Wheel/calendar fallback |
| `apps/mobile/lib/features/business/expiry/widgets/swipe_actions.dart` | Swipe-to-edit/delete |
| `apps/mobile/test/features/business/expiry/expiry_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/expiry/golden/expiry_states.dart` | Goldens |
| `apps/mobile/integration_test/expiry_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// expiry_state.dart
sealed class ExpiryTabState { const ExpiryTabState(); }
class ExpiryTabLoading extends ExpiryTabState { const ExpiryTabLoading(); }
class ExpiryTabReady extends ExpiryTabState {
  final List<ExpiryRow> rows;     // sorted ascending by daysUntilExpiry
  final String? nextCursor;
  final ExpiryBucket bucket;
  const ExpiryTabReady({required this.rows, required this.bucket, this.nextCursor});
}
class ExpiryTabEmpty extends ExpiryTabState { final ExpiryBucket bucket; const ExpiryTabEmpty(this.bucket); }
class ExpiryTabError extends ExpiryTabState { final ExpiryFailure f; const ExpiryTabError(this.f); }

// expiry_controller.dart
abstract interface class ExpiryController {
  Future<void> refresh(ExpiryBucket bucket);
  Future<void> loadMore(ExpiryBucket bucket);
  Future<void> capture(ExpiryDraft draft);
  Future<void> edit(String id, ExpiryDraft draft);
  Future<void> remove(String id);
}

// ocr capture
sealed class OcrCaptureState { const OcrCaptureState(); }
class OcrIdle extends OcrCaptureState { const OcrIdle(); }
class OcrProcessing extends OcrCaptureState { const OcrProcessing(); }
class OcrLocalSuggestion extends OcrCaptureState { final List<DateCandidate> candidates; const OcrLocalSuggestion(this.candidates); }
class OcrCloudFallback extends OcrCaptureState { const OcrCloudFallback(); }
class OcrFailed extends OcrCaptureState { final String reason; const OcrFailed(this.reason); }
```

### `DaysPill` widget
```dart
class DaysPill extends StatelessWidget {
  final int daysUntilExpiry;     // negative = already expired
  final bool reducedMotion;
  const DaysPill({super.key, required this.daysUntilExpiry, this.reducedMotion = false});
}
```
- Color: ≤ 0 → `tokens.semantic.urgent` (red 700), 1–14 → `tokens.semantic.warn` (amber 700), 15+ → `tokens.semantic.ok` (green 700).
- Label: `≤0` shows "Expired {abs} d ago" (capped to "Expired 99+ d"), positive shows "{n} d".
- A 6dp dot leads the label, color-matched.
- On day-rollover (cron tick / app foreground), pill cross-fades color over 240ms `easeInOut`.

### OCR sheet
- Modal bottom sheet (not full-screen) on top of the expiry tab — 70% screen height.
- Top: small camera viewfinder (240×160) with reticule rectangle suggesting "frame the date".
- Middle: row of up to 3 `DateSuggestionChip` showing parsed candidates (e.g., "12 Mar 2026", "Mar 2026", "12-03-26").
- Tap a chip to confirm; or tap "Edit manually" to open `ManualDatePicker`.
- Bottom: confirm button only enabled when a chip selected or manual date set.

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **tabs loading** | Tab bar shows count badges as skeleton; rows show shimmer |
| 2 | **Expired tab loaded** | Tab indicator red; rows sorted by days desc (most expired first); FAB green "+" |
| 3 | **Near-Expiry tab loaded** | Tab indicator amber; rows sorted by days asc (most urgent first) |
| 4 | **Safe tab loaded** | Tab indicator green; rows sorted alphabetically; subtle "All clear" message at top |
| 5 | **empty (Safe)** | Lottie `expiry_empty_safe` plays once + loops at 30% opacity; "No safe items captured yet — start with a scan" |
| 6 | **empty (Expired)** | Plain check mark + "Nothing expired today — nice work" |
| 7 | **OCR sheet idle** | Camera live; reticule pulses subtly; "Frame the date stamp" hint |
| 8 | **OCR processing (local)** | Lottie `ocr_scan_loop` plays over viewfinder; chip area shows skeleton |
| 9 | **OCR local suggestion** | Up to 3 chips visible; first chip pre-selected (highest confidence); haptic selection |
| 10 | **OCR cloud fallback** | After 1.5s of failed local OCR, sheet shows "Sending to RADHA cloud OCR…" with same Lottie; cancellable |
| 11 | **OCR failed** | "Couldn't read the date — enter manually" + manual date picker pre-opened |
| 12 | **swipe-to-edit** | Right swipe reveals blue Edit; tap opens an edit sheet |
| 13 | **swipe-to-delete** | Left swipe reveals red Remove; tap opens confirmation modal |
| 14 | **error (network)** | Banner "Couldn't load — showing cache"; pull-to-refresh disabled |
| 15 | **offline OCR** | Local ML Kit only; "Cloud OCR unavailable offline" tooltip if local fails |
| 16 | **reduced motion** | Days pill cross-fade replaced with instant color set; Lottie disabled |
| 17 | **dynamic type xxLarge** | Row layout reflows: pill below product name; batch wraps |
| 18 | **high contrast** | Pill adds 2dp pattern (diagonal for urgent) |

## Animations Inventory

Business motion budget: subtle. Per-row animations ≤ 220ms; OCR processing visible up to 1500ms (justified — bridging local→cloud).

- **Lottie**:
  - `ocr_scan_loop.json` — 1100ms loop during local OCR; restart (no flicker) when transitioning to cloud
  - `ocr_success_check.json` — 360ms one-shot on candidate confirm
  - `expiry_empty_safe.json` — 1800ms loop on Safe-tab empty state
- **flutter_animate chains**:
  - Row entrance (staggered 40ms): `.fadeIn(180ms).slideY(begin: 0.04)`
  - Days pill color crossfade on day-rollover: 240ms `easeInOut`
  - Tab indicator slide between tabs: `Curves.easeInOutCubic`, 240ms
  - OCR chip selection: `.scale(begin:1.0,end:1.04,duration:120ms).then().scale(begin:1.04,end:1.0)`
  - Swipe action reveal: `Dismissible` default with custom 200ms `easeOutCubic` curve and snap-back if not committed
- **Hero**: `Hero(tag: 'expiry-row-{id}')` from row to edit sheet header; 220ms `easeInOutCubic`
- **Custom**: pull-to-refresh uses standard Material indicator (no Lottie here — this screen prioritizes density over flourish)

## Haptics
- **selection** — tab switch, OCR candidate chip select, days-pill long-press to preview row
- **light** — row tap, edit save
- **medium** — OCR confirm (single confirmation when date locks in)
- **warning** — opening Expired tab when it has rows (signals "act now")
- **heavy** — destructive remove confirmation tap

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `exp.title` | "Expiry" | "एक्सपायरी" | "காலாவதி" | "ఎక్స్‌పైరీ" | "মেয়াদ" | "एक्स्पायरी" |
| `exp.tab.expired` | "Expired" | "एक्सपायर्ड" | "காலாவதியான" | "గడువు ముగిసింది" | "মেয়াদোত্তীর্ণ" | "एक्स्पायर्ड" |
| `exp.tab.near` | "Near-Expiry" | "जल्द एक्सपायरी" | "காலாவதி நெருங்கி" | "ఎక్స్‌పైరీ సమీపం" | "মেয়াদ-নিকট" | "लवकर एक्स्पायरी" |
| `exp.tab.safe` | "Safe" | "सुरक्षित" | "பாதுகாப்பான" | "సురక్షితం" | "নিরাপদ" | "सुरक्षित" |
| `exp.pill.days_left` | "{n} d" | "{n} दिन" | "{n} நாள்" | "{n} రోజు" | "{n} দিন" | "{n} दिवस" |
| `exp.pill.expired_ago` | "Expired {n} d ago" | "{n} दिन पहले एक्सपायर" | "{n} நாட்களுக்கு முன்" | "{n} రోజుల క్రితం" | "{n} দিন আগে" | "{n} दिवस आधी" |
| `exp.fab.capture` | "Capture date" | "तारीख कैप्चर" | "தேதி கைப்பற்று" | "తేదీ కేప్చర్" | "তারিখ ক্যাপচার" | "तारीख कॅप्चर" |
| `exp.ocr.frame_hint` | "Frame the date stamp" | "तारीख फ्रेम करें" | "தேதியை வைக்கவும்" | "తేదీని ఫ్రేమ్ చేయండి" | "তারিখ ফ্রেম করুন" | "तारीख फ्रेम करा" |
| `exp.ocr.cloud_hint` | "Trying RADHA cloud OCR…" | "क्लाउड OCR…" | "கிளவுட் OCR…" | "క్లౌడ్ OCR…" | "ক্লাউড OCR…" | "क्लाउड OCR…" |
| `exp.ocr.fail` | "Couldn't read — enter manually" | "मैन्युअल दर्ज करें" | "கைமுறையாக உள்ளிடவும்" | "మాన్యువల్‌గా" | "ম্যানুয়ালি" | "मॅन्युअली" |
| `exp.empty.safe` | "No safe items yet" | "अभी कोई सुरक्षित आइटम नहीं" | "பாதுகாப்பான பொருள்கள் இல்லை" | "సురక్షిత వస్తువులు లేవు" | "নিরাপদ আইটেম নেই" | "सुरक्षित आयटम नाहीत" |
| `exp.empty.expired` | "Nothing expired — nice work" | "कुछ भी एक्सपायर नहीं" | "எதுவும் காலாவதியில்லை" | "ఏదీ గడువు ముగియలేదు" | "কিছু মেয়াদোত্তীর্ণ নয়" | "काहीही एक्स्पायर नाही" |
| `exp.swipe.edit` | "Edit" | "संपादित करें" | "திருத்து" | "సవరించు" | "এডিট" | "एडिट" |
| `exp.swipe.remove` | "Remove" | "हटाएं" | "அகற்று" | "తీసివేయి" | "সরান" | "काढा" |
| `exp.confirm.remove` | "Remove from shelf?" | "शेल्फ़ से हटाएं?" | "அலமாரியிலிருந்து அகற்றவா?" | "షెల్ఫ్ నుండి తీసివేయాలా?" | "শেলফ থেকে সরাতে?" | "शेल्फमधून काढायचे?" |

## Backend Integration
- **Endpoints**: BE-18 expiry CRUD, BE-22 OCR fallback
- Pagination: cursor-based on `(expiryDate asc, id asc)` for Near + Safe; `(expiryDate desc, id asc)` for Expired

### OCR pipeline
1. ML Kit `TextRecognizer` runs locally on captured frame (≤ 600ms typical on Pixel 4a)
2. Local heuristic regex extracts up to 3 date candidates (e.g., `\d{2}[/.\-]\d{2}[/.\-]\d{2,4}`, `MMM YYYY`)
3. If 0 candidates after 1500ms → POST image bytes (compressed to ≤ 200 KB JPEG, sharp on the device side via `image` package) to BE-22
4. Cloud returns `candidates: [{ date, confidence }]` typically within 1.5s
5. User picks a candidate or edits manually; payload to BE-18 includes `capturedVia: 'ocr_local' | 'ocr_cloud' | 'manual'`

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | — | row inserts/updates with stagger animation |
| 400 | `invalid_date` | manual picker re-opens with field error |
| 401 | `unauthorized` | force `/login` |
| 409 | `duplicate_batch` | toast "This batch is already tracked. Open?" with deep link |
| 422 | `expiry_before_manufacture` | inline error on date picker |
| 429 | `ocr_quota_exceeded` | tooltip; manual fallback only |
| 5xx / network on POST expiry | — | enqueue in Drift outbox; row appears with cloud-off icon until synced |

## Charts & Data Viz
This screen does not render charts. The `DaysPill` is the data viz primitive:
- Color encodes severity (red/amber/green)
- Width is fixed (no quantitative encoding)
- Long-press reveals a numeric tooltip with exact expiry date and batch
- Accessibility: `Semantics(label: '{daysUntilExpiry} days until expiry, severity {severity}')` is the canonical read-out

## Accessibility
- Tab bar: tabs labeled with both name and count ("Expired, 4 items")
- Row: `Semantics(button: true, label: '{productName}, {batch}, {qty} units, expires in {n} days, severity {severity}. Swipe right to edit, left to remove.')`
- OCR: camera viewfinder labeled "Camera. Frame the date stamp on the package."
- Reduced motion: pill cross-fades replaced with instant set; row stagger removed; Lottie disabled
- Dynamic type up to xxLarge; row reflows to 2 lines; pill anchors to bottom-right
- Manual date picker exposes a 3-wheel `CupertinoDatePicker` style on iOS and a native `showDatePicker` on Android
- High contrast: pill uses pattern fill alongside color
- Voice/keyboard input: manual date picker accepts typed numeric input as well

## Testing
- **Widget tests**:
  - `DaysPill` color/label correct for −5, 0, 1, 14, 15, 99, 100
  - Tab switch animates and re-fetches
  - OCR sheet candidate selection enables confirm button
  - Swipe-to-remove fires confirmation modal once
  - Reduced motion path skips Lottie + stagger
- **Golden tests**: 8 states × 3 sizes = 24 goldens
- **Integration tests**:
  - Capture date end-to-end: photo → local OCR succeeds → confirm → row appears in Near-Expiry
  - Capture date with cloud fallback: simulate empty local result → BE-22 returns candidate → confirm → row inserted with `capturedVia: 'ocr_cloud'`
  - Offline expiry create queues in Drift outbox and syncs on reconnect

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Three tabs render with correct count badges |
| T2 | Tab indicator color matches bucket (red/amber/green) |
| T3 | Days pill shows red ≤ 0, amber 1–14, green 15+ |
| T4 | Day rollover cross-fades pill color in 240ms |
| T5 | Capture FAB opens OCR sheet with camera live |
| T6 | Local OCR returns candidates in < 800ms p95 |
| T7 | Cloud OCR fallback fires after 1500ms of empty local result |
| T8 | Manual fallback opens when both OCR paths fail |
| T9 | Confirm posts to BE-18 with correct `capturedVia` |
| T10 | Duplicate batch returns 409 and shows deep-link toast |
| T11 | Swipe-to-remove asks confirmation and POSTs delete |
| T12 | Pull-to-refresh fetches first page; loadMore paginates with cursor |
| T13 | Offline create enqueues in Drift outbox and shows cloud-off icon on row |
| T14 | TalkBack reads tab labels with counts and row labels with all fields |
| T15 | Reduced motion path skips all per-row animation |

### Q&A (8)
1. How does local ML Kit choose between multiple regex matches when both look valid (e.g., "12/03/26" could be dd/mm/yy or mm/dd/yy)?
2. What is the policy for ambiguous month-only dates ("Mar 2026") — accept end-of-month or surface a clarifier?
3. How do we ensure the Cloud Vision call doesn't leak PII (the user's face accidentally in frame)?
4. How is OCR quota (BE-22 free tier) managed per tenant — soft warn, hard cap, or queueing?
5. What is the dedupe rule when the user captures the same batch twice within 60s — silent merge or duplicate error?
6. How do we handle days-pill rollovers across timezones (server is IST; user travels)?
7. What is the perf target for ML Kit on a Pixel 3a (slowest supported device)?
8. How does this screen integrate with FE-31 to auto-create a "remove from shelf" task when an item flips to Expired?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; OCR p95 latency hit on Pixel 4a
- [ ] Reviewer: Cloud fallback path verified; outbox + sync behavior correct
- [ ] Designer (motion review): Pill cross-fade and OCR sheet transitions on hardware
- [ ] PM: OCR success rate ≥ 88% on a 200-image regression set

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-28**
