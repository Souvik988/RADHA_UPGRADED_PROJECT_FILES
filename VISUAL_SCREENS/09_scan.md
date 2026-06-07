# 09 · Scan — `/scan`
Mode: **both** · Tab/Stack: **root tab 2 of 5 (center)** · Gate: none (camera permission prompt on first use)

> The app's primary action surface — the centre tab, emphasized in the nav. Must feel fast, focused,
> and confident. Every pixel earns its place. Governed by the Bible (`.kiro/steering/visual-assets.md`).

---

## Story arc
**Human beat** (the user IS the protagonist here — the camera IS the moment) →
**Substance** (live viewfinder + scan frame + EAN feedback) →
**Action** (route to scan result, or record session item).

---

## Backend wiring (do not break)
| Zone | Provider / endpoint | Module |
|---|---|---|
| Product lookup | `GET /products/lookup/{ean}?storeId=` | products |
| Session scan recording | `POST /scan-sessions/{id}/items` | scans |
| Scan history | `GET /scans?limit=5&storeId=` | scans |
| Session list | `GET /scan-sessions?storeId=` | scans |
| Create session | `POST /scan-sessions` | scans |

---

## Scroll zones (top → bottom)

### Z-HERO — Scan header band *(slim, ~64 dp)*
- **Layout:** slim dark-overlay bar sitting over the camera feed. Left: back chevron (when drilled).
  Centre: "Scan Product" title `titleLarge` `w700` white. Right: history icon button (opens S1).
- **Tokens:** overlay `rgba(28,25,23,0.72)`, text white, `space16` H padding.
- **A11y:** title `Semantics(header:true)`; history button labeled "Scan history".

### Z1 — Live camera viewfinder *(fills remaining viewport)*
- **Layout:** edge-to-edge live `mobile_scanner` camera preview. Centred over it: the **scan frame**.
- **Scan frame:** a 260×180 dp rounded rectangle (`radius.lg`), 2 dp white stroke broken into four
  corner-bracket segments (top-left, top-right, bottom-left, bottom-right — each ~32 dp long).
  A thin **orange scanning line** `#EA580C` animates vertically up and down within the frame
  (1.6s loop, easeInOut, paused on reduced-motion). The brackets subtly pulse opacity 0.7→1
  in sync with the scan line (60 ms phase shift).
- **Torch button:** bottom-right of viewfinder, 44 dp circular button, `rgba(28,25,23,0.6)` fill,
  torch glyph white. Toggles flashlight. Press-scale `0.97`.
- **Gallery button:** bottom-left of viewfinder, same style, photo glyph. Opens image picker for
  barcode from photo (web fallback only).
- **Instruction label:** below the scan frame, "Align barcode within the frame" `labelMedium`
  white, `rgba(28,25,23,0.5)` pill background, `radius.full`.
- **EAN detected feedback:** when an EAN is detected — the frame corners flash orange `#EA580C`,
  the scan line stops, a subtle `haptic.medium` fires, then the app routes to `/scan/result/:ean`
  (200 ms transition delay so the flash is visible).
- **Session badge:** if a scan session is active, a floating pill at the top of the viewfinder
  (below the header bar) shows "Session active · 12 scanned" with an orange dot and a "Stop" button.
- **Tokens:** scan line `#EA580C`; frame stroke `rgba(255,255,255,0.85)`; corner flash `#EA580C`.
- **Motion:** scan line continuous loop 1.6s easeInOut; corner flash 200ms orange pulse on detect;
  session badge slides down from header on session start (spring, 280ms).
- **A11y:** camera view `excludeSemantics`; torch `Semantics('Toggle flashlight')`; gallery
  `Semantics('Pick image to scan')`; session pill `Semantics('Scan session active, 12 items scanned')`.
- **States:** camera permission denied → Z2 permission prompt (replaces viewfinder); no camera
  hardware → fallback image picker only.

### Z2 — Camera permission prompt *(replaces viewfinder when camera denied)*
- **Layout:** centred column on canvas `#FFFBF5`. Tonal camera badge (outline camera glyph on
  accent-tint `#FED7AA` circle). Title "Camera access needed" `w700`. Sub "RADHA needs camera
  access to scan barcodes." `bodyMedium` ink-soft. Orange "Allow camera" CTA (opens system
  settings). Secondary "Pick from gallery" text button.
- **Tokens:** badge 72 dp, `radius.full`; CTA full-width orange; spacing `space24`.

### Z3 — Scan history bottom sheet *(S1 — opened by history icon)*
See Sub-surfaces S1 below.

