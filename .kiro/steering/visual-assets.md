---
inclusion: always
---

# RADHA Visual System & Asset Bible

> The single source of truth for how RADHA **looks, feels, and moves** — on every screen,
> every sub-page, every scroll section. This is the master bible: philosophy, locked
> tokens, component catalogue, icon catalogue, the **Scroll Grammar**, the motion spec, the
> **image-generation prompt system**, and the asset contract. The per-screen, scroll-by-scroll
> production specs live in **`VISUAL_SCREENS/<nn>_<slug>.md`** (one file per screen, each
> independently buildable) and are governed by this file. If a pixel ships in RADHA, its
> rule lives here or in its screen file.
>
> **North star:** RADHA must look like a real, premium product a Gujarat retail client is
> proud to demo — *content-heavy, merchandised, visually-told, alive, unmistakably Indian-warm.*
> Quality bar on every artifact: **beat the reference mockup the user provided.** Think the
> merchandising polish of Blinkit / Zepto / Instamart / Swiggy Instamart crossed with editorial
> warmth and the festive confidence of a great Gujarati storefront — but unmistakably RADHA:
> warm cream canvas, confident burnt-orange, real products, custom glyphs, motion that breathes.

---

## 0. How to use this bible (read first, every time)

1. **Master + screens.** This file = the system. `VISUAL_SCREENS/<nn>_<slug>.md` = the
   scroll-by-scroll build spec for one screen. The screen index is §11. Each screen file is
   self-contained: a developer or an agent can open one file and build that screen end to end
   without reading the other 40 — because the shared rules are all here and cited by token.
2. **Image-first law.** *Every* visual artifact passes through `kiro-gpt-bridge` **before**
   code. Full-page mockup → component visual → banner → icon set → illustration → product
   cutout → background. Generate the asset, save it, eyeball it against §10, *then* implement
   Flutter that matches it at first render. No screen is coded from imagination. (§8)
3. **Skills are the craft engine, not flavor** — invoke them aggressively, every screen (§9):
   - **`impeccable`** → art direction, IA, color strategy, the anti-slop gate, critique/polish.
   - **`design-taste-frontend`** → the hard dials. For RADHA: **VARIANCE 7 · MOTION 6 · DENSITY 7**
     (content-heavy, merchandised — denser than its default 4, but always sectioned + breathing).
   - **`emil-design-eng`** → motion + micro-interaction polish (easing, durations, press-scale,
     stagger, reduced-motion, perceived performance). Translate its CSS to Flutter.
   - **`imagegen-frontend-mobile`** → the art-direction brain for *every* `kiro-gpt-bridge`
     brief. Its dials for RADHA: ART_DIRECTION 9 · PLATFORM_AWARENESS 9 · CLARITY 10 ·
     CONSISTENCY 10 · COLOR_DISCIPLINE 10 · TEXTURE 6 · DENSITY 6 (richer than its default 3,
     because RADHA is merchandised) · MOCKUP_FRAME 9 · TEXT_READABILITY 10.
   - **`high-end-visual-design`** → the "make it feel expensive / kill the cheap defaults" pass.
   - **`ui-ux-pro-max`** → Flutter component patterns, palette/typography math, UX heuristics.
   - **`redesign-existing-projects`** → upgrade the *existing* screen without breaking wiring.
   - **`stitch-design-taste`** → discipline for writing/extending these very design specs.
   - **`full-output-enforcement`** → when authoring a screen file, output it **complete** —
     never `// rest of sections` or a truncated brief. Every scroll section, fully specified.
4. **Function is sacred; visuals are the change.** RADHA stays a retail-audit / expiry / tasks
   / inventory / GRN / subscription tool. Preserve every Riverpod provider, API call, DTO,
   validation, permission/entitlement gate, and route. **No new features** (no cart, no
   checkout-beyond-subscription, **no scan-to-earn rewards** — the reference's "Scan more, earn
   more" is *not* a RADHA feature) unless separately specced.
5. **Honest data discipline.** Render only names/numbers the backend returns. Where an endpoint
   returns IDs/tokens, show the token or a tasteful placeholder — never fabricate a product name
   to fill a pretty cell. Empty/locked/loading are *designed* states, not fallbacks.
6. **Real product imagery is approved** per `BRAND_ASSETS_LICENSE.md` (client holds rights):
   clean cutouts on white/neutral, consistent lighting, consistent in-cell padding.

---

## 1. Design philosophy — visual storytelling

RADHA is not a form with buttons. It is a **story told in panels**: every screen opens with a
human moment (who you are, which store, what matters right now), escalates into dense glanceable
value, and resolves into one clear next action.

**The three storytelling laws (every screen obeys):**
1. **Open with a human beat.** Greeting, store identity, a warm illustrated header or a real
   storefront. The first ~140–180 px of every primary screen feels *authored* — never a bare
   AppBar. Secondary screens get a slimmer but still-styled header band.
2. **Escalate into substance.** Below the header, pack real organised value — KPI tiles,
   merchandised banners, category rails, product rows, status timelines. **Density is a feature;
   clutter is the enemy.** Density is *earned* through a strict grid, generous internal padding,
   clear sectioning with eyebrow labels, and **one obvious focal point per region.**
3. **Resolve into action.** Every screen ends with (or floats) one unmistakable next step in
   brand orange. **One primary orange CTA per region — never two competing.**

**Content-heavy *and* calm (the RADHA balance).** We run `design-taste` DENSITY 7 (merchandised)
but honor `imagegen-frontend-mobile`'s breathe rule: density lives *inside* zones (tight grids,
rich tiles); **generous space sits *between* zones** (`space24`–`space32` section gaps). Dense
zone, big breath, dense zone. Never a wall; never a void.

