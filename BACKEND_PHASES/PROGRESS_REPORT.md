# Backend Phases — v2 Upgrade Progress Report

## Status Summary

**Total Phases**: 57 (33 v1 + 24 v2)
**Phases with full MD spec**: 57
**Phases with handoff stub**: 57
**ADDENDUM v2 sections appended**: 18 (on existing phases)

# 🎊 v2 BACKEND DOCUMENTATION COMPLETE 🎊

## v1 Status (Complete)

All 33 v1 phases (BE-01 to BE-33) remain valid as the v1 contract.

## v2 Updates (This Session)

### ADDENDUM v2 sections appended (18)

| Phase | Driver Reqs |
|---|---|
| BE-06 | Req 55 — Pending invitation auto-onboarding |
| BE-08 | Req 1 — Consumer 5th role + entitlements |
| BE-09 | Req 41 — PostgreSQL RLS + tenant scope middleware + isolation property tests |
| BE-10 | Req 4 — Scan endpoint with mode parameter |
| BE-11 | Req 4, Req 38 — Comprehensive OFF data fetch |
| BE-12 | Req 4, Req 32 — Comprehensive output + allergen matching |
| BE-13 | Req 38 — Image fallback presigned-URL flavor |
| BE-14 | Req 39 — Search SLOs and tenant scoping |
| BE-22 | Req 38, Req 45 — Vision + LLM provider implementations |
| BE-24 | Req 28, Req 31, Req 47 — FCM/in-app/SES channels + preferences |
| BE-26 | Req 29 — Vendor Quality metric extraction |
| BE-27 | Req 29 — Inventory Accuracy metric extraction |
| BE-28 | Req 13, Req 33 — 4-tier subscriptions + Trial Pro + ₹2 + e-mandate + Family Sharing |
| BE-29 | Req 44 — PostHog SDK with locked event taxonomy |
| BE-30 | Req 29 — Operational Health Score with 6 components |
| BE-31 | Req 15 — App Owner Dashboard privacy boundary |
| BE-32 | Req 43 — Cache_Layer per-resource TTL registry |
| BE-33 | Req 17, Req 50 — PostgreSQL TDE + KMS + backup posture |

### New phases added (24)

| Phase | Title | Driver Req |
|---|---|---|
| BE-34 | Onboarding Self-Selection API | 26 |
| BE-35 | Business Activation Endpoint + Touchpoints | 27 |
| BE-36 | Premium Consumer Tier + Family Sharing | 33 |
| BE-37 | Allergen Profile (per-family-member) | 32 |
| BE-38 | Expiry Calendar (Consumer) | 30 |
| BE-39 | Recall Alert Sweep + FSSAI Feed | 31 |
| BE-40 | AI Ingredient Explainer (LLM) | 45 |
| BE-41 | Healthy Alternatives + Affiliate Engine | 35 |
| BE-42 | Multi-Language i18n | 34 |
| BE-43 | Referral Program | 42 |
| BE-44 | Offline-First Sync + Idempotency | 37 |
| BE-45 | Image OCR Fallback (Cloud Vision) | 38 |
| BE-46 | Free-Tier Rate Limiting & Quotas | 40 |
| BE-47 | Feature Flags (Unleash/GrowthBook) | 48 |
| BE-48 | Observability (Sentry + OpenTelemetry) | 49 |
| BE-49 | DB Backups + PITR | 50 |
| BE-50 | Webhooks for Pro Tier | 52 |
| BE-51 | Public Product Profile Pages (SEO) | 53 |
| BE-52 | RADHA Verified Badge | 54 |
| BE-53 | Admin Impersonation Tool | 51 |
| BE-54 | Daily Insights + Weekly Digest | 47 |
| BE-55 | Shopping List Module | 47 |
| BE-56 | Barcode Learning Service (Community) | 46 |
| BE-57 | Voice Features Deferral Marker | 36 |

## Final Statistics

