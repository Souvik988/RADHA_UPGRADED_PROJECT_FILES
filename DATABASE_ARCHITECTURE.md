# File: DATABASE_ARCHITECTURE.md

# RADHA Database Architecture and Optimization

## Database Choice
PostgreSQL on Amazon RDS.

## Core Conventions
- Snake_case table/column names.
- `id uuid primary key`.
- `tenant_id` on multi-tenant business tables.
- `created_at`, `updated_at`, `deleted_at` where mutable.
- Cursor pagination on `(created_at, id)` or domain-specific sort columns.

## Table-by-Table Execution and Optimization Map
|Table|Created In Phase|Depends On|Used By APIs|Main Indexes|Common Queries|Risk|Optimization|
|---|---|---|---|---|---|---|---|
|tenants|DB-04|none|/users,/dashboard|idx_tenants_status|read tenant config by id|tenant scoping mistakes|Always require tenant_id in child tables.|
|stores|DB-04|tenants|/dashboard,/tasks,/scans|idx_stores_tenant_city|list stores by tenant/city|unscoped scans|Composite indexes include tenant_id.|
|users|DB-03|tenants/stores|/auth,/users,/tasks|uniq_users_mobile,idx_users_tenant_role|login, user list, role check|PII leakage|Encrypt/avoid logging mobile/email.|
|user_sessions|DB-03|users|/auth/refresh|idx_sessions_user_active|refresh token lookup|stale sessions|Revoke old refresh token on rotation.|
|otp_attempts|DB-03|users optional|/auth/otp/*|idx_otp_mobile_created|OTP verify by mobile/request|OTP brute force|Store hashed OTP, rate-limit in Redis and DB.|
|products|DB-05|tenants optional|/products,/scans|uniq_products_ean,idx_products_brand_category|lookup by EAN|missing product data|Use internal DB first, external fallback.|
|product_nutrition|DB-05|products|/products/health|idx_nutrition_product|fetch nutrition for health|null/incomplete labels|Allow partial JSON and confidence flags.|
|product_health_assessments|DB-05|products|/products/health,/dashboard|idx_health_product,idx_health_label|read product health score|wrong health claims|Rule-based score with disclaimer and version.|
|ean_lists|DB-06|tenants,stores|/ean-lists|idx_ean_lists_store_active|list active EAN files|wrong list used|Version and active flag per store.|
|ean_list_items|DB-06|ean_lists|/ean-lists/validate|idx_ean_items_list_ean unique|EAN existence check|slow validation|Composite unique(list_id, ean).|
|ean_import_errors|DB-06|ean_lists|/ean-lists/import|idx_import_errors_list|download invalid rows|bad Excel data|Store row number and reason.|
|scan_sessions|DB-07|users,stores,tasks|/scan-sessions|idx_scan_sessions_store_created|audit session history|huge lists|Cursor paginate by created_at/id.|
|scan_items|DB-07|scan_sessions,products|/scan-sessions/items,/reports|idx_scan_items_session,idx_scan_items_store_created|write/read scan items|hot table growth|Partition later by month if volume grows.|
|expiry_records|DB-07|scan_items,products|/expiry-records|idx_expiry_store_status_date|near-expiry dashboard|wrong thresholds|Use category thresholds and confirm OCR.|
|tasks|DB-08|users,stores|/tasks|idx_tasks_store_status_due|task list by status/due|overdue query slow|Composite(store_id,status,due_date).|
|task_events|DB-08|tasks,users|/tasks/{id}|idx_task_events_task_created|task audit trail|missing audit context|Append-only event model.|
|reports|DB-09|stores,users|/reports|idx_reports_store_created|report history|regenerating large reports|Persist generated file and filters.|
|report_files|DB-09|reports,media_assets|/reports/download|idx_report_files_report|download report|expired links|Use presigned URL with short TTL.|
|media_assets|DB-10|users|/media|idx_media_owner,idx_media_status|fetch uploaded image/audio|unsafe media published|Pending until scanned.|
|ai_extractions|DB-10|media_assets/reports|/ai/*|idx_ai_source_status|review OCR/AI outputs|hallucinated AI data|AI suggestions require confirmation.|
|notification_logs|DB-09|users|/notifications later|idx_notifications_user_created|audit sent notifications|cost/noise|Throttle by type.|
|audit_logs|DB-03|all|admin/audit|idx_audit_actor_created|admin audit|too much data|Append-only, retention policy.|


## Query Pattern Map
| Query | Required Index | Pagination |
|---|---|---|
| Product lookup by EAN | `unique(products.ean)` | no |
| Active EAN validation | `unique(ean_list_id, ean)` | no |
| Recent scans | `(store_id, scanned_at desc, id desc)` | cursor |
| Near-expiry | `(store_id, status, expiry_date)` | cursor |
| Pending tasks | `(assigned_to, status, due_date)` | cursor |
| Report history | `(store_id, created_at desc)` | cursor |

## Transaction Strategy
- EAN import: validated chunks.
- Scan item: scan_item + optional expiry_record + audit log.
- Task completion: task update + task_event + evidence links.
- Report generation: pending report -> worker generates file -> status ready.

# File: DATABASE_EXECUTION_PHASES.md

# Database Execution and Optimization Phases

## Phase DB-01: Database Engine Confirmation and Naming Conventions

### Goal
Lock PostgreSQL, schema names, UUID strategy, timestamps, soft delete policy, enum policy.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/001_database_engine_confirmation_and_naming_conventions.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-01 complete when migrations, indexes, and tests pass.
## Phase DB-02: Migration System and Base Extensions

### Goal
Create migration framework, uuid extension, citext extension, audit timestamp trigger, enum bootstrap.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/002_migration_system_and_base_extensions.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-02 complete when migrations, indexes, and tests pass.
## Phase DB-03: Identity, OTP, Sessions, and Audit Tables

### Goal
Create users, sessions, otp_attempts, audit_logs.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/003_identity_otp_sessions_and_audit_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-03 complete when migrations, indexes, and tests pass.
## Phase DB-04: Tenant, Store, Role, and Access Scope Tables

### Goal
Create tenants, stores, user_store_access, role-scoping constraints.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/004_tenant_store_role_and_access_scope_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-04 complete when migrations, indexes, and tests pass.
## Phase DB-05: Product Catalog, Nutrition, and Health Tables

### Goal
Create products, product_nutrition, product_health_assessments, product_sources.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/005_product_catalog_nutrition_and_health_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-05 complete when migrations, indexes, and tests pass.
## Phase DB-06: EAN Import and Approved Display Verification Tables

### Goal
Create ean_lists, ean_list_items, ean_import_errors, import_batches.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/006_ean_import_and_approved_display_verification_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-06 complete when migrations, indexes, and tests pass.
## Phase DB-07: Scan Session, Scan Item, and Expiry Tables

### Goal
Create scan_sessions, scan_items, expiry_records, expiry_thresholds.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/007_scan_session_scan_item_and_expiry_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-07 complete when migrations, indexes, and tests pass.
## Phase DB-08: Task and Workflow Tables

### Goal
Create tasks, task_assignments, task_events, task_evidence.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/008_task_and_workflow_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-08 complete when migrations, indexes, and tests pass.
## Phase DB-09: Reports, Export Files, and Dashboard Aggregation Tables

### Goal
Create reports, report_files, daily_store_metrics.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/009_reports_export_files_and_dashboard_aggregation_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-09 complete when migrations, indexes, and tests pass.
## Phase DB-10: Media and AI Extraction Tables

### Goal
Create media_assets, ai_extractions, ocr_attempts.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/010_media_and_ai_extraction_tables.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-10 complete when migrations, indexes, and tests pass.
## Phase DB-11: Indexes, Constraints, and Composite Access Paths

### Goal
Apply unique, partial, composite, and GIN indexes based on query map.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/011_indexes_constraints_and_composite_access_paths.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-11 complete when migrations, indexes, and tests pass.
## Phase DB-12: Pagination, Filtering, Transactions, and Concurrency Strategy

### Goal
Define cursor pagination, atomic scan writes, import transactions, row locks where needed.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/012_pagination_filtering_transactions_and_concurrency_strategy.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-12 complete when migrations, indexes, and tests pass.
## Phase DB-13: Seed Data and Reference Data

### Goal
Seed roles, initial admin, health thresholds, categories, sample stores, demo products.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/013_seed_data_and_reference_data.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-13 complete when migrations, indexes, and tests pass.
## Phase DB-14: Backup, Restore, Retention, and Archiving

### Goal
Enable RDS backups, test restore, define retention for reports/media/audit logs.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/014_backup_restore_retention_and_archiving.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-14 complete when migrations, indexes, and tests pass.
## Phase DB-15: 10,000-User Readiness and Slow Query Validation

### Goal
Run EXPLAIN plans, load-seed 10K users, validate scan/report query latency, connection pooling.

### Why This Phase Matters
This phase creates a production-grade boundary for all later work and prevents building the wrong feature order.

### Files to Create
| File | Purpose | Empty Initially? |
|---|---|---|
| `server/src/db/migrations/015_10_000_user_readiness_and_slow_query_validation.sql` | Required implementation/documentation artifact | No |
| `server/src/db/schema/` | Create required folder scaffold | Yes |


### Files to Modify
| File | Required Change |
|---|---|
| `DATABASE_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `BACKEND_ARCHITECTURE.md` | Update with this phase's contract, dependencies, and validation rules. |
| `API_CONTRACTS.md` | Update with this phase's contract, dependencies, and validation rules. |


### Commands to Run
```bash
cd server
pnpm db:generate
pnpm db:migrate
pnpm db:test
```

### Dependencies
Depends on PF-04/PF-05. Backend phases cannot proceed until required migrations exist.

### Database Tables Affected
Tables listed in DATABASE_ARCHITECTURE.md.

### API Contracts Affected
API contracts relying on affected tables must be updated before backend implementation.

### Frontend Screens/Components Affected
No direct access; frontend uses API contracts.

### Backend Routes/Controllers/Services Affected
Repositories for affected tables must wait for migration.

### Tests to Write
- Migration up/down test.
- Repository integration tests.
- EXPLAIN checks for hot paths.

### Validation Checklist
- Migration runs from zero.
- FKs/indexes exist.
- Query plans avoid full scans on hot paths.

### Risks and Bugs to Watch
- Missing tenant/store indexes.
- Backend implemented before schema stable.
- Overusing JSONB for filterable fields.

### Completion Criteria
DB-15 complete when migrations, indexes, and tests pass.
---

## 2026-05-15 Upgrade Patch: Inventory, GRN, Subscription, and Owner Analytics Tables

### Added Database Tables
| Table | Created In Phase | Depends On | Used By APIs | Main Indexes | Common Queries | Risk | Optimization |
|---|---|---|---|---|---|---|---|
| suppliers | DB-16 | tenants,stores | /suppliers,/grn | idx_suppliers_store_name | supplier lookup by store | duplicate suppliers | Unique normalized supplier name per tenant/store where practical. |
| grn_headers | DB-16 | tenants,stores,suppliers,users | /grn | idx_grn_store_date, uniq_grn_store_invoice_supplier | inward history by store/date | duplicate invoice posting | Unique supplier+invoice per store; status draft/posted/cancelled. |
| grn_items | DB-16 | grn_headers,products | /grn/{id}/items | idx_grn_items_header, idx_grn_items_product | products in inward | missing expiry/batch | Require expiry for expiry-tracked categories. |
| inventory_items | DB-17 | tenants,stores,products | /inventory/counts | uniq_inventory_store_product | current product stock by store | stale computed counts | Update through stock movement transaction only. |
| inventory_batches | DB-17 | inventory_items,grn_items,products | /inventory/batches,/expiry | idx_batches_store_expiry, idx_batches_product_expiry | expiry-wise stock | wrong batch stock | FIFO stock-out and reconciliation logs. |
| stock_movements | DB-17 | inventory_items,inventory_batches,users | /inventory/stock-in,/inventory/stock-out | idx_stock_movements_store_created, idx_stock_movements_product_created | audit stock history | negative stock bugs | Transaction + non-negative stock constraint. |
| low_stock_rules | DB-18 | tenants,stores,products/categories | /inventory/low-stock-rules | idx_low_stock_store_product | threshold lookup | too many false alerts | Product threshold overrides category threshold. |
| low_stock_alerts | DB-18 | low_stock_rules,inventory_items | /inventory/low-stock | idx_low_stock_alerts_store_status | active low-stock alerts | alert spam | Open/resolve lifecycle; de-duplicate active alerts. |
| subscription_plans | DB-19 | none | /owner/subscription-plans | uniq_plan_code | plan setup | wrong entitlement | Immutable plan code; version entitlements. |
| plan_entitlements | DB-19 | subscription_plans | /subscriptions/status | idx_entitlements_plan | feature limits | clients using blocked features | Enforce in backend guards. |
| tenant_subscriptions | DB-19 | tenants,subscription_plans | /subscriptions/status,/owner/subscriptions | idx_tenant_sub_status, idx_sub_trial_end | trial/paid state | expired trials still active | Status gate every request where needed. |
| subscription_events | DB-19 | tenant_subscriptions | /owner/subscriptions/events | idx_sub_events_sub_created | payment/trial event audit | lost billing state | Append-only event log. |
| razorpay_orders | DB-19 v2 | tenants(optional),users,subscription_plans | /payments/checkout,/payments/verify,/payments/refund,/payments/webhooks/razorpay | razorpay_orders_order_id_unique, razorpay_orders_tenant_status_idx, razorpay_orders_user_status_idx | Razorpay order ledger | duplicate captures, mis-attributed payments | Unique on `razorpay_order_id`; status `created→authorised→captured→refunded/failed`; HMAC verify before write. |
| payment_webhooks_inbox | DB-19 v2 | none (provider-only) | /payments/webhooks/razorpay | payment_webhooks_inbox_event_id_unique, payment_webhooks_inbox_provider_type_received_idx | Webhook idempotency anchor | duplicate side-effects on retry | Unique on `event_id`; insert on receive, stamp `processed_at` after side-effects, swallow handler errors into `processing_error`. |
| website_events | DB-20 | none/tenants optional | /owner/analytics/website | idx_website_events_created, idx_website_events_session | visitor/click analytics | PII overcollection | Store minimal event data and consent-aware IDs. |
| marketing_leads | DB-20 | website_events optional | /owner/leads | idx_leads_created_status | demo/contact leads | duplicate leads | Deduplicate by mobile/email hash. |
| app_usage_events | DB-20 | tenants,users,stores | /owner/analytics/app | idx_app_usage_tenant_created, idx_app_usage_event | feature usage | huge event table | Roll up daily metrics; retain raw events by policy. |
| owner_daily_metrics | DB-20 | website_events,app_usage_events,subscriptions | /owner/dashboard/summary | idx_owner_metrics_date | owner KPI dashboard | slow dashboard | Scheduled rollups. |

### Inventory Transaction Rules
- GRN posting creates `stock_movements` with type `GRN_IN` and increments `inventory_items` and `inventory_batches` in one transaction.
- Manual stock in creates movement type `MANUAL_IN`.
- Stock out creates movement type `EXPIRED_OUT`, `DAMAGED_OUT`, `AUDIT_ADJUSTMENT_OUT`, or `MANUAL_OUT`.
- Stock cannot go negative unless a manager/admin creates an approved correction.
- Low-stock alerts are recalculated after every stock movement.
- Expiry dashboard should read from `inventory_batches` and `expiry_records` together, but batch stock is the source for current stock quantity.

### Subscription Rules
- Every tenant starts with a free trial window.
- After trial end, backend entitlements decide whether scan, export, report, inventory, AI summary, and staff-user limits remain available.
- Plans should be represented as data, not hardcoded constants, so ₹49, ₹99, and ₹199 tiers can change later.

### Owner Analytics Rules
- Owner dashboard is outside tenant access and requires owner-only role.
- Client store admins must never access owner analytics.
- Website analytics should track page views, feature/pricing clicks, contact clicks, lead submissions, app download clicks, and campaign source.
- App analytics should track signups, logins, active users, feature usage, subscription state, and conversion funnel.

