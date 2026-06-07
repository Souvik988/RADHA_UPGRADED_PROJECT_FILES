# Phase FE-30: Inventory Stock In/Out + Counts + Low-Stock Rules

## Phase Metadata
- **Phase ID**: FE-30
- **Phase Name**: Inventory Stock In/Out + Counts
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-04 (motion tokens), FE-06 (API client), FE-07 (Riverpod auth + roles), FE-08 (Drift offline outbox), FE-17 (camera + ML Kit barcode widget reused for product picking), FE-29 (GRN posting feeds inventory `on_hand`), BE-27 (`POST /api/v1/inventory/stock-in`, `POST /api/v1/inventory/stock-out`, `GET /api/v1/inventory`, `GET /api/v1/inventory/low-stock`, `PUT /api/v1/inventory/low-stock-rules`), BE-30 v2 (Inventory Accuracy is one of the six OHS components)
- **Blocks**: FE-31 (tasks like "Recount aisle 3" reference inventory items and quantities), FE-32 (reports include stock-on-hand and movement totals), FE-39 (perf budget on the inventory list — must scroll 1000 SKUs at 60fps)
- **Estimated Duration**: 4–5 days
- **Complexity**: High

## Goal
Inventory is the spine of the business app. Every other Layer 4 surface — GRN posting (FE-29), expiry tracker (FE-28), tasks (FE-31), reports (FE-32) — either writes to or reads from this single source of truth. FE-30 ships a **two-tab Stock In / Stock Out screen**, a **counts list** with inline low-stock badges, and a **low-stock rules editor** sheet. All three share one Riverpod `Notifier<StockMovementDraftState>` so a partially-filled stock-in form survives a tab switch and a cold restart.

The bar is clear: a manager closes the day in 90 seconds — open inventory, reconcile two manual counts, push a stock-out for damaged stock, and walk out. Stock movements post optimistically and roll back with a clean diff if the backend rejects. Every accepted movement increments the **Inventory Accuracy** OHS component (BE-30 v2); every rollback decrements it.

## Why This Phase Matters
- **Inventory Accuracy is an OHS component**: BE-30 v2 publishes a six-leg health score, and one of those legs is "stock movements posted vs. stock movements rolled back." A store that lets staff fat-finger quantities sees the OHS badge degrade in 24 hours. The UI is the only place we can prevent the fat-finger.
- **Daily-use loop**: GRN posts in (FE-29), expiry pulls forward (FE-28), and inventory is what the manager looks at to decide what to reorder. If this screen is slow or noisy, the day stops.
- **Time savings**: pen-and-paper stock counts on a 600-SKU shop floor take ~45 minutes. With the bulk-count list and scanner-fed pickers, that drops to ~15. ₹150/day in staff time for a single store.
- **Compliance + audit trail**: every state-changing write here lands an audit log entry on the server tied to the local user. The UI never trusts client-side role assertions to gate actions — every mutation is gated by a fresh role probe at submit time (BE-08).
- **Permissions awareness**: the scanner used by the product picker must re-check camera permission on every entry into scan mode (not just on first launch). A user who revoked the permission in system settings between sessions sees the FE-17 permission rationale sheet again, not a black camera surface.

## Prerequisites
- [ ] Backend: `POST /api/v1/inventory/stock-in` body `{ ean, quantity, reason, batchNumber?, expiryDate? }` → `{ movementId, onHand, atRevision }` (BE-27)
- [ ] Backend: `POST /api/v1/inventory/stock-out` body `{ ean, quantity, reason: 'sold' | 'damaged' | 'expired' | 'recall' | 'other', notes? }` → `{ movementId, onHand, atRevision }` (BE-27)
- [ ] Backend: `GET /api/v1/inventory?storeId=&cursor=&q=` — cursor-paginated list of `{ ean, name, onHand, lowStockThreshold, lastMovementAt }` (BE-27)
- [ ] Backend: `GET /api/v1/inventory/low-stock?storeId=` — pre-filtered list with `urgency: 'amber' | 'red'` (BE-27)
- [ ] Backend: `PUT /api/v1/inventory/low-stock-rules` body `{ rules: [{ ean?, category?, threshold, mode: 'absolute' | 'days_of_cover' }] }` (BE-27)
- [ ] Backend: BE-08 fresh role probe on every mutation (`X-Role-Recheck: 1` header path)
- [ ] FE-17 camera + ML Kit barcode widget exposed as `ProductScanPickerSheet`
- [ ] FE-08 Drift outbox table `inventory_outbox` with idempotency key column
- [ ] Lottie pack additions:
  - `stock_in_success.json` — 900ms one-shot, ≤ 60 KB
  - `stock_out_success.json` — 900ms one-shot, ≤ 60 KB
  - `low_stock_pulse.json` — 1.6s loop, ≤ 28 KB (drives the urgency dot on red rows)
