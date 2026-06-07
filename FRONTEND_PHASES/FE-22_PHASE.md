# Phase FE-22: AI Ingredient Explainer Modal

## 1. Phase Metadata

- **Phase ID**: FE-22
- **Phase Name**: AI Ingredient Explainer Modal
- **Section**: Frontend Execution — Consumer Core
- **Depends On**: FE-04 (theme), FE-09 (haptics), FE-18 (caller — ingredient chips), FE-19 (caller — explainer launcher), BE-40 (LLM explainer), BE-42 (i18n), BE-08 v2 (entitlement: aiExplainer)
- **Blocks**: none
- **Estimated Duration**: 2 days
- **Complexity**: Medium (streaming text + cache-aware UX + language switch)

## 2. Goal (Engagement Angle)

The single most differentiated feature for Premium consumers: tap any ingredient → a slide-up sheet animates open and *types out* the explanation at 40 chars/sec like a thoughtful expert is talking to you. A confidence badge at the top sets expectations honestly. A language pill in the corner lets the user instantly switch to Hindi/Tamil/Bengali — RADHA listens. On *cache hits* the text appears instantly with no animation, because nothing communicates "we already know this" faster than zero-latency.

## 3. Why This Phase Matters (Retention Metric)

- The typewriter effect is the most-quoted "delight moment" from beta. Users *call out* this animation in App Store reviews.
- Target: **median time-to-explanation ≤ 1.2 s** for cold; **≤ 80 ms** for cached.
- Language switch usage is a strong signal of engagement depth — premium users who switch language at least once stay 2.4× longer per session.
- Modal is reused by FE-18 and FE-19 — one polished primitive paying off twice.

## 4. Prerequisites

- [ ] BE-40 — `GET /api/v1/ingredients/{slug}/explanation?locale=...` returns `{ description, healthConsiderations, confidence }`
- [ ] BE-40 — Streaming variant `?stream=1` returns SSE/chunked tokens (preferred); modal falls back to non-stream + client-side typewriter if not available
- [ ] BE-42 — locales endpoint enumerates supported languages
- [ ] BE-08 v2 — `Entitlements.aiExplainer` flag
- [ ] FE-04 — `Sheet` primitive (rounded-top 28 dp, drag handle)
- [ ] FE-09 — `HapticsService.selectionClick()` for language switch

## 5. Files to Create

| File Path | Purpose |
|---|---|
| `apps/mobile/lib/features/ingredient_explainer/ingredient_explainer_sheet.dart` | The bottom sheet widget |
| `apps/mobile/lib/features/ingredient_explainer/widgets/typewriter_text.dart` | 40-cps animated text |
| `apps/mobile/lib/features/ingredient_explainer/widgets/confidence_badge.dart` | Low/Med/High pill |
| `apps/mobile/lib/features/ingredient_explainer/widgets/language_pill.dart` | Compact language switcher |
| `apps/mobile/lib/features/ingredient_explainer/widgets/streaming_indicator.dart` | 3-dot caret while waiting |
| `apps/mobile/lib/features/ingredient_explainer/widgets/explainer_skeleton.dart` | First-paint skeleton |
| `apps/mobile/lib/features/ingredient_explainer/widgets/error_view.dart` | Network/timeout fallback |
| `apps/mobile/lib/features/ingredient_explainer/controllers/explainer_controller.dart` | Riverpod stream + cache logic |
| `apps/mobile/lib/features/ingredient_explainer/services/explainer_repository.dart` | Drift cache + Dio (SSE / fallback) |
| `apps/mobile/lib/features/ingredient_explainer/services/typewriter_engine.dart` | Pure controller (testable) |
| `apps/mobile/test/features/ingredient_explainer/typewriter_engine_test.dart` | Unit tests (PBT) |
| `apps/mobile/test/features/ingredient_explainer/explainer_widget_test.dart` | Widgets |
| `apps/mobile/test/features/ingredient_explainer/explainer_golden_test.dart` | Goldens |

## 6. Screen / Widget Spec

