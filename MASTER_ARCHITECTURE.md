# File: MASTER_ARCHITECTURE.md

# RADHA Master Architecture

**RADHA** = Retail Assistant for Data, Health & Audits.

## Product Overview
RADHA is a native mobile-first retail audit platform for Indian retail teams. It supports barcode/EAN scanning, product lookup, product health indicators, expiry tracking, approved EAN verification through Excel/CSV uploads, bulk audit scans, reports, task assignment, OCR assistance, and a web admin panel.

## Final Architecture Decision
- Mobile app: Flutter for Android and iOS from one codebase.
- Admin panel and marketing website: Next.js.
- Backend: NestJS modular monolith.
- Database: PostgreSQL on AWS RDS.
- Storage: AWS S3 with presigned upload URLs.
- CDN: CloudFront.
- SMS: MSG91 wrapper through backend only.
- AI/OCR: free-first layered system: Google ML Kit on-device scanning/OCR, rule-based health scoring, Open Food Facts lookup, optional LLM summaries through an abstracted AI wrapper, AWS Rekognition only as paid escalation.

## Major Execution Sections
1. Project Foundation and Shared Architecture
2. Frontend Execution
3. Backend Execution
4. Database Execution and Optimization
5. Infrastructure, Testing, Deployment, and Production Launch

## Core Modules
| Module | Purpose | Primary Owner |
|---|---|---|
| Auth/Roles | OTP login, admin login, staff/manager/admin access | Backend + Mobile |
| Product Catalog | EAN lookup, product enrichment, manual product creation | Backend + DB |
| Health Indicator | Rules-based health status, child suitability, sugar/oil/processed indicators | Backend + Mobile |
| Expiry Tracking | MFG/EXP input, OCR assist, category thresholds, green/yellow/red status | Backend + DB + Mobile |
| EAN Verification | Excel/CSV approved EAN uploads and green/red scan validation | Backend + Admin + Mobile |
| Bulk Scan | Continuous scan sessions, exportable audit trail | Backend + Mobile |
| Tasks | Manager assignment and staff completion | Backend + Mobile |
| Reports | Excel/PDF exports and dashboard summaries | Backend + Admin |
| AI/OCR | Free-first product data/expiry assist/report summaries | Backend Worker |
| Admin Panel | User/product/EAN/task/report management | Admin Web |

## Top-Notch Upgrade Scope Added
- Offline audit mode.
- Pharmacy expiry mode.
- School canteen health list mode.
- Vendor near-expiry accountability.
- Auto discount suggestion for near-expiry stock.
- WhatsApp manager bot later.
- Shelf-photo AI audit later.
- Planogram compliance later.

## Scalability Summary
Prepared for 10,000 users by using RDS indexing, cursor pagination, background workers, S3 direct upload, async reports, tenant/store scoping, and report file persistence.

## Build Order Summary
1. Lock contracts and repository foundations.
2. Create database migrations before backend repositories.
3. Implement auth/roles/users/stores.
4. Implement product lookup and EAN import.
5. Implement scanner, expiry, scan sessions.
6. Implement tasks and reports.
7. Add OCR/AI wrappers.
8. Harden infra, testing, and launch checklist.

## Reference Sources
- Flutter official site: https://flutter.dev/ — single codebase mobile/web/desktop development.
- Google ML Kit barcode scanning: https://developers.google.com/ml-kit/vision/barcode-scanning/ — on-device standard barcode scanning.
- Open Food Facts API: https://openfoodfacts.github.io/openfoodfacts-server/api/ — ingredients and nutrition product data.
- AWS S3 presigned uploads: https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html
- Amazon Rekognition content moderation: https://aws.amazon.com/rekognition/content-moderation/
- Amazon RDS backups: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html
- MSG91 OTP docs: https://docs.msg91.com/otp
---

## 2026-05-15 Upgrade Patch: Lightweight Inventory, GRN, Subscriptions, and Owner Dashboard

### Revised Product Boundary
RADHA is **not** a GST billing, POS, accounting, or full ERP product in V1. RADHA is a smart retail operations platform focused on audit, scanning, expiry control, display verification, lightweight GRN, and lightweight inventory.

### Updated Product Surfaces
| Surface | User | Platform | Purpose |
|---|---|---|---|
| RADHA Mobile App | Retail clients: owner, manager, staff, auditor | Flutter | Operational work and client in-app dashboard. |
| RADHA Marketing Website | Public visitors and prospects | Next.js | Product marketing, pricing, contact/demo, Play Store links, privacy/terms. |
| RADHA Owner Dashboard | RADHA business owner only | Private Next.js web app | Website analytics, leads, app users, trial users, subscriptions, revenue, usage, support signals. |
| Backend API + Worker | System | NestJS | Business APIs, imports, reports, subscriptions, owner analytics, AI wrappers. |

### Added Core Modules
| Module | Purpose | Primary Owner |
|---|---|---|
| Lightweight Inventory | Stock in/out, basic counts, category stock visibility, low-stock alerts | Backend + DB + Mobile |
| GRN/Inward | Supplier entry, invoice number, inward quantity, expiry/batch capture, stock posting | Backend + DB + Mobile |
| Subscription/Entitlements | 3-month free trial, ₹49/₹99/₹199 plans, feature limits, subscription state | Backend + Owner Dashboard |
| Owner Analytics | Track website visitors, clicks, leads, signups, app logins, active users, subscriptions, revenue | Backend + Owner Dashboard |
| Client In-App Dashboard | Store-level scans, expiry, EAN, tasks, inventory, low-stock, GRN summaries | Mobile |

### Lightweight Inventory Scope
Inventory must remain simple and operational:
- Stock in from GRN or manual adjustment.
- Stock out for expired, damaged, removed, correction, or manual adjustment.
- Product/store/category stock counts.
- Low-stock threshold and alerts.
- Expiry visibility by batch.
- No sales ledger, GST invoice, POS cart, payment collection, or accounting.

### Owner Dashboard Scope
Owner-only dashboard must show:
- Website visitors, clicks, pricing-page views, contact/WhatsApp clicks.
- Leads and demo requests.
- App registrations, stores created, active users, login activity.
- Trial users, paid users, expired trials, cancelled subscriptions.
- Plan split: ₹49, ₹99, ₹199.
- Monthly recurring revenue estimate.
- Feature usage: scans, expiry records, EAN validations, inventory entries, GRNs, reports.
- AI usage and cost signals.

### Revised Build Order Insertions
Add these after scan/expiry/EAN and before advanced AI:
1. DB inventory + GRN tables.
2. Backend inventory + GRN services.
3. Mobile inventory + GRN screens.
4. Client dashboard inventory cards.
5. Subscription entitlement engine.
6. Owner analytics ingestion and dashboard.

