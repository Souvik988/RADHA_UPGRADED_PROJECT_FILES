# 42 · Notifications — ChatGPT prompts

> Full spec: `VISUAL_SCREENS/42_notifications.md`. Run these in the SAME ChatGPT chat as
> `00_PRIMER.md` + `01_brand_icons_backgrounds.md` + `MOR_ASSET_KIT.md` so this screen inherits the
> locked identity, the icon family, and Mor. One generation per block.
>
> ✅ `N0` was already generated via the bridge → `assets/v2/mockup/notifications.png`. Run `N1`–`N3`
> here to complete the set (kept token-light to avoid the bridge's long-render timeouts).

---

## N0 · Notifications — DEFAULT  → `assets/v2/mockup/notifications.png`  *(done — bridge)*
```
RADHA — Notifications screen, DEFAULT state, full screen inside the clean iPhone 15 mockup, per the
RADHA locked system. Top → bottom, content-heavy but breathing, ONE orange accent region (the
segmented control + unread dots):
• SLIM HEADER BAND on a cream→#FFF3E6 wash: a back chevron; title "Notifications" w800 ink #1C1917;
  a trailing "Mark all read" text button in accent-deep #9A3412; a small warm peacock mascot (Mor,
  greet pose) to the right of the title; sub line "Here's what moved while you were away." in ink-soft.
• SEGMENTED CONTROL — "Unread · All" pill with a sliding orange #EA580C indicator on the active segment;
  a small settings gear glyph at the right.
• NOTIFICATION LIST grouped under small ink-soft day eyebrows "TODAY" / "YESTERDAY", rows divided by
  #E7E1D4 hairlines. Each row: a tinted category-glyph well (clock=amber #B45309, clipboard=orange
  #EA580C, truck=green #15803D, alert-triangle=danger #B91C1C), a w600 title + a 2-line ink-soft body,
  a JetBrains-Mono relative time, and an orange unread dot for unread rows (which carry a faint #FED7AA
  left wash). Rows: "Task due · Check dairy fridge temps · 2h" (unread), "GRN received · 2 invoices
  posted to stock · 5h" (unread), "Expiring soon · 18 items before Friday · Yesterday" (read),
  "Recall alert · Batch check needed · 12 Aug" (read).
Warm, premium, readable, custom rounded glyphs. Portrait 1024×1536.
Save → assets/v2/mockup/notifications.png
```

## N1 · Notifications — EMPTY "all caught up"  → `assets/v2/mockup/notifications-empty.png`
```
RADHA Notifications — EMPTY unread state, same header + segmented control (Unread active), but the
list area is a designed empty state with personality: the peacock mascot Mor in a calm RESTING (sleep)
pose on a soft sunken #F5F1E8 backer, a w700 ink title "You're all caught up", and one ink-soft line
"No new notifications. Mor's keeping watch." No CTA — calm and quiet. "Mark all read" is disabled.
Portrait 1024×1536.
Save → assets/v2/mockup/notifications-empty.png
```

## N2 · Notifications — PREFERENCES sheet  → `assets/v2/mockup/notifications-prefs.png`
```
RADHA Notifications — PREFERENCES bottom sheet rising over a dimmed list, rounded xl top corners with a
drag handle. Title "Notification settings". A list of toggle rows with orange #EA580C switches: "Push
notifications" (on), "Expiry alerts" (on), "Tasks" (on), "GRN" (on), "Recall alerts" (on), "Store
health" (off), "Weekly digest" (on). A small thinking-pose peacock mascot (Mor) at the top endorsing
the controls. Warm cream sheet, hairline dividers, readable. Portrait 1024×1536.
Save → assets/v2/mockup/notifications-prefs.png
```

## N3 · Notifications — ERROR  → `assets/v2/mockup/notifications-error.png`
```
RADHA Notifications — ERROR state, same header, but the list area is a designed error state: the
peacock mascot Mor in a CONCERN pose with a danger-tinted icon badge, a w700 title "Couldn't load
notifications.", a supportive ink-soft line, and an orange "Retry" pill. Warm, never a raw red error.
Portrait 1024×1536.
Save → assets/v2/mockup/notifications-error.png
```

---
**Tip:** keep this chat open; the day-grouped row rhythm and the tinted category-glyph wells should
match exactly across N0–N3.
