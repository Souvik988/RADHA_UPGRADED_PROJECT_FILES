# 11 · Expiry List — `/expiry`
Mode: **business** · Tab/Stack: **root tab 3 of 5** · Gate: none

> The expiry screen is the store owner's most anxious surface — it carries real financial stakes.
> The design must communicate urgency without panic: organized, scannable, action-ready.
> Governed by the Bible.

---

## Story arc
**Human beat** (how many items need attention today?) →
**Substance** (sorted, filterable list with status-coded rows) →
**Action** (tap to mark done, swipe to add batch, FAB to add new).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| Near-expiry list | `GET /expiry?status=near&storeId=&cursor=` | expiry |
| Expired list | `GET /expiry?status=expired&storeId=&cursor=` | expiry |
| Safe list | `GET /expiry?status=safe&storeId=&cursor=` | expiry |
| Create expiry | `POST /expiry` | expiry |
| Update expiry record | `PATCH /expiry/{id}` | expiry |
| Calendar view | `GET /expiry/calendar?month=` | expiry BE-38 |

---

## Scroll zones (top → bottom)

### Z-HERO — Expiry header band *(~120 dp)*
- **Layout:** styled header — warm cream `#FFFBF5` band. Left: "Expiry Tracker" `headlineMedium`
  `w800` ink. Right: calendar icon → `15_expiry_calendar`, add icon → `14_expiry_create`.
- **Summary strip:** 3 inline stat chips — "18 Near-expiry" amber `#B45309`, "4 Expired" danger
  `#B91C1C`, "126 Safe" success `#15803D` — each a small pill with count + label. Tappable to
  filter.
- **Tokens:** band padding `space16` H; chips `radius.full`, 8% tint bg, tint border; gap `space8`.
- **Motion:** chips count-up on first reveal; press-scale `0.97`.
- **A11y:** each chip `Semantics` reads "18 near-expiry items, tap to filter".

### Z1 — Filter tabs *(sticky on scroll)*
- **Layout:** segmented control (§3.11) with 3 segments: "Near-expiry · 18", "Expired · 4",
  "Safe · 126". Orange sliding indicator. Sticks below the header when scrolled.
- **Tokens:** `radius.full` pill tabs, orange indicator, `space16` H margin.
- **Motion:** indicator slides on tab change (200 ms easeOut transform).

### Z2 — Expiry item list *(cursor-paginated)*
- **Layout:** vertical list of **expiry rows** (§3.8 row variant):
  - Left: product thumb (44 dp `md` `#F5F1E8` well, licensed cutout).
  - Center: product name `titleMedium` `w600`; brand + batch `bodySmall` ink-soft; location chip.
  - Right: expiry date in **JetBrains Mono** `labelLarge` colored by status (amber near / red
    expired / green safe); quantity badge `bodySmall` mono ink-soft below date.
  - Far right: status dot 8 dp (amber/red/green).
- **Status pills** (on expired rows only): a small "EXPIRED" danger pill replaces the date color.
- **Swipe-left:** reveals "Edit" (accent-deep) + "Remove" (danger) quick actions.
- **Swipe-right:** reveals "Mark cleared" (success green) quick action.
- **Pull-to-refresh:** custom orange RADHA indicator.
- **Pagination:** auto-loads next page when scrolled within 200 dp of list bottom.
- **Tokens:** row 72 dp, hairline dividers, thumb `md` radius; date `monoLabel`; `space16` H.
- **Motion:** row press-scale; swipe spring; new rows fade-in from bottom on load.
- **A11y:** each row announces "Parle-G Biscuits 200g, expires in 2 days, 12 units, near-expiry".

### Z-FAB — Add expiry
- Orange FAB, `+` icon, `radius.full`, bottom-right, 16 dp from edge + safe-area. Routes to
  `14_expiry_create`. Press-scale `0.95→1.0`, haptic medium.

### Z-NAV — Bottom navigation (§3.12)
Home · Scan · **Expiry (active orange)** · Tasks · Profile.

---

## Sub-surfaces
- **S1 · Sort/filter sheet** — tapped from header or long-press filter tab. Options: sort by date
  asc/desc, filter by category, filter by location. Orange "Apply" CTA.
- **S2 · Row action confirm** — "Are you sure you want to remove this expiry record?" dialog.
- **S3 · Batch actions bar** — multi-select mode: checkboxes appear on long-press, a bottom action
  bar slides up with "Mark cleared", "Delete selected", count badge.

---

## State gallery
`default (near-expiry tab)` · `expired tab` · `safe tab` · `empty (all clear)` · `loading` · `offline`.

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| D0 | Full Expiry List mockup | `generate_ui_mockup` | `assets/mockup/expiry-list.png` | Expiry List screen. Z-HERO: "Expiry Tracker" title w800, 3 stat chips "18 Near-expiry (amber), 4 Expired (red), 126 Safe (green)". Z1: segmented tabs "Near-expiry · 18 / Expired · 4 / Safe · 126" with orange active indicator on Near-expiry. Z2: list of 5 expiry rows — each row has product thumb, name, brand, expiry date in JetBrains Mono amber/red, quantity, status dot. Top row "Parle-G Biscuits 200g EXP 14 Jun 2026 12 units amber", second "Pepsi 2L EXP 10 Jun 2026 8 units red EXPIRED", etc. Orange FAB bottom-right. 5-tab nav, Expiry active. Warm cream #FFFBF5 canvas, white cards, amber #B45309, danger #B91C1C, orange #EA580C. Plus Jakarta Sans + JetBrains Mono. iPhone 15. |
| D1 | Expiry empty + expired tab states | `generate_ui_mockup` | `assets/mockup/expiry-states.png` | Two panels: LEFT = all-clear empty state on "Near-expiry" tab: a warm calendar illustration with a green checkmark, "All clear!" title w700, "No items expiring soon" subtitle ink-soft, orange "Add expiry record" CTA. RIGHT = "Expired" tab with 3 red expired rows, each showing "EXPIRED" danger pill, swipe-left revealed "Edit + Remove" actions visible on the bottom row. iPhone 15, warm cream palette. |

---

## Motion checklist (Emil)
stat chips count-up ✓ · filter tab indicator slide ✓ · row swipe spring ✓ · FAB press-scale ✓ ·
pagination fade-in ✓ · pull-to-refresh orange ✓ · reduced-motion: all static ✓.

## Accessibility checklist
stat chips labeled with tap-to-filter ✓ · rows full sentence semantics ✓ · swipe actions labeled ✓ ·
FAB labeled "Add expiry record" ✓ · filter tabs keyboard navigable ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion ✓ · empty/expired/safe states present ✓ · wiring intact ✓.
