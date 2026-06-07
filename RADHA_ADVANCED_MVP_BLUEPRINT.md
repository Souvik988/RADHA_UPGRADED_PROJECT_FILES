# RADHA Advanced MVP Implementation Blueprint

This consolidated blueprint summarizes the upgraded architecture across the uploaded files.

## Product Positioning
RADHA is a smart retail operations and audit platform for product scanning, expiry management, EAN verification, task management, reports, lightweight GRN, lightweight inventory, and owner-level SaaS analytics.

## V1 Core Modules
1. Auth and roles.
2. Barcode/EAN scanner.
3. Product detail and health indicator.
4. Expiry management.
5. EAN approved-list validation.
6. Bulk scan export.
7. Task assignment.
8. Client in-app dashboard.
9. Lightweight inventory.
10. GRN inward.
11. Reports.
12. Subscription/free trial.
13. Marketing website.
14. Owner-only SaaS dashboard.

## Lightweight Inventory Design
- Stock in.
- Stock out.
- Low-stock alerts.
- Basic inventory counts.
- Category-wise stock visibility.
- Batch/expiry-aware quantity.
- Movement audit trail.

## GRN Design
- Supplier entry.
- Invoice number.
- GRN inward date.
- Product quantity.
- Batch number where available.
- Expiry date during inward.
- Review and post flow.
- Posted GRN updates inventory.

## Subscription Model
- Three-month free trial.
- ₹49 Starter plan.
- ₹99 Growth plan.
- ₹199 Pro plan.
- Backend entitlement guard.
- Owner dashboard subscription tracking.

## Dashboard Split
### Client Dashboard Inside App
Shows store-level operational metrics: scans, expiry alerts, EAN mismatches, pending tasks, GRN entries, stock counts, low-stock alerts, reports.

### Owner Dashboard Only for RADHA Owner
Shows business-level SaaS metrics: website visitors, clicks, leads, app signups, active users, subscriptions, trial status, paid users, revenue estimate, feature usage, support signals.

## Non-Goals
No GST billing, POS, accounting, printer integration, sales payment, or full ERP functionality in V1.
