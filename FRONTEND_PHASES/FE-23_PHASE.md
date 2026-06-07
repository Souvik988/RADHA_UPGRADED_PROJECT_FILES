# Phase FE-23: Healthy Alternatives Carousel

## 1. Phase Metadata

- **Phase ID**: FE-23
- **Phase Name**: Healthy Alternatives Carousel
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme), FE-09 (haptics), FE-18 (host), FE-19 (host), BE-41 (alternatives + affiliate), BE-08 v2 (entitlement: affiliateAlternatives), BE-12 v2 (health-score delta)
- **Blocks**: none
- **Estimated Duration**: 2 days
- **Complexity**: Medium (carousel + CCT + click tracking + premium gate)

## 2. Goal (Engagement Angle)

The carousel is RADHA's biggest *passive* revenue surface. Three cards horizontally, each showing a healthier substitute with a tiny **green delta chip** (+15 health-score points!) next to the score, a brand wordmark, and a single "Buy on Amazon/Flipkart" CTA. Tap → analytics fires, then a Custom Chrome Tab launches the affiliate URL. Empty state is honest and helpful: "We didn't find anything healthier — you're already on a good one." Premium gate shows two cards blurred with a single shimmer line.

## 3. Why This Phase Matters (Retention Metric)

- This is the **#1 affiliate revenue driver**. Target: **carousel CTR ≥ 9%** when alternatives are present.
- Empty-state copy is itself a retention move — it reinforces RADHA's neutral, helpful voice ("you're on a good one") rather than always pushing alternatives.
- Reused by FE-18 (scan output) and FE-19 (product detail) — one component, two retention surfaces.
- Premium-gate hint converts ~6% of free-tier viewers monthly per beta data — every blurred card is a paywall ad in disguise.

## 4. Prerequisites