### Z-NAV — Bottom navigation (§3.12)
Home · **Scan (active, centre-emphasized orange)** · Expiry · Tasks · Profile.

---

## Sub-surfaces

### S1 · Scan history sheet
- Bottom sheet `xl` top radius, drag handle. Title "Recent Scans" `titleMedium` `w700`.
- Lists last 10 scans from `GET /scans?limit=10`: product thumb (44 dp `md` well) + name/token +
  brand + `mono` EAN + mono expiry date + status dot. Hairline dividers.
- "View all" footer row → `12_scan_sessions`.
- Spring enter, exit faster. Pull-to-refresh inside sheet.
- Empty: tonal scan badge + "No scans yet" + "Scan your first product".

### S2 · Scan session controls sheet
- Opened from the session badge "Stop" button. Title "End scan session?".
- Shows session summary: total scanned, pass count (green), fail count (red), not-in-list (warn).
- Two actions: "Continue scanning" (dismiss) + orange "End session" → marks session complete,
  routes to session summary screen `12_scan_sessions/{id}`.

### S3 · EAN not found sheet
- Bottom sheet triggered when `GET /products/lookup/{ean}` returns 404.
- "Product not found" title, EAN shown in `mono`. Options: "Add to expiry manually",
  "Report unknown EAN", "Scan again" (dismisses sheet, re-activates scanner).

---

## State gallery
`default (scanning)` · `EAN detected (flash + transition)` · `session active` · `camera denied` ·
`EAN not found` · `scan history sheet` · `session controls sheet`.

---

## Asset checklist
| ID | Asset | Tool | Save path | Brief |
|---|---|---|---|---|
| B0 | Full Scan mockup (default) | `generate_ui_mockup` | `assets/mockup/scan.png` | SCREEN: Scan (/scan). Live camera viewfinder fullscreen with dark overlay header "Scan Product", centred white corner-bracket scan frame (260x180dp), animated orange scanning line, torch + gallery buttons at bottom corners of viewfinder, instruction pill "Align barcode within the frame", session badge pill "Session active · 12 scanned" top of viewfinder. 5-tab nav at bottom with Scan tab active in orange. Dark cinematic feel inside the camera zone, warm cream only on the nav bar. Real barcode product visible through the scan frame (cereal box or biscuit packet barcode area). |
| B1 | Scan frame corner-brackets glyph | `generate_image` | `assets/illustration/scan-frame.png` | Minimal vector-style scan frame: four white corner brackets on transparent background, each ~32dp long, 2dp stroke weight, rounded terminals, warm white. No fill. Leaves the center empty. Suitable for overlaying on a camera preview. |
| B2 | Scan screen states mockup | `generate_ui_mockup` | `assets/mockup/scan-states.png` | Two-panel side by side: LEFT = scan screen with "camera permission denied" empty state on warm cream canvas (tonal camera badge, "Camera access needed" title, orange "Allow camera" CTA). RIGHT = scan screen with EAN-detected flash state (corner brackets glowing orange, orange scanning line stopped at centre, "EAN Detected" toast at top). Same iPhone 15 framing. |
| B3 | Scan history sheet mockup | `generate_ui_mockup` | `assets/mockup/scan-history-sheet.png` | iPhone 15. Bottom sheet covering ~55% of screen showing scan history: drag handle, "Recent Scans" title, list of 4 product rows (product thumb + name + mono EAN + green/red status dot), "View all" footer. Behind sheet: dark camera viewfinder dimmed. Warm cream sheet on dark backdrop. |

---

## Motion checklist (Emil)
scan line loop ✓ · corner flash on detect ✓ · press-scale torch/gallery ✓ · session badge spring ✓ ·
history sheet spring enter ✓ · reduced-motion: scan line instant/static ✓.

## Accessibility checklist
camera view excluded from semantics ✓ · torch + gallery labeled ✓ · session badge announced ✓ ·
permission prompt fully keyboard/switch navigable ✓ · EAN detection announced via `Semantics.announce` ✓.

## Anti-slop gate
dark cinematic camera feel distinct from generic scanner apps ✓ · custom corner-bracket frame not
stock Material ✓ · orange scan line branded ✓ · session badge is functional not decorative ✓ ·
"an AI made that" test fails ✓.

## Done gate
mockup beaten ✓ · tokens-only ✓ · motion+reduced-motion ✓ · all states present ✓ · slop gate ✓ ·
backend wiring intact ✓ · widget tests green ✓.