- [ ] Design assets: empty-state illustrations for both tabs, plus an "all stocked up" illustration for the low-stock list

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/inventory/inventory_screen.dart` | Two-tab host: Stock In / Stock Out + drawer entries for counts + rules |
| `apps/mobile/lib/features/business/inventory/inventory_counts_screen.dart` | Counts list with infinite scroll, search, low-stock filter chip |
| `apps/mobile/lib/features/business/inventory/low_stock_rules_screen.dart` | Rules editor (per-EAN + per-category) |
| `apps/mobile/lib/features/business/inventory/inventory_controller.dart` | Riverpod `Notifier<StockMovementDraftState>` |
| `apps/mobile/lib/features/business/inventory/inventory_state.dart` | Sealed state + tab enum + reason enum |
| `apps/mobile/lib/features/business/inventory/data/inventory_repository.dart` | Wraps BE-27 read endpoints |
| `apps/mobile/lib/features/business/inventory/data/stock_movement_repository.dart` | Wraps BE-27 mutation endpoints (idempotent) |
| `apps/mobile/lib/features/business/inventory/data/low_stock_rules_repository.dart` | Wraps low-stock rules endpoint |
| `apps/mobile/lib/features/business/inventory/data/inventory_outbox.dart` | Drift table + replay handler |
| `apps/mobile/lib/features/business/inventory/widgets/stock_in_form.dart` | Form for tab 1 (qty, reason, optional batch + expiry) |
| `apps/mobile/lib/features/business/inventory/widgets/stock_out_form.dart` | Form for tab 2 (qty, reason mandatory) |
| `apps/mobile/lib/features/business/inventory/widgets/product_scan_picker.dart` | Bridges to FE-17 with permission re-check |
| `apps/mobile/lib/features/business/inventory/widgets/inventory_row.dart` | List tile: name, on-hand chip, urgency dot, last-movement time |
| `apps/mobile/lib/features/business/inventory/widgets/urgency_dot.dart` | Amber / red Lottie-pulsed dot |
| `apps/mobile/lib/features/business/inventory/widgets/quantity_stepper.dart` | +/- with long-press auto-repeat |
| `apps/mobile/lib/features/business/inventory/widgets/reason_chip_strip.dart` | Horizontal reason chips (sold/damaged/expired/recall/other) |
| `apps/mobile/lib/features/business/inventory/widgets/movement_success_sheet.dart` | Lottie + new on-hand + "Add another" CTA |
| `apps/mobile/lib/features/business/inventory/widgets/rollback_diff_banner.dart` | Shows server-asserted on-hand vs optimistic on-hand on reject |
| `apps/mobile/lib/features/business/inventory/widgets/low_stock_rule_row.dart` | One rule row in the editor |
| `apps/mobile/test/features/business/inventory/inventory_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/inventory/golden/inventory_states.dart` | Goldens (light + dark + RTL) |
| `apps/mobile/integration_test/inventory_flow_test.dart` | Patrol E2E |

## Screen / Widget Spec

```dart
// inventory_state.dart
enum InventoryTab { stockIn, stockOut }

enum StockOutReason { sold, damaged, expired, recall, other }

sealed class StockMovementDraftState { const StockMovementDraftState(); }

class StockMovementIdle extends StockMovementDraftState {
  final InventoryTab tab;
  final InventoryItem? selected;
  final int quantity;
  final StockOutReason? reason;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;
  final bool offlineQueued;
  final FormValidation validation;
  const StockMovementIdle({...});
}

class StockMovementSubmitting extends StockMovementDraftState {
  final StockMovementIdle snapshot;
  const StockMovementSubmitting(this.snapshot);
}

class StockMovementPosted extends StockMovementDraftState {
  final String movementId;
  final int newOnHand;
  final InventoryTab tab;
  const StockMovementPosted(this.movementId, this.newOnHand, this.tab);
}

