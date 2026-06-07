# File: PROJECT_FILE_STRUCTURE.md

# RADHA Project File Structure and Ownership Map

## Repository Tree
```text
radha/
  apps/mobile/
  apps/admin-web/
  server/src/modules/
  server/src/db/
  packages/shared-types/
  packages/shared-validators/
  infra/
  docs/
```

## File Ownership and Build Order
|File Path|Section|Created In Phase|Filled In Phase|Purpose|Depends On|Used By|Status|
|---|---|---|---|---|---|---|---|
|apps/mobile/lib/main.dart|Frontend|FE-01|FE-01|Flutter app entry|Flutter SDK|Mobile app|Planned|
|apps/mobile/lib/core/network/api_client.dart|Frontend|FE-01|FE-04|Typed REST client|shared-types|All feature APIs|Planned|
|apps/mobile/lib/features/scanner/presentation/scanner_screen.dart|Frontend|FE-06|FE-06|Barcode scanner UI|Barcode plugin, Product API|Scanner workflow|Planned|
|apps/mobile/lib/features/products/presentation/product_detail_screen.dart|Frontend|FE-07|FE-07|Product + health + expiry UI|Product API|Staff/auditor|Planned|
|apps/admin-web/app/admin/dashboard/page.tsx|Frontend|FE-11|FE-11|Admin dashboard|API client|Managers/admin|Planned|
|server/src/main.api.ts|Backend|BE-01|BE-01|API process entry|NestJS config|HTTP endpoints|Planned|
|server/src/main.worker.ts|Backend|BE-01|BE-13|Worker process entry|Queues|Imports/reports/AI|Planned|
|server/src/modules/auth/auth.controller.ts|Backend|BE-05|BE-05|Auth endpoints|Auth service|Mobile/admin login|Planned|
|server/src/modules/products/products.controller.ts|Backend|BE-07|BE-07|Product lookup CRUD|Product service|Scanner/admin|Planned|
|server/src/modules/ean-lists/ean-lists.controller.ts|Backend|BE-09|BE-09|EAN imports/validate|EAN service|Admin/audit|Planned|
|server/src/modules/scans/scans.controller.ts|Backend|BE-10|BE-10|Scan sessions/items|Scan service|Scanner|Planned|
|server/src/modules/reports/reports.controller.ts|Backend|BE-13|BE-13|Report generation/download|Report service|Reports UI|Planned|
|server/src/modules/ai/ai.service.ts|Backend|BE-15|BE-15|AI provider abstraction|AI clients|OCR/summary|Planned|
|server/src/db/schema/products.ts|Database|DB-05|DB-05|Product schema|DB conventions|Product module|Planned|
|server/src/db/migrations/001_extensions.sql|Database|DB-02|DB-02|Base extensions|Postgres|All migrations|Planned|
|infra/docker-compose.dev.yml|Infra|INF-01|INF-01|Local dev services|Docker|All devs|Planned|
---

## 2026-05-15 Upgrade Patch: Corrected Advanced File Structure

```text
radha/
  apps/
    mobile/
      lib/features/auth/
      lib/features/dashboard/
      lib/features/scanner/
      lib/features/products/
      lib/features/expiry/
      lib/features/ean_audit/
      lib/features/tasks/
      lib/features/reports/
      lib/features/grn/
      lib/features/inventory/
      lib/features/subscription/
    marketing-web/
      app/(public)/page.tsx
      app/(public)/features/page.tsx
      app/(public)/pricing/page.tsx
      app/(public)/contact/page.tsx
      app/(legal)/privacy/page.tsx
      app/(legal)/terms/page.tsx
    owner-dashboard/
      app/owner/dashboard/page.tsx
      app/owner/website/page.tsx
      app/owner/leads/page.tsx
      app/owner/users/page.tsx
      app/owner/subscriptions/page.tsx
      app/owner/usage/page.tsx
  server/src/modules/
    auth/
    users/
    tenants/
    stores/
    products/
    ean-lists/
    scans/
    expiry/
    tasks/
    reports/
    suppliers/
    grn/
    inventory/
    subscriptions/
    analytics/
    owner-dashboard/
    ai/
  server/src/db/schema/
    suppliers.ts
    grn.ts
    inventory.ts
    subscriptions.ts
    analytics.ts
```

### Added Ownership Rows
| File Path | Section | Created In Phase | Filled In Phase | Purpose | Depends On | Used By | Status |
|---|---|---|---|---|---|---|---|
| apps/mobile/lib/features/inventory/presentation/inventory_dashboard_screen.dart | Frontend | FE-13 | FE-13 | Client in-app inventory dashboard | Inventory API | Store users | Planned |
| apps/mobile/lib/features/inventory/presentation/stock_in_screen.dart | Frontend | FE-13 | FE-13 | Stock in form | Inventory API | Manager/admin | Planned |
| apps/mobile/lib/features/inventory/presentation/stock_out_screen.dart | Frontend | FE-13 | FE-13 | Stock out form | Inventory API | Manager/admin | Planned |
| apps/mobile/lib/features/grn/presentation/grn_entry_screen.dart | Frontend | FE-14 | FE-14 | Supplier invoice inward flow | GRN API | Manager/admin | Planned |
| apps/marketing-web/app/(public)/pricing/page.tsx | Frontend | FE-15 | FE-15 | Public subscription pricing | Analytics API | Prospects | Planned |
| apps/owner-dashboard/app/owner/dashboard/page.tsx | Frontend | FE-16 | FE-16 | Owner-only SaaS KPIs | Owner APIs | RADHA owner | Planned |
| server/src/modules/inventory/inventory.controller.ts | Backend | BE-19 | BE-19 | Stock/count/low-stock APIs | DB-17/DB-18 | Mobile app | Planned |
| server/src/modules/grn/grn.controller.ts | Backend | BE-18 | BE-18 | GRN APIs | DB-16/DB-17 | Mobile app | Planned |
| server/src/modules/subscriptions/subscriptions.controller.ts | Backend | BE-20 | BE-20 | Trial/plan status and events | DB-19 | Mobile/owner dashboard | Planned |
| server/src/modules/owner-dashboard/owner-dashboard.controller.ts | Backend | BE-22 | BE-22 | Owner-only analytics APIs | DB-20 | Owner dashboard | Planned |

