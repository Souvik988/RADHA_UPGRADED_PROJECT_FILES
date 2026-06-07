# Phase FE-19: Product Detail Page

## 1. Phase Metadata

- **Phase ID**: FE-19
- **Phase Name**: Product Detail Page
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-18 (Hero source), FE-04 (theme), FE-09 (haptics), BE-09 v2 (saved products), BE-12 v2 (health), BE-37 (recall history view), BE-40 (explainer), BE-41 (alternatives), BE-08 v2 (entitlements / paywall)
- **Blocks**: FE-20 (Saved Products + Calendar), FE-23 (Alternatives Carousel)
- **Estimated Duration**: 3-4 days
- **Complexity**: Medium-High (parallax + paywall gating + many sections)

## 2. Goal (Engagement Angle)

The detail page is the *re-engagement* surface — the place a user lands when they come back to a saved product days or weeks after the initial scan. It must feel calmer than the scan-output screen (no shake, no rush) but pack the long tail of useful information: a parallax hero, six expandable sections, a recall-history timeline, and an unmistakable but tasteful Premium gate. Every premium-locked section is a soft sales pitch, not a wall.

## 3. Why This Phase Matters (Retention Metric)

- This is where a "saved product" earns its 2nd, 3rd, 5th view. Target: **average sessions per saved product ≥ 1.4** within 14 days of save.
- Premium conversion: paywall sheets that rise from premium-only sections produce ~3× the conversion of settings-page upsells. Target: **paywall-impression-to-checkout ≥ 7%**.
- Affiliate revenue: alternatives section embedded here is the second-largest source of BE-41 click-outs after the scan-output screen.
- Trust: showing the recall-history timeline visibly demonstrates RADHA's safety value — a major driver of long-term retention measured in Q3 beta.

## 4. Prerequisites

