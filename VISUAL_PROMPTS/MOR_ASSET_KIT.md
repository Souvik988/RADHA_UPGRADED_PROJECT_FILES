# Mor — Asset Generation Kit (ChatGPT → hand back to Claude)

> **Purpose:** generate every still asset for **Mor** (RADHA's saffron-peacock companion) in your own
> ChatGPT, precisely, with zero ambiguity — then hand the files to me and I build the motion (Flutter
> code + Lottie JSON I author). This kit is deliberately exhaustive so **nothing is left to chance.**
>
> **You generate only STILL images here.** The animations (loader, petal burst, sync-spark, Mor
> breathing/blink/tail-fan) are **mine to build** — do **not** try to generate animation/Lottie in
> ChatGPT. Concept + meaning + motion spec live in `../CHARACTER_STORYTELLING_BIBLE.md`.

---

## 0. How to use this kit (read fully once)

**Workflow (do it in this exact order, all in ONE ChatGPT conversation):**
1. Open a **fresh ChatGPT chat** (GPT-4o / GPT Image).
2. Paste **`00_PRIMER.md` → "RADHA IMAGE SYSTEM — LOCKED"** block (sets the world).
3. Paste **§1 below ("MOR — CHARACTER LOCK")** (sets the character).
4. Generate **A1 (master turnaround) FIRST.** This image becomes your **visual anchor.**
5. For **every** asset after A1, start the prompt with: *"Using the exact Mor from the turnaround
   image above — same shapes, same colors, same proportions —"* then the prompt. This is how you
   stop drift. (ChatGPT remembers the image in-conversation.)
6. Generate **A2 → A3 → A4 → A5 → A6–A8** in order. One asset per generation.
7. Save each to the path noted. Name files **exactly** as given (I load them by these names).
8. Verify each against its **Reject if…** line (§ per asset) before saving. Regenerate failures.
9. When done, send me the **Hand-back checklist (§10)** — the parts are the must-have.

**ChatGPT settings & facts:**
- **Sizes:** character sheets/parts → **1024×1024** (or 1536×1024 if it won't fit); scenes →
  **1024×1536** portrait.
- **Transparency:** GPT Image supports it — say **"transparent background, PNG with alpha, no
  backdrop, no ground shadow, no canvas color."** If it still adds a background → use the **magenta
  fallback** (§9).
- **Text:** Mor has no text; ignore any stray text it adds (regenerate if it appears).
- **One at a time.** If it drifts, reply `regenerate — fix: <issue>, keep Mor identical to the
  turnaround`.

---

## 1. MOR — CHARACTER LOCK  *(paste once, right after the RADHA primer block)*

> **MOR** is RADHA's original mascot: a warm, modern, **chibi-confident PEACOCK** (not babyish, not
> vain) — calm, kind, watchful, devoted. Build him EXACTLY like this every time:
>
> **Construction:** a rounded, plump egg-shaped body; a small rounded head with a short gentle curved
> beak; two short legs with simple rounded feet; two small rounded wings; **one upright crest feather**
> with a soft heart/teardrop tip; a tail of **exactly 5 feathers**, each ending in a small peacock
> "eye" ornament. Two large warm round eyes, each with a single white catchlight. Soft, friendly,
> alert-but-calm face. Body-to-head ratio about 1 : 0.9.
>
> **Exact palette (use these hex, no others):** body cream **#FFFBF5**; belly **#FED7AA**; wing tips
> and plumage edges burnt-orange **#EA580C**; **the ONLY teal is #0F766E** — used solely in the crest
> tip and the 5 tail "eyes", each tail-eye ringed with marigold **#F59E0B**; outline + facial features
> ink **#1C1917** (never pure black); eye catchlight pure white. Teal must be **≤10%** of the whole
> character — Mor reads **saffron-orange first, peacock second.**
>
> **Style:** premium **semi-flat with soft cel-shaded depth**; clean, even, rounded linework; ~2px
> rounded corner language; warm key light from upper-left. **Not** glossy, **not** 3D-rendered, **not**
> neon, **not** photoreal feathers, **not** purple/blue, **not** a deity/crown/flute. One coherent,
> ownable, premium character.
>
> Acknowledge, then keep Mor pixel-consistent across every image I ask for in this chat.

---

## 2. A1 · Master turnaround (generate FIRST — the anchor)  → `assets/character/mor/sheet-turnaround.png`
```
Generate Mor's MASTER TURNAROUND sheet on a TRANSPARENT background (PNG with alpha, no backdrop, no
ground shadow). Show the SAME Mor in 4 clean views evenly spaced in a row: front, 3/4 left, side
profile, and back (tail fanned slightly so the 5 tail-eyes read). Neutral calm "idle" expression,
standing, crest upright. Identical construction, exact palette and proportions from the MOR lock.
Premium semi-flat, clean line, warm upper-left light. 1536×1024.
Reject if: any view differs in shape/color; teal >10%; purple/neon/gloss; a background or ground
shadow appears; fewer/more than 5 tail feathers.
```

## 3. A2 · Expression / mood sheet (9 moods)  → `assets/character/mor/sheet-expressions.png`
```
Using the exact Mor from the turnaround above, generate one labelled EXPRESSION SHEET on a TRANSPARENT
background: a clean 3×3 grid of the SAME Mor (front-facing, consistent size) in 9 moods —
1 idle (calm, half-lidded), 2 greet (small bow, crest up, tail half-fan), 3 think (head tilt, looking
at a tiny floating EAN barcode), 4 work (focused, looking down at a tiny clipboard), 5 celebrate (full
tail-fan + a few marigold #F59E0B petals + happy hop), 6 shelter (one wing wrapped around a small
glowing cream box), 7 concern (soft hopeful brow, slight head tilt — NOT sad), 8 guard (upright,
alert, proud), 9 sleep (curled, crest drooped, tiny "z"). A small text label under each. Identical
construction + palette. 1024×1024.
Reject if: moods look identical; proportions/colors drift; background appears; teal >10%.
```

## 4. A3 · ⭐ PARTS SHEET for rigging (the critical one for animation)  → `assets/character/mor/parts/parts-sheet.png`
```
Using the exact Mor from the turnaround above, generate an EXPLODED PARTS SHEET on a TRANSPARENT
background (PNG alpha, NO backdrop, NO shadow): the SAME front-facing Mor disassembled into clearly
SEPARATED, NON-OVERLAPPING, labelled parts, all at the same scale and style, laid out flat in a neat
grid with space around each so each can be cut out cleanly:
1 BODY (torso + belly, no head/wings/tail/legs)
2 HEAD (face, eyes open, beak — no crest)
3 CREST (the single upright crest feather, straight)
4 EYELID (one closed-eye lid shape, for blinking)
5 WING-LEFT (open, flat)
6 WING-RIGHT (open, flat)
7 TAIL-BASE (the small base the feathers attach to)
8–12 the 5 TAIL FEATHERS as 5 SEPARATE pieces, each straight/upright, each with its teal #0F766E eye +
marigold ring
13 FEET (the two legs/feet)
Each part complete and self-contained, exact Mor palette, clean edges, transparent around every part.
Label each part with small text. 1024×1024 (or 1536×1024 if needed for spacing).
Reject if: parts overlap or share edges; any part is cut off; background/shadow appears; styles/scale
differ between parts; fewer than 5 separate tail feathers.
```
> **Why this matters:** I composite and animate these layers in Flutter (breathing, blink, crest sway,
> tail-fan, wing-shelter). Exact pixel registration isn't required — I set the pivots in code — but the
> parts must be **truly separated, transparent, same scale.** If transparency is messy, use §9.

## 5. A4 · Static mood fallbacks (reduced-motion)  → `assets/character/mor/static/<mood>.png`
> You can simply **slice these from the A2 expression sheet** (9 PNGs) — no new generation needed.
> Name them: `idle.png greet.png think.png work.png celebrate.png shelter.png concern.png guard.png
> sleep.png`. Each a clean transparent crop of one mood. (These show when a device has animations off.)

## 6. A5 · Glyph (mono-line, for nav + loaders)  → `assets/character/mor/glyph.png`
```
Using the exact Mor, generate a tiny SINGLE-LINE GLYPH version on a TRANSPARENT background: Mor reduced
to one clean continuous ink #1C1917 line (uniform ~1.75px weight, rounded terminals), front-facing,
crest + a hint of the tail, readable at 24px. Provide two: inactive (ink-soft #57534E line) and active
(filled burnt-orange #EA580C). 1024×1024.
Reject if: it's detailed/shaded (must be a flat clean glyph); off-weight; background appears.
```

## 7. A6–A8 · Hero scenes (premium, asymmetric composition)
> Art direction for all scenes: **asymmetric, off-center composition, generous negative space, one
> clear focal point, warm cinematic light** — premium, never centered-and-flat. These have a
> background (full scene), portrait **1024×1536**, leave the **lower third cleaner** for the app's
> white sheet/text overlay.

```
A6 · SPLASH  → assets/character/mor/hero-splash.png
Using the exact Mor, a warm dawn-lit RADHA splash scene: Mor in GREET pose, off-center, crest rising,
tail half-fanned, a single saffron feather elegantly tracing toward where the RADHA wordmark will sit;
warm cream #FFFBF5 light, soft glow, generous negative space upper-right, premium and calm. Transparent
or cream background. 1024×1536.
```
```
A7 · OFFLINE (flagship)  → assets/character/mor/hero-offline.png
Using the exact Mor, an OFFLINE scene: Mor in SHELTER pose, off-center-left, one wing curved
protectively around a softly GLOWING cream box stamped with a small saffron RADHA mark; warm interior
light, a blurred warm dukaan (Indian shop) behind, crest gently dimmed (state, not sadness);
reassuring, premium, asymmetric. Keep the lower third clean for a white sheet. 1024×1536.
```
```
A8 · WIN-BEAT  → assets/character/mor/hero-win.png
Using the exact Mor, a celebration scene: Mor CELEBRATE — full tail-fan, a tasteful burst of marigold
#F59E0B petals, a happy hop — beside a proud smiling young Indian store-owner woman (warm saffron/
terracotta clothes, RADHA-marked apron) giving a small thumbs-up; warm confetti light, asymmetric, one
orange accent, joyful but refined. 1536×1024.
```

---

## 8. (Optional, secondary) Human cast sheet
> When you want the human storytelling characters, run `CM3` from `../CHARACTER_STORYTELLING_BIBLE.md`
> §10 (Priya, Rameshbhai, Anjali, customer — RADHA saffron palette, never purple). Not needed for the
> first Mor motion demo.

---

## 9. Transparency & cleanup — precise method (no guesswork)
1. **Always ask** for *"transparent background, PNG with alpha, no backdrop, no ground shadow."*
2. If ChatGPT still returns a background or a white box:
   - Re-prompt: *"same image, but fully transparent background, remove all backdrop and shadow."*
   - If still bad → **magenta fallback:** *"put it on a solid flat #FF00FF magenta background, no
     shadows"* → then remove the magenta with a free tool:
     - **remove.bg** (web, one click), or **Photopea** (free, web Photoshop: Magic Wand the magenta →
       Delete → export PNG), or **Procreate** (iPad).
3. For the **parts sheet**, after transparency, **slice each labelled part** into its own PNG
   (Photopea/Procreate: select around each part → export). Keep them same-scale.

---

## 10. Hand-back checklist (what to send me — and the priority)
Send the files named exactly as below. **Bold = must-have for the first live motion demo.**

- **`assets/character/mor/sheet-turnaround.png`** (the anchor / reference)
- **`assets/character/mor/parts/` — body, head, crest, eyelid, wing-l, wing-r, tail-base,
  tail-1…tail-5, feet** (the rig pieces — THIS is what makes Mor move)
- `assets/character/mor/sheet-expressions.png` + the 9 `static/<mood>.png` crops
- `assets/character/mor/glyph.png` (nav/loader)
- `assets/character/mor/hero-splash.png`, `hero-offline.png`, `hero-win.png` (for those screens)

> Minimum to start the demo: **the turnaround + the parts** (body, head, crest, 2 eyelids, 2 wings,
> tail-base, 5 tail feathers, feet). With just those I can ship Mor breathing + blinking + a tail-fan
> scan-success beat.

---

## 11. After you generate → what happens next (the handoff)
1. You drop the files into `assets/character/mor/...` (exact names above).
2. **Tell me "Mor art is in."** I then:
   - Write the **Flutter motion** (compositing the parts): breathing, blink, crest sway, **tail-fan
     scan-success**, wing-shelter offline — using `flutter_animate` + custom painters, on the
     `RadhaMotion` tokens.
   - **Author the Lottie JSON myself** (you don't generate these): `loader.json`,
     `win-beat-petals.json`, `offline-sync.json`.
   - Wire the `mascotControllerProvider` + reduced-motion static fallbacks + a11y (per
     `CHARACTER_STORYTELLING_BIBLE.md` §7).
3. You see Mor **actually moving** in the app; then we extend across the emotional map (§6 of the bible).

> If any part comes out wrong or you want a different look, send it anyway with a note — I'll tell you
> the precise re-prompt. The goal is the **most refined, premium, asymmetric, on-brand Mor** — and a
> clean rig so the motion is buttery.