| Metric | v1 | v2 added | v1+v2 total |
|---|---|---|---|
| Phases | 33 | 24 | **57** |
| MD files (phase + handoff) | 66 | 48 | **114** |
| Plus index/plan files | 3 | 1 | 4 |
| Phases with mandatory SOP | 33 | 24 | 57 |
| Phases with sign-off gate | 33 | 24 | 57 |

## Excluded from v2

- **Open API for Enterprise tier** — explicitly excluded by user direction
- **Voice features** — deferred to v3 with formal marker phase BE-57

## Coverage Map — Requirements → Phases

Every requirement (1–55) in the spec has at least one backend phase:

| Req Range | Phase Coverage |
|---|---|
| 1–25 (v1 + updates) | BE-01 to BE-33 with v2 ADDENDUMs |
| 26 Onboarding | BE-34 |
| 27 Business Activation | BE-35 |
| 28 Notifications | BE-24 v2 |
| 29 Operational Health Score | BE-30 v2, BE-26 v2, BE-27 v2 |
| 30 Expiry Calendar | BE-38 |
| 31 Recall Alerts | BE-39 |
| 32 Allergen Profile | BE-37 |
| 33 Family Sharing | BE-36 |
| 34 Multi-language | BE-42 |
| 35 Affiliate / Healthy Alternatives | BE-41 |
| 36 Voice Deferral | BE-57 |
| 37 Offline-First Sync | BE-44 |
| 38 Image OCR Fallback | BE-45 |
| 39 Search-First | BE-14 v2 |
| 40 Rate Limiting | BE-46 |
| 41 Multi-Tenant Hardening | BE-09 v2 |
| 42 Referral | BE-43 |
| 43 Smart Cache | BE-32 v2 |
| 44 Analytics from Day 1 | BE-29 v2 |
| 45 AI Ingredient Explainer | BE-40 |
| 46 Barcode Learning | BE-56 |
| 47 Daily Insights / Shopping List | BE-54, BE-55 |
| 48 Feature Flags | BE-47 |
| 49 Observability | BE-48 |
| 50 DB Backups + PITR | BE-49 |
| 51 Admin Impersonation | BE-53 |
| 52 Webhooks | BE-50 |
| 53 Public Product Pages | BE-51 |
| 54 RADHA Verified Badge | BE-52 |
| 55 Staff Invitation | BE-06 v2, BE-09 v2 |

## What Remains Outside Backend

- **Frontend (Flutter Mobile App)**: A separate execution stream owned by FE phases.
  - The Onboarding card-grid UI (Lottie + flutter_animate + haptics + Hero) is FE work consuming BE-34's API.
  - All comprehensive scan output rendering, Allergen highlight banners, Expiry Calendar UI, etc.
- **App Owner Dashboard (Next.js)**: A separate execution stream consuming BE-31 (with v2 ADDENDUM) and analytics from PostHog.
- **Marketing Website (Next.js)**: Existing in v1 plan; no v2 changes.
- **Infrastructure/DevOps phases**: Unchanged.

## How to Read the Repo Now

For each existing v1 phase that has v2 changes:
1. Read `BE-XX_PHASE.md` original content (the v1 contract)
2. Read the `🔄 ADDENDUM v2` section appended after the v1 sign-off block
3. Implement both before signing off
4. Update `BE-XX_HANDOFF.md` with both v1 and v2 status

For each new v2 phase (BE-34 to BE-57):
1. Read `BE-XX_PHASE.md` (single contract — there's no v1)
2. Implement
3. Update `BE-XX_HANDOFF.md`

## Quality Standards Maintained

✅ Every phase has Phase Metadata (ID, dependencies, blocks, duration)
✅ Every phase has goal, prerequisites, files-to-create, service interfaces
✅ Every phase has DTOs/schemas, API endpoint specs, key implementation code
✅ Every phase has the 15-step Testing/Q&A SOP (or scaled variant for trivial phases)
✅ Every phase has a developer + reviewer sign-off gate
✅ Every phase has an independent handoff document

---

**v2 Update**: 2026-05-17
**Status**: ✅ COMPLETE
**Total Phases**: 57
**Total Files in BACKEND_PHASES/**: 118 (57 phase + 57 handoff + 4 index/plan/progress)
