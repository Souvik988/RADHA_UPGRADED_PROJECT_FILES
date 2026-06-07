# 10 · Scan Result — `/scan/result/:ean`
Mode: **both** · Tab/Stack: **drill-down from Scan** · Gate: none (health detail may be premium-gated)

> The payoff screen — every scan leads here. The richest single-product view in the app.
> Must feel instantly valuable and visually premium. Governed by the Bible.

---

## Story arc
**Human beat** (the product IS the protagonist — big hero image, real name) →
**Substance** (health score + badges + EAN verification + allergen flags + ingredient explainer) →
**Action** (Add to expiry / Add to stock / Save / Share).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| Product data | `GET /products/lookup/{ean}?storeId=` | products |
| Allergen check | `GET /allergen/check/{productId}` | allergen |
| Ingredient explainer | `GET /ai/ingredients/explain` (on demand) | ai / BE-40 |
| Healthy alternatives | `GET /healthy-alternatives/{productId}` (on demand) | BE-41 |
| Add to expiry | `POST /expiry` | expiry |
| Add to inventory | `POST /inventory/movements` | inventory |
| Save product | `POST /shopping-list/items` | shopping-list |
| Record session item | `POST /scan-sessions/{id}/items` (if session active) | scans |

---

## Scroll zones (top → bottom)

### Z-HERO — Product hero band *(~240 dp)*
- **Layout:** full-bleed white card top zone. Left-aligned content with a product cutout image
  (220×180 dp) anchored to the right, overlapping into Z1.
- **Content left:**
  - Back chevron + "Scan Result" slim header (overlaid, `rgba(255,255,255,0.9)` bar).
  - Product name `headlineMedium` `w800` ink `#1C1917` (max 2 lines).
  - Brand + category `bodyMedium` ink-soft `#57534E`.
  - **EAN verification pill** (§3.9): `matched` → green ✓ "Approved product"; `not-in-list` →
    danger ✗ "Not in approved list"; `no-list` → warn ℹ "No list uploaded"; `checking` → spinner.
  - Size/weight `bodySmall` mono ink-soft.
- **Product image:** clean cutout, `md` sunken well `#F5F1E8`, consistent padding, no clipping.
- **Tokens:** band `#FFFFFF`, name `w800`, EAN pill (§3.9 tokens), image 220×180, `radius.lg` card.
- **Motion:** Hero widget (product thumb → this image, Hero tag = `product_${ean}`); name fades up
  200 ms easeOut; EAN pill slides in 120 ms after name.
- **A11y:** image alt = product name; EAN pill `Semantics` reads full status; back labeled.

### Z1 — Health assessment card *(eyebrow: "HEALTH PROFILE")*
- **Layout:** raised `#FFFFFF` card `radius.lg`, full-width minus `space16` H margin.
- **Health label chip:** large pill — "Healthy" green `#15803D` / "Moderate" amber `#B45309` /
  "Unhealthy" danger `#B91C1C` — with icon + label `w700`. One focal point per card.
- **Attribute badges row:** horizontal scroll of pills:
  - Sugar level, Fat level, Salt level, Processed flag, Child-suitable flag — each is a small
    pill with an icon, colored by severity (green/amber/red). Max 5-6 pills.
- **Allergen row** (if check complete): "Your allergens: ✗ Dairy · ✗ Gluten" danger chips OR
  "No allergen conflicts" green row. Loaded from `GET /allergen/check/{productId}`.
- **Tokens:** health chip `radius.full`, attribute pills `radius.full` at 8% tint bg; allergen
  row danger `#B91C1C`; `space12` gap between pills.
- **Motion:** card fades up on scroll reveal; health chip animates scale 0.8→1.0 on enter (160ms).
- **States:** loading → skeleton chips row; no health data → "Health data unavailable" ink-soft.

### Z2 — Ingredient explainer *(eyebrow: "INGREDIENTS", collapsed by default)*
- **Layout:** collapsible section. Header row: eyebrow + chevron. Collapsed: shows first 2 lines
  of ingredients list (truncated, ink-soft). Expanded: full ingredient list + an orange
  **"Explain ingredients" CTA button** that calls `GET /ai/ingredients/explain` and renders
  the AI response in a sheet (S2).
