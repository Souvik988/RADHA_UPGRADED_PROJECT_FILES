# File: PHASE_DEPENDENCY_MAP.md

# Phase Dependency Map

|Phase|Name|Depends On|Blocks|Can Run In Parallel With|Notes|
|---|---|---|---|---|---|
|PF-01|Architecture Baseline and Scope Lock|None|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Freeze RADHA MVP scope, premium upgrade scope, terminology, role matrix, and source-of-truth documentation.|
|PF-02|Repository and Monorepo Setup|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create repository layout for Flutter app, admin website, NestJS backend, shared contracts, infrastructure, and docs.|
|PF-03|Tooling, Formatting, and Type Safety|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Add formatting, linting, package scripts, TypeScript configuration, Dart analysis, pre-commit hooks, and CI-ready commands.|
|PF-04|Environment and Configuration Contract|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Define all environment variables, secrets, local dev values, staging/prod separation, and boot-time validation rules.|
|PF-05|Shared Types and Validation Foundation|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create shared DTOs, enums, API response envelopes, validation schemas, and error codes consumed by mobile/admin/backend.|
|PF-06|API Contract Baseline|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Finalize endpoint groups, request/response shapes, auth requirements, role requirements, rate limits, and phase ownership.|
|PF-07|Developer Setup and Documentation Index|Previous PF phase|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create bootstrap scripts, README, local setup runbook, contribution rules, and phase execution index.|
|FE-01|Flutter Mobile App Initialization|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create RADHA mobile app shell, package structure, env loader, and basic build targets.|
|FE-02|Mobile Routing, App Shell, and Role Navigation|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build authenticated/unauthenticated routes, role-based navigation, and bottom/tab structure.|
|FE-03|Design System, Theme, and Shared UI Components|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create premium RADHA UI foundation: colors, typography, cards, buttons, inputs, chips, status badges.|
|FE-04|Authentication and Onboarding Screens|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build mobile OTP login, admin/staff/manager role routing, and first-login profile setup.|
|FE-05|Role-Based Dashboards|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build Staff, Manager, Admin/Auditor dashboard shells with scan/task/report quick actions.|
|FE-06|Barcode/EAN Scanner Screen|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build camera scanner, manual EAN entry fallback, scan states, duplicate scan handling, and scanner permissions.|
|FE-07|Product Detail, Health Indicator, and Expiry Entry|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build product detail screen, health badge UI, child-preference indicator, expiry/manual-OCR entry flow.|
|FE-08|EAN Audit and Bulk Scan Workflow|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build approved-EAN task mode, bulk scan list, green/red validation, invalid item notes, and session summary.|
|FE-09|Task Assignment and Completion Screens|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build manager task creation/list/detail and staff task execution/completion flows.|
|FE-10|Reports, Export, and Sharing Screens|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build report filters, summary cards, Excel/PDF download links, email/WhatsApp share actions.|
|FE-11|Admin Web Panel and Marketing Website|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Build Next.js admin web dashboard, website landing pages, login, product/admin management screens.|
|FE-12|Frontend Testing, Accessibility, Offline States, and Store Polish|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Add tests, responsive checks, accessibility, loading/error/empty states, app icon/splash, release readiness.|
|BE-01|NestJS Backend Initialization|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create server app with API, worker, and scheduler entrypoints.|
|BE-02|Configuration and Environment Validation|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Add typed config, env validation, secrets naming, and boot-time failure on invalid configuration.|
|BE-03|Global Middleware, Error Envelope, Logging, and Request Context|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Add request IDs, safe logs, error filters, response envelope, CORS, Helmet, validation pipes.|
|BE-04|Database Connection and Repository Foundation|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Add Drizzle/Knex data layer, migrations loader, base repository utilities, transactions.|
|BE-05|Authentication, OTP, Sessions, and Admin Login|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement mobile OTP, admin login, refresh tokens, session revocation, OTP abuse protection.|
|BE-06|Authorization, Roles, Users, Tenants, and Stores|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement role guards, tenant/store scoping, user management, store management.|
|BE-07|Product Catalog and Barcode Lookup Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement product lookup by EAN, Open Food Facts fallback, manual product creation, product update.|
|BE-08|Health Scoring and Product Analysis Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement rule-based health indicators, child preference, sugar/oil/processed flags, recompute API.|
|BE-09|EAN List Import and Validation Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement Excel/CSV upload parsing, validation, import errors, approved EAN lookup, list versioning.|
|BE-10|Scan Sessions, Bulk Scan, and Audit Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement scan sessions, scan item writes, EAN pass/fail, duplicate detection, audit metadata.|
|BE-11|Expiry Tracking Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement MFG/EXP dates, status calculation, category thresholds, expired/near-expiry queries.|
|BE-12|Task Assignment Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement task CRUD, assignment, due dates, status transitions, evidence requirements, completion rules.|
|BE-13|Reports and Export Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement report generation, Excel/PDF exports, report file storage, summary API.|
|BE-14|Media, AWS S3, OCR, and Image Processing Module|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement presigned uploads, media approval, OCR expiry assist, label image queue.|
|BE-15|AI Wrapper, Report Summaries, Product Enrichment, and Anomaly Detection|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create free-first AI abstraction, Open Food Facts enrichment, OCR structuring, optional LLM summaries.|
|BE-16|Notifications, Testing, Hardening, and Performance Optimization|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Implement SMS wrapper, email notifications, push hooks, tests, rate limits, security hardening, perf checks.|
|DB-01|Database Engine Confirmation and Naming Conventions|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Lock PostgreSQL, schema names, UUID strategy, timestamps, soft delete policy, enum policy.|
|DB-02|Migration System and Base Extensions|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create migration framework, uuid extension, citext extension, audit timestamp trigger, enum bootstrap.|
|DB-03|Identity, OTP, Sessions, and Audit Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create users, sessions, otp_attempts, audit_logs.|
|DB-04|Tenant, Store, Role, and Access Scope Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create tenants, stores, user_store_access, role-scoping constraints.|
|DB-05|Product Catalog, Nutrition, and Health Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create products, product_nutrition, product_health_assessments, product_sources.|
|DB-06|EAN Import and Approved Display Verification Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create ean_lists, ean_list_items, ean_import_errors, import_batches.|
|DB-07|Scan Session, Scan Item, and Expiry Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create scan_sessions, scan_items, expiry_records, expiry_thresholds.|
|DB-08|Task and Workflow Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create tasks, task_assignments, task_events, task_evidence.|
|DB-09|Reports, Export Files, and Dashboard Aggregation Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create reports, report_files, daily_store_metrics.|
|DB-10|Media and AI Extraction Tables|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create media_assets, ai_extractions, ocr_attempts.|
|DB-11|Indexes, Constraints, and Composite Access Paths|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Apply unique, partial, composite, and GIN indexes based on query map.|
|DB-12|Pagination, Filtering, Transactions, and Concurrency Strategy|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Define cursor pagination, atomic scan writes, import transactions, row locks where needed.|
|DB-13|Seed Data and Reference Data|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Seed roles, initial admin, health thresholds, categories, sample stores, demo products.|
|DB-14|Backup, Restore, Retention, and Archiving|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Enable RDS backups, test restore, define retention for reports/media/audit logs.|
|DB-15|10,000-User Readiness and Slow Query Validation|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Run EXPLAIN plans, load-seed 10K users, validate scan/report query latency, connection pooling.|
|INF-01|Local Development Environment|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Dockerize Postgres/Redis/localstack-compatible S3 if used, dev scripts, local env.|
|INF-02|AWS Account, IAM, VPC, and Cost Guardrails|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create IAM roles, least privilege policies, VPC/subnets/security groups, budgets/alarms.|
|INF-03|RDS PostgreSQL Provisioning|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create RDS, parameter group, backups, connection limits, migration access.|
|INF-04|S3 Media Buckets and CloudFront CDN|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Create buckets, CORS, lifecycle, signed access pattern, CloudFront distribution.|
|INF-05|Compute Deployment Target|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Provision ECS Fargate or EC2 Docker host for API/worker/admin; define scale path.|
|INF-06|Secrets and Environment Promotion|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Set secrets manager/SSM, staging/prod envs, rotation rules.|
|INF-07|CI/CD Pipeline|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|GitHub Actions for lint/test/build/migrate/deploy with manual prod approval.|
|INF-08|Staging Deployment|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Deploy full staging stack, seed demo tenant, verify app/admin/backend flows.|
|INF-09|Monitoring, Logging, and Alerting|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|CloudWatch, Sentry, uptime, audit log alerts, cost alerts.|
|INF-10|Backup, Restore, and Disaster Recovery Drill|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Run restore test, media backup check, DB snapshot policy, rollback plan.|
|INF-11|Security, Load, and Abuse Testing|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|OWASP checks, k6 load tests, OTP abuse tests, file upload threat tests.|
|INF-12|Production Launch and Post-Launch Operations|Previous phase in same section + PF-05/PF-06|Downstream feature implementation|Frontend with mocks / DB+Backend / Infra after env contract|Go-live checklist, app store/internal distribution, first 30-day support cadence.|