- [ ] FE-18 complete with Hero tag `product-{ean}-image`
- [ ] BE-09 v2 — `GET /api/v1/saved-products/{id}` returns full enriched product
- [ ] BE-12 v2 — health score available on cached product
- [ ] BE-37 — `GET /api/v1/products/{ean}/recall-history` returns timeline
- [ ] BE-40 explainer endpoint reachable
- [ ] BE-41 alternatives endpoint reachable
- [ ] BE-08 v2 — `Entitlements` payload exposes `aiExplainer`, `affiliateAlternatives`, `recallHistory`
- [ ] FE-04 — paywall sheet primitive (`PaywallSheet`) shared

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/product_detail/product_detail_screen.dart` | Page widget |
| `apps/mobile/lib/features/product_detail/widgets/parallax_hero.dart` | Image with `SliverAppBar` parallax |
| `apps/mobile/lib/features/product_detail/widgets/section_card.dart` | Reusable expandable card |
| `apps/mobile/lib/features/product_detail/widgets/recall_timeline.dart` | Vertical timeline component |
| `apps/mobile/lib/features/product_detail/widgets/premium_locked_section.dart` | Frosted-blur gated wrapper |
| `apps/mobile/lib/features/product_detail/widgets/affiliate_alternatives_block.dart` | Wraps FE-23 carousel |
| `apps/mobile/lib/features/product_detail/widgets/edit_save_metadata_sheet.dart` | Update expiry/quantity |
| `apps/mobile/lib/features/product_detail/widgets/paywall_sheet.dart` | Rises from gated section |
| `apps/mobile/lib/features/product_detail/controllers/product_detail_controller.dart` | Riverpod loader |
| `apps/mobile/lib/features/product_detail/controllers/affiliate_click_tracker.dart` | Logs to BE-41 before launching CCT |
| `apps/mobile/lib/features/product_detail/services/custom_chrome_tab_launcher.dart` | Wraps `flutter_custom_tabs` |
| `apps/mobile/lib/features/product_detail/animations/parallax_curve.dart` | Custom curve for hero |
| `apps/mobile/assets/lottie/recall_safety_shield.json` | 1100 ms loop on recall section |
| `apps/mobile/assets/lottie/premium_lock_unlock.json` | 900 ms unlock on subscribe |
| `apps/mobile/test/features/product_detail/product_detail_widget_test.dart` | Widgets |
| `apps/mobile/test/features/product_detail/product_detail_golden_test.dart` | Goldens |
| `apps/mobile/integration_test/product_detail_flow_test.dart` | Integration |

## 6. Screen / Widget Spec

```dart
// product_detail_screen.dart
CustomScrollView(slivers: [
  SliverAppBar(
    pinned: true, expandedHeight: 320,
    flexibleSpace: FlexibleSpaceBar(
      background: ParallaxHero(
        tag: 'product-${product.ean}-image',
        url: product.imageUrl,
        scrollNotifier: scrollNotifier,        // drives custom translate
      ),
      title: AnimatedOpacity(
        opacity: collapsed ? 1 : 0,
        duration: 200.ms,
        child: Text(product.name, maxLines: 1),
      ),
    ),
  ),
  SliverList(delegate: SliverChildListDelegate([
    SectionCard(title: 'Ingredients', child: IngredientList(...)),
    SectionCard(title: 'Nutrition', child: NutritionTable(...)),
    SectionCard(title: 'Allergens', child: AllergenList(...)),
    PremiumLockedSection(
      entitlement: 'recallHistory',
      title: 'Recall history',
      child: RecallTimeline(eventsProvider: ...),
    ),
    PremiumLockedSection(
      entitlement: 'aiExplainer',
      title: 'AI explainer',
      child: AiExplainerLauncher(...),
    ),
    PremiumLockedSection(
      entitlement: 'affiliateAlternatives',
      title: 'Healthier alternatives',
      child: AffiliateAlternativesBlock(ean: product.ean),
    ),
    const SizedBox(height: 96),
  ])),
]);
```

```dart
// parallax_hero.dart — translate factor 0.4 of scroll
final t = (scrollOffset.clamp(0.0, 320.0)) * 0.4;
return Transform.translate(
  offset: Offset(0, -t),
  child: Hero(tag: tag, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)),
);
```

```dart
// premium_locked_section.dart
return Stack(children: [
  if (entitled) child
  else IgnorePointer(
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: child,
    ),
  ),
  if (!entitled) Positioned.fill(
    child: GestureDetector(
      onTap: () => showPaywallSheet(context, gate: entitlement),
      child: Center(child: PremiumGateCard(...)),
    ),
  ),
]);
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial / hero arrival** | Pushed from FE-18 | Parallax hero settles in 360 ms |
| 2 | **loading** | Detail not yet fetched | Hero placeholder + skeleton sections (4 bones) |
| 3 | **loaded — entitled** | Premium user | All sections visible and tappable |
| 4 | **loaded — free tier** | Premium gates active | Last 3 sections blurred + lock chip |
| 5 | **paywall sheet open** | Tap a gated section | Sheet rises 320 ms with plan options |
| 6 | **paywall — upgrading** | User taps "Upgrade" | Inline progress, Razorpay/Cashfree handoff |
| 7 | **paywall — upgraded** | Subscription confirmed | Lottie unlock 900 ms, sheet dismisses, gates clear with crossfade 240 ms |
| 8 | **section expanded** | Tap section header | `AnimatedSize` 280 ms easeInOutCubic |
| 9 | **affiliate-tap (CCT launching)** | Tap alternative card | Inline 240 ms scale-down + `affiliate_click_tracker` POST awaited up to 600 ms then CCT launches even if pending |
| 10 | **affiliate-tap (offline)** | No connectivity | Tap shows toast "Save the link for later" + pin to outbox |
| 11 | **edit save metadata** | Tap "edit expiry" pill | Bottom sheet with date picker + quantity stepper |
| 12 | **edit save metadata — saved** | Sheet confirm | Snackbar "Updated" + section re-renders |
| 13 | **error-network** | Initial load fails | Empty state with retry pill, hero retains last cached image |
| 14 | **error-not-found / withdrawn** | 410 from BE-37 | Banner "This product was withdrawn from the catalog" + recall context |
| 15 | **offline — read-only** | Connectivity none | Top strip + edits deferred to outbox |
| 16 | **accessibility-mode** | Reduced motion | No parallax, no Lottie loops, paywall slide replaced with fade |
| 17 | **rate-limited explainer** | BE-40 returns 429 | Inline "Try again in {{n}} s" pill instead of modal launch |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `recall_safety_shield.json` | 1100 ms | Recall section visible (entitled) | Yes | ≤ 22 KB |
| `premium_lock_unlock.json` | 900 ms | Successful upgrade | No | ≤ 26 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| AppBar title fade-in on collapse | `.fadeIn(dur: 200)` | linear | 200 ms |
| Section AnimatedSize | (built-in) 280 ms | easeInOutCubic | 280 ms |
| Premium gate "shimmer hint" | `.shimmer(dur: 1400, color: scheme.primary.withOpacity(.18))` | — | 1400 ms loop |
| Paywall sheet | `.slideY(begin: 1, end: 0, dur: 320)` | easeOutCirc | 320 ms |
| Gate-blur crossfade after upgrade | `.fadeOut(dur: 240).then(.fadeIn(dur: 240))` | easeInOut | 480 ms |
| Affiliate card press | `.scaleXY(begin: 1, end: .98, dur: 80).then().scaleXY(end: 1, dur: 80)` | easeOut | 160 ms |

