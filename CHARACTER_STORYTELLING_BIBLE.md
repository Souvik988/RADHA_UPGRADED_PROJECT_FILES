# RADHA — Character & Visual-Storytelling Bible

> **An independent, comprehensive system** for transforming RADHA's UI into a character-driven,
> emotionally-told, culturally-rooted experience — the way the best apps make you *feel* something
> on every screen, even the offline and error ones.
>
> This file governs **characters, mascot, emotional storytelling, and the motion engineering** that
> brings them to life. It sits **on top of** the master visual system
> `.kiro/steering/visual-assets.md` (which owns tokens, components, the Scroll Grammar) and the
> `VISUAL_PROMPTS/` generation pack — it never contradicts them. Everything here lives inside
> RADHA's **warm saffron-orange / cream** world (`#EA580C` / `#FFFBF5`), **never** the purple of the
> Bakaloo references. We learned from those references; we are building something more original,
> more meaningful, and consistent across the **whole** app — not two or three screens.
>
> Craft bar: treat this as if directed by someone fluent in Flutter animation, Rive state machines,
> Lottie / After Effects, particle systems, and editorial illustration — **authentic, modern, cool,
> meaningful, engaging.**

---

## 0. How this file relates to the rest

| Concern | Owner file |
|---|---|
| Tokens, color, type, components, Scroll Grammar, per-screen specs | `.kiro/steering/visual-assets.md` + `VISUAL_SCREENS/` |
| Token-free image generation (ChatGPT prompts) | `VISUAL_PROMPTS/` |
| **Characters, mascot, emotional storytelling, character motion** | **this file** |

Rule of precedence: **the master bible wins on tokens; this file wins on character & narrative.**
A character never introduces a color, type, or motion value outside the master bible.

---

## 1. The vision — why RADHA needs characters

Most retail/utility apps treat empty, offline, error, loading and success as *dead ends*. The
Bakaloo references prove the opposite: a single recurring human, **emoting to the moment**
(scratching his head when offline, calm when verifying OTP), turns a system state into a small human
story — engaging, warm, memorable.

RADHA goes further on three axes:
1. **A cast, not a clip-art.** A signature **companion mascot** + a small **human shopkeeper cast**,
   used with intent across *every* surface — onboarding to win-beats — so the app feels authored.
2. **Meaning, not decoration.** Every character beat ties to RADHA's real value (your data is safe
   offline; your store is watched over; today's mission; the win). Characters *say something true*.
3. **Motion that's engineered, not stickered.** Reactive **Rive** state-machines + scripted **Lottie**
   scenes + `flutter_animate` choreography, on a strict performance + reduced-motion budget.

**North star:** a shopkeeper should feel that RADHA is a *warm, devoted companion who has their back*
— and want to open it again tomorrow. Characters are how we earn that feeling.

---

## 2. The cultural foundation — "RADHA, with devotion" (handled with respect)

The name **RADHA** resonates with **Radha** of the Radha–Krishna tradition — the embodiment of
*selfless devotion, love, and care*. We honour the **spirit and symbolism**, never the deity's image.

**The meaning we borrow (and what it becomes in product):**
| Source motif | Cultural meaning | RADHA product meaning |
|---|---|---|
| **Saffron / kesari** (our `#EA580C`) | sacred, auspicious, devotion | the brand is *devoted* to the shopkeeper's success; orange = our saffron |
| **Peacock feather (mor pankh)** | beauty, watchfulness, Krishna's crown, monsoon abundance | our **companion mascot** — beautiful + *watches over* the store (audit) |
| **Marigold (genda) / lotus** | devotional offering, celebration, purity | win-beats, festive skins, success petals |
| **Bansuri (flute) — the call** | calling, guidance | the mascot "calls" the owner to today's mission |
| **Devotion (bhakti) itself** | selfless, steadfast care | RADHA = a steadfast, caring "second-in-command" |

**Respect guardrails (non-negotiable):**
- **Never depict Radha, Krishna, any deity, idol, or religious figure** — not as a mascot, avatar,
  illustration, or icon. We evoke *values and natural/folk motifs* (peacock, feather, marigold,
  saffron light), never iconography of the divine.
- No religious symbols used trivially (no om/temple/tilak slapped on UI; no prayer poses for
  comedy). Cultural warmth is carried by **light, colour, craft, and the peacock/marigold motif** —
  tasteful, modern, never kitsch, never stereotype (no garba-dance clip-art, no flags, no rangoli
  wallpaper behind text).
