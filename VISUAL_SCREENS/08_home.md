# 08 · Home (Store Command) — `/home`
Mode: **both** (business-first layout; consumer variant noted) · Tab/Stack: **root tab 1 of 5** · Gate: none

> This is the **anchor screen** and the quality reference for the entire app. Every other screen
> inherits its rhythm. Governed by `.kiro/steering/visual-assets.md` (the Bible); all tokens,
> motion, the image-gen blocks (§6.1/§6.2), and the Scroll Grammar (§5) are cited, not repeated.
> Quality bar: **beat the reference mockup.**

---

## Story arc
**Human beat** ("Hi Priya 👋 — manage your store, stay ahead", her storefront lit warm) →
**Substance** (4 KPI tiles → one orange promo → quick actions → top categories → expiry &
store-health split → recently scanned) → **Action** (the orange promo CTA + persistent Scan in nav).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| Header greeting + avatar | `authUserProvider` / `GET /me` | BE-08 | First name only; fallback "Hi there". |
| Store picker | `currentStoreProvider`, `storesProvider` / `GET /stores` | stores | If 1 store → chip is static (no chevron sheet). |
| Notifications bell + count | `unreadNotificationsProvider` / `GET /notifications?unread=1` | notifications | Badge hidden if 0; never fake a number. |
| KPI: Expiring soon | `expiringSoonCountProvider` / `GET /expiry?window=near` | expiry | Count only; tap → `13_expiry_list` pre-filtered "near". |
| KPI: Low stock | `lowStockCountProvider` / `GET /inventory/low-stock-alerts` | inventory | Gated feature → tile shows lock glyph if not entitled. |
| KPI: Tasks due | `tasksDueTodayProvider` / `GET /tasks?due=today` | tasks | Count of today's open tasks. |
| KPI: GRNs pending | `grnPendingProvider` / `GET /grn?status=pending` | grn | Gated → lock glyph if not entitled. |
| Promo banner | `homePromoProvider` (server-driven slots) / `GET /dashboard/home-cards` | client-dashboard BE-30 | Each slot maps to a **real** route (audit/expiry/GRN/subscription). No rewards. |
| Quick actions | static + entitlement flags | — | Locked actions render with lock glyph, route to `38_subscription`. |
| Top categories | `categoriesProvider` / `GET /products/categories` | products | Cutout = licensed asset; label from API. |
| Store-health banner | `ohsSummaryProvider` / `GET /dashboard/ohs` | BE-30 / BE-52 | "assessment pending" honest state if no score yet. |
| Recently scanned | `recentScansProvider` / `GET /scans?limit=5` | scans | Name or token; expiry date mono + status dot. |
| Search | `globalSearchProvider` / `GET /search` | — | "Search products, tasks, GRNs…" placeholder is real scope. |