```dart
// ingredient_explainer_sheet.dart — entry point
Future<void> showIngredientExplainer(BuildContext context, {required String slug}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => IngredientExplainerSheet(slug: slug),
  );
}

class IngredientExplainerSheet extends ConsumerWidget {
  final String slug;
  const IngredientExplainerSheet({required this.slug, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(explainerControllerProvider(slug));
    return DraggableScrollableSheet(
      initialChildSize: 0.55, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (ctx, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(state.displayName, style: theme.titleLarge)),
              ConfidenceBadge(level: state.confidence),
            ]),
            const SizedBox(height: 12),
            LanguagePill(
              current: state.locale,
              onChanged: (l) => ref.read(explainerControllerProvider(slug).notifier).switchLocale(l),
            ),
            const SizedBox(height: 16),
            switch (state.kind) {
              ExplainerKind.cacheHit => _CachedView(state),
              ExplainerKind.streaming => TypewriterText(
                  source: state.tokenStream, charsPerSecond: 40,
                ),
              ExplainerKind.loading => const ExplainerSkeleton(),
              ExplainerKind.error => ErrorView(retry: () => ref.refresh(...)),
            },
          ],
        )),
      ),
    );
  }
}
```

```dart
// typewriter_engine.dart — pure controller
class TypewriterEngine {
  final int charsPerSecond;          // 40
  final void Function(String) onUpdate;
  Timer? _timer;
  String _shown = '';
  String _target = '';
  TypewriterEngine({required this.charsPerSecond, required this.onUpdate});

  void start() {
    final tickMs = (1000 / charsPerSecond).round();    // 25 ms per char
    _timer = Timer.periodic(Duration(milliseconds: tickMs), (_) {
      if (_shown.length >= _target.length) return;
      _shown = _target.substring(0, _shown.length + 1);
      onUpdate(_shown);
    });
  }
  void appendTarget(String chunk) { _target += chunk; }
  void completeImmediately() { _shown = _target; onUpdate(_shown); _timer?.cancel(); }
  void dispose() => _timer?.cancel();
}
```

## 7. Visual Behaviour & Interaction States

| # | State | Trigger | UI |
|---|---|---|---|
| 1 | **opening** | `showIngredientExplainer` called | Sheet rises 280 ms easeOutCubic from bottom |
| 2 | **loading (cold)** | Cache miss, awaiting first token | Skeleton 3 lines, streaming caret blinking |
| 3 | **streaming** | Token chunks arriving | Typewriter at 40 cps, caret pulsing 600 ms |
| 4 | **completed-streaming** | Final chunk received | Caret disappears, body fully shown, "Helpful?" feedback row fades in |
| 5 | **cache-hit (instant)** | Cache present in Drift | Body fully rendered immediately, no animation, only sheet rise |
| 6 | **language-switching** | User taps language pill | Body fades out 160 ms, skeleton + new locale loading |
| 7 | **language-switched (cached)** | New locale already cached | Cross-fade 200 ms |
| 8 | **error-network** | Dio failure | Error view with retry pill, last cached locale stays viewable |
| 9 | **error-timeout** | 10 s no response | Same as error-network with copy "Taking too long…" |
| 10 | **rate-limited (BE-40 LLM cap)** | 429 | Friendly card "We're a bit busy — try again in {{n}}s" |
| 11 | **gate-locked (free tier)** | Entitlement false | Sheet shows preview-only first 2 lines + Premium CTA |
| 12 | **dismissed** | Drag down or tap outside | Scroll position preserved on FE-18/FE-19 underneath |
| 13 | **offline** | No connectivity | If cached → still works; if not → error view "Need internet for first explanation" |
| 14 | **accessibility-mode** | Reduced motion | Typewriter disabled; full text shown immediately; caret hidden |
| 15 | **feedback submitted** | User taps "Helpful?" thumbs | Row morphs to "Thanks!" with subtle Lottie pop 600 ms |
| 16 | **streaming-paused (resume)** | App backgrounded mid-stream | On resume, completes immediately if response cached, else reconnects |

## 8. Animations Inventory

### Lottie

| File | Duration | Trigger | Loop | Size |
|---|---|---|---|---|
| `feedback_thumbs_pop.json` | 600 ms | Helpful feedback submitted | No | ≤ 16 KB |

### flutter_animate Chains

