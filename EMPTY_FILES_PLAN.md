# File: EMPTY_FILES_PLAN.md

# Placeholder-to-Implementation Map

|Empty File|Section|Why It Exists|Filled In Phase|Future Content|Depends On|Blocks|Required|
|---|---|---|---|---|---|---|---|
|apps/mobile/lib/features/scanner/presentation/scanner_screen.dart|Frontend|Reserved for scanner UI|FE-06|Camera scanner, manual EAN input, scan state machine|FE-01, API contracts|Scanner cannot ship|Yes|
|apps/mobile/lib/features/expiry/presentation/expiry_entry_screen.dart|Frontend|Reserved for expiry workflow|FE-07|MFG/EXP form, OCR suggestion card, status banner|Product detail screen|Expiry feature|Yes|
|apps/admin-web/app/admin/ean-lists/page.tsx|Frontend|Reserved for EAN imports|FE-11|Excel upload wizard, import errors, active list selector|Admin auth|Display verification|Yes|
|server/src/modules/ai/ai.service.ts|Backend|Provider abstraction placeholder|BE-15|Free-first OCR/summary interface and provider switching|Config, queues|AI features|Yes|
|server/src/modules/sms/sms.service.ts|Backend|SMS wrapper placeholder|BE-16|MSG91 implementation and retry/failure handling|Env config|OTP|Yes|
|server/src/db/schema/scan-items.ts|Database|Hot scan table schema|DB-07|scan_sessions and scan_items schema definitions|DB conventions|Scans/reports|Yes|
|infra/aws/rds.md|Infra|RDS runbook placeholder|INF-03|RDS creation, backups, connection pooling, restore drill|AWS account|Production DB|Yes|
---

## 2026-05-15 Upgrade Patch: Additional Placeholder-to-Implementation Rows

| Empty File | Section | Why It Exists | Filled In Phase | Future Content | Depends On | Blocks | Required |
|---|---|---|---|---|---|---|---|
| apps/mobile/lib/features/inventory/presentation/inventory_dashboard_screen.dart | Frontend | Reserved for lightweight inventory dashboard | FE-13 | Stock counts, category visibility, low-stock alerts | Inventory API | Inventory cannot ship | Yes |
| apps/mobile/lib/features/inventory/presentation/stock_in_screen.dart | Frontend | Reserved for stock in workflow | FE-13 | Manual stock in and GRN-linked stock in | Inventory API | Stock update flow | Yes |
| apps/mobile/lib/features/inventory/presentation/stock_out_screen.dart | Frontend | Reserved for stock out workflow | FE-13 | Expired/damaged/adjustment stock out | Inventory API | Inventory correction | Yes |
| apps/mobile/lib/features/grn/presentation/grn_entry_screen.dart | Frontend | Reserved for GRN inward workflow | FE-14 | Supplier, invoice, inward items, expiry/batch | GRN API | GRN cannot ship | Yes |
| apps/mobile/lib/features/subscription/presentation/subscription_status_screen.dart | Frontend | Reserved for trial/plan visibility | FE-15 | Trial countdown, plan status, entitlement banners | Subscription API | SaaS launch | Yes |
| apps/marketing-web/app/(public)/pricing/page.tsx | Frontend | Reserved for pricing page | FE-15 | 3-month free trial, ₹49/₹99/₹199 plan cards | Marketing design | Conversion | Yes |
| apps/owner-dashboard/app/owner/dashboard/page.tsx | Frontend | Reserved for owner SaaS dashboard | FE-16 | Visitors, users, trials, paid users, revenue, leads | Owner API | Business monitoring | Yes |
| server/src/modules/grn/grn.service.ts | Backend | Reserved for transactional GRN posting | BE-18 | Draft/post/cancel, stock posting | DB-16/DB-17 | GRN | Yes |
| server/src/modules/inventory/inventory.service.ts | Backend | Reserved for stock movement rules | BE-19 | stock in/out, counts, low-stock alerts | DB-17/DB-18 | Inventory | Yes |
| server/src/modules/subscriptions/subscriptions.service.ts | Backend | Reserved for subscription gates | BE-20 | Trial/plan state and entitlements | DB-19 | Monetization | Yes |
| server/src/modules/owner-dashboard/owner-dashboard.service.ts | Backend | Reserved for owner-only KPIs | BE-22 | Users, subscriptions, website analytics, leads | DB-20 | Owner dashboard | Yes |

