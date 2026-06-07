# 43 · Family Sharing — ChatGPT prompts

> Full spec: `VISUAL_SCREENS/43_family_sharing.md`. Run these in the SAME ChatGPT chat as
> `00_PRIMER.md` + `01_brand_icons_backgrounds.md` + `MOR_ASSET_KIT.md`. One generation per block.
> Honor the **5-seat backend ceiling** (BE-36) in every render. No rewards/points/coins.
>
> ✅ `F0` already generated via the bridge → `assets/v2/mockup/family-sharing.png`. Run `F1`–`F3` here.

---

## F0 · Family Sharing — DEFAULT  → `assets/v2/mockup/family-sharing.png`  *(done — bridge)*
```
RADHA — Family sharing screen (consumer premium), DEFAULT state, full screen inside the clean iPhone 15
mockup, per the RADHA locked system. Top → bottom, ONE orange focal region (seats card + invite CTA):
• HEADER BAND on a cream→#FFF3E6 wash: back chevron; title "Family sharing" w800; sub "Share your
  RADHA premium with up to 5 people." in ink-soft; on the right a small peacock mascot (Mor, greet)
  beside 2–3 round monogram member avatars (accent-tint #FED7AA circles, hairline ring).
• SEATS CARD — one raised white card: a big JetBrains-Mono "3 of 5" in orange #EA580C + "seats used"
  label; a 5-pip seat meter (3 filled orange pips, 2 empty hairline pips); a small "Premium · Family"
  accent-tint chip.
• MEMBERS list (hairline-divided rows): "You" with an orange "Owner" chip; "Riya" with a green
  #15803D "Active" check chip + mono join date; "+91 98••• ••210" with an amber #B45309 "Invite sent"
  clock chip (faint dashed avatar ring); each row a monogram avatar + overflow ⋮.
• A full-width orange "Invite a member" button pinned near the bottom with a helper line "2 seats left".
Warm, premium, readable, custom rounded glyphs. No rewards/coins. Portrait 1024×1536.
Save → assets/v2/mockup/family-sharing.png
```

## F1 · Family Sharing — LOCKED (not premium)  → `assets/v2/mockup/family-sharing-locked.png`
```
RADHA Family sharing — LOCKED state: render the SAME family layout (seats card, members, invite CTA)
behind a tasteful soft blur + a warm scrim, with a centered card on top: a guard-pose peacock mascot
(Mor) + a lock glyph, title "Family sharing is a Premium feature", line "Share RADHA with up to 5
people on one plan.", and an orange "See plans" pill. Show the value behind glass — never a blank
upgrade wall. Portrait 1024×1536.
Save → assets/v2/mockup/family-sharing-locked.png
```

## F2 · Family Sharing — INVITE sheet  → `assets/v2/mockup/family-invite-sheet.png`
```
RADHA Family sharing — INVITE bottom sheet rising over the dimmed list, rounded xl top corners + drag
handle. Title "Invite a family member". A single mobile-number input with a "+91" prefix chip, shown
in JetBrains-Mono, with an orange #EA580C focus ring; helper line "They'll get an SMS/notification to
accept."; a full-width orange "Send invite" button. Warm cream sheet, hairline, readable. Portrait
1024×1536.
Save → assets/v2/mockup/family-invite-sheet.png
```

## F3 · Family Sharing — EMPTY (only you)  → `assets/v2/mockup/family-sharing-empty.png`
```
RADHA Family sharing — EMPTY state (only the owner so far): same header, but the body is a designed
empty state with personality: a greet-pose peacock mascot (Mor, ~104dp), a w700 title "Bring your
family in", a supportive ink-soft line "Invite up to 5 people to share your RADHA premium — allergen
profiles, saved lists and reminders, together.", and an orange "Invite a member" pill. The seats card
reads "0 of 5 · seats used" with an empty pip meter. Portrait 1024×1536.
Save → assets/v2/mockup/family-sharing-empty.png
```

---
**Tip:** keep the seat-pip meter and the chip styles identical across F0–F3.
