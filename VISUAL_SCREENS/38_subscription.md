# 38 · Subscription — `/subscription`
Mode: **both** · Tab/Stack: **drill-down from Profile** · Gate: none

> The paywall screen that must earn the upgrade, not beg for it. Show value, not pressure.
> Real plan names, real prices, real feature lists. Governed by the Bible.

---

## Story arc
**Human beat** (here's where you are — your current plan) →
**Substance** (plan comparison table — what you get at each tier) →
**Action** (one clear orange upgrade CTA per plan card).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| Current subscription | `GET /subscription/status` | subscriptions |
| Plan list | `GET /subscription/plans` | subscriptions |
| Create order | `POST /subscription/create-order` | subscriptions |
| Verify payment | `POST /subscription/verify-payment` | subscriptions |

---

## Scroll zones (top → bottom)

### Z-HERO — Subscription header *(~80 dp)*
- Back chevron + "Choose Your Plan" `headlineMedium` `w800` ink.
- If already on paid plan: "Manage Subscription" with current plan badge.

### Z1 — Current plan banner *(if active paid plan)*
- Raised warm card: "You're on Standard Plan ✓" in green, renew date mono, "Cancel" text link.

### Z2 — Plan cards *(vertical stack of 3–4 cards)*
- **Free Trial card** (greyed out if expired, active if in trial): "Free Trial · 3 months" title.
  Feature list: basic scan, basic expiry, 1 store. Trial days remaining pill.
- **Basic ₹49/mo card**: feature list with checkmarks (green ✓) — scans, expiry, tasks. Orange
  "Upgrade to Basic" CTA (full-width `radius.full`). Inactive if current plan ≥ this.
- **Standard ₹99/mo card** *(recommended — highlighted with a "Most Popular" eyebrow badge in
  accent-deep)*: full feature list + inventory + GRN + reports. Orange CTA.
- **Premium ₹199/mo card**: everything + AI features + OHS + allergen + family sharing + weekly
  digest. Gold `#F59E0B` "Popular choice" badge. Orange CTA.
- Each card: `radius.xl`, raised `#FFFFFF`, warm shadow. Active/current plan card gets an orange
  `#EA580C` border. Price in `displaySmall` mono ink. Features list `bodySmall` ink with ✓ / ✗.
- **Tokens:** card `radius.xl`; price `displaySmall` mono; CTA `radius.full` orange full-width;
  "Most Popular" badge accent-deep pill top-right.

### Z3 — Trust + FAQ *(collapsed accordion)*
- "🔒 Secure payment via Razorpay" bodySmall ink-soft. "Cancel anytime." "Questions? →".
- 2 FAQ rows (collapsible): "How does billing work?", "Can I switch plans?".

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| G0 | Full Subscription mockup | `generate_ui_mockup` | `assets/mockup/subscription.png` | Subscription screen. Z-HERO: "Choose Your Plan" headlineMedium w800 back arrow. Z1: green "You're on Free Trial · 22 days remaining" banner card. Z2: three plan cards stacked vertically. Basic ₹49/mo card: white raised, feature list with green checkmarks, orange "Upgrade to Basic" full-width button. Standard ₹99/mo card (center, highlighted): has a burnt-orange border, "MOST POPULAR" pill badge top-right in accent-deep, feature list longer, orange "Upgrade to Standard" button, price ₹99 in displaySmall mono prominent. Premium ₹199/mo card: "BEST VALUE" badge in marigold #F59E0B, fullest feature list, orange "Upgrade to Premium" button. Z3: "Secure payment via Razorpay" trust row + "Cancel anytime" + FAQ rows. Warm cream #FFFBF5 canvas, cards #FFFFFF, orange #EA580C borders and CTAs, green #15803D checkmarks. iPhone 15. Plus Jakarta Sans + JetBrains Mono. No watermarks. |

---

## Done gate
mockup beaten ✓ · real prices shown ✓ · current plan highlighted ✓ · one CTA per card ✓ · trust signals present ✓.
