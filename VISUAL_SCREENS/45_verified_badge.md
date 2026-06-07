# 45 · RADHA Verified Badge — `/badges/me`
Mode: **business** (owner/manager) · Tab/Stack: **drill-down** (from Profile or OHS dashboard) · Gate: earned via **OHS score** (not a paywall — a *merit* gate)

> Governed by `.kiro/steering/visual-assets.md` (the Bible) + `CHARACTER_STORYTELLING_BIBLE.md`
> (Mor). Tokens, motion, image-gen blocks (§6.1/§6.2), Scroll Grammar (§5) are **cited, not
> repeated**. Quality bar: **beat the reference mockup.** Honest-data law: the badge state comes
> straight from `GET /badges/me` (`issued` / `revoked` / `none`) — never render a badge the
> backend hasn't issued.

---

## Story arc
**Human beat** (proud header — *"RADHA Verified"*, Mor `celebrate` presenting the badge like a
trophy when earned) → **Substance** (the badge artifact + status + the OHS score behind it + what
it means) → **Action** (share / copy the public verify link, or — if not yet earned — one orange
"Improve store health" CTA to the path that earns it).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| My badge | `myBadgeProvider` / `GET /badges/me` | verified-badge BE-52 | Returns `status` ('issued'\|'revoked'\|'none'), `issuedAt?`, `lastScore?`, `revokedAt?`, `reason?`, and `assets.png`/`assets.svg` (only when issued). Requires a tenant scope (403 otherwise). |
| Badge artwork | `assets.png` / `assets.svg` from response | verified-badge | Render the **server-issued** asset path; never a locally-faked badge graphic for an unissued tenant. |
| Public verify link | `GET /verify/:tenantSlug` (public, cached 1h) | verified-badge | The shareable proof URL; used by Share/Copy actions + the embeddable-link preview. |
| OHS context | `ohsSummaryProvider` / `GET /dashboard/ohs` | client-dashboard BE-30/BE-52 | Shows the score behind the badge + "assessment pending" honest state if no score yet. Tap → `48_ohs_dashboard`. |

**Three honest states, three designs:** `issued` (proud, shareable), `revoked` (respectful, shows
`reason` + how to regain), `none` (aspirational, shows the criteria). The screen never blurs these.

---

## Scroll zones (top → bottom)

### Z-HERO — Badge header band  *(~176 dp)*
- **Layout:** warm band cream→`#FFF3E6`; back chevron; eyebrow "TRUST & SAFETY" `labelMedium`
  accent-deep; title **"RADHA Verified"** `headlineMedium` `w800`. Right: **Mor** — `celebrate`
  when issued (presenting the badge), `work` when none (still on the job), `concern` when revoked.
- **Tokens:** padding `space16` H; eyebrow→title `space8`; band radius bottom `xl`.
- **Motion:** band fade + parallax; Mor reduced-motion → static.
- **A11y:** title header semantics; Mor `excludeSemantics`.

### Z1 — The badge artifact  *(the focal point — centered showpiece)*
- **Layout (issued):** the **server-issued badge** (`assets.png`) centered on a soft warm
  **spotlight halo** `#FFF3E6` in a raised `radius.xl` card; below it a **Success** status chip
  "Verified" (check-seal, `#15803D`) + mono **"Issued 14 Aug 2026"**. A faint ≤8 % marigold ring
  motif frames the halo (celebratory, integrated — not a slapped border).
- **Layout (none):** a **locked/ghost badge** silhouette (greyscale, dashed hairline ring) on the
  sunken `#F5F1E8` backer + Warn chip "Not yet earned"; the spotlight is dim. Honest — clearly
  *not* a real badge.
- **Layout (revoked):** the badge dimmed to 60 % + a Danger chip "Revoked" + mono `revokedAt` and
  the server `reason` (e.g. "OHS below 70 for 7 days") in ink-soft.
- **Tokens:** badge max ~200 dp; halo radial `#FFF3E6`; chips per §3.9 tints.
- **Motion:** on `issued` reveal — badge scales `0.95→1` + opacity + a **single** spotlight
  shimmer (≤800 ms, reduced-motion off); none/revoked → no shimmer (honest, not celebratory).
- **A11y:** badge `Semantics('RADHA Verified badge, issued 14 August 2026')`; ghost badge
  announced as "Not yet earned"; chip text carries state (not color alone).
- **States:** loading → badge-shaped skeleton on halo; 403 (no tenant) → "Verified badge is for
  business accounts" → `44_business_activation`.

### Z2 — Score behind the badge  *(eyebrow: "YOUR STORE HEALTH")*
- **Layout:** raised `radius.lg` card: a mini **OHS gauge** (§3.10, animated sweep) with mono
  `lastScore` center, label "Store health score", and the threshold line "Earn the badge at 70+".
  "View dashboard ›" → `48_ohs_dashboard`. If no score: gauge shows "–" + "Assessment pending".
- **Tokens:** gauge fill `#EA580C`; card raised, hairline, Cat-teal 8 % wash.
- **Motion:** gauge sweeps 0→score on reveal; reduced-motion → instant final.
- **A11y:** "Store health score 78 of 100, badge earned at 70" one semantics.
- **States:** issued → score ≥70 shown proudly; revoked → score shown with the gap to 70;
  none/pending → "–".

### Z3 — What it means  *(eyebrow: "WHY IT MATTERS")*
- **Layout:** 2–3 compact info rows (glyph + one line): "Shows customers your store passed RADHA's
  health & expiry checks", "A public link anyone can verify", "Refreshed automatically — stays
  honest". Custom warm glyphs, no nested cards.
