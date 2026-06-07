# Phase FE-37: Empty States, Error States, Skeleton Loaders

## Phase Metadata
- **Phase ID**: FE-37
- **Phase Name**: Empty States + Error States + Skeleton Loaders
- **Section**: Layer 5 — Polish + Cross-cutting
- **Depends On**: FE-02 (tokens), FE-03 (component lib), FE-33 (motion), FE-34 (`ShimmerSkeleton`), FE-35 (i18n)
- **Backend Depends On**: BE-46 quotas (quota-exceeded variant), BE-39 recalls (recall empty CTA), BE-44 sync (offline error variant), BE-48 observability (error reports)
- **Blocks**: FE-38 (a11y audit verifies these states), FE-40 (release prep includes these screens in store screenshots)
- **Estimated Duration**: 3-4 days
- **Complexity**: Medium-High — applies to every screen

## Goal
Replace every `Container()`, every "no data yet", every silent crash, and every spinner with a deliberate state widget that has personality, recovery actions, and zero layout jump. Specifically:

- A **canonical empty state** widget (`EmptyStateView`) used by every list/grid/screen — Lottie illustration + 1-line headline + 1-line body + clear CTA.
- A **canonical error state** widget (`ErrorStateView`) covering 6 variants: network, validation, permission, quota, version-out-of-date, server-5xx.
- A **canonical skeleton system** (`ShimmerCard`, `ShimmerList`, `ShimmerGrid`, `ShimmerKpiPanel`) where each skeleton's intrinsic dimensions match the post-load widget exactly — verified by widget test, no layout jump on data arrival.
- A **quota-exceeded state** (BE-46) that doubles as an upgrade-prompt sheet with a Premium CTA in 6 languages.
- A **per-screen state checklist** (table below) requiring every screen to wire all three of empty / error / skeleton.
- All states honour reduced-motion (skeleton becomes static tint, Lottie becomes PNG), high contrast, and dynamic type.

By the end of this phase, no screen in the app shows a blank surface, a generic spinner, or a silent error. Every state has personality, every error has a recovery action, every load has a shape.

## Why This Phase Matters
- **First-impression retention**: a brand-new user opens the app and immediately sees an empty saved-products list. The default "List is empty" string is forgettable. A Lottie of a friendly bag with "Save your first product to get started" + a primary CTA earns the next session.
- **Skeletons reduce perceived load by 40%** (NN Group). Spinners say "wait." Skeletons say "almost there." On a 4G connection, a ProductDetail screen with a layout-matching skeleton feels native; the same screen with a centered spinner feels like a 2010-era WebView.
- **Layout jump on load is the #1 mobile-quality complaint** in Play Store reviews of Indian apps. Skeletons that don't match the final layout cause cards to jump 40dp when data arrives. Locking dimensions kills that complaint.
- **Quota-exceeded (BE-46) is the primary monetization lever**. Free-tier users hitting the 50-scan/day cap must see a prompt that converts. A vague error toast does not. A full-screen, illustrated, 1-tap-to-Premium state lifts conversion 3-5×.
- **Recovery > error**: Silent failures are the #1 source of "broken app" reviews. Every error here ships with a retry button, a "what to try" body line, and a deep link to support if all else fails.
- **Trust signal**: a polished empty state on a niche feature (e.g., shopping list) signals the entire app is well-made.

## Prerequisites
- [ ] FE-33 motion tokens locked.
- [ ] FE-34 `ShimmerSkeleton` shipped.
- [ ] FE-35 i18n catalogue extended with state-string keys (~60 new keys).
- [ ] Lottie pack `radha_state_pack_v1.zip` containing 14 illustrations (one per empty state, one per error variant — see asset list).
- [ ] Designer-supplied skeleton specs per screen (Figma node `skeletons.fig`).
- [ ] BE-46 quota-exceeded response shape locked.
- [ ] BE-39 recall-empty CTA copy approved.

