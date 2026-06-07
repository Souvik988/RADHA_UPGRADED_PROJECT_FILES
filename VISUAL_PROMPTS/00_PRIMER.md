# RADHA — ChatGPT Image Prompt Pack (token-free generation)

**Why this exists.** Generate every RADHA visual in **your own ChatGPT** (Pro) instead of through
the `kiro-gpt-bridge` MCP server — so image generation costs **zero Claude Code tokens**. Claude
writes the prompts (cheap); ChatGPT renders the images (your subscription). Keep the MCP server
registered but idle; you don't need it for this route.

These prompts are the ChatGPT-ready form of the asset briefs in the master bible
`.kiro/steering/visual-assets.md`. Same system, same save paths.

---

## ✅ The best way to run this (recommended workflow)

1. Open a **fresh ChatGPT conversation** (GPT-4o / GPT Image).
2. **Paste the "RADHA IMAGE SYSTEM — LOCKED" block (below) once.** It sets the style contract for
   the entire conversation, so every image stays on-brand and consistent. ChatGPT remembers it.
3. Fire the per-asset prompts **in order, in the same conversation**:
   - **First** → `01_brand_icons_backgrounds.md` (logo → app icon → token board → icon sets →
     backgrounds → illustration DNA). These define RADHA's visual identity — make them first.
   - **Then** each screen pack (`08_home.md`, then the rest as they're deep-specced).
4. **Save** each result to the path noted with the prompt. PNGs go straight to `assets/...`; icon
   sheets get traced/exported to SVG at `assets/icon/...`.
5. **One asset per generation.** If it drifts, reply `regenerate — fix: <issue>`; the locked block
   still applies. Keep the chat going so consistency carries across images.

## Practical ChatGPT notes
- **Sizes:** phone mockups → portrait **1024×1536**. Icon / logo sheets → **1024×1024**.
  Banners / heroes / boards → **1536×1024**. Product cutouts → **1024×1024** on pure white.
- **Text in full-screen mockups is approximate** — image models can't render long UI copy
  pixel-perfect. Treat full-screen mockups as **art-directed references** (layout, color,
  hierarchy, mood). Icons, logos, illustrations, cutouts and banners come out clean and usable.
- **Transparency:** for logos/icons say *"isolated on plain #FFFBF5, centered, even margins"* then
  background-remove if you need transparent — or ask directly for *"transparent background"*.
- **Icon sets:** request **one labelled sheet of N glyphs in a grid**, identical weight — easier
  than N calls and guarantees one family. Then slice to individual SVGs.
- **Consistency rescue:** if a later image drifts, paste *"match the RADHA locked system and the
  earlier logo/icons we made in this chat."*

---

## 📌 RADHA IMAGE SYSTEM — LOCKED  *(paste this once at the top of the ChatGPT conversation)*

> You are RADHA's lead mobile-product image art director. RADHA is a **premium Indian retail-
> operations app** (barcode scanning, expiry tracking, EAN audits, GRN, lightweight inventory,
> tasks, reports) for Gujarat shopkeepers. For **every** image I ask for in this conversation,
> obey this system exactly and keep all images **one coherent product world**:
>
> **PLATFORM & FRAME** — cross-platform premium, iOS-leaning. Full screens are shown inside a
> clean, subtle **iPhone 15 mockup** (rounded corners, thin bezel, status bar + home indicator
> drawn), centered with even margins. The device supports the UI; the **content is the hero** —
> never let the frame dominate.
>
> **PALETTE (use these exact hex)** — canvas warm cream `#FFFBF5` with a faint paper-grain texture
> (never flat/pure white); raised cards `#FFFFFF` with a 1px hairline `#E7E1D4`; **ONE brand accent
> burnt-orange `#EA580C`** used once per region (primary CTA / active nav / focus ring / gauge
> fill); accent-deep `#9A3412`; accent-tint `#FED7AA`; text ink `#1C1917` (**never pure `#000000`**);
> secondary text ink-soft `#57534E`. Muted **category tints used ONLY as ~10% soft tile
> backgrounds**: amber `#B45309` (expiry), indigo-violet `#6D5BD0` (low stock — flat, not neon),
> green `#15803D` (GRN/fresh), teal `#0F766E` (store health). States: success `#15803D`, warn
> `#B45309`, danger `#B91C1C`. Festive **marigold `#F59E0B` + turmeric `#FACC15` ONLY on
> celebratory/win moments**.
>
> **TYPE** — Plus Jakarta Sans for display + body (titles w800, section headers w700, body w400);
> **JetBrains Mono for ALL numbers**, EAN codes, prices, dates, timers. Editorial uppercase
> **eyebrow labels** introduce sections.
>
> **ICONS** — one **custom warm rounded glyph family**: single ~1.75px stroke, ~2px corner radius,
> rounded terminals, consistent optical size; inactive = ink-soft line, active = orange filled-
> accent. **Never** generic Material/Lucide icons, never emoji.
>
> **SURFACES & DEPTH** — soft **WARM** shadows (tinted toward ink, never black); large radii (cards
> 16px, pills full, tiles 12px, banners 24px); strict 4-pt spacing grid; **content-heavy but
> clearly sectioned with generous breathing space between zones**. Subtle warm grain; an optional
> **≤8% bandhani-dot or marigold-petal motif** only at section seams or celebratory overlays —
> tasteful, integrated, never wallpaper, never cliché.
>
> **IMAGERY** — real product packshots as **clean cutouts on white**, consistent lighting + padding;
> warm semi-flat **3D-lite illustrations** (muted, not glossy) in the orange/cream/terracotta family.
>
> **MOOD** — warm, proud, organised Indian neighbourhood-store confidence; premium and merchandised
> like Blinkit/Zepto crossed with editorial warmth. Readable, calm, intentional, screenshot-worthy.
>
> **HARD NEGATIVES (never include)** — purple/blue gradients, AI-glow, neon, glassmorphism; fast-
> food/Halloween orange (must read as burnt `#EA580C`); pure `#000000`; watermarks or generator
> badges; lorem/garbled text; emoji-as-icon; generic Material/Lucide icons; nested cards-in-cards;
> identical repeated card grids; gradient text; side-stripe accent borders; fake charts/stat spam;
> two competing orange CTAs in one region; the device frame dominating; tiny unreadable text;
> cultural-stereotype graphics (no garba dancers, flags, or rangoli wallpaper). **NO scan-to-earn /
> rewards content anywhere — RADHA has no rewards feature.**
>
> Acknowledge, then hold this system for every image request in this chat until I say otherwise.

---

## Index of prompt files
- **`01_brand_icons_backgrounds.md`** — logo, app icon, token reference board, all 5 icon
  families, utility icons, backgrounds/textures, illustration DNA + core spots. *(Generate first.)*
- **`08_home.md`** — Home screen mockups (default + states) + the Hero Story Banner scene.
- *(more screen packs `<nn>_<slug>.md` added as each screen is deep-specced — mirrors `VISUAL_SCREENS/`)*

> Generation order: **brand & icons & board → backgrounds & illustrations → Home → other screens.**
