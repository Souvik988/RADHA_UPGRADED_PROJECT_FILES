# 46 · Community Contribute — `/products/learn`
Mode: **consumer** · Tab/Stack: **drill-down** (from a scan miss in `10_scan_result`, or Profile) · Gate: **role = consumer**

> Governed by `.kiro/steering/visual-assets.md` (the Bible) + `CHARACTER_STORYTELLING_BIBLE.md`
> (Mor). Tokens, motion, image-gen blocks (§6.1/§6.2), Scroll Grammar (§5) are **cited, not
> repeated**. Quality bar: **beat the reference mockup.** Honest-data law: this writes to the
> community barcode-learning queue (BE-56) — set expectations honestly ("goes to review", not
> "instantly added") and never imply rewards (no scan-to-earn).

---

## Story arc
**Human beat** (friendly header — *"Help RADHA learn this product"*, Mor `think` examining a
barcode, the community spirit) → **Substance** (the unknown EAN + a short honest contribution form:
product name, brand, pack size, optional photo) → **Action** (one orange "Submit to RADHA" CTA →
queues the entry for review; plus a quieter "Flag incorrect" path for existing-but-wrong data).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module | Honest-data note |
|---|---|---|---|
| Submit new entry | `POST /products/learn` { ean, name, brand?, packSize?, imageRef? } | barcode-learning BE-56 | Consumer-only; 201. Returns a `SubmissionDto` (status = pending review). Show "Sent for review", never "Added". |
| Flag existing | `POST /products/:ean/flag` { reason } | barcode-learning BE-56 | For a product that exists but is wrong; 200 → `FlagResultDto`. Threshold-tracked server-side. |
| Prefill EAN | scan-result deep-link arg / `eanProvider` | scans | EAN comes from the failed lookup in `10_scan_result`; render it mono, read-only. If entered manually, validate via `ean_validator`. |
| Rate-limit feedback | service-enforced (BE-56) | barcode-learning | If rate-limited (429), show honest "You've submitted a lot today — try again later", not a fake error. |
| Photo upload (optional) | media presign (if wired) / `imageRef` | media | Only if the schema accepts an image ref; otherwise omit the photo field entirely. |

**No rewards, ever:** the reference's "scan more, earn more" is **not** a RADHA feature. The
motivation framing is *community trust* ("you're helping every RADHA shopper"), never points/coins.

---

## Scroll zones (top → bottom)

### Z-HERO — Contribute header band  *(~168 dp)*
- **Layout:** warm band cream→`#FFF3E6`; back chevron; eyebrow "COMMUNITY" `labelMedium`
  accent-deep; title **"Help RADHA learn this product"** `w800` (2 lines); sub "Add what you know
  — it goes to review and helps every RADHA shopper." `bodyMedium` ink-soft. Right: **Mor `think`**
  inspecting a small barcode (the curious-helper beat).
- **Tokens:** padding `space16` H; eyebrow→title `space8`; band radius bottom `xl`.
- **Motion:** band fade + parallax; Mor reduced-motion → static.
- **A11y:** title header semantics; Mor `excludeSemantics`.

### Z1 — The unknown product  *(eyebrow: "SCANNED CODE")*
- **Layout:** raised `radius.lg` card: a `md` `#F5F1E8` well with a generic **barcode glyph**
  (no product cutout — we don't have one, that's the whole point) + the **mono EAN** big
  `monoLabel` (e.g. "8901234567890") + a Warn chip "Not in RADHA yet" (`#B45309`, info glyph).
- **Tokens:** well 56 dp, EAN `displaySmall` mono ink; chip §3.9 warn tints.
- **Motion:** card fade-up; press-scale none (informational).
- **A11y:** "Scanned code 8901234567890, not in RADHA yet" one semantics.
- **States:** EAN from scan (read-only) vs manual entry (editable + validated); invalid EAN →
  inline danger.

### Z2 — Contribution form  *(eyebrow: "WHAT IS IT?")*
- **Layout:** raised form card, hairline. Fields (only what `SubmitBarcodeSchema` accepts):
  - **Product name** — text field, cream, hairline, **orange focus ring**, required.
  - **Brand** — text field (optional, marked).
  - **Pack size** — text field, mono-friendly (e.g. "200 g"), optional.
  - **Photo (optional, only if schema supports `imageRef`)** — a `md` dashed-hairline upload well
    with camera glyph "Add a clear photo of the pack" (uses image_picker); shows thumbnail when set.
  - Helper ink-soft: "RADHA reviews community entries before they go live."
- **Tokens:** field `radius.md`, label `labelMedium`, helper `bodySmall` ink-soft, danger on error.
- **Motion:** focus → orange ring 150 ms; photo well → thumbnail fades in.
- **A11y:** each field labeled + describedby helper/error; optional fields marked "(optional)";
  logical focus order.
- **States:** empty/typing/valid/invalid; submitting → fields disabled + inline spinner.

### Z3 — Submit action  *(pinned)*
- **Layout:** full-width orange **"Submit to RADHA"** primary button pinned above home indicator;
  under it ink-soft "Goes to review — thanks for helping the community."
- **Tap →** `POST /products/learn` → S1 success.
- **Secondary path:** a quiet text link **"This product exists but the info is wrong → Flag it"**
  → S2 flag sheet (`POST /products/:ean/flag`).
- **States:** disabled until name valid; submitting → "Submitting…" + spinner; 429 → honest rate-
  limit line; error → inline danger + retry.

