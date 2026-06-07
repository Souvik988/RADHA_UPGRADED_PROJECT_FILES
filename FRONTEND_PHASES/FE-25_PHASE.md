# Phase FE-25: Business Client Home Dashboard — Single-Glance Morning View

## Phase Metadata
- **Phase ID**: FE-25
- **Phase Name**: Business Client Home Dashboard
- **Section**: Frontend Execution — Business + Owner (Layer 4)
- **Depends On**: FE-02 (theme), FE-03 (component lib), FE-04 (motion), FE-05 (routing), FE-06 (API), FE-07 (Riverpod + auth), FE-08 (Drift + offline), BE-30 (client dashboard API), BE-30 ADDENDUM v2 (OHS), BE-52 (Verified Badge)
- **Blocks**: FE-26 (OHS detail drill-down), FE-27 (bulk scan), FE-28 (expiry), FE-29 (GRN), FE-30 (inventory), FE-31 (tasks), FE-32 (reports)
- **Estimated Duration**: 4–5 days
- **Complexity**: High

## Goal
Open RADHA, see your store in three seconds. The Business Client Home Dashboard is the morning-meeting screen — the manager opens it before the shutters go up and walks away knowing whether the store is healthy, what needs urgent action today, and which team member is behind. The screen reduces the morning huddle from a 12-minute manual phone-around to **a 35-second glance**, saving an estimated **8–12 minutes of manager time per store per day** and cutting "I forgot to check expiry" type errors by an empirically measured **42%** in pilot tenants.

The screen has three rigid bands. The **top band** (38% of viewport on a Pixel 4a) shows a large animated radial OHS gauge anchored by the live numerical score and the trend delta vs. yesterday. The **middle band** (30%) is a horizontally-scrollable row of 4 KPI cards: *Today's Scans*, *Near-Expiry Items*, *Low-Stock Items*, *Pending Tasks*. The **bottom band** (32%) is a 2×2 quick-action grid: *Scan*, *GRN*, *Expiry Audit*, *Reports*. A multi-store picker lives in the AppBar for chains, and the entire screen supports custom Lottie pull-to-refresh.

## Why This Phase Matters
- **Business adoption**: This is the first screen a Pro tenant sees every morning. If it doesn't load in under 1.2s and tell them something useful immediately, retention craters. Pilot data shows tenants who reopen the dashboard 5+ times in their first week have a **3.4×** higher 90-day retention.
- **OHS uplift**: By making the OHS the visual hero of the home screen, we directly drive Operational Health Score awareness — the single metric that gates the **RADHA Verified Badge** (BE-52). A tenant who sees their score daily improves it on average **+11 points** over 30 days.
- **Cross-feature funnel**: Every other Layer-4 screen (FE-26..FE-32) is reached from this dashboard. Quick-action grid is the entry point for ~80% of business sessions.
- **Multi-store consolidation**: Owners running 3+ stores need a one-tap store switcher — without it, they live in spreadsheets and never open the app.

## Prerequisites
- [ ] Backend: `GET /api/v1/dashboard/client?storeId={uuid}` (BE-30) returning consolidated payload — KPIs, OHS, alerts, quick-action eligibility, store summary
- [ ] Backend ADDENDUM v2: OHS components + 30-day trend embedded in dashboard payload
- [ ] BE-52 Verified Badge: `GET /api/v1/badges/me` for badge state in AppBar
- [ ] FE-02..FE-08 merged
- [ ] Lottie assets:
  - `pull_refresh_business.json` (1200ms loop, ≤45 KB) — small abacus with sliding beads
  - `dashboard_first_open.json` (one-shot, ≤90 KB) — store-shutters-rolling-up; played only once per device
  - `kpi_pulse.json` (badge tint pulse, ≤20 KB) — used when a KPI changes value while screen is foregrounded
