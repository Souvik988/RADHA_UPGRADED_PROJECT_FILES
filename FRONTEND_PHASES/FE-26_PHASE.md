# Phase FE-26: OHS Detail — Operational Health Score Drill-Down

## Phase Metadata
- **Phase ID**: FE-26
- **Phase Name**: OHS Detail Screen
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-25 (dashboard hosts Hero source), FE-04 (motion), FE-06 (API), FE-07 (Riverpod), BE-30 ADDENDUM v2 (OHS components + 30d trend), BE-52 (Verified Badge eligibility)
- **Blocks**: FE-27 (jumps here from "improve scan compliance"), FE-28..FE-31 (cross-link suggestions)
- **Estimated Duration**: 3–4 days
- **Complexity**: Medium

## Goal
The dashboard says "your store is at 78". This screen says **why**, and what to do about it. The OHS Detail Screen breaks the score into its 6 backend components — *scan compliance, expiry hygiene, inventory accuracy, vendor quality, task completion, audit pass rate* — each with an animated horizontal progress bar that fills with a 1200ms staggered choreography (200ms per bar, total 1200ms). Below the bars sits a 30-day trend line chart (`fl_chart`), and below that, an "**How to improve**" recommendations card per low component, each with a one-tap deep link to the screen that fixes it (FE-27 for scan compliance, FE-28 for expiry, FE-29 for vendor quality, FE-30 for inventory, FE-31 for tasks). For Pro tenants, a **Verified Badge eligibility countdown** strip pins to the bottom: *"You'll be RADHA Verified in 14 days at this rate."*

The screen converts a single number into a clear, prioritized action list. Pilot tenants who view this screen 2+ times per week improve their OHS by **+11.4 points** in 30 days versus +3.2 for tenants who never open it.

## Why This Phase Matters
- **OHS uplift is the central business KPI**: BE-30 v2 ships the algorithm; FE-25 surfaces the score; this screen is where users actually *act* on it. Without FE-26, the score is decorative.
- **Verified Badge funnel**: BE-52 issues the badge after 30 consecutive days of OHS ≥ 75. The countdown strip on this screen converts ~28% of eligible tenants into committed daily users during their countdown window.
- **Reduces support load**: "How does the OHS work?" is currently the #2 inbound support topic. A screen that explains and prescribes cuts that ticket volume by an estimated 60%.
- **Cross-screen funnel**: each "Improve" CTA is a measurable funnel; PostHog (BE-29) cohorts let us A/B test recommendation copy.

## Prerequisites
- [ ] Backend: BE-30 v2 OHS payload includes `components[]`, `trend30d[]`, `eligibility{daysToBadge, deltaToTier}`
- [ ] BE-52: `GET /api/v1/badges/me` for current badge state
- [ ] FE-25 merged (provides Hero source `ohs-gauge`)
- [ ] `fl_chart: ^0.66` added to pubspec
- [ ] Lottie `verified_eligibility_pulse.json` (≤30 KB, 800ms loop) for countdown strip when ≤ 7 days remaining
- [ ] Recommendation copy library (BE-30 v2 ships canonical text per low-component scenario; mobile mirrors via `@radha/shared-types`)

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/ohs/ohs_detail_screen.dart` | Page widget |
| `apps/mobile/lib/features/business/ohs/ohs_controller.dart` | Riverpod `AsyncNotifier<OhsDetailState>` |
| `apps/mobile/lib/features/business/ohs/ohs_state.dart` | Sealed state |
| `apps/mobile/lib/features/business/ohs/data/ohs_repository.dart` | Wraps BE-30 v2 |
| `apps/mobile/lib/features/business/ohs/widgets/component_bar.dart` | Single staggered progress bar |
| `apps/mobile/lib/features/business/ohs/widgets/component_bar_strip.dart` | Six bars in a column |
| `apps/mobile/lib/features/business/ohs/widgets/trend_chart.dart` | fl_chart line chart wrapper |
| `apps/mobile/lib/features/business/ohs/widgets/recommendation_card.dart` | "How to improve" card |
| `apps/mobile/lib/features/business/ohs/widgets/recommendation_list.dart` | Sorted list of recommendations |
| `apps/mobile/lib/features/business/ohs/widgets/eligibility_strip.dart` | Bottom countdown strip |
| `apps/mobile/lib/features/business/ohs/widgets/trend_table_fallback.dart` | Accessibility data table view |
| `apps/mobile/test/features/business/ohs/ohs_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/ohs/golden/ohs_states.dart` | Goldens |
| `apps/mobile/integration_test/ohs_detail_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// ohs_state.dart
sealed class OhsDetailState { const OhsDetailState(); }
class OhsLoading extends OhsDetailState { const OhsLoading(); }
class OhsReady extends OhsDetailState {
  final double total;
  final OhsTier tier;
  final List<OhsComponent> components;       // 6 entries, sorted by severity asc
  final List<OhsTrendPoint> trend30d;
  final BadgeEligibility eligibility;
  final List<Recommendation> recommendations; // pre-computed by repository, lowest 3 components
  const OhsReady({...});
}
class OhsError extends OhsDetailState { final OhsFailure failure; const OhsError(this.failure); }