### Hero Transitions

| From | To | Tag | Curve | Duration |
|---|---|---|---|---|
| FE-18 product image | This screen parallax hero | `product-{ean}-image` | easeInOutCubic | 360 ms |
| FE-20 saved-product card | This screen parallax hero | `product-{ean}-image` | easeInOutCubic | 360 ms |

### Custom Motion Budgets

- **Entrance**: ≤ 560 ms (Hero 360 + skeleton fade-out 200 overlapped)
- **Paywall**: ≤ 320 ms slide
- **Upgrade unlock cycle**: ≤ 1100 ms (Lottie 900 + crossfade 240 overlapped)

## 9. Haptics

| Event | Type |
|---|---|
| Section expand | `selectionClick` |
| Premium gate tap | `mediumImpact` |
| Paywall "Upgrade" tap | `mediumImpact` |
| Successful upgrade | `heavyImpact` |
| Affiliate card tap | `lightImpact` |
| Edit save metadata save | `mediumImpact` |
| Error toast | `lightImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `product_detail.recall_history_title` | Recall history | TODO | TODO | TODO | TODO | TODO |
| `product_detail.no_recalls` | No recalls on record. Stays this way? You're good. | TODO | TODO | TODO | TODO | TODO |
| `product_detail.alternatives_title` | Healthier alternatives | TODO | TODO | TODO | TODO | TODO |
| `product_detail.gate_explainer` | Unlock the AI explainer with Premium | TODO | TODO | TODO | TODO | TODO |
| `product_detail.gate_alternatives` | See healthier alternatives with Premium | TODO | TODO | TODO | TODO | TODO |
| `product_detail.gate_recall_history` | See full recall history with Premium | TODO | TODO | TODO | TODO | TODO |
| `product_detail.paywall_title` | Premium for ₹49 / month | TODO | TODO | TODO | TODO | TODO |
| `product_detail.paywall_cta` | Start Premium | TODO | TODO | TODO | TODO | TODO |
| `product_detail.edit_expiry_cta` | Edit expiry & quantity | TODO | TODO | TODO | TODO | TODO |
| `product_detail.affiliate_offline` | We saved this link to retry later | TODO | TODO | TODO | TODO | TODO |
| `product_detail.withdrawn_banner` | This product has been withdrawn from the catalog | TODO | TODO | TODO | TODO | TODO |
| `product_detail.error_network` | Couldn't load. Pull to retry. | TODO | TODO | TODO | TODO | TODO |
| `product_detail.upgrade_success` | Premium unlocked — enjoy! | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/saved-products/{id}` | Hydrate enriched product | BE-09 v2 |
| `GET` | `/api/v1/products/{ean}/recall-history` | Timeline events | BE-37 |
| `GET` | `/api/v1/products/{ean}/alternatives` | 3 alternatives | BE-41 |
| `GET` | `/api/v1/ingredients/{slug}/explanation` | Modal launcher (proxied via FE-22) | BE-40 |
| `PATCH` | `/api/v1/saved-products/{id}` | Update expiry / quantity | BE-09 v2 |
| `POST` | `/api/v1/affiliate/clicks` | Click tracking before CCT | BE-41 |
| `POST` | `/api/v1/subscriptions/checkout` | Paywall start | BE-08 v2 / BE-30 |

### DTOs (excerpt)

```ts
interface ProductDetailDto extends SavedProductDto {
  recallHistory: Array<{ recalledAt: string; reason: string; severity: 'low'|'med'|'high'; sourceUrl?: string }>;
  affiliateAlternatives: Array<HealthierAlternativeDto>;
  entitlements: { aiExplainer: boolean; affiliateAlternatives: boolean; recallHistory: boolean };
}
```

