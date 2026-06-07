# Phase FE-18: Comprehensive Scan Output Screen

## 1. Phase Metadata

- **Phase ID**: FE-18
- **Phase Name**: Comprehensive Scan Output Screen
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-17 (scanner Hero), FE-04 (theme), FE-09 (haptics), BE-10 v2 (scan), BE-12 v2 (health score), BE-40 (ingredient explainer), BE-41 (alternatives), BE-56 (report wrong info)
- **Blocks**: FE-19 (Product Detail), FE-22 (Explainer Modal), FE-23 (Alternatives Carousel)
- **Estimated Duration**: 4 days
- **Complexity**: High (the "money screen" — many states, nested animations)

## 2. Goal (Engagement Angle)

This is the screen that converts a curious shopper into a daily user. Within 1.2 seconds of the scan firing, the user must see: a clear health verdict, an obvious allergen warning if relevant, a tappable nutrition table, ingredients that beg to be tapped, and three smarter alternatives. The page **earns the next scan**: every section is engineered for thumb-stopping clarity and a sense that RADHA *gets* what the user cares about.

## 3. Why This Phase Matters (Retention Metric)

- This screen is the single largest determinant of **scan-to-save** conversion (target ≥ 28% on personal accounts) and **alternatives CTR** (target ≥ 9%, drives BE-41 affiliate revenue).
- Allergen warning shake animation is a critical-safety affordance — parents have *explicitly* told us in research that an unmissable visual is what makes them trust the app.
- Progressive disclosure (collapsible sections) is what makes the screen feel "premium-app-fast" rather than overwhelming. Section-collapse height tween must be smooth (≤ 300 ms, easeInOutCubic).
- Engagement multiplier: tappable ingredients → BE-40 modal averages 1.7 modals per scan in beta — a free engagement win.

## 4. Prerequisites

