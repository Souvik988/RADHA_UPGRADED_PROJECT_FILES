# RADHA Files Review and Upgrade Report

Generated: 2026-05-15

## Executive Decision
RADHA should be upgraded as a **mobile-first retail operations, audit, expiry, EAN verification, lightweight GRN, and lightweight inventory SaaS platform**.

The client dashboard stays **inside the mobile app**. A separate **owner-only web dashboard** is required for the RADHA business owner to track website visitors, signups, subscriptions, app usage, leads, and revenue.

## What Was Wrong or Missing in the Uploaded Files

| Area | Problem Found | Required Fix |
|---|---|---|
| Lightweight inventory | Inventory, stock in/out, stock counts, low-stock alerts, and GRN are almost completely missing from architecture, API, DB, frontend, backend, connection map, testing, and build order. | Add a dedicated inventory + GRN domain across all layers. |
| Dashboard separation | Existing docs mix “admin web panel,” “admin panel,” and “dashboard” too generally. | Make client dashboard mobile-only; create a separate owner-only SaaS dashboard. |
| Owner analytics | No clear model for website visitors, clicks, leads, app signups, active users, trial users, paid users, plan revenue, or subscription funnel. | Add owner analytics module, marketing events, lead capture, app events, and SaaS metrics. |
| Subscription system | No clear plan for 3-month free trial, ₹49/₹99/₹199 plans, entitlement gates, expiry, payment events, or subscription status. | Add subscription and entitlement contracts. |
| Scope boundary | The docs do not strongly protect the product from drifting into ERP/POS/billing/GST/accounting. | Add explicit non-goals and feature boundary. |
| Frontend path issue | FE-11 says Admin Web Panel and Marketing Website, but also creates `apps/mobile/lib/features/admin_web_panel_and_marketing_website/`, which incorrectly places web concerns inside the mobile app tree. | Separate `apps/marketing-web`, `apps/owner-dashboard`, and mobile app features. |
| Backend module naming | Backend execution phases use long generic slug module folders instead of clean domain modules. | Replace/override with clean modules: auth, users, products, ean-lists, scans, expiry, tasks, reports, inventory, grn, subscriptions, owner-analytics. |
| Database gaps | Database has products, scans, expiry, tasks, reports, AI, but no inventory batches, stock movements, suppliers, GRN, plan subscriptions, owner analytics. | Add normalized tables with tenant/store scoping and indexes. |
| Connection map gaps | End-to-end wiring only covers core audit features. | Add inventory, GRN, subscriptions, owner analytics, website lead capture, app event tracking. |
| Testing gaps | Test matrix does not include inventory transaction integrity, GRN-to-stock consistency, subscription gating, or owner-dashboard privacy. | Add tests for these critical flows. |
| AI scope | AI is well structured but should also include simple rule-first inventory insights. | Add AI reorder suggestion, expiry-risk summary, stock anomaly detection, owner conversion insight as later enhancements. |

## Upgraded Product Surface Split

| Surface | User | Platform | Purpose |
|---|---|---|---|
| RADHA Mobile App | Retail store owner, manager, staff, auditor | Flutter Android/iOS | Scan, expiry, EAN verification, GRN, lightweight inventory, tasks, reports, client in-app dashboard. |
| RADHA Marketing Website | Public visitors and leads | Next.js website | Explain features, pricing, contact/demo, app download, privacy/terms. |
| RADHA Owner Dashboard | RADHA business owner only | Private Next.js web dashboard | Website analytics, lead tracking, app users, active users, subscriptions, revenue, plan conversion, support signals. |
| Backend API + Worker | System | NestJS | Auth, tenant/store scoping, domain APIs, reports, imports, subscriptions, analytics ingestion. |

## Final V1 Feature Boundary

### Include in V1
- Mobile OTP login, admin/staff/manager roles.
- Barcode/EAN scanning and product details.
- Expiry entry and green/yellow/red expiry status.
- Approved EAN Excel/CSV upload and validation.
- Bulk scan export to Excel/PDF.
- Task assignment and completion tracking.
- Client dashboard inside mobile app.
- Lightweight GRN: supplier, invoice, inward products, quantity, expiry/batch.
- Lightweight inventory: stock in, stock out, stock counts, category visibility, low-stock alerts.
- Owner dashboard: website analytics, leads, app users, subscriptions, trials, revenue.
- Subscription model: 3-month free trial, ₹49, ₹99, ₹199 plans.

### Explicitly Exclude from V1
- Full GST billing.
- POS checkout.
- Accounting/ledger.
- Printer integration.
- Payment gateway beyond subscription handling.
- Full ERP purchase/sales/accounting workflows.

## Implementation Upgrade Summary

The upgraded files in this package add the missing modules across architecture, database, API contracts, frontend, backend, build order, testing, production checklist, and AI scope.

Recommended build order now:

1. Foundation, auth, tenant/store/user roles.
2. Product lookup, scanner, expiry, EAN validation.
3. GRN + lightweight inventory database and APIs.
4. Mobile inventory/GRN screens and client dashboard cards.
5. Reports, exports, tasks.
6. Subscription/free-trial entitlement engine.
7. Website + owner-only dashboard analytics.
8. AI/rules insights and production hardening.