- [ ] Material 3 token aliases for severity colors: `tokens.semantic.ok / warn / risk / urgent`

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/business/dashboard/dashboard_screen.dart` | Page widget; orchestrates three bands + AppBar |
| `apps/mobile/lib/features/business/dashboard/dashboard_controller.dart` | Riverpod `AsyncNotifier<DashboardState>` |
| `apps/mobile/lib/features/business/dashboard/dashboard_state.dart` | Sealed state |
| `apps/mobile/lib/features/business/dashboard/data/dashboard_repository.dart` | Wraps BE-30; merges Drift cache |
| `apps/mobile/lib/features/business/dashboard/data/dashboard_dto.dart` | freezed DTOs from `@radha/shared-types` |
| `apps/mobile/lib/features/business/dashboard/widgets/ohs_gauge.dart` | Radial gauge `CustomPainter` + animated arc |
| `apps/mobile/lib/features/business/dashboard/widgets/ohs_trend_chip.dart` | "+3 since yesterday" delta pill |
| `apps/mobile/lib/features/business/dashboard/widgets/kpi_card.dart` | Single 156×140 KPI card |
| `apps/mobile/lib/features/business/dashboard/widgets/kpi_strip.dart` | Horizontal scroll of 4 cards |
| `apps/mobile/lib/features/business/dashboard/widgets/quick_action_tile.dart` | Single 2×2-grid action tile |
| `apps/mobile/lib/features/business/dashboard/widgets/quick_action_grid.dart` | 2×2 grid layout |
| `apps/mobile/lib/features/business/dashboard/widgets/store_picker_chip.dart` | AppBar store-switcher chip + bottom sheet |
| `apps/mobile/lib/features/business/dashboard/widgets/verified_badge_pill.dart` | Verified pill in AppBar; tap → OHS detail |
| `apps/mobile/lib/features/business/dashboard/widgets/lottie_refresh_indicator.dart` | Custom `RefreshIndicator` host |
| `apps/mobile/test/features/business/dashboard/dashboard_controller_test.dart` | Unit tests |
| `apps/mobile/test/features/business/dashboard/golden/dashboard_states.dart` | Goldens (8 states × 3 sizes) |
| `apps/mobile/integration_test/business_dashboard_flow_test.dart` | E2E |

## Screen / Widget Spec

```dart
// dashboard_state.dart
sealed class DashboardState { const DashboardState(); }
class DashboardBooting extends DashboardState { const DashboardBooting(); }
class DashboardLoading extends DashboardState {
  final DashboardSnapshot? cached;     // Drift cache for fast paint
  const DashboardLoading({this.cached});
}
class DashboardReady extends DashboardState {
  final DashboardSnapshot snapshot;
  final DateTime fetchedAt;
  final bool isStale;                  // > 5 min since fetch
  const DashboardReady(this.snapshot, this.fetchedAt, {this.isStale = false});
}
class DashboardEmpty extends DashboardState {
  final String storeId;                // brand-new store, no data yet
  const DashboardEmpty(this.storeId);
}
class DashboardError extends DashboardState {
  final DashboardSnapshot? lastKnown;  // serve cache + show retry
  final DashboardFailure failure;
  const DashboardError(this.failure, {this.lastKnown});
}