| Widget | Chain | Curves | Total |
|---|---|---|---|
| Sheet rise | (built-in `showModalBottomSheet`) 280 ms | easeOutCubic | 280 ms |
| Typewriter caret | `.fadeIn(300).then().fadeOut(300)` (loop) | linear | 600 ms loop |
| Body crossfade on language switch | `.fadeOut(dur: 160).then().fadeIn(dur: 200)` | easeInOut | 360 ms |
| Cache-hit fade-in | `.fadeIn(dur: 80)` | linear | 80 ms |
| Confidence badge entrance | `.scaleXY(begin: .9, end: 1, dur: 180)` | easeOutBack | 180 ms |
| Feedback row appearance | `.fadeIn(220).slideY(begin: .04, end: 0, dur: 240)` | easeOutCubic | 460 ms |
| Error-view shake on retry-fail | `.shakeX(hz: 3, amount: 4, dur: 280)` | easeInOut | 280 ms |

### Hero Transitions

None — modal does not host hero motion.

### Custom Motion Budgets

- **Cold path entrance to first char**: ≤ 1200 ms (sheet 280 + first-token 600 + first-char 25)
- **Cache-hit entrance to fully visible**: ≤ 360 ms (sheet 280 + fade 80)
- **Language-switch cycle**: ≤ 360 ms

## 9. Haptics

| Event | Type |
|---|---|
| Sheet open | `lightImpact` once |
| Cache-hit (instant render) | none (instant feels best with silence) |
| Streaming begins (first token) | `selectionClick` |
| Language pill tap | `selectionClick` |
| Helpful "thumbs up" | `mediumImpact` |
| Helpful "thumbs down" | `lightImpact` |
| Error view shown | `lightImpact` |
| Rate-limited card | `heavyImpact` |
| Premium gate-locked sheet | `mediumImpact` |

## 10. Microcopy

| Key | en | hi | ta | te | bn | mr |
|---|---|---|---|---|---|---|
| `explainer.confidence_low` | Low confidence | TODO | TODO | TODO | TODO | TODO |
| `explainer.confidence_med` | Medium confidence | TODO | TODO | TODO | TODO | TODO |
| `explainer.confidence_high` | High confidence | TODO | TODO | TODO | TODO | TODO |
| `explainer.language_pill` | In {{language}} | TODO | TODO | TODO | TODO | TODO |
| `explainer.streaming_caret_alt` | Composing… | TODO | TODO | TODO | TODO | TODO |
| `explainer.error_network` | Couldn't reach the explainer. Tap to retry. | TODO | TODO | TODO | TODO | TODO |
| `explainer.error_timeout` | Taking too long. Tap to try again. | TODO | TODO | TODO | TODO | TODO |
| `explainer.rate_limited` | We're a bit busy — try again in {{n}} seconds | TODO | TODO | TODO | TODO | TODO |
| `explainer.gate_preview` | Premium unlocks the full explanation | TODO | TODO | TODO | TODO | TODO |
| `explainer.gate_cta` | Start Premium | TODO | TODO | TODO | TODO | TODO |
| `explainer.helpful_question` | Was this helpful? | TODO | TODO | TODO | TODO | TODO |
| `explainer.helpful_thanks` | Thanks for letting us know | TODO | TODO | TODO | TODO | TODO |
| `explainer.offline_no_cache` | You'll need internet for the first explanation | TODO | TODO | TODO | TODO | TODO |

## 11. Backend Integration

### Endpoints

| Method | Path | Purpose | Source |
|---|---|---|---|
| `GET` | `/api/v1/ingredients/{slug}/explanation?locale=hi` | Non-stream JSON | BE-40 |
| `GET` | `/api/v1/ingredients/{slug}/explanation?locale=hi&stream=1` | SSE stream of tokens (preferred) | BE-40 |
| `POST` | `/api/v1/ingredients/{slug}/feedback` | Helpful y/n | BE-40 |

### DTO

```ts
interface IngredientExplanationDto {
  slug: string;
  language: string;          // 'en'|'hi'|'ta'|'te'|'bn'|'mr'
  description: string;
  healthConsiderations: string;
  confidence: 'low'|'medium'|'high';
  generatedBy: string;
  cached: boolean;           // true if served from server cache
}
```

### Idempotency Key Strategy

- Feedback POST: `idempotencyKey = sha256(slug + locale + thumbsValue + dayBucket)` — once per day per ingredient.

### Error → UI Mapping

| Code | UI |
|---|---|
| 401 | Force re-login |
| 403 / `entitlement.ai_explainer_required` | Render preview + Premium CTA |
| 404 / `ingredient.not_found` | Toast "We don't know that ingredient yet" |
| 429 | Rate-limited card |
| 5xx / network / SSE-disconnect | Fallback to non-stream JSON; if that fails too, error view |