- [ ] FE-17 complete with Hero tag `scan-{id}-image`
- [ ] BE-10 v2 returns full `ScanResult` with embedded `HealthScore`, `Allergens`, `Nutrition`, `Ingredients`, `Alternatives`
- [ ] BE-12 v2 health-score gauge spec frozen (0–100, color bands)
- [ ] BE-40 endpoint `/api/v1/ingredients/{slug}/explanation` reachable
- [ ] BE-41 endpoint `/api/v1/products/{ean}/alternatives` reachable
- [ ] BE-56 endpoint `/api/v1/products/{ean}/report-wrong-info` reachable
- [ ] FE-04 ColorScheme exposes `healthExcellent / Good / Fair / Poor / Bad` semantic colours

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/scan_output/scan_output_screen.dart` | Stateful page, hero target |
| `apps/mobile/lib/features/scan_output/widgets/sticky_health_header.dart` | Sticky header w/ animated gauge |
| `apps/mobile/lib/features/scan_output/widgets/health_rating_gauge.dart` | 0–100 animated arc |
| `apps/mobile/lib/features/scan_output/widgets/allergen_warning_banner.dart` | Red shake banner |
| `apps/mobile/lib/features/scan_output/widgets/nutrition_table.dart` | Per-100g table |
| `apps/mobile/lib/features/scan_output/widgets/ingredient_chip.dart` | Tappable ingredient chip |
| `apps/mobile/lib/features/scan_output/widgets/expandable_section.dart` | Reusable smooth-tween section |
| `apps/mobile/lib/features/scan_output/widgets/save_to_list_fab.dart` | Morphing FAB |
| `apps/mobile/lib/features/scan_output/widgets/quick_actions_row.dart` | Report-wrong / Share |
| `apps/mobile/lib/features/scan_output/controllers/scan_output_controller.dart` | Riverpod `AsyncNotifier` |
| `apps/mobile/lib/features/scan_output/controllers/save_action_controller.dart` | Optimistic save / undo |
| `apps/mobile/lib/features/scan_output/services/report_wrong_info_service.dart` | BE-56 client |
| `apps/mobile/lib/features/scan_output/animations/gauge_sweep.dart` | TweenAnimationBuilder for arc |
| `apps/mobile/lib/features/scan_output/animations/banner_shake.dart` | Sinusoidal x-translate 480 ms |
| `apps/mobile/assets/lottie/save_to_list_burst.json` | 700 ms confetti when saved |
| `apps/mobile/assets/lottie/allergen_pulse.json` | 1200 ms pulsing red ring |
| `apps/mobile/test/features/scan_output/scan_output_widget_test.dart` | Widget tests |
| `apps/mobile/test/features/scan_output/scan_output_golden_test.dart` | Goldens — 5 themes |
| `apps/mobile/integration_test/scan_output_flow_test.dart` | Hero-in + tap flow |

## 6. Screen / Widget Spec

```dart
// scan_output_screen.dart (sketch)
class ScanOutputScreen extends ConsumerWidget {
  final String scanId;
  const ScanOutputScreen({required this.scanId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanOutputControllerProvider(scanId));
    return Scaffold(
      body: state.when(
        data: (s) => CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true, expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'scan-$scanId-image',
                child: ProductHeroImage(url: s.product.imageUrl),
              ),
            ),
          ),
          SliverPersistentHeader(pinned: true, delegate: StickyHealthHeaderDelegate(s)),
          if (s.allergenMatches.isNotEmpty)
            SliverToBoxAdapter(child: AllergenWarningBanner(matches: s.allergenMatches)),
          SliverToBoxAdapter(child: ExpandableSection(
            title: 'Nutrition (per 100g)',
            initiallyExpanded: true,
            child: NutritionTable(s.product.nutrition),
          )),
          SliverToBoxAdapter(child: ExpandableSection(
            title: 'Ingredients',
            child: IngredientChipWrap(ingredients: s.product.ingredients,
              onTap: (slug) => _openExplainer(context, slug)),
          )),
          SliverToBoxAdapter(child: AlternativesCarousel(ean: s.product.ean)),
          SliverToBoxAdapter(child: QuickActionsRow(productEan: s.product.ean)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ]),
        loading: () => const _ShimmerSkeleton(),
        error: (e, _) => _ScanErrorView(error: e),
      ),
      floatingActionButton: SaveToListFab(scanId: scanId),
    );
  }
}
```

```dart
// expandable_section.dart — height tween core
AnimatedSize(
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeInOutCubic,
  alignment: Alignment.topCenter,
  child: expanded ? child : const SizedBox.shrink(),
);
```

```dart
// allergen_warning_banner.dart — shake animation
.animate(target: hasMatches ? 1 : 0)
 .shakeX(hz: 4, amount: 6, duration: 480.ms)
 .tint(color: scheme.error.withOpacity(.08))
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial / hero-arrival** | Pushed from FE-17 | Image fades in via Hero (380 ms), rest of body slides up 240 ms easeOutCubic |
| 2 | **loading** | API still resolving | Shimmer skeleton: header gauge bone, 4 row bones, 3 card bones. Pulse 1100 ms |
| 3 | **loaded — safe product** | Allergens empty, score ≥ 60 | Header chip green, no banner, sections collapsed except Nutrition |
| 4 | **loaded — risky product** | Allergens match OR score < 40 | Red banner shakes once on entry, header chip red, gauge arc pulses subtly |
| 5 | **section-expanded** | User taps section header | Chevron rotates 180° (200 ms easeOut), content `AnimatedSize` 280 ms |
| 6 | **ingredient-tapped** | Tap chip | Chip scales to 1.06 then 1.0 (140 ms), opens FE-22 explainer modal |
| 7 | **save-pressed (optimistic)** | Tap FAB | FAB icon morphs heart→filled (240 ms), Lottie confetti, snackbar "Saved — Undo" |
| 8 | **save-undo** | Tap Undo within 4 s | FAB reverts; backend call cancelled if not yet sent |
| 9 | **save-error** | BE-09 v2 returns error | FAB reverts; toast "Couldn't save — tap to retry" |
| 10 | **report-wrong-info-tapped** | Tap quick action | Bottom sheet with 4 options + free-text + send (BE-56) |
| 11 | **share-tapped** | Tap share | Native share sheet with deep-link `radha.app/p/{slug}` |
| 12 | **error-network** | Initial load failure | Empty state with illustration + retry pill |
| 13 | **error-unknown-product** | `status: 'unknown'` | Card "We don't know this one yet — help us learn" → BE-46 community-barcode form |
| 14 | **error-rate-limited** | 429 on save | Save FAB shakes red 320 ms, sheet "Free tier limit reached" w/ Premium CTA |
| 15 | **offline** | Connectivity none | Read-only — Save FAB queues to outbox, banner "Will sync when back online" |
| 16 | **accessibility-mode** | Reduced motion | All `AnimatedSize` collapse to 0 ms, gauge snaps, banner uses solid colour (no shake) |
| 17 | **premium-locked** | (BE-08 v2) explainer/alternatives gated | Section blurs lower 40%, paywall sheet rises from bottom 320 ms |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `save_to_list_burst.json` | 700 ms | Save success | No | ≤ 28 KB |
| `allergen_pulse.json` | 1200 ms | Allergen banner present | Yes | ≤ 20 KB |
| `health_score_glow.json` | 900 ms | Score band == excellent | No (one-shot on load) | ≤ 24 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| Body slide-up entrance | `.fadeIn(160).slideY(begin: .08, end: 0, dur: 240)` | easeOutCubic | 400 ms |
| Allergen shake | `.shakeX(hz: 4, amount: 6, dur: 480)` | easeInOut | 480 ms |
| Section chevron | `.rotate(begin: 0, end: .5, dur: 200)` | easeOut | 200 ms |
| Section AnimatedSize | (built-in) `dur: 280` | easeInOutCubic | 280 ms |
| Ingredient chip pop | `.scaleXY(begin: 1, end: 1.06, dur: 70).then().scaleXY(end: 1, dur: 70)` | easeOut | 140 ms |
| FAB morph | `.flipH(dur: 240)` + Lottie burst | easeOutBack | 240 ms |
| Paywall rise | `.slideY(begin: 1, end: 0, dur: 320)` | easeOutCirc | 320 ms |

