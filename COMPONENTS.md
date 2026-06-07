# Components — visual mockup queue (RADHA mobile app)

Component-level mockups for every reusable visual primitive in the RADHA mobile app. These mockups are the ground truth — Flutter widgets must match the mockup pixel-for-pixel at first render. Generate components **before** the pages that depend on them.

Activation phrases:
- **"generate next N components"** → process the first N unchecked items here.
- **"generate <component-name>"** → jump to a specific row.

Every brief must follow `.kiro/steering/visual-assets.md`: 200–600 chars, concrete style anchor, exact hex from the locked palette (`#EA580C` accent on `#FFFBF5` canvas with `#1C1917` ink, hairline `#E7E1D4`, `#FFFFFF` raised surfaces), Plus Jakarta Sans + JetBrains Mono, mandatory negative anchors. Component output goes under `assets/mockup/components/{kebab-name}.png` shown in isolation on `#FFFBF5` canvas with 24px margin and a faint baseline grid.

---

## Foundation tokens (do these FIRST — they unblock everything else)

- [x] **Design tokens reference sheet** — `tokens-reference` — generated as `assets/radha-design-tokens.png` (brand pack).
- [x] **Logo lockup (light)** — `logo-light` — generated as `assets/logo/image.png` (राधा Devanagari brand pack).
- [x] **Logo lockup (dark)** — `logo-dark` — generated as `assets/logo/radha-logo-dark.png` (brand pack).
- [x] **App icon** — `app-icon-mark` — generated as `assets/icons/app-icon-mark.png`.

## Inputs (5)

- [x] **Primary text input** — `input-text-primary` — generated as `assets/mockups/radha-primary-text-input-field-component.png`.
- [x] **OTP input (6-box)** — `input-otp` — generated as `assets/mockups/radha-otp-verification-input-component.png`.
- [x] **Mobile number input** — `input-phone` — generated as `assets/mockups/radha-mobile-number-input-component-a-s.png`.
- [x] **Search bar** — `input-search` — generated as `assets/mockups/radha-search-bar-component-a-48pt-tall.png`.
- [x] **Date picker (inline)** — `input-date-inline` — generated as `assets/mockups/radha-inline-date-picker-component-a-mo.png`.

## Buttons + CTAs (5)

- [x] **Primary CTA button** — `cta-primary` — generated as `assets/mockups/radha-primary-cta-button-component-thre.png`.
- [x] **Secondary CTA button** — `cta-secondary` — generated as `assets/mockups/radha-secondary-cta-button-component-th.png`.
- [x] **Destructive button** — `cta-destructive` — generated as `assets/mockups/radha-destructive-button-component-thre.png`.
- [x] **Icon button (44pt)** — `icon-button` — generated as `assets/mockups/radha-icon-button-component-three-circu.png`.
- [x] **FAB (floating action button)** — `fab` — generated as `assets/mockups/radha-floating-action-button-component.png`.

## Navigation (3)

- [x] **Bottom nav (5-tab)** — `bottom-nav-5` — generated as `assets/mockups/radha-bottom-navigation-bar-component-a.png`.
- [x] **Top app bar** — `app-bar-top` — generated as `assets/mockups/radha-top-app-bar-component-a-56pt-tall.png`.
- [x] **Segmented control (3-segment)** — `segmented-3` — generated as `assets/mockups/radha-segmented-control-component-a-3-s.png`.

## Cards + surfaces (6)

- [x] **Product card (scan result)** — `card-product-scan` — generated as `assets/mockups/radha-product-card-component-scan-resul.png`.
- [ ] **Product card (list row, dense)** — `card-product-row` — 64pt single-line row with thumb, name, trailing chip. Used in expiry, saved-products list.
- [x] **Product card (list row, dense)** — `card-product-row` — generated as `assets/mockups/radha-dense-product-list-row-component.png`.
- [x] **KPI tile** — `tile-kpi` — generated as `assets/mockups/radha-kpi-tile-component-a-square-1-1-d.png`.
- [x] **Score gauge (circular)** — `gauge-score` — generated as `assets/mockups/radha-circular-health-score-gauge-compon.png`.
- [x] **Health badge chip** — `chip-health` — generated as `assets/mockups/radha-health-badge-chip-set-four-rounde.png`.
- [x] **Status chip (generic)** — `chip-status` — generated as `assets/mockups/radha-generic-status-chip-set-five-smal.png`.

## Sheets + modals (3)

- [x] **Bottom sheet (default)** — `sheet-bottom` — generated as `assets/mockups/radha-modal-bottom-sheet-component-a-ro.png`.
- [x] **Confirmation dialog** — `dialog-confirm` — generated as `assets/mockups/radha-confirmation-dialog-component-a-c.png`.
- [x] **Snackbar** — `snackbar` — generated as `assets/mockups/radha-snackbar-component-shown-as-three.png`.

## Scanner-specific (3)

