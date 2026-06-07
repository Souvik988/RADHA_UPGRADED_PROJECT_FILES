# RADHA — Master UI Upgrade Prompt (corpus)

> **How to use:** open this file, **copy everything below the line**, and paste it as the first
> message to your coding agent in the other IDE (Cursor / Kiro / Windsurf / Claude / etc.). The repo
> must be open in that IDE. This single prompt makes the entire RADHA visual + character upgrade
> clear, A→Z, with nothing missed.

---

You are the **executive frontend architect + UI/UX designer + Flutter motion engineer** for **RADHA**,
a premium mobile-first retail-operations app (barcode scanning, expiry, EAN audits, GRN, lightweight
inventory, tasks, reports, subscriptions) for Indian — especially **Gujarat** — shopkeepers. Your job:
**upgrade the ENTIRE Flutter app (`apps/mobile`) to a premium, character-driven, culturally-warm,
animation-rich UI — visual layer only, every screen, every state, every asset, nothing left generic.**
Quality bar: better than top Indian retail apps (Blinkit/Zepto) crossed with editorial warmth — and
unmistakably RADHA. Work like someone fluent in Flutter, Riverpod, `flutter_animate`, Rive, Lottie,
custom painters, and editorial illustration.

## 0. SOURCE OF TRUTH — read these first, in this order
1. `.kiro/steering/visual-assets.md` — **THE master visual bible** (tokens, components, Scroll Grammar,
   image-gen system, the 48-screen index, per-screen spec template §7). **Highest authority.**
2. `CHARACTER_STORYTELLING_BIBLE.md` — the character + storytelling + motion system (Mor + human cast).
3. `VISUAL_SCREENS/08_home.md` — the **depth exemplar**. Build EVERY screen to this depth + the §7
   template. (Author the missing 47 screen files to this standard before/with implementing them.)
4. `VISUAL_PROMPTS/` — token-free **ChatGPT asset prompts** (`00_PRIMER.md`, `01_brand_icons_backgrounds.md`,
   `08_home.md`, `MOR_ASSET_KIT.md`). Use these to brief image generation; do not invent a different style.
5. `PAGES.md`, `COMPONENTS.md` — the screen + component queue.
6. `API_CONTRACTS.md`, `CONNECTION_MAP.md` — the backend wiring you must preserve exactly.

## 1. PALETTE CONFLICT — RESOLVED (critical, obey strictly)
Use **ONLY** the warm light system from `visual-assets.md`. **IGNORE and treat as SUPERSEDED:**
- `.kiro/specs/radha-platform-design/design.md` (dark-first `#0E0F12`, saffron `#F08C2C`, **Inter**).
- `FRONTEND_DESIGN_SYSTEM.md` (emerald `#10B981`).
Do **NOT** use Inter, dark-mode-first, near-black canvas, emerald, or `#F08C2C` anywhere.

## 2. LOCKED DESIGN TOKENS (inline, so there is zero ambiguity)
- **Color:** canvas cream `#FFFBF5` (faint warm grain, never flat white) · raised `#FFFFFF` · sunken
  `#F5F1E8` · hairline `#E7E1D4` · brand accent burnt-orange `#EA580C` (ONE per region) · accent-deep
  `#9A3412` · accent-tint `#FED7AA` · ink `#1C1917` (never pure black) · ink-soft `#57534E` · success
  `#15803D` · warn `#B45309` · danger `#B91C1C` · complement teal `#0F766E` (very sparing) · festive
  marigold `#F59E0B`/turmeric `#FACC15` (celebration only). Category tile tints (~10% only): amber
  `#B45309`, indigo-violet `#6D5BD0` (flat, not neon), green `#15803D`, teal `#0F766E`, orange `#EA580C`.
- **Type:** Plus Jakarta Sans (display+body; titles w800, headers w700, body w400) + **JetBrains Mono
  for ALL numbers/EAN/dates/timers**. Uppercase editorial eyebrow labels introduce sections.
- **Spacing:** 4-pt grid (8/12/16/24/32/48/64): in-card 16, tight 8, section gap 24, zone break 32.
- **Radii:** sm 8 / md 12 / lg 16 / xl 24 / full. Cards lg, pills full, tiles md, banners lg–xl, sheets xl.
- **Elevation:** soft WARM shadows (tinted toward ink, never black) + 1px hairline. No glassmorphism.
- **Motion:** instant 0 · fast 120 (easeOutCubic) · normal 200 (easeInOutCubic) · slow 320 (easeOutQuint)
  · expressive 480 (Cubic 0.16,1,0.3,1) · celebrate 800 (spring). Press-scale 0.97; stagger 30–80ms;
  enter/exit easeOut, never ease-in; only animate transform/opacity; honor `MediaQuery.disableAnimations`.
- **Read tokens from `apps/mobile/lib/design/tokens.dart`; never hard-code values in feature code.**

## 3. NON-NEGOTIABLES
- **Visual layer only.** Preserve every Riverpod provider, API call, DTO, validation, permission/
  entitlement gate, route, and existing motion primitive (`RadhaMotion`, `_PressableCard`, `_Stagger`).
- **No new features.** Especially **NO scan-to-earn / rewards** (no such backend feature). Veg/non-veg
  is a product filter, not a search mode. Bottom-nav 5th tab is **Profile** (not "More").