- **Tokens:** collapse animation 250 ms easeOut height; chevron rotates 0→180°.
- **Motion:** expand/collapse height animation; "Explain" button press-scale 0.97.

### Z3 — Healthy alternatives *(eyebrow: "HEALTHIER OPTIONS", on-demand)*
- **Layout:** lazy-loaded horizontal snap rail of up to 4 product cards from
  `GET /healthy-alternatives/{productId}`. Each card: thumb + name (2 lines) + health chip.
  "Load alternatives" text button triggers the fetch (not auto-loaded to save quota).
- **Tokens:** card `radius.md`, `space12` gap, rail horizontal snap.
- **States:** not-yet-loaded → "Load alternatives" CTA; loading → 3 skeleton cards; empty →
  "No healthier alternatives found" ink-soft; error → retry.

### Z4 — Pinned action bar *(always visible above home indicator)*
- **Layout:** 72 dp raised `#FFFFFF` bar, `space16` H padding, `space8` between actions.
  Left: "Add to expiry" outlined button (accent-deep border + label). Centre: "Add to stock"
  outlined. Right: "Save" orange filled primary CTA. Overflow "⋮" opens S3.
- **Tokens:** primary CTA `radius.full` orange; outlined `radius.full` accent-deep border.
- **Motion:** bar slides up from bottom on Z-HERO completion (spring 240ms); press-scale 0.97.
- **A11y:** each button labeled; overflow menu labeled "More actions".

---

## Sub-surfaces

### S1 · Share sheet
Standard OS share sheet triggered from overflow ⋮. Pre-fills: product name + EAN + health label.

### S2 · Ingredient explainer sheet
Bottom sheet `xl`. Title "Ingredient Explainer". Renders AI markdown response in a scrollable
view. Loading state: skeleton paragraph lines with shimmer. Error: retry. Footer: "Powered by
RADHA AI" ink-soft.

### S3 · More actions sheet
Overflow sheet: "View full product detail", "Report incorrect data", "Add to recall watchlist",
"Share product". Each is a labeled row with glyph.

---

## State gallery
`default (matched EAN, healthy product)` · `not-in-list (danger pill)` · `unhealthy product` ·
`allergen conflict` · `loading` · `product not found (404)` · `ingredient explainer open`.

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| C0 | Full Scan Result mockup | `generate_ui_mockup` | `assets/mockup/scan-result.png` | Scan result screen: product hero band showing "Good Day Cashew Cookies 200g" with a biscuit product cutout right-aligned, green EAN verified pill "Approved product", below it Health Profile card with "Moderate" amber chip and 5 attribute pills (Sugar High red, Fat Medium amber, Salt Low green, Processed yes amber, Child suitable yes green), allergen row "No conflicts" green, then collapsible ingredients zone, then healthy alternatives rail (3 cards), then pinned action bar "Add to expiry + Add to stock + Save". Warm cream palette, orange accents. iPhone 15 frame. |
| C1 | Health badge set (5 states) | `generate_icon_set` | `assets/icons/health-badges.png` | 5 health attribute pill icons: sugar-drop, fat-droplet, salt-shaker, processed-factory, child-star. Single weight warm rounded glyphs, 24px optical size, solid ink #1C1917 on transparent. |
| C2 | Scan result states mockup | `generate_ui_mockup` | `assets/mockup/scan-result-states.png` | Two panels side by side: LEFT = "Not in approved list" danger state (red verification pill, red border on card), RIGHT = "Unhealthy product" state (red "Unhealthy" health chip, danger badges for sugar/fat/salt, allergen conflict warning row in red). Same iPhone 15 framing, warm cream palette. |

---

## Motion checklist (Emil)
Hero transition thumb→full ✓ · name fade-up ✓ · health chip scale-in ✓ · collapse animation ✓ ·
pinned bar spring-up ✓ · press-scale all CTAs ✓ · reduced-motion: all instant ✓.

## Accessibility checklist
product image alt-text ✓ · health chip announced ✓ · attribute pills labeled ✓ · allergen
conflicts announced ✓ · action bar buttons labeled ✓ · collapse state announced ✓.

## Anti-slop gate
product cutout not a stock blob ✓ · health chip color-coded not just colored ✓ · EAN pill reads
functional not decorative ✓ · ingredient section collapses (not always expanded) ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion ✓ · all states present ✓ · slop gate ✓ · wiring intact ✓.