### Idempotency Key Strategy

- PATCH save metadata: `idempotencyKey = sha256(savedProductId + payloadHash)`.
- Affiliate click POST: stateless, no key (analytics row, dedupe is server-side debounce by user+ean within 60 s).

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 / `auth.expired` | Force re-login, return to this page |
| 403 / `entitlement.locked` | Render gated UI (state #4) |
| 404 / `saved_products.not_found` | Toast + back to FE-20 |
| 410 / `product.withdrawn` | Banner state #14 |
| 5xx / network | Empty state with retry pill |

## 12. Accessibility

- **Semantics**: Hero image gets `Semantics(label: '${product.name}, image')`. Each gated section announces "{{section name}}, premium feature, double tap to upgrade".
- **Focus order**: Back → AppBar title → each section header in DOM order → paywall card (when present) → edit metadata pill.
- **Dynamic type**: All section titles use `displaySmall`; body uses `bodyMedium`. Tested at 1.5×.
- **Reduced motion**: Disable parallax (hero stays still), Lottie loops switch to first frame, paywall slide → fade.
- **VoiceOver script**: On entry to a gated section: "Premium feature. Double tap to learn more."
- **Contrast**: Frosted-blur lock card uses `surfaceContainerHigh` background to maintain ≥ 4.5:1 against text.

## 13. Testing

### Widget tests

- Parallax translate factor is exactly 0.4× scroll offset.
- Premium gate renders blur + lock card when entitlement false.
- Tapping gated section opens paywall sheet with correct gate prop.
- Recall timeline renders entries newest-first.
- Edit metadata sheet validates expiry date is not past today (warns, doesn't block).

### Golden tests

- Free-tier (3 gates visible) light + dark
- Premium-tier (no gates) light + dark
- Withdrawn-product banner state
- Loading skeleton state
- 1.5× type scaling

### Integration tests

- Affiliate tap: verify POST `/affiliate/clicks` fires *before* CCT launch (or within 600 ms then CCT launches anyway).
- Upgrade flow: mock subscription confirm → gates clear with Lottie unlock visible.
- Reduced motion: assert no parallax transform applied.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Hero arrival completes in 360 ± 40 ms with no flash |
| T2 | Parallax translate factor = 0.4 verified at scroll offsets {0, 80, 160, 320} |
| T3 | Sections render in order: Ingredients, Nutrition, Allergens, Recall history, AI explainer, Alternatives |
| T4 | Free-tier user sees blur on last 3 sections, premium-tier sees none |
| T5 | Paywall slide-up completes in 320 ± 30 ms |
| T6 | Successful upgrade triggers Lottie unlock and clears all gates with crossfade |
| T7 | Affiliate click POST is awaited up to 600 ms then CCT launches with affiliate URL |
| T8 | Edit-metadata sheet PATCHes correctly with idempotency key |
| T9 | Withdrawn-product (410) renders banner and disables Save/Edit actions |
| T10 | Recall timeline shows newest event first, supports up to 50 entries with virtualised list |
| T11 | Reduced motion disables parallax and Lottie loops |
| T12 | VoiceOver announces gated sections with the correct prompt |
| T13 | Network failure during PATCH queues mutation in outbox and shows retry pill |
| T14 | Tapping a gated section twice in 200 ms only opens one paywall sheet (debounced) |
| T15 | Memory profile under 80 MB on Pixel 4a after 30 s of scrolling |

### Q&A Questions (8)

1. How does the parallax behave on iOS where overscroll is bouncy vs. Android where it isn't?
2. What is the strategy for caching recall-history server-responses to keep BE-37 calls minimal?
3. How are gated sections announced if the user enables Premium *while* on this page (without leaving)?
4. How do we prevent the affiliate click tracker from leaking PII via referer headers when launching CCT?
5. What's the behaviour when a CCT cannot be launched (no Chrome installed)?
6. How does the paywall sheet behave if the user has an *active* subscription that's pending payment confirmation?
7. How do we handle products with no image (placeholder strategy + parallax behaviour)?
8. What's the long-term plan for converting "withdrawn product" banners into a community-flag CTA?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off parallax curve and gate blur intensity
- [ ] Animation budgets respected
- [ ] Goldens merged for free + premium states

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-20 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-19 — DO NOT PROCEED WITHOUT APPROVAL**