- [ ] BE-41 — `GET /api/v1/products/{ean}/alternatives` returns up to 3 with `affiliateLink`, `partner`, `healthScore`, `delta`
- [ ] BE-41 — `POST /api/v1/affiliate/clicks` accepts source EAN + alt EAN + partner before launch
- [ ] BE-08 v2 — `Entitlements.affiliateAlternatives` flag
- [ ] `flutter_custom_tabs` package wired and tested for Android + `SFSafariViewController` on iOS
- [ ] FE-04 — `delta-chip` colour token (green-tinted)

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/alternatives/alternatives_carousel.dart` | Carousel widget, embeddable |
| `apps/mobile/lib/features/alternatives/widgets/alternative_card.dart` | Single card |
| `apps/mobile/lib/features/alternatives/widgets/delta_chip.dart` | "+15" green chip |
| `apps/mobile/lib/features/alternatives/widgets/partner_badge.dart` | Amazon/Flipkart wordmark |
| `apps/mobile/lib/features/alternatives/widgets/empty_alternatives_view.dart` | Reassuring empty state |
| `apps/mobile/lib/features/alternatives/widgets/premium_gated_card.dart` | Frosted-blur card |
| `apps/mobile/lib/features/alternatives/controllers/alternatives_controller.dart` | Riverpod loader |
| `apps/mobile/lib/features/alternatives/services/affiliate_click_service.dart` | Tracks + launches CCT |
| `apps/mobile/lib/features/alternatives/animations/card_lift.dart` | Press scale + shadow |
| `apps/mobile/assets/lottie/empty_alternatives_calm.json` | 1400 ms loop |
| `apps/mobile/test/features/alternatives/alternatives_widget_test.dart` | Widgets |
| `apps/mobile/test/features/alternatives/alternatives_golden_test.dart` | Goldens |
| `apps/mobile/integration_test/alternatives_flow_test.dart` | Integration with mocked CCT |

## 6. Screen / Widget Spec

```dart
// alternatives_carousel.dart
class AlternativesCarousel extends ConsumerWidget {
  final String ean;
  const AlternativesCarousel({required this.ean, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alternativesControllerProvider(ean));
    return state.when(
      loading: () => const _CarouselSkeleton(itemCount: 3),
      error: (_, __) => const SizedBox.shrink(),     // fail silently — non-essential
      data: (alts) {
        if (alts.isEmpty) return const EmptyAlternativesView();
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: alts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => AlternativeCard(alt: alts[i], sourceEan: ean),
          ),
        );
      },
    );
  }
}
```

```dart
// alternative_card.dart
return AnimatedScale(
  scale: pressed ? 0.97 : 1,
  duration: const Duration(milliseconds: 90),
  child: Material(
    elevation: pressed ? 0 : 2, borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: () => ref.read(affiliateClickServiceProvider).launch(
        sourceEan: sourceEan, altEan: alt.ean, partner: alt.partner,
        url: alt.affiliateLink,
      ),
      child: SizedBox(width: 168, child: Padding(padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1,
              child: ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: alt.imageUrl, fit: BoxFit.cover))),
            const SizedBox(height: 8),
            Row(children: [
              Text(alt.healthScore.toString(), style: theme.titleMedium),
              const SizedBox(width: 6),
              DeltaChip(delta: alt.delta),
            ]),
            Text(alt.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [PartnerBadge(partner: alt.partner), const Spacer(),
              const Icon(Icons.open_in_new, size: 16)]),
          ],
        ),
      )),
    ),
  ),
);
```

```dart
// affiliate_click_service.dart — track-then-launch
Future<void> launch({...}) async {
  // Fire analytics first; bounded wait so user never feels blocked
  final tracking = _api.trackClick(...).timeout(const Duration(milliseconds: 600));
  try { await tracking; } catch (_) { /* swallow but enqueue offline */ }
  await _customTabs.launch(url, options: ChromeTabsOptions(
    toolbarColor: scheme.primary, urlBarHidingEnabled: false,
  ));
}
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **initial / loading** | Mount | Skeleton row of 3 cards, shimmer 1100 ms |
| 2 | **loaded — populated** | API returns 1–3 alternatives | Carousel renders cards from left, snap scrolling |
| 3 | **loaded — empty** | 0 alternatives | Calm "you're on a good one" empty card with Lottie |
| 4 | **card-press** | Touch down on card | Scale 0.97, shadow elevation drops 2 → 0, 90 ms |
| 5 | **card-tap (online)** | Tap up | Click POST awaited up to 600 ms, then CCT launches |
| 6 | **card-tap (slow track)** | Track > 600 ms | CCT launches anyway; track POST queued offline |
| 7 | **card-tap (offline)** | No connectivity | Snackbar "Saved the link to retry — open later"; click queued |
| 8 | **error-load** | API error | Component renders nothing (silent — host page must still work) |
| 9 | **rate-limited** | 429 | Skeleton stays + small footer "Try again in {{n}}s" |
| 10 | **gate-locked (free tier)** | Entitlement false | First card visible, next 2 blurred, single CTA "Unlock with Premium" |
| 11 | **gate-locked (free tier — no recommendations available either)** | Both gated and empty | Show only "Premium gives you healthier picks" gate card |
| 12 | **CCT-returned** | User comes back from external | Carousel state preserved; analytics `affiliate_return` fired |
| 13 | **partner-inactive** | BE-41 returns alt with no link | Card renders but CTA reads "Unavailable" greyed |
| 14 | **accessibility-mode** | Reduced motion | Press scale disabled; shimmer single-frame |
| 15 | **scroll-end haptic** | User overscrolls past last card | `lightImpact` once |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `empty_alternatives_calm.json` | 1400 ms | Empty state | Yes | ≤ 22 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| Skeleton shimmer | `.shimmer(dur: 1100, color: scheme.primary.withOpacity(.10))` (loop) | — | 1100 ms loop |
| Card entrance (staggered) | `.fadeIn(160).slideX(begin: .04, end: 0, dur: 220, delay: i*60ms)` | easeOutCubic | 220 + 120 stagger |
| Card press lift | `.scaleXY(end: .97, dur: 90).then().scaleXY(end: 1, dur: 90)` | easeOut | 180 ms |
| Premium-gate card shimmer hint | `.shimmer(dur: 1400, color: scheme.primary.withOpacity(.18))` (loop) | — | 1400 ms loop |
| Empty state hero | `.fadeIn(220).slideY(begin: .04, end: 0, dur: 280)` | easeOutCubic | 500 ms |

### Hero Transitions

None for this carousel — CCT has its own native transition.

### Custom Motion Budgets

- **Entrance**: ≤ 460 ms (skeleton fade-out 220 + first card slide-in 220, overlapped)
- **Card press cycle**: ≤ 180 ms
- **Track-to-launch**: ≤ 600 ms (timeout); ≤ 900 ms total entry into CCT

## 9. Haptics

| Event | Type |
|---|---|
| Card press down | none (scale already gives feedback) |
| Card tap (commit) | `selectionClick` |
| CCT launches | `lightImpact` |
| Card tap blocked (offline / rate-limited) | `mediumImpact` |
| Premium gate tap | `mediumImpact` |
| Scroll-end overscroll | `lightImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `alternatives.title` | Healthier picks | TODO | TODO | TODO | TODO | TODO |
| `alternatives.delta_chip` | +{{delta}} | TODO | TODO | TODO | TODO | TODO |
| `alternatives.cta_amazon` | Buy on Amazon | TODO | TODO | TODO | TODO | TODO |
| `alternatives.cta_flipkart` | Buy on Flipkart | TODO | TODO | TODO | TODO | TODO |
| `alternatives.empty_heading` | You're on a good one | TODO | TODO | TODO | TODO | TODO |
| `alternatives.empty_body` | We didn't find anything healthier in this category | TODO | TODO | TODO | TODO | TODO |
| `alternatives.gate_title` | Premium picks healthier alternatives for you | TODO | TODO | TODO | TODO | TODO |
| `alternatives.gate_cta` | Unlock with Premium | TODO | TODO | TODO | TODO | TODO |
| `alternatives.offline_toast` | Saved the link — we'll open it next time you're online | TODO | TODO | TODO | TODO | TODO |
| `alternatives.unavailable` | Unavailable right now | TODO | TODO | TODO | TODO | TODO |
| `alternatives.disclosure` | Buying through these links supports RADHA | TODO | TODO | TODO | TODO | TODO |

> The `alternatives.disclosure` line must appear *somewhere* in the carousel section to honour BE-41's affiliate-disclosure Q&A.

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/products/{ean}/alternatives` | Up to 3 picks | BE-41 |
| `POST` | `/api/v1/affiliate/clicks` | Track click | BE-41 |