## Critical Blocking Chain
PF-01 → PF-05 → PF-06 → DB-01..DB-07 → BE-01..BE-11 → FE-06..FE-08 → Integration Testing.
---

## 2026-05-15 Upgrade Patch: Added Advanced Phase Dependencies

### Revised Master Build Order
1. Complete PF-01 to PF-07.
2. Complete DB-01 to DB-04 and BE-01 to BE-06.
3. Build FE-01 to FE-05 against mocks while backend auth/user APIs stabilize.
4. Complete DB-05 to DB-07, BE-07 to BE-11, FE-06 to FE-08.
5. Complete DB-08 to DB-10, BE-12 to BE-15, FE-09 to FE-10.
6. Add DB-16 to DB-18, BE-17 to BE-19, FE-13 to FE-14 for GRN and lightweight inventory.
7. Add DB-19 to DB-20, BE-20 to BE-22, FE-15 to FE-16 for subscriptions, marketing website, owner-only dashboard, and analytics.
8. Complete INF-01 to INF-08 during backend/frontend build.
9. Complete FE-12, BE-16, DB-15, INF-09 to INF-12 before launch.
10. Launch internal demo, closed pilot, three-store pilot, paid beta, public release.

### Added Roadmap Phases
| Phase | Name | Depends On | Blocks | Can Run In Parallel With | Notes |
|---|---|---|---|---|---|
| DB-16 | Suppliers and GRN Tables | DB-04,DB-05 | BE-17,BE-18 | FE mocks | Supplier, invoice, inward, item expiry/batch. |
| DB-17 | Inventory Items, Batches, and Movements | DB-16 | BE-19 | FE mocks | Stock source of truth and stock movement audit. |
| DB-18 | Low Stock Rules and Alerts | DB-17 | FE-13 dashboard cards | Reports/AI | Thresholds and alert lifecycle. |
| DB-19 | Subscription Plans and Entitlements | DB-04 | BE-20 | Marketing website | Trial and ₹49/₹99/₹199 plans. |
| DB-20 | Analytics, Leads, and Owner Metrics | DB-04,DB-19 | BE-21,BE-22 | Marketing website | Website events, app events, owner KPI rollups. |
| FE-13 | Mobile Lightweight Inventory | BE-19 mocks | Client dashboard | BE-19 | Inventory counts, stock in/out, low-stock alerts. |
| FE-14 | Mobile GRN and Supplier Flow | BE-18 mocks | Inventory posting | BE-18 | Supplier, invoice, inward items, review/post. |
| FE-15 | Marketing Website and Pricing | PF-06 | Owner analytics | BE-21 | Public landing, pricing, lead capture, download CTA. |
| FE-16 | Owner-Only Dashboard | BE-22 mocks | SaaS operations | BE-22 | Website analytics, users, subscriptions, revenue, leads. |
| BE-17 | Suppliers Module | DB-16 | BE-18 | FE-14 | Supplier CRUD scoped by tenant/store. |
| BE-18 | GRN Module | DB-16,DB-17 | BE-19 | FE-14 | Draft/post/cancel GRN with stock posting. |
| BE-19 | Inventory Module | DB-17,DB-18 | Dashboard/reports | FE-13 | Stock in/out, counts, low-stock alerts. |
| BE-20 | Subscription and Entitlement Module | DB-19 | Feature gating | FE-15 | Trial status, plans, limits, subscription events. |
| BE-21 | Analytics and Lead Ingestion | DB-20 | Owner dashboard | FE-15 | Website/app events and leads. |
| BE-22 | Owner Dashboard Module | DB-20 | Owner web dashboard | FE-16 | Owner-only KPIs, users, subscriptions, leads, usage. |