**Second-read moments (mandatory).** Per `impeccable`: every screen rewards a second look — a
mono KPI ticking up on entry, a category glyph with a custom RADHA twist, a banner with real
depth, an empty state with personality, a festive micro-motif at a section seam. **No
second-read moment = not done.**

**The anti-slop gate (mandatory before "done").** Run `impeccable`'s AI-slop test:
- First-order: could someone guess the look from the category alone ("retail app → generic
  grocery green")? Rework until *no*.
- Second-order: could they guess it from category + obvious anti-reference? Rework until *no*.
- If anyone could say "an AI made that" without doubt — it failed. **Fix the structure, not the paint.**

---

## 1A. The Gujarati soul (cultural layer — tasteful, never kitsch)

The client and core market are **Gujarat** retail. The app must feel warm and *of that world*
without a single cliché. This is art direction, not decoration.

- **Do:** warm festive confidence (the palette already carries it — burnt orange + cream +
  turmeric/marigold accents reserved for celebratory beats); generous merchandising; the feel
  of a proud, busy, organised dukaan (shop). A faint **bandhani-dot** or **marigold-petal** or
  **temple-arch** motif may appear *only* at section seams / empty-state illustrations /
  celebratory overlays at ≤8% presence, integrated into the system — never a border slapped on.
- **Don't:** stereotype graphics (no garba dancers on a KPI tile), no rangoli wallpaper behind
  text, no saffron-white-green flag motif, no Devanagari-as-decoration where the locale is
  Latin. Cultural warmth is a *mood*, carried by color, light, and product, not by stickers.
- **Festive states** (Diwali / Uttarayan / Navratri) are an *optional themed skin* of the same
  tokens (marigold accent swap, kite/diya micro-motif on celebratory overlays only) — specced
  per screen as a variant, never the default.
- **Language reality:** UI locales are en/hi/ta/te/bn/mr. Gujarati (`gu`) is **not** shipped in
  v1 — flag it as a recommended add for this client, but do **not** fake Gujarati copy in
  mockups. All bilingual layouts must survive Devanagari/Tamil/Telugu/Bengali line-height and
  the 2.0× text-scale rule (§ design-system a11y).

---

## 1B. The visual storytelling system (the narrative spine)

RADHA tells one continuous story: **"You run a tight, proud store — RADHA is your second-in-
command."** The owner/manager is the protagonist; RADHA is the trusted lieutenant who hands them
today's mission and celebrates the win. Every surface advances that story. Four devices, used
deliberately (never as decoration):

1. **The daily mission frame.** The Home **Hero Story Banner** (§3.5★) opens each day as a
   *mission*: what the store needs *today*, framed with real stakes and a one-tap path. Missions
   are backend-driven (expiry to clear, aisle to audit, GRN to receive, health to lift) — **never
   invented, never "rewards."**
2. **Protagonist continuity.** Greeting by name, the store's own name + storefront, and a quietly
   persistent "today" thread the owner watches move as they work (18 → 12 → 0 expiries). **Numbers
   are the plot; mono type is its voice.**
3. **The win beat.** Completing a meaningful action (audit closed, shelf cleared, GRN received,
   OHS milestone) triggers a *designed* celebration — brief, warm, festive-accented (marigold
   confetti / diya spark on the Diwali skin) — earned and sparing. This is the retention hook: the
   **fourth open**.
4. **Merchandised substance.** Between mission and win, value is merchandised like a great shop
   shelf — categories, products, KPIs arranged with intent and warmth, so the app feels like
   walking a well-kept *dukaan*, not reading a dashboard.

**Gujarati context, professionally.** Warmth is carried by **light, color, product, and the
storefront** — plus optional warm-voice microcopy in a shipped locale (Hindi/English). Festive
**skins** (Diwali / Uttarayan / Navratri) are the story's seasonal chapters: same tokens, marigold/
turmeric accent swap, kite/diya micro-motifs on celebratory surfaces only. **Recommended:** add
**Gujarati (`gu`) as a v1.1 locale** for this client so the story can speak in the owner's own
language (it is not shipped today). Until then, **do not fake Gujarati copy** in mockups — carry
the warmth visually.

---

## 2. Brand foundations — LOCKED tokens

These map 1:1 to `radha_app/lib/design/tokens.dart` (`RadhaColors`, `RadhaSpacing`,
`RadhaRadii`, `RadhaMotion`, `RadhaTypography`). **Never hard-code values in features** — always
read tokens. When briefing the bridge, always cite **exact hex**.

> Note on the stale doc: `FRONTEND_DESIGN_SYSTEM.md` describes an older **emerald `#10B981`**
> system. That is **superseded.** The warm-orange system below is the live brand. If you touch
> `FRONTEND_DESIGN_SYSTEM.md`, reconcile it to these tokens or mark it deprecated.

### 2.1 Color — core brand (immutable)

| Token | Hex | Role |
|---|---|---|
| Accent (primary) | `#EA580C` | THE brand accent — primary CTA, active nav, focus ring, gauge fill, brand mark, the one hero promo banner per region |
| Accent deep | `#9A3412` | Pressed CTA, section eyebrow headers, dark-surface accent |
| Accent tint | `#FED7AA` | Soft badges, highlight chips, quick-action wells, warm hover, low-opacity watermarks |
| Ink | `#1C1917` | Primary text, marks, dark surfaces. **Never `#000000`.** |
| Ink soft | `#57534E` | Secondary text, captions, dimmed labels |
| Surface (canvas) | `#FFFBF5` | Default page background — warm cream, **never flat white** |
| Surface raised | `#FFFFFF` | Cards, sheets, banners, product cells |
| Surface sunken | `#F5F1E8` | Skeletons, empty wells, image backers |
| Hairline | `#E7E1D4` | Borders, dividers, table rules (1 px) |
| Success | `#15803D` | Confirmed, fresh, in-stock, matched-EAN |
| Warn | `#B45309` | Expiring soon, low stock |
| Danger | `#B91C1C` | Expired, not-in-list, errors (sparing) |
| Complement (teal) | `#0F766E` | Very sparing — one info cue or one chart series. Never a 2nd brand accent. |

**Festive accent (celebratory beats only):** Marigold `#F59E0B` + Turmeric `#FACC15` — used in
confetti, success overlays, referral/reward-free celebration moments, and the optional festive
skin. **Never** as a CTA or a competing brand hue on a normal screen.

**Color discipline (from `impeccable`):** tint every neutral toward the brand hue — no pure
`#000`/`#fff`. RADHA's strategy is **Restrained-plus**: tinted-cream neutrals + orange accent
≤10 % of surface, *plus* a controlled category-tint set (below) used only as quiet low-alpha
tile backgrounds. Orange never shares "hero" status on a screen.

### 2.2 Color — category / KPI accent tints (controlled, muted, flat)

Used ONLY as soft tile backgrounds (8–12 % alpha) + matching icon/number tint, to differentiate
KPI tiles and category chips on dense screens. Never large fills, never gradients, never the
brand accent's job.

| Token | Hex | Domain |
|---|---|---|
| Cat-amber | `#B45309` | Expiry / time-sensitive |
| Cat-violet | `#6D5BD0` | Low stock / inventory (muted indigo-violet — NOT neon, NOT gradient) |
| Cat-green | `#15803D` | GRN / received / fresh |
| Cat-teal | `#0F766E` | Store health / analytics |
| Cat-orange | `#EA580C` | Scans / audit (brand doubles as a category) |

Rule: if a tile tint ever reads louder than the screen's orange CTA, lower its alpha. **Tints
whisper; orange speaks.**

### 2.3 Typography

- **Display + body:** Plus Jakarta Sans. **Mono (numbers, KPIs, EANs, prices, dates, IDs,
  timers):** JetBrains Mono. No Inter, Roboto, Helvetica, Times, script.
- **Hierarchy via scale + weight,** ≥ 1.25 ratio between steps (per `impeccable`).
  Greeting/screen titles `w800`; section headers `w700`; body `w400`; captions `w400` ink-soft.
- **Eyebrow labels** (small, `w600`, +letter-spacing, ink-soft or accent-deep, often uppercase)
  introduce every major section — a core part of the editorial, content-heavy feel.
- Numbers are *always* mono and treated as a design element (KPIs count up on entry).
- Body line length stays readable; never run long paragraphs full-bleed. Indic scripts get
  +line-height; verify at `textScaleFactor 2.0` with no clip.

### 2.4 Spacing, radii, elevation

- **Spacing:** 4-pt grid (`space2 … space64`). **Vary spacing for rhythm** — same padding
  everywhere is monotony. In-card padding `space16`; tight groups `space8`; section gaps
  `space24`; zone breaks `space32`; hero breathing `space48`.
- **Radii:** `sm 8 / md 12 / lg 16 / xl 24 / full`. Cards `lg`, chips/pills `full`, tiles/wells
  `md`, banners `lg`–`xl`, bottom sheets `xl` (top corners).
- **Elevation:** one soft shadow language. Raised `#FFFFFF` cards on cream get a faint *warm*
  shadow (y2–y6, low alpha, tinted toward ink `#1C1917`, never black) + 1 px hairline. **Banners**
  may carry a slightly deeper shadow to feel merchandised. **No glassmorphism by default.**

### 2.5 Motion (Emil-grade)

- **Durations:** press 100–160 ms; tooltips/popovers 125–200 ms; dropdowns/selects 150–250 ms;
  sheets/drawers 200–360 ms. **All UI motion < 300 ms** except deliberate celebration (≤ 800 ms).
- **Easing:** enter/exit → `easeOut` (`RadhaMotion.easeOut` / `Cubic(0.23,1,0.32,1)`); on-screen
  move → ease-in-out; drawers/sheets → `RadhaMotion.spring = Cubic(0.32,0.72,0,1)`.
  **Never ease-in on UI.**
- **Press-scale `0.97`** on every tappable surface (RADHA's `_PressableCard`). Never animate
  from `scale(0)` — start `0.95` + opacity.
- **Stagger** list/section entrances 30–80 ms apart (RADHA's `_Stagger`, Interval-based
  controller — never `Future.delayed`, it's timer-leaky under tests).
- **Exit faster than enter.** Honor `MediaQuery.disableAnimations` everywhere. **Only animate
  transform/opacity, never layout.**
- **Scroll choreography** (see §5): parallax header drift, on-scroll section fade-up + 30–80 ms
  stagger, sticky section headers that compress, KPI count-up triggered on first reveal.

### 2.6 Background & texture system (from `imagegen-frontend-mobile` TEXTURE 6)

Cream is **never** dead-flat. Apply, subtly:
- **Base canvas:** `#FFFBF5` + an *almost-invisible* warm paper grain / fine noise (≤ 3 %),
  applied once at the scaffold layer, never per-card.
- **Hero bands:** a soft warm tonal wash (cream → `#FFF3E6`) behind the human-beat header, plus
  the illustrated storefront/skyline motif anchored top-right (the reference's energy, refined).
- **Section seams (optional):** a ≤ 8 % `#FED7AA` bandhani-dot or marigold-petal micro-motif as
  a quiet seam between two major zones — tasteful, integrated, never wallpaper.
- **Image-behind-text** (onboarding, digest, verified-badge): edge-to-edge visual with a
  bottom-to-top scrim so headline/CTA stay ≥ 4.5:1. Elegant fade, never raw opacity.
- **Banned backgrounds:** purple-blue gradients, AI-glow, neon, glassmorphism, busy photos
  behind body text, rainbow noise.

### 2.7 Imagery & product-cutout system

- **Product cutouts:** real licensed packshots, clean cutout on white/neutral, *consistent
  lighting*, consistent in-cell padding (product never touches the well edge), `md` well in
  `#F5F1E8`. One cutout style across the whole app (no mixed lighting).
- **Illustrations:** warm, semi-flat with soft depth, orange/cream/terracotta family, 3D-lite
  for hero objects (gift/box/calendar/shield like the reference) but **muted, not glossy
  fast-food orange.** Generated via the bridge to a single illustration language.
- **Avatars:** circular, hairline ring; default = warm monogram on accent-tint.

### 2.8 Iconography tokens

One custom glyph family (see §4): single line weight (~1.75 dp), ~2 px corner radius, rounded
terminals, optical size 24. Inactive = ink-soft line; active = orange filled-accent. SVG only —
**PNG icons banned.** Each tappable icon carries a `semanticLabel`.

---

## 3. The RADHA component catalogue

Every component has ONE canonical look. Generate a component mockup for each (on `#FFFBF5`,
raised `#FFFFFF` where applicable, 1× scale) before/while implementing, and keep it identical
across screens — this is what makes the app read as one system. Each entry's **state matrix** is
default · pressed (`0.97`) · loading (skeleton/inline spinner) · disabled (0.38) · empty · error.

| # | Component | Canonical spec (abridged — full per-use detail in screen files) |
|---|---|---|
| 3.1 | **Primary header / hero band** | Greeting `w800` + store-picker chip + avatar + warm storefront motif top-right; ~140–180 px; parallax drift on scroll; the authored human beat. |
| 3.2 | **Section header band** | Screen title `w800` (+ optional eyebrow) + one contextual action (filter/add). Slim, styled — never a bare Material AppBar. May compress + stick on scroll. |
| 3.3 | **Store-picker chip** | Pill, `storefront` glyph + store name + chevron, hairline border, surface-container fill; opens store sheet. |
| 3.4 | **KPI tile** | Square-ish `lg` raised card, hairline. Top-left category glyph in its tint; large **mono** number (tint-colored, counts up on reveal); label ink-soft; optional micro-trend / "Action needed ›". Rows of 2–4 on a strict grid. |
| 3.5★ | **Hero Story Banner (signature showpiece)** | The app's most crafted surface — today's *mission*, told cinematically. **Carries no scan-to-earn / rewards** (no such backend feature). One per region; rotating real missions; merchandised depth + warm spotlight + ≤8 % festive motif. **Full spec in the signature block below this table.** |
| 3.6 | **Quick-actions grid** | Row of icon tiles: `md` well in accent-tint (primary action = stronger tint), custom glyph in accent-deep, label below. Press-scale + haptic. "Customize" affordance optional. |
| 3.7 | **Category rail** | Horizontal scroll of category cells: clean real product cutout in a `md` well + label; "View all" at rail header. Snap scroll, momentum. |
| 3.8 | **Product card / row** | *Row:* thumb (cutout/placeholder) + name (or token) + meta (EAN mono, expiry date mono + status dot) + chevron/overflow. *Card:* thumb, name, brand, one status chip. **Never nest cards in cards.** |
| 3.9 | **Verification pill / status chip** | Pill, icon + label, tinted bg (8 %) + tint border (35 %). States: matched→success `check-circle`; not-in-list→danger `cancel`; no-list→warn `info`; invalid→neutral `help`; checking→spinner. Always `Semantics`. |
| 3.10 | **Score / OHS gauge** | Circular arc, animated sweep 0→value on reveal, mono number center, dashed neutral ring + "–" for "assessment pending". Fill = orange. |
| 3.11 | **Segmented control / filter chips** | Pill segments with a **sliding orange indicator** (animate position via transform, not color). Filter chips: selectable, tint when active. |
| 3.12 | **Bottom nav (5)** | **Home · Scan · Expiry · Tasks · Profile** (canonical 5th = Profile, *not* "More" — supersedes the reference). Active = orange glyph + label + subtle indicator. Scan = center emphasized affordance. Custom glyphs. |
| 3.13 | **Sheets / dialogs / snackbars / toasts** | Bottom sheets `xl` top radius + drag handle, `spring` enter from bottom, exit faster. Dialogs centered (`origin: center`), scrim, `0.95→1` + opacity. Toasts enter+exit same edge, interruptible. |
| 3.14 | **Empty / error / skeleton (first-class)** | *Empty:* tonal icon badge, `w700` title, one supportive line, one orange CTA, sunken backer, **personality required**. *Error:* same chrome, danger-tinted icon, retry. *Skeleton:* sunken `#F5F1E8` blocks matching final layout; shimmer respects reduced-motion. |
| 3.15 | **Forms & inputs** | Cream field, hairline border, **orange focus ring**, mono for numeric (EAN/qty/dates), inline validation (danger), helper ink-soft. Primary submit = orange, full-width on mobile. |
| 3.16 | **Badges · dots · timelines · steppers** | Status dots (success/warn/danger/neutral). GRN/task timelines: vertical connector + node + label + mono timestamp. Multi-step wizard: linear progress + numbered steps. |
| 3.17 | **Calendar heat grid** | Month grid, day cells dot-coded by expiry density (orange = this week, warn = next), selected-day drill list; swipe-month chevrons. |
| 3.18 | **Carousel / shelf** | Snap horizontal shelves (categories, alternatives, digest panels) with dots; glide momentum; peek of next card to invite scroll. |
| 3.19 | **Locked-feature overlay** | For paid surfaces (Reports, OHS): the real layout rendered + a tasteful blur/scrim + lock glyph + plan CTA. Never a blank "upgrade" wall — show the value behind glass. |

### Signature spec — the RADHA Hero Story Banner (§3.5★, the app's showpiece)

This replaces any generic "promo" and **explicitly carries no scan-to-earn / rewards** content —
that feature does not exist in the backend, so it must never appear in the UI. The banner is a
**merchandised, cinematic, story-driven mission card** — the single most crafted surface in the
app. Build it screenshot-worthy.

- **Frame:** wide `radius.xl` card with real depth — **not a flat fill.** A layered scene: a soft
  warm **spotlight/halo** (`#FFF3E6`) behind a **3D-lite hero object** (a lit shelf, an audit
  clipboard + product cluster, a calendar, a shield), gentle floating accents, and a ≤8 %
  **marigold-string / bandhani** micro-motif along one edge (festive warmth, *integrated* — never
  a slapped-on border).
- **Left column (~56 %):** mission **eyebrow** ("AAJ KA KAAM · TODAY'S MISSION", `labelMedium` on
  `#FED7AA`); **2-line headline** `w800` white that names the stakes; a thin **progress ribbon**
  (mono "12 of 18 done" + a filling orange bar); a **white CTA pill**, verb-first.
- **Right column:** the hero object on its spotlight, soft shadow, **micro-parallax** on scroll.
- **Rotation:** 1–4 real missions from `GET /dashboard/home-cards`, each mapped to a real route
  (expiry / audit / GRN / subscription / verified-badge). Dots animate width; auto-advance 6 s,
  pause on touch / reduced-motion. One mission → no dots.
- **States:** *mission* (default) · *all-clear* (a warm **win beat** — "Shabaash! Your store's in
  great shape today" + the day's stat recap, marigold accent — shown when no urgent mission) ·
  *locked* (a value mission routing to subscription) · *loading* (one warm skeleton, never an
  empty fill).
- **Motion:** fade-up + 4 dp lift on reveal; ribbon counts up; spotlight **shimmer off by
  default**, on only for the all-clear win beat + festive skin; **one orange CTA only.**
- **Why it's different:** it isn't advertising a promo — it **hands the owner today's quest and
  shows them winning it.** That narrative frame + merchandised depth is the upgrade over a flat
  banner, and it is the home of RADHA's visual storytelling (§1B).

---

## 4. The RADHA icon system (every icon made distinctly)

Icons are **not** stock Material drop-ins. RADHA gets a cohesive custom glyph family — one line
weight, one corner radius (~2 px), one optical size, rounded terminals, warm + confident.
Generate via `generate_icon_set` in **themed batches (≥ 3 related glyphs)** so each batch shares
DNA. Each glyph may carry its domain category tint on a tinted well.

**Required icon families (generate each as one set):**
1. **Bottom nav (5):** home, scan, expiry, tasks, profile — each inactive (ink-soft line) +
   active (orange filled-accent).
2. **Quick actions (6+):** scan barcode, add expiry, add task, create GRN, recall check, stock count.
3. **Categories (8–12):** biscuits & snacks, breakfast & spreads, dairy & eggs, beverages,
   personal care, household, staples/grains, frozen, baby, health — as flat warm glyphs *and*
   the real-cutout rail variant.
4. **KPI / status (6):** expiring (clock), low-stock (box), tasks-due (clipboard), GRN-pending
   (truck), matched (check-seal), store-health (shield-check).
5. **Utility (as needed):** search, filter, sort, chevrons, overflow, share, edit, delete, back,
   close, calendar, camera/torch, info, alert, copy, WhatsApp.

Each icon brief states: single line weight, ~2 px corner radius, rounded terminals, RADHA
warmth, exact tint hex if tinted, and the negative line. **Reject** any icon that's a generic
Material clone, emoji-like, or off-weight from the family.

---

## 5. Screen Anatomy & Scroll Grammar (the universal skeleton)

Every RADHA screen is composed of stacked **zones** in scroll order. A screen file specifies its
zones top-to-bottom; this is the grammar they all share.

### 5.1 Vertical zones (top → bottom)
1. **System zone** — status bar (drawn in mockups), safe-area top inset. Never place content here.
2. **Hero / human-beat band** (Z-HERO) — §3.1/§3.2. Primary screens: tall authored header with
   storefront motif + parallax. Secondary: slim styled title band. **The first fold must feel
   authored and uncluttered** (`imagegen` First-Screen rule): one focal point, headline ≤ 3 lines.
3. **Substance zones** (Z1…Zn) — the merchandised body: KPI bento, promo banner, rails, lists,
   forms, timelines. Each zone = an eyebrow label + content + (optional) "view all". Zones are
   separated by `space24`–`space32` breaths. One focal point per zone.
4. **Floating action** (Z-FAB) — optional FAB or pinned action bar in orange (e.g. expiry/tasks
   "New", scan-result "Add to expiry"). One primary float per screen.
5. **Bottom nav** (Z-NAV) — §3.12, 72 dp + safe-area; only on the 5 root tabs. Drill-down screens
   hide it and show a back affordance.

### 5.2 The fold budget (first viewport, ~393×852 minus system + nav)
- Primary screens: hero band + **one** focal substance zone visible; everything else invites scroll.
- Don't cram stats/chips/pills above the fold. If the first fold has > 1 focal point, cut.

### 5.3 Scroll behaviors (specify per screen)
- **Parallax header:** hero illustration drifts ~0.5× scroll speed; greeting fades to a compact
  sticky title at ~120 px scrolled.
- **Sticky section header:** a zone's eyebrow/header may pin + compress (filters, calendars).
- **Scroll-reveal:** each zone fades-up (opacity + 12 px translate, `easeOut`, stagger 30–80 ms)
  on first entry into viewport. Once only; respects reduced-motion (instant).
- **KPI count-up:** mono numbers animate 0→value when their tile first reveals.
- **Snap rails:** horizontal shelves snap; vertical lists never snap.
- **Pull-to-refresh:** custom orange RADHA refresh indicator (not stock), on all data lists.
- **Pinned action bar:** scan-result / wizards keep the primary CTA pinned above the home indicator.

### 5.4 Sub-pages, sheets & states (every screen enumerates these)
A "screen" includes its **sub-surfaces**, each specified in the screen file:
- **Sheets** (bottom): pickers (store, supplier, assignee, date), confirms, share, upgrade.
- **Dialogs:** destructive confirms, errors.
- **Inline states:** loading (skeleton), empty, error, locked (paid), offline banner.
- **Variants:** consumer vs business mode, role-gated affordances, festive skin (optional).
- **Entry/exit transitions:** route transition (Hero where a thumb→detail relationship exists).

### 5.5 Per-screen "story arc" notation
Each screen file opens with: **Human beat → Substance (zones) → Action.** If a screen can't name
its human beat, its substance focal points, and its one action, it isn't designed yet.

---

## 6. The image-generation prompt system (operationalizes §8)

Every `kiro-gpt-bridge` call uses **`enhance_prompt: true`** and this structure. Lock the
**Design-Bible Block** once per app and prepend it (lightly) so screen 3 never drifts from
screen 1 (`imagegen` App-Design-Bible rule).

### 6.1 Locked Design-Bible Block (prepend to every brief)
> `RADHA — premium Indian retail-ops mobile app, cross-platform premium (iOS-leaning), shown in
> a clean subtle iPhone 15 mockup (393×852, status bar + home indicator drawn), content is the
> hero not the device, even margins. Palette: canvas warm cream #FFFBF5 (faint paper grain),
> raised #FFFFFF cards + #E7E1D4 hairline, ONE brand burnt-orange #EA580C accent per region,
> accent-deep #9A3412, accent-tint #FED7AA, ink #1C1917 (never pure black), ink-soft #57534E,
> category tints #B45309/#6D5BD0/#15803D/#0F766E at ~10% on tiles only. Type: Plus Jakarta Sans
> (display+body) + JetBrains Mono (all numbers/EAN/dates). Custom warm rounded glyph icons (~2px
> radius, single weight). Real product cutouts on clean white. Soft warm shadows, lg radii,
> strict 4pt grid, content-heavy but sectioned and breathing, editorial eyebrow labels, motion-
> implied. Warm Indian-retail confidence, tasteful — no kitsch.`

### 6.2 Shared negative footer (append to every brief)
> `Negative: no garbled/lorem text, no watermark or generator badge, no purple/blue gradients,
> no AI-glow/neon/glassmorphism, no fast-food/Halloween orange, no pure #000000, no emoji-as-
> icon, no generic Material/Lucide icons, no nested cards, no identical repeated card grids, no
> gradient text, no side-stripe accent borders, no hero-metric SaaS template, no fake charts, no
> two competing orange CTAs, no device frame dominating the screen, no tiny unreadable text, no
> cultural stereotype graphics.`

### 6.3 Brief skeleton (per artifact, 200–600 chars between the two blocks)
`[Design-Bible Block]` → `SCREEN: <name> (<route>). PLATFORM: cross-platform premium. STORY:
<human beat → substance → action>. SCROLL ZONES (top→bottom): Z-HERO <…>; Z1 <…>; Z2 <…>; …
FOCAL POINT: <the one>. STATE: <default|empty|loading|locked|error>. REAL PRODUCT CUTOUTS:
<yes/no>. COPY (verbatim, short, real): <exact strings>. MOTION-IMPLIED: <e.g. fade-up stagger,
parallax header>.` → `[Negative footer]`

### 6.4 Tool selection
| Artifact | Tool |
|---|---|
| Full-page mockup / component / banner / sheet | `generate_ui_mockup` |
| Brand logo / mark / lockup | `generate_logo` |
| Promo hero / category banner / illustration | `generate_hero` |
| Icon family (≥ 3 glyphs, one batch) | `generate_icon_set` |
| Product cutout / decorative motif | `generate_image` |

### 6.5 Frame, save, anti-drift rules
- **Frame:** iPhone 15 portrait 393×852, status bar + home indicator drawn, even margins,
  content-first (`imagegen` mockup-frame discipline 9).
- **One screen per image.** Never compress a flow into a collage. Need a detail? Generate a fresh
  standalone detail render — **never crop** an old board (`imagegen` rules 5, 4).
- **Generate enough screens** for a believable flow; don't be lazy with count.
- **Save:** `assets/{category}/{kebab-name}.{ext}` — categories `logo|hero|icon|illustration|
  background|mockup|other`; product cutouts under `assets/illustration/products/`; per-screen
  mockups under `assets/mockup/{page-slug}.png` (queue = `PAGES.md`).
- **Cohesion sheet:** before any new screen, generate/reuse `assets/other/radha-design-tokens-v2.png`
  (token + component reference board) and pass it as visual context.
- **Anti-drift:** if code must deviate from a mockup, regenerate the mockup to the new spec.

---

## 7. The per-screen spec template (every `VISUAL_SCREENS/*.md` follows this)

```
# <NN> · <Screen name> — <route>
Mode: consumer | business | both     Tab/Stack: <root tab | drill-down>     Gate: <none|paid|role>

## Story arc
Human beat → Substance (Z1…Zn) → Action.   (one sentence)

## Backend wiring (do not break)
Providers / endpoints / DTOs consumed (cite BE-NN + API_CONTRACTS.md). Honest-data notes.

## Scroll zones (top → bottom)
### Z-HERO — <name>
- Layout, exact components (§3 refs), tokens (cite hex/space/radius), copy (verbatim, real),
  imagery/illustration brief, motion (entry + scroll), a11y (Semantics, focus order), states.
### Z1 … Zn  (same structure each)
### Z-FAB / pinned action     ### Z-NAV (if root tab)

## Sub-surfaces
Sheets / dialogs / pickers / variants — each with its own mini-spec + asset brief.

## State gallery
default · loading(skeleton) · empty · error · offline · locked(if paid) · festive(optional).

## Asset checklist (image-first)
| asset | tool | save path | brief (200–600c, uses §6 blocks) | status |

## Motion checklist (Emil)  ·  ## Accessibility checklist  ·  ## Anti-slop gate
## Done gate: mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/skeleton ✓
· slop gate ✓ · wiring intact ✓ · widget tests green ✓
```

---

## 8. Asset generation workflow (image-first, mandatory)

1. **Brief** per §6 (Design-Bible Block + 200–600 c body + Negative footer).
2. **Generate** with the matching tool + `enhance_prompt: true`. Generate enough; never lazy.
3. **Save** per §6.5 naming.
4. **Check** against §10 rejection list. Re-brief + regenerate failures — **never commit slop.**
5. **Code** Flutter to match at first render; preserve all wiring (§ guardrails).
6. **Cohesion:** pass the token reference board as context for every new screen.

Deeper asset conventions (formats, sizes, optimization, licensing) live in `ASSET_PIPELINE.md`
and `BRAND_ASSETS_LICENSE.md` — keep both reconciled to this bible.

**Token-light generation route (chosen for this client).** Instead of the `kiro-gpt-bridge` MCP
server (which spends Claude Code tokens per image + retry), generate in **your own ChatGPT** using
the ready prompts in **`VISUAL_PROMPTS/`**: paste `VISUAL_PROMPTS/00_PRIMER.md` once to lock the
style, then fire each per-asset prompt in the same chat. Same briefs, same save paths, **zero
Claude tokens**. The MCP server stays registered but idle. Each deep-specced screen gets a matching
`VISUAL_PROMPTS/<nn>_<slug>.md` alongside its `VISUAL_SCREENS/<nn>_<slug>.md`.

---

## 9. Skill invocation playbook (use aggressively, every screen)

| Phase | Skill | What to run |
|---|---|---|
| Plan a screen | `impeccable` (`shape`) + `ui-ux-pro-max` | UX/IA plan, register=product, color strategy, theme scene-sentence, slop pre-check |
| Set the dials | `design-taste-frontend` | variance 7 / motion 6 / density 7; component architecture + spacing/type math |
| Art-direct assets | `imagegen-frontend-mobile` + `high-end-visual-design` | per-artifact briefs (§6), premium direction, kill cheap defaults |
| Generate assets | kiro-gpt-bridge | per §6/§8, briefs from the screen file |
| Upgrade existing screen | `redesign-existing-projects` | audit current Flutter, restyle to bible without breaking wiring |
| Build Flutter | `impeccable` (`craft`) + tokens | implement to match mockup, real wiring intact |
| Motion pass | `emil-design-eng` | easing/duration/press-scale/stagger/reduced-motion (Flutter table) |
| Review | `impeccable` (`critique`/`audit`/`polish`) | heuristic score, a11y, perf, slop gate; Before/After table |
| Amplify/quiet | `impeccable` (`bolder`/`quieter`/`delight`) | push bland, calm loud, add the second-read moment |
| Author the spec | `stitch-design-taste` + `full-output-enforcement` | write the screen file complete, anti-generic, unabridged |

**Done only when:** mockup beaten ✓ · tokens-only (no hard-coded values) ✓ · motion polished +
reduced-motion safe ✓ · empty/error/skeleton present ✓ · slop gate passed ✓ · all backend wiring
intact ✓ · widget tests green ✓.

---

## 10. Rejection list (regenerate / rework — never commit)

Reject any output containing: neon/fast-food/Halloween orange (must read `#EA580C`); purple-blue
gradients or AI-glow (flat muted `#6D5BD0` tile is fine, gradients are not); pure `#000000`;
visible watermark/generator badge; lorem-ipsum/garbled glyphs; emoji-as-icon; dirty/dark/busy
product photos (must be clean cutouts); generic Material/Lucide-clone icons off the family weight;
nested cards; identical repeated card grids; gradient text; side-stripe accent borders; the
hero-metric SaaS template; fake charts/stat spam; more than one competing orange CTA per region;
device frame dominating; tiny unreadable text; cultural-stereotype graphics; **any screen that
passes the "an AI made that" test.**

---

## 11. Screen index → `VISUAL_SCREENS/` (every route, each independently buildable)

Build queue + mockup tracking remain in `PAGES.md` / `COMPONENTS.md`. Each screen below gets a
full scroll-by-scroll file `VISUAL_SCREENS/<nn>_<slug>.md` (template §7). Status: 🟢 deep-spec done ·
🟡 skeleton (arc + zones noted, awaiting deep-spec) · ⬜ queued.

**Auth & entry** — `01_splash` ⬜ · `02_onboarding_segments` ⬜ · `03_onboarding_value` ⬜ ·
`04_onboarding_consent` ⬜ · `05_otp_request` ⬜ · `06_otp_verify` ⬜ · `07_select_store` ⬜

**Core shell** — `08_home` 🟢 *(the anchor / quality reference — deep-spec done)* · `09_scan` ⬜ ·
`10_scan_result` ⬜ · `11_bulk_ean_audit` ⬜ · `12_scan_sessions` ⬜

**Expiry** — `13_expiry_list` ⬜ · `14_expiry_create` ⬜ · `15_expiry_calendar` ⬜

**Tasks** — `16_tasks_list` ⬜ · `17_task_create` ⬜ · `18_task_detail` ⬜

**Inventory & GRN** — `19_inventory_list` ⬜ · `20_stock_movement` ⬜ · `21_low_stock_alerts` ⬜ ·
`22_grn_list` ⬜ · `23_grn_create` ⬜ · `24_grn_items` ⬜ · `25_suppliers` ⬜

**Catalog / AI / consumer** — `26_product_detail` ⬜ · `27_ingredient_explainer` ⬜ ·
`28_healthy_alternatives` ⬜ · `29_saved_products` ⬜ · `30_allergen_profile` ⬜ · `31_recall_alerts` ⬜ ·
`32_shopping_list` ⬜ · `33_public_product` ⬜

**Account / growth / business** — `34_profile` ⬜ · `35_settings` ⬜ · `36_language` ⬜ ·
`37_support` ⬜ · `38_subscription` ⬜ · `39_checkout` ⬜ · `40_referrals` ⬜ · `41_weekly_digest` ⬜ ·
`42_notifications` ⬜ · `43_family_sharing` ⬜ · `44_business_activation` ⬜ · `45_verified_badge` ⬜ ·
`46_community_contribute` ⬜

**Paid dashboards** — `47_reports_hub` ⬜ · `48_ohs_dashboard` ⬜

> **Build order:** `08_home` first (sets the bar), then Core shell → Expiry → Tasks → Inventory/GRN
> → AI/consumer → Account/growth → Paid dashboards. Each deep-spec is authored complete (§7) and
> its mockups generated (§6/§8) before the next.

---

## 12. Implementation guardrails (function stays intact)

- **Visual layer only.** Preserve Riverpod providers, API client, DTOs, validation,
  permission/entitlement gates, routing, and the existing motion primitives (`RadhaMotion`,
  `_PressableCard`, `_Stagger`).
- **Tokens only** — no hard-coded color/spacing/radius/duration in feature code (CI/token-lint
  enforces). Cite tokens in every screen file.
- **Validate every rebuild** against the **widget test suite** (not just analyzer): `flutter
  analyze --no-pub lib` clean + `flutter test` green is the floor. Visual rebuilds have regressed
  tests before.
- **Real product imagery** per `BRAND_ASSETS_LICENSE.md`; keep that file accurate.
- **Bottom nav 5th tab is Profile** (align mockups + code). **Veg/non-veg is a product filter**,
  not a home-search mode. **No scan-to-earn / rewards** feature.
- **Don't run watchers/dev-servers from agent tools** (Windows/PowerShell host) — ask the user.

---

## Changelog
- **2026-06-03 — v2.1** Added §1B visual-storytelling system (narrative spine + Gujarati story
  chapters); replaced the generic promo with the **Hero Story Banner** signature surface (§3.5★);
  **removed all scan-to-earn / rewards** content app-wide. Updated Home Z2 + asset briefs A0/A4.
- **2026-06-03 — v2.0** Upgraded to master Visual System Bible: added §1A Gujarati cultural
  layer, §2.6 background/texture, §2.7 imagery, §2.8 icon tokens, §5 Screen Anatomy & Scroll
  Grammar, §6 image-gen prompt system (Design-Bible + negative blocks + per-tool templates), §7
  per-screen spec template, §11 `VISUAL_SCREENS/` index (48 screens). Reconciled brand to warm
  orange `#EA580C` (noted emerald `FRONTEND_DESIGN_SYSTEM.md` as superseded). Folded in new
  skills (imagegen-frontend-mobile, high-end-visual-design, ui-ux-pro-max, redesign-existing-
  projects, stitch-design-taste, full-output-enforcement).
- **prior — v1** Original visual system & asset brief library.
