# 44 · Business Activation — `/account/activate-business`
Mode: **consumer → owner** · Tab/Stack: **drill-down** (from Profile, Home store-sheet "Add store", or a touchpoint banner) · Gate: **role = consumer** (the only role that can activate)

> Governed by `.kiro/steering/visual-assets.md` (the Bible) + `CHARACTER_STORYTELLING_BIBLE.md`
> (Mor). Tokens, motion, image-gen blocks (§6.1/§6.2), Scroll Grammar (§5) are **cited, not
> repeated**. Quality bar: **beat the reference mockup.** Honest-data law: gate strictly on the
> `consumer` role + real `GET /account/touchpoints` flags; this is a one-way upgrade — design it
> with the gravity that deserves.

---

## Story arc
**Human beat** (aspirational header — *"Turn RADHA into your store's command centre"*, Mor `work`
in front of a warm dukaan + the owner protagonist) → **Substance** (value props of going business
→ a short, honest activation form: business name, store name, city) → **Action** (one orange
"Activate my business" CTA → upgrades consumer to owner with a new tenant + store).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| Eligibility / touchpoints | `touchpointsProvider` / `GET /account/touchpoints` | business-activation BE-35 | Returns which activation touchpoints to surface for this consumer. Drives whether the entry banner/this screen is offered. Don't show to non-eligible users. |
| Activate | `POST /account/activate-business` { businessName, storeName, city, … } | business-activation BE-35 | **Consumer-only**, 201 on success. Promotes user → owner, creates tenant + first store. One-way; confirm before firing (S1). |
| Role guard | `authUserProvider.role` | auth | If role ≠ consumer → screen shows the **already-business** state (Z-DONE), not the form. |
| Post-activation routing | new owner session → `/home` (business mode) | — | On 201, refresh session/token, route to business Home with a win-beat (S2). |

**Field truth:** only collect what `ActivateBusinessSchema` accepts. If the schema has just
business name / store name / city, the form has exactly those — no decorative "GST", "category",
or "logo upload" fields that the API ignores.

---

## Scroll zones (top → bottom)

### Z-HERO — Aspirational activation band  *(~196 dp, parallax)*
- **Layout:** tall warm band cream→`#FFF3E6`; back chevron; **eyebrow** "GROW WITH RADHA"
  `labelMedium` accent-deep; headline **"Turn RADHA into your store's command centre"** `w800`
  ink, 2 lines; sub "Activate a business account to unlock audits, expiry, tasks, GRN and store
  health." `bodyMedium` ink-soft. **Right/behind:** a refined warm **storefront illustration**
  with **Mor `work`** (apron/clipboard) standing proud out front — protagonist + lieutenant (§1B).
- **Tokens:** padding `space16` H; eyebrow→headline `space8`; headline→sub `space8`; band radius
  bottom `xl`.
- **Motion:** illustration parallax ~0.5×; text fade-up stagger 40 ms; Mor reduced-motion → static.
- **A11y:** headline header semantics; illustration `excludeSemantics`.
- **States:** loading → headline/sub skeleton.

### Z1 — Value props  *(eyebrow: "WHAT YOU UNLOCK")*
- **Layout:** 2×2 grid (or 1-col on narrow) of 4 **value tiles** (KPI-tile chassis, §3.4) — glyph
  in category tint + `w700` title + one ink-soft line:
  1. **Approved-EAN audits** (Cat-orange clipboard) — "Verify shelves against your list."
  2. **Expiry & GRN** (Cat-amber clock / Cat-green truck) — "Track dates, receive stock."
  3. **Staff tasks** (Cat-orange) — "Assign and track work."
  4. **Store health** (Cat-teal shield) — "An OHS score you can show off."
- **Tokens:** tile `radius.lg` raised, hairline, tint well 10 %; reuse Home KPI rhythm.
- **Motion:** tiles fade-up stagger 60 ms; press-scale (informational, no nav).
- **A11y:** each tile labeled; decorative glyphs excluded.
- **States:** static; loading → 4 skeleton tiles.

### Z2 — Activation form  *(eyebrow: "YOUR BUSINESS")*
- **Layout:** raised `radius.lg` form card, hairline. Fields (only what the schema accepts):
  - **Business name** — text field, cream fill, hairline, **orange focus ring**, inline validation.
  - **Store name** — text field (first store of the new tenant).
  - **City** — text field (or picker if the schema constrains it).
  - Helper line ink-soft: "You'll be the owner. You can add staff and more stores later."
- **Tokens:** field `radius.md`, label `labelMedium`, helper `bodySmall` ink-soft, danger on error.
- **Motion:** field focus → orange ring 150 ms; error shake (≤120 ms, reduced-motion: none).
- **A11y:** each field labeled + describedby its helper/error; logical focus order; keyboard "next".
- **States:** empty/typing/valid/invalid; submitting → fields disabled + inline spinner.

### Z3 — Activate action  *(pinned)*
- **Layout:** full-width orange **"Activate my business"** primary button pinned above home
  indicator; under it a quiet ink-soft line "This upgrades your account to a business owner."