- Authentic, inclusive India: real shopkeepers of varied ages, faiths, and regions — dignified,
  never caricatured.
- When in doubt, choose **subtle symbolism over literal reference**. The feeling is *devotional
  warmth*, not a religious statement.

This foundation is what makes RADHA *mean* something the Bakaloo grocery character never could.

---

## 3. The cast (overview)

RADHA ships **two layers** of character — together they beat any single-mascot or single-human system:

1. **Mor — the companion** (signature, ownable). A stylised **peacock guide** that embodies
   watchful, devoted care. Appears as the brand's living presence: splash, loading, empty, success,
   offline shelter, achievements, the nav "scan" pulse. This is RADHA's unique, trademark-able face.
2. **The Shopkeeper Cast** (human, relatable). A small set of authentic Indian retail people used for
   *emotional, situational* storytelling (onboarding, OTP, offline, error, big empty states) — the
   warmth the references nailed, but in RADHA's world and tied to RADHA's real roles.

**When to use which:** Mor leads *brand & system* moments (it's calm, never alarming). Humans lead
*situational, emotional* moments where relatability matters. They co-star on the biggest scenes
(splash, win-beats, onboarding). Never more than **one human + Mor** in a single frame (clarity).

---

## 4. Mor — the companion mascot (full spec)

> **Working name:** **Mor** (Hindi/Gujarati for peacock). Brand-name alternates for the client:
> *Moru · Pankhi · Neelu*. Design is final; the name is a one-line swap.

### 4.1 Concept & meaning
A warm, modern peacock who is RADHA's **devoted guardian of the store** — it watches (audit), it
guides (today's mission), it celebrates the win, and it shelters your data when you go offline.
Beautiful but never vain; calm, competent, kind. Think *"a wise, friendly shop-cat energy" in a
peacock* — present, reassuring, a little delightful.

### 4.2 Silhouette & construction (so it's instantly recognisable at 24 px and 240 px)
- **Primary read:** a rounded, plump body + a single **upright crest feather** (the "tilak" of the
  silhouette) + a **fan hint** of 3 tail eyes. Recognisable as a pure black silhouette.
- **Geometry:** built on soft circles and the RADHA `~2px` corner-radius language; **single
  continuous warm line** option for the small/icon variant (matches the icon family §4 of the bible).
- **Proportions:** chibi-leaning (body : head ≈ 1 : 0.9) for warmth, but *not* babyish — confident
  stance. Three construction sizes: **Glyph** (nav/loaders, monoline), **Spot** (cards/empty states,
  semi-flat), **Hero** (splash/win, full painterly-clean).

### 4.3 Palette (stays inside the brand — this is the critical consistency move)
A peacock is naturally teal/blue — which would fight the brand. So **Mor is a *saffron* peacock**:
- Body: warm cream `#FFFBF5` → accent-tint `#FED7AA` belly, burnt-orange `#EA580C` plumage edges.
- Crest + tail-eyes: the **one** sanctioned peacock accent — **teal `#0F766E`** (the bible's
  "very-sparing complement"), used *only* in the feather eyes + crest tip, ≤10% of the character.
  Marigold `#F59E0B` highlight in the eye ring for festive/celebrate states.
- Outline/ink: `#1C1917` (never pure black). Eyes warm ink with a single catchlight.
- **Net effect:** reads unmistakably RADHA-orange first, peacock second. Teal whispers; saffron speaks.

### 4.4 Personality & voice
Devoted, watchful, warm, lightly playful, *never* anxious or slapstick. Mor reassures in bad moments
(offline/error) rather than panicking — its calm is the brand promise. It never speaks in first
person on screen (copy stays RADHA's voice); it *emotes*, it doesn't talk.

### 4.5 Expression / state set (this drives the Rive state machine, §7)
| State | Pose / expression | Used on |
|---|---|---|
| **Idle** | gentle breath, slow crest sway, occasional blink + one feather-eye shimmer | loaders, ambient |
| **Greet** | small bow + crest rise + tail half-fan | splash, onboarding, first open |
| **Think / Work** | head tilt, looking at a tiny floating EAN/clipboard, focused | scanning, processing, syncing |
| **Celebrate** | full tail-fan burst + marigold-petal pop + happy hop | win-beats, audit complete, OHS milestone |
| **Shelter** | wing wrapped around a small glowing "saved" box, calm, protective | **offline** (our brand twist) |
| **Concern** | soft brow, head tilt, *hopeful* not sad, one wing rubbing neck | error / 500 |
| **Guard** | upright, alert, scanning a shelf — watchful pride | store-health, verified badge |
| **Sleep** | curled, crest drooped, "z" feather | long idle / locked at rest |

### 4.6 Do / Don't
- **Do** keep one continuous warm line in the glyph size; keep teal ≤10%; keep it calm in errors.
- **Don't** make it photoreal, glossy, neon, or babyish; don't add a flute/crown that reads as a
  deity reference; don't let teal dominate; don't animate it talking; don't use it to *block* (it
  guides, it never scolds).

---

## 5. The human shopkeeper cast (full spec)

Authentic, dignified, warm Indian retail people — relatable like the Bakaloo character, but **in
RADHA's palette** (saffron/cream/terracotta wardrobe, never purple) and tied to RADHA's real roles.

| Persona | Role (matches product) | Look (authentic, not caricature) | Emotional range |
|---|---|---|---|
| **Priya** | young store **owner** (the "Hi Priya" greeting) | late-20s, confident, kurti/shirt in warm tones, dupatta or apron with subtle RADHA mark | proud, focused, relieved, delighted |
| **Rameshbhai** | seasoned **staff / auditor** | 40s, salt-pepper, half-sleeve shirt, clipboard, reading glasses | diligent, reassuring, "on it" |
| **Anjali** | **manager** | 30s, smart-casual, tablet in hand | decisive, calm-under-load |
| **The customer** | consumer mode | varied ages, everyday Indian street-wear, a cloth bag of real products | curious, satisfied |

**Wardrobe & world:** warm saffron/terracotta/cream clothing; the store world is a clean, sunlit
Indian *dukaan* (shelves, a striped RADHA awning, neat product packs — atta, basmati, dal, masala,
dairy) — the merchandised warmth of the Bakaloo bag, RADHA-branded.

**Casting rules:** diverse ages/faiths/skin tones; dignified posture; expressive but never mocking;
hands and props read clearly (phone, clipboard, scanner, product). **Relatable, never a mascot of a
stereotype.** One human max per frame (with optional Mor).

---

## 6. The emotional storytelling map (every screen + state)

The heart of this system: **who** appears, feeling **what**, saying **what** — across the whole app.
RADHA's twist vs the references: we convert dead-ends into *brand-affirming* moments (especially
offline, since RADHA is **offline-first** — a problem the references don't have an answer for).

### 6.1 Master map
| Surface / state | Character + emotion | Scene & RADHA twist | Copy tone (real, short) |
|---|---|---|---|
| **Splash** | **Mor — Greet** | crest rises, tail half-fans, a single saffron feather draws the RADHA mark; warm dawn light | none / wordmark only |
| **Onboarding 1–3** | Priya **+ Mor** | Priya runs her proud dukaan; Mor guides through segment → value → consent; one illustrated story panel each | "Run a tighter, prouder store." |
| **OTP request / verify** | Priya — **calm, trusting** (like the smiling Bakaloo OTP) | seated, warm room, phone in hand, Mor perched small + reassuring | "Verify your number." |
| **Offline** ⭐ | **Mor — Shelter** + Rameshbhai patient | Mor wraps a wing over a glowing **"saved" box**; RADHA twist: *your work is safe, keep going* | "You're offline — but your work is safe. RADHA saved everything and will sync when you're back." · Retry · *Keep working offline* |
| **Error / 500** | Rameshbhai **+ Mor — Concern (hopeful)** | "we're on it" energy, gentle, a tiny wrench/heartbeat, never alarmist | "Something hiccuped on our side. We're on it — try again in a moment." · Try again · Go home |
| **Empty: scans** | **Mor — Greet**, pointing to scanner | tidy empty shelf + magnifier; invites the first scan | "No scans yet — point at a barcode to begin." · Scan now |
| **Empty: tasks** | Priya **— relieved/smiling** | a cleared board, chai cup | "No tasks today. Go enjoy the chai." |
| **Empty: expiry** | **Mor — Guard**, calm | green-lit fresh shelf | "All clear — nothing expiring soon." |
| **Empty: inventory/GRN** | Rameshbhai with clipboard | ready-to-start stance | "Add your first stock entry to begin." |
| **Loading (≥300ms)** | **Mor — Think** (Rive idle-think loop) | feather shimmer + tiny floating EAN | skeletons carry the layout (bible §16) |
| **Win-beat: audit/expiry cleared, GRN received** | **Mor — Celebrate** + Priya proud | tail-fan + **marigold-petal** burst; "Shabaash!" | "Shabaash! Aisle 4 audited — 12 of 12 verified." |
| **Achievement: OHS milestone / Verified badge** | Priya **+ Mor — Guard→Celebrate** | badge unfurls, peacock-eye seal shimmer | "Your store is RADHA Verified." |
| **Locked / paid** | **Mor — Guard**, gentle gatekeep | value shown behind warm glass, Mor presents the key, never scolds | "Unlock Reports & store health." |
| **Notifications empty** | **Mor — Sleep** | curled, peaceful | "You're all caught up." |
| **Subscription success** | **Mor — Celebrate** + confetti | premium glow | "Welcome to RADHA Pro." |
| **Recall alert (serious)** | **no comedy** — Rameshbhai **alert**, restrained | urgency without panic; clarity first | "Recall: action needed on 2 batches." |

> **Tone discipline:** serious states (recall, hard data loss) reduce character whimsy and lead with
> clarity (a11y first). Character warmth is for *friction*, not *danger*.

### 6.2 The offline screen — worked example (our flagship "better than the reference")
The references show a confused man — a *dead end*. RADHA's offline screen is a **promise kept**:
- **Hero:** Mor in **Shelter** pose, one wing curved around a softly-glowing cream box stamped with a
  tiny saffron RADHA mark and a mono "synced: 2 min ago"; warm interior light; the dukaan blurred
  warm behind. A small **offline feather** (crest dimmed, not drooping) signals state without sadness.
- **Sheet copy:** title "You're offline — your work is safe" (w800), body "RADHA saved everything on
  this device. Keep scanning and adding — we'll sync the moment you're back." Buttons: **primary
  orange "Keep working"** (this is the brand flex — you *can*), secondary "Retry connection."
- **Motion:** Mor's wing breathes (Rive idle); the box pulses a slow warm glow; on reconnect, the box
  "lifts" and a marigold spark runs up a sync line → instantly flips to a tiny **Celebrate**. The
  state *resolves on screen*. That micro-story is the retention hook.

This is the model: **find the brand truth in each state and let the character tell it.**

---

## 7. Motion & animation engineering (the hard part, done right)

Three technologies, each for what it's best at — on a strict budget.

### 7.1 Technology split
| Layer | Tech | Use |
|---|---|---|
| **Reactive mascot** | **Rive** (`rive` pkg) + state machine | Mor everywhere he reacts to app state (loading↔done, offline↔online, idle↔celebrate). One `.riv` file, many states. |
| **Scripted scenes** | **Lottie** (`lottie` pkg), authored in After Effects | splash reveal, win-beat confetti, big empty-state set-pieces, marigold-petal burst. |
| **UI choreography** | `flutter_animate` + native `AnimationController` | entrance, parallax, stagger, press-scale — tied to `RadhaMotion` tokens (bible §2.5/§14). |
| **Particles** | Rive or a light custom `CustomPainter` | feather shimmer, marigold petals, confetti, sync spark. |

**Why Rive for Mor (not Lottie):** Mor must *react* — go from idle→think→celebrate driven by app
state, follow progress (0–1), and blend moods. Rive **state machines** take runtime inputs and blend
states; Lottie only plays fixed clips. Rive files are smaller and GPU-cheap. Lottie stays for
*authored, non-interactive* set-pieces where AE's vector control wins.

### 7.2 Mor's Rive state machine (spec the rigger builds to)
- **File:** `assets/rive/mor.riv` (one artboard "Mor", one state machine "MorSM").
- **Inputs:**
  - `mood` (number enum): 0 idle · 1 greet · 2 think · 3 work · 4 celebrate · 5 shelter · 6 concern · 7 guard · 8 sleep
  - `progress` (number 0–1): drives think→done, loaders, gauge sync
  - `intensity` (number 0–1): celebration size
  - `trigTap`, `trigSuccess`, `trigError` (triggers): one-shot reactions
  - `lookX`, `lookY` (numbers −1..1): optional eye/crest follow on interactive screens
  - `reduceMotion` (bool): when true, SM snaps to a single expressive frame per mood (no loops)
- **States & blends:** Idle (looping, breath+blink+shimmer) ⇄ each mood via 200–320ms blends
  (`RadhaMotion.normal/slow`, easeOut). Celebrate = 800ms one-shot (`motion.celebrate`, spring) then
  settle to Idle. Concern never loops anxiously (one settle, then calm idle).
- **Budget:** `.riv` **< 150 KB**; ≤ 2 simultaneous Mor instances on a screen (usually 1).

### 7.3 Flutter integration (architecture)
- **`mascotControllerProvider`** (Riverpod): owns the `StateMachineController`, exposes typed setters
  (`setMood`, `setProgress`, `celebrate(intensity)`, `goOffline()/goOnline()`), reads
  `MediaQuery.disableAnimations` → sets `reduceMotion`. Disposed with the route.
- **Preload** `mor.riv` + splash Lottie during the splash boot (warm cache, no first-use jank).
- **`MorView`** widget = `RiveAnimation.asset` wrapping the SM; a sibling `Semantics(label: …)` always
  describes the *state in words* (the character is `excludeSemantics`).
- **Lottie** scenes via `Lottie.asset(..., controller)`; gate loop on reduced-motion; `.lottie`
  (dotLottie) for multi-clip packs.
- **Reduced motion (mandatory):** every animated character has a **static expressive PNG fallback**
  per mood (`assets/character/mor/static/<mood>.png`); when `disableAnimations` is true we show the
  PNG and skip Rive/Lottie. *No state is ever conveyed by motion alone.*

### 7.4 Per-moment motion specs (examples — every signature moment gets one)
| Moment | Trigger | Build | Duration / curve | Reduced-motion |
|---|---|---|---|---|
| **Splash reveal** | cold start | Lottie: dawn light → Mor Greet → feather draws RADHA mark; preloads app | ≤ 1500 ms, easeOutQuint | static logo + Mor Greet PNG |
| **Scan success** | verified scan | Mor `trigSuccess` → Celebrate(0.5) + haptic.success + 6 marigold petals | 600 ms, spring | success pill + static celebrate PNG |
| **Win-beat** | mission complete | Mor Celebrate(1.0) + Lottie petal burst + count-up | 800 ms, motion.celebrate | static + confetti-still |
| **Offline shelter** | connectivity off | Mor → Shelter, box glow loop; on reconnect sync-spark → Celebrate(0.4) | enter 320 ms; resolve 600 ms | static Shelter PNG + text |
| **Loading** | data ≥ 300 ms | Mor Think + `progress` bound to load; skeletons behind | loop, instant in reduce | skeletons only |

### 7.5 Performance budget (gate, not aspiration)
60 fps on Pixel 4a / iPhone SE2 · Rive `.riv` < 150 KB · each Lottie < 60 KB · static fallbacks < 20 KB ·
≤ 2 concurrent rigged characters · preload only splash + Mor; lazy-load scene Lotties · never animate
layout, only transform/opacity (bible §2.5). A character that misses budget ships as a static spot.

### 7.6 Accessibility
Characters are decorative → `excludeSemantics: true`; a sibling `Semantics` always conveys the state
in text. Honor `disableAnimations` + `highContrast` (static high-contrast PNGs). Never rely on a
character (or color) alone to communicate offline/error/success — text + icon always present.

---

## 8. Signature moments to build first (the "wow" five)
Build these five to set the bar before scaling to every state:
1. **Splash** — Mor Greet draws the RADHA mark (Lottie). The first impression.
2. **Offline shelter** — the flagship "your work is safe" story (Rive, §6.2).
3. **Scan success** — the daily dopamine (Rive Celebrate + petals).
4. **Win-beat** — "Shabaash!" mission complete (Rive + Lottie).
5. **Onboarding hero** — Priya + Mor introduce RADHA (Lottie/illustrated panels).
Ship these, run the anti-slop + reduced-motion + a11y gates, then extend to the full §6 map.

---

## 9. Production pipeline & asset organisation

### 9.1 Illustration craft (so all character art matches)
Warm, **semi-flat with soft painterly depth** (the Bakaloo quality level) but in RADHA's saffron/
cream/ink palette; clean edges, controlled light (warm key, soft fill), no glossy 3D, no neon. The
human cast slightly more painterly; Mor slightly more graphic/vector so he scales to a glyph.

### 9.2 Tooling path
1. **Concept art** → generate with ChatGPT (§10 prompts), keep the best, lock the character sheet.
2. **Refine** in Photoshop / Procreate (clean line, palette-snap to tokens, build the expression
   sheet). Export PNGs (static fallbacks) + layered source.
3. **Rig Mor** in the **Rive editor** (bones/meshes + the §7.2 state machine) → `mor.riv`.
4. **Author scenes** in **After Effects → Bodymovin/Lottie** (splash, petals, win-beat) → `.json`/`.lottie`.
5. **Optimise** (SVGO for any SVG, Lottie compression, dotLottie packing) to hit §7.5 budgets.

### 9.3 Asset paths & naming
```
assets/
  character/
    mor/
      sheet-turnaround.png        # construction turnaround
      sheet-expressions.png       # all 9 moods
      static/<mood>.png           # reduced-motion fallbacks (idle, greet, … sleep)
      hero-splash.png  hero-offline.png  hero-win.png
    humans/
      priya-<emotion>.png  ramesh-<emotion>.png  anjali-<emotion>.png  customer-<emotion>.png
  rive/
    mor.riv
  lottie/
    splash.json  scan-success.json  win-beat-petals.json  offline-sync.json
```
Reconcile with `ASSET_PIPELINE.md` and the bible §8 (categories). PNG icons stay banned; character
*illustrations* may be PNG (raster art), but Mor's **glyph** form is SVG for the icon family.

---

## 10. Character generation prompts (ChatGPT, token-free — same workflow as `VISUAL_PROMPTS/`)

Run in the SAME ChatGPT chat as `VISUAL_PROMPTS/00_PRIMER.md` (so the locked RADHA palette/world
applies). Generate the **sheets first** (they lock the character), then per-state scenes. Save under
`assets/character/...`. Remember: full-screen text is approximate; character art comes out clean.

### CM1 · Mor — character turnaround sheet → `assets/character/mor/sheet-turnaround.png`
```
Design "Mor", an original mascot for RADHA, per the RADHA locked system. A friendly, modern,
CHIBI-LEANING-BUT-CONFIDENT PEACOCK that is mostly WARM SAFFRON: cream #FFFBF5 body, #FED7AA belly,
burnt-orange #EA580C plumage edges, with ONE restrained TEAL #0F766E accent only in the crest tip and
3 tail-feather "eyes", a tiny marigold #F59E0B eye-ring; ink #1C1917 line (never pure black), warm
eyes with a single catchlight. Rounded, soft-geometric, ~2px corner-radius language, premium semi-
flat with soft depth (not glossy, not 3D, not neon). Show a clean TURNAROUND: front, 3/4, side, plus a
tiny single-line GLYPH version that reads at 24px. Calm, devoted, watchful personality — a wise
friendly guardian, not babyish, not vain. On #FFFBF5. No deity/crown/flute, no purple, no neon.
```

### CM2 · Mor — expression / mood sheet → `assets/character/mor/sheet-expressions.png`
```
Same Mor character, one labelled EXPRESSION SHEET of 9 moods, identical construction and palette:
idle (calm, half-lidded), greet (small bow + crest up + half tail-fan), think/work (head tilt at a
tiny floating EAN/clipboard), celebrate (full tail-fan + marigold petals + happy hop), shelter (wing
wrapped around a small glowing cream "saved" box), concern (soft hopeful brow, NOT sad), guard (alert,
proud, scanning a shelf), sleep (curled, crest drooped, tiny "z"). Consistent warm saffron palette,
teal only in feather-eyes. On #FFFBF5. These map to a Rive state machine.
```

### CM3 · Human cast — character sheet → `assets/character/humans/sheet.png`
```
A warm, authentic, dignified INDIAN SHOPKEEPER cast for RADHA, per the locked system, in RADHA's
SAFFRON/CREAM/TERRACOTTA palette (never purple). Four people on one labelled sheet: PRIYA (late-20s
confident store owner, kurti/shirt warm tones, subtle RADHA-marked apron); RAMESHBHAI (40s seasoned
staff/auditor, salt-pepper, half-sleeve shirt, clipboard, reading glasses); ANJALI (30s manager,
smart-casual, tablet); a CUSTOMER (everyday street-wear, cloth bag of real Indian products — atta,
basmati, dal, dairy, veg). Semi-flat painterly warmth, clean edges, controlled warm light, premium.
Relatable real people, never caricature, diverse, dignified. On a warm sunlit dukaan backdrop.
```

### CM4 · Per-state scene prompts (examples — generate as needed, one per state)
```
SPLASH → A warm dawn-lit RADHA splash: "Mor" in GREET pose, crest rising, tail half-fanned, a single
saffron feather elegantly drawing the RADHA wordmark; cream #FFFBF5, soft warm glow, premium, calm.
Portrait 1024×1536.  Save → assets/character/mor/hero-splash.png
```
```
OFFLINE (flagship) → "Mor" in SHELTER pose, one wing curved protectively around a softly glowing cream
box stamped with a small saffron RADHA mark and a tiny mono "synced 2 min ago"; warm interior light,
a blurred warm dukaan behind, crest gently dimmed (state, not sadness); reassuring, premium. Leaves
lower third clean for the white sheet. Portrait 1024×1536.  Save → assets/character/mor/hero-offline.png
```
```
WIN-BEAT → "Mor" CELEBRATE: full tail-fan, a burst of marigold #F59E0B petals, a happy hop, beside a
proud smiling PRIYA giving a small thumbs-up; warm confetti light; one orange accent; premium, joyful
but tasteful. 1536×1024.  Save → assets/character/mor/hero-win.png
```
```
ERROR/500 → RAMESHBHAI with a calm "we're on it" expression + "Mor" in CONCERN (hopeful, head tilt,
tiny wrench), warm dukaan-gate backdrop, NOT alarmist; leaves lower third for the white sheet.
Portrait 1024×1536.  Save → assets/character/humans/ramesh-onit.png
```

> Generate expression/turnaround sheets first; reuse them as visual reference ("match Mor from our
> sheet") for every scene so the character never drifts.

---

## 11. Consistency, respect & anti-slop guardrails (done-gate)

A character beat is **done** only when:
- **In-system:** uses only RADHA tokens (palette/type/motion); Mor's teal ≤10%; no purple/neon/gloss.
- **Consistent:** matches the locked turnaround + expression sheets; one human + optional Mor per frame.
- **Meaningful:** ties to a real RADHA truth (offline-safe, mission, watch-over, win) — not decoration.
- **Respectful:** zero deity/idol/religious depiction; symbolism (peacock/marigold/saffron) only;
  dignified, non-stereotyped people.
- **Engineered:** Rive/Lottie within budget (§7.5); **static + text fallback** for reduced-motion;
  `excludeSemantics` + a real text label; state never conveyed by motion/colour alone.
- **Anti-slop (`impeccable` test):** no one could say "a generic mascot/AI made that." Distinct,
  authored, warm. Fix structure, not paint.
- **Tests green:** widget tests pass; no jank on Pixel 4a.

---

## 12. How to use this file / build order
1. Lock **Mor** + **human** sheets (CM1–CM3 → refine in Photoshop/Procreate).
2. Build the **wow five** (§8): splash, offline, scan-success, win-beat, onboarding.
3. Rig `mor.riv` (§7.2) + author the Lottie set-pieces; wire `mascotControllerProvider` (§7.3).
4. Roll Mor + the human cast across the full **emotional map** (§6), screen by screen, alongside the
   `VISUAL_SCREENS/` specs — each new screen names its character beat in its own spec file.
5. Gate every beat through §11. Keep the master bible the source of truth for tokens.

---

## Changelog
- **2026-06-03 — v1.0** Created the RADHA Character & Visual-Storytelling Bible: cultural foundation
  ("RADHA, with devotion" — respectful peacock/marigold/saffron symbolism, no deity depiction); the
  dual cast (**Mor** the saffron-peacock companion + the human shopkeeper cast); the full emotional
  storytelling map across every screen/state (incl. the offline-first "your work is safe" flagship);
  the motion engineering (Rive state machine + Lottie + flutter_animate + particles, with budgets,
  Flutter architecture, reduced-motion + a11y); production pipeline; and token-free ChatGPT character
  prompts. Consistent with `.kiro/steering/visual-assets.md` (warm orange/cream) — not Bakaloo purple.
