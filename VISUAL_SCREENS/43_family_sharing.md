# 43 · Family Sharing — `/family`
Mode: **consumer** (premium) · Tab/Stack: **drill-down** (from Profile → "Family sharing", §34) · Gate: **paid** (premium consumer entitlement)

> Governed by `.kiro/steering/visual-assets.md` (the Bible) + `CHARACTER_STORYTELLING_BIBLE.md`
> (Mor). Tokens, motion, image-gen blocks (§6.1/§6.2), Scroll Grammar (§5) are **cited, not
> repeated**. Quality bar: **beat the reference mockup.** Honest-data law: render only what
> `GET /family/members` returns; respect the **5-member backend limit** exactly (BE-36).

---

## Story arc
**Human beat** (warm header — *"Share RADHA with your family"*, Mor + a small cluster of warm
member avatars) → **Substance** (entitlement state → member list with status chips → seats-left
counter) → **Action** (one orange "Invite a member" CTA, disabled at the 5-member ceiling).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| Member list | `familyMembersProvider` / `GET /family/members` | subscriptions BE-36 | Rows: `id`, `memberMobile`/`memberName?`, `status` ('invited'\|'accepted'), `invitedAt`, `acceptedAt?`. Show mobile or token; never fabricate a name. |
| Invite | `POST /family/invite` { mobile } | subscriptions BE-36 | 10-digit IN mobile (optionally +91). **5-member limit** → 409; surface as inline "Family is full (5/5)". |
| Accept (invited user side) | `POST /family/accept` { inviteId } | subscriptions BE-36 | Reached via deep-link/notification on the *invitee's* device — see S3. |
| Remove member | `DELETE /family/members/:id` | subscriptions BE-36 | Owner/manager/admin only; destructive confirm (S2). 204 on success. |
| Entitlement gate | `premiumConsumerProvider` / `GET /subscriptions/status` | subscriptions BE-36 | If not premium → render **locked overlay** (§3.19) over the real layout, CTA → `38_subscription`. |

**Limit is law:** the backend enforces ≤5 active members. The UI mirrors it: a live **"3 of 5
seats used"** counter, and the Invite CTA disables (not hides) at 5 with an explanatory line.

---

## Scroll zones (top → bottom)

### Z-HERO — Family header band  *(~168 dp)*
- **Layout:** warm band cream→`#FFF3E6`; back chevron; title **"Family sharing"** `headlineMedium`
  `w800`; sub "Share your RADHA premium with up to 5 people." `bodyMedium` ink-soft. Right side: a
  small **warm illustrated cluster** — **Mor `greet`** beside 2–3 monogram member avatars
  (accent-tint circles, hairline ring) — the human beat.
- **Tokens:** padding `space16` H; title→sub gap `space8`; band radius bottom `xl`.
- **Motion:** band parallax ~0.5×; Mor + avatars fade-up stagger 40 ms; reduced-motion → static.
- **A11y:** title header semantics; illustrated cluster `excludeSemantics`.
- **States:** loading → title + sub skeleton.

### Z1 — Seats counter + plan strip  *(eyebrow: "YOUR FAMILY PLAN")*
- **Layout:** one raised `radius.lg` card, hairline: left — **mono** "3 of 5" big `displaySmall`
  in `#EA580C` + "seats used" label ink-soft; right — a 5-pip seat meter (filled pips orange,
  empty pips hairline). Below: plan name chip ("Premium · Family") accent-tint.
- **Tokens:** card raised `#FFFFFF`, warm shadow elev-1; pips 10 dp, gap `space4`.
- **Motion:** pips fill left→right stagger 60 ms on reveal; the mono count counts up 0→used.
- **A11y:** "3 of 5 seats used" one semantics; meter `excludeSemantics` (count already announced).
- **States:** at 5/5 → meter full, label "Family is full"; loading → skeleton pips.

### Z2 — Members list  *(eyebrow: "MEMBERS")*
- **Layout:** vertical list of **member rows**, hairline-divided:
  - **Leading:** circular monogram avatar (accent-tint, hairline ring) — initial from name or "?".
  - **Body:** name **or** masked mobile (e.g. "+91 98••• ••210") `titleMedium` `w600`; sub =
    **status chip** (§3.9): *accepted* → Success `#15803D` "Active" check · *invited* → Warn
    `#B45309` "Invite sent" clock.
  - **Trailing:** mono `invitedAt`/`acceptedAt` short date; overflow `⋮` → remove (owner only).
  - First row = **"You" (primary)** with an orange "Owner" chip; never removable.
- **Tokens:** row 64 dp, avatar 40 dp; chip tint bg 8 % + tint border 35 %.
- **Motion:** rows fade-up stagger 40 ms; remove → row collapses (height+opacity, 200 ms); press-scale.
- **A11y:** row = "Riya, active member, joined 12 Aug" / "+91…210, invite sent"; overflow labeled.
- **States:** loading → 3 skeleton rows; only-you → see Z-EMPTY; pending invites visually distinct
  (warn chip + faint dashed avatar ring).

### Z3 — Invite action  *(pinned / Z-FAB)*
- **Layout:** full-width orange **"Invite a member"** primary button (§3.15) pinned above the home
  indicator (or inline below the list on short content). Helper line under it: live "2 seats left".
- **Tap →** S1 invite sheet.
- **Tokens:** primary `#EA580C`, `radius.full`/`lg`, `w700` white label.
- **States:** **disabled (0.38)** at 5/5 with line "Family is full — remove a member to invite
  someone new."; **locked** (not premium) → whole screen behind locked overlay (Z-LOCK).