### Z-EMPTY / entry without an EAN
- If opened without a scanned code: a small **Mor `greet`** + "Scan a product first, or type its
  barcode" + a mono EAN input + "Continue". Keeps the flow honest (no blank form floating).

### Z-NAV
None — drill-down. Back chevron returns to scan-result/profile; bottom nav hidden.

---

## Sub-surfaces
- **S1 · Submission success sheet** — bottom sheet `xl`, drag handle: **Mor `celebrate`** (small,
  warm — *thanks*, not a reward), title "Sent for review 🙏", line "Thanks! RADHA's team will
  check it. You're helping every shopper.", orange "Done" + secondary "Add another". Spring enter.
  **No points/coins/score.**
- **S2 · Flag-incorrect sheet** — bottom sheet `xl`: title "What's wrong?", a reason chooser
  (chips: "Wrong name", "Wrong brand", "Wrong health info", "Other") + optional note field, danger-
  leaning "Submit flag" (it's a correction, not destructive). Calls `POST /products/:ean/flag`.
- **S3 · Photo guidance tip** — inline (not modal): "Flat, well-lit, whole pack visible" with a
  tiny do/don't illustration. Only if photo field present.
- **S4 · Rate-limited / error** — **Mor `concern`** + honest server message + Retry.

---

## State gallery (generate a mockup for each)
`default (EAN prefilled from scan, form empty)` · `filled/valid` · `invalid (inline errors)` ·
`submitting` · `success sheet (Mor celebrate, no rewards)` · `flag-incorrect sheet` ·
`no-EAN entry (Mor greet)` · `rate-limited (Mor concern)` · `loading` · `error`.

---

## Asset checklist (image-first — run §6 blocks; one tool call each, `enhance_prompt:true`)
| ID | Asset | Tool | Save path | Brief body (between Bible Block §6.1 & Negative footer §6.2) |
|---|---|---|---|---|
| A0 | **Full Community Contribute mockup (default)** | `generate_ui_mockup` | `assets/v2/mockup/community-contribute.png` | SCREEN: Community contribute (/products/learn). STORY: friendly "Help RADHA learn this product" header with a curious peacock mascot inspecting a barcode → "SCANNED CODE" card (barcode glyph well + mono EAN 8901234567890 + amber "Not in RADHA yet" chip) → "WHAT IS IT?" form (Product name, Brand optional, Pack size, optional photo upload well) → full-width orange "Submit to RADHA" with "Goes to review" helper + a quiet "Flag it" link. FOCAL: the submit CTA. COPY (verbatim): "COMMUNITY", "Help RADHA learn this product", "Add what you know — it goes to review and helps every RADHA shopper.", "Scanned code", "Not in RADHA yet", "What is it?", "Product name", "Brand", "Pack size", "RADHA reviews community entries before they go live.", "Submit to RADHA". Real product cutouts: no (the product is unknown — that's the point). Motion-implied: fade-up stagger, focus ring, photo thumbnail fade. NO rewards/points/coins anywhere. |
| A1 | Submission-success sheet mockup | `generate_ui_mockup` | `assets/v2/mockup/community-success.png` | Bottom sheet: small warm celebrate-pose peacock mascot (gratitude, not a prize), title "Sent for review 🙏", line "Thanks! RADHA's team will check it. You're helping every shopper.", orange "Done" + "Add another". Absolutely no points, coins, score, or scan-to-earn motif. |
| A2 | Community/contribution spot illustration | `generate_image` | `assets/v2/illustration/spot-community.png` | Small warm card-friendly illustration: a curious peacock mascot examining a barcode/magnifier with a soft community/hands-helping motif, burnt-orange + cream + terracotta, soft depth, muted (not glossy). Card-sized. |
| A3 | Flag-incorrect + photo-guidance glyph set (4) | `generate_icon_set` | `assets/v2/icons/contribute-set.svg` | One batch RADHA warm rounded glyphs (~1.75dp, ~2px radius, rounded terminals): barcode, camera-pack, flag, magnifier-check. Consistent family weight. |

> **Mor reuse:** `think` / `greet` / `celebrate` / `concern` frames exist under
> `assets/v2/character/mor/static/` — reference, don't regenerate. Only A0–A3 are new renders.

---

## Motion checklist (Emil) — reduced-motion safe
header fade/parallax ✓ · card + form fade-up stagger ✓ · field focus ring 150 ms ✓ · photo
thumbnail fade-in ✓ · success sheet spring-in ✓ · press-scale 0.97 + haptic on submit ✓ · all
`MediaQuery.disableAnimations`-gated ✓.

## Accessibility checklist
header semantics ✓ · EAN announced ✓ · every field labeled + optional marked + error describedby ✓ ·
"goes to review" expectation in text ✓ · ≥48 dp targets ✓ · WCAG-AA orange-on-white + ink-on-cream ✓ ·
2.0× text-scale: form grows, helper wraps, no clip ✓ · decorative illustration excluded ✓.

## Anti-slop gate
one orange focal (submit CTA) ✓ · NO rewards/points/coins/scan-to-earn anywhere ✓ · no nested
cards ✓ · form asks ONLY schema-accepted fields ✓ · honest "sent for review" (not "added") ✓ ·
unknown product shown as a barcode glyph, not a fake cutout ✓ · "an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · empty/error/submitting/success states ✓ ·
slop gate ✓ · wiring intact (learn + flag + rate-limit) ✓ · no-rewards rule honored ✓ · widget tests
green ✓.