- **States:** identical across badge states (it's explanatory).

### Z4 — Action zone
- **Issued:** primary orange **"Share badge"** (→ S1 share sheet with the public verify link +
  PNG) + secondary "Copy link". A small **embeddable preview** card shows how the badge looks on a
  storefront/site (using the public verify URL).
- **None:** primary orange **"Improve store health"** → `48_ohs_dashboard` (the real path that
  earns it); secondary "How it's calculated" → info sheet S2.
- **Revoked:** primary orange **"See what changed"** → `48_ohs_dashboard`; the `reason` is already
  shown in Z1.
- **States:** share disabled until `assets.png` present; copy → toast "Verify link copied".

### Z-NAV
None — drill-down. Back chevron returns to entry point; bottom nav hidden.

---

## Sub-surfaces
- **S1 · Share sheet** — native share with the **public verify URL** + the issued PNG; preview
  thumbnail + "Copy link" + WhatsApp quick-share (uses share_plus). Only available when issued.
- **S2 · "How it's calculated" sheet** — bottom sheet `xl`: plain-language OHS criteria + the 70+
  threshold + cadence; **Mor `think`** endorsing. Pulls copy from honest OHS docs, no fake numbers.
- **S3 · Public verify preview** — a faithful render of the `/verify/:tenantSlug` public page
  (tenant name, status, issuedAt) so the owner sees exactly what customers see. Read-only.

---

## State gallery (generate a mockup for each)
`issued (proud, shareable)` · `none (ghost badge, aspirational)` · `revoked (dimmed + reason)` ·
`assessment-pending (gauge "–")` · `loading (badge skeleton)` · `403 not-business` · `share sheet`
· `error (Mor concern + retry)` · `festive skin (optional — marigold ring on issued only)`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Verified Badge mockup (issued)** | `generate_ui_mockup` | `assets/v2/mockup/verified-badge.png` | SCREEN: RADHA Verified (/badges/me). STORY: proud "RADHA Verified" header with a celebrate-pose peacock mascot presenting the badge → the badge artifact centered on a warm spotlight halo with a green "Verified" chip + mono "Issued 14 Aug 2026" → "YOUR STORE HEALTH" mini OHS gauge (78, "Earn the badge at 70+") → "WHY IT MATTERS" rows → orange "Share badge" + "Copy link" + an embeddable storefront preview. FOCAL: the badge on its halo. COPY (verbatim): "TRUST & SAFETY", "RADHA Verified", "Verified", "Issued 14 Aug 2026", "Store health score", "Earn the badge at 70+", "Share badge", "Copy link". Real product cutouts: no. Motion-implied: badge scale-in + single shimmer, gauge sweep. |
| A1 | The RADHA Verified badge mark | `generate_logo` | `assets/v2/logo/radha-verified-badge.png` | A premium circular trust seal: "RADHA VERIFIED" around a peacock-feather + shield-check motif, burnt-orange #EA580C + cream + deep #9A3412, single confident mark, crisp at small sizes, NOT glossy, no gradients. (Design reference for the artifact RADHA's CDN issues; the live app renders the server PNG.) |
| A2 | None/ghost + revoked badge states mockup | `generate_ui_mockup` | `assets/v2/mockup/verified-badge-states.png` | Two-up (or sequential) states: (1) NOT-YET-EARNED — greyscale ghost badge silhouette with dashed ring on a sunken cream backer, amber "Not yet earned" chip, work-pose peacock, orange "Improve store health"; (2) REVOKED — badge dimmed 60% with a red "Revoked" chip + mono date + reason line "OHS below 70 for 7 days", concern-pose peacock. Honest, never showing a fake-issued badge. |
| A3 | Public verify preview mockup | `generate_ui_mockup` | `assets/v2/mockup/verified-badge-public.png` | The public /verify page as a customer sees it: tenant name, big green "Verified" status, "Issued 14 Aug 2026", "Verified by RADHA" footer, cache-friendly clean layout. Same RADHA warm system, web-leaning but on the phone mockup. |

> **Mor reuse:** `celebrate` / `work` / `concern` / `think` frames exist under
> `assets/v2/character/mor/static/` — reference, don't regenerate. Only A0–A3 are new renders.

---

## Motion checklist (Emil) — reduced-motion safe
header fade/parallax ✓ · **badge scale-in 0.95→1 + single spotlight shimmer (issued only, ≤800 ms,
reduced-motion off)** ✓ · gauge sweep ✓ · info rows fade-up stagger ✓ · share/copy press-scale +
haptic ✓ · none/revoked = no celebratory shimmer (honest) ✓ · all `MediaQuery.disableAnimations`-
gated ✓.

## Accessibility checklist
header semantics ✓ · badge state announced in text (issued/none/revoked) not color alone ✓ · gauge
value + threshold announced ✓ · share/copy labeled ✓ · ≥48 dp targets ✓ · WCAG-AA chips + ink-on-
cream ✓ · 2.0× text-scale: badge + gauge + rows reflow, no clip ✓ · decorative halo/marigold ring
excluded ✓.

## Anti-slop gate
one orange focal (badge halo + primary CTA) ✓ · ghost/revoked states are visibly honest, never a
faked seal ✓ · no nested cards ✓ · marigold ring ≤8 %, issued-only ✓ · real server asset rendered,
not invented ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · issued/none/revoked/pending/loading/403
states present ✓ · slop gate ✓ · wiring intact (badge + verify + OHS) ✓ · honest badge state ✓ ·
widget tests green ✓.
