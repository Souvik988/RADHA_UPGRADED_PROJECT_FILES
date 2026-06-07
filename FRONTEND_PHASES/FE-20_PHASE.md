# Phase FE-20: Saved Products + Expiry Calendar

## 1. Phase Metadata

- **Phase ID**: FE-20
- **Phase Name**: Saved Products + Expiry Calendar
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme), FE-09 (haptics), FE-15 (router), FE-19 (Hero target), BE-09 v2 (saved products), BE-38 (expiry calendar API), BE-36 (family sharing), BE-08 v2 (entitlements)
- **Blocks**: FE-21 (Recall Inbox can deep-link to saved item), FE-24 (Shopping List share)
- **Estimated Duration**: 3 days
- **Complexity**: Medium-High (calendar layout + bottom sheet + family-share filter)

## 2. Goal (Engagement Angle)

Turn the home pantry into a glanceable habit. Open the app any morning, see the month at a glance — green dots for "all good", yellow for "use soon", red for "today/expired". Tap a day, get a beautiful bottom sheet of products with swipe-to-consume gestures that make food management feel light. For Premium users, the calendar quietly *unions* the family's pantries with a friendly chip — one tap toggles "just me" / "the whole family".

## 3. Why This Phase Matters (Retention Metric)

- This screen is the **2nd-most-opened screen** after the scanner. Target: **weekly active calendar opens / WAU ≥ 0.6**.
- Reduces food waste — measurable via "marked consumed" events. Each consume tap is a "win" haptic, reinforcing the habit.
- Family-share union is the visible payoff for Premium — the chip's existence on the screen is itself a feature-discovery affordance.
- Empty state with Lottie + scan CTA is the highest-converting "back-to-scanner" prompt for users with 0 saved items. Target: **empty-state CTR to scanner ≥ 35%**.

## 4. Prerequisites