### Z-LOCK — Locked overlay (when not premium, §3.19)
- The real Z1–Z3 layout renders behind a tasteful blur/scrim + **Mor `guard`** + lock glyph;
  card title "Family sharing is a Premium feature", body "Share RADHA with up to 5 people on one
  plan.", orange "See plans" → `38_subscription`. Never a blank wall — show the value behind glass.

### Z-EMPTY — Only you yet
- **Mor `greet`** (104 dp), title "Bring your family in", line "Invite up to 5 people to share
  your RADHA premium — allergen profiles, saved lists and reminders, together.", orange "Invite a
  member" → S1. *Second-read moment.*

### Z-NAV
None — drill-down. Back chevron returns to Profile; bottom nav hidden.

---

## Sub-surfaces
- **S1 · Invite sheet** — bottom sheet `xl`, drag handle: title "Invite a family member", a single
  **mobile input** (mono, +91 prefix chip, 10-digit validation, orange focus ring, inline danger
  on invalid), helper "They'll get an SMS/notification to accept." Primary orange "Send invite"
  (calls `POST /family/invite`). Success → toast "Invite sent" + sheet closes + new pending row
  animates in. 409 (limit) → inline "Family is full (5/5)."; spring enter.
- **S2 · Remove confirm dialog** — centered dialog, scrim, `0.95→1`+opacity: "Remove {name}?",
  body "They'll lose access to your shared premium.", danger "Remove" + ghost "Cancel". Calls
  `DELETE /family/members/:id`.
- **S3 · Accept-invite surface (invitee device)** — reached from a notification/deep-link: a warm
  card "Priya invited you to her RADHA family" + **Mor `greet`** + orange "Accept" (calls `POST
  /family/accept`). Expired/used invite → **Mor `concern`** + "This invite has expired."

---

## State gallery (generate a mockup for each)
`default (mix of active + pending, 3/5)` · `full (5/5, invite disabled)` · `only-you (empty, Mor
greet)` · `locked (not premium, Mor guard)` · `invite sheet` · `remove confirm` · `accept-invite`
· `loading (skeletons)` · `error (Mor concern + retry)`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Family Sharing mockup (default)** | `generate_ui_mockup` | `assets/v2/mockup/family-sharing.png` | SCREEN: Family sharing (/family). STORY: warm header with peacock mascot + member avatars → "3 of 5 seats used" card with a 5-pip orange seat meter → MEMBERS list (You · Owner chip; Riya · Active green chip; +91 98•••210 · Invite sent amber chip) → full-width orange "Invite a member" with "2 seats left". FOCAL: the seats counter + invite CTA. COPY (verbatim): "Family sharing", "Share your RADHA premium with up to 5 people.", "3 of 5", "seats used", "Owner", "Active", "Invite sent", "Invite a member", "2 seats left". Real product cutouts: no. Motion-implied: pip fill stagger, count-up, fade-up rows. |
| A1 | Locked-overlay mockup | `generate_ui_mockup` | `assets/v2/mockup/family-sharing-locked.png` | The same family layout behind a tasteful soft blur + scrim, a guard-pose peacock mascot + lock glyph, card "Family sharing is a Premium feature" + orange "See plans". Value visible behind glass — never a blank upgrade wall. |
| A2 | Invite sheet mockup | `generate_ui_mockup` | `assets/v2/mockup/family-invite-sheet.png` | Bottom sheet: "Invite a family member", +91 mobile input (mono) with orange focus ring, helper "They'll get an SMS/notification to accept.", orange "Send invite". Same RADHA system. |
| A3 | Family seat-meter spot illustration | `generate_image` | `assets/v2/illustration/spot-family.png` | Small warm card-friendly illustration: a cluster of 3–4 simplified warm member silhouettes/avatars around a shared RADHA premium emblem, burnt-orange + cream + terracotta, soft depth, muted (not glossy). Card-sized, leaves room for text. |

> **Mor reuse:** `greet` / `guard` / `concern` frames exist under `assets/v2/character/mor/static/`
> — reference, don't regenerate. Only A0–A3 are new renders.

---

## Motion checklist (Emil) — reduced-motion safe
header parallax ✓ · seat-pip fill stagger + count-up ✓ · member rows fade-up stagger ✓ · remove
collapse ✓ · invite sheet spring-in ✓ · press-scale 0.97 + haptic ✓ · locked-overlay blur fade ✓ ·
Mor breathing → static under `MediaQuery.disableAnimations` ✓.

## Accessibility checklist
header semantics ✓ · seats announced as text not just pips ✓ · each member row labeled w/ status ✓ ·
invite input labeled + inline error read ✓ · disabled-at-5 explained in text ✓ · ≥48 dp targets ✓ ·
status conveyed by chip text + icon, not color alone ✓ · 2.0× text-scale no clip ✓ · decorative
illustration excluded ✓.

## Anti-slop gate
one orange focal (seats + CTA) ✓ · status chips use AA tints, not neon ✓ · no nested cards ✓ ·
locked state shows value behind glass, not a wall ✓ · honest: masks mobile, never invents names,
mirrors the 5-seat backend ceiling ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/skeleton/locked present ✓ ·
slop gate ✓ · wiring intact (every provider above) ✓ · 5-member limit honored ✓ · widget tests green ✓.
