# Pages — full-page mockup queue (RADHA mobile app)

When the user says **"generate next N pages"** or **"generate next batch"**, the agent processes the first N unchecked items in the list below, calls `generate_ui_mockup` with `enhance_prompt: true` for each (one tool call per page, sequentially — never in parallel), saves each output under `assets/mockup/{page-slug}.png`, ticks the item off in this file, and stops. The agent does not re-order, skip, or batch beyond N. If a generation fails, the agent reports the failure for that one page and continues the rest of the batch.

Every brief must follow `.kiro/steering/visual-assets.md`: 200–600 chars, concrete style anchors, exact hex (`#EA580C` accent on `#FFFBF5` canvas with `#1C1917` ink), Plus Jakarta Sans + JetBrains Mono, mandatory negative anchors, iPhone 15 portrait frame `393×852`. Briefs below are seed-only — the agent expands them to ~400 chars before calling the bridge.

---

## Pre-auth + onboarding (5)

- [ ] **Splash** — `/splash` — RADHA wordmark on warm cream `#FFFBF5`, single accent dot in `#EA580C`, faint product-bar-code watermark in `#FED7AA` at 8% opacity, brand subline in JetBrains Mono.
- [ ] **Onboarding 1 / segments** — `/onboarding` (page 1 of 3) — six-segment grid (personal, business owner, parent, pharmacy, institution, auditor), 2×3 layout, each tile a clean line illustration with one orange dot, top headline + skip link.
- [ ] **Onboarding 2 / value-prop** — `/onboarding` (page 2 of 3) — left-aligned hero illustration of a hand scanning a product, three-line claim, page indicator dots.
- [ ] **Onboarding 3 / consent** — `/onboarding` (page 3 of 3) — consent toggles for notifications + camera, primary orange CTA "Let's go".
- [ ] **OTP request** — `/auth/otp` — Indian mobile-number input with `+91` chip, large primary CTA "Send OTP", secondary "Use email" link, footer T&C in caption ink-soft.

## Auth follow-up (2)

- [ ] **OTP verify** — `/auth/otp/verify` — six-box OTP input, 60s resend timer, mobile number echo above, paste hint, error pill state shown faded for visual reference.
- [ ] **Select store** — `/select-store` — list of 3 mock stores with address subtitle, leading orange dot for currently active, primary CTA "Continue", secondary "Add new store" link.

## Bottom-nav core (5)