**Consumer-mode variant:** greeting + consumer KPIs (today's scans · saved · expiring) + consumer
promo (premium / family) + consumer quick actions (Scan · Add expiry · Allergens · Saved) + recent
scans. Same grammar, different data. Detailed in this file's *Variants* block.

---

## Scroll zones (top → bottom)

### Z-HERO — Storefront greeting band  *(~176 dp, parallax)*
- **Layout:** full-bleed warm band; cream→`#FFF3E6` tonal wash; illustrated low-poly **storefront
  + RADHA awning + parcels + warm dunes/skyline** anchored top-right (the reference's warmth,
  refined, muted — not glossy). Left-aligned text column.
- **Content:**
  - Row 1 (top inset): **store-picker chip** (§3.3) left — `storefront` glyph + "Priya Store" +
    chevron, hairline, `surface raised`; right cluster — **notifications bell** (unread dot
    `#EA580C`) + **avatar** (32 dp, hairline ring).
  - Row 2: greeting **"Hi Priya! 👋"** `displaySmall`/`headlineLarge` `w800` ink `#1C1917`.
  - Row 3: sub **"Manage your store. Stay ahead."** `bodyMedium` ink-soft `#57534E`.
- **Search bar** (docked at hero base, overlaps the seam by 24 dp so it reads as a pinned object):
  pill, `radius.full`, `surface raised`, hairline, `magnifier` glyph + placeholder "Search
  products, tasks, GRNs…" + trailing **scan glyph** button (opens `09_scan`). To its right a small
  **Veg/Non-veg** segmented filter (product filter only — *not* a search mode).
- **Tokens:** padding `space16` H; greeting→sub gap `space8`; band radius bottom `xl`.
- **Imagery brief →** `assets/illustration/home-storefront.png` (see asset checklist A1).
- **Motion:** illustration parallax ~0.5× scroll; greeting + sub fade-up stagger 40 ms on cold
  start; at ~120 dp scrolled the band compresses to a sticky slim bar (compact "Priya Store" +
  bell + avatar). Search bar gains a subtle elevation as it pins under the slim bar.
- **A11y:** greeting `Semantics(header:true)`; bell `Semantics('Notifications, 3 unread')`;
  storefront illustration `excludeSemantics`. Focus order: store chip → bell → avatar → search.
- **States:** loading → greeting/sub skeleton lines + chip skeleton; offline → thin `BannerBar`
  ("You're offline — showing last synced data") docks under the search bar.

### Z1 — KPI bento  *(eyebrow: "TODAY AT A GLANCE")*
- **Layout:** 2×2 (or 1×4 scroll on narrow) grid of **KPI tiles** (§3.4), `space12` gutters,
  zone padding `space16` H, top gap `space24` from hero.
- **The four tiles (business):**
  1. **Expiring soon** — Cat-amber `#B45309`, `clock` glyph, mono count (e.g. `18`), label "items",
     micro-CTA "Action needed ›". Tap → `13_expiry_list?filter=near`.
  2. **Low stock** — Cat-violet `#6D5BD0`, `box` glyph, mono `7`, "items", "Restock now ›". Gated.
  3. **Tasks due** — Cat-orange `#EA580C` (brand-as-category here), `clipboard` glyph, mono `5`,
     "today", "View tasks ›". Tap → `16_tasks_list?due=today`.
  4. **GRNs pending** — Cat-green `#15803D`, `truck` glyph, mono `2`, "to review", "Review now ›". Gated.
- **Tokens:** tile `radius.lg`, raised `#FFFFFF`, warm shadow elev-1, hairline; tint well behind
  glyph at 10 % alpha; number `displaySmall` mono in tint color; label `bodySmall` ink-soft;
  micro-CTA `labelMedium` accent-deep with chevron.
- **Motion:** tiles fade-up stagger 60 ms on reveal; **each mono number counts up 0→value** once;
  press-scale `0.97` + `haptic.light`.
- **A11y:** each tile one `Semantics` ("Expiring soon, 18 items, action needed"); ≥48 dp target.
- **States:** loading → 4 skeleton tiles; zero-value → number `0` + softened label ("All clear")
  *(never hide a tile)*; **locked** (Low stock / GRN not entitled) → tile dims to 60 %, lock glyph
  top-right, tap → `38_subscription`.

### Z2 — Hero Story Banner (the showpiece) *(no eyebrow label — it *is* the focal point; §3.5★)*
- **Concept:** today's **mission**, told cinematically — RADHA hands Priya her quest and shows
  her winning it (§1B). Replaces any "promo"; **no scan-to-earn / rewards** (not a backend feature).
- **Layout:** wide `radius.xl` layered card, zone gap `space32`. **Left (~56 %):** mission eyebrow
  "AAJ KA KAAM · TODAY'S MISSION" `labelMedium` on `#FED7AA`; **2-line headline** `w800` white
  naming the stakes; **progress ribbon** (mono "12 of 18 done" + filling orange bar); **white CTA
  pill** verb-first. **Right:** 3D-lite hero object on a soft warm **spotlight halo** with
  micro-parallax; ≤8 % marigold-string motif along the top edge.
- **Honest, real missions** (server-driven `GET /dashboard/home-cards`; one shown + carousel):
  *"18 items expire before Friday — clear the shelf"* → Open expiry (`/expiry`) · *"Audit aisle 4
  — 12 EANs to verify"* → Start audit (`/scan-sessions`) · *"2 GRNs waiting"* → Review (`/grn`) ·
  *"Unlock Reports & store health"* → See plans (`/subscription`).
- **All-clear win beat:** when no urgent mission — *"Shabaash! Your store's in great shape today"*
  + a mono day-recap (scans / cleared / received), marigold accent + a brief spotlight shimmer.
- **Tokens:** deeper warm merchandised shadow; spotlight `#FFF3E6`; ribbon bar `#EA580C` on
  `#FED7AA` track; white CTA `radius.full`, label `#EA580C`.
- **Motion:** fade-up + 4 dp lift; ribbon counts up; spotlight shimmer only on all-clear / festive;
  carousel auto-advance 6 s (pauses on touch / reduced-motion); dots animate width. One orange CTA.
- **A11y:** banner = one `Semantics(button)` reading eyebrow + headline + progress; carousel index
  announced ("Mission 1 of 3").
- **States:** loading → one warm skeleton (never an empty fill); all-clear → win-beat variant;
  locked → value mission routes to subscription.

### Z3 — Quick actions  *(eyebrow: "QUICK ACTIONS" + "Customize" trailing)*
- **Layout:** scrollable row of 6 **action tiles** (§3.6): Scan barcode · Add expiry · Add task ·
  Create GRN · Recall check · Stock count. Tile = `md` well accent-tint `#FED7AA` (Scan well =
  stronger, accent `#EA580C` outline) + custom glyph accent-deep + label `labelMedium` below.
- **Tokens:** well 56 dp, `radius.md`, gap `space12`.
- **Motion:** press-scale `0.97` + `haptic.medium` on Scan, `haptic.light` others; row reveals
  with 30 ms stagger.
- **A11y:** each tile labeled; "Customize" opens reorder sheet (sub-surface S3).
- **States:** locked actions (Create GRN / Stock count if ungated) → lock glyph, route to subs.

### Z4 — Top categories rail  *(eyebrow: "TOP CATEGORIES" + "View all ›")*
- **Layout:** horizontal snap **category rail** (§3.7): cells = real product **cutout** in `md`
  `#F5F1E8` well + 2-line label (e.g. "Biscuits & Snacks", "Dairy & Eggs"). 6 visible + peek.
- **Imagery:** licensed cutouts, one lighting language; brief → asset checklist A3 (set).
- **Motion:** snap-scroll with momentum; cells fade-in on first reveal; press-scale.
- **A11y:** rail = horizontal scroll region; each cell labeled; "View all" → category index.
- **States:** loading → 6 shimmer wells; empty → omit (categories always exist in v1).

### Z5 — Expiry & Store-health split  *(two side-by-side info banners)*
- **Layout:** two `radius.lg` raised cards side by side (`space12` gap), zone gap `space24`.
  - **Left — "Stay ahead of expiry dates":** warm illustration (calendar + bell), title `w700`,
    sub `bodySmall` ink-soft, small orange "Add expiry" CTA → `14_expiry_create`.
  - **Right — "Store health at a glance":** **OHS gauge** (§3.10) mini or a `shield-check`
    illustration in Cat-teal, title, sub "Keep your store healthy & compliant", **green** "View
    dashboard" CTA → `48_ohs_dashboard` (locked overlay if unpaid). If no score: gauge shows "–"
    + "assessment pending".
- **Tokens:** the two cards may carry different category tints at 8 % (amber left, teal right) to
  differentiate — still quieter than any orange.
- **Motion:** gauge sweeps 0→value on reveal; cards fade-up stagger.
- **A11y:** each card one button-semantics; gauge value announced.
- **States:** OHS locked → right card shows value behind a tasteful blur + lock + "See plans".

### Z6 — Recently scanned  *(eyebrow: "RECENTLY SCANNED" + "View all ›")*
- **Layout:** 3–5 **product rows** (§3.8): thumb (cutout/placeholder) + name (or token) + meta
  (brand · size) + trailing **mono expiry** "EXP 14 Aug 2026" + status dot (green/amber/red) +
  overflow `⋮`. Rows divided by hairline.
- **Tokens:** row 64 dp, thumb 44 dp `md` well, name `titleMedium` `w600`, meta `bodySmall`
  ink-soft, date `monoLabel`, dot 8 dp.
- **Motion:** rows fade-up stagger 40 ms; row press → Hero thumb to `10_scan_result`; swipe-left
  reveals quick actions (save / add expiry).
- **A11y:** row = "Good Day Cashew, 200 g, expires 14 Aug 2026, fresh"; overflow menu labeled.
- **States:** loading → 4 skeleton rows; **empty** → `EmptyState` (§3.14): tonal `scan` badge,
  "No scans yet", "Scan your first product to see it here", orange "Scan now" → `09_scan`
  *(personality required — this is a second-read moment)*.
- **Bottom inset:** `space32` so the last row clears the nav.

### Z-NAV — Bottom navigation (§3.12)
Home(active) · Scan(center emphasized) · Expiry · Tasks · Profile. Active = orange glyph + label +
indicator; Tasks shows unread/count badge if any. 72 dp + safe-area. Custom glyphs (icon set §4-1).

---

## Sub-surfaces
- **S1 · Store-picker sheet** — bottom sheet `xl`, drag handle, list of stores (name, role chip,
  address, active radio in orange), "Add new store" row → `44_business_activation`. Spring enter.
  Brief → asset A6.
- **S2 · Notifications** — taps bell → `42_notifications` (full screen), not a sheet.
- **S3 · Customize quick actions sheet** — reorderable list of actions, toggle visible, drag
  handles, "Reset", orange "Save". Persists to prefs.
- **S4 · Search** — focusing search pushes `/search` results screen (recents + typeahead grouped
  Products / Tasks / GRNs). (Spec lives with search screen; entry point is here.)
- **S5 · Offline banner** — persistent `BannerBar` under search when `connectivityProvider` is off.

---

## State gallery (generate a mockup for each)
`default (populated)` · `loading (skeletons across all zones)` · `partial (some KPIs zero / OHS
pending)` · `empty recently-scanned` · `locked (Low-stock/GRN/OHS gated)` · `offline (banner +
last-synced)` · `consumer variant` · `festive skin (optional — marigold accent + diya micro-motif
on promo only)`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Home mockup (default)** | `generate_ui_mockup` | `assets/mockup/home.png` | SCREEN: Home (/home). STORY: storefront greeting → 4 KPI bento → one orange promo → quick actions → categories rail → expiry+store-health split → recently scanned → 5-tab nav. FOCAL: the orange promo banner. ZONES top→bottom as in this file. COPY (verbatim): "Hi Priya! 👋", "Manage your store. Stay ahead.", KPIs "Expiring soon 18 items / Low stock 7 items / Tasks due 5 today / GRNs pending 2 to review", hero story banner "AAJ KA KAAM · 18 items expire before Friday — clear the shelf · 12 of 18 done · Open expiry", "Recently scanned" rows "Good Day Cashew 200g EXP 14 Aug 2026 (green dot)", "Amul Butter 500g EXP 20 Sep 2026 (green)", "Pepsi 2.25L EXP 10 Dec 2025 (red)". Real product cutouts: yes. Motion-implied: parallax header, fade-up stagger, KPI count-up. |
| A1 | Storefront hero illustration | `generate_hero` | `assets/illustration/home-storefront.png` | Warm low-poly Indian dukaan storefront with RADHA striped awning, neat parcels, soft warm dunes/skyline, top-right composition on transparent/cream, muted burnt-orange + cream + terracotta, soft depth, NOT glossy, leaves left third clear for text. |
| A2 | KPI category glyph set (4) | `generate_icon_set` | `assets/icon/kpi-set.svg` | One batch: clock(expiry), box(low-stock), clipboard(tasks), truck(GRN) — single ~1.75dp weight, ~2px radius, rounded terminals, each renderable in its tint. |
| A3 | Category cutout set (8) | `generate_image` | `assets/illustration/products/cat-*.png` | 8 clean product cutouts on white, one lighting: biscuits, breakfast/spreads, dairy/eggs, beverages, personal-care, household, staples, frozen. Consistent in-cell padding. |
| A4 | Hero Story Banner scene (mission) | `generate_hero` | `assets/illustration/home-mission.png` | Cinematic merchandised mission scene for the orange #EA580C story banner: a 3D-lite lit shelf / audit clipboard + product cluster on a soft warm spotlight halo `#FFF3E6`, gentle floating accents, ≤8% marigold-string motif along the top edge, muted (not glossy), white-friendly, **leaves the left 56% clear** for headline + progress ribbon + CTA. NO gift/coin/reward/scan-to-earn motif. |
| A5 | Expiry + Store-health spot illustrations (2) | `generate_image` | `assets/illustration/spot-expiry.png`, `spot-storehealth.png` | Pair: (1) warm calendar + alert bell (amber family); (2) shield-check + subtle bar trend (teal family). Same illustration language, small, card-friendly. |
| A6 | Store-picker sheet mockup | `generate_ui_mockup` | `assets/mockup/home-store-sheet.png` | Bottom sheet: store list rows w/ role chips + active orange radio + "Add new store". Same system. |
| A7 | Nav glyph set (5) | `generate_icon_set` | `assets/icon/nav-set.svg` | home/scan/expiry/tasks/profile, inactive line + active orange-filled variants, Scan center-emphasis. |
| A8 | Loading + empty + consumer + festive mockups | `generate_ui_mockup` | `assets/mockup/home-{loading,empty,consumer,festive}.png` | One per state, same system; festive = marigold accent + tiny diya motif on promo only. |

---

## Motion checklist (Emil) — reduced-motion safe
parallax hero ✓ · fade-up + stagger per zone (once) ✓ · KPI count-up ✓ · gauge sweep ✓ · press-
scale 0.97 + haptics ✓ · carousel auto-advance (pauses) ✓ · Hero thumb→result ✓ · pull-to-refresh
(custom orange) ✓ · all `MediaQuery.disableAnimations`-gated ✓.

## Accessibility checklist
header semantics ✓ · every tile/row/CTA labeled ✓ · focus order defined ✓ · ≥48 dp targets ✓ ·
WCAG-AA on orange-on-white CTA + ink-on-cream ✓ · 2.0× text-scale no clip (KPI bento reflows
1-col) ✓ · decorative illustrations excluded from semantics ✓.

## Anti-slop gate
one orange focal point ✓ · no nested cards ✓ · KPI tiles differ by tint not by being identical ✓ ·
real merchandised illustration not a stock blob ✓ · honest data ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/skeleton/locked present ✓ ·
slop gate ✓ · wiring intact (every provider above) ✓ · widget tests green ✓.
