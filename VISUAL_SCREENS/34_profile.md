# 34 · Profile — `/profile`
Mode: **both** · Tab/Stack: **root tab 5 of 5** · Gate: none

> The personal hub — who you are, your store, your plan, your settings. Must feel warm and
> personal, not bureaucratic. Governed by the Bible.

---

## Story arc
**Human beat** (your name, your role, your store — you're in control) →
**Substance** (account info + subscription status + quick settings + support) →
**Action** (manage subscription / switch language / logout).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| User info | `GET /auth/me` | auth |
| Subscription status | `GET /subscription/status` | subscriptions |
| Store details | `GET /stores/{id}` | stores |

---

## Scroll zones (top → bottom)

### Z-HERO — Profile hero band *(~160 dp)*
- **Layout:** warm cream band. Large **avatar** (72 dp circular, hairline ring `#EA580C`, warm
  monogram on accent-tint bg if no photo). Name `headlineMedium` `w800` ink. Role chip pill
  (e.g. "Manager") in accent-tint `#FED7AA` + accent-deep text. Store name `bodyMedium` ink-soft.
- **Tokens:** avatar 72 dp `radius.full`; name `w800`; role chip `radius.full`; `space16` H.
- **Motion:** avatar + name fade-up stagger 40 ms on cold start.

### Z1 — Subscription card *(eyebrow: "YOUR PLAN")*
- **Layout:** raised `#FFFFFF` card `radius.lg`. Plan name `titleLarge` `w700` (e.g. "Standard
  Plan"). Billing period `bodySmall` mono ink-soft "Renews 15 Jul 2026". Days-remaining pill
  (orange if trial, green if active). Orange "Manage plan" CTA → `38_subscription`.
- **Tokens:** card raised, hairline, warm shadow; plan name ink; CTA `radius.full` orange.

### Z2 — Settings sections *(grouped list rows)*
- **Layout:** two grouped sections with `space24` gap between.
  - **"ACCOUNT"** group: "Edit profile", "Change mobile", "Language" (trailing current locale
    "EN"), "Notifications", "Family sharing".
  - **"STORE"** group: "Store details", "Manage team", "Verified badge" (trailing lock if unpaid).
- Each row: leading glyph in accent-tint well + label `bodyLarge` ink + trailing chevron.
  "Language" row has a trailing current-locale badge.
- **Tokens:** row 56 dp, glyph well 36 dp `radius.md`, `space16` H; hairline dividers within group.

### Z3 — Support & legal *(small rows)*
- "Help & support" → `37_support`. "Privacy policy". "Terms of service". "Rate RADHA ★".
- Rows 48 dp, no leading glyph, chevron only.

### Z4 — Logout *(danger zone)*
- "Log out" row: danger `#B91C1C` text, no chevron, tap → confirm dialog.
- App version `bodySmall` mono ink-soft centered below.

### Z-NAV — Bottom navigation (§3.12)
Home · Scan · Expiry · Tasks · **Profile (active orange)**.

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| F0 | Full Profile mockup | `generate_ui_mockup` | `assets/mockup/profile.png` | Profile screen. Z-HERO: warm cream band, large 72dp circular avatar with orange ring showing "PR" warm monogram on accent-tint background, "Priya Sharma" headlineMedium w800, "Manager" role chip in accent-tint, "Priya General Store" bodyMedium ink-soft. Z1: "YOUR PLAN" eyebrow, raised white card "Standard Plan" titleLarge w700, "Renews 15 Jul 2026" mono ink-soft, a green "Active" pill, orange "Manage plan" button. Z2: two grouped sections "ACCOUNT" (Edit profile, Change mobile, Language "EN", Notifications, Family sharing) and "STORE" (Store details, Manage team, Verified badge with lock) — each row has a small warm tinted icon well + label + chevron. Z3: support rows. Z4: "Log out" in danger red. App version "v1.2.0" centered. Profile tab active in nav. Warm cream #FFFBF5, orange #EA580C, accent-tint #FED7AA, ink #1C1917. iPhone 15. Plus Jakarta Sans. No watermarks. |

---

## Done gate
mockup beaten ✓ · role chip real data ✓ · subscription status honest ✓ · logout confirm present ✓.