- [x] **Scanner viewfinder overlay** — `scanner-viewfinder` — generated as `assets/mockups/radha-barcode-scanner-viewfinder-full-s.png`.
- [x] **Scanner result card popup** — `scanner-result-popup` — generated as `assets/mockups/radha-scan-result-popup-a-partial-heigh.png`.
- [x] **Scanner empty / no-match state** — `scanner-no-match` — generated as `assets/mockups/radha-scanner-no-match-empty-state-a-cl.png`.

## States (4)

- [x] **Empty state — generic** — `empty-generic` — generated as `assets/mockups/radha-generic-empty-state-template-a-cl.png`.
- [x] **Loading skeleton — list** — `loading-skeleton-list` — generated as `assets/mockups/radha-loading-skeleton-list-three-stack.png`.
- [x] **Error state — generic** — `error-generic` — generated as `assets/mockups/radha-generic-error-state-a-clean-mobil.png`.
- [x] **Locked feature overlay** — `locked-feature` — generated as `assets/mockups/radha-locked-feature-overlay-a-mobile-s.png`.

## Onboarding-specific (2)

- [x] **Segment tile (onboarding 1)** — `segment-tile` — generated as `assets/mockups/radha-onboarding-segment-tile-component.png`.
- [~] **Page indicator dots** — `pager-dots` — SKIPPED. Two `IMAGE_TIMEOUT`s on this trivial prompt (three dots on a plain canvas gives the image pipeline too little to render). Trivial 2-line Flutter widget — will be built directly from tokens without a mockup.

## Data display (3)

- [x] **List section header** — `list-section-header` — generated as `assets/mockups/radha-list-section-header-component-a-l.png`.
- [x] **Sparkline** — `sparkline-mono` — generated as `assets/mockups/radha-inline-sparkline-component-a-smal.png`.
- [x] **Bento layout reference** — `bento-2x2` — generated as `assets/mockups/radha-bento-layout-reference-sheet-a-2x.png`.

---

## Done log

Once checked, leave checked. The history of generated components is the source of truth for which design primitives are stable — implementations can rely on them.

---

## Feature-coverage components (added after RADHA-CLIENT-OVERVIEW review)

These reusable components surfaced from reconciling the component library against all 57 backend phases / 25 v2 features. They are safety-critical, revenue-critical, or basic primitives that multiple pages depend on.

### Safety + alerts (batch 7)
- [x] **Allergen warning banner** — `banner-allergen` — generated as `assets/mockups/radha-allergen-warning-banner-component.png`.
- [x] **Recall alert banner** — `banner-recall` — generated as `assets/mockups/radha-recall-alert-banner-component-a-c.png`.
- [x] **Quota usage meter** — `meter-quota` — generated as `assets/mockups/radha-quota-usage-meter-component-a-com.png`.
- [x] **Inline banner (activation touchpoint)** — `banner-inline` — generated as `assets/mockups/radha-inline-activation-banner-component.png`.
- [x] **Paywall / upgrade sheet** — `sheet-paywall` — generated as `assets/mockups/radha-paywall-upgrade-bottom-sheet-a-ro.png`.

### Monetization + business (batch 8)
- [x] **Pricing tier card** — `card-pricing` — generated as `assets/mockups/radha-pricing-tier-cards-three-plan-car.png`.
- [x] **Affiliate alternative card** — `card-alternative` — generated as `assets/mockups/radha-healthy-alternative-affiliate-card.png`.
- [x] **OHS breakdown bars** — `ohs-breakdown` — generated as `assets/mockups/radha-operational-health-score-breakdown.png`.
- [x] **Family member row** — `row-family-member` — generated as `assets/mockups/radha-family-member-list-component-thre.png`.
- [x] **Verified badge mark** — `badge-verified` — generated as `assets/logo/radha-verified.png`.

### Core primitives (batch 9)
- [x] **Toggle / switch** — `toggle-switch` — generated as `assets/mockups/radha-toggle-switch-component-shown-in-t.png`.
- [x] **Quantity stepper** — `stepper-qty` — generated as `assets/mockups/radha-quantity-stepper-component-a-hori.png`.
- [x] **Selection row** — `row-selection` — generated as `assets/mockups/radha-selection-row-component-showing-ra.png`.
- [x] **Avatar** — `avatar` — generated as `assets/mockups/radha-avatar-component-shown-at-three-si.png`.
- [x] **Linear progress bar** — `progress-linear` — generated as `assets/mockups/radha-linear-progress-bar-component-show.png`.

### Remaining feature components (batch 10)
- [x] **Ingredient row + explainer card** — `ingredient-explainer` — generated as `assets/mockups/radha-ingredient-explainer-component-to.png`.
- [x] **Shopping list row** — `row-shopping` — generated as `assets/mockups/radha-shopping-list-component-three-sta.png`.
- [x] **OCR packaging capture frame** — `ocr-capture` — generated as `assets/mockups/radha-ocr-packaging-capture-frame-full.png`.
- [x] **Expiry calendar day cell** — `calendar-day-expiry` — generated as `assets/mockups/radha-expiry-calendar-component-a-parti.png`.
- [x] **Referral code card** — `card-referral` — generated as `assets/mockups/radha-referral-code-card-a-raised-white.png`.