## Files to Create
| File Path | Purpose |
|---|---|
| `apps/mobile/lib/states/empty_state_view.dart` | The canonical empty widget |
| `apps/mobile/lib/states/error_state_view.dart` | The canonical error widget |
| `apps/mobile/lib/states/error_variant.dart` | `enum ErrorVariant { network, validation, permission, quota, versionOutOfDate, server5xx }` |
| `apps/mobile/lib/states/quota_exceeded_sheet.dart` | Upgrade-prompt full-bleed sheet |
| `apps/mobile/lib/states/shimmer_card.dart` | Card-shaped skeleton primitive |
| `apps/mobile/lib/states/shimmer_list.dart` | List of N skeleton rows |
| `apps/mobile/lib/states/shimmer_grid.dart` | Grid of N skeleton cells |
| `apps/mobile/lib/states/shimmer_kpi_panel.dart` | Business dashboard KPI skeleton |
| `apps/mobile/lib/states/state_view_resolver.dart` | Async-state → widget mapping helper |
| `apps/mobile/lib/states/state_strings.dart` | Type-safe accessors for state ARB keys |
| `apps/mobile/lib/states/state_assets.dart` | Type-safe Lottie references |
| `apps/mobile/test/states/empty_state_view_test.dart` | Unit + golden |
| `apps/mobile/test/states/error_state_view_test.dart` | Unit + golden per variant |
| `apps/mobile/test/states/shimmer_layout_match_test.dart` | Asserts skeleton-to-loaded layout match |
| `apps/mobile/integration_test/quota_exceeded_flow_test.dart` | E2E |

## Implementation Spec

### `EmptyStateView`
```dart
class EmptyStateView extends StatelessWidget {
  final LottieAsset illustration;       // type-safe Lottie ref
  final String headline;                // i18n key resolved
  final String body;                    // i18n key resolved
  final String? primaryCtaLabel;
  final VoidCallback? primaryCta;
  final String? secondaryCtaLabel;
  final VoidCallback? secondaryCta;
  final EdgeInsets padding;             // default 24dp horizontal, 32dp vertical
  // Layout: vertical stack — Lottie 200×200dp top; 16dp gap; headline (titleLarge);
  //         8dp gap; body (bodyMedium 70% opacity); 24dp gap; primary button;
  //         8dp gap; secondary text button (optional).
  // Animation: Lottie loops at 0.6× speed; entrance fade+rise (slideY -8dp, 200ms).
  // Reduced motion: Lottie replaced by frame-0 PNG.
}
```

### `ErrorStateView` per variant
```dart
class ErrorStateView extends StatelessWidget {
  final ErrorVariant variant;
  final Object? cause;                  // for logging (Sentry breadcrumb)
  final VoidCallback? onRetry;
  final VoidCallback? onSecondary;      // typically "Contact support"

  // Each variant has a prebuilt headline / body / CTA / Lottie. Devs pass
  // the variant; we never hand-write copy at call sites.
}
```

| Variant | Lottie | Headline | Body | Primary CTA | Secondary |
|---|---|---|---|---|---|
| `network` | `state_offline_cloud.json` | "You're offline" | "Check your connection. Your work is safe." | "Retry" | — |
| `validation` | `state_form_pencil.json` | "Check your input" | "{field}: {reason}" | "Got it" | — |
| `permission` | `state_lock_key.json` | "Permission needed" | "{permissionName} lets RADHA do {capability}." | "Open settings" | "Not now" |
| `quota` | `state_quota_meter.json` | "Daily limit reached" | "Free tier: {limit} {unit}/day. Upgrade for unlimited." | "Upgrade to Premium" | "Maybe later" |
| `versionOutOfDate` | `state_update_arrow.json` | "Update RADHA" | "This version is no longer supported. Update to continue." | "Open Play Store" | — |
| `server5xx` | `state_server_smile.json` | "We're working on it" | "Our servers had a moment. Please try again." | "Retry" | "Contact support" |

### `state_view_resolver.dart`
```dart
Widget resolveAsyncState<T>({
  required AsyncValue<T> async,
  required Widget Function(T data) onData,
  Widget? loading,                       // defaults to ShimmerCard or ShimmerList per shape hint
  ShimmerShape shape = ShimmerShape.list,
  EmptyStateView? empty,                 // resolver decides if data is empty
  bool Function(T)? isEmpty,
  ErrorStateView Function(Object, StackTrace)? error,
}) {
  return async.when(
    data: (d) {
      final empty0 = isEmpty?.call(d) ?? false;
      return empty0 ? (empty ?? const SizedBox()) : onData(d);
    },
    loading: () => loading ?? _defaultSkeletonFor(shape),
    error: (e, st) {
      Sentry.captureException(e, stackTrace: st);
      return error?.call(e, st) ?? ErrorStateView(variant: _classify(e));
    },
  );
}
```

