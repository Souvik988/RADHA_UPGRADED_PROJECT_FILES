# Visual UX Audit

Status: in progress

## Strengths Observed

- The app consistently uses the RADHA warm cream/orange palette, rounded cards, and Plus Jakarta Sans scale.
- OTP and onboarding screens feel intentionally branded rather than generic Material defaults.
- Manual scan fallbacks are discoverable and useful on emulator hardware.
- Segment selection has a clear selected state and a disabled-to-enabled CTA transition.
- The Expiry tab now degrades to an intentional no-store empty state instead of a backend-looking error.

## Findings

### VUX-001 - Onboarding segment grid is clipped by sticky CTA

- Evidence: `docs/qa/screenshots/android-onboarding-segments.png`
- Severity: P2 polish/accessibility risk
- Details: On the 1080x2340 emulator, the Institution and Auditor cards are partly covered by the sticky bottom CTA area. The controls remain detectable in the accessibility tree, but visually the lower labels are cut off.
- Recommendation: Add bottom padding equal to CTA height plus safe area, or reduce card height/spacing for this viewport.

### VUX-002 - Bottom nav active state can be visually ambiguous on Home

- Evidence: `docs/qa/screenshots/android-auth-verified-home.png`
- Severity: P3 polish
- Details: Home is the active route, but Scan also receives prominent orange treatment as a central action. This may read as two active tabs.
- Recommendation: Keep Scan prominent if it is the primary action, but differentiate active route state from promoted action state.

### VUX-003 - Scan result health-chip icons render as tiny/odd glyphs

- Evidence: `docs/qa/screenshots/android-scan-result-amul-butter-fixed.png`
- Severity: P3 polish
- Details: Sugar/Salt/Fat/Processed/Child-suitable chips show very small marks that do not read like polished icons at emulator size.
- Recommendation: Use consistent vector icons or remove unavailable image glyphs until real health flags are present.

### VUX-004 - Expiry no-store copy is business-oriented for consumer accounts

- Evidence: `docs/qa/screenshots/android-expiry-no-store-fixed.png`
- Severity: P3 polish/product decision
- Details: The repaired state is functionally correct, but the copy says to ask a manager. That fits invited staff, while pure consumer accounts may need a different "store features are for business workspaces" message.
- Recommendation: Split empty-state copy by app mode once consumer personal-expiry support is clarified.

## Emulator Caveats

- The scanner screen produced CameraX warnings about missing expected camera hardware on the emulator. The app did not crash and showed fallback controls.