- **Honest data.** Render only what the backend returns; tokens/placeholders where it returns IDs.
- **Every screen ships designed `empty / loading(skeleton) / error / offline / locked(if paid)` states.**
- **One primary orange CTA per region.** Content-heavy but sectioned and breathing.
- **Character system (per `CHARACTER_STORYTELLING_BIBLE.md`):** integrate **Mor** (the saffron-peacock
  companion) + the human shopkeeper cast for emotional storytelling. Cultural respect is mandatory —
  evoke peacock/marigold/saffron/devotion symbolism, **never depict any deity**, never stereotype.
- **Motion:** Mor via Flutter code (compositing parts) + Lottie JSON for set-pieces; reduced-motion
  static fallbacks for every animation; state never conveyed by motion or color alone.
- **Accessibility:** Semantics on every meaningful widget, logical focus order, ≥48dp targets, WCAG-AA,
  no clip at `textScaleFactor 2.0`. **Performance:** 60fps on Pixel 4a; `.riv` <150KB, Lottie <60KB.
- **Tests stay green:** `flutter analyze --no-pub lib` clean + `flutter test` green is the floor.

## 4. SCOPE — every screen (48), nothing skipped
Auth/entry: splash · onboarding_segments · onboarding_value · onboarding_consent · otp_request ·
otp_verify · select_store. Core shell: **home (the reference)** · scan · scan_result · bulk_ean_audit ·
scan_sessions. Expiry: expiry_list · expiry_create · expiry_calendar. Tasks: tasks_list · task_create ·
task_detail. Inventory/GRN: inventory_list · stock_movement · low_stock_alerts · grn_list · grn_create ·
grn_items · suppliers. Catalog/AI/consumer: product_detail · ingredient_explainer · healthy_alternatives ·
saved_products · allergen_profile · recall_alerts · shopping_list · public_product. Account/growth/
business: profile · settings · language · support · subscription · checkout · referrals · weekly_digest ·
notifications · family_sharing · business_activation · verified_badge · community_contribute. Paid:
reports_hub · ohs_dashboard. **Plus** every shared component (`COMPONENTS.md`) and every asset category
(logo, hero, icon, illustration, background, mockup, character). **No screen, state, or asset is optional.**

## 5. PER-SCREEN WORKFLOW (repeat for ALL 48)
1. Read the bible + this screen's `VISUAL_SCREENS/<nn>_<slug>.md` — **if it doesn't exist, author it
   first** to the §7 template at Home's depth (scroll zones, components, tokens, copy, motion, states,
   asset briefs, a11y, done-gate).
2. Define the **story arc** (human beat → substance → action) and the **character beat** (which Mor/human
   emotion, per character bible §6).
3. **Assets image-first:** brief via `VISUAL_PROMPTS/` (ChatGPT, token-free) or generate in-IDE if image
   tools exist; save to `assets/{category}/...`; verify against the bible's rejection list.
4. **Implement Flutter** to match the mockup at first render — tokens only, preserve all wiring.
5. Build **all states** (default/loading/empty/error/offline/locked) + **motion** (RadhaMotion + Mor) +
   **reduced-motion fallbacks**.
6. **A11y** (Semantics/focus/contrast/text-scale) + **widget tests** green.
7. **Done-gate:** mockup beaten · tokens-only · motion+reduced-motion · all states present · anti-slop
   passed (no screen could be called "AI-generic") · wiring intact · tests green.

## 6. ASSET & CHARACTER WORKFLOW
- Follow `VISUAL_PROMPTS/00_PRIMER.md` (locked style) for every generated image. Generate brand/icons/
  board first, then per-screen mockups, then character art via `MOR_ASSET_KIT.md`.
- Mor motion: composite the part PNGs in Flutter (breathing, blink, crest sway, tail-fan, wing-shelter);
  author Lottie JSON for loader / marigold-petal burst / sync-spark; wire a `mascotControllerProvider`
  with reduced-motion + a11y per `CHARACTER_STORYTELLING_BIBLE.md` §7.

## 7. BUILD ORDER
Tokens/foundation already exist → **Home** (match `VISUAL_SCREENS/08_home.md` exactly) → Scan suite →
Expiry → Tasks → Inventory/GRN → AI/consumer → Account/growth → Paid dashboards → then the Mor motion
layer + the "wow five" signature moments (splash, offline-shelter, scan-success, win-beat, onboarding).

## 8. OUTPUT RULES
Produce **complete, unabridged** code and specs — **no placeholders, no `// rest unchanged`, no TODOs,
no truncation.** Fully implement each screen before moving on. If a response is long, continue in parts
until **everything** is done. Never skip a screen, state, or asset.

## 9. DEFINITION OF DONE (whole app)
Every one of the 48 screens matches the bible + its screen spec, ships all states + motion + a11y,
integrates the character system where specified, preserves all backend wiring, passes `flutter analyze`
+ `flutter test`, and passes the anti-slop gate. The result feels **premium, warm, alive, culturally
rooted, and unmistakably RADHA** — light-mode-first cream + burnt-orange, Plus Jakarta Sans, Mor present.
If any screen still looks like a generic template, it is not done — rework the structure, not the paint.

Begin by confirming the source-of-truth files and the resolved palette, then start with **Home**.