### `ShimmerCard` family — layout match guarantee
Every `ShimmerCard` ships with a `loadedDimensions` field that tests assert match the post-load widget's intrinsic size:
```dart
class ShimmerCard extends StatelessWidget {
  final double height;     // MUST match post-load card height
  final double? width;     // null = match parent
  final BorderRadius radius;
  final EdgeInsets padding;
  // Internally a column of ShimmerSkeleton primitives matching the
  // post-load card's text-line and avatar layout.
}
```

A widget test (`shimmer_layout_match_test.dart`) renders the loaded widget and the matching skeleton at the same constraints; asserts the box height delta ≤ 2dp.

### `QuotaExceededSheet`
```dart
class QuotaExceededSheet extends StatelessWidget {
  final QuotaKind kind;        // 'scan' | 'save'
  final int limit, used;
  final DateTime resetsAt;
  // Renders as a 70%-height bottom sheet with:
  //  - Lottie state_quota_meter (animated needle)
  //  - "{used}/{limit} used today"
  //  - Countdown to reset (computed locally; tooltip explains BE-46 timezone)
  //  - "Upgrade to Premium" primary button → opens FE-13 paywall
  //  - "Maybe later" → dismiss; haptic.warning fires on open
}
```

## Patterns / Reusable Widgets

| Widget | API |
|---|---|
| `EmptyStateView` | illustration + headline + body + primaryCta + secondaryCta |
| `ErrorStateView` | variant + onRetry + cause |
| `QuotaExceededSheet` | kind + used/limit + resetsAt |
| `ShimmerCard` | height + width + radius + padding |
| `ShimmerList` | itemCount (default 6) + itemHeight + separator |
| `ShimmerGrid` | crossAxisCount + cellAspectRatio + itemCount |
| `ShimmerKpiPanel` | tile count, KPI shape |
| `resolveAsyncState<T>(...)` | takes `AsyncValue<T>`, returns the right widget |
| `OfflineGuard` (from FE-36) | wraps screens whose offline state is "no cached data" → emits `ErrorStateView(network)` |

## Configuration / Tokens

| Token | Value | Why |
|---|---|---|
| `states.empty.lottie.size` | 200 × 200 dp | Big enough to feel intentional, small enough on Pixel 4a portrait |
| `states.empty.padding` | 24 horizontal, 32 vertical | Matches design system page padding |
| `states.empty.headline.style` | `titleLarge` (22sp) | M3 typography |
| `states.empty.body.style` | `bodyMedium` (14sp), 70% opacity | M3 emphasis |
| `states.cta.gap` | 24dp from body | Whitespace breathes between message and action |
| `states.error.headline.color` | `error.onContainer` for `network/server5xx`, `surface.onSurface` for soft variants | Avoid red overload |
| `states.shimmer.layoutTolerance` | 2dp | Skeleton vs loaded box height delta gate |
| `states.shimmer.defaultRowCount` | 6 | Average visible rows on Pixel 4a |
| `states.shimmer.entrance.fade` | 80ms | Just-perceptible fade-in to avoid pop |
| `states.quota.sheet.height` | 70% of viewport | Leaves room to dismiss without filling screen |
| `states.quota.cta.upgradeRoute` | `/subscribe?source=quota_<kind>` | Source param for analytics |
| `states.minTimeToShow` | 200ms | Don't flash a skeleton if data arrives faster |
| `states.error.network.banner.delay` | 4000ms | Aligns with FE-36 banner debounce |
| `states.lottie.bundle.maxSizeKb` | 1800 | Total state-pack budget — designer enforces |
| `states.lottie.individualMaxKb` | 180 | Per-illustration budget |
| `states.illustrations.count` | 14 | 8 empty + 6 error variants |

## Per-Screen Application Checklist