### Hero Transitions

| From | To | Tag | Curve | Duration |
|---|---|---|---|---|
| FE-17 reticle area | This screen image | `scan-{id}-image` | easeInOutCubic | 380 ms |
| This screen image | FE-19 detail image (saved view) | `product-{ean}-image` | easeInOutCubic | 360 ms |

### Custom Motion Budgets

- **Entrance**: ≤ 600 ms (Hero 380 + body slide 240, overlapped → ~520 ms perceived)
- **Section toggle**: ≤ 320 ms
- **Save success cycle**: ≤ 800 ms (FAB morph 240 + Lottie 700, overlapped)
- **Allergen shake**: 480 ms once, then static — never loops to avoid anxiety

## 9. Haptics

| Event | Type |
|---|---|
| Page entrance complete | none (Hero already gives motion cue) |
| Allergen banner shake on load | `HapticFeedback.heavyImpact()` once |
| Section expand | `HapticFeedback.selectionClick()` |
| Ingredient chip tap | `HapticFeedback.lightImpact()` |
| Save FAB success | `HapticFeedback.mediumImpact()` |
| Save FAB undo | `HapticFeedback.lightImpact()` |
| Report-wrong submit | `HapticFeedback.mediumImpact()` |
| Rate-limit sheet appears | `HapticFeedback.heavyImpact()` |
| Paywall rise | `HapticFeedback.mediumImpact()` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `scan_output.health_label` | Health rating | TODO | TODO | TODO | TODO | TODO |
| `scan_output.allergen_warning` | Contains {{allergen}} — flagged for {{member}} | TODO | TODO | TODO | TODO | TODO |
| `scan_output.nutrition_header` | Nutrition (per 100 g) | TODO | TODO | TODO | TODO | TODO |
| `scan_output.ingredients_header` | Ingredients — tap any to learn more | TODO | TODO | TODO | TODO | TODO |
| `scan_output.save_cta` | Save to my list | TODO | TODO | TODO | TODO | TODO |
| `scan_output.save_success` | Saved to your list | TODO | TODO | TODO | TODO | TODO |
| `scan_output.save_undo` | Undo | TODO | TODO | TODO | TODO | TODO |
| `scan_output.alternatives_title` | Healthier picks like this | TODO | TODO | TODO | TODO | TODO |
| `scan_output.report_wrong` | Report wrong info | TODO | TODO | TODO | TODO | TODO |
| `scan_output.share` | Share | TODO | TODO | TODO | TODO | TODO |
| `scan_output.unknown_product` | We don't know this one yet — help RADHA learn it | TODO | TODO | TODO | TODO | TODO |
| `scan_output.error_network` | Couldn't load product details. Tap to retry. | TODO | TODO | TODO | TODO | TODO |
| `scan_output.rate_limit` | You've reached your free saved-products limit | TODO | TODO | TODO | TODO | TODO |
| `scan_output.offline_save` | Saved offline — will sync when you're back online | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Used For | Source |
|---|---|---|---|
| `GET` | `/api/v1/scans/{id}` | Hydrate full scan result | BE-10 v2 |
| `POST` | `/api/v1/saved-products` | Save (idempotent) | BE-09 v2 |
| `DELETE` | `/api/v1/saved-products/{id}` | Undo save | BE-09 v2 |
| `GET` | `/api/v1/products/{ean}/alternatives` | 3 alternatives | BE-41 |
| `POST` | `/api/v1/products/{ean}/report-wrong-info` | Report flag | BE-56 |

### Key DTO (from `@radha/shared-types`)

```ts
interface ScanResultDto {
  id: string;
  product: {
    ean: string; name: string; brand: string; imageUrl?: string;
    healthScore: { value: number; band: 'excellent'|'good'|'fair'|'poor'|'bad'; reasons: string[] };
    nutrition: { per100g: Record<string, number> };
    ingredients: Array<{ slug: string; displayName: string; category: string }>;
    allergenMatches: Array<{ allergen: string; matchedFor: string; severity: 'low'|'med'|'high' }>;
  };
  status: 'matched'|'unknown'|'pending_ocr';
  capturedAt: string;
}
```

