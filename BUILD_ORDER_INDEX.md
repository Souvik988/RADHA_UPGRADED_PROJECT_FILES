# File: BUILD_ORDER_INDEX.md

# RADHA Build Order Index

## Build First
1. PF-01 Architecture Baseline
2. PF-02 Repository Setup
3. PF-04 Environment Contract
4. PF-05 Shared Types
5. PF-06 API Contracts
6. DB-01 to DB-04
7. BE-01 to BE-06
8. FE-01 to FE-05

## Build Second
1. DB-05 Product tables
2. BE-07 Product lookup
3. FE-06 Scanner
4. FE-07 Product/expiry UI
5. DB-06 EAN tables
6. BE-09 EAN validation
7. FE-08 Bulk scan

## Build Third
1. DB-07 Scan/expiry tables
2. BE-10/BE-11 Scan + expiry
3. DB-08 Tasks
4. BE-12 Tasks
5. FE-09 Task screens
6. DB-09 Reports
7. BE-13 Reports
8. FE-10 Reports UI
---

## 2026-05-15 Upgrade Patch: Revised Build Order

## Build Fourth: Lightweight Inventory and GRN
1. DB-16 Suppliers and GRN tables.
2. DB-17 Inventory items, batches, and stock movements.
3. DB-18 Low-stock rules and alerts.
4. BE-17 Suppliers module.
5. BE-18 GRN module with transactional posting.
6. BE-19 Inventory module with stock in/out and low-stock alerts.
7. FE-13 Mobile inventory screens.
8. FE-14 Mobile GRN screens.
9. Add inventory/GRN cards to FE-05 dashboard.

## Build Fifth: Subscription and Owner Dashboard
1. DB-19 Subscription plans, entitlements, tenant subscriptions, subscription events.
2. DB-20 Website events, marketing leads, app usage events, owner daily metrics.
3. BE-20 Subscription and entitlement guard.
4. BE-21 Analytics and lead ingestion.
5. BE-22 Owner dashboard APIs.
6. FE-15 Marketing website pricing/contact/download pages.
7. FE-16 Owner-only web dashboard.

## Build Sixth: Advanced AI and Hardening
1. AI inventory insights and report summaries.
2. Subscription entitlement tests.
3. Owner dashboard privacy tests.
4. Load tests for scan, inventory, and owner dashboard metrics.

