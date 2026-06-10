# Phase 1 — Consumer-Flow UI Audit & Fix Report

> Scope of this pass: the consumer engagement path (the highest-visibility journey, and
> where the new banners / categories / ingredients work lives). Each screen audited against
> the production checklist: **states · tokens · assets · partial-failure isolation · 60fps
> hygiene · backend wiring · honest-data**. Every fix was a small reversible edit, verified
> with `flutter analyze` + the affected tests after each change.

## Baseline (pre-audit)
- `flutter analyze lib` → **clean** (0 issues across all 38 screens).
- Full test suite → **179 / 179 passing** (after Phase 0 fixed 8 pre-existing failures).

---

## Screens audited this pass

| # | Screen | Verdict | Action |
|---|--------|---------|--------|
| 1 | Home (`home_screen.dart`) | ✅ PASS | No changes — already production-grade |
| 2 | Scan Result (`scan/scan_result_screen.dart`) | ✅ PASS | Honest by design (assessment-pending) |
| 3 | Product Detail (`product/product_detail_screen.dart`) | 🔴→✅ FIXED | Removed fabricated health label |
| 4 | Ingredient Explainer (`ai/…`) | ✅ PASS | Minor token nit only (not blocking) |
| 5 | Healthy Alternatives (`alternatives/…`) | 🟡→✅ FIXED | Added image decode cap (60fps) |
| 6 | Saved Products (`saved_products/…`) | 🟡→✅ FIXED | Replaced timer-leaky stagger |
| 7 | Recall Alerts (`recall/…`) | 🟡→✅ FIXED | Replaced timer-leaky stagger |
| 8 | Allergen Profile (`allergen/…`) | 🟡→✅ FIXED | Replaced timer-leaky stagger |

---

## Fixes applied

### 🔴 HIGH — Honest-data violation (Product Detail)
**Problem:** `_HealthAssessmentSection` hardcoded `HealthLabelChip(label: 'Moderate')` plus
five fixed health badges for **every** product. The `ProductResponse` DTO has no health
fields (only id/name/ean/brand/category/imageUrl), so this was a fabricated rating shown to
users regardless of real data — a direct violation of the "render only what the backend
returns" rule.
**Fix:** Replaced with an honest **"Assessment pending"** state + neutral unknown flag chips,
matching the pattern the Scan Result screen already uses. The real `HealthLabelChip` remains
in the healthy-alternatives section, where it renders an actual backend `healthScore`.
**Verified:** stale test updated to assert the honest state; product tests green.

### 🟡 MEDIUM — Timer-leaky entrance animation (3 screens)
**Problem:** Saved Products, Recall Alerts, and Allergen Profile drove their staggered
entrance with `Future.delayed(...)`, which the project's own steering (visual-assets.md
§2.5/§12) explicitly bans: *"never `Future.delayed` — it's timer-leaky under tests."* A
pending delayed callback can outlive the widget and trips the test pending-timer guard
(the same class of bug fixed in the splash bootstrap in Phase 0).
**Fix:** Replaced with a single `AnimationController` + `Interval`-based stagger (the same
approach the Home screen's `_Stagger` uses) — no orphan timers, reduced-motion safe.

### 🟡 MINOR — Image decode cap (Healthy Alternatives)
**Problem:** the 80×80 product thumbnail used `CachedNetworkImage` with no decode cap,
decoding full-resolution bitmaps into a small box (memory + scroll jank risk).
**Fix:** added `memCacheWidth: 160` (≈2× for retina).

---

## Confirmed-good (no change needed)
- **Home** — per-tile skeletons, last-known-value KPIs (never flicker to dash mid-session),
  `RepaintBoundary` + `cacheWidth` on every image, `BrandedImage` never-crash fallback,
  no auto-advance carousel timer, tokens throughout, ink-scrim for banner text legibility.
- **`BrandedImage`** — the "blank slot with a name, never a crash" contract: `errorBuilder`
  degrades to a captioned tile, skeleton→crossfade for the static-UI feel, `cacheWidth` decode.
- **Scan Result** — health gauge correctly shows a dashed "–" + "Assessment pending" with
  honest copy; no fabricated values.
- **Ingredient Explainer / Healthy Alternatives / Saved Products / Recall / Allergen** —
  all honest-data clean, all with complete loading / empty / error branches and proper
  error isolation (one failed call degrades its own section, never the whole screen).

## Remaining minor (non-blocking) nits
- `ai/ingredient_explainer_screen.dart` — a couple of raw spacing magics (`top: 8`, bullet
  dot `6×6`) should use `RadhaSpacing`. Cosmetic; deferred.
- `recall_alerts_screen.dart` — severity stripe `width: 4` raw magic. Cosmetic; deferred.

---

## Verification
- `flutter analyze` on all five edited features → **No issues found**.
- Tests for product / alternatives / saved_products / recall / allergen → **17 / 17 passing**.
- No production source left in a broken state; every edit is small and reversible.

## Next phases (queued)
- **Phase 2:** Expiry → Tasks (consumer + ops split).
- **Phase 3:** Inventory / GRN.
- **Phase 4:** Reports / OHS (paid, locked-overlay states).
- **Phase 5:** Account (Profile / Settings / Subscription / Support).
- **Phase 6 (decided):** build a real product browse off `/api/v1/products`, upgrading the
  category quick-view into a true product grid with `BrandedImage` fallbacks. Open item to
  confirm when reached: client-side category grouping vs. a backend `?category=` param
  (will pick client-side if `product_dto` exposes category — **it does**, so no BE change needed).