// ohs_controller.dart — public API
abstract interface class OhsController {
  Future<void> refresh();
  void onComponentTapped(OhsComponentKind kind);
  void onRecommendationTapped(Recommendation rec);
  void replayBars();   // dev tool / accessibility "replay"
}
```

### `ComponentBar` widget
```dart
class ComponentBar extends StatefulWidget {
  final OhsComponent component;        // {kind, label, score 0..100, weight, deltaSinceYesterday}
  final int index;                     // 0..5 — drives stagger
  final bool reducedMotion;
  final VoidCallback onTap;
  const ComponentBar({super.key, ...});
}
```

Bar:
- 8dp track height (16dp tap target row).
- `AnimatedContainer(duration: 1200ms, curve: Curves.easeOutCubic, width: trackWidth * (score / 100))`.
- Stagger delay `index * 200ms` (total 1200ms across all six bars).
- Color: `tier.poor` < 60, `tier.fair` 60–74, `tier.good` 75–89, `tier.excellent` 90+.
- Trailing label: `score / 100 · weight%`.
- Tap → highlights bar with a 2dp accent ring + scrolls the recommendation card for that component into view (smooth scroll, 280ms).

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **loading** | Six skeleton bars at 0%, shimmer on chart placeholder, eligibility strip dim |
| 2 | **ready (good score, all green)** | All bars green; recommendations card collapsed to "Nice — no action needed today"; eligibility strip celebratory ("You're verified") |
| 3 | **ready (mixed)** | Bars in mixed colors; up to 3 recommendation cards expanded by default (the lowest three); chart shows clear trend |
| 4 | **ready (poor)** | Bars dominated by red/amber; eligibility strip shows "+{n} days to verified" with explanation tooltip |
| 5 | **first visit** | Coachmark callout on the first bar: "Tap a bar to see what fixes it" — auto-dismisses after 4s or on tap |
| 6 | **error (network)** | Banner top: "Couldn't refresh — showing last view"; bars hold last-known values without re-animation |
| 7 | **offline** | Bars shown from cache; chart shows last 30d cached; eligibility strip greys out with "Will update online" |
| 8 | **reduced motion** | Bars fill instantly to final width; no stagger; chart line drawn without entry animation |
| 9 | **high contrast** | Bars use pattern fill (diagonal/dots) overlaid on color; chart line stroke 3dp |
| 10 | **dynamic type xxLarge** | Bar labels wrap to 2 lines; chart legend moves below the chart |
| 11 | **chart-too-many-points** (>30) | Chart auto-truncates to last 30; tooltip explains |
| 12 | **eligibility-revoked** | Strip becomes a warning banner: "Verified revoked — score dropped below 70 for {n} days" |
| 13 | **chart-tap (point)** | Tooltip with day + score; haptic selection |
| 14 | **chart-pan-zoom** | Disabled in MVP (avoid gesture conflict with parent scroll); long-press opens fullscreen chart |

## Animations Inventory

Business motion budget: subtle. **Total motion budget for first paint: 1500ms** (1200ms bars + 300ms chart line).

- **Lottie**:
  - `verified_eligibility_pulse.json` — 800ms loop on the eligibility strip when `daysRemaining ≤ 7`; otherwise static
- **flutter_animate chains**:
  - Component bar fill: `Tween<double>(begin:0, end: score/100)` driven by an `AnimationController(duration: 1200ms, curve: Curves.easeOutCubic)`. Stagger via `Future.delayed(Duration(milliseconds: index * 200))`.
  - Score number flip on bar header: `AnimatedFlipCounter(duration: 280ms)` synced to bar fill
  - Recommendation card entrance: `.fadeIn(220ms).slideY(begin: 0.04)` after bars finish (delay 1300ms)
  - Eligibility strip slide-up: `.slideY(begin: 0.6, curve: Curves.easeOutCubic).fadeIn(220ms)` from screen bottom (320ms)
- **Hero**: incoming `ohs-gauge` Hero from FE-25 lands as the screen's hero header, then morphs to the 6-bar layout with a 320ms `easeInOutCubicEmphasized`.
- **Custom**: chart line draws stroke from left to right via `LineChartData.lineBarsData[0].dashArray = null` + a `lineLength` driver — 600ms `easeOutCubic` after bars finish.

## Haptics
- **selection** — bar tap, recommendation card tap, chart point tap
- **light** — recommendation CTA button press, eligibility strip CTA
- **medium** — bar fill animation completes (single confirmation when all 6 done)
- **heavy** — eligibility revoked transition

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `ohs.title` | "Operational Health" | "ऑपरेशनल हेल्थ" | "செயல்பாட்டு ஆரோக்கியம்" | "ఆపరేషనల్ హెల్త్" | "অপারেশনাল হেলথ" | "ऑपरेशनल हेल्थ" |
| `ohs.comp.scan_compliance` | "Scan compliance" | "स्कैन अनुपालन" | "ஸ்கேன் இணக்கம்" | "స్కాన్ సమ్మతి" | "স্ক্যান সম্মতি" | "स्कॅन अनुपालन" |
| `ohs.comp.expiry_hygiene` | "Expiry hygiene" | "एक्सपायरी स्वच्छता" | "காலாவதி தூய்மை" | "ఎక్స్‌పైరీ పరిశుభ్రత" | "মেয়াদ পরিচ্ছন্নতা" | "एक्स्पायरी स्वच्छता" |
| `ohs.comp.inventory_accuracy` | "Inventory accuracy" | "इन्वेंटरी सटीकता" | "சரக்கு துல்லியம்" | "ఇన్వెంటరీ ఖచ్చితత్వం" | "ইনভেন্টরি নির্ভুলতা" | "इन्व्हेंटरी अचूकता" |
| `ohs.comp.vendor_quality` | "Vendor quality" | "विक्रेता गुणवत्ता" | "விற்பனையாளர் தரம்" | "విక్రేత నాణ్యత" | "ভেন্ডর গুণমান" | "विक्रेता दर्जा" |
| `ohs.comp.task_completion` | "Task completion" | "कार्य पूर्णता" | "பணி நிறைவு" | "పని పూర్తి" | "কাজ সমাপ্তি" | "कार्य पूर्णता" |
| `ohs.comp.audit_pass_rate` | "Audit pass rate" | "ऑडिट पास दर" | "ஆடிட் வெற்றி விகிதம்" | "ఆడిట్ పాస్ రేట్" | "অডিট পাস হার" | "ऑडिट पास दर" |
| `ohs.recommend.scan_compliance` | "Most days had a 12-hr gap. Try a quick scan after every shift change." | "हर शिफ्ट के बाद स्कैन करें" | "ஷிஃப்ட் முடிவில் ஸ்கேன்" | "ప్రతి షిఫ్ట్ తర్వాత స్కాన్" | "প্রতিটি শিফটের পরে স্ক্যান" | "प्रत्येक शिफ्टनंतर स्कॅन" |
| `ohs.recommend.cta` | "Open {feature}" | "{feature} खोलें" | "{feature} திற" | "{feature} తెరవండి" | "{feature} খুলুন" | "{feature} उघडा" |
| `ohs.eligibility.in_days` | "Verified in {n} days at this rate" | "{n} दिनों में Verified" | "{n} நாட்களில் Verified" | "{n} రోజుల్లో Verified" | "{n} দিনে Verified" | "{n} दिवसांत Verified" |
| `ohs.eligibility.now` | "You're RADHA Verified" | "आप RADHA Verified हैं" | "நீங்கள் RADHA Verified" | "మీరు RADHA Verified" | "আপনি RADHA Verified" | "तुम्ही RADHA Verified" |
| `ohs.eligibility.revoked` | "Verified revoked" | "Verified रद्द" | "Verified ரத்து" | "Verified రద్దు" | "Verified বাতিল" | "Verified रद्द" |
| `ohs.empty.no_data` | "Not enough data yet — keep scanning" | "अभी डेटा कम है" | "தரவு போதாது" | "డేటా తక్కువ" | "ডেটা কম" | "डेटा कमी आहे" |

## Backend Integration
- **Endpoint**: `GET /api/v1/dashboard/client?storeId={uuid}` (BE-30 v2) — same payload that FE-25 fetches; this screen reuses Riverpod cache so no second network call on Hero arrival.
- **Endpoint**: `GET /api/v1/badges/me` (BE-52) for badge state — fetched in parallel on first mount; thereafter cached for the session.

### Response slice (OHS)
```typescript
export interface OhsDetailResponse {
  total: number;
  tier: OhsTier;
  components: Array<{
    kind: 'scan_compliance' | 'expiry_hygiene' | 'inventory_accuracy' | 'vendor_quality' | 'task_completion' | 'audit_pass_rate';
    score: number;             // 0..100
    weight: number;             // 0..1, sums to 1.0
    deltaSinceYesterday: number;
  }>;
  trend30d: Array<{ day: string; total: number }>;
  eligibility: {
    status: 'eligible_in_days' | 'issued' | 'revoked' | 'not_eligible';
    daysRemaining?: number;     // when 'eligible_in_days' or 'revoked' (cooldown)
  };
}
```

### Error code → UI mapping
| HTTP | UI |
|---|---|
| 200 | normal flow |
| 401 | force `/login` |
| 403 | banner + back to FE-25 |
| 5xx / network | serve cache; pin a "showing cached" banner |

## Charts & Data Viz
- **Library**: `fl_chart: ^0.66`
- **Type**: `LineChart`
- **Config**:
  - `lineTouchData: LineTouchData(enabled: true, handleBuiltInTouches: true, touchTooltipData: ...)`
  - `gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25)` — gridline at 25, 50, 75, 100
  - `axisTitleData` off; `titlesData` shows day-of-month every 5 days on x-axis
  - `lineBarsData[0]`: `isCurved: true, curveSmoothness: 0.32, barWidth: 2.5dp, dotData: FlDotData(show: false)`
  - `belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [tier.color.alpha60, tier.color.alpha0]))`
- **Animation**: `swapAnimationDuration: 600ms`, `swapAnimationCurve: Curves.easeOutCubic`. Triggered after bars finish (delay 1300ms from screen mount).
- **Accessibility (chart → table fallback)**: long-press on chart for ≥ 600ms opens a `DataTable` half-sheet with two columns *Day* and *Score*. The table is the canonical accessibility read-out. `Semantics(label: 'Trend chart, 30 days, current 78, peak 84 on March 12, low 62 on March 4')` on the chart container.
- **Reduced motion**: chart line drawn without entry animation; tooltip remains.
- **High contrast**: chart line stroke increases to 3dp; gradient fill replaced with hatched pattern.

## Accessibility
- Each `ComponentBar` exposes `Semantics(button: true, label: '{label}, score {score} of 100, weight {weight}%, {delta} since yesterday. Double tap to see how to improve.')`
- Focus order: hero → component bars (top-to-bottom) → chart → recommendations → eligibility strip
- Reduced motion path: bars fill instantly; chart line drawn without entry animation; eligibility Lottie disabled
- Dynamic type: bar labels wrap; recommendation cards expand vertically; chart legend moves below
- Long-press anywhere on the chart → table fallback (canonical accessibility read-out)
- `replayBars()` exposed via a debug 3-finger tap and via accessibility action "Replay animation"

## Testing
- **Widget tests**:
  - 6 bars rendered with correct stagger delays (0, 200, 400, 600, 800, 1000)
  - Score 0..100 → bar width 0..trackWidth
  - Tap on a bar scrolls the matching recommendation into view
  - Reduced motion path skips all animation
- **Golden tests**: 6 score profiles (all-green, all-amber, all-red, mixed-1, mixed-2, eligibility-revoked) × 3 device sizes = 18 goldens; chart goldens for 5/15/30 data points
- **Integration tests**:
  - Hero arrival from FE-25 produces a single fetch (Riverpod cache hit) and zero double-paint
  - Tap on "Improve scan compliance" pushes FE-27 with correct deep-link payload
  - Long-press on chart opens DataTable fallback and TalkBack reads it correctly

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | All six bars render in correct order matching weight desc |
| T2 | Stagger delays measured at 0, 200, 400, 600, 800, 1000 ms (±20 ms) |
| T3 | Bar fill animation completes in 1200ms ± 30ms |
| T4 | Color tier transitions at 60/75/90 boundaries |
| T5 | Chart renders 30 data points, last point matches `total` |
| T6 | Chart tooltip on tap shows `day + score` |
| T7 | Recommendation card lowest-component is visible without scrolling |
| T8 | Tap "Open Bulk Scan" from `scan_compliance` card routes to FE-27 |
| T9 | Eligibility strip shows correct days when `eligible_in_days` |
| T10 | Eligibility strip shows "RADHA Verified" when issued |
| T11 | Eligibility strip shows "Verified revoked" when revoked |
| T12 | Long-press on chart opens DataTable fallback |
| T13 | Reduced motion: bars fill instantly, no stagger, no chart entry animation |
| T14 | TalkBack reads OHS title → bars in order → chart summary → recommendations |
| T15 | Replaying bars (debug 3-finger tap) re-runs the stagger without re-fetch |

### Q&A (8)
1. How does the screen reuse FE-25's payload without making a second network call, and what happens if the cache is older than 5 minutes?
2. What is the precise rule for sorting components in the bar list — by raw score asc, by deficit-to-target, or by weight × deficit?
3. How is recommendation copy localized when the underlying scenario is dynamic (e.g., "12-hour gap" computed from data)?
4. How do we avoid double-animating bars when the user navigates back from a recommendation deep link?
5. What is the chart's behavior when there are < 7 days of data — do we show a sparser line or a "more soon" placeholder?
6. How does the eligibility countdown update when the OHS dropped below 75 yesterday — does it reset or pause?
7. What is the exact PostHog event taxonomy for "OHS detail viewed" and "recommendation acted on" so the funnel is measurable?
8. How is the chart redrawn on theme switch (light↔dark) without a frame drop?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; chart frame budget < 16.6 ms during entry
- [ ] Reviewer: Recommendation deep links route correctly; Hero in-flight from FE-25 has no double-paint
- [ ] Designer (motion review): Bar stagger and chart line draw approved on hardware
- [ ] PM: Recommendation copy reviewed in all 6 languages

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-26**
