# RADHA Backend — Upgrade Plan v2

**Date**: 2026-05-17
**Driver**: 30 new requirements (Req 26–55) added to `requirements.md` in May 2026
**Goal**: Roll the new requirements into the existing 33 backend phases without losing any prior work

---

## Scope Summary

| Bucket | Count | Notes |
|---|---|---|
| **Existing phases preserved as-is** | 15 | No changes needed |
| **Existing phases UPDATED via ADDENDUM** | 18 | Original content kept; ADDENDUM v2 section appended |
| **New phases ADDED (BE-34 onward)** | 24 | New MD + new HANDOFF per phase |
| **Total phases after upgrade** | 57 | Up from 33 |
| **Total MD files after upgrade** | 114 | (57 phase + 57 handoff) + plan/progress files |

---

## Existing Phases — UPDATE Map (Surgical ADDENDUM only)

For phases below, the original phase file is **preserved verbatim**. A new
section titled `## ADDENDUM v2 — Requirements Update May 2026` is appended.
The addendum lists:
- Which new requirements (Req IDs) this phase now also covers
- New service interfaces, DTOs, endpoints, DB columns introduced
- New test procedures and Q&A questions added to the SOP

| BE# | Original Title | ADDENDUM Adds |
|---|---|---|
| BE-06 | OTP Auth & SMS | Req 55 — Pending invitation detection on first OTP login (auto-create user under inviter's tenant, bypass onboarding) |
| BE-08 | Authorization Guards & Roles | Req 1 — Add Consumer as 5th role; role-based UI capability matrix expanded |
| BE-09 | Multi-tenancy | Req 41 — PostgreSQL RLS policies, Tenant_Scope_Middleware, cross-tenant isolation property tests |
| BE-10 | Product Catalog & EAN Lookup | Req 4 — `GET /api/v1/products/{ean}/scan?mode=basic\|comprehensive` endpoint with mode-specific response shapes |
| BE-11 | Open Food Facts Integration | Req 4, Req 38 — Comprehensive scan data fetch, fallback chain |
| BE-12 | Health Scoring Engine | Req 4, Req 32 — Comprehensive output (PROS/CONS/age bands/consumption guidance), Allergen_Profile matching at scan time |
| BE-13 | Product Images & S3 | Req 38 — Presigned upload paths used by Image_OCR_Fallback |
| BE-14 | Product Search | Req 39 — Fuzzy search SLOs and tenant scoping rules |
| BE-22 | AI/OCR Wrapper | Req 38, Req 45 — Image OCR fallback wiring; AI Ingredient Explainer LLM wrapper |
| BE-24 | Notifications & Background Jobs | Req 28, Req 31, Req 47 — FCM-first stack, Recall_Sweep_Job, Daily_Insights_Job, Notification_Preferences enforcement |
| BE-26 | GRN Module | Req 29 — Vendor Quality component metrics emitted to OHS calculator |
| BE-27 | Inventory Module | Req 29 — Inventory Accuracy component metrics emitted to OHS calculator |
| BE-28 | Subscriptions | Req 13, Req 33 — 4-tier model (Free Consumer, Premium Consumer ₹49, Starter ₹49, Growth ₹99, Pro ₹199), 14-day Trial Pro + ₹2 Trial_Verification_Charge + RBI_eMandate (UPI Autopay/e-NACH), Family_Sharing entitlement propagation |
| BE-29 | Analytics & Leads | Req 44 — PostHog SDK + locked event taxonomy from Day 1 |
| BE-30 | Client In-App Dashboard | Req 29 — Operational_Health_Score (6-component, 0–100, daily) + 30-day trend |
| BE-31 | App Owner Dashboard | Req 15 — Privacy boundary: dedicated endpoints; 403 on tenant content; PostgreSQL TDE language |
| BE-32 | Performance & Caching | Req 43 — Tiered Cache_Layer with per-resource TTLs (24h product, 1h recall, tenant-scoped keys, forever-local scan history on device) |
| BE-33 | Security Hardening | Req 17, Req 50 — PostgreSQL TDE at storage, AWS KMS for AES-256 field encryption, WAL archiving + PITR + monthly automated restore tests |

---

## Existing Phases — UNCHANGED (no addendum needed)

| BE# | Title | Reason no change |
|---|---|---|
| BE-01 | NestJS Backend Initialization | Foundational, no behavior change |
| BE-02 | Configuration & Env Validation | Adds new env vars, but covered by addendum-light reference inside BE-48 (Feature Flags) and BE-44 (Sync) |
| BE-03 | Global Middleware & Request Context | Tenant scope hook listed in BE-09 addendum |
| BE-04 | Error Handling & Logging | Sentry/OpenTelemetry wiring covered in BE-48 (Observability — new phase) |
| BE-05 | Database Connection & Repository | RLS policies covered in BE-09 addendum |
| BE-07 | Admin Auth & Sessions | No behavior change for v2 |
| BE-15 | EAN List Import | No behavior change |
| BE-16 | Scan Sessions | No behavior change |
| BE-17 | Bulk Scan Processing | No behavior change |
| BE-18 | Expiry Tracking & Alerts | Consumer-side calendar covered in BE-38 (new phase); business-side unchanged |
| BE-19 | Tasks | No behavior change (OHS metric extraction in BE-30 addendum) |
| BE-20 | Report Generation | No behavior change |
| BE-21 | Report Export | No behavior change |
| BE-23 | Media Processing & CDN | No behavior change |
| BE-25 | Suppliers | No behavior change |

---

## New Phases — BE-34 to BE-57

Each new phase ships:
- A `BE-XX_PHASE.md` (~500–800 lines) with the same structure as existing phases
- A `BE-XX_HANDOFF.md` (~200–400 lines)
- The mandatory Testing/Q&A SOP block (15 test procedures + 8 Q&A questions)
- A Sign-off Gate (Developer signature → Reviewer approval → next phase)

| BE# | Phase Title | Covers Req(s) | Layer |
|---|---|---|---|
| BE-34 | Onboarding Self-Selection API | 26 | Identity |
| BE-35 | Business Activation Endpoint + Touchpoints | 27 | Identity |
| BE-36 | Premium Consumer Tier + Family Sharing | 33 | Subscriptions |
| BE-37 | Allergen Profile (per-family-member) | 32 | Consumer |
| BE-38 | Expiry Calendar (Consumer) | 30 | Consumer |
| BE-39 | Recall Alert Sweep + FSSAI Feed | 31 | Background Jobs |
| BE-40 | AI Ingredient Explainer (LLM) | 45 | AI |
| BE-41 | Healthy Alternatives + Affiliate Engine | 35 | Recommendations |
| BE-42 | Multi-Language i18n | 34 | Platform |
| BE-43 | Referral Program | 42 | Growth |
| BE-44 | Offline-First Sync + Idempotency | 37 | Mobile Backend |
| BE-45 | Image OCR Fallback (Cloud Vision) | 38 | AI |
| BE-46 | Free-Tier Rate Limiting & Quotas | 40 | Platform |
| BE-47 | Feature Flags (Unleash/GrowthBook) | 48 | Platform |
| BE-48 | Observability (Sentry + OpenTelemetry) | 49 | Ops |
| BE-49 | DB Backups + PITR | 50 | Ops |
| BE-50 | Webhooks for Pro Tier | 52 | Integrations |
| BE-51 | Public Product Profile Pages (SEO) | 53 | Web |
| BE-52 | RADHA Verified Badge | 54 | Trust/Marketing |
| BE-53 | Admin Impersonation Tool | 51 | Ops |
| BE-54 | Daily Insights Job + Weekly Digest | 47 (digest part) | Background Jobs |
| BE-55 | Shopping List Module | 47 (list part) | Consumer |
| BE-56 | Barcode Learning Service (Community) | 46 | Catalog |
| BE-57 | Voice Features Deferral Marker | 36 | Roadmap (lightweight) |

---

## Execution Batches (How We Roll Out)

To keep velocity high without losing review quality, work proceeds in 5 batches:

### Batch A — Master docs + Addendums for highest-impact existing phases
- This file (UPGRADE_PLAN_v2.md) ✅
- Update `00_MASTER_BACKEND_ROADMAP.md` to 57-phase scope
- Update `PROGRESS_REPORT.md` to show v2 upgrade in progress
- Append ADDENDUM v2 to: BE-08, BE-09, BE-12, BE-24, BE-28, BE-29, BE-30, BE-31

### Batch B — Remaining existing-phase addendums
- Append ADDENDUM v2 to: BE-06, BE-10, BE-11, BE-13, BE-14, BE-22, BE-26, BE-27, BE-32, BE-33

### Batch C — New phases (Identity + Consumer features)
- BE-34 Onboarding Self-Selection API
- BE-35 Business Activation Endpoint + Touchpoints
- BE-36 Premium Consumer Tier + Family Sharing
- BE-37 Allergen Profile
- BE-38 Expiry Calendar
- BE-39 Recall Alert Sweep
- BE-43 Referral Program

### Batch D — New phases (AI + Recommendations + Platform)
- BE-40 AI Ingredient Explainer
- BE-41 Healthy Alternatives + Affiliate Engine
- BE-42 Multi-Language i18n
- BE-44 Offline-First Sync
- BE-45 Image OCR Fallback
- BE-46 Free-Tier Rate Limiting

### Batch E — New phases (Ops + Growth + Roadmap)
- BE-47 Feature Flags
- BE-48 Observability
- BE-49 DB Backups + PITR
- BE-50 Webhooks for Pro
- BE-51 Public Product Profile Pages
- BE-52 RADHA Verified Badge
- BE-53 Admin Impersonation Tool
- BE-54 Daily Insights + Weekly Digest
- BE-55 Shopping List Module
- BE-56 Barcode Learning Service
- BE-57 Voice Features Deferral Marker

---

## Quality Standards (Carry Forward From v1)

Every new and updated artifact maintains the v1 standards:

- ✅ Phase metadata: ID, dependencies, blocks, duration
- ✅ Goal & justification
- ✅ Prerequisites checklist
- ✅ Files to create / modify with absolute paths
- ✅ Service interfaces in TypeScript
- ✅ DTOs with Zod validation schemas
- ✅ Database integration (tables, queries, migrations)
- ✅ API endpoint specifications (request/response/auth/error codes)
- ✅ Test specifications (unit + integration + E2E)
- ✅ Mandatory Testing/Q&A SOP (15 test procedures + 8 Q&A questions)
- ✅ Sign-off gate (Developer → Reviewer → next phase)
- ✅ Risk assessment
- ✅ Performance benchmarks
- ✅ Security considerations
- ✅ Independent handoff document for context continuity

---

## Out of Scope for v2

- **Open API for Enterprise tier** — explicitly excluded by user
- **Voice features** — deferred to v3 (Req 36 documents the deferral)
- **Frontend (Flutter app, marketing website, owner dashboard web app)** — separate execution stream
- **Infrastructure/DevOps phases** — separate execution stream

---

## Status

| Batch | Items | Status |
|---|---|---|
| Batch A | Master docs + 8 addendums | 🚧 In progress this session |
| Batch B | 10 addendums | 📝 Pending |
| Batch C | 7 new phases | 📝 Pending |
| Batch D | 6 new phases | 📝 Pending |
| Batch E | 11 new phases | 📝 Pending |