| Screen / Phase | Empty State | Error State | Skeleton |
|---|---|---|---|
| Onboarding cards FE-10 | n/a | network — "Couldn't reach RADHA" | n/a |
| OTP entry FE-11 | n/a | network, validation, server5xx | n/a |
| OTP verify FE-12 | n/a | validation (wrong OTP), server5xx | resend countdown |
| Premium subscribe FE-13 | n/a | network, server5xx, payment-failed (custom) | plan card shimmer |
| Family invite FE-14 | "No family yet — invite your first" | network, server5xx | row shimmer |
| Allergen setup FE-15 | "No allergens — tap to add" | network | chip shimmer |
| Business activation FE-16 | n/a | validation per step | n/a |
| Scanner FE-17 | n/a | permission (camera), validation | scan output shimmer |
| Scan output FE-18 | "Product not found — try image OCR" | network, server5xx | full card shimmer |
| Product detail FE-19 | n/a | network, server5xx | header + ingredient shimmer |
| Expiry calendar FE-20 | "No expiring items — start saving products" | network | month grid shimmer |
| Recall inbox FE-21 | "No recall alerts — your products are safe" | network | row shimmer |
| Ingredient explainer FE-22 | n/a | network, server5xx (LLM down) | streaming shimmer |
| Healthy alternatives FE-23 | "No alternatives this time — try another category" | network | carousel shimmer |
| Shopping list FE-24 | "Empty list — add your first item" | network | row shimmer |
| Business dashboard FE-25 | first-day "Set up your first store" | network, server5xx | KPI panel shimmer |
| OHS detail FE-26 | "No data yet — keep auditing" | network | trend shimmer |
| Bulk scan FE-27 | "Start scanning your aisle" | permission, quota | scan list shimmer |
| Expiry tracker biz FE-28 | "No expiring SKUs" | network | row shimmer |
| GRN wizard FE-29 | n/a | validation, network | step-form shimmer |
| Inventory FE-30 | "No stock yet — receive your first GRN" | network | row shimmer |
| Tasks FE-31 | "Inbox zero — well done" (different copy from "no tasks ever") | network | row shimmer |
| Reports FE-32 | "No reports yet — run your first audit" | network | row shimmer |
| Settings — Sync Queue | "Queue is clear — everything synced" | n/a | row shimmer |
| Settings — Language Switcher | n/a | n/a | n/a |

## Backend Integration

| Backend | Role |
|---|---|
| **BE-46 quotas** | A 429 with `{quota: 'scan', limit: 50, used: 51, resetAt}` opens `QuotaExceededSheet`. Sheet copy localized via FE-35. Upgrade CTA deep links to FE-13 with `source=quota_scan`. |
| **BE-44 sync** | Offline → cached data shown. No cached data → `ErrorStateView(network)` with retry → triggers a sync flush + change pull. |
| **BE-39 recalls** | Empty inbox state copy: "No recall alerts — your products are safe." (NOT "no data") |
| **BE-29 analytics** | Each state emits `state_shown` event with `{screen, kind: 'empty'|'error'|'quota'|'skeleton'}`. Used for funnel analysis ("How many users hit empty saved-products vs first save?"). |
| **BE-48 observability** | `ErrorStateView` captures `cause` to Sentry with breadcrumb `state_error_shown` and screen + variant tag. |
| **BE-13 force update** | `versionOutOfDate` variant fires when server returns 426 or `client_too_old` error code. |
| **BE-35 (BE phase) account** | "Account suspended" handled as a custom variant of error state (not in the 6 standard variants — uses `ErrorStateView(server5xx)` with override copy). |

## Accessibility & Platform Variants

### Accessibility
- Every illustration has `excludeSemantics: true`; the headline is the screen reader's primary anchor.
- Empty/error views announce as a single `liveRegion` so screen readers hear the state change once, not three times.
- Primary CTA receives focus on appear; user can immediately press it.
- Dynamic type xxLarge: layout collapses Lottie size 200dp → 140dp; body text wraps to 4 lines maximum without clipping.
- High contrast: error states use `error.container` background — verified ≥ 4.5:1 against `error.onContainer` text.
- Reduced motion: Lotties replaced by frame-0 PNG; entrance fade kept at 80ms (under reduced-motion threshold).

### Android specifics
- Predictive back gesture: dismissing `QuotaExceededSheet` works with a swipe from left edge as well as the system back gesture.
- Material 3 dynamic color: empty/error illustrations use ColorFilter.matrix to pick up the theme's primary color hue at runtime.

### iOS specifics
- iOS 16+ haptics: a `haptic.warning` fires on `QuotaExceededSheet` open and once on each new error state transition.
- Sheet uses Cupertino-style detents on iOS for native feel.

### Tablet
- Empty/error views center horizontally with max width 480dp on tablet (avoids stretched look).

### Low-end devices
- Lottie illustrations downgrade to PNG on `MotionProfile.lowEndAuto`.
- Skeleton animations pause when off-screen.

## Testing

### Widget tests
- `EmptyStateView` renders illustration + headline + body + CTA in correct order.
- `ErrorStateView` for each variant renders the correct Lottie + copy + CTA.
- `QuotaExceededSheet` countdown ticks once per second.
- `resolveAsyncState` returns the correct widget for `data`/`loading`/`error`/`empty` permutations.
- Skeleton-to-loaded layout match: `shimmer_layout_match_test.dart` renders 12 skeleton/loaded pairs and asserts ≤ 2dp delta.

