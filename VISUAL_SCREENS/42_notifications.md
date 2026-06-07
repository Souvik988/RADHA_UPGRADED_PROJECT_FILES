# 42 · Notifications — `/notifications`
Mode: **both** · Tab/Stack: **drill-down** (pushed from Home bell, §08 Z-HERO) · Gate: none

> Governed by `.kiro/steering/visual-assets.md` (the Bible) + `CHARACTER_STORYTELLING_BIBLE.md`
> (Mor). All tokens, motion, image-gen blocks (§6.1/§6.2) and Scroll Grammar (§5) are **cited,
> not repeated**. Quality bar: **beat the reference mockup.** Honest-data law (§0.5): render only
> what `GET /notifications` returns — never invent a count or a fake alert.

---

## Story arc
**Human beat** (slim "Notifications" band — RADHA quietly catching the owner up: *"Here's what
moved while you were away"*) → **Substance** (Unread/All filter → grouped, dated notification rows
with category glyphs + status dots) → **Action** ("Mark all read" + each row taps through to its
real destination route).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| List + pagination | `notificationsProvider` / `GET /notifications` (cursor) | notifications BE-31 | Cursor `(created_at desc, id desc)`. Each row carries `type`, `title`, `body`, `createdAt`, `readAt`, optional `deeplink`. |
| Unread filter | `GET /notifications?unread=1` | notifications | Drives the "Unread" segment; count = Home bell badge source. |
| Mark one read | `POST /notifications/:id/read` | notifications | Optimistic; dot clears on tap, reconciles on response. |
| Mark all read | `POST /notifications/read-all` | notifications | One call; clears all unread dots + Home badge. |
| Preferences | `GET/PATCH /notifications/preferences` | notifications | Channel toggles (push/expiry/tasks/GRN/recall) — sub-surface S2. |
| Row deep-link | row `deeplink` → GoRouter route | — | Routes to the **real** owning screen (expiry/tasks/GRN/recall/subscription). Missing deeplink → row is non-tappable, no fake nav. |

**Role/mode note:** notification *types* differ by role (consumer sees recall/expiry/family;
business sees tasks/GRN/low-stock/OHS) but the screen chrome is identical. Never render a type the
backend didn't send for this user.

---

## Scroll zones (top → bottom)

### Z-HERO — Slim notifications band  *(~120 dp, styled — never a bare AppBar)*
- **Layout:** slim warm band, cream→`#FFF3E6` tonal wash; back chevron left; title **"Notifications"**
  `headlineMedium` `w800` ink `#1C1917`; trailing **"Mark all read"** text button accent-deep
  `#9A3412` (disabled 0.38 when 0 unread). A small **Mor `greet`** (40 dp) sits right of the title
  as the human beat — RADHA catching you up.
- **Sub:** one ink-soft line "Here's what moved while you were away." `bodySmall`.
- **Tokens:** padding `space16` H; title→sub gap `space8`; band radius bottom `lg`.
- **Motion:** band fade-in; at scroll the title compresses to a sticky slim bar; Mor honors
  reduced-motion (static frame).
- **A11y:** title `Semantics(header:true)`; "Mark all read" labeled w/ live count
  ("Mark all 3 as read"); Mor `excludeSemantics`.
- **States:** loading → title skeleton; 0 unread → "Mark all read" disabled.

### Z1 — Filter segment  *(sticky under the band)*
- **Layout:** segmented control (§3.11) — **Unread · All** — sliding orange `#EA580C` indicator
  (animate position via transform, not color). Right: optional **gear** glyph → preferences (S2).
- **Tokens:** pill track `surface sunken` `#F5F1E8`, `radius.full`, active segment `surface raised`.
- **Motion:** indicator slides 200 ms `easeOut`; list cross-fades on switch.
- **A11y:** each segment `Semantics(selected:)`; gear labeled "Notification settings".
- **States:** sticky-pins below the slim title bar when scrolled.

### Z2 — Notification list  *(grouped by day; eyebrow per group: "TODAY" / "YESTERDAY" / "EARLIER")*
- **Layout:** vertical list of **notification rows**, divided by hairline `#E7E1D4`, grouped under
  small `w600` ink-soft day eyebrows. Each row:
  - **Leading:** category glyph in a `md` tinted well (8–12 % alpha): expiry→Cat-amber `#B45309`
    clock · task→Cat-orange `#EA580C` clipboard · GRN→Cat-green `#15803D` truck · low-stock→Cat-
    violet `#6D5BD0` box · recall→Danger `#B91C1C` alert · store-health→Cat-teal `#0F766E` shield.
  - **Body:** `title` `titleMedium` `w600` ink + `body` `bodySmall` ink-soft (2-line clamp).
  - **Trailing:** **mono** relative time "2h", "Yesterday", "12 Aug" `monoLabel`; **unread dot**
    8 dp `#EA580C` (only when `readAt == null`).
  - Unread rows carry a faint `#FED7AA` 6 % left wash; read rows are flat cream.
- **Tokens:** row min 72 dp, well 40 dp `radius.md`, glyph accent-deep, ≥48 dp target.
- **Motion:** rows fade-up stagger 40 ms on first reveal; tap → dot clears (120 ms) + press-scale
  `0.97`; swipe-left reveals "Mark read" (orange) action.