- [ ] **Home** — `/home` — greeting block ("Good morning, Sayan"), store-picker chip top-right, three KPI tiles in a 2-row bento (today's scans / expiring soon / low stock — KPI numbers in JetBrains Mono), one wide accent CTA card "Scan a product", recent-tasks list of three rows, bottom nav.
- [ ] **Scan** — `/scan` — full-screen camera viewfinder with rounded-rect EAN frame, single orange corner brackets, hint pill "Hold steady" centred below, torch button bottom-left, manual-entry button bottom-right, brand chip top-left.
- [ ] **Expiry list** — `/expiry` — segmented control (All / Expiring soon / Expired), search bar, list of 5 product rows with thumb, name, days-to-expire chip in warn `#B45309`, FAB in `#EA580C`.
- [ ] **Tasks list** — `/tasks` — section headers Today / This week, three task cards each with assignee avatar stack, status chip, due-date in mono, FAB.
- [ ] **Profile** — `/profile` — user header with avatar + role chip, list rows for Stores, Subscription, Language, Help, Sign out — each a 56pt row with leading icon.

## Scan flow (1)

- [ ] **Scan result** — `/scan/result/:ean` — product hero card with image, name, brand, EAN in mono, then health-score gauge dial filling in `#EA580C`, ingredient list with severity chips, three CTAs (Save, Add to expiry, Find alternatives), recall banner space (hidden state shown).

## Expiry flow (3)

- [ ] **Expiry create** — `/expiry/new` — form: product picker, MFG date, EXP date, batch number, notes, OCR scan suggestion banner at top, primary CTA "Save expiry".
- [ ] **Expiry calendar** — `/expiry-calendar` — month grid with dots (orange = expiring this week, warn = next week), selected-day list at bottom, swipe-month chevrons in header.
- [ ] **Saved products** — `/saved-products` — list of bookmarked products, each card shows thumb / name / barcode mono / saved date, swipe-action removed shown, empty state preview with bookmark glyph.

## Tasks flow (2)

- [ ] **Task detail** — `/tasks/:id` — title large display, status chip, assignee row, due-date row, description body, comments thread (3 messages), bottom CTA "Mark complete" in orange.
- [ ] **Task create** — `/tasks/create` — form: title, description, assignee picker, store, due-date picker, priority chips, primary CTA.

## Inventory + GRN (6)

- [ ] **Inventory list** — `/inventory` — table-ish list with name / SKU mono / stock count / value in mono, sticky header, filter chips, FAB.
- [ ] **Stock movement** — `/inventory/stock-movement` — segmented (In / Out / Adjust), product picker, qty input, reason dropdown, primary CTA.
- [ ] **Low-stock alerts** — `/inventory/low-stock-alerts` — alert cards (3) each with product, current count vs threshold, "Reorder now" CTA chip.
- [ ] **GRN list** — `/grn` — list of supplier deliveries, status chips (pending / received / discrepancy), date in mono, FAB.
- [ ] **GRN create** — `/grn/create` — supplier picker, invoice number, date, photo-of-invoice card, primary CTA "Continue to items".
- [ ] **GRN items** — `/grn/:id/items` — line-item table with product / qty / batch / expiry, add-line FAB, footer total card.

## AI / consumer (3)

- [ ] **Ingredient explainer** — `/ingredients/:slug` — ingredient name large, plain-language explanation card, severity chip, "found in" product list with mini cards, locale switcher.
- [ ] **Healthy alternatives** — `/alternatives/:ean` — top "what you scanned" card, three alternative cards stacked, each with health-score gauge mini, single primary CTA per card "View".
- [ ] **Weekly digest** — `/digest` — week range header, three insight cards (most-scanned, expiring this week, score change), share button, archive link.

## Settings + support (4)

- [ ] **Settings hub** — `/settings` — sectioned list (Account, Preferences, Sync, About), each row 56pt with leading icon and trailing chevron.
- [ ] **Language picker** — `/settings/language` — radio list of 6 languages (English, Hindi, Bengali, Tamil, Telugu, Kannada) with native script preview.
- [ ] **Support** — `/support` — three-card grid (FAQ / Contact / Report a bug), search bar, footer with version + build mono.
- [ ] **Subscription** — `/subscription` — current plan card with renewal date, three plan tiles (₹49 / ₹99 / ₹199) with feature checklist, primary upgrade CTA in orange.

## Reports + dashboards (2)

- [ ] **Reports hub** — `/reports` — recent-reports list, "Generate new" primary CTA, scheduled-reports section preview, locked-feature overlay state shown faded for reference.
- [ ] **OHS dashboard** — `/ohs` — store header, big composite score gauge in `#EA580C`, four sub-metrics in a 2×2 bento, trend sparkline at bottom in mono.

## Other surfaces (3)

- [ ] **Recall alerts** — `/recall-alerts` — alert cards with severity stripe, product image, recall date mono, action CTA, empty state.
- [ ] **Allergen profile** — `/allergens` — family-member tabs at top, allergen tag chips below, add-allergen FAB.
- [ ] **Shopping list** — `/shopping-list` — checklist rows with qty stepper, segmented (To buy / Bought), share-to-WhatsApp icon button.
- [ ] **Referrals** — `/referrals` — invite-code card with copy button, share row, three reward tiers timeline.

## Backend-reconciliation pages (added after RADHA-CLIENT-OVERVIEW review — every shipped backend module gets a UI)

- [ ] **EAN audit / bulk-scan session** — `/scan-sessions` — staff audit flow: a running scan session with a live tally header (scanned / approved / unauthorized), a stream of scanned rows each with a green tick (on approved EAN list) or red cross, OCR-captured expiry chip, and an "End session" CTA. The "audit aisle 4" surface.
- [ ] **Business activation wizard** — `/business/activate` — multi-step upgrade-to-business flow: step header with linear progress, business-name + GST + store-type form, 14-day Pro trial benefit panel, primary "Start trial" CTA.
- [ ] **Verified badge** — `/verified-badge` — the RADHA Verified badge state screen: large verified seal, OHS eligibility meter (above 75 for 30 days), public verify URL with copy, downloadable PNG/SVG asset chips, revoked/at-risk state hinted.
- [ ] **Community barcode submission** — `/contribute` — submit a missing product: a captured packaging photo card, name/brand/category form, "submitted to moderation" status hint, daily-cap caption in mono.
- [ ] **Notifications inbox** — `/notifications` — chronological alert list: recall alerts, expiry reminders, weekly digest, day-7 push — each a row with a leading category glyph, title, time in mono, unread dot in #EA580C; section headers Today / Earlier; empty state.
- [ ] **Family sharing** — `/family` — manage up to 5 members: family member rows with avatars + role chips + remove, an "Invite member" row, a "3 of 5" mono counter, and a small note that the primary pays.
- [ ] **Payment checkout** — `/checkout` — UPI e-mandate checkout sheet: selected plan summary card with price in mono, UPI auto-pay mandate explainer, Razorpay-style pay button in #EA580C, secure-payment footer note.
- [ ] **Suppliers** — `/suppliers` — supplier directory feeding GRN: searchable list rows with supplier name, contact, last-delivery date in mono, a trailing chevron, and an "Add supplier" FAB.

---

## Component-level mockups

Component-level mockups are tracked in `COMPONENTS.md`. Generate components first when several pages depend on them (product card, scanner overlay, score gauge, bottom nav, segmented control, CTA, sheet, snackbar, empty state).

---

## Done log

Once a row is checked, leave it checked — do not delete it. The history of what was generated stays here so future batches don't accidentally re-mock a page.
