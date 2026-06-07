# RADHA Backend Execution — Master Roadmap (v2 — Upgraded May 2026)

## Overview

This directory contains **57 backend execution phases** for the RADHA platform (33 v1 phases + 24 v2 phases). Each phase ships its own MD specification and a session handoff file.

**Total Files**: 114 (57 phase + 57 handoff) plus index/plan/progress files.

> **Upgrade history**:
> - **v1 (May 2026)** — Original 33 phases delivered (BE-01 to BE-33) covering core platform.
> - **v2 (May 2026)** — Added 24 new phases (BE-34 to BE-57) plus ADDENDUM v2 sections appended to 18 existing phases. Driven by 30 new requirements (Req 26–55) covering Consumer mode, Premium Consumer tier, ₹2 Trial Pro flow, business activation touchpoints, comprehensive scan output, FCM-first notifications, Operational Health Score, killer consumer features, multi-language, and 22 architectural refinements.
> - See `UPGRADE_PLAN_v2.md` for the full v2 execution plan.

---

## Phase Overview by Layer

### Layer 1: Foundation (BE-01 to BE-05) — 5 phases (v1, unchanged)

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-01 | NestJS Backend Initialization | 2-3 days | Unchanged |
| BE-02 | Configuration & Env Validation | 1-2 days | Unchanged |
| BE-03 | Global Middleware & Request Context | 2-3 days | Unchanged |
| BE-04 | Error Handling & Logging | 2-3 days | Unchanged |
| BE-05 | Database Connection & Repository Foundation | 2-3 days | Unchanged |

### Layer 2: Security & Identity (BE-06 to BE-09) — 4 phases

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-06 | OTP Authentication & SMS | 3-4 days | ADDENDUM v2 |
| BE-07 | Admin Auth & Sessions | 2-3 days | Unchanged |
| BE-08 | Authorization Guards & Roles | 2-3 days | ADDENDUM v2 (Consumer role) |
| BE-09 | Multi-tenancy | 2-3 days | ADDENDUM v2 (PostgreSQL RLS) |

### Layer 3: Core Product (BE-10 to BE-14) — 5 phases

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-10 | Product Catalog & EAN Lookup | 2-3 days | ADDENDUM v2 (scan modes) |
| BE-11 | Open Food Facts Integration | 2-3 days | ADDENDUM v2 |
| BE-12 | Health Scoring Engine | 2-3 days | ADDENDUM v2 (comprehensive output) |
| BE-13 | Product Image Management & S3 | 2-3 days | ADDENDUM v2 |
| BE-14 | Product Search & Filtering | 2-3 days | ADDENDUM v2 |

### Layer 4: Audit & Compliance (BE-15 to BE-18) — 4 phases (v1, unchanged)

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-15 | EAN List Import & Validation | 3-4 days | Unchanged |
| BE-16 | Scan Session Management | 2-3 days | Unchanged |
| BE-17 | Bulk Scan Processing | 2-3 days | Unchanged |
| BE-18 | Expiry Tracking & Alerts (Business) | 2-3 days | Unchanged |

### Layer 5: Operations (BE-19 to BE-21) — 3 phases (v1, unchanged)

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-19 | Task Assignment & Workflow | 2-3 days | Unchanged |
| BE-20 | Report Generation Engine | 3-4 days | Unchanged |
| BE-21 | Report Export (Excel/PDF) | 2-3 days | Unchanged |

### Layer 6: AI & Media (BE-22 to BE-24) — 3 phases

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-22 | AI/OCR Wrapper (Free-first) | 3-4 days | ADDENDUM v2 |
| BE-23 | Media Processing & CDN | 2-3 days | Unchanged |
| BE-24 | Notifications & Background Jobs | 2-3 days | ADDENDUM v2 (FCM stack) |

### Layer 7: Business Operations (BE-25 to BE-31) — 7 phases

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-25 | Suppliers Management | 1-2 days | Unchanged |
| BE-26 | GRN Module | 3-4 days | ADDENDUM v2 (OHS metrics) |
| BE-27 | Inventory Module | 3-4 days | ADDENDUM v2 (OHS metrics) |
| BE-28 | Subscriptions | 2-3 days | ADDENDUM v2 (Trial Pro + ₹2) |
| BE-29 | Analytics & Lead Ingestion | 2-3 days | ADDENDUM v2 (PostHog) |
| BE-30 | Client In-App Dashboard | 2-3 days | ADDENDUM v2 (OHS) |
| BE-31 | App Owner Dashboard | 2-3 days | ADDENDUM v2 (privacy) |

### Layer 8: Hardening (BE-32 to BE-33) — 2 phases

| Phase | Name | Duration | v2 Status |
|---|---|---|---|
| BE-32 | Performance Optimization & Caching | 3-4 days | ADDENDUM v2 (Cache layer) |
| BE-33 | Security Hardening & Production Readiness | 3-4 days | ADDENDUM v2 (TDE + KMS) |

---