- **A11y:** row = one `Semantics(button)` ("Task due: Check dairy fridge temps, 2 hours ago,
  unread"); time announced; ≥48 dp.
- **States:** loading → 6 skeleton rows (well + 2 text lines); paginating → footer spinner;
  read row → no dot, no wash.

### Z-EMPTY / Z-ERROR  *(replaces Z2 when applicable — first-class, §3.14)*
- **Empty (Unread, all caught up):** **Mor `sleep`** (96 dp, peacock resting) on a sunken
  `#F5F1E8` backer, title `w700` **"You're all caught up"**, line "No new notifications. Mor's
  keeping watch.", no CTA (calm). *Second-read moment — personality required.*
- **Empty (All, brand new account):** **Mor `greet`** (104 dp), "Nothing here yet", "Alerts about
  expiry, tasks and recalls will land here.", subtle orange "Go to Home" → `/home`.
- **Error:** same chrome, **Mor `concern`** + danger-tinted retry; "Couldn't load notifications."
  + orange **Retry** (re-runs `notificationsProvider`).

### Z-NAV
None — this is a drill-down. Back chevron in Z-HERO returns to Home; bottom nav hidden.

---

## Sub-surfaces
- **S1 · Row overflow / long-press sheet** — bottom sheet `xl`, drag handle: "Mark as read",
  "Mute this type" (→ writes a preference), "Open" (deeplink). Spring enter from bottom.
- **S2 · Notification preferences sheet/screen** — toggles backed by `GET/PATCH
  /notifications/preferences`: Push enabled, Expiry, Tasks, GRN, Recall, Store-health, Weekly
  digest. Orange focus ring on switches; saves optimistically. Small Mor `think` endorsing the
  controls (decorative).
- **S3 · Permission prompt (first run)** — if OS push permission undetermined, a tasteful inline
  card (not a blocking dialog) "Turn on alerts so you never miss an expiry" + orange "Enable"
  (triggers OS prompt) — only shown once, dismissible.

---

## State gallery (generate a mockup for each)
`default (mixed read/unread, grouped)` · `unread-only` · `loading (skeleton rows)` ·
`empty all-caught-up (Mor sleep)` · `empty new-account (Mor greet)` · `error (Mor concern)` ·
`preferences sheet` · `offline (banner + last-synced list)`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Notifications mockup (default)** | `generate_ui_mockup` | `assets/v2/mockup/notifications.png` | SCREEN: Notifications (/notifications). STORY: slim "Notifications" band with small peacock mascot greeting → Unread/All segmented control with sliding orange indicator → day-grouped rows (TODAY / YESTERDAY) each with a tinted category glyph well, two-line title+body, mono relative time, orange unread dot. FOCAL: the unread rows. COPY (verbatim): title "Notifications", sub "Here's what moved while you were away.", "Mark all read", rows: "Task due · Check dairy fridge temps · 2h", "GRN received · 2 invoices posted to stock · 5h", "Expiring soon · 18 items before Friday · Yesterday", "Recall alert · Batch check needed · 12 Aug". Real product cutouts: no. Motion-implied: fade-up stagger, dot clear, sliding segment. |
| A1 | Empty "all caught up" mockup | `generate_ui_mockup` | `assets/v2/mockup/notifications-empty.png` | Empty unread state: resting peacock mascot (Mor `sleep`) on a soft sunken cream backer, title "You're all caught up", line "No new notifications. Mor's keeping watch." Calm, no CTA. |
| A2 | Notification category glyph set (6) | `generate_icon_set` | `assets/v2/icons/notif-set.svg` | One batch, RADHA warm rounded glyphs (~1.75dp single weight, ~2px radius, rounded terminals): clock(expiry), clipboard(task), truck(GRN), box(low-stock), alert-triangle(recall), shield-check(store-health). Each renderable in its category tint. |
| A3 | Preferences sheet mockup | `generate_ui_mockup` | `assets/v2/mockup/notifications-prefs.png` | Bottom sheet with toggle rows (Push, Expiry, Tasks, GRN, Recall, Store-health, Weekly digest), orange switches, small thinking-peacock mascot endorsing the controls. Same RADHA system. |

> **Mor reuse:** `greet` / `sleep` / `concern` / `think` frames already exist under
> `assets/v2/character/mor/static/` — reference, don't regenerate. Only A0–A3 are new renders.

---

## Motion checklist (Emil) — reduced-motion safe
band fade + sticky compress ✓ · segment slide (transform) ✓ · row fade-up stagger (once) ✓ · unread
dot clear 120 ms ✓ · swipe-to-read ✓ · press-scale 0.97 + haptic.light ✓ · pull-to-refresh (custom
orange) ✓ · Mor breathing collapses to static under `MediaQuery.disableAnimations` ✓.

## Accessibility checklist
header semantics ✓ · each row one labeled button w/ read-state + time ✓ · segment selected-state ✓ ·
"Mark all read" live count ✓ · ≥48 dp targets ✓ · WCAG-AA ink-on-cream + orange dot visible to
color-blind via position not color-only ✓ · 2.0× text-scale: body clamps, time wraps under, no
clip ✓ · Mor excluded from semantics ✓.

## Anti-slop gate
one orange accent region (segment + dots), not a rainbow ✓ · category tints whisper, dots speak ✓ ·
no nested cards (rows are hairline-divided, not boxed) ✓ · empty state has real personality (resting
Mor) ✓ · honest data — no fabricated alerts ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/skeleton present ✓ ·
slop gate ✓ · wiring intact (every provider above) ✓ · widget tests green ✓.