class StockMovementRolledBack extends StockMovementDraftState {
  final StockMovementIdle snapshot;
  final int serverOnHand;
  final int optimisticOnHand;
  final String reasonCode;
  const StockMovementRolledBack({
    required this.snapshot,
    required this.serverOnHand,
    required this.optimisticOnHand,
    required this.reasonCode,
  });
}

// inventory_controller.dart
abstract interface class InventoryController {
  void switchTab(InventoryTab tab);
  Future<void> pickProduct(String ean);
  void setQuantity(int qty);
  void setReason(StockOutReason reason);
  void setBatch(String? batch, DateTime? expiry);
  Future<void> submit();
  Future<void> retry();
  void resetAfterSuccess();
}
```

```dart
// quantity_stepper.dart
class QuantityStepper extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  // Long-press to auto-repeat at 8/sec, capped at `max`. Haptic.selection on each tick.
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9999,
    super.key,
  });
}
```

```dart
// urgency_dot.dart
class UrgencyDot extends StatelessWidget {
  final UrgencyLevel level; // none, amber, red
  const UrgencyDot(this.level, {super.key});
  // Red plays low_stock_pulse.json on a 1.6s loop. Amber is static. Reduced motion -> static for both.
}
```

### `InventoryRow`
- Layout: 56dp tall. Left: 32×32 product avatar (initials fallback). Center: name (1 line ellipsis) + sub-line "{onHand} on hand · {timeAgo}". Right: `UrgencyDot`.
- Tap: opens FE-19 product detail with a Hero on `hero.product.{ean}` (registered with FE-33).
- Long-press: opens an action sheet — Stock-out · Recount · Set rule · Cancel.
- Swipe right: stock-in shortcut (pre-fills the form on tab 1 with this item selected).
- Swipe left: stock-out shortcut.

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **Tab idle, no product** | Empty state illustration + "Scan or search to start" + scan FAB pulses (220ms scale 0.96→1.0 every 4s) |
| 2 | **Product picked** | Hero card slides in from right (`motion.normal`, `swiftOut`); quantity stepper enters at 1; reason chips fade in (stagger `tight`) on the stock-out tab |
| 3 | **Quantity step long-press** | Auto-repeat fires after 320ms hold; haptic.selection per tick; visual 0.97 scale on the tapped button |
| 4 | **Reason chip selected (stock-out)** | Selected chip pulses to scale 1.04 over 120ms then settles; siblings dim to 60% opacity |
| 5 | **Submit pressed (online)** | Button collapses into a spinner (200ms), backend probe runs; on 200, `MovementSuccessSheet` slides up with `stock_in_success.json` or `stock_out_success.json` (900ms one-shot), new on-hand displayed in 28sp, "Add another" CTA |
| 6 | **Submit rejected (validation)** | `RollbackDiffBanner` slides down: "Server has 14 on hand, you tried to remove 18. Showing latest." Inline form refresh; haptic.warning |
| 7 | **Submit rejected (insufficient stock)** | Same banner, with red urgency tint and "Reduce quantity" CTA that auto-clamps to `serverOnHand` on tap |
| 8 | **Submit while offline** | Form locks for 200ms; outbox entry created with idempotency key `inv-mov-{uuid}`; cloud-off badge appears in the success sheet; banner "Will post when online" |
| 9 | **Counts list scroll** | Pull-to-refresh with `motion.normal` rebound; new items fade in (`tight` stagger) |
| 10 | **Counts list low-stock filter** | Filter chip toggles; non-matching rows collapse with 180ms slide-out + fade |
| 11 | **Low-stock rules editor open** | Bottom sheet height 75% of screen; rule rows enter with `loose` stagger; per-row delete swipe |
| 12 | **Permission revoked entering scanner** | FE-17 rationale sheet replaces camera viewport; "Open settings" deep-link via `permission_handler` |
| 13 | **Role demoted mid-session** | Server returns 403 on submit; inline modal "Your role no longer allows this. Ask the manager." → routes to FE-25 dashboard |
| 14 | **Dark mode** | Surface `M3 surfaceContainerHighest`, urgency dots stay perceptually equivalent (luminance-mapped, not raw hex) |
| 15 | **RTL (hi/ar paths)** | Tab order flips, reason chips reverse, swipe directions invert (right-swipe = stock-out for RTL) |
| 16 | **Reduced motion** | Lottie sheets replaced with a static checkmark frame; stagger removed from list reveal; stepper press-scale removed |
| 17 | **Dynamic type xxLarge** | Quantity stepper grows to 72dp; reason chips wrap to two rows; on-hand chip moves below the name |
| 18 | **Keyboard open on quantity** | Form scrolls to keep stepper above the keyboard; reason chips remain visible above the keyboard inset |

## Animations

Inventory motion budget is conservative — this is a daily-use screen and exuberance gets old fast. The two moments that earn full motion: a successful post and a low-stock pulse.

- **Lottie**:
  - `stock_in_success.json` — 900ms, success sheet, single shot per submit
  - `stock_out_success.json` — 900ms, success sheet, single shot per submit
  - `low_stock_pulse.json` — 1.6s loop on red urgency dots only (amber is static)
- **flutter_animate chains**:
  - Tab switch: `.fadeIn(motion.normal, swiftOut).slideX(begin: 0.05)` — the next tab slides in from outside
  - Inventory row enter (counts list): stagger `tight` (28ms), `.fadeIn(motion.fast).slideY(begin: 0.04)`
  - Reason chip select: `.scale(begin: 1.0, end: 1.04, duration: motion.fast).then().scale(end: 1.0)`
  - Submit button morph: width-tween to circle over 200ms, spinner inside
  - RollbackDiffBanner: `.slideY(begin: -1.0, end: 0, duration: motion.normal, curve: standard).fadeIn(motion.fast)`
  - Empty state illustration: 4s loop on the scan FAB scale only — illustration itself is static
- **Hero**: `Hero(tag: RadhaHero.product(ean))` from inventory row to product detail (FE-19). Single Hero per route, enforced by FE-33.
- **Custom**: success sheet uses `motion.celebrate` overshoot curve on the on-hand digit count-up (e.g., 14 → 18 ticks over 480ms)

## Haptics
- **selection** — tab switch, quantity stepper tick, reason chip select
- **light** — submit button press, swipe-to-action reveal
- **medium** — successful post (single confirmation pulse)
- **warning** — rollback banner appears, low-stock filter surfaces a red row
- **heavy** — role demoted modal (rare, but the user must feel it)
- **success** — pattern fires alongside `MovementSuccessSheet` open

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `inv.title` | "Inventory" | "इन्वेंटरी" | "சரக்கு" | "ఇన్వెంటరీ" | "ইনভেন্টরি" | "इन्व्हेंटरी" |
| `inv.tab.in` | "Stock In" | "स्टॉक इन" | "உள்வரவு" | "స్టాక్ ఇన్" | "স্টক ইন" | "स्टॉक इन" |
| `inv.tab.out` | "Stock Out" | "स्टॉक आउट" | "வெளியேற்றம்" | "స్టాక్ అవుట్" | "স্টক আউট" | "स्टॉक आउट" |
| `inv.empty.scan` | "Scan or search to start" | "स्कैन या खोजें" | "ஸ்கேன் அல்லது தேடு" | "స్కాన్ లేదా శోధించండి" | "স্ক্যান বা খুঁজুন" | "स्कॅन किंवा शोधा" |
| `inv.qty` | "Quantity" | "मात्रा" | "அளவு" | "పరిమాణం" | "পরিমাণ" | "मात्रा" |
| `inv.reason.sold` | "Sold" | "बिका" | "விற்கப்பட்டது" | "విక్రయించబడింది" | "বিক্রি হয়েছে" | "विकले" |
| `inv.reason.damaged` | "Damaged" | "क्षतिग्रस्त" | "சேதம்" | "దెబ్బతిన్నది" | "ক্ষতিগ্রস্ত" | "खराब" |
| `inv.reason.expired` | "Expired" | "एक्सपायर" | "காலாவதி" | "గడువు ముగిసింది" | "মেয়াদোত্তীর্ণ" | "मुदतबाह्य" |
| `inv.reason.recall` | "Recall" | "रिकॉल" | "திரும்பப் பெறுதல்" | "రీకాల్" | "রিকল" | "परत बोलावले" |
| `inv.success.in` | "Stocked in {qty} — now {onHand}" | "स्टॉक {qty} जोड़ा" | "{qty} சேர்க்கப்பட்டது" | "{qty} జోడించబడింది" | "{qty} যোগ হয়েছে" | "{qty} जोडले" |
| `inv.success.out` | "Stocked out {qty} — now {onHand}" | "{qty} घटाया" | "{qty} கழிக்கப்பட்டது" | "{qty} తగ్గించబడింది" | "{qty} কমানো হয়েছে" | "{qty} वजा केले" |
| `inv.rollback.short` | "Server has {n} — try again" | "सर्वर {n} — पुनः" | "சேவையகத்தில் {n}" | "సర్వర్‌లో {n}" | "সার্ভারে {n}" | "सर्व्हर {n}" |
| `inv.offline.queued` | "Will post when online" | "ऑनलाइन होने पर" | "ஆன்லைனில்" | "ఆన్‌లైన్‌లో" | "অনলাইনে" | "ऑनलाइन झाल्यावर" |
| `inv.lowstock.title` | "Low stock" | "कम स्टॉक" | "குறைந்த சரக்கு" | "తక్కువ స్టాక్" | "কম স্টক" | "कमी स्टॉक" |
| `inv.rules.add` | "Add rule" | "नियम जोड़ें" | "விதி சேர்" | "నియమం జోడించండి" | "নিয়ম যোগ" | "नियम जोडा" |

## Backend Integration
- **POST /api/v1/inventory/stock-in** body `{ ean, quantity, reason: 'grn' | 'manual' | 'correction', batchNumber?, expiryDate? }` → `200 { movementId, onHand, atRevision }`
- **POST /api/v1/inventory/stock-out** body `{ ean, quantity, reason, notes? }` → `200 { movementId, onHand, atRevision }`
- **GET /api/v1/inventory** query `storeId, cursor?, q?` → cursor page of `InventoryItem`
- **GET /api/v1/inventory/low-stock** query `storeId` → list of `InventoryItem` with `urgency`
- **PUT /api/v1/inventory/low-stock-rules** body `{ rules: LowStockRule[] }` → 204

### Idempotency
Every mutation sends `Idempotency-Key: inv-mov-{uuid-v4-per-attempt}`. Replays return the original 200 — never a duplicate movement. The outbox stores the same key so a reconnect retry collapses safely.

### Optimistic UI + rollback
1. User taps Submit. UI moves to `StockMovementSubmitting` and locally bumps `onHand` by `±qty`.
2. Backend probes role (BE-08), validates `onHand ≥ qty` for stock-out, and writes the audit row.
3. On 200, UI moves to `StockMovementPosted`. The success sheet count-up animates from the optimistic value to `response.onHand` (almost always equal — the gap exists only if a concurrent sync arrived between steps 1 and 3).
4. On 4xx, UI moves to `StockMovementRolledBack`. The form is restored, the banner shows server vs optimistic, and the local on-hand snaps back via the `atRevision` versioning rule from BE-44.

### Security note
The UI does **not** gate the stock-out reason `recall` based on a local `role == 'manager'` check. The server enforces that. The UI shows the chip; if the server returns 403, the UI surfaces the role-demoted modal. Trusting client-side role for security would be an audit-log forgery vector.

### Permissions note
Entering the product scan picker (`product_scan_picker.dart`) re-checks `Permission.camera.status` every time, even within the same session, and routes to the FE-17 rationale sheet on `denied` or `permanentlyDenied`. The rationale sheet itself never auto-prompts on `permanentlyDenied` — it surfaces an "Open settings" deep-link only.

### Vendor quality + OHS
Inventory accuracy is one of the six OHS components (BE-30 v2). The metric counts:
- numerator: `movements_posted` (200 path)
- denominator: `movements_posted + movements_rolled_back` (200 + 4xx path)
- window: rolling 30 days
The dashboard (FE-25) re-fetches OHS at most every 60s. We don't need to do anything beyond emitting the success/reject events with the standard analytics envelope.

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 | — | success sheet + on-hand count-up |
| 400 | `validation_error` | inline field error + warning haptic |
| 401 | `unauthorized` | force `/login` |
| 403 | `not_in_role` | role-demoted modal; route to FE-25 |
| 404 | `ean_not_found` | inline "Product missing — add it via GRN" CTA → FE-29 |
| 409 | `revision_conflict` | rollback banner with diff; outbox replays once with fresh revision |
| 422 | `insufficient_stock` | rollback banner with "Reduce to {n}" CTA |
| 429 | `rate_limited` | toast; submit disabled 30s |
| 5xx / network | — | offline outbox path; cloud-off success sheet |

## Charts & Data Viz
The counts list shows a 7-day on-hand sparkline only on tap-and-hold of a row (read from BE-27 `?series=7d`). It uses the same `MicroSparkline` widget from FE-25.
- Y-axis is implicit; tooltip shows `{date}: {onHand}`
- Reduced motion: sparkline draws in instantly with no path-trace animation
- Accessibility: `Semantics(label: '7-day stock trend, low {min}, high {max}')` and a long-form table accessible from the row's accessibility menu

## Accessibility
- Tabs expose `Semantics(header: true, selected: ...)` and announce "Stock In tab, 1 of 2"
- Quantity stepper announces "Quantity {n}, double-tap and hold to repeat" via `Semantics(value: ...)`
- Reason chip strip is a single `RadioListTile`-style group with `Semantics(toggled: ...)`
- `UrgencyDot` is decorative (`ExcludeSemantics`); the row's text already carries "low stock"
- Reduced motion: stepper press-scale, tab slide, chip pulse all swap to instant; success sheet Lottie replaced with a static check
- Dynamic type xxLarge: stepper +/- buttons grow to 72dp tap target; reason chips wrap; on-hand chip relocates below the name
- Focus order: tab bar → product picker → quantity stepper → reason chips → batch/expiry (if visible) → submit
- High contrast: urgency dots use luminance-mapped tokens (`color.urgency.amber.contrast`, `color.urgency.red.contrast`) — never raw hex
- Voice input on the quantity field
- TalkBack/VoiceOver labels for `MovementSuccessSheet`: "Stocked in 4 units. New on hand 18. Add another or close."

## Testing

### Unit
- `inventory_controller_test.dart`: state machine — idle → submitting → posted on 200; idle → submitting → rolledBack on 422 with diff
- Quantity stepper auto-repeat math: 8 ticks/sec capped at `max`
- Idempotency key generation per attempt — replay returns same key
- Outbox: enqueues on offline; replays in order; collapses dupes by idempotency key

### Widget
- Two-tab screen renders both forms; switching preserves draft state
- `QuantityStepper` long-press auto-repeats and stops on lift
- `ReasonChipStrip` enforces single-select on stock-out tab; absent on stock-in tab
- `MovementSuccessSheet` shows correct Lottie per tab; count-up animates from optimistic → server value
- `RollbackDiffBanner` shows server vs optimistic and auto-clamps quantity on tap
- Permission revoked between sessions: scanner entry shows FE-17 rationale, not black surface
- Reduced motion swaps Lottie for static frame and removes stepper scale

### Golden (light + dark + RTL)
- 8 anchor states × 3 themes × 3 sizes = 72 goldens, generated under the FE-37 baseline harness:
  - empty, picked-product, submitting, posted-success, rolled-back, offline-queued, low-stock-list, low-stock-rules-editor

### Integration (Patrol)
- Happy path stock-in: pick product → qty 5 → submit → success sheet → "Add another" returns to clean form
- Happy path stock-out with reason: pick → qty 3 → reason `damaged` → submit → success
- Insufficient-stock rollback: pick → qty 999 → submit → 422 → banner → "Reduce to {n}" → submit → success
- Offline path: airplane mode → submit → outbox queued → reconnect → replay → success sheet appears
- Role demotion mid-flow: server returns 403 → modal → routes to FE-25
- Permission re-check: revoke camera in settings → re-enter scan picker → rationale sheet surfaces

### Perf
- 1000-row scroll on Pixel 4a release build at 60fps (verified with DevTools timeline; jank rate < 1%)
- p95 stock-out submit-to-success latency < 1.2s online; offline queue path < 200ms

## Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Optimistic UI hides a real backend rejection (e.g., user assumes success) | Medium | `RollbackDiffBanner` is sticky until acknowledged; haptic.warning fires; analytics tracks rollback rate per store |
| Drift outbox replays out of order, double-decrements stock | Low/Critical | Idempotency keys + server `atRevision` check; integration test simulates 3 queued entries with same EAN |
| Camera permission revoked between sessions silently breaks scan picker | Medium | Re-check on every entry, not just first launch; rationale sheet surfaces instead of black surface |
| Client-side role-gating allows a demoted user to send a recall stock-out | Low/Critical | UI never gates by local role; server returns 403; UI surfaces role-demoted modal |
| 1000-SKU scroll janks on Pixel 4a (low-end) | Medium | `ListView.builder` + `RepaintBoundary` per row; sparkline only on long-press, not always-on; verified by FE-39 perf pass |
| Low-stock pulse Lottie burns battery on always-visible counts list | Medium | Pulse only renders for visible red rows via `VisibilityDetector`; off-screen rows pause the loop |
| Multiple concurrent stock-outs race the on-hand value | High | Server is the source of truth; optimistic UI corrects on 200 via `response.onHand`; revision conflict path tested |
| RTL swipe directions confuse left-handed RTL users | Medium | Swipe-to-action localized: in RTL, right-swipe = stock-out (mirroring LTR's left-swipe semantics); golden test covers it |

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Stock-in with valid product + qty 5 + reason `manual` posts in < 1.2s p95 online and surfaces the success sheet with on-hand count-up |
| T2 | Stock-out with reason `damaged` posts and the audit log entry on the server records the correct local user and reason code |
| T3 | Quantity stepper long-press auto-repeats at 8 ticks/sec and stops within 60ms of lift |
| T4 | Insufficient-stock submission triggers `RollbackDiffBanner`; tapping "Reduce to {n}" auto-clamps the stepper |
| T5 | Offline submission enqueues to the outbox with a fresh idempotency key; reconnect replays exactly once |
| T6 | Idempotency replay (same key, two attempts) returns the same `movementId` and on-hand — never two ledger rows |
| T7 | Camera permission revoked in OS settings between sessions: re-entering the scan picker shows the FE-17 rationale sheet, not a black camera surface |
| T8 | Role demoted mid-session (server 403) surfaces the role-demoted modal and routes to FE-25; the local on-hand snaps back |
| T9 | Counts list scrolls 1000 rows on a Pixel 4a release build with jank rate < 1% measured by DevTools timeline |
| T10 | Low-stock pulse Lottie animates only for visible red rows; scrolled-off rows pause within 200ms of leaving the viewport |
| T11 | Low-stock rules editor: adding a per-EAN rule with `mode: days_of_cover` posts a 204 and re-fetches the low-stock list within one tick |
| T12 | Reduced-motion enabled: success sheet shows a static check, stepper has no press-scale, list reveal has no stagger |
| T13 | RTL build (Hindi/Arabic mock): swipe-to-stock-out is right-swipe; goldens match the LTR mirrored baseline |
| T14 | TalkBack reads the success sheet as "Stocked in {qty}, new on hand {n}, add another or close" |
| T15 | Inventory Accuracy OHS component on FE-25 dashboard reflects a successful submit + a forced rollback within one dashboard refresh window (≤ 60s) |

### Q&A Questions (8)
1. How do we keep the form draft alive across cold-restarts (e.g., user composes a stock-out and force-quits the app)?
2. What's the policy when the local outbox depth exceeds 50 entries — surface a hard "go online" warning, or silently keep enqueuing?
3. How does the optimistic on-hand reconcile with a concurrent inbound GRN posting from FE-29 between submit and ack?
4. Why is the camera permission re-checked on every scan-picker entry instead of cached for the session?
5. Why does the UI never gate the `recall` reason by local role, and what would the audit-log forgery look like if we did?
6. How do we keep the low-stock pulse Lottie from burning battery on always-visible counts lists with many red rows?
7. What's the analytics taxonomy for `inventory_movement_posted` vs `inventory_movement_rolled_back` so the Owner Dashboard can compute store-level accuracy?
8. How does the rules editor handle a rule conflict (e.g., per-EAN threshold of 3 vs per-category threshold of 5 for the same SKU)?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90% on `lib/features/business/inventory/**`; submit-to-success p95 < 1.2s
- [ ] Developer: 8 Q&A answered in the handoff doc
- [ ] Reviewer: Idempotency verified end-to-end with a forced reconnect; rollback diff verified on hardware
- [ ] Reviewer: confirmed the UI never gates mutations by local role
- [ ] Designer (motion review): success sheet and low-stock pulse approved on Pixel 4a + iPhone SE 2
- [ ] Accessibility reviewer: TalkBack + VoiceOver flows on hardware; reduced motion verified
- [ ] PM: Microcopy reviewed in all 6 languages

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-30 — DO NOT PROCEED WITHOUT APPROVAL**