### DTOs

```ts
interface HealthierAlternativeDto {
  ean: string;
  name: string;
  brand: string;
  imageUrl?: string;
  healthScore: number;
  delta: number;                  // points improved vs. source
  partner: 'amazon'|'flipkart'|'other';
  affiliateLink?: string;         // null if partner inactive
}
interface AffiliateClickRequest {
  sourceProductEan: string;
  alternativeProductEan: string;
  partnerId: string;
}
```

### Idempotency Key Strategy

- Click POST is idempotent server-side via dedupe (user + sourceEan + altEan within 60 s).
- Client uses no key — repeated rapid taps are a debounce concern (see SOP T13).

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 | Force re-login |
| 403 / `entitlement.affiliate_alternatives_required` | Render gated state #10 |
| 404 / `product.not_found` | Empty state (silent) |
| 429 | State #9 |
| 5xx / network | Render nothing (host renders without us); track failure offline |

## 12. Accessibility

- **Semantics**: Each card `Semantics(button: true, label: '{{name}}, health score {{score}}, plus {{delta}} versus current. Buy on {{partner}}.')`. Empty state announces calmly.
- **Focus order**: Carousel cards left-to-right; gated card consumes its own focus stop.
- **Dynamic type**: Card width grows with text scale; minimum 168 dp at 1.0×, 200 dp at 1.5× via `IntrinsicWidth`.
- **Reduced motion**: No staggered fade; cards appear simultaneously; press scale disabled.
- **VoiceOver script**: On launch CCT, announce `"Opening {{partner}} in browser"`.
- **Contrast**: Delta chip text ≥ 4.5:1 against pale-green background.

## 13. Testing

### Widget tests

- Renders up to 3 cards from response.
- Empty state when no alternatives.
- Free-tier user: first card visible, others gated with paywall CTA.
- Card press triggers track POST and CCT launch with correct affiliate URL.
- Disclosure line is present whenever the carousel renders.

### Golden tests

- 3 cards filled (light + dark)
- 1 card available (light)
- Empty state (light + dark)
- Gated free-tier (light + dark)
- 1.5× type scaling

### Integration tests

- Track POST fires with correct `sourceEan`+`altEan`+`partner` before CCT launch.
- Network-down: track queues offline, CCT still launches.
- Rapid double-tap launches CCT only once (debounce).

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Carousel renders horizontally with 168 dp cards and 12 dp spacing |
| T2 | Skeleton uses 1100 ms shimmer and resolves on data |
| T3 | Card press scales to 0.97 within 90 ms |
| T4 | Click POST is awaited up to 600 ms before CCT launches |
| T5 | If track POST exceeds 600 ms, CCT still launches and track is queued offline |
| T6 | Offline mode shows snackbar and queues clicks for later |
| T7 | Free-tier sees first card visible, next 2 blurred + Premium CTA |
| T8 | Premium-gate tap opens paywall sheet with `gate: 'affiliateAlternatives'` |
| T9 | Empty state renders Lottie + reassuring copy when API returns 0 |
| T10 | Disclosure line is rendered whenever carousel renders |
| T11 | Rapid double-tap launches CCT only once (debounced) |
| T12 | Reduced-motion disables stagger and press-scale |
| T13 | Health-delta chip is hidden when delta ≤ 0 (defensive) |
| T14 | VoiceOver announces card semantics correctly |
| T15 | Component fails silently (renders nothing) on API error so host pages still render fully |

### Q&A Questions (8)

1. How is the "fail silently" rule enforced — should host screens be allowed to detect failure for analytics?
2. How do we test that the disclosure line is *visible*, not just rendered (above-the-fold or in-card)?
3. What is the correct behaviour when only 1 of 3 cards comes back (do we still render or hide entirely)?
4. How is the affiliate URL signed/validated client-side to detect tampering?
5. How do we handle the case where the user has an ad-blocker that blocks CCT-launched URLs?
6. How is partner cycling (Amazon vs Flipkart) tested when BE-41 dynamically prefers one?
7. What is the long-term plan for ML-based alternative ranking — does the client need to change?
8. How does this carousel coexist with FE-19's recall banner (z-order, scroll behaviour)?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off card density and gate blur
- [ ] Affiliate disclosure line is present and reviewed by Legal/Compliance
- [ ] Goldens merged

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-24 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

**Compliance**: ☐ DISCLOSURE APPROVED  ___________________

---

**END OF FE-23 — DO NOT PROCEED WITHOUT APPROVAL**