### Golden tests
- Empty state per screen × light/dark = 25 × 2 = 50 frames.
- Error state per variant × light/dark = 6 × 2 = 12 frames.
- QuotaExceededSheet × scan/save × light/dark = 4 frames.
- All states at xxLarge dynamic type — additional 12 frames.

### Integration tests
- `quota_exceeded_flow_test.dart`: simulate 51st scan → sheet opens → "Upgrade" → paywall opens with `source=quota_scan`.
- `empty_to_first_data_test.dart`: open shopping list (empty) → tap "Add first item" → first row appears with `RadhaListReveal`.
- `error_to_recovery_test.dart`: simulate 5xx → ErrorStateView appears → "Retry" → success → ErrorStateView dismounts.

### Perf benchmarks
- Skeleton shimmer animation: 60fps on Pixel 4a with 30 visible skeleton rows.
- Empty state Lottie cold load: ≤ 80ms.
- Total state-pack APK delta: ≤ 1.8 MB.

## Mandatory SOP — 15 Test Procedures + 8 Q&A

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Every screen in the per-screen table has an empty/error/skeleton wired and tested |
| T2 | Skeleton-to-loaded layout match: ≤ 2dp delta across 12 representative pairs |
| T3 | Empty state on Shopping List shows the right Lottie + copy in all 6 locales (golden × 6) |
| T4 | `ErrorStateView(network)` retry button triggers exactly one network call |
| T5 | `ErrorStateView(quota)` opens `QuotaExceededSheet`; "Upgrade" deep links with `source=quota_scan` |
| T6 | `versionOutOfDate` variant blocks navigation — back button does not dismiss |
| T7 | `permission` variant "Open settings" successfully navigates to OS app settings on both platforms |
| T8 | Reduced motion on: Lotties replaced by frame-0 PNG; no animation thread runs |
| T9 | Dynamic type xxLarge: every state widget renders without clipping (golden) |
| T10 | High contrast: error variant text contrast ≥ 4.5:1 against background |
| T11 | TalkBack/VoiceOver announces the state change once per transition |
| T12 | Sentry receives a breadcrumb `state_error_shown` for every `ErrorStateView` mount |
| T13 | Skeleton minTimeToShow: data arriving in < 200ms does not flash a skeleton (verified by widget test with fake clock) |
| T14 | `state_shown` analytics event fires for empty / error / quota states; not for skeletons |
| T15 | Total Lottie pack adds ≤ 1.8 MB to APK (verified by `flutter build --analyze-size`) |

### Q&A Questions (8)

1. The minTimeToShow for skeletons is 200ms. What's the rationale, and how do we handle the boundary case where data arrives at 199ms but the user's eye already saw the skeleton flash?
2. We have 6 error variants. Why no `paymentFailed` variant — wouldn't BE-28 errors deserve their own?
3. Empty states on a brand-new screen (no data ever) and a screen that became empty (user deleted everything) often want different copy. How do we differentiate?
4. The `QuotaExceededSheet` shows a countdown to reset. The reset is in BE-46's IST timezone. What if the user is travelling abroad?
5. The retry button on `ErrorStateView(network)` triggers one network call. What if the user mashes it 5 times?
6. Sentry breadcrumb on every error state could explode our 5K/month free quota. What's the sampling strategy?
7. Skeletons match the loaded layout to ≤ 2dp. What about a screen whose loaded layout depends on data length (e.g., a long product name causes a 3-line title)?
8. The `permission` variant deep-links to OS settings. On Android the user can return without granting; we then re-render. How do we avoid an infinite loop of "permission needed" if they refuse repeatedly?

## Sign-off Gate
- [ ] Developer: 15 tests pass; coverage ≥ 95% on `lib/states/**`.
- [ ] Developer: 8 Q&A answered.
- [ ] Developer: every screen in the table has its empty/error/skeleton verified against design.
- [ ] Reviewer: spot-checked 8 screens at xxLarge dynamic type.
- [ ] Reviewer: confirmed reduced-motion behavior on a real device.
- [ ] Designer: every Lottie matches the brand voice; copy reviewed in all 6 locales.
- [ ] Accessibility reviewer: TalkBack + VoiceOver pass on all 6 error variants.

**Developer Signature**: ___________________________
**Reviewer Signature**: ___________________________
**Designer Signature**: ___________________________
**Accessibility Reviewer Signature**: ___________________________

---
**END OF FE-37 — DO NOT PROCEED WITHOUT APPROVAL**