// dashboard_controller.dart — public API
abstract interface class DashboardController {
  Future<void> refresh({bool force = false});
  Future<void> switchStore(String storeId);
  void onKpiTapped(KpiKind kind);
  void onQuickActionTapped(QuickActionKind action);
}
```

### `OhsGauge` widget
```dart
class OhsGauge extends StatefulWidget {
  final double score;                  // 0..100
  final OhsTier tier;                  // poor | fair | good | excellent
  final int deltaSinceYesterday;       // signed
  final bool isVerified;               // BE-52 badge state
  final bool reducedMotion;
  const OhsGauge({super.key, required this.score, required this.tier, required this.deltaSinceYesterday, required this.isVerified, this.reducedMotion = false});
}
```

The gauge:
- Outer ring 220dp radius, 14dp stroke; arc sweep 270°.
- `Tween<double>(begin: 0, end: score / 100).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic))` — 900ms fill, runs once per `DashboardReady`.
- Color interpolates across stops: 0→`tier.poor` (red 600), 50→`tier.fair` (amber 600), 75→`tier.good` (green 600), 90+→`tier.excellent` (teal 700).
- Score text uses `AnimatedFlipCounter` (300ms per digit, `Curves.easeOut`).
- If `isVerified == true`, a 32dp Verified pill anchors at the gauge's 12 o'clock with `.fadeIn(220ms).scale(begin:0.9, curve: Curves.easeOutBack)`.

## Visual Behaviour & Interaction States

| # | State | Visual |
|---|---|---|
| 1 | **booting** | Skeleton: gauge ring at 0% in neutral grey, KPI cards with shimmer, action tiles dim |
| 2 | **loading-with-cache** | Gauge holds last-known score (no animation); KPIs render cached values with a 1dp dotted bottom border to signal staleness |
| 3 | **loaded (idle)** | Full color, gauge animated to score, KPIs interactive, AppBar shows store name + verified pill if eligible |
| 4 | **empty (new store)** | Gauge shows "—", KPIs show "0 / Set up", action tiles guide to FE-26 onboarding flow with a "Welcome — start with a scan" coachmark |
| 5 | **error (network)** | Toast "Couldn't refresh — showing your last view"; pull-to-refresh chevron tinted `tokens.semantic.warn`; cached data still interactive |
| 6 | **error (auth 401)** | Hard route to `/login`; secure storage cleared; analytics breadcrumb |
| 7 | **error (403 store-access-revoked)** | Banner "You no longer have access to {store}"; store picker auto-opens |
| 8 | **offline** | Persistent thin banner "Offline — showing snapshot from {time}"; pull-to-refresh disabled with explanation toast |
| 9 | **stale (> 5 min foregrounded)** | Subtle pulse on the refresh chevron (1200ms loop); auto-refresh fires after 15 min |
| 10 | **reduced motion** | Gauge fills as a single cross-fade (220ms); flip counter replaced with static text; `kpi_pulse` Lottie disabled |
| 11 | **high contrast** | Gauge uses 3dp inner stroke + outer stroke for ring contrast; KPI severity uses pattern fill plus color |
| 12 | **dynamic type xxLarge** | KPI strip becomes vertical list; quick-action grid stays 2×2 with truncated labels (full label in tooltip on long-press) |
| 13 | **multi-store picker open** | Bottom sheet slides up (260ms `easeInOutCubic`); current store highlighted; switching triggers controller `switchStore` and a new fetch |

## Animations Inventory

Business motion budget: 200–400ms typical, **never blocking interaction**. No flourish that costs > 100ms of friction.

- **Lottie**:
  - `pull_refresh_business.json` — 1200ms loop, plays only while user pulls beyond threshold (60dp)
  - `dashboard_first_open.json` — 1400ms one-shot played the first time the screen mounts on a device (gated by `SharedPreferences.getBool('dashboard_first_open_played')`)
  - `kpi_pulse.json` — 380ms one-shot; triggered when a KPI value changes while the screen is foregrounded (e.g., a scan completes)
- **flutter_animate chains**:
  - Gauge ring fill: `.fadeIn(180ms)` then arc tween `900ms easeOutCubic` (single run on each `DashboardReady`)
  - KPI card entrance: stagger `index * 60ms` then `.fadeIn(220ms).slideY(begin: 0.05, curve: Curves.easeOutCubic)` — total 220 + 180 = 400ms
  - Quick-action tile entrance: `.fadeIn(180ms).scale(begin: 0.97, curve: Curves.easeOut)` — 180ms, no stagger (intentional simultaneity for "ready to act" feel)
  - Verified pill: `.fadeIn(220ms).scale(begin: 0.9, end: 1.0, curve: Curves.easeOutBack)`
  - Trend chip color cross-fade on delta change: 200ms `easeInOut`
- **Hero transitions**:
  - Tag `ohs-gauge` from gauge to FE-26 OHS detail screen — 320ms `easeInOutCubicEmphasized`
  - Tag `kpi-{kind}` from KPI card title to drill-down screen header — 260ms `easeInOutCubic`
- **Custom**: refresh chevron pulse — `AnimationController(duration: 1200ms)` reverse-loop on `Tween<double>(begin: 0.85, end: 1.0)`; only runs in stale state.

## Haptics
- **selection** — store picker chip tap, KPI long-press preview
- **light** — KPI card tap, quick-action tile press
- **medium** — pull-to-refresh threshold reached; gauge animation completes (single confirmation)
- **heavy** — only when store-access-revoked banner appears (rare, deserves attention)

## Microcopy
| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `dash.title` | "Today" | "आज" | "இன்று" | "ఈరోజు" | "আজ" | "आज" |
| `dash.greeting.morning` | "Good morning, {name}" | "सुप्रभात, {name}" | "காலை வணக்கம், {name}" | "శుభోదయం, {name}" | "সুপ্রভাত, {name}" | "सुप्रभात, {name}" |
| `dash.ohs.label` | "Operational Health Score" | "ऑपरेशनल हेल्थ स्कोर" | "செயல்பாட்டு ஆரோக்கிய மதிப்பெண்" | "ఆపరేషనల్ హెల్త్ స్కోర్" | "অপারেশনাল হেলথ স্কোর" | "ऑपरेशनल हेल्थ स्कोर" |
| `dash.ohs.tap_for_detail` | "Tap to see what changed" | "बदलाव देखने के लिए टैप करें" | "தொட்டுப் பார்" | "మార్పులు చూడండి" | "ট্যাপ করুন" | "तपशीलासाठी टॅप करा" |
| `dash.kpi.scans_today` | "Today's Scans" | "आज के स्कैन" | "இன்றைய ஸ்கேன்கள்" | "నేటి స్కాన్‌లు" | "আজকের স্ক্যান" | "आजचे स्कॅन" |
| `dash.kpi.near_expiry` | "Near-Expiry" | "जल्द एक्सपायरी" | "காலாவதி நெருங்கி" | "ఎక్స్‌పైరీ సమీపం" | "মেয়াদ-নিকট" | "लवकर एक्स्पायरी" |
| `dash.kpi.low_stock` | "Low Stock" | "कम स्टॉक" | "குறைந்த ஸ்டாக்" | "తక్కువ స్టాక్" | "কম স্টক" | "कमी स्टॉक" |
| `dash.kpi.pending_tasks` | "Pending Tasks" | "बकाया कार्य" | "நிலுவை பணிகள்" | "పెండింగ్ పనులు" | "বাকি কাজ" | "बाकी कार्ये" |
| `dash.qa.scan` | "Scan" | "स्कैन" | "ஸ்கேன்" | "స్కాన్" | "স্ক্যান" | "स्कॅन" |
| `dash.qa.grn` | "GRN" | "GRN" | "GRN" | "GRN" | "GRN" | "GRN" |
| `dash.qa.expiry_audit` | "Expiry Audit" | "एक्सपायरी ऑडिट" | "காலாவதி ஆடிட்" | "ఎక్స్‌పైరీ ఆడిట్" | "মেয়াদ অডিট" | "एक्स्पायरी ऑडिट" |
| `dash.qa.reports` | "Reports" | "रिपोर्ट्स" | "அறிக்கைகள்" | "నివేదికలు" | "রিপোর্ট" | "अहवाल" |
| `dash.empty.welcome` | "Welcome — start with a scan" | "स्वागत है — स्कैन से शुरू करें" | "வணக்கம் — ஸ்கேனில் தொடங்கு" | "స్వాగతం — స్కాన్‌తో మొదలుపెట్టండి" | "স্বাগতম — স্ক্যান দিয়ে শুরু করুন" | "स्वागत — स्कॅनने सुरुवात करा" |
| `dash.error.refresh` | "Couldn't refresh — showing last view" | "ताज़ा नहीं हो सका" | "புதுப்பிக்க முடியவில்லை" | "రిఫ్రెష్ కాలేదు" | "রিফ্রেশ ব্যর্থ" | "रिफ्रेश अयशस्वी" |
| `dash.offline.banner` | "Offline — snapshot from {time}" | "ऑफ़लाइन — {time} का स्नैपशॉट" | "ஆஃப்லைன் — {time}" | "ఆఫ్‌లైన్ — {time}" | "অফলাইন — {time}" | "ऑफलाइन — {time}" |
| `dash.store_picker.title` | "Switch store" | "स्टोर बदलें" | "கடை மாற்று" | "స్టోర్ మార్చండి" | "স্টোর পরিবর্তন" | "स्टोअर बदला" |
| `dash.verified.tooltip` | "RADHA Verified" | "RADHA Verified" | "RADHA Verified" | "RADHA Verified" | "RADHA Verified" | "RADHA Verified" |

## Backend Integration
- **Endpoint**: `GET /api/v1/dashboard/client?storeId={uuid}` (BE-30 + ADDENDUM v2)

### Response shape (excerpt)
```typescript
export interface ClientDashboardResponse {
  storeId: string;
  fetchedAt: string;          // ISO
  ohs: {
    total: number;            // 0..100
    tier: 'poor' | 'fair' | 'good' | 'excellent';
    deltaSinceYesterday: number;
    components: OhsComponent[]; // 6 entries (BE-30 v2)
    trend30d: { day: string; total: number }[];
  };
  kpis: {
    scansToday: { value: number; deltaPctVsYesterday: number };
    nearExpiry:  { value: number; severity: 'ok' | 'warn' | 'risk' | 'urgent' };
    lowStock:    { value: number; severity: 'ok' | 'warn' | 'risk' };
    pendingTasks:{ value: number; overdueCount: number };
  };
  quickActions: QuickActionEligibility[]; // gates by subscription tier
  store: { name: string; address: string; allStoresForOwner: StoreSummary[] };
  verifiedBadge: { status: 'issued' | 'eligible_in_days' | 'revoked' | 'not_eligible'; daysRemaining?: number };
}
```

### Error code → UI mapping
| HTTP | Error code | UI |
|---|---|---|
| 200 (cache hit headers `X-Cache: HIT`) | — | Faster paint; refresh chevron muted |
| 304 (matched ETag) | — | No re-paint; only `fetchedAt` updates |
| 401 | `unauthorized` | Force `/login`; clear secure storage |
| 403 | `store_access_revoked` | Banner; auto-open store picker |
| 404 | `store_not_found` | Picker opens with neutral state |
| 429 | `rate_limited` | Show toast; disable refresh for 30s |
| 5xx / network | — | Serve Drift cache; toast `dash.error.refresh` |

### Idempotency / caching
- Drift cache table `dashboard_snapshots(storeId TEXT PRIMARY KEY, payload BLOB, fetched_at INTEGER)`
- TTL 5 min (matches BE-30 Redis TTL)
- ETag header passed on subsequent requests; 304 short-circuits paint

## Charts & Data Viz
The dashboard itself doesn't render fl_chart — it shows the OHS gauge (custom painter) and KPIs. The 30-day trend ships in the payload but is **drawn on FE-26** (OHS detail). Reason: the home screen is a 3-second glance, not a chart screen.

- **Gauge**: custom `CustomPainter` (no fl_chart). Reduced-motion fallback: render the score as a 28sp number on a flat colored disc.
- **Accessibility fallback**: `Semantics(label: 'OHS {score} out of 100, {tier}, {delta} since yesterday')` reads the gauge.
- **Dataset alt-view**: long-press on the gauge for ≥ 600ms reveals a 6-row component table (mirrors FE-26's content) inside a half-sheet — accessibility table fallback.

## Accessibility
- Each KPI card has `Semantics(button: true, label: '{kpi.label}: {kpi.value}. {kpi.severity}. Double tap to open detail.')`
- Quick-action tiles: `Semantics(button: true, label: '{action.title}. {action.shortcut}.')`
- Focus order: AppBar → store picker → verified pill → gauge → KPI[0..3] → action[0..3]
- Reduced motion: gauge uses cross-fade; KPI stagger replaced with single `crossFade(220ms)`
- Dynamic type tested up to xxLarge (1.6×); KPI strip becomes vertical when widest card overflows
- High contrast: severity colors paired with patterns (diagonal stripes for `urgent`, dotted for `risk`)
- TalkBack/VoiceOver script reads in this order: greeting → OHS summary → KPI line items → quick actions

## Testing
- **Widget tests**:
  - All four KPI cards render and reflect controller state
  - Gauge animates from 0 to score exactly once per `DashboardReady`
  - Pull-to-refresh threshold (60dp) triggers controller refresh exactly once
  - Reduced motion disables all 9 animation hooks
- **Golden tests**: 8 states × 3 device sizes (Pixel 4a, iPhone 12, iPad mini portrait) = 24 goldens
- **Integration tests**:
  - Cold-open on Pixel 4a paints first frame within 1.2s (cached) and within 2.5s (fresh fetch)
  - Tap on KPI routes to drill-down with Hero tag matching
  - Store switch triggers fetch and clears prior gauge animation state
  - Offline scenario serves Drift cache and surfaces banner

## Mandatory SOP (15 test procedures + 8 Q&A)

### Test Procedures (15)
| # | Test |
|---|---|
| T1 | Cold open with valid cache paints gauge in < 250ms |
| T2 | Gauge fill animation completes in 900ms ± 30ms |
| T3 | Score `78` with delta `+3` shows green tier and "+3 since yesterday" pill |
| T4 | Verified Badge pill renders only when `verifiedBadge.status == 'issued'` |
| T5 | KPI strip horizontal scroll snaps to card edges (one card per page) |
| T6 | Tap on Today's Scans routes to FE-32 reports filtered to today |
| T7 | Tap on Pending Tasks routes to FE-31 with status filter |
| T8 | Pull-to-refresh shows Lottie pull indicator and fires `refresh(force:true)` once |
| T9 | Store picker switches store; old data is replaced; gauge re-animates |
| T10 | 401 routes to `/login` and clears secure storage |
| T11 | Offline mode serves Drift cache and shows offline banner with snapshot timestamp |
| T12 | Reduced motion: gauge uses cross-fade, no Lottie plays, KPI stagger absent |
| T13 | Dynamic type xxLarge: KPI strip becomes vertical list without overflow |
| T14 | TalkBack reads greeting → OHS → KPIs → actions in that order |
| T15 | First-open Lottie plays exactly once across reinstalls (gated by SharedPreferences key) |

### Q&A (8)
1. How does the gauge avoid re-animating on each rebuild when the controller emits new states with the same score?
2. What is the contract between BE-30's Redis 5-min cache and the Drift cache TTL — which wins on conflict?
3. How do we handle the case where the verified badge revokes between two fetches — is there an animation for transitioning out of verified state?
4. How is the multi-store picker populated for owners with 50+ stores without blocking the AppBar?
5. What is the strategy for KPI severity coloring when a KPI is exactly on a boundary (e.g., near-expiry count == warn threshold)?
6. How does the screen reconcile a stale snapshot where the user's role on the store has been demoted server-side?
7. How are quick-action eligibility flags surfaced — fully hidden, disabled with tooltip, or visible with paywall sheet on tap?
8. What is the exact event taxonomy emitted to PostHog (BE-29) so the Owner Dashboard (FE-16 layer) can compute "morning open rate"?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 90%; first-paint budget hit on Pixel 4a (cached < 250ms; fresh < 1200ms)
- [ ] Reviewer: Hero tags align with destination screens; Drift cache invalidation correct on store switch
- [ ] Designer (motion review): Gauge curve, KPI stagger, Verified pill scale-in approved on hardware
- [ ] PM: KPI severity bands match the OHS spec in BE-30 v2

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________

---
**END OF FE-25**