## 12. Accessibility

- **Semantics**: Sheet root `Semantics(container: true, label: 'Ingredient explanation')`. Language pill `Semantics(button: true, label: 'Change language, currently {{lang}}')`.
- **Focus order**: Drag handle → ingredient title → confidence badge → language pill → body → feedback row.
- **Dynamic type**: Body uses `bodyMedium`; max scale 1.5×; sheet auto-grows beyond `initialChildSize` if content overflows.
- **Reduced motion**: Disable typewriter; show full text immediately; replace caret with static "Composed" label.
- **VoiceOver script**: When body finishes streaming, announce `"Explanation complete. Use the helpful question to give feedback."` once.
- **Contrast**: Confidence badge color paired with text label; never color-only.

## 13. Testing

### Property-based / unit tests (TypewriterEngine)

- For any `target` of length n with `cps = 40`, all chars revealed within `n × 25 + 50` ms.
- `appendTarget` extends without resetting shown.
- `completeImmediately` always equals target.

### Widget tests

- Sheet opens with rise animation.
- Cache-hit path renders body without typewriter widget mounted.
- Language pill switch triggers re-fetch with new locale param.
- Premium gate renders preview when entitlement false.
- Reduced-motion flag short-circuits typewriter.

### Golden tests

- Streaming mid-render (light + dark)
- Cached complete (light + dark)
- Premium gate state (light)
- Error view (light)

### Integration tests

- Tap ingredient on FE-18 → sheet opens, streams, dismisses, FE-18 scroll position preserved.
- Switch language during stream — first stream cancelled cleanly.
- Background app mid-stream → resume completes correctly.

## 14. Mandatory SOP

### Test Procedures (15)

| # | Test |
|---|---|
| T1 | Sheet rise completes in 280 ± 30 ms |
| T2 | Cache-hit body fully visible in ≤ 360 ms |
| T3 | Cold path renders first character in ≤ 1200 ms |
| T4 | Typewriter cadence is 40 ± 2 cps |
| T5 | Caret blinks at 600 ms cadence (or hidden under reduced motion) |
| T6 | Language pill switch cancels in-flight stream and re-issues with new locale |
| T7 | Free-tier user sees only first 2 lines + Premium CTA |
| T8 | Helpful "thumbs up" submits and morphs to thanks state |
| T9 | Helpful "thumbs down" optionally captures free text via secondary sheet |
| T10 | Reduced-motion shows full text immediately, no typewriter |
| T11 | VoiceOver announces "Explanation complete" exactly once |
| T12 | Background-foreground cycle preserves shown text and resumes correctly |
| T13 | SSE disconnect mid-stream falls back to non-stream JSON within 500 ms |
| T14 | Rate-limited (429) renders countdown card with `retryAfter` |
| T15 | Drift cache write occurs only on successful complete (no half-cached entries) |

### Q&A Questions (8)

1. How do we distinguish a "server-cached" hit (BE-40 cached row) from "client Drift-cached" hit?
2. What is our policy for cache invalidation when BE-40 regenerates explanations after model upgrade?
3. How do we cap the cumulative typewriter time so very long explanations don't drag — auto-flush after threshold?
4. How do we handle a user who switches language *mid-typewriter* — abort animation, start over, or finish current then switch?
5. What's the strategy for rate-limit (429) responses to ensure they don't accidentally cache as the "explanation"?
6. How do we test the typewriter visually in CI (it's time-based)?
7. How do we ensure language-switch buttons remain accessible to TalkBack and announce the change?
8. What is the long-term plan for offline-first — pre-fetch explanations when a product is saved?

### Sign-off Gate

- [ ] All 15 SOP tests pass
- [ ] All 8 Q&A answered
- [ ] Designer signed off typewriter cadence and caret style
- [ ] Animation budgets respected (cold ≤ 1200 ms; cached ≤ 360 ms)
- [ ] Goldens merged

**Developer Signature**: ___________________________

**Reviewer**: ☐ APPROVED — Proceed to FE-23 ☐ CHANGES REQUESTED  ___________________

**Designer**: ☐ APPROVED ☐ CHANGES REQUESTED  ___________________

---

**END OF FE-22 — DO NOT PROCEED WITHOUT APPROVAL**
