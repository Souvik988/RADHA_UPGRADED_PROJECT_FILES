# Product

**RADHA** — Retail Assistant for Data, Health & Audits.

A mobile-first retail audit platform for Indian retail teams. Not a POS, billing, or accounting system in V1.

## Core capabilities (V1)
- Barcode/EAN scanning (on-device) and product lookup
- Rule-based product health indicators (sugar/oil/processed flags, child suitability)
- Expiry tracking with category thresholds and OCR-assisted MFG/EXP entry
- Approved EAN verification via Excel/CSV upload + bulk audit scans
- Task assignment and completion (manager → staff)
- Reports and Excel/PDF exports
- Lightweight inventory (stock in/out, counts, low-stock alerts) — no sales ledger or GST
- Lightweight GRN inward (supplier invoice, batch/expiry capture, stock posting)
- Subscription and entitlements (3-month trial, ₹49/₹99/₹199 plans)

## Surfaces
- **RADHA Mobile App** (Flutter) — Staff, Manager, Auditor, Admin-lite, Owner. Includes in-app client dashboard.
- **Marketing Website** (Next.js) — public landing, pricing, contact, privacy/terms, app download.
- **Owner Dashboard** (private Next.js) — RADHA business owner only: visitors, leads, signups, trials, subscriptions, revenue, usage.
- **Backend** (NestJS) — API + Worker + Scheduler processes.

## Out of V1 scope
Full GST billing, POS checkout, accounting/ERP, printer integration, supplier payable ledger.

## Roles
Staff, Manager, Auditor, Admin-lite (in-app), Tenant Admin, RADHA Owner (private dashboard only).

## Multi-tenancy
Every business table is scoped by `tenant_id`. Most operational data is also scoped by `store_id`. Tenant/store scoping is mandatory and enforced at the service/repository layer.