### Idempotency Key Strategy

- Save action: `idempotencyKey = sha256(userId + ean)` — repeated taps within session are no-ops on the server.
- Report-wrong-info: `sha256(userId + ean + reasonCode + dayBucket)` — one report per user per product per day.

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 / `auth.expired` | Push login, preserve scan id in deep-link |
| 403 / `entitlement.saved_products_quota_exceeded` | Rate-limit sheet (state #14) with Premium CTA |
| 404 / `product.not_found` | Empty state #13 with community-barcode link |
| 409 / `saved_products.already_saved` | Show toast "Already in your list" + nav to FE-19 |
| 5xx / network | Retry pill + outbox queue |

## 12. Accessibility

- **Semantics**: Health gauge gets `Semantics(value: '$score out of 100, $band')`. Allergen banner is `liveRegion: true` so it announces the moment it appears.
- **Focus order**: AppBar back → Save FAB → Health header → Allergen banner → Nutrition header → Ingredients header → Alternatives → Quick actions.
- **Dynamic type**: Nutrition table uses `IntrinsicColumnWidth` so values stay aligned at 1.5× scaling.
- **Reduced motion**: Disable shake on allergen banner; replace with persistent border + `SemanticsService.announce` of the warning.
- **VoiceOver script**: On state #4 entry, announce `"Allergen warning: contains {{allergen}}. Flagged for {{member}}."`.
- **Colour contrast**: Score band colours all tested ≥ 4.5:1 against light + dark surfaces. Red allergen banner uses `onError` foreground.

## 13. Testing

### Widget tests

- Score gauge renders correct band colour for {0, 39, 40, 59, 60, 79, 80, 100}.
- Allergen banner only renders when `allergenMatches.isNotEmpty`.
- Section expand toggles `AnimatedSize` and rotates chevron.
- Save FAB shows Lottie burst on success.
- Tapping ingredient chip pushes FE-22 modal.

### Golden tests

- Safe product (light + dark + 1.5× type)
- Risky product with allergen (light + dark)
- Loading shimmer state
- Unknown product state

### Integration tests

- Hero from FE-17 lands at correct image with no flash of unstyled content.
- Save → undo within 4 s cancels server call (verify Dio mock was invoked 0 times after debounce).
- Tap ingredient → FE-22 modal opens, scroll position restored on dismiss.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Hero arrival at 380 ± 40 ms with no jank (per perf overlay) |
| T2 | Body slide entrance fully complete by 600 ms |
| T3 | Health gauge sweeps 0 → score over 900 ms once, never re-sweeps without explicit rebuild |
| T4 | Allergen banner appears only when matches present, shakes exactly once |
| T5 | Section AnimatedSize completes in 280 ± 30 ms across all sections |
| T6 | Save FAB optimistic update reverts cleanly on undo within 4 s (Dio call never sent) |
| T7 | Save FAB optimistic update reverts on 5xx with retry pill toast |
| T8 | Tapping ingredient chip with cached explanation opens FE-22 in < 100 ms |
| T9 | Tapping ingredient chip with cold cache shows FE-22 streaming-text state |
| T10 | Report-wrong-info sheet captures and POSTs reason code + free text |
| T11 | Share sheet uses share URL `https://radha.app/p/{slug}` |
| T12 | Unknown product state offers BE-46 community-barcode CTA |
| T13 | Reduced motion replaces shake with announce + persistent border |
| T14 | VoiceOver announces allergen warning exactly once on state-change |
| T15 | Hero-out tag `product-{ean}-image` matches what FE-19 expects |

### Q&A Questions (8)

1. How is the page's data prevented from re-fetching when the user backgrounds and resumes?
2. How do we sequence multiple competing animations on first paint without jank (Hero + slide + gauge sweep + Lottie glow)?
3. What is the correct behaviour when an allergen profile changes *after* a scan was performed but *before* the user re-opens this screen?
4. How do we test the "scan-to-save conversion" metric end-to-end given saves can be undone?
5. How does this screen behave when BE-41 alternatives is slow (>2 s) — do we render the rest first?
6. What is the rollback if BE-12 v2 health-score format changes mid-release (gauge crash protection)?
7. How are PII-sensitive allergen matches anonymised in PostHog events emitted from this screen?
8. How do we keep the "money screen" from regressing visually — what's our golden-test coverage policy?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off colour bands + shake intensity
- [ ] Performance budget respected (entrance ≤ 600 ms, section toggle ≤ 320 ms)
- [ ] Goldens merged for 5 themes

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-19 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-18 — DO NOT PROCEED WITHOUT APPROVAL**