- **Tap →** S1 confirm (because it's one-way), then `POST /account/activate-business`.
- **States:** disabled until required fields valid; submitting → label "Activating…" + spinner;
  error → inline danger banner + retry.

### Z-DONE — Already a business (role ≠ consumer)
- If the user already owns a business: replace the form with a calm state — **Mor `celebrate`**
  (small), title "You're already running RADHA for business", line "Manage stores from your
  profile.", secondary "Manage stores" → Profile store management. No duplicate activation.

### Z-NAV
None — drill-down. Back chevron returns to entry point; bottom nav hidden.

---

## Sub-surfaces
- **S1 · Activate confirm dialog** — centered, scrim, `0.95→1`+opacity (this is consequential):
  title "Activate business account?", body "You'll become the owner of '{businessName}'. This
  can't be undone.", orange **"Activate"** + ghost "Not yet". Mor `work` small icon.
- **S2 · Success win-beat** — on 201: full-screen **`MorCelebration`** overlay (marigold/turmeric
  petal burst, §3.5 celebration tokens, ≤800 ms, reduced-motion → static `celebrate` frame) +
  "Welcome, owner! Your store is live." → auto-route to business `/home`. This is the retention
  win beat (§1B law 3).
- **S3 · Error sheet** — activation failed (network/validation): **Mor `concern`** + the server
  message (honest) + orange Retry; never swallow the real error.

---

## State gallery (generate a mockup for each)
`default (form empty)` · `filled/valid` · `invalid (inline errors)` · `submitting` ·
`success win-beat (MorCelebration)` · `already-business (Z-DONE)` · `loading (skeleton)` ·
`error (Mor concern)` · `festive skin (optional — marigold accents on the value tiles)`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Business Activation mockup (default)** | `generate_ui_mockup` | `assets/v2/mockup/business-activation.png` | SCREEN: Business activation (/account/activate-business). STORY: aspirational header "Turn RADHA into your store's command centre" with a proud apron-wearing peacock mascot in front of a warm dukaan storefront → 2x2 "WHAT YOU UNLOCK" value tiles (Approved-EAN audits, Expiry & GRN, Staff tasks, Store health) → "YOUR BUSINESS" form (Business name, Store name, City) → full-width orange "Activate my business". FOCAL: the activate CTA. COPY (verbatim): "GROW WITH RADHA", "Turn RADHA into your store's command centre", "Activate a business account to unlock audits, expiry, tasks, GRN and store health.", "What you unlock", "Your business", "Business name", "Store name", "City", "You'll be the owner. You can add staff and more stores later.", "Activate my business". Real product cutouts: no. Motion-implied: parallax header, fade-up stagger, focus ring. |
| A1 | Owner + storefront hero illustration | `generate_hero` | `assets/v2/illustration/business-activation-hero.png` | Warm aspirational scene: an apron/clipboard peacock mascot (Mor `work`) standing proudly in front of a refined low-poly Indian dukaan with RADHA striped awning + neat shelves, muted burnt-orange + cream + terracotta, soft depth, NOT glossy, top-right composition leaving the left third clear for headline. |
| A2 | Success win-beat mockup | `generate_ui_mockup` | `assets/v2/mockup/business-activation-success.png` | Full-screen celebration: peacock mascot in celebrate pose with a tasteful marigold + turmeric petal burst (festive accent, celebration-only), headline "Welcome, owner! Your store is live." Warm, earned, not confetti-spam. |
| A3 | Value-prop glyph set (4) | `generate_icon_set` | `assets/v2/icons/activation-set.svg` | One batch RADHA warm rounded glyphs (~1.75dp, ~2px radius, rounded terminals): clipboard-check(audits), calendar+truck(expiry & GRN), staff-tasks(people+check), shield-check(store health). Each in its category tint. |

> **Mor reuse:** `work` / `celebrate` / `concern` frames + the `MorCelebration` widget already
> exist (`assets/v2/character/mor/static/` + `lib/design/widgets/mor_celebration.dart`) — reference,
> don't regenerate. Only A0–A3 are new renders.

---

## Motion checklist (Emil) — reduced-motion safe
header parallax ✓ · value tiles fade-up stagger ✓ · field focus ring 150 ms ✓ · submit spinner ✓ ·
**success MorCelebration petal burst (≤800 ms, reduced-motion → static celebrate)** ✓ · press-scale
0.97 + haptic.medium on activate ✓ · all `MediaQuery.disableAnimations`-gated ✓.

## Accessibility checklist
header semantics ✓ · every field labeled + error describedby ✓ · one-way nature stated in text +
confirm dialog ✓ · CTA disabled-state explained ✓ · ≥48 dp targets ✓ · WCAG-AA orange-on-white +
ink-on-cream ✓ · 2.0× text-scale: value grid reflows 1-col, form fields grow, no clip ✓ ·
decorative illustration + celebration excluded from semantics ✓.

## Anti-slop gate
one orange focal (activate CTA) ✓ · value tiles differ by tint, not identical clones ✓ · no nested
cards ✓ · form asks ONLY for schema-accepted fields (no fake GST/logo) ✓ · celebration is earned +
sparing ✓ · honest one-way upgrade gravity ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/submitting/done states ✓ ·
slop gate ✓ · wiring intact (touchpoints + activate + role guard) ✓ · consumer-only gate honored ✓ ·
widget tests green ✓.