- [ ] BE-38 — `GET /api/v1/consumer/expiry-calendar?month=YYYY-MM` returns per-day buckets and color codes
- [ ] BE-09 v2 — `POST /api/v1/saved-products/{id}/consumed`, `DELETE /api/v1/saved-products/{id}`
- [ ] BE-36 — Family-share union flag respected by BE-38
- [ ] BE-08 v2 — `Entitlements.familySharing` exposed
- [ ] FE-04 — Day-cell color tokens (`pantryGreen`, `pantryYellow`, `pantryRed`) approved
- [ ] FE-19 — Hero tag `product-{ean}-image` available for tap-through

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/saved_products/saved_products_screen.dart` | Page widget — calendar + tabs |
| `apps/mobile/lib/features/saved_products/widgets/expiry_month_grid.dart` | 7×N grid of day cells |
| `apps/mobile/lib/features/saved_products/widgets/expiry_day_cell.dart` | Day cell w/ colored dot |
| `apps/mobile/lib/features/saved_products/widgets/month_pager_header.dart` | Month switcher with pager |
| `apps/mobile/lib/features/saved_products/widgets/day_products_sheet.dart` | Bottom sheet with list |
| `apps/mobile/lib/features/saved_products/widgets/saved_product_tile.dart` | Dismissible swipe-tile |
| `apps/mobile/lib/features/saved_products/widgets/family_filter_chip.dart` | "Just me / Family" toggle |
| `apps/mobile/lib/features/saved_products/widgets/empty_state_view.dart` | Lottie + scan CTA |
| `apps/mobile/lib/features/saved_products/controllers/expiry_calendar_controller.dart` | Riverpod month loader |
| `apps/mobile/lib/features/saved_products/controllers/saved_products_controller.dart` | List CRUD + optimistic |
| `apps/mobile/lib/features/saved_products/services/expiry_calendar_repository.dart` | Drift cache + API |
| `apps/mobile/lib/features/saved_products/animations/dot_pulse.dart` | Today-cell ring pulse |
| `apps/mobile/assets/lottie/empty_pantry.json` | 1500 ms gentle floating-fruit loop |
| `apps/mobile/assets/lottie/consume_check.json` | 600 ms green check on swipe |
| `apps/mobile/test/features/saved_products/saved_products_widget_test.dart` | Widgets |
| `apps/mobile/test/features/saved_products/saved_products_golden_test.dart` | Goldens |
| `apps/mobile/integration_test/saved_products_flow_test.dart` | Integration |

## 6. Screen / Widget Spec

```dart
// saved_products_screen.dart
return Scaffold(
  appBar: AppBar(title: const Text('My pantry'), actions: [FamilyFilterChip()]),
  body: Column(children: [
    MonthPagerHeader(
      month: state.month,
      onPrev: () => ctrl.shiftMonth(-1),
      onNext: () => ctrl.shiftMonth(1),
    ),
    Expanded(
      child: state.when(
        loading: () => const _GridSkeleton(),
        error: (e, _) => _CalendarError(error: e),
        data: (month) => month.isEmpty
          ? const EmptyStateView()
          : ExpiryMonthGrid(
              month: month,
              onTapDay: (date) => _openDaySheet(context, date, ref),
            ),
      ),
    ),
  ]),
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () => context.go('/scan'),
    icon: const Icon(Icons.qr_code_scanner),
    label: const Text('Scan'),
  ),
);
```

```dart
// expiry_day_cell.dart
return InkWell(
  onTap: count == 0 ? null : onTap,
  child: Center(
    child: Stack(alignment: Alignment.center, children: [
      Text('$day', style: theme.bodyMedium),
      if (isToday) const _TodayPulseRing(),
      if (count > 0) Positioned(
        bottom: 4,
        child: Container(
          width: 6, height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
      ),
    ]),
  ),
);
```

```dart
// saved_product_tile.dart — Dismissible
return Dismissible(
  key: ValueKey(item.id),
  background: _SwipeBg.consume,        // right swipe (left→right gesture)
  secondaryBackground: _SwipeBg.delete, // left swipe (right→left gesture)
  confirmDismiss: (dir) async {
    if (dir == DismissDirection.startToEnd) {
      await ctrl.markConsumed(item.id);
      return true;
    }
    return await _confirmDelete(context);
  },
  child: ListTile(...),
);
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial** | Page mount, current month | Grid renders with skeleton dots; today cell pulses |
| 2 | **loading** | Month switching | Grid bones with 1100 ms shimmer |
| 3 | **loaded — populated** | Items present | Days with items show colored dots; total-count chip top-right of grid |
| 4 | **loaded — empty (no items at all)** | 0 saved products | Lottie `empty_pantry` + heading + scan CTA |
| 5 | **loaded — empty (this month only)** | Items exist but not this month | Calendar shows but with subdued caption "Nothing expiring this month" |
| 6 | **day-sheet open** | Tap day with items | Bottom sheet rises 240 ms easeOutCubic, day's products in list |
| 7 | **swipe-consume** | Right swipe on tile | Tile slides + green bg + Lottie check; confirm haptic |
| 8 | **swipe-delete (confirm)** | Left swipe past threshold | Confirm dialog, on confirm row collapses 200 ms |
| 9 | **family-filter on** | Tap chip toggle (Premium only) | Chip animates fill; calendar refetches with `?include=family` |
| 10 | **family-filter locked** | Free tier | Tap shows mini paywall toast with Premium CTA |
| 11 | **error-network** | Calendar fetch fails | Empty state with retry pill, shows last cached month if available |
| 12 | **offline** | Connectivity none | Strip "Showing cached pantry"; consume/delete actions queue to outbox |
| 13 | **rate-limited** | 429 | Snackbar with `retryAfter`, gestures debounced |
| 14 | **today-pulse** | Always | Today cell has continuous 1.4 s ring scale 1→1.1→1, opacity 0.6→0.0 |
| 15 | **just-consumed micro-summary** | After consume | Snackbar "Marked consumed — undo" 4 s |
| 16 | **accessibility-mode** | Reduced motion | No today-pulse, no Lottie loops, sheet uses fade |
| 17 | **month-swipe** | Horizontal pager swipe | Slides ±1 month, 320 ms easeInOutCubic |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `empty_pantry.json` | 1500 ms | Empty state | Yes | ≤ 30 KB |
| `consume_check.json` | 600 ms | Swipe-consume | No | ≤ 18 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| Today-cell pulse ring | `.scale(begin: 1, end: 1.1, dur: 700).then().fade(end: 0, dur: 700)` (loop) | easeOutCubic | 1400 ms loop |
| Day-sheet rise | `.slideY(begin: 1, end: 0, dur: 240)` | easeOutCubic | 240 ms |
| Family-filter chip | `.scaleXY(begin: 1, end: 1.05, dur: 120).then().scaleXY(end: 1, dur: 120)` | easeOut | 240 ms |
| Tile collapse on delete | `.fadeOut(dur: 120).then().crossfade(dur: 80)` (height tween) | easeOut | 200 ms |
| Empty-state hero entrance | `.fadeIn(220).slideY(begin: .04, end: 0, dur: 280)` | easeOutCubic | 500 ms |
| Month-pager swipe | `PageView` with `Curves.easeInOutCubic` 320 ms | — | 320 ms |

### Hero Transitions

| From | To | Tag | Curve | Duration |
|---|---|---|---|---|
| Day sheet tile thumbnail | FE-19 parallax hero | `product-{ean}-image` | easeInOutCubic | 360 ms |

### Custom Motion Budgets

- **Entrance**: ≤ 480 ms (grid 220 fade + skeleton resolve)
- **Day-sheet flow**: ≤ 240 ms rise
- **Swipe action**: ≤ 380 ms (tile slide 200 + Lottie 600 overlapped)

## 9. Haptics

| Event | Type |
|---|---|
| Tap day cell with items | `selectionClick` |
| Tap empty day cell | none (no-op) |
| Day-sheet open | `lightImpact` |
| Swipe-consume threshold reached | `mediumImpact` |
| Swipe-delete threshold reached | `heavyImpact` |
| Confirm delete | `mediumImpact` |
| Month swipe across boundary | `lightImpact` |
| Family-filter toggle on | `mediumImpact` |
| Family-filter blocked (free) | `heavyImpact` |
| Undo consume | `lightImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `pantry.title` | My pantry | TODO | TODO | TODO | TODO | TODO |
| `pantry.empty_heading` | Nothing here yet | TODO | TODO | TODO | TODO | TODO |
| `pantry.empty_body` | Scan your first product to start tracking expiry | TODO | TODO | TODO | TODO | TODO |
| `pantry.empty_cta` | Open scanner | TODO | TODO | TODO | TODO | TODO |
| `pantry.empty_month` | Nothing expiring this month | TODO | TODO | TODO | TODO | TODO |
| `pantry.day_sheet_title` | Expiring on {{date}} | TODO | TODO | TODO | TODO | TODO |
| `pantry.consume_action` | Mark consumed | TODO | TODO | TODO | TODO | TODO |
| `pantry.consumed_undo` | Marked consumed — Undo | TODO | TODO | TODO | TODO | TODO |
| `pantry.delete_confirm_title` | Remove from pantry? | TODO | TODO | TODO | TODO | TODO |
| `pantry.family_chip_self` | Just me | TODO | TODO | TODO | TODO | TODO |
| `pantry.family_chip_all` | Everyone | TODO | TODO | TODO | TODO | TODO |
| `pantry.family_locked` | Family sharing is a Premium feature | TODO | TODO | TODO | TODO | TODO |
| `pantry.cached_strip` | Showing your cached pantry | TODO | TODO | TODO | TODO | TODO |
| `pantry.error_network` | Couldn't load. Pull to retry. | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/consumer/expiry-calendar?month=YYYY-MM&include=family` | Month buckets | BE-38 |
| `POST` | `/api/v1/consumer/expiry-calendar/saved-products/{id}/consumed` | Mark consumed | BE-38 |
| `DELETE` | `/api/v1/consumer/expiry-calendar/saved-products/{id}` | Remove | BE-38 |
| `GET` | `/api/v1/consumer/family-members` | Filter source for chip | BE-36 |

### DTOs

```ts
interface ExpiryCalendarMonthDto {
  month: string;                                       // 'YYYY-MM'
  days: Array<{ date: string; bucket: 'green'|'yellow'|'red'; count: number; productIds: string[] }>;
  total: number;
}
```

### Idempotency Key Strategy

- Mark consumed: `idempotencyKey = sha256(savedProductId + 'consumed')` — repeat is no-op.
- Delete: `If-Match` ETag header from GET response to prevent stale deletes.

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 | re-login |
| 403 / `entitlement.family_sharing_required` | Mini-paywall toast on chip |
| 404 / `saved_products.not_found` | Snackbar "Already removed" + refresh |
| 422 / invalid month | Should be impossible from UI, log Sentry |
| 5xx / network | Cached fallback + retry pill |

## 12. Accessibility

- **Semantics**: Each day cell `Semantics(label: 'September 14, 3 products expiring soon, urgent')`. Sheet handle gets `Semantics(label: 'Drag to dismiss')`.
- **Focus order**: AppBar → family chip → month pager prev → month label → next → calendar grid in row-major order.
- **Dynamic type**: Day-cell numbers scale up to 1.4×; beyond that rows reflow to 6-col grid.
- **Reduced motion**: No today-pulse loop, sheet rises via fade-in 200 ms.
- **VoiceOver script**: On day-sheet open, announce `"Showing 3 products expiring on September 14"`.
- **Contrast**: Day-cell dots tested ≥ 3:1 against grid background; bucket text alongside dot for color-blind users.

## 13. Testing

### Widget tests

- Day cell renders correct dot color for buckets {green, yellow, red, none}.
- Tapping empty day cell does nothing.
- Tapping populated day opens sheet with correct count.
- Swipe-consume calls controller `markConsumed`.
- Swipe-delete shows confirm dialog before mutating.
- Family chip is locked for free tier and unlocked for premium.

### Golden tests

- Month with mixed buckets (light + dark)
- Empty state full-page (light + dark + 1.4× type)
- Day-sheet open with 5 items
- Family chip locked vs. unlocked

### Integration tests

- Mark consumed → optimistic UI → undo within 4 s rolls back.
- Month-pager swipe triggers fetch of new month and caches result.
- Offline mode shows cached month and queues mutations.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Calendar grid renders 7 columns, dynamic 5–6 rows depending on month |
| T2 | Today cell pulses continuously at 1400 ms cadence (or static under reduced motion) |
| T3 | Month pager swipe triggers BE-38 fetch with the correct `month` param |
| T4 | Day cell color matches BE-38 bucket exactly (green/yellow/red) |
| T5 | Tapping populated day opens sheet within 240 ms |
| T6 | Swipe-consume mutation is optimistic and reverts on 5xx |
| T7 | Swipe-delete shows native confirm and respects cancel |
| T8 | Family chip is gated by `Entitlements.familySharing` and shows mini-paywall on tap (free) |
| T9 | Family chip toggle re-fetches with `?include=family` and merges other members |
| T10 | Empty state uses Lottie loop and routes to `/scan` on CTA tap |
| T11 | Offline mode shows cached month + strip + queues mutations |
| T12 | VoiceOver announces day cell contents correctly |
| T13 | Reduced motion disables pulse and uses fade for sheet |
| T14 | Hero from sheet tile to FE-19 detail completes cleanly |
| T15 | Calendar still renders correctly on month boundaries crossing DST/IST edge cases |

### Q&A Questions (8)

1. How does the calendar handle products with no expiry date (do they appear at all)?
2. How is the "yellow window" threshold (e.g., 7 days) sourced — global config, per-category, or BE-38 response?
3. How do we keep family-share union performant when 5 members each have 200+ saved products?
4. How are products that appear in multiple members' pantries de-duplicated in the day sheet?
5. What's the strategy for "infinite" months (user navigates 12 months ahead) — fetch eagerly or on demand?
6. How do we handle a user who deletes a saved product on this screen but recently used it on FE-19 (cache invalidation)?
7. How do we test the "weekly active calendar opens" metric without polluting it with developer activity?
8. What's the long-term plan for export-to-ICS that BE-38 mentions as a Q&A item?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off bucket colors and pulse intensity
- [ ] Animation budgets respected
- [ ] Goldens merged
- [ ] Family-chip paywall flow approved by Product

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-21 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-20 — DO NOT PROCEED WITHOUT APPROVAL**