## Layer 9: Identity v2 (BE-34 to BE-35) — 2 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-34 | Onboarding Self-Selection API | 26 | 2 days |
| BE-35 | Business Activation Endpoint + Touchpoints | 27 | 2-3 days |

## Layer 10: Consumer Features (BE-36 to BE-39, BE-43) — 5 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-36 | Premium Consumer Tier + Family Sharing | 33 | 2-3 days |
| BE-37 | Allergen Profile (per-family-member) | 32 | 2 days |
| BE-38 | Expiry Calendar (Consumer) | 30 | 1-2 days |
| BE-39 | Recall Alert Sweep + FSSAI Feed | 31 | 2 days |
| BE-43 | Referral Program | 42 | 1-2 days |

## Layer 11: AI v2 + Recommendations (BE-40 to BE-42, BE-45) — 4 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-40 | AI Ingredient Explainer (LLM) | 45 | 2 days |
| BE-41 | Healthy Alternatives + Affiliate Engine | 35 | 2-3 days |
| BE-42 | Multi-Language i18n | 34 | 2-3 days |
| BE-45 | Image OCR Fallback (Cloud Vision) | 38 | 2 days |

## Layer 12: Mobile Backend Plumbing (BE-44, BE-46) — 2 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-44 | Offline-First Sync + Idempotency | 37 | 2-3 days |
| BE-46 | Free-Tier Rate Limiting & Quotas | 40 | 1-2 days |

## Layer 13: Platform Ops v2 (BE-47 to BE-49, BE-53) — 4 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-47 | Feature Flags (Unleash/GrowthBook) | 48 | 2 days |
| BE-48 | Observability (Sentry + OpenTelemetry) | 49 | 2-3 days |
| BE-49 | DB Backups + PITR | 50 | 1-2 days |
| BE-53 | Admin Impersonation Tool | 51 | 2 days |

## Layer 14: Growth & Integrations (BE-50 to BE-52, BE-54 to BE-57) — 7 NEW phases

| Phase | Name | Covers Req | Duration |
|---|---|---|---|
| BE-50 | Webhooks for Pro Tier | 52 | 2-3 days |
| BE-51 | Public Product Profile Pages (SEO) | 53 | 2 days |
| BE-52 | RADHA Verified Badge | 54 | 1-2 days |
| BE-54 | Daily Insights Job + Weekly Digest | 47 (digest) | 2 days |
| BE-55 | Shopping List Module | 47 (list) | 1-2 days |
| BE-56 | Barcode Learning Service (Community) | 46 | 2-3 days |
| BE-57 | Voice Features Deferral Marker | 36 | 0.5 days |

---

## Total Duration

- **v1 (33 phases)**: 70-95 days sequential
- **v2 additions (24 phases)**: 45-60 days sequential
- **Combined v1+v2 (57 phases)**: 115-155 days sequential
- **With parallelization (Wave-based)**: 70-95 days

## File Standards

Every phase file (`BE-XX_PHASE.md`) contains:
1. Phase Metadata (ID, dependencies, blocks, duration)
2. Goal & justification
3. Prerequisites checklist
4. Files to create / modify
5. TypeScript service interfaces
6. Implementation code (production-ready)
7. DTOs with Zod validation schemas
8. Database integration (tables, queries, migrations)
9. API endpoint specifications
10. Test specifications (unit + integration + E2E)
11. Commands to run
12. Environment variables
13. Validation checklist (15-25 items)
14. Risk assessment
15. Performance benchmarks
16. Security considerations
17. **Mandatory Testing/Q&A SOP** (15 test procedures + 8 Q&A questions)
18. **Sign-off Gate** (Developer signature → Reviewer approval → next phase)
19. Completion criteria

Every handoff file (`BE-XX_HANDOFF.md`) contains:
1. Session metadata
2. What was completed
3. Files created/modified
4. Tests written
5. Database changes
6. What's ready for next phase
7. Known issues
8. Deviations from plan
9. Context for next developer
10. Environment state
11. Performance metrics
12. Security audit
13. Next phase preparation
14. Questions for next developer
15. Rollback information

## Status

| Phase Range | Count | Status |
|---|---|---|
| BE-01 to BE-33 | 33 | ✅ v1 complete |
| BE-01 to BE-33 ADDENDUM v2 | 18 | 🚧 In progress |
| BE-34 to BE-57 | 24 | 📝 Pending |

## How to Use This Roadmap

### Reading Order
1. Read phase MD file completely
2. If phase has ADDENDUM v2 section, read it after the original spec
3. Implement following both base spec + addendum
4. Run all 15 test procedures from the Testing/Q&A SOP
5. Answer all 8 Q&A questions
6. Get developer self-verification + reviewer approval
7. Update handoff file
8. Move to next phase

### For Multi-developer Parallelization
Use the wave map in `UPGRADE_PLAN_v2.md` to assign phases to parallel developers without dependency conflicts.

---

**v2 Status**: 🚧 Active rollout
**Last Updated**: 2026-05-17
**Total Phases**: 57
**Total MD Files**: 114 + index/plan/progress
